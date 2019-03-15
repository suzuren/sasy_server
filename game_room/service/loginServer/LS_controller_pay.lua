local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local addressResolver = require "addressResolver"

local REQUEST = {
	[0x000500] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "queryPayOrderItem", tcpAgent, tcpAgentData.userID)
	end,
	[0x000501] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "PaymentNotify", tcpAgent, tcpAgentData.userID)
	end,
	[0x000502] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "queryFreeScore", tcpAgentData.userID)
		return 0x000502, re
	end,
	[0x000503] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "getFreeScore", tcpAgentData.userID, tcpAgentData.sui)
		return 0x000503, re
	end,
	[0x000504] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "queryVipFreeScore", tcpAgentData.sui)
	end,
	[0x000505] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "getVipFreeScore", tcpAgentData.userID, tcpAgentData.sui, pbObj.memberType)
		return 0x000505, re
	end,
	[0x000506] = function(tcpAgent, pbObj, tcpAgentData) -- ÀñÈ¯»»½ð±Ò
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "getPresentScore", tcpAgentData.userID, tcpAgentData.sui, pbObj.gift)
		return 0x000506, re
	end,
	[0x000507] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "queryVipInfo", tcpAgentData.userID)
		return 0x000507, re
	end,
	[0x000512] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "ChangePaymentNotify", pbObj,tcpAgentData.userID)
	end,
}

local conf = {
	loginCheck = true,
	protocalHandlers = REQUEST,
}

pbServiceHelper.createService(conf)
