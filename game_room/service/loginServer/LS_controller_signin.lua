local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local addressResolver = require "addressResolver"

local REQUEST = {
	[0x001000] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("LS_model_signin"), "lua", "SigninListInfo", tcpAgent, tcpAgentData.userID)
	end,
	[0x001001] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_signin"), "lua", "Sign", tcpAgent, tcpAgentData.userID, tcpAgentData.sui, pbObj.signType, pbObj.dayID)
		return 0x001001, re
	end,
}

local conf = {
	loginCheck = true,
	protocalHandlers = REQUEST,
}

pbServiceHelper.createService(conf)

