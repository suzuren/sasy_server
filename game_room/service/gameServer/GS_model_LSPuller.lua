require "utility.string"
local skynet = require "skynet"
local cluster = require "cluster"
local ServerUserItem = require "sui"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local resourceResolver = require "resourceResolver"
local GS_CONST = require "define.gsConst"
local COMMON_CONST = require "define.commonConst"
local GS_EVENT = require "define.eventGameServer"

local _serverSignature
local _LS_GSProxyAddress

local function relayMessageSystemMessage(data)
	local pbParser = resourceResolver.get("pbParser")
	local packetStr = skynet.call(pbParser, "lua", "encode", 0xff0000, data, true)
	if packetStr then
		skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "broadcast", packetStr)
	end
end

local function relayMessageBigTrumpet(data)
	local pbParser = resourceResolver.get("pbParser")
	local packetStr = skynet.call(pbParser, "lua", "encode", 0x010308, data, true)
	if packetStr then
		skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "broadcast", packetStr)
	end
end

local function lsNotifyLoginOtherServer(data)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "kickUser", data.userID, "对不起,您的网络连接不稳定,请重新登录")
end

local function lsNotifyPayOrderConfirm(data)
	local userItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "getUserItem", data.userID)
	if not userItem then
		skynet.error(string.format("---------玩家在游戏里充值,可是找不到玩家内存---userid=%d----time=%s------------",data.userID,os.date("%Y-%m-%d %H:%M:%S", os.time())))
		return
	end

	skynet.error(string.format("---------玩家在游戏里充值---userid=%d----time=%s------------",data.userID,os.date("%Y-%m-%d %H:%M:%S", os.time())))
	
	local userAttr = ServerUserItem.getAttribute(userItem, {"tableID", "agent","userID"})
	
	ServerUserItem.addAttribute(userItem, {
		score=data.score,
		contribution=data.contribution,
	})
	ServerUserItem.setAttribute(userItem, {
		memberOrder=data.memberOrder,
		userRight=data.userRight,
	})

	if userAttr.agent~=0 then
		skynet.send(userAttr.agent, "lua", "forward", 0x01ff02, {
			orderID=data.orderID,
			currencyType=data.currencyType,
			currencyAmount=data.currencyAmount,
			payID=data.payID,
			score=data.score,
			memberOrder=data.memberOrder,
			userRight=data.userRight,
		})
	end

	if data.ItemReward then
		for k, v in pairs(data.ItemReward.rewardList) do
			if v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
				ServerUserItem.addAttribute(userItem,{score=v.goodsCount})
				-- skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "AddItemRecord",userAttr.userID,
				-- 	v.goodsID,v.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.PAY_ADD)
			-- else
			-- 	skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
			-- 		v.goodsID,v.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.PAY_ADD,true)
			end

			skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
				v.goodsID,v.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.PAY_ADD,true)
		end
	end
	
	local tableAddress
	if userAttr.tableID~=GS_CONST.INVALID_TABLE then
		tableAddress = addressResolver.getTableAddress(userAttr.tableID)
	end
	
	if tableAddress then
		skynet.call(tableAddress, "lua", "onUserScoreNotify", userItem)
		skynet.call(tableAddress, "lua", "onUserGoldRecordChange", userItem)
		-- if data.score ~= 0 then
		-- 	skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "AddItemRecord",userAttr.userID,
		-- 		1001,data.score,COMMON_CONST.ITEM_SYSTEM_TYPE.PAY_ADD)
		-- end
	else
		skynet.error(string.format("---------玩家在游戏里充值没通知到玩家,掉线了---userid=%d----time=%s------------",data.userID,os.date("%Y-%m-%d %H:%M:%S", os.time())))
	end

	if data.score ~= 0 then
		skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
			1001,data.score,COMMON_CONST.ITEM_SYSTEM_TYPE.PAY_ADD,true)
	end

	skynet.call(addressResolver.getAddressByServiceName("GS_model_attemperEngine"), "lua", "broadcastUserScore", userItem)
	skynet.send(addressResolver.getAddressByServiceName("GS_model_gunUplevel"),"lua","checkGunLevelUp",data.memberOrder,data.userID,userAttr.agent)
	local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_FIRST_CHARGE
	skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",data.userID,limitId,1)

	local limitId_1 = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_PAY_RMB_NEW
	skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",data.userID,limitId_1,tonumber(data.contribution))

	local limitId_1 = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_PAY_RMB_NEW_1
	skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",data.userID,limitId_1,tonumber(data.contribution))

	--触发体验炮台
	if data.memberOrder < 4 then
		local bLimit = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "CheckIsForeverLimit",data.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP4,1)
		if not bLimit then
			skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",data.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP4,1)
		end
	end
