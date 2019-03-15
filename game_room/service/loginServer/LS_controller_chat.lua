local skynet = require "skynet"
local pbServiceHelper = require "serviceHelper.pb"
local addressResolver = require "addressResolver"
local COMMON_CONST = require "define.commonConst"
local ServerUserItem = require "sui"

local REQUEST = {
	[0x004000] = function(tcpAgent, pbObj, tcpAgentData)
		local re = skynet.call(addressResolver.getAddressByServiceName("LS_model_chat"),"lua","SendMessageBoardInfo",pbObj,tcpAgentData)
		return 0x004000, re

		-- local attrr = ServerUserItem.getAttribute(tcpAgentData.sui,{"agent"})
		-- if attrr.agent ~= 0 then
		-- 	skynet.send(attrr.agent, "lua", "forward", 0xff0000, {
		-- 		type = COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_EJECT|COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_CHAT,
		-- 		msg = "该模块在维护中,敬请期待",
		-- 	})
		-- end	


	end,
}

local conf = {
	loginCheck = true,
	protocalHandlers = REQUEST,
}

pbServiceHelper.createService(conf)

