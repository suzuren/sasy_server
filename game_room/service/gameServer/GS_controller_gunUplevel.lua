local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local addressResolver = require "addressResolver"

local REQUEST = {
	[0x012000] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("GS_model_gunUplevel"),"lua","FortLevelInfoList",tcpAgent,tcpAgentData.userID)
	end,
	[0x012001] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("GS_model_gunUplevel"),"lua","RequestFortLevel",tcpAgentData,pbObj.fortLevel)
		return 0x012001, re
	end,
}

local conf = {
	loginCheck = true,
	protocalHandlers = REQUEST,
}

pbServiceHelper.createService(conf)

