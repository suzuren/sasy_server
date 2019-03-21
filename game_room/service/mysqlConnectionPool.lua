local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"

local _pool = {}
local _poolSize = 0
local _iterator = 0
local _timeOutTick = 0

local function createConnection()
	table.insert(
		_pool,
		{
			["conn"] = skynet.newservice("mysqlConnection"),
			["tick"] = skynet.now(),
		}
	)
end


local function cmd_getConnection()
	local realPoolSize = #_pool
	
	if realPoolSize < _poolSize then
		createConnection()
		realPoolSize = realPoolSize + 1
	end
	
	_iterator = _iterator + 1
	if _iterator > realPoolSize then
		_iterator = 1
	end

	local item = _pool[_iterator]
	local nowTick = skynet.now()
	if nowTick - item.tick >= _timeOutTick then
		skynet.error(string.format("%s: mysql connection %s time out", SERVICE_NAME, tostring(item.conn)))
		skynet.send(item.conn, "lua", "exit")
		item.conn = skynet.newservice("mysqlConnection")
	end
	item.tick = nowTick

	return item.conn
end

local function cmd_connectionError(address)
	for i, item in ipairs(_pool) do
		if item.conn == address then
			table.remove(_pool, i)
			break
		end
	end
	skynet.send(address, "lua", "exit")
	createConnection()
end


local conf = {
	methods = {
		["getConnection"] = {["func"]=cmd_getConnection, ["isRet"]=true},
		["connectionError"] = {["func"]=cmd_connectionError, ["isRet"]=false},
	},
	initFunc = function()
		_poolSize = tonumber(skynet.getenv("mysqlPoolSize"))
		if _poolSize==nil or _poolSize<1 then
			error(string.format("%s: invalid pool size: %s", SERVICE_NAME, tostring(_poolSize)))
		end
		
		_timeOutTick = tonumber(skynet.getenv("mysqlConnectionTimeOut"))
		if _timeOutTick==nil or _timeOutTick<=0 then
			error(string.format("%s: invalid connection timeout: %s", SERVICE_NAME, tostring(_timeOutTick)))
		end
		_timeOutTick = _timeOutTick * 100
		
		for i=1, _poolSize do
			createConnection()
		end
	end,
}

commonServiceHelper.createService(conf)


