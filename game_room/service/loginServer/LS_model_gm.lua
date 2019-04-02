local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local resourceResolver = require "resourceResolver"
local timerUtility = require "utility.timer"
local mysqlutil = require "utility.mysqlHandle"
local commonConst = require "define.commonConst"
local ServerUserItem = require "sui"
local lsConst = require "define.lsConst"
local currencyUtility = require "utility.currency"

local _data = {
}

-- data={}
local function cmd_setUserFishPercent(data)
	if data.tp then
		local serverList = skynet.call(addressResolver.getAddressByServiceName("LS_model_serverManager"), "lua", "getServerIDListByKindID", 2010)
		if serverList then
			skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", 
					serverList, commonConst.LSNOTIFY_EVENT.gm_setUserFishPercent, data)
		end
		return
	end
	local baojiPercent = data.baojiPercent or 0
	local opGold = data.opGold or 0
	local sql = string.format(
			"update `qpgamedb`.`s_fish_luck` set reducePercent=%d,reduceBaoji=%d,opGold=%d where id=%d",
			tonumber(data.fishPercent), baojiPercent, opGold, tonumber(data.userId))
	local mysqlConn = addressResolver.getMysqlConnection()
	skynet.call(mysqlConn, "lua", "query", sql)
	local userItem = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getUserItemByUserID", data.userId)
	if userItem then
		local attr = ServerUserItem.getAttribute(userItem, {"userID", "agent", "serverID"})
		if attr.serverID~=0 then
			skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", 
					{attr.serverID}, commonConst.LSNOTIFY_EVENT.gm_setUserFishPercent, data)
		end
	end
	skynet.error("gm手动更改玩家概率")
	return re
end

-- data={}
local function cmd_setFishProb(data)
	local serverList = skynet.call(addressResolver.getAddressByServiceName("LS_model_serverManager"), "lua", "getServerIDListByKindID", 2010)
	if serverList then
		for _,v in pairs(serverList) do
			if v == data.serverId then
				skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", 
						{v}, commonConst.LSNOTIFY_EVENT.gm_setFishProb, data)
				break
			end
		end
	end
	skynet.error("gm手动更改鱼概率")
	return re
end

-- data={}
local function cmd_setBaojiProb(data)
	local serverList = skynet.call(addressResolver.getAddressByServiceName("LS_model_serverManager"), "lua", "getServerIDListByKindID", 2010)
	if serverList then
		for _,v in pairs(serverList) do
			if v == data.serverId then
				skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", 
						{v}, commonConst.LSNOTIFY_EVENT.gm_setFishProb, data)
				break
			end
		end
	end
	skynet.error("gm手动更改鱼暴击概率")
	return re
end

-- data={}
local function cmd_setJihuiyu(data)
	local serverList = skynet.call(addressResolver.getAddressByServiceName("LS_model_serverManager"), "lua", "getServerIDListByKindID", 2010)
	if serverList then
		for _,v in pairs(serverList) do
			if v == data.serverId then
				skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", 
						{v}, commonConst.LSNOTIFY_EVENT.gm_setJihuiyu, data)
				break
			end
		end
	end
	skynet.error("gm手动更改机会鱼")
	return re
end

-- data={} 设置出鱼时间
local function cmd_setFishTime(data)
	local serverList = skynet.call(addressResolver.getAddressByServiceName("LS_model_serverManager"), "lua", "getServerIDListByKindID", 2010)
	if serverList then
		for _,v in pairs(serverList) do
			if v == data.serverId then
				skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", 
						{v}, commonConst.LSNOTIFY_EVENT.gm_setFishTime, data)
				break
			end
		end
	end
	skynet.error("gm手动更改鱼概率")
	return re
end

-- data={} 统计打鱼数量,-1不统计
local function cmd_recordFishNum(data)
	local serverList = skynet.call(addressResolver.getAddressByServiceName("LS_model_serverManager"), "lua", "getServerIDListByKindID", 2010)
	if serverList then
		skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", 
				serverList, commonConst.LSNOTIFY_EVENT.gm_recordFishNum, data)
	end
	skynet.error("gm统计打鱼数量")
	return re
end

