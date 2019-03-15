local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local addressResolver = require "addressResolver"

local REQUEST = {
	[0x013000] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("GS_model_huoDong"), "lua", "ActivityInfoList", tcpAgent, tcpAgentData.userID)
	end,
	[0x013001] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("GS_model_huoDong"), "lua", "ExchangeActivityReward", tcpAgent, tcpAgentData, pbObj)
		return 0x013001, re
	end,
}

local conf = {
	loginCheck = true,
	protocalHandlers = REQUEST,
}

pbServiceHelper.createService(conf)

