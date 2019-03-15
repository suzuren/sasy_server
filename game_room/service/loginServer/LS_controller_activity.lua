local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local activityBusiness = require "business.activity"
local addressResolver = require "addressResolver"

local REQUEST = {
	[0x000800] = function(tcpAgent, pbObj, tcpAgentData)
		return 0x000800, activityBusiness.queryScoreActivity(tcpAgentData.userID)
	end,
	[0x000801] = function(tcpAgent, pbObj, tcpAgentData)
		return 0x000801, activityBusiness.alms(tcpAgentData.userID)
	end,
	
}

local conf = {
	loginCheck = true,
	protocalHandlers = REQUEST,
}

pbServiceHelper.createService(conf)
