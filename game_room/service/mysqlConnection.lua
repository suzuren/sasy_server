local skynet = require "skynet"
--local luasql = require "luasql.mysql"
local luamysql = require "skynet.db.mysql"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local sysConfig = require "sysConfig"
local inspect = require "inspect"

local _env = nul
local _conn = nil

-- this function never throw
local function disconnect()
	if _conn ~= nil then
		--_conn:close()
		_conn:disconnect()
		_conn = nil
	end

	if _env ~= nil then
		_env:close()
		_env = nil
	end
end

--[[
local function checkReturn(ret, errmsg)
	if ret==nil then
		skynet.send(addressResolver.getAddressByServiceName("mysqlConnectionPool"), "lua", "connectionError", skynet.self())
		error(errmsg)
	end
end
]]

local function checkReturn(ret, errmsg)
	if ret==false then
		if _conn==nil then
			skynet.send(addressResolver.getAddressByServiceName("mysqlConnectionPool"), "lua", "connectionError", skynet.self())
		end
		--error(errmsg)
	end
end

local function cmd_exit()
	disconnect()
	skynet.exit()
end

--[[
local function cmd_execute(sql)
	local ret, errmsg = _conn:execute(sql)
	checkReturn(ret, errmsg)
end
]]

local function cmd_execute(sql)
	local isSuccess, cursor = pcall(_conn.query,_conn,sql)
	checkReturn(isSuccess, cursor)
end

--[[
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
]]

local function cmd_query(sql)
	local isSuccess, cursor = pcall(_conn.query,_conn,sql)
	--skynet.error(string.format("%s cmd_insert - ",SERVICE_NAME),isSuccess, cursor,"\ncursor-\n",inspect(cursor))
	checkReturn(isSuccess, cursor)
	return cursor
end

--[[
local function cmd_insert(sql)
	local cursor, errmsg = _conn:execute(sql)
	checkReturn(cursor, errmsg)
	if type(cursor)~='number' then
		return nil
	end
	return _conn:getlastautoid()
end
]]

local function cmd_insert(sql)
	local isSuccess, cursor = pcall(_conn.query,_conn,sql)
	--skynet.error(string.format("%s cmd_insert - ",SERVICE_NAME),isSuccess, cursor,"\ncursor-\n",inspect(cursor))
	checkReturn(isSuccess, cursor)
	if isSuccess==true and cursor.server_status==2 and cursor.insert_id~=nil then
		return cursor.insert_id
	end
	return -1
end

--[[
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
]]

--[[
 {
	{
	   {
		  retCode = 1,
		  retMsg = "ÕÒ²»µ½t_huo_dong_time_config¼ÇÂ¼"
		}
	},
	{
		affected_rows = 0,
		insert_id = 0,
		server_status = 2,
		warning_count = 1
	},
	multiresultset = true
}
]]

local function cmd_call(sql)
	local isSuccess, cursor = pcall(_conn.query,_conn,sql)
	checkReturn(isSuccess, cursor)
	local rows = {}
	if isSuccess and cursor[2].server_status == 2 then
		rows = cursor[1][1]
	end
	--skynet.error(string.format("%s cmd_call - ",SERVICE_NAME),isSuccess, cursor,"\ncursor-\n",inspect(cursor),"\nrows-\n",inspect(rows))
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
		--[[
		_env = luasql.mysql()
		_conn = assert(_env:connect(
			sysConfig.mysqlInfo.mysqlDataBase,
			sysConfig.mysqlInfo.mysqlUser,
			sysConfig.mysqlInfo.mysqlPassword,
			sysConfig.mysqlInfo.mysqlHost
		))
		_conn:execute("set names 'utf8'")
		]]

		local function on_connect(dbconnect)
			dbconnect:query("set charset utf8");
		end
		local opts =
		{
			database		= sysConfig.mysqlInfo.mysqlDataBase,
			user			= sysConfig.mysqlInfo.mysqlUser,
			password		= sysConfig.mysqlInfo.mysqlPassword,
			host			= sysConfig.mysqlInfo.mysqlHost,
			port			= 3306,
			max_packet_size = 1024 * 1024,
			on_connect		= on_connect
		}
		_conn = assert(luamysql.connect(opts))
	end,
}
commonServiceHelper.createService(conf)


