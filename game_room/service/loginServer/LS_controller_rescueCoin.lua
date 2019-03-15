local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local addressResolver = require "addressResolver"

local REQUEST = {
	[0x002000] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_rescueCoin"), "lua", "RequestRescueCoin", tcpAgent,tcpAgentData)
		return 0x002000, re
	end,
	[0x002001] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_rescueCoin"), "lua", "RescueCoinSynchronizeTime", tcpAgent,tcpAgentData)
		return 0x002001, re
	end,
	[0x002002] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_rescueCoin"), "lua", "ReceiveRescueCoin", tcpAgent,tcpAgentData)
		return 0x002002, re
	end,
}

local conf = {
	loginCheck = true,
	protocalHandlers = REQUEST,
}

pbServiceHelper.createService(conf)