end

local function lsNotifyUserBankWithdraw(data)
	local userItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "getUserItem", data.userID)
	if not userItem then
		return
	end
	ServerUserItem.addAttribute(userItem, {
		score=data.score,
		insure=data.insure,
	})

	skynet.call(addressResolver.getAddressByServiceName("GS_model_attemperEngine"), "lua", "broadcastUserScore", userItem)

	local userAttr = ServerUserItem.getAttribute(userItem, {"tableID"})
	local tableAddress
	if userAttr.tableID~=GS_CONST.INVALID_TABLE then
		tableAddress = addressResolver.getTableAddress(userAttr.tableID)
	end

	if tableAddress then
		skynet.call(tableAddress, "lua", "onUserScoreNotify", userItem)
	end
end

local function lsNotifyUserRescueCoin(data)
	local userItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "getUserItem", data.userID)
	if not userItem then
		return
	end
	
	ServerUserItem.addAttribute(userItem, {score=data.score})

	skynet.call(addressResolver.getAddressByServiceName("GS_model_attemperEngine"), "lua", "broadcastUserScore", userItem)
	
	local userAttr = ServerUserItem.getAttribute(userItem, {"tableID","userID"})
	local tableAddress
	if userAttr.tableID~=GS_CONST.INVALID_TABLE then
		tableAddress = addressResolver.getTableAddress(userAttr.tableID)
	end
	
	if tableAddress then
		skynet.call(tableAddress, "lua", "onUserScoreNotify", userItem)
		-- skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "AddItemRecord",data.userID,
		-- 	1001,data.score,COMMON_CONST.ITEM_SYSTEM_TYPE.RESCUE_COIN)
		-- skynet.send(addressResolver.getAddressByServiceName("GS_model_protect"), "lua", "ChangeFishCount",userAttr.userID,data.num,data.randNum,data.bDaySwitch)
	end

	skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
		1001,data.score,COMMON_CONST.ITEM_SYSTEM_TYPE.RESCUE_COIN,true)

	skynet.send(addressResolver.getAddressByServiceName("GS_model_protect"), "lua", "ChangeFishCount",userAttr.userID,data.num,data.randNum,data.bDaySwitch)
end

local function lsNotifyWorldBossStartOrEnd(data)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_tableManager"), "lua", "NotifyWorldBossStartOrEnd", data)
end

local function lsNotifyUserChangeItemInfo(data)
	local userItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "getUserItem", data.userID)
	if not userItem then
		return
	end
	
	local userAttr = ServerUserItem.getAttribute(userItem, {"tableID", "agent","userID"})

	if data.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
		ServerUserItem.addAttribute(userItem, {score=data.goodsCount})
		local tableAddress
		if userAttr.tableID~=GS_CONST.INVALID_TABLE then
			tableAddress = addressResolver.getTableAddress(userAttr.tableID)
		end
		
		if tableAddress then
			skynet.call(tableAddress, "lua", "onUserScoreNotify", userItem)
		end
	-- else
	-- 	skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
	-- 		data.goodsID,data.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FROM_LS,true)
	end

	skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
		data.goodsID,data.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FROM_LS,true)
end

local function lsNotifyUserChangeUserName(data)
	local userItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "getUserItem", data.userID)
	if not userItem then
		return
	end

	ServerUserItem.setAttribute(userItem, {nickName=data.nickName})

	local userAttr = ServerUserItem.getAttribute(userItem, {"tableID", "agent","userID","score"})
	
	if data.bFree == 1 then
		local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_CHANGE_NAME
		skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",data.userID,limitId,1)
	else
		if data.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
			ServerUserItem.addAttribute(userItem, {score=data.goodsCount})

			local tableAddress
			if userAttr.tableID~=GS_CONST.INVALID_TABLE then
				tableAddress = addressResolver.getTableAddress(userAttr.tableID)
			end
			
			if tableAddress then
				skynet.call(tableAddress, "lua", "onUserScoreNotify", userItem)
			end

			-- skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "AddItemRecord",userAttr.userID,
			-- 	data.goodsID,data.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.USE_CHANGE_NAME)
		-- else
		-- 	skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
		-- 		data.goodsID,data.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FROM_LS,true)
		end

		skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
			data.goodsID,data.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.USE_CHANGE_NAME,true)
	end
end

