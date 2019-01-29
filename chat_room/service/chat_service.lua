local skynet = require "skynet"
local socket = require "chat_socket"

local parsedata = require "parsedata"

local mode , id = ...
local queue	= ""	-- message queue

local function echo(id)
	socket.start(id)

	while true do
		local str = socket.read(id)		
		--print("testsocket.lua - id, str - ",id, str)		
		if str then
			--print("testsocket.lua - id, str - ",id, str)
			queue = queue..str
			local err, id, size, buffer, last, remain = parsedata.parsepacket(id, queue);
			queue = remain
			print("testsocket.lua - err, id, size, #buffer, last, #queue - ", err, id, size, #buffer, last, #queue)
			if err==1 then
				socket.write(id, buffer)
			end
		else
			print("testsocket.lua - socket.close id, str - ",id, str)
			socket.close(id)
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
			-- you have choices :
			-- 1. skynet.newservice("testsocket", "agent", id)
			-- 2. skynet.fork(echo, id)
			-- 3. accept(id)
			--accept(id)
			skynet.fork(echo, id)
		end)
	end)
end