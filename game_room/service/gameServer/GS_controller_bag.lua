local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local addressResolver = require "addressResolver"

local REQUEST = {
	[0x010900] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "GoodsInfoList", tcpAgent, tcpAgentData)
	end,
	[0x010901] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "GoodsInfo", tcpAgentData.userID, pbObj.goodsID)
	end,
	[0x010902] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "OffsetGoodsInfo", tcpAgent,pbObj,tcpAgentData)
		return 0x010902, re
	end,
	[0x010903] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "UseGoodsInfo", tcpAgentData.userID, pbObj.goodsID,pbObj.getGoodsID,tcpAgentData.sui)
		return 0x010903, re
	end,
	[0x010904] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "CompositingGoodsInfo", tcpAgentData, pbObj.goodsID)
		return 0x010904, re
	end,
	[0x010905] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "GiveGoodsInfo", pbObj, tcpAgentData.userID,tcpAgentData.sui)
		return 0x010905, re
	end,
	[0x010906] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "equipGoodsInfo", pbObj, tcpAgentData.userID)
		return 0x010906, re
	end,
	[0x010907] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "CompositingCDInfo", pbObj, tcpAgentData.userID)
		return 0x010907, re
	end,	
}

local conf = {
	loginCheck = true,
	protocalHandlers = REQUEST,
}

pbServiceHelper.createService(conf)

