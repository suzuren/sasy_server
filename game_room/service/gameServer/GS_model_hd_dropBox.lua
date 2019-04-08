local skynet = require "skynet"
local addressResolver = require "addressResolver"
local commonServiceHelper = require "serviceHelper.common"

local config
local ServerID = 0
local _AddScore = 0
local _DelScore = 0

local function loadData()
	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("SELECT * FROM `ssfishdb`.`t_hd_drop_box` WHERE ServerID=%d",ServerID)
	local rows = skynet.call(dbConn,"lua","query",sql)
	if rows[1] ~= nil then
		_AddScore = tonumber(rows[1].AddScore)
		_DelScore = tonumber(rows[1].DelScore)
	end
end

local function cmd_changeScore(score,addFalg)
	if not config.isEnable then
		return false
	end

	if addFalg then
		_AddScore = _AddScore + score
	else
		_DelScore = _DelScore + score
	end

	if _DelScore-_AddScore >= config.openNeedScore then
		return true
	end

	return false
end

local function cmd_savedata()
	if not config.isEnable then
		return
	end
	
	local sql = string.format("INSERT INTO `ssfishdb`.`t_hd_drop_box` VALUES (%d,%d,%d) ON DUPLICATE KEY UPDATE `AddScore`=VALUES(`AddScore`),`DelScore`=VALUES(`DelScore`)",
		ServerID, _AddScore,_DelScore)
	
	local mysqlConn = addressResolver:getMysqlConnection()
	skynet.call(mysqlConn, "lua", "query", sql)
end

local function cmd_resetScore()
	_AddScore = 0
	_DelScore = 0
end

local function cmd_getScore()
	return _DelScore-_AddScore
end

local conf = {
	methods = {
		["changeScore"] = {["func"]=cmd_changeScore, ["isRet"]=true},
		["savedata"] = {["func"]=cmd_savedata, ["isRet"]=false},
		["resetScore"] = {["func"]=cmd_resetScore, ["isRet"]=false},
		["getScore"] = {["func"]=cmd_getScore, ["isRet"]=true},
	},

	initFunc = function()
		local serverConfig = skynet.call(addressResolver.getAddressByServiceName("GS_model_serverStatus"),"lua","getServerData")
		if not serverConfig then
			error("HD_DropBox-----serverConfig-----is----error---")
		end
		ServerID = serverConfig.ServerID

		local isFishRoom = skynet.call(addressResolver.getAddressByServiceName("GS_model_serverStatus"),"lua","isFishRoom",ServerID)
		if isFishRoom then
			local _config = require(string.format("config.fish_%d",ServerID))
			if not _config then
				error("HD_DropBox----config----is----error")
			end
			
			config = _config.hdDropBox
			loadData()
		end
	end,
}

commonServiceHelper.createService(conf)


