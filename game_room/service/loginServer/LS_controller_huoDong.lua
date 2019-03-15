local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local addressResolver = require "addressResolver"

local REQUEST = {
	[0x006000] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("LS_model_huoDong"), "lua", "ActivityInfoList", tcpAgent, tcpAgentData.userID)
	end,
	[0x006001] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_huoDong"), "lua", "ExchangeActivityReward", tcpAgent, tcpAgentData, pbObj)
		return 0x006001, re
	end,
	[0x006003] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("LS_model_huoDong"), "lua", "RedPacketInfo", tcpAgent, tcpAgentData.userID)
	end,
}

local conf = {
	loginCheck = true,
	protocalHandlers = REQUEST,
}

pbServiceHelper.createService(conf)

