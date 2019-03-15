local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local addressResolver = require "addressResolver"

local REQUEST = {
	[0x003000] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "GoodsInfoList", tcpAgent, tcpAgentData)
	end,
	[0x003001] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "GoodsInfo", tcpAgentData.userID, pbObj.goodsID)
	end,
	[0x003002] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "OffsetGoodsInfo", tcpAgent,pbObj,tcpAgentData)
		return 0x003002, re
	end,
	[0x003003] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "UseGoodsInfo", tcpAgentData.userID, pbObj.goodsID,pbObj.getGoodsID)
		return 0x003003, re
	end,
	[0x003004] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "CompositingGoodsInfo", tcpAgentData, pbObj.goodsID)
		return 0x003004, re
	end,
	[0x003005] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "GiveGoodsInfo", tcpAgent, pbObj, tcpAgentData.userID,tcpAgentData.sui)
		return 0x003005, re
	end,
	[0x003006] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "equipGoodsInfo", pbObj, tcpAgentData.userID)
		return 0x003006, re
	end,
	[0x003007] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ShopGoodsInfo", pbObj, tcpAgentData.userID)
		return 0x003007, re
	end,
	[0x003008] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "CompositingCDInfo", pbObj, tcpAgentData.userID)
		return 0x003008, re
	end,
	[0x003009] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "GivenHistory", tcpAgent, pbObj, tcpAgentData.userID)
	end,
}

local conf = {
	loginCheck = true,
	protocalHandlers = REQUEST,
}

pbServiceHelper.createService(conf)

