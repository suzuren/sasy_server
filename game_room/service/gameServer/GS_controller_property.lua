local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local GS_CONST = require "define.gsConst"
local addressResolver = require "addressResolver"

local _serverConfig

local REQUEST = {
	[0x010302] = function(tcpAgent, pbObj, tcpAgentData)
		if pbObj.propertyCount < 1 then
			return 0x010302, {code="RC_PROPERTY_COUNT_ERROR"}
		end	
		
		skynet.call(addressResolver.getAddressByServiceName("GS_model_property"), "lua", "buyProperty", tcpAgentData.sui, pbObj.propertyID, pbObj.propertyCount)
	end,
	
	[0x010304] = function(tcpAgent, pbObj, tcpAgentData)
		if (_serverConfig.ServerType & GS_CONST.GAME_GENRE.MATCH) ~= 0 then
			return 0x010304, {code="RC_MATCH"}
		end
		
		if (_serverConfig.ServerType & GS_CONST.GAME_GENRE.EDUCATE) ~= 0 then
			return 0x010304, {code="RC_EDUCATE"}
		end
		
		if pbObj.propertyCount < 1 then
			return 0x010302, {code="RC_PROPERTY_COUNT_ERROR"}
		end	
		
		skynet.call(addressResolver.getAddressByServiceName("GS_model_property"), "lua", "useProperty", tcpAgentData.sui, pbObj.propertyID, pbObj.propertyCount, pbObj.targetUserID)
	end,
	
	[0x010307] = function(tcpAgent, pbObj, tcpAgentData)
		if pbObj.trumpetID==GS_CONST.SMALL_TRUMPET_PROPERTY_ID then
			skynet.call(addressResolver.getAddressByServiceName("GS_model_property"), "lua", "sendSmallTrumpet", tcpAgentData.sui, pbObj.color, pbObj.msg)
		elseif pbObj.trumpetID==GS_CONST.BIG_TRUMPET_PROPERTY_ID then
			skynet.call(addressResolver.getAddressByServiceName("GS_model_property"), "lua", "sendBigTrumpet", tcpAgentData.sui, pbObj.color, pbObj.msg)
		else
			return 0x010307, {code="RC_ERROR_TRUMPETID"}
		end
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
	end
}

pbServiceHelper.createService(conf)