-- data={userId=,tp=,title=,content=,gold=,present=,vip=,vipDays=,days=,} 
local function http_sendMail(data)
	local temp = {gold = 0, vip = 0, vipDays = 0, days = 7}
	temp.userId = tonumber(data.userId)
	temp.tp = tonumber(data.tp)
	temp.title = data.title
	temp.content = data.content
	temp.gold = tonumber(data.gold) or 0
	temp.present = tonumber(data.present) or 0
	temp.loveliness = tonumber(data.loveliness) or 0
	temp.vip = tonumber(data.vip) or 0
	temp.vipDays = tonumber(data.vipDays) or 0
	temp.items = data.items or ""
	temp.days = tonumber(data.days) or 7
	
	if temp.gold < 0 or temp.present < 0 or temp.loveliness < 0 or temp.vip < 0 or temp.vip > 5 then
		return false
	end
	if temp.vip ~= 0 and temp.vipDays == 0 then
		return false
	end
	skynet.send(addressResolver.getAddressByServiceName("LS_model_mail"), "lua", "makeMail", 2, temp)
	
	skynet.error("gm发送邮件")
	return true
end

-- data={userId=,gold=,present=,vip=,vipDays=,loveliness=,} 只能在大厅
local function http_changeScore(data, offline)
	local userId = tonumber(data.userId)
	local gold = tonumber(data.gold) or 0
	local present = tonumber(data.present) or 0
	local vip = tonumber(data.vip) or 0
	local vipDays = tonumber(data.vipDays) or 0
	local loveliness = tonumber(data.loveliness) or 0
	
	if gold == 0 and present == 0 and loveliness == 0 and vip == 0 then
		return true
	end
	
	local userItem = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getUserItemByUserID", tonumber(data.userId))
	if userItem then
		local attr = ServerUserItem.getAttribute(userItem, {"userID", "agent", "serverID", "score", "present", "loveliness"})
		if attr.serverID~=0 then
			return false, "该玩家还在游戏中"
		end
		
		if gold < 0 and gold + attr.score < 0 then
			return false, "金币不足"
		end
		if present < 0 and present + attr.present < 0 then
			return false, "礼券不足"
		end
		if loveliness < 0 and loveliness + attr.loveliness < 0 then
			return false, "魅力不足"
		end
		
		local dbConn = addressResolver.getMysqlConnection()
		local sql = string.format(
			"call kftreasuredb.s_write_money(%d, %d, %d, %d, %d, %d, %d, 0, 0, 0, 0)",
			userId, 14, gold, present, loveliness, vip, vipDays
		)
		local rows = skynet.call(dbConn, "lua", "call", sql)
		if tonumber(rows[1].retCode) ~= 0 then
			return false, rows[1].retMsg
		end
		
		ServerUserItem.addAttribute(userItem, {score=gold, present=present, loveliness=loveliness})
		if vip > 0 and vipDays > 0 then --vip
			local attr = ServerUserItem.getAttribute(userItem, {"memberOrder"})
			if attr.memberOrder < vip then
				ServerUserItem.setAttribute(userItem, {memberOrder=vip})
			end
		end
		if attr.agent ~= 0 then
			local temp = {}
			if gold ~= 0 then
				temp.score = attr.score + gold
			end
			if present ~= 0 then
				temp.present = attr.present + present
			end
			if loveliness ~= 0 then
				temp.loveLiness = attr.loveliness + loveliness
			end
			skynet.send(attr.agent, "lua", "forward", 0x000102, temp)
		end
	else
		if offline == true then
			local dbConn = addressResolver.getMysqlConnection()
			local sql = string.format(
				"call kftreasuredb.s_write_money(%d, %d, %d, %d, %d, %d, %d, 0, 0, 0, 0)",
				userId, 14, gold, present, loveliness, vip, vipDays
			)
			local rows = skynet.call(dbConn, "lua", "call", sql)
			if tonumber(rows[1].retCode) ~= 0 then
				return false, rows[1].retMsg
			end
		else
			return false, "该玩家不在线"
		end
	end
	return true
end

local function cmd_changeScore(data)
	local isOk, msg = http_changeScore(data, true)
	if isOk then
		return "change成功"
	else
		return msg
	end
end

-- 锁定并踢除玩家
local function http_kickUser(data)
	skynet.send(addressResolver.getAddressByServiceName("LS_model_sessionManager"), 
			"lua", "kickUser", tonumber(data.userId), data.isCancel)
	return true
end

local function cmd_kickUser(data)
	local isOk, msg = http_kickUser(data)
	if isOk then
		return "成功"
	else
		return msg
	end
