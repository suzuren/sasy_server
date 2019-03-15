local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local addressResolver = require "addressResolver"

local REQUEST = {
	[0x000400] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("LS_model_ranking"), "lua", "sendWealthRankingList", tcpAgent)
	end,
	[0x000401] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("LS_model_ranking"), "lua", "sendLoveLinesRankingList", tcpAgent)
	end,
	[0x000402] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("LS_model_ranking"), "lua", "sendBoxRankingList", tcpAgent)
	end,
	[0x000403] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("LS_model_ranking"), "lua", "sendTitleList", tcpAgent,tcpAgentData.userID)
	end,
}

local conf = {
	loginCheck = true,
	protocalHandlers = REQUEST,
}

pbServiceHelper.createService(conf)
