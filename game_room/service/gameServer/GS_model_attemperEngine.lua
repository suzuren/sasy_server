local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local GS_CONST = require "define.gsConst"
local ServerUserItem = require "sui"
local addressResolver = require "addressResolver"
local resourceResolver = require "resourceResolver"

local _serverConfig
local function broadcastUserScore(userItem)
	local userAttr = ServerUserItem.getAttribute(userItem, {
		"userID",
		"score",
		"insure",
		"grade",
		"medal",
		"gift",
		"present",
		"experience",
		"loveliness",
		
		"winCount",
		"lostCount",
		"drawCount",
		"fleeCount",
		
		"trusteeScore",
		"frozenedScore",
	})
	userAttr.score = userAttr.score + userAttr.trusteeScore + userAttr.frozenedScore
	userAttr.trusteeScore = nil
	userAttr.frozenedScore = nil
	
	local pbParser = resourceResolver.get("pbParser")
	local packetStr = skynet.call(pbParser, "lua", "encode", 0x01ff01, userAttr, true)
	if packetStr then
		skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "broadcast", packetStr)
	end	
end

local function writeVariation(userItem)
	local userAttr = ServerUserItem.getAttribute(userItem, {"userID"})	
	local isModified, tmp = ServerUserItem.distillVariation(userItem)
	if not isModified then
		return true
	end

	local variationInfo = tmp.variationInfo
	local sql = string.format(
		"call kftreasuredb.sp_write_score(%d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d)",
		userAttr.userID,
		variationInfo.revenue,
		variationInfo.score,
		variationInfo.insure,
		variationInfo.grade,
		variationInfo.medal,
		variationInfo.gift,
		variationInfo.present,
		variationInfo.experience,
		variationInfo.loveliness,
		variationInfo.playTimeCount,
		variationInfo.winCount,
		variationInfo.lostCount,
		variationInfo.drawCount,
		variationInfo.fleeCount
	)
	
	local result
	local mysqlConn = addressResolver.getMysqlConnection()
	local ret = skynet.call(mysqlConn, "lua", "call", sql)[1]
	if tonumber(ret.retCode) ~= 0 then		
		skynet.error(string.format("%s: 游戏数据写库错误: userID=%d %s", SERVICE_NAME, userAttr.userID, tostring(ret.retMsg)))
		result = false
	else
		result = true
	end	
	
	return result
end

local function cmd_writeVariation(userItem)
	local result
	if (_serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_IMMEDIATE_WRITE_SCORE)~= 0 then
		result = writeVariation(userItem)
	end
	
	if result then
		broadcastUserScore(userItem)
	end
end

local function cmd_writeVariationWithoutNotify(userItem)
	writeVariation(userItem)
end

local conf = {
	methods = {
		["writeVariation"] = {["func"]=cmd_writeVariation, ["isRet"]=true},
		["writeVariationWithoutNotify"] = {["func"]=cmd_writeVariationWithoutNotify, ["isRet"]=true},
		["broadcastUserScore"] = {["func"]=function(...) broadcastUserScore(...) end, ["isRet"]=true},
	},
	-- CAttemperEngineSink::OnAttemperEngineStart
	initFunc = function()
		_serverConfig = skynet.call(addressResolver.getAddressByServiceName("GS_model_serverStatus"), "lua", "getServerData")
		if not _serverConfig then
			error("server config not initialized")
		end
		resourceResolver.init()
	end,
}

commonServiceHelper.createService(conf)
