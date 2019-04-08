local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local addressResolver = require "addressResolver"
local resourceResolver = require "resourceResolver"
local wordFilterUtility = require "wordfilter"
local mysqlutil = require "utility.mysqlHandle"
local ServerUserItem = require "sui"
local COMMON_CONST = require "define.commonConst"

local REQUEST = {
	[0x000600] = function(tcpAgent, pbObj, tcpAgentData)
		if pbObj.faceID >= 0xffff then
			error(string.format("%s protocal=0x000600 invalid faceID=%d", SERVICE_NAME, pbObj.faceID))
		end
		
		
		local sql = string.format("update `ssaccountsdb`.`AccountsInfo` set `FaceID`=%d where `UserID`=%d", pbObj.faceID, tcpAgentData.userID)
		local dbConn = addressResolver.getMysqlConnection()
		skynet.call(dbConn, "lua", "query", sql)
		ServerUserItem.setAttribute(tcpAgentData.sui, {faceID=pbObj.faceID})
		
		return 0x000600, {code="RC_OK"}
	end,
	[0x000601] = function(tcpAgent, pbObj, tcpAgentData)		
		local signatureLen = string.len(pbObj.signature)
		if signatureLen>=255 then
			return 0x000601, {code="RC_TOO_LONG"}
		end
			
		if signatureLen > 0 then
			local swfObj = resourceResolver.get("sensitiveWordFilter")
			if wordFilterUtility.hasMatch(swfObj, pbObj.signature) then
				return 0x000601, {code="RC_SENSITIVE_WORD_FOUND"}
			end
		end
				
		local sql
		if signatureLen==0 then
			sql = string.format("delete from `ssaccountsdb`.`AccountsSignature` where `UserID`=%d", tcpAgentData.userID)
		else
			sql = string.format(
				"insert `ssaccountsdb`.`AccountsSignature` (`UserID`, `Signature`) values (%d, '%s') on duplicate key update `Signature`=values(`Signature`)", 
				tcpAgentData.userID,
				mysqlutil.escapestring(pbObj.signature)
			)
		end
		
		local dbConn = addressResolver.getMysqlConnection()
		skynet.call(dbConn, "lua", "query", sql)
		ServerUserItem.setAttribute(tcpAgentData.sui, {signature=pbObj.signature})
		
		return 0x000601, {code="RC_OK"}
	end,
	[0x000602] = function(tcpAgent, pbObj, tcpAgentData)
		local nicknameLen = string.len(pbObj.nickName)
		if nicknameLen==0 or nicknameLen>31 then
			return 0x000602, {code="RC_INVALID_NICKNAME_LEN"}
		end
		
		local swfObj = resourceResolver.get("sensitiveWordFilter")
		if wordFilterUtility.hasMatch(swfObj, pbObj.nickName) then
			return 0x000602, {code="RC_SENSITIVE_WORD_FOUND"}
		end		
	
		local bFree = 0
		local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_CHANGE_NAME
		local bLimit = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "CheckIsForeverLimit",tcpAgentData.userID,limitId,1)
		if not bLimit then   
    		bFree = 1
        end

        local sql = string.format("call ssaccountsdb.sp_change_nickname(%d, '%s', %d)", tcpAgentData.userID, mysqlutil.escapestring(pbObj.nickName), bFree)
		local dbConn = addressResolver.getMysqlConnection()
		local rows = skynet.call(dbConn, "lua", "call", sql)
		local row = rows[1]
		row.retCode = tonumber(row.retCode)

		if row.retCode==0 then
			local attrToSet = {nickName=pbObj.nickName}
			ServerUserItem.setAttribute(tcpAgentData.sui, attrToSet)
			if bFree == 0 then
				skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",tcpAgentData.userID,
					COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,-100000,COMMON_CONST.ITEM_SYSTEM_TYPE.USE_CHANGE_NAME)
			else
				skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "AddLimit",tcpAgentData.userID,limitId,1)
			end

			local attr = ServerUserItem.getAttribute(tcpAgentData.sui, {"serverID"})
			if attr.serverID ~= 0 then
				skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", {attr.serverID}, 
					COMMON_CONST.LSNOTIFY_EVENT.EVT_LSNOTIFY_GS_CHANGE_USER_NAME, 
					{
						userID = tcpAgentData.userID,
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
						goodsCount = -100000,
						bFree = bFree,
						nickName = pbObj.nickName,
					})
			end
			
			return 0x000602, {code="RC_OK"}
		elseif row.retCode==2 then
			return 0x000602, {code="RC_SAME_NICKNAME"}
		elseif row.retCode==3 then
			return 0x000602, {code="RC_NICKNAME_ALREADY_USED"}			
		elseif row.retCode==4 then
			return 0x000602, {code="RC_NOT_ENOUGH_SCORE", msg=row.retMsg}
		end
	end,
	[0x000603] = function(tcpAgent, pbObj, tcpAgentData)
		local swfObj = resourceResolver.get("sensitiveWordFilter")
		if wordFilterUtility.hasMatch(swfObj, pbObj.nickName) then
			return 0x000603, {code="RC_SENSITIVE_WORD_FOUND"}
		end
		
		local sql = string.format("call ssaccountsdb.sp_is_nickname_used('%s')", mysqlutil.escapestring(pbObj.nickName))
		local dbConn = addressResolver.getMysqlConnection()
		local rows = skynet.call(dbConn, "lua", "call", sql)
		local ret = tonumber(rows[1].ret)
		if ret==0 then
			return 0x000603, {code="RC_OK"}
		else
			return 0x000603, {code="RC_NICKNAME_ALREADY_USED"}
		end
	end,
	[0x000604] = function(tcpAgent, pbObj, tcpAgentData)
		if pbObj.gender >= 127 then
			error(string.format("%s protocal=0x000604 invalid gender=%d", SERVICE_NAME, pbObj.gender))
		end
		
		local sql = string.format("UPDATE `ssaccountsdb`.`AccountsInfo` SET `Gender`=%d WHERE `UserID`=%d", pbObj.gender, tcpAgentData.userID)
		local dbConn = addressResolver.getMysqlConnection()
		skynet.call(dbConn, "lua", "query", sql)
		ServerUserItem.setAttribute(tcpAgentData.sui, {gender=pbObj.gender})
		
		return 0x000604, {code="RC_OK"}
	end,
	[0x000605] = function(tcpAgent, pbObj, tcpAgentData)
		if string.len(pbObj.platformFace) ~= 32 then
			error(string.format("%s protocal=0x000605 invalid platformFace=%s", SERVICE_NAME, tostring(pbObj.platformFace)))
		end
		
		local sql = string.format("call ssaccountsdb.sp_set_platform_face(%d, '%s')", tcpAgentData.userID, mysqlutil.escapestring(pbObj.platformFace))
		local dbConn = addressResolver.getMysqlConnection()
		skynet.call(dbConn, "lua", "call", sql)
		ServerUserItem.setAttribute(tcpAgentData.sui, {platformFace=pbObj.platformFace})
		
		return 0x000605, {code="RC_OK"}
	end,

	[0x000606] = function(tcpAgent, pbObj, tcpAgentData)
		local userAttr = ServerUserItem.getAttribute(tcpAgentData.sui, {"platformID"})
		skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "bindingAccount", userAttr.platformID)
		return 0x000606, {code="RC_OK"}
	end,
}

local conf = {
	loginCheck = true,
	protocalHandlers = REQUEST,
	initFunc = function()
		resourceResolver.init()
	end,
}

pbServiceHelper.createService(conf)
