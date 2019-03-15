local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local addressResolver = require "addressResolver"

local REQUEST = {
	[0x007000] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("LS_model_worldBoss"), "lua", "WorldBossFishInfo", tcpAgent, tcpAgentData.userID,pbObj.bossType)
	end,
	[0x007004] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("LS_model_worldBoss"), "lua", "SynchronizationBossSwimTime", tcpAgent, tcpAgentData.userID)
	end,
}

local conf = {
	loginCheck = true,
	protocalHandlers = REQUEST,
}

pbServiceHelper.createService(conf)

