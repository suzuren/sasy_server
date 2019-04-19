local skynet = require "skynet"
local socket = require "socket"
local queue = require "skynet.queue"
local commonServiceHelper = require "serviceHelper.common"
local netpack = require "websocketnetpack"
local inspect = require "inspect"

local _fd
local _gate							-- address of wsGateway
local _cache = {}					-- {addr, session, userID, sui}
local _event = {}					-- {disconnect }
local _heartBeatData = {}			-- {"hello":"world"}
local _criticalSection = queue()

local function sendPacket(msg, size)
	if _fd then
		socket.write(_fd, msg, size)
	end
end

local function exit()
	skynet.error(string.format("wsConnection.exit: close fd=%s", tostring(_fd)))
	if _gate and _fd then
		local fd = _fd
		_fd = nil
		skynet.call(_gate, "lua", "kick", fd)
	end
	skynet.exit()
end

local function sendMessage(strData)
	_criticalSection(function()	-- 新加，保证消息次序
		sendPacket(netpack.pack(strData))
	end)
end


local function cmd_start(data)
	_gate = data.gateway
	_fd = data.fd
	_cache.addr = data.addr
	
	_heartBeatData = string.format("{\"hello\":\"world\"}")

	skynet.call(_gate, "lua", "forward", _fd)
end

local function cmd_forward(strData)
	sendMessage(strData)
end

local function cmd_forwardMultiple(msgList)
	for _, data in ipairs(msgList) do
		sendMessage(strData)
	end
end

local function cmd_setCache(session, sui, userID)
	_cache.session = session
	_cache.sui = sui
	_cache.userID = userID
end

local function cmd_clearCache()
	_cache.session = nil
	_cache.sui = nil
	_cache.userID = nil	
end

local function webSocketDispatch(session, address, strData)	
	skynet.error(string.format("%s, webSocketDispatch - ,session:%d,address:%d,strData:%s", SERVICE_NAME,session, address,strData))
	sendMessage(strData)
end

local conf = {
	methods = {
		["start"] = {["func"]=cmd_start, ["isRet"]=false},
		["exit"] = {["func"]=function() _criticalSection(exit()) end, ["isRet"]=false},
		["forward"] = {["func"]=cmd_forward, ["isRet"]=false},
		["forwardMultiple"] = {["func"]=cmd_forwardMultiple, ["isRet"]=false},
		["setCache"] = {["func"]=cmd_setCache, ["isRet"]=true},
		["clearCache"] = {["func"]=cmd_clearCache, ["isRet"]=true},
	},
	initFunc = function()		
		skynet.register_protocol {
			name = "wireWebSocketStr",
			id = skynet.PTYPE_CLIENT,
			unpack = netpack.tostring,
			dispatch = webSocketDispatch,
		}
	end,
}
commonServiceHelper.createService(conf)

