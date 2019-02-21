local skynet = require "skynet"
local socket = require "socket"
local ipUtility = require "utility.ip"

local _pool = {}
local _poolSize = tonumber(skynet.getenv("httpWorkerPoolSize"))
local _iterator = 0

skynet.start(function()
	local address = skynet.getenv("httpAddress")
	local port = tonumber(skynet.getenv("httpPort"))

	if type(address)~="string" or #address==0 then
		error(string.format("invalid address (%s) for http to listen", tostring(address)))
	end

	if type(port)~="number" or port<1024 or port>65535 then
		error(string.format("invalid port (%s) for http to listen", tostring(port)))
	end

	if type(_poolSize)~="number" or _poolSize<1 then
		error(string.format("invalid pool size: %s", tostring(_poolSize)))
	end

	for i=1,_poolSize do
		local workAddress = skynet.newservice("LS_httpWorker")
		table.insert(_pool, workAddress)
		--skynet.error(string.format("i-%d,SERVICE_NAME-%s,workAddress-:%08x",i, SERVICE_NAME, workAddress))
	end

	local socketId = socket.listen(address, port)
	skynet.error(string.format("%s listen on %s:%d", SERVICE_NAME, address, port))
	socket.start(socketId , function(connectionId, addr)
		_iterator = _iterator + 1
		if _iterator > _poolSize then
			_iterator = 1
		end
		local workAddress = _pool[_iterator]
		skynet.error(string.format("%s connected, pass it to agent :%08x", addr, workAddress))
		skynet.send(workAddress, "lua", connectionId, ipUtility.getAddressOfIP(addr))
	end)
end)

