local skynet = require "skynet"
local luasql = require "luasql.mysql"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local sysConfig = require "sysConfig"
local _env, _conn, _addressResvoler

-- this function never throw
local function disconnect()
	if _conn ~= nil then
		_conn:close()
		_conn = nil
	end

	if _env ~= nil then
		_env:close()
		_env = nil
	end
end


local function checkReturn(ret, errmsg)
	if ret==nil then
		skynet.send(addressResolver.getAddressByServiceName("mysqlConnectionPool"), "lua", "connectionError", skynet.self())
		error(errmsg)
	end
end

local function cmd_exit()
	disconnect()
	skynet.exit()
end


local function cmd_execute(sql)
	local ret, errmsg = _conn:execute(sql)
	checkReturn(ret, errmsg)
end


local function cmd_query(sql)
	local cursor, errmsg = _conn:execute(sql)
	checkReturn(cursor, errmsg)
	
	if type(cursor)=='number' then
		return cursor
	end

	local rows = {}
	while true do
		local row = cursor:fetch({}, 'a')
		if row then
			table.insert(rows, row)
		else
			break;
		end
	end
	cursor:close()
	return rows
end

local function cmd_insert(sql)
	local cursor, errmsg = _conn:execute(sql)
	checkReturn(cursor, errmsg)
	if type(cursor)~='number' then
		return nil
	end

	return _conn:getlastautoid()
end

local function cmd_call(sql)
	local cursor, errmsg = _conn:callprocedure(sql)
	checkReturn(cursor, errmsg)	
	local rows = {}
	while true do
		local row = cursor:fetch({}, 'a')
		if row then
			table.insert(rows, row)
		else
			break;
		end
	end
	cursor:close()
	return rows
end

local conf = {
	methods = {
		["exit"] = {["func"]=cmd_exit, ["isRet"]=false},
		["execute"] = {["func"]=cmd_execute, ["isRet"]=false},
		["query"] = {["func"]=cmd_query, ["isRet"]=true},
		["insert"] = {["func"]=cmd_insert, ["isRet"]=true},
		["call"] = {["func"]=cmd_call, ["isRet"]=true},
	},
	initFunc = function() 
		_env = luasql.mysql()
		_conn = assert(_env:connect(
			sysConfig.mysqlInfo.mysqlDataBase,
			sysConfig.mysqlInfo.mysqlUser,
			sysConfig.mysqlInfo.mysqlPassword,
			sysConfig.mysqlInfo.mysqlHost
		))
		_conn:execute("set names 'utf8'")
	end,
}
commonServiceHelper.createService(conf)