end
-- 锁定并踢除玩家
local function cmd_kickAndroid(data)
	skynet.send(addressResolver.getAddressByServiceName("LS_model_androidManager"), 
			"lua", "kickAndroid", data)
	return "成功"
end

-- 重载配置
local function cmd_reloadConfig(data)
	
	local f = io.open("./server/sysConfig.lua", "rb")
	if not f then
		return
	end
	local source = f:read "*a"
	f:close()
	local temp = load(source)()

	--skynet.call(addressResolver.getAddressByServiceName("LS_webController_interface"), 
	--		"lua", "reloadConfig", temp.httpInterfaceAllowIPList)
	--skynet.call(addressResolver.getAddressByServiceName("LS_webController_uniformPlatform"), 
	--		"lua", "reloadConfig", temp.uniformPlatformServerKey)
	skynet.send(addressResolver.getAddressByServiceName("LS_model_serverManager"), 
			"lua", "reloadConfig", temp.defenseList)
	--local serverList = skynet.call(addressResolver.getAddressByServiceName("LS_model_serverManager"), "lua", "getServerIDListByKindID", 2010)
	--if serverList then
	--	skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", 
	--			serverList, commonConst.LSNOTIFY_EVENT.reloadConfig, {presentInfo=temp.presentInfo, fishInfo=temp.fishInfo})
	--end
	return "成功"
end

-- 关服
local function cmd_shutdown(data)
	skynet.error("执行关服指令")
	local serverList = skynet.call(addressResolver.getAddressByServiceName("LS_model_serverManager"), "lua", "getServerIDListByKindID", data.kindId)
	if serverList then
		skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", 
				serverList, commonConst.LSNOTIFY_EVENT.closeServer)
	end
	return "成功"
end

-- 往指定serverId添加机器人
local function cmd_addAndroid(data)
	skynet.send(addressResolver.getAddressByServiceName("LS_model_androidManager"), 
			"lua", "gmAddAndroid", data)
end

local function cmd_addAndroidTime(data)
	skynet.send(addressResolver.getAddressByServiceName("LS_model_androidManager"), 
			"lua", "gmAddAndroidTime", data)
end

-- 释放机器人
local function cmd_freeAndroid(data)
	skynet.send(addressResolver.getAddressByServiceName("LS_model_androidManager"), 
			"lua", "gmFreeAndroid", data)
end

-- 获取玩家信息
local function http_getInfoByPid(data)
	local re = {}
	if tonumber(data.pid) == nil or tonumber(data.pid) <= 0 then
		re.code = "RC_OTHER"
		re.msg = "非法参数"
		return false, re
	end
	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format(
			"select UserID,GameID,NickName,LoveLiness,Status from kfaccountsdb.accountsinfo where PlatformID=%d",
			tonumber(data.pid))
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if rows[1] then
		re.userId = tonumber(rows[1].UserID)
		re.gameId = tonumber(rows[1].GameID)
		re.nickName = rows[1].NickName
		re.loveliness = tonumber(rows[1].LoveLiness)
		re.status = tonumber(rows[1].Status)
	else
		re.code = "RC_OTHER"
		re.msg = "账号不存在"
		return false, re
	end
	sql = string.format(
			"select Score from kftreasuredb.gamescoreinfo where UserID=%d",
			re.userId)
	rows = skynet.call(dbConn, "lua", "query", sql)
	if rows[1] then
		re.gold = tonumber(rows[1].Score)
	else
		re.code = "RC_OTHER"
		re.msg = "账号不存在"
		return false, re
	end
	re.code = "RC_OK"
	return true, re
end

