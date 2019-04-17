local skynet = require "skynet"
local gateserver = require "utility.gateserver_ws"
local skynetHelper = require "skynetHelper"
local timerUtility = require "utility.timer"
local ipUtility = require "utility.ip"

local _connection = {}	-- fd -> connection : { fd , agent , ip, tick }
local _forwarding = {}	-- agent -> connection
local _tcpConnectionType
local _timeoutCheckData = {
	timerID = 0,
	threshold = 0,
	intervalTick = 0,
}

local function unforward(c)
	if c.agent then
		skynet.error(string.format("wsGateway.unforward: close fd=%d", c.fd))
		skynet.send(c.agent, "lua", "exit")
		_forwarding[c.agent] = nil
		c.agent = nil
	end
end

local function close_fd(fd)
	local c = _connection[fd]
	if c then
		unforward(c)
		_connection[fd] = nil
	end
end

local function onTimercheckTimeout()
	local currentTick = skynet.now()
	for fd, connData in pairs(_connection) do
		if currentTick - connData.tick > _timeoutCheckData.threshold then
			skynet.error(string.format("wsGateway.onTimercheckTimeout: close fd=%d", fd))
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
	unforward(c)
	c.agent = source
	_forwarding[c.agent] = c
	gateserver.openclient(fd)
end

function CMD.accept(source, fd)
	local c = assert(_connection[fd])
	unforward(c)
	gateserver.openclient(fd)
end

function CMD.kick(source, fd)
	gateserver.closeclient(fd)
end

function CMD.kickAll()
	for fd, _ in pairs(_connection) do
		gateserver.closeclient(fd)
	end
end

function CMD.initialize(source, type)
	if _tcpConnectionType~=nil then
		error(string.format("%s: 已经初始化过了", SERVICE_NAME))
	end
	_tcpConnectionType = type
	
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
	if c and c.agent then
		c.tick = skynet.now()
		skynet.redirect(c.agent, 0, "wireWebSocketStr", 0, msg, sz)
	else
		skynet.error("找不到数据包接收者")
		skynetHelper.free(msg)
		close_fd(fd)
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
	_forwarding[agent] = c
	skynet.send(agent, "lua", "start", {
		gateway = skynet.self(),
		fd = fd,
		addr = ipUtility.getAddressOfIP(addr),
		type = _tcpConnectionType
	})
end

function handler.disconnect(fd)
	close_fd(fd)
end

function handler.error(fd, msg)
	close_fd(fd)
end

function handler.command(cmd, source, ...)
	local f = assert(CMD[cmd])
	return f(source, ...)
end

gateserver.start(handler)
