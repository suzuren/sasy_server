--debug_console
local skynet = require "skynet"
require "skynet.manager"
local codecache = require "skynet.codecache"
local core = require "skynet.core"
local socket = require "socket"
local snax = require "snax"
local addressResolver = require "addressResolver"
local xpcallUtility = require "utility.xpcall"
local memory = require "skynet.memory"

local port = tonumber(...)
local COMMAND = {}

local function format_table(t)
	local index = {}
	for k in pairs(t) do
		table.insert(index, k)
	end
	table.sort(index)
	local result = {}
	for _,v in ipairs(index) do
		table.insert(result, string.format("%s:%s",v,tostring(t[v])))
	end
	return table.concat(result,"\t")
end

local function dump_line(print, key, value)
	if type(value) == "table" then
		print(string.format("%-16s", tostring(key)), format_table(value))
	else
		print(string.format("%-16s", tostring(key)), tostring(value))
	end
end

local function dump_list(print, list)
	local index = {}
	for k in pairs(list) do
		table.insert(index, k)
	end
	table.sort(index)
	for _,v in ipairs(index) do
		dump_line(print, v, list[v])
	end
	print("TELNET_OK")
end

local function split_cmdline(cmdline)
	local split = {}
	for i in string.gmatch(cmdline, "%S+") do
		table.insert(split,i)
	end
	return split
end

local function docmd(cmdline, print, fd)
	local split = split_cmdline(cmdline)
	local command = split[1]
	if command == "debug" then
		table.insert(split, fd)
	end
	local cmd = COMMAND[command]
	local ok, list
	if cmd then
		ok, list = xpcall(cmd, xpcallUtility.errorMessageSaver, select(2,table.unpack(split)))
	else
		print("Invalid command, type help for command list")
	end

	if ok then
		if list then
			if type(list) == "string" then
				print(list)
			else
				dump_list(print, list)
			end
		else
			print("TELNET_OK")
		end
	else
		print("Error:", xpcallUtility.getErrorMessage())
	end
end

local function console_main_loop(stdin, print)
	socket.lock(stdin)
	print("欢迎登录管理后台")
	while true do
		local cmdline = socket.readline(stdin, "\n")
		skynet.error(string.format("%s - cmdline:%s", SERVICE_NAME, cmdline))
		if not cmdline then
			--print("管理客户端退出")
			break
		end
		if cmdline ~= "" then
			docmd(cmdline, print, stdin)
		end
	end
	socket.unlock(stdin)
end

skynet.start(function()
	local listen_socket = socket.listen ("127.0.0.1", port)
	skynet.error(SERVICE_NAME .. "Start debug console at 127.0.0.1 " .. port)
	socket.start(listen_socket , function(id, addr)
		local function print(...)
			local t = { ... }
			for k,v in ipairs(t) do
				t[k] = tostring(v)
			end
			socket.write(id, table.concat(t,"\t"))
			socket.write(id, "\n")
		end
		socket.start(id)
		skynet.fork(console_main_loop, id , print)
	end)
end)

function COMMAND.help()
	return {
		help = "This help message",
		list = "List all the service",
		stat = "Dump all stats",
		info = "Info address : get service infomation",
		exit = "exit address : kill a lua service",
		mem = "mem : show memory status",
		gc = "gc : force every lua service do garbage collect",
		service = "List unique service",
		task = "task address : show service task detail",
		cmem = "Show C memory info",
		shrtbl = "Show shared short string table info",
		shutdown = "close this game server",
	}
end

function COMMAND.reloadDefense()
	skynet.call(addressResolver.getAddressByServiceName("LS_model_telnet"), "lua", "reloadDefense")
end


----------------------------------------------------------------------------------------------------------

local function adjust_address(address)
	if address:sub(1,1) ~= ":" then
		address = assert(tonumber("0x" .. address), "Need an address") | (skynet.harbor(skynet.self()) << 24)
	end
	return address
end

function COMMAND.list()
	return skynet.call(".launcher", "lua", "LIST")
end

function COMMAND.stat()
	return skynet.call(".launcher", "lua", "STAT")
end

function COMMAND.info(address)
	address = adjust_address(address)
	return skynet.call(address,"debug","INFO")
end

function COMMAND.exit(address)
	skynet.send(adjust_address(address), "debug", "EXIT")
end

function COMMAND.mem()
	return skynet.call(".launcher", "lua", "MEM")
end

function COMMAND.gc()
	return skynet.call(".launcher", "lua", "GC")
end

function COMMAND.service()
	return skynet.call("SERVICE", "lua", "LIST")
end

function COMMAND.task(address)
	address = adjust_address(address)
	return skynet.call(address,"debug","TASK")
end

function COMMAND.cmem()
	local info = memory.info()
	local tmp = {}
	for k,v in pairs(info) do
		tmp[skynet.address(k)] = v
	end
	return tmp
end

function COMMAND.shrtbl()
	local n, total, longest, space = memory.ssinfo()
	return { n = n, total = total, longest = longest, space = space }
end

function COMMAND.shutdown()
	skynet.error("从控制台发起退出")
	skynet.sleep(200)
	skynet.abort()
end


----------------------------------------------------------------------------------------------------------


