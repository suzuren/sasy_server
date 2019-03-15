local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local addressResolver = require "addressResolver"

local REQUEST = {
	[0x011000] = function(tcpAgent, pbObj, tcpAgentData)
		skynet.send(addressResolver.getAddressByServiceName("GS_model_reward_gold_fish"),"lua","LotteryInfo",tcpAgent,tcpAgentData.userID)
	end,
	[0x011001] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("GS_model_reward_gold_fish"),"lua","RequestLotteryItem",tcpAgentData.userID,pbObj.lotteryType)
		return 0x011001, re
	end,
	[0x011002] = function(tcpAgent, pbObj, tcpAgentData)	
		local re = skynet.call(addressResolver.getAddressByServiceName("GS_model_reward_gold_fish"),"lua","ReceiveLotteryGoodsInfo",pbObj,tcpAgentData)
		return 0x011002, re
	end,
}

local conf = {
	loginCheck = true,
	protocalHandlers = REQUEST,
}

pbServiceHelper.createService(conf)