-- 赠送魅力
local function http_sendLoveliness(data)
	local re = {}
	local userId = tonumber(data.userId)
	local targetGameId = tonumber(data.targetGameId)
	local loveliness = tonumber(data.loveliness)
	if userId <= 0 or targetGameId <= 0 or loveliness <= 0 then
		re.code = "RC_OTHER"
		re.msg = "非法参数"
		return false, re
	end

	local dbConn = addressResolver.getMysqlConnection()
	
	local sql = string.format("select UserID from `kfaccountsdb`.`AccountsInfo` where GameID=%d", targetGameId)
	--local rows = skynet.call(dbConn, "lua", "query", sql)
	local rows ={
		{
			UserID = 1003,
		}
	}
	local targetUserId = tonumber(rows[1].UserID)
	
	if userId == nil or targetUserId == nil then
		re.code = "RC_OTHER"
		re.msg = "非法参数"
		return false, re
	end
	
	sql = string.format("select Status from `kfaccountsdb`.`AccountsInfo` where UserID=%d", userId)
	--rows = skynet.call(dbConn, "lua", "query", sql)
	rows ={
		{
			Status = 0,
		}
	}
	if tonumber(rows[1].Status) & 0x01 == 1 then
		re.code = "RC_OTHER"
		re.msg = "账号已被冻结"
		return false, re
	end
	
	sql = string.format(
		"call kftreasuredb.p_pay(%d)",
		userId
	)
	--rows = skynet.call(dbConn, "lua", "call", sql)
	rows ={
		{
			retCode = 0,
			totalPay = 10000,
		}
	}
	if tonumber(rows[1].retCode) ~= 0 or tonumber(rows[1].totalPay) < 10000 then
		re.code = "RC_OTHER"
		re.msg = "充值小于100，无法赠送"
		return false, re
	end
	
	--local needGold = loveliness * commonConst.lovelinessToGold
	local needGold = loveliness * 0
	local userItem = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), 
			"lua", "getUserItemByUserID", userId)
	if userItem then
		local attr1 = ServerUserItem.getAttribute(userItem, {"userID", "agent", "serverID", "score", "loveliness"})
		if attr1.serverID~=0 then
			re.code = "RC_OTHER"
			re.msg = "还在游戏中"
			return false, re
		end
		if attr1.score < needGold then
			re.code = "RC_OTHER"
			re.msg = "金币不足"
			return false, re
		end
		ServerUserItem.addAttribute(userItem, {score=-needGold})
	else
		sql = string.format(
				"select Score from kftreasuredb.gamescoreinfo where UserID=%d",
				userId)
		rows = skynet.call(dbConn, "lua", "query", sql)
		if tonumber(rows[1].Score) < needGold then
			re.code = "RC_OTHER"
			re.msg = "金币不足"
			return false, re
		end
	end
	
	sql = string.format("update `kftreasuredb`.`GameScoreInfo` set `Score`=`Score`+%d where UserID=%d", -needGold, userId)
	--skynet.call(dbConn, "lua", "query", sql)
	sql = string.format("update `kfaccountsdb`.`AccountsInfo` set `LoveLiness`=`LoveLiness`+%d where UserID=%d", loveliness, targetUserId)
	--skynet.call(dbConn, "lua", "query", sql)
	sql = string.format("insert into `kfrecorddb`.`r_deal_info` values (%d, %d, 0, 0, %d, 0, 0, %d, NOW())", userId, -needGold, targetUserId, loveliness)
	--skynet.send(dbConn, "lua", "execute", sql)
	
	local targetUserItem = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", 
			"getUserItemByUserID", targetUserId)
	if targetUserItem then
		local attr = ServerUserItem.getAttribute(targetUserItem, {"userID", "agent", "serverID", "loveliness"})
		if attr.serverID~=0 then
			skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", 
					{attr.serverID}, commonConst.LSNOTIFY_EVENT.addMoney, {
				tp = 6,
				userId = attr.userID,
				loveliness = loveliness,
			})
		else
			ServerUserItem.addAttribute(targetUserItem, {loveliness=loveliness})
			
			if attr.agent ~= 0 then
				local temp = {}
				temp.loveLiness = attr.loveliness + loveliness
				skynet.send(attr.agent, "lua", "forward", 0x000102, temp)
			end
		end
	end
	
	re.code = "RC_OK"
	return true, re
end