local function processLSNotify(msgNo, msgBody)
	if msgNo==COMMON_CONST.LSNOTIFY_EVENT.EVT_LSNOTIFY_USER_LOGIN_OTHER_SERVER then
		lsNotifyLoginOtherServer(msgBody)
	elseif msgNo==COMMON_CONST.LSNOTIFY_EVENT.EVT_LSNOTIFY_PAY_ORDER_CONFIRM then
		lsNotifyPayOrderConfirm(msgBody)
	elseif msgNo == COMMON_CONST.LSNOTIFY_EVENT.EVT_LSNOTIFY_USER_BANK then
		lsNotifyUserBankWithdraw(msgBody)
	elseif msgNo == COMMON_CONST.LSNOTIFY_EVENT.EVT_LSNOTIFY_USER_RESCUECOIN then
		lsNotifyUserRescueCoin(msgBody)
	elseif msgNo == COMMON_CONST.LSNOTIFY_EVENT.EVT_LSNOTIFY_WORLD_BOSS_START_OR_END then
		lsNotifyWorldBossStartOrEnd(msgBody)
	elseif msgNo == COMMON_CONST.LSNOTIFY_EVENT.EVT_LSNOTIFY_GS_CHANGE_USER_ITEM then
		lsNotifyUserChangeItemInfo(msgBody)
	elseif msgNo == COMMON_CONST.LSNOTIFY_EVENT.EVT_LSNOTIFY_GS_CHANGE_USER_NAME then
		lsNotifyUserChangeUserName(msgBody)
	else
		error(string.format("%s: unknow the message from loginserver", SERVICE_NAME))
	end
end

local function processRelayMessage(msgNo, msgBody)
	if msgNo == COMMON_CONST.RELAY_MESSAGE_TYPE.RMT_SYSTEM_MESSAGE then
		relayMessageSystemMessage(msgBody)
	elseif msgNo == COMMON_CONST.RELAY_MESSAGE_TYPE.RMT_BIG_TRUMPET then
		relayMessageBigTrumpet(msgBody)
	elseif msgNo == COMMON_CONST.RELAY_MESSAGE_TYPE.RMT_MATCH_SIGNUP then
		local isSuccess, roomID = skynet.call(addressResolver.getAddressByServiceName("GS_model_matchManager"), "lua", "onSignup", msgBody)
		if isSuccess then
			skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "dispatch", GS_EVENT.EVT_GS_MATCH_SIGNUP_SUCCESS, roomID)
		end
	elseif msgNo == COMMON_CONST.RELAY_MESSAGE_TYPE.RMT_MATCH_CANCLE_SIGNUP then
		skynet.call(addressResolver.getAddressByServiceName("GS_model_matchManager"), "lua", "onSignup", msgBody.userID)
	else
		error(string.format("%s: unknow the message to disspatch", SERVICE_NAME))
	end
end

local function doPulling()
	local list = cluster.call("loginServer", _LS_GSProxyAddress, "gs_pull", _serverSignature.serverID, _serverSignature.sign)
--[[	
	do
		local jsonUtil = require "cjson.util"
		skynet.error(string.format("%s %d\n%s", SERVICE_NAME, skynet.now(), jsonUtil.serialise_value(list)))
	end
--]]	
	for _, item in ipairs(list) do
		if (item.msgNo & COMMON_CONST.LSNOTIFY_EVENT_MASK)~=0 then
			processLSNotify(item.msgNo, item.msgData)
		elseif (item.msgNo & COMMON_CONST.RELAY_MESSAG_MASK)~=0 then
			processRelayMessage(item.msgNo, item.msgData)
		else
			error(string.format("%s: unknow the message type", SERVICE_NAME))
		end
	end
end

local function cmd_onEventServerRegisterSuccess(data)
	local isPullingStarted = _serverSignature~=nil
	
	_serverSignature = data
	
	if not isPullingStarted then
		skynet.fork(function()
			while true do
				local isSuccess, errMsg = pcall(doPulling)
				if not isSuccess then
					skynet.error(string.format("%s connect to loginserver is failed: %s", SERVICE_NAME, tostring(errMsg)))
					skynet.sleep(1000)
				end	
			end
		end)
	end
end


local conf = {
	methods = {
		["onEventServerRegisterSuccess"] = {["func"]=cmd_onEventServerRegisterSuccess, ["isRet"]=false},
	},
	initFunc = function()
		_LS_GSProxyAddress = cluster.query("loginServer", "LS_model_GSProxy")
		resourceResolver.init()
		skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "addEventListener", GS_EVENT.EVT_GS_SERVER_REGISTER_SUCCESS, skynet.self(), "onEventServerRegisterSuccess")
	end,
}

commonServiceHelper.createService(conf)
