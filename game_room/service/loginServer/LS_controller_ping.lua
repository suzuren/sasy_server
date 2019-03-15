local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local addressResolver = require "addressResolver"

local _responseProtoStr = nil

local REQUEST = {
	[0x000800] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "ping")
		return _responseProtoStr
	end,
}

local conf = {
	loginCheck = false,
	protocalHandlers = REQUEST,
	initFunc = function()
		_responseProtoStr = skynet.call(addressResolver.getAddressByServiceName("simpleProtocalBuffer"), "lua", "get", 0x000800)
	end,	
}

pbServiceHelper.createService(conf)
