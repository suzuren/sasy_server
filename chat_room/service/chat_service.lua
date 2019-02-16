local skynet = require "skynet"
local socket = require "chat_socket"
local socketmanager = require "manager_socket"

local parsedata = require "parsedata"

local mode , id = ...
local queue	= ""	-- message queue

local function echo(id)
	socket.start(id)
	while true do
		local str = socket.read(id)
		--print("chat_service.lua - id, str - ",id, str)		
		if str then
			--print("chat_service.lua - id, str - ",id, str)
			queue = queue..str
			local err, id, size, buffer, last, remain = parsedata.parsepacket(id, queue);
			queue = remain
			print("chat_service.lua - err, id, size, #buffer, last, #queue - ", err, id, size, #buffer, last, #queue)
			if err==1 then
				socket.write(id, buffer)
			end
		else
			print("chat_service.lua - socket.close id, str - ",id, str)
			socket.close(id)
			return
		end
	end
end


local function echo_chat(id)
	socket.start(id)
	while true do
		local size, uin, cmd, len, msg = socket.read_chat(id)
		--print("chat_service.lua echo_chat - id, size, uin, cmd, len, msg, #ret - ",id, size, uin, cmd, len, msg)
		if size ~= 0 then
			--socket.write_chat(id, uin, cmd, len, msg)
			socketmanager.putclient(socket, id, uin, cmd, len, msg)
		else
			socket.close(id)
			socketmanager.popclient(id)
			return
		end
	end
end


if mode == "agent" then
	id = tonumber(id)

	skynet.start(function()
		skynet.fork(function()
			echo(id)
			skynet.exit()
		end)
	end)
else
	local function accept(id)
		socket.start(id)
		socket.write(id, "Hello Skynet\n")
		skynet.newservice(SERVICE_NAME, "agent", id)
		-- notice: Some data on this connection(id) may lost before new service start.
		-- So, be careful when you want to use start / abandon / start .
		socket.abandon(id)
	end

	skynet.start(function()
		local id = socket.listen("127.0.0.1", 8001)
		print(SERVICE_NAME.. " service Listen socket :", "127.0.0.1", 8001)

		socket.start(id , function(id, addr)
			print("connect from " .. addr .. " " .. id)
			socketmanager.setclient(id)
			-- you have choices :
			-- 1. skynet.newservice("chat_service", "agent", id)
			-- 2. skynet.fork(echo, id)
			-- 3. accept(id)
			--accept(id)
			skynet.fork(echo_chat, id)
		end)
	end)
end