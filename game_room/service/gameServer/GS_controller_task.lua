local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local addressResolver = require "addressResolver"

local REQUEST = {
	[0x010800] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("GS_model_task"), "lua", "RequestTask",pbObj.taskType,tcpAgentData.sui)
	end,
	[0x010801] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("GS_model_task"), "lua", "ChangeTaskGoodsCount",pbObj,tcpAgentData.sui)
	end,
	[0x010802] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("GS_model_task"), "lua", "CompleteTask",pbObj,tcpAgentData.sui)
		return 0x010802, re
	end,
	[0x010805] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("GS_model_task"), "lua", "TaskSynchronizationTime",pbObj.taskType,tcpAgentData.sui)
	end,
}

local conf = {
	loginCheck = true,
	protocalHandlers = REQUEST,
}

pbServiceHelper.createService(conf)

