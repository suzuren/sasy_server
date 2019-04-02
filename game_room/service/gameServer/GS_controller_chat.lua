local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local GS_CONST = require "define.gsConst"
local COMMON_CONST = require "define.commonConst"
local ServerUserItem = require "sui"
local mysqlutil = require "utility.mysqlHandle"
local addressResolver = require "addressResolver"
local resourceResolver = require "resourceResolver"
local wordFilterUtility = require "wordfilter"

local _serverConfig

local _messageCache = {}

local function logMessage(userID, tableID, msg,payRmb,useridList)
	local mysqlConn = addressResolver.getMysqlConnection()
	local sql = string.format(
		"insert into `kfrecorddb`.`Chat`(`ServerID`, `TableID`, `SendUserID`, `Ctime`, `Message`,`PayRmb`,`UserIdList`) values (%d, %d, %d, now(), '%s',%d,'%s')",
		_serverConfig.ServerID,
		tableID,
		userID,
		mysqlutil.escapestring(msg),
		payRmb,
		mysqlutil.escapestring(useridList)
	)
	skynet.send(mysqlConn, "lua", "execute", sql)		
end

local function prepareChat(agent, userItem)
	local userAttr = ServerUserItem.getAttribute(userItem, {"userID", "userRight", "tableID", "nickName", "loveliness","contribution"})
	 
	local tableAddress = addressResolver.getTableAddress(userAttr.tableID)
	if not tableAddress then
		return false
	end
	
	if (_serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_FORFEND_GAME_CHAT)~=0 then
		skynet.send(agent, "lua", "forward", 0xff0000, {
			type = COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_EJECT,
			msg = "抱歉，当前游戏房间禁止游戏聊天！",
		})
		return false
	end
	
	if (userAttr.userRight & GS_CONST.USER_RIGHT.UR_CANNOT_ROOM_CHAT)~=0 then
		skynet.send(agent, "lua", "forward", 0xff0000, {
			type = COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_EJECT,
			msg = "抱歉，您没有游戏聊天的权限，若需要帮助，请联系游戏客服咨询！",
		})
		return false
	end
	
	if userAttr.loveliness < 0 then
		skynet.send(agent, "lua", "forward", 0xff0000, {
			type = COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_EJECT,
			msg = "抱歉，魅力值小于0，禁止发言！",
		})
		return false
	end

	return true, userAttr, tableAddress
end


local REQUEST = {
	[0x010400] = function(tcpAgent, pbObj, tcpAgentData)
		local isSuccess, userAttr, tableAddress = prepareChat(tcpAgent, tcpAgentData.sui)
		if not isSuccess then
			return
		end

		local swfObj = resourceResolver.get("sensitiveWordFilter")
		if wordFilterUtility.hasMatch(swfObj, pbObj.content) then
			return
		end	

		local useridList = skynet.call(addressResolver.getTableAddress(userAttr.tableID), "lua", "getTableUserIdList")
		logMessage(userAttr.userID, userAttr.tableID, pbObj.content,userAttr.contribution,useridList)
	
		pbObj.content = wordFilterUtility.doFiltering(swfObj, pbObj.content)
		
		local pbParser = resourceResolver.get("pbParser")
		local pbStr = skynet.call(pbParser, "lua", "encode", 0x010400, {
			color=pbObj.color,
			sendUserID=userAttr.userID,
			sendNickname=userAttr.nickName,
			content=pbObj.content
		}, true)
		
		skynet.send(tableAddress, "lua", "broadcastTable", pbStr)

		--skynet.send(tcpAgent, "lua", "forward", pbStr)

	end,
	[0x010401] = function(tcpAgent, pbObj, tcpAgentData)
		local isSuccess, userAttr, tableAddress = prepareChat(tcpAgent, tcpAgentData.sui)
		if not isSuccess then
			return
		end

		local useridList = skynet.call(addressResolver.getTableAddress(userAttr.tableID), "lua", "getTableUserIdList")
		logMessage(userAttr.userID, userAttr.tableID, string.format("expressID=%d", pbObj.expressID),userAttr.contribution,useridList)
		
		local pbParser = resourceResolver.get("pbParser")
		local pbStr = skynet.call(pbParser, "lua", "encode", 0x010401, {
			expressID=pbObj.expressID,
			sendUserID=userAttr.userID,
			sendNickname=userAttr.nickName,
		}, true)
		
		skynet.send(tableAddress, "lua", "broadcastTable", pbStr)
	end,
	[0x010402] = function(tcpAgent, pbObj, tcpAgentData)
		local isSuccess, userAttr, tableAddress = prepareChat(tcpAgent, tcpAgentData.sui)
		if not isSuccess then
			return
		end

		local useridList = skynet.call(addressResolver.getTableAddress(userAttr.tableID), "lua", "getTableUserIdList")
		logMessage(userAttr.userID, userAttr.tableID, string.format("type=%d url=%s", pbObj.type, pbObj.url),userAttr.contribution,useridList)
		
		local pbParser = resourceResolver.get("pbParser")
		local pbStr = skynet.call(pbParser, "lua", "encode", 0x010402, {
			type=pbObj.type,
			url=pbObj.url,
			sendUserID=userAttr.userID,
			sendNickname=userAttr.nickName,
		}, true)
		
		skynet.send(tableAddress, "lua", "broadcastTable", pbStr)
	end,	
	
}

local conf = {
	loginCheck = true,
	protocalHandlers = REQUEST,
	initFunc = function()
		_serverConfig = skynet.call(addressResolver.getAddressByServiceName("GS_model_serverStatus"), "lua", "getServerData")
		if not _serverConfig then
			error("server config not initialized")
		end
		resourceResolver.init()
	end
}

pbServiceHelper.createService(conf)
