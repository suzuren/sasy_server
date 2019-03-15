local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local addressResolver = require "addressResolver"

local REQUEST = {
	[0x000202] = function(tcpAgent, pbObj, tcpAgentData)
		if type(pbObj.serverIDList)~="table" then
			error("serverIDList类型必须是table，客户端协议发送错误")
		end
		
		skynet.send(addressResolver.getAddressByServiceName("LS_model_serverManager"), "lua", "sendServerOnline", tcpAgent, pbObj.serverIDList)
	end,
}

local conf = {
	loginCheck = true,
	protocalHandlers = REQUEST,
}

pbServiceHelper.createService(conf)
