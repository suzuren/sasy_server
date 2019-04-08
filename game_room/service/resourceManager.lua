local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"

local _data = {}

local _initializer = {
	sensitiveWordFilter = function(poolSize)		
		if type(poolSize)~="number" or poolSize < 1 then
			error(string.format("敏感词过滤器池大小错误: poolSize = %s", tostring(poolSize)))
		end
		
		local dataItem = {pool={}, poolSize=poolSize, iterator=1}
		
		local wordFilter = require "wordfilter"
		local filter = wordFilter.new()
		local dbConn = addressResolver.getMysqlConnection()
		local sql = "SELECT `Word` FROM `ssplatformdb`.`SensitiveWords`"
		local rows = skynet.call(dbConn, "lua", "query", sql)	
		for _, row in ipairs(rows) do
			wordFilter.addWord(filter, row.Word)
		end
		table.insert(dataItem.pool, filter)
		for i=1, poolSize-1 do
			table.insert(dataItem.pool, wordFilter.copy(filter))
		end
		
		_data.sensitiveWordFilter = dataItem
	end,
	pbParser = function(mode, poolSize)
		if type(poolSize)~="number" or poolSize < 1 then
			error(string.format("pbParser池大小错误: poolSize = %s", tostring(poolSize)))
		end
		
		local dataItem = {pool={}, poolSize=poolSize, iterator=1}
		
		for i=1, poolSize do
			local parser = skynet.newservice("pbParser")
			skynet.call(parser, "lua", "start", mode)
			table.insert(dataItem.pool, parser)
		end
		
		_data.pbParser = dataItem
	end,
	
}
-- skynet.call(resManager, "lua", "initialize", "pbParser", "loginServer", tonumber(skynet.getenv("resManager_pbParserPoolSize")))
local function cmd_get(kind, hint)
	local item = _data[kind]
	if not item then
		error(string.format("没有这类资源: %s", tostring(kind)))
	end
	
	local pacer
	if hint==nil then
		item.iterator = item.iterator + 1
		if item.iterator > item.poolSize then
			item.iterator = 1
		end
		pacer = item.iterator
	else
		pacer = (hint % item.poolSize) + 1
	end
	
	return item.pool[pacer]
end

local function cmd_initialize(kind, ...)
	if _data[kind] ~= nil then
		error(string.format("%s 已经初始化过了", kind))
	end	
	
	local initializer = _initializer[kind]
	
	if initializer == nil then
		error(string.format("找不到这类资源的初始化过程: %s", tostring(kind)))
	end
	initializer(...)
end



local conf = {
	methods = {
		["get"] = {["func"]=cmd_get, ["isRet"]=true},
		["initialize"] = {["func"]=cmd_initialize, ["isRet"]=true},
	}
}

commonServiceHelper.createService(conf)
