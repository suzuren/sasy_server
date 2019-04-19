local skynet = require "skynet"
local gateserver = require "utility.gateserver_ws"
local timerUtility = require "utility.timer"
local ipUtility = require "utility.ip"

local _connection = {}	-- fd -> connection : { fd , agent , ip, tick }
local _forwarding = {}	-- agent -> connection
local _wsConnectionType
local _timeoutCheckData = {
	timerID = 0,
	threshold = 0,
	intervalTick = 0,
}

local function unforward(c)
	skynet.error(string.format("%s unforward agent",SERVICE_NAME), c.agent)
	if c.agent then
		skynet.error(string.format("%s unforward close fd=%d",SERVICE_NAME, c.fd))
		print("aaaaaaaaaaaaaaaaaaaaa")
		skynet.send(c.agent, "lua", "exit")
		print("bbbbbbbbbbbbbbbbbbbbb")
		_forwarding[c.agent] = nil
		c.agent = nil
	end
end

local function close_fd(fd)
	local c = _connection[fd]
	skynet.error(string.format("%s, close_fd - fd:%d", SERVICE_NAME,fd), c)
	print("ffffffffffffffffffffffffff")
	if c then
	print("cccccccccccccccccccccc")
		unforward(c)
		print("ddddddddddddddddddddddddd")
		_connection[fd] = nil
	end
	print("eeeeeeeeeeeeeeeeeeeee")
end

local function onTimercheckTimeout()
	local currentTick = skynet.now()
	for fd, connData in pairs(_connection) do
		if currentTick - connData.tick > _timeoutCheckData.threshold then
			--skynet.error(string.format("wsGateway.onTimercheckTimeout: close fd=%d", fd))
			--gateserver.closeclient(fd)
			--close_fd(fd)
		end
	end
end

skynet.register_protocol {
	name = "wireWebSocketStr",
	id = skynet.PTYPE_CLIENT,
}

local CMD = {}
function CMD.forward(source, fd)
	local c = assert(_connection[fd])
	skynet.error(string.format("%s, forward - fd:%d", SERVICE_NAME,fd), c)
	unforward(c)
	c.agent = source
	_forwarding[c.agent] = c
	gateserver.openclient(fd)
end

function CMD.accept(source, fd)
	skynet.error(string.format("%s, accept -fd:%d", SERVICE_NAME,fd))
	local c = assert(_connection[fd])
	unforward(c)
	gateserver.openclient(fd)
end

function CMD.kick(source, fd)
	skynet.error(string.format("%s, kick -fd:%d", SERVICE_NAME,fd))
	gateserver.closeclient(fd)
end

function CMD.kickAll()
	for fd, _ in pairs(_connection) do
		gateserver.closeclient(fd)
	end
end

function CMD.initialize(source, type)
	if _wsConnectionType~=nil then
		error(string.format("%s: 已经初始化过了", SERVICE_NAME))
	end
	_wsConnectionType = type
	
	_timeoutCheckData.threshold = 13
	if not _timeoutCheckData.threshold or _timeoutCheckData.threshold <= 0 then
		error(string.format("%s: 心跳检测阈值错误: %s", SERVICE_NAME, tostring(_timeoutCheckData.threshold)))
	end
	_timeoutCheckData.threshold = _timeoutCheckData.threshold * 100
	
	_timeoutCheckData.intervalTick = 5
	if not _timeoutCheckData.intervalTick or _timeoutCheckData.intervalTick <= 0 then
		error(string.format("%s: 心跳检测周期错误: %s", SERVICE_NAME, tostring(checkInterval)))
	end
	_timeoutCheckData.intervalTick = _timeoutCheckData.intervalTick * 100	
	
	timerUtility.start(_timeoutCheckData.intervalTick)
	_timeoutCheckData.timerID = timerUtility.setInterval(onTimercheckTimeout, 1)
end

local handler = {}
function handler.message(fd, msg, sz)
	-- recv a package, forward it
	local c = _connection[fd]
	skynet.error(string.format("%s, message - fd:%d", SERVICE_NAME,fd),c)
	if c then
		print("gggggggggggggg,",c.agent)
	end
	print("hhhhhhhhhhhhhhhhhhhhhhhh")
	if c and c.agent then
		c.tick = skynet.now()
		skynet.redirect(c.agent, 0, "wireWebSocketStr", 0, msg, sz)
	else
		print("iiiiiiiiiiiiiiiiiiiiiiiii")
		close_fd(fd)
		print("jjjjjjjjjjjjjjjjjjjjjjj")
	end
end

function handler.connect(fd, addr)
	local c = {
		fd = fd,
		agent = nil,
		ip = addr,
		tick = skynet.now(),
	}
	_connection[fd] = c

	local agent = skynet.newservice("wsConnection")
	--skynet.error(string.format("%s - connect - ", SERVICE_NAME),agent,skynet.self())

	_forwarding[agent] = c
	skynet.send(agent, "lua", "start", {
		gateway = skynet.self(),
		fd = fd,
		addr = ipUtility.getAddressOfIP(addr),
		type = _wsConnectionType
	})
end

function handler.disconnect(fd)
	skynet.error(string.format("%s, disconnect - fd:%d", SERVICE_NAME,fd))
	print("kkkkkkkkkkkkkkkkk")
	close_fd(fd)
	print("llllllllllllllllllllll")
end

function handler.wsdisconnect(fd)
	skynet.error(string.format("%s, wsdisconnect - fd:%d", SERVICE_NAME,fd))
end

function handler.error(fd, msg)
	skynet.error(string.format("%s, error - fd:%d", SERVICE_NAME,fd))
	close_fd(fd)
end

function handler.command(cmd, source, ...)
	local f = assert(CMD[cmd])
	return f(source, ...)
end

gateserver.start(handler)