-- 兑换魅力
local function http_exchangeLoveliness(data)
	local re = {}
	local userId = tonumber(data.userId)
	local loveliness = tonumber(data.loveliness)
	if userId <= 0 then
		re.code = "RC_OTHER"
		re.msg = "非法参数"
		return false, re
	end
	if loveliness <= 0 then
		re.code = "RC_OTHER"
		re.msg = "魅力值不足"
		return re
	end
	local sui = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), 
			"lua", "getUserItemByUserID", userId)
	if sui then
		local attr = ServerUserItem.getAttribute(sui, {"loveliness", "score", "memberOrder"})
		if attr.loveliness <= 0 or loveliness <= 0 then
			re.code = "RC_OTHER"
			re.msg = "魅力值不足"
			return re
		end
		if attr.memberOrder<=0 or attr.memberOrder>6 then
			re.code = "RC_OTHER"
			re.msg = "您不是vip用户"
		end
		local usedLoveliness = loveliness > attr.loveliness and attr.loveliness or loveliness
		local gold = commonConst.lovelinessToGold * usedLoveliness
		
		local dbConn = addressResolver.getMysqlConnection()
		local sql = string.format(
			"call kftreasuredb.s_write_money(%d, %d, %d, %d, %d, %d, %d, 0, 0, 0, 0)",
			userId, 5, gold, 0, -usedLoveliness, 0, 0
		)
		local rows = skynet.call(dbConn, "lua", "call", sql)
		if tonumber(rows[1].retCode) ~= 0 then
			re.code = "RC_OTHER"
			re.msg = "魅力值不足"
			return re
		end
		ServerUserItem.addAttribute(sui, {score = commonConst.lovelinessToGold * usedLoveliness, loveliness = -usedLoveliness})
		attr = ServerUserItem.getAttribute(sui, {"loveliness", "score"})
	else
		local dbConn = addressResolver.getMysqlConnection()
		local sql = string.format(
			"call kftreasuredb.s_write_money(%d, %d, %d, %d, %d, %d, %d, 0, 0, 0, 0)",
			userId, 5, commonConst.lovelinessToGold * loveliness, 0, -loveliness, 0, 0
		)
		local rows = skynet.call(dbConn, "lua", "call", sql)
		if tonumber(rows[1].retCode) ~= 0 then
			re.code = "RC_OTHER"
			re.msg = "魅力值不足"
			return re
		end
	end
	re.code = "RC_OK"
	return re
end

-- 查询信息
local function http_queryPayOrderItem(data)
	local re = {}
	local sql = string.format("call kftreasuredb.sp_query_pay_order_item_info(%d)", data.userId)
	local mysqlConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(mysqlConn, "lua", "call", sql)
	for _, row in ipairs(rows) do
		re[row.ItemID] = tonumber(row.AvailableTimes)
	end
	return true, re
end

local conf = {
	methods = {
		["reloadConfig"] = {["func"]=cmd_reloadConfig, ["isRet"]=true},
		["setUserFishPercent"] = {["func"]=cmd_setUserFishPercent, ["isRet"]=true},
		["setFishProb"] = {["func"]=cmd_setFishProb, ["isRet"]=true},
		["setBaojiProb"] = {["func"]=cmd_setBaojiProb, ["isRet"]=true},
		["setJihuiyu"] = {["func"]=cmd_setJihuiyu, ["isRet"]=true},
		["setFishTime"] = {["func"]=cmd_setFishTime, ["isRet"]=true},
		["recordFishNum"] = {["func"]=cmd_recordFishNum, ["isRet"]=true},
		["shutdown"] = {["func"]=cmd_shutdown, ["isRet"]=true},
		["addAndroid"] = {["func"]=cmd_addAndroid, ["isRet"]=true},
		["addAndroidTime"] = {["func"]=cmd_addAndroidTime, ["isRet"]=true},
		["freeAndroid"] = {["func"]=cmd_freeAndroid, ["isRet"]=true},
		["kickAndroid"] = {["func"]=cmd_kickAndroid, ["isRet"]=true},
		
		["sendMail"] = {["func"]=http_sendMail, ["isRet"]=true},
		["changeScore"] = {["func"]=http_changeScore, ["isRet"]=true},
		["telnetChangeScore"] = {["func"]=cmd_changeScore, ["isRet"]=true},
		["kickUser"] = {["func"]=http_kickUser, ["isRet"]=true},
		["telnetKickUser"] = {["func"]=cmd_kickUser, ["isRet"]=true},
		["getInfoByPid"] = {["func"]=http_getInfoByPid, ["isRet"]=true},
		["sendLoveliness"] = {["func"]=http_sendLoveliness, ["isRet"]=true},
		["exchangeLoveliness"] = {["func"]=http_exchangeLoveliness, ["isRet"]=true},
		["queryPayOrderItem"] = {["func"]=http_queryPayOrderItem, ["isRet"]=true},
	},
	initFunc = function()
		resourceResolver.init()
	end,
}

commonServiceHelper.createService(conf)
