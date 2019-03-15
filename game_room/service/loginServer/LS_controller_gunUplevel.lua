local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local addressResolver = require "addressResolver"

local REQUEST = {
	[0x005000] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("LS_model_gunUplevel"),"lua","FortLevelInfoList",tcpAgent,tcpAgentData.userID)
	end,
	[0x005001] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_gunUplevel"),"lua","RequestFortLevel",tcpAgentData,pbObj.fortLevel)
		return 0x005001, re
	end,
}

local conf = {
	loginCheck = true,
	protocalHandlers = REQUEST,
}

pbServiceHelper.createService(conf)

