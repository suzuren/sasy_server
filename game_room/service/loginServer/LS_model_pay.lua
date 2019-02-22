require "utility.string"
local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local timeUtility = require "utility.time"
local mysqlutil = require "mysqlutil"
local COMMON_CONST = require "define.commonConst"
local LS_EVENT = require "define.eventLoginServer"
local ServerUserItem = require "sui"
local LS_CONST = require "define.lsConst"
local timerUtility = require "utility.timer"

local startTime = 0
local endTime = 0
local bStartFlag = false
local _payOrderItemHash_EX = {}
local _payOrderItemHash = {}
local _freeScoreHash = {}
local _vipInfoHash = {}
local _freeScoreInfo = {
	limitScore = LS_CONST.FREESCORE.limit,
	freeScore = LS_CONST.FREESCORE.gold,
	num = LS_CONST.FREESCORE.num,
	vipNum = LS_CONST.FREESCORE.vipNum,
}

local function loadVipInfoConfig()
	local sql = "SELECT * FROM `kftreasuredb`.`VipAwardInfo` order by id asc"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if type(rows)=="table" then
		local tmp = {}
		for _, row in ipairs(rows) do
			local item = {
				id = tonumber(row.id),
				freeScore = tonumber(row.freeScore)
			}
			
			_vipInfoHash[item.id] = item
		end
	end
end

local function cmd_PaymentNotify(agent,userID)
	local pbObj = {
		paymentNotifyItem = {},
	}

	local sql = string.format("SELECT * FROM `kftreasuredb`.`payOrderConfirm` where UserId = %d and ReadFlag = 0", userID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	for _, item in ipairs(rows) do 
		local info = {
			payID = tonumber(item.PayOrderItemID),
			orderID = item.OrderID,
			readResult = 0,
		}

		table.insert(pbObj.paymentNotifyItem,info)
	end

	skynet.send(agent,"lua","forward",0x000501,pbObj)
end

local function cmd_ChangePaymentNotify(pbObj,userID)
	local sql = string.format("update `kftreasuredb`.`payOrderConfirm` set ReadFlag = 1 where OrderID = '%s' and UserId = %d and PayOrderItemID = %d ",
		mysqlutil.escapestring(pbObj.orderID ),userID,pbObj.payID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
end

-- 查询免费金币
local function cmd_queryFreeScore(userId)
	local re = {}
	local nowTime = os.time()
	re.limitScore = _freeScoreInfo.limitScore
	re.freeScore = _freeScoreInfo.freeScore
	re.num = _freeScoreInfo.num
	re.vipNum = _freeScoreInfo.vipNum
	re.nowTime = nowTime
	local nowDate = tonumber(os.date("%Y%m%d", nowTime))
	local sql = string.format("SELECT earnDate,num FROM `kftreasuredb`.`s_free_score_info` where id = %d", userId)
	local dbConn = addressResolver.getMysqlConnection()
	local earnDate = 0
	local num = 0
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if rows[1] == nil then
		sql = string.format("insert into `kftreasuredb`.`s_free_score_info` values(%d,%d,0,0)",userId, nowDate)
		skynet.call(dbConn, "lua", "query", sql)
	else
		earnDate = tonumber(rows[1].earnDate)
		num = tonumber(rows[1].num)
	end
	if earnDate ~= nowDate then
		re.recvNum = 0
	else
		re.recvNum = num
	end
	return re
end

-- 领取免费金币
local function cmd_getFreeScore(userId, sui)
	local re = {}
	local nowTime = os.time()
	local nowDate = tonumber(os.date("%Y%m%d", nowTime))
	local sql = string.format("SELECT earnDate,num FROM `kftreasuredb`.`s_free_score_info` where id = %d", userId)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if rows[1] == nil then
		re.code = "RC_OTHER"
		return re
	end
	local earnDate = tonumber(rows[1].earnDate)
	local num = tonumber(rows[1].num)
	local attr = ServerUserItem.getAttribute(sui, {"score", "insure", "memberOrder"}) -- 获取身上及银行金币
	
	if attr.score + attr.insure >= _freeScoreInfo.limitScore then -- 身上金币不符合领取条件
		re.code = "RC_LIMITSCORE_ERROR"
		return re
	end
	local tempNum = _freeScoreInfo.num
	if attr.memberOrder > 0 then
		tempNum = _freeScoreInfo.vipNum
	end

	if earnDate == nowDate and num >= tempNum then -- 领取次数不足
		re.code = "RC_LIMITNUM_ERROR"
		return re
	end
	if earnDate == nowDate then
		sql = string.format("update `kftreasuredb`.`s_free_score_info` set num=%d where id = %d", num+1, userId)
	else
		sql = string.format("update `kftreasuredb`.`s_free_score_info` set earnDate=%d,num=1,vipFreeState=0 where id = %d", nowDate, userId)
	end
	skynet.call(dbConn, "lua", "query", sql)
	
	sql = string.format("update `kftreasuredb`.`GameScoreInfo` set Score=Score+%d where UserID = %d", _freeScoreInfo.freeScore, userId)
	skynet.call(dbConn, "lua", "query", sql)
	sql = string.format("insert `kfrecorddb`.`Recordalms` set `UserID`=%d,`Score`=%d,`Datetime`='%s'", userId, _freeScoreInfo.freeScore, os.date("%Y-%m-%d %H:%M:%S", os.time()))
	skynet.call(dbConn, "lua", "query", sql)
	ServerUserItem.addAttribute(sui, {score = _freeScoreInfo.freeScore})
	--背包--start
	skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",userId,
			COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,_freeScoreInfo.freeScore,COMMON_CONST.ITEM_SYSTEM_TYPE.GET_FREE_SCORE)
	--背包--end
	
	re.code = "RC_OK"
	re.score = _freeScoreInfo.freeScore
	return re
end


-- 查询VIP免费金币
local function cmd_queryVipFreeScore(sui)
	local attr = ServerUserItem.getAttribute(sui, {"userID", "agent"})
	local re = {vipFreeScore = {}}
	local nowTime = os.time()
	local nowDate = tonumber(os.date("%Y%m%d", nowTime))
	local sql = string.format("SELECT earnDate,vipFreeState FROM `kftreasuredb`.`s_free_score_info` where id = %d", attr.userID)
	local dbConn = addressResolver.getMysqlConnection()
	local earnDate = 0
	local vipFreeState = 0
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if rows[1] == nil then
		sql = string.format("insert into `kftreasuredb`.`s_free_score_info` values(%d,%d,0,0)",attr.userID, nowDate)
		skynet.call(dbConn, "lua", "query", sql)
	else
		earnDate = tonumber(rows[1].earnDate)
		vipFreeState = tonumber(rows[1].vipFreeState)
	end

	sql = string.format("select MemberOrder as vipLevel, UNIX_TIMESTAMP(MemberOverDate) as OverDate from `kfaccountsdb`.`AccountsMember` where UserID=%d", attr.userID)
	rows = skynet.call(dbConn, "lua", "query", sql)
	if earnDate ~= nowDate then
		vipFreeState = 0
	end

	for k, v in pairs(_vipInfoHash) do
		local vipInfo = {
			id = v.id,
			freeScore = v.freeScore,
			recvState = 0,
		} 
		local m = (1 << (k-1))
		for _, row in ipairs(rows) do
			if k == tonumber(row.vipLevel) then
				if nowTime < tonumber(row.OverDate) then
					vipInfo.recvState = 1
					if (vipFreeState & m) ~= 0 then
						vipInfo.recvState = 2
					end
				end
				break
			end
		end
		table.insert(re.vipFreeScore,vipInfo)
	end

	skynet.send(attr.agent,"lua","forward",0x000504,re)
end

-- 领取VIP免费金币
local function cmd_getVipFreeScore(userId, sui, memberType)
	-----------------------充值模拟测试
	if memberType < 0 and skynet.getenv("isTest") == "true" then
		if _payOrderItemHash[-memberType] == nil then
			return {}
		end
		
		local testOrder = os.date("%Y%m%d%H%M%S", os.time())
		testOrder = "test________"..testOrder
		local test = ServerUserItem.getAttribute(sui, {"platformID"}) -- 获取身上金币
		local event = {OrderID=testOrder,
		PayChannel="1",
		PayID=tostring(-memberType),-- 202-218
		UserID=tostring(test.platformID),
		CurrencyType="CNY",
		CurrencyAmount=tostring(_payOrderItemHash[-memberType].price),
		SubmitTime=os.date("%Y-%m-%d %H:%M:%S", os.time()),}

		skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "payOrderConfirm", event)
		return {}
	end
	------------
	local re = {}
	local nowTime = os.time()
	local nowDate = tonumber(os.date("%Y%m%d", nowTime))
	local sql = string.format("SELECT earnDate,vipFreeState FROM `kftreasuredb`.`s_free_score_info` where id = %d", userId)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if rows[1] == nil then
		re.code = "RC_OTHER"
		return re
	end
	local earnDate = tonumber(rows[1].earnDate)
	local vipFreeState = tonumber(rows[1].vipFreeState)
	
	local m = (1 << (memberType - 1))
	if earnDate == nowDate and (vipFreeState & m ~= 0) then -- 已经领取
		re.code = "RC_LIMITNUM_ERROR"
		return re
	end
	
	sql = string.format("select UNIX_TIMESTAMP(MemberOverDate) as OverDate from `kfaccountsdb`.`AccountsMember` where UserID=%d and MemberOrder=%d", userId, memberType)
	rows = skynet.call(dbConn, "lua", "query", sql)
	if rows[1] == nil or tonumber(rows[1].OverDate) < nowTime then
		re.code = "RC_CONDITION_ERROR"
		return re
	end
	if earnDate == nowDate then
		sql = string.format("update `kftreasuredb`.`s_free_score_info` set vipFreeState=%d where id = %d", vipFreeState | m, userId)
	else
		sql = string.format("update `kftreasuredb`.`s_free_score_info` set earnDate=%d,vipFreeState=%d where id=%d", nowDate, m, userId)
	end
	skynet.call(dbConn, "lua", "query", sql)
	
	sql = string.format("update `kftreasuredb`.`GameScoreInfo` set Score=Score+%d where UserID = %d", _vipInfoHash[memberType].freeScore, userId)
	skynet.call(dbConn, "lua", "query", sql)
	
	sql = string.format("insert `kfrecorddb`.`Recordmemberscore` set `UserID`=%d,`Score`=%d,`Datetime`='%s',`MemberOrder`=%d", 
			userId, _vipInfoHash[memberType].freeScore, os.date("%Y-%m-%d %H:%M:%S", os.time()), memberType)
	skynet.call(dbConn, "lua", "query", sql)
	ServerUserItem.addAttribute(sui, {score = _vipInfoHash[memberType].freeScore})
	 --背包--start
	skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",userId,
			COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,_vipInfoHash[memberType].freeScore,COMMON_CONST.ITEM_SYSTEM_TYPE.GET_VIP_SCORE)
	--背包--end

	--cmd_queryVipFreeScore(sui)
	skynet.send(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "queryVipFreeScore",sui)
	
	re.code = "RC_OK"
	re.score = _vipInfoHash[memberType].freeScore
	return re
end

-- 魅力值换金币，统一平台接口，只有在线才能换
local function cmd_getLovelinessScore(data)
	local platformID = tonumber(data.UserID)
	local userItem = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getUserItemByPlatformID", platformID)
	if userItem then
		local attr = ServerUserItem.getAttribute(userItem, {"userID", "agent", "loveliness", "score", "memberOrder"})
		if attr.loveliness <= 0 then
			return false, "not enough loveliness"
		end
		if attr.memberOrder<=0 or attr.memberOrder>6 then
			return false, "memberOrder error"
		end
		local temp = 1-LS_CONST.LOVELINESS_MEMBER[attr.memberOrder]
		local addScore = math.floor(attr.loveliness * LS_CONST.LOVELINESS_SCORE * temp)
		
		local sql = string.format(
			"call kftreasuredb.s_write_loveliness_score(%d, %d, %d)",attr.userID, -attr.loveliness, addScore
		)
		local dbConn = addressResolver.getMysqlConnection()
		local rows = skynet.call(dbConn, "lua", "call", sql)
		if tonumber(rows[1].retCode)~=0 then
			return false, "other error"
		end
		ServerUserItem.addAttribute(userItem, {loveliness = -attr.loveliness, score = addScore})
		attr = ServerUserItem.getAttribute(userItem, {"userID", "agent", "loveliness", "score"})
		if attr.agent~=0 then
			skynet.send(attr.agent, "lua", "forward", 0x000509, {
				loveliness=attr.loveliness,
				score=attr.score
			})
		end
	else
		return false, "user not online"
	end
	return true
end

-- 礼券换金币
local function cmd_getPresentScore(userId, sui, presentNum)
	local re = {}
	local attr = ServerUserItem.getAttribute(sui, {"gift", "score","memberOrder"})
	if attr.gift <= 0 or presentNum <= 0 then
		re.code = 1
		return re
	end
	local count = skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "GetItemCount",userId,COMMON_CONST.ITEM_ID.ITEM_ID_FISH)
	if count < presentNum then
		re.code = 2
		return re
	end

	local usedPresent = presentNum > attr.gift and attr.gift or presentNum

	local sql = string.format("call kftreasuredb.s_write_present_score(%d, %d, %d)",userId, -usedPresent, COMMON_CONST.PRESENT_SCORE * usedPresent)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "call", sql)
	if tonumber(rows[1].retCode)~=0 then
		re.code = 3
		return re
	end

	local goldRate = 1000
	if 2 <= attr.memberOrder and attr.memberOrder <= 4 then
		goldRate = 1300
	elseif 5 <= attr.memberOrder and attr.memberOrder <= 7 then
		goldRate = 1500
	end

    --背包--start
	skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",userId,
			COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,goldRate * usedPresent,COMMON_CONST.ITEM_SYSTEM_TYPE.EXCHANGE)
	skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",userId,
			COMMON_CONST.ITEM_ID.ITEM_ID_FISH,-usedPresent,COMMON_CONST.ITEM_SYSTEM_TYPE.EXCHANGE)
	--背包--end

	ServerUserItem.addAttribute(sui, {score = goldRate * usedPresent, gift = -usedPresent})
	re.code = 0
	re.gift = 1
	re.score = 2
	return re
end

-- 查询VIP到期信息
local function cmd_queryVipInfo(userId)
	local re = {}
	re.vipInfo = {}
	local nowTime = os.time()
	local nowDate = tonumber(os.date("%Y%m%d", nowTime))
	local sql = string.format("select MemberOrder, UNIX_TIMESTAMP(MemberOverDate) as OverDate from `kfaccountsdb`.`AccountsMember` where UserID=%d", userId)
	local dbConn = addressResolver.getMysqlConnection()
	rows = skynet.call(dbConn, "lua", "query", sql)
	
	for _,row in pairs(rows) do
		table.insert(re.vipInfo, {id = row.MemberOrder, overDate = row.OverDate})
	end
	re.nowTime = nowTime
	return re
end

local function loadPayOrderItemConfig()
	local sql = "SELECT * FROM `kftreasuredb`.`PayOrderItem` WHERE `EndDate`>NOW()"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if type(rows)=="table" then
		local tmp = {}
		for _, row in ipairs(rows) do
			local item = {
				id = tonumber(row.ID),
				price = tonumber(row.Price),
				gold = tonumber(row.Gold),
				goldExtra = tonumber(row.GoldExtra),
				limitTimes = tonumber(row.LimitTimes),
				limitDays = tonumber(row.LimitDays),
				isRecommend = tonumber(row.IsRecommend)==1,
				isPepeatable = tonumber(row.IsRepeatable)==1,
				startTimestamp = timeUtility.makeTimeStamp(row.StartDate),
				endTimestamp = timeUtility.makeTimeStamp(row.EndDate),
				memberOrder = tonumber(row.MemberOrder),
				memberOrderDays = tonumber(row.MemberOrderDays),
				name = row.Name
			}

			if item.id == 8 or item.id == 459 then
				startTime = tonumber(os.date('%H%M%S',item.startTimestamp))
				endTime = tonumber(os.date('%H%M%S',item.endTimestamp))
			end
			
			_payOrderItemHash[item.id] = item
		end
	end

	sql = "SELECT * FROM `kftreasuredb`.`payorderitem_ex`"
	local rowss = skynet.call(dbConn, "lua", "query", sql)
	if type(rowss)=="table" then
		for _, row in ipairs(rowss) do
			local itemr = {
				rewardList = {},
				id = tonumber(row.ID),
			}

			local listReward = row.ItemInfo:split("|")
			for _, item in pairs(listReward) do
				local itemPart = item:split(":")
				local goods = {
					goodsID = tonumber(itemPart[1]),
					goodsCount = tonumber(itemPart[2])
				}
				table.insert(itemr.rewardList,goods)
			end
			
			_payOrderItemHash_EX[itemr.id] = itemr
		end
	end
end

local function addUserPayScoreRecord(platformID, userID, score)
	-- 更新玩家充值记录
	local sql = string.format("SELECT platformID FROM `kfrecorddb`.`UserPayScore` where platformID = %d", platformID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if rows[1] == nil then
		sql = string.format("insert into `kfrecorddb`.`UserPayScore` values(%d,%d,%d)",platformID, userID, score)
		skynet.call(dbConn, "lua", "query", sql)
		return
	end
	sql = string.format("update `kfrecorddb`.`UserPayScore` set score= score + %d, userID=%d where platformID = %d", score, userID, platformID)
	skynet.call(dbConn, "lua", "query", sql)
end

local function monthCardOprator(userID)
	local nowTime = os.time()
	local startTime = nowTime
	local endTime = 0
	local remainDay = 3
	local mysqlConn = addressResolver.getMysqlConnection()
	local sql = string.format("SELECT * FROM `kffishdb`.`t_month_card` where UserId=%d",userID)
	local rows = skynet.call(mysqlConn,"lua","query",sql)
	if rows[1] == nil then
		endTime = nowTime + COMMON_CONST.MONTH_CARD_TIME
		sql = string.format("insert into `kffishdb`.`t_month_card` values(%d,%d,%d)",userID,startTime,endTime)
		skynet.call(mysqlConn, "lua", "query", sql)
	else
		startTime = tonumber(rows[1].StartTime)
		endTime = tonumber(rows[1].EndTime)
		if endTime <= nowTime then
			endTime = nowTime + COMMON_CONST.MONTH_CARD_TIME
		else
			endTime = endTime + COMMON_CONST.MONTH_CARD_TIME
		end
		sql = string.format("update `kffishdb`.`t_month_card` set EndTime=%d where UserId=%d",endTime,userID)
		skynet.call(mysqlConn,"lua","query",sql)
	end

	local nowYear = tonumber(os.date("%Y",nowTime))
	local nowMonth = tonumber(os.date("%m",nowTime))
	local nowDay = tonumber(os.date("%d",nowTime))
	local nowtable = {year=nowYear, month=nowMonth, day=nowDay, hour=00,min=00,sec=00,isdst=false}
	local nowTimeTemp = os.time(nowtable)

	local startYear = tonumber(os.date("%Y",startTime))
	local startMonth = tonumber(os.date("%m",startTime))
	local startDay = tonumber(os.date("%d",startTime))

	local tab = {year=startYear, month=startMonth, day=startDay, hour=00,min=00,sec=00,isdst=false}
	local startTimeTemp = os.time(tab)

	remainDay = math.floor((endTime-startTime)/(24*60*60)) - (math.floor((nowTimeTemp-startTimeTemp)/(24*60*60)))
	
	local messageTitle = string.format("月卡礼包")
	local messageInfo = string.format("您的月卡礼包,还剩%s天",remainDay)
	local itemList = {}
	local item = {
		goodsID = 1001,
		goodsCount = 20000
	}
	table.insert(itemList,item)

	local item = {
		goodsID = 1004,
		goodsCount = 2
	}	
	table.insert(itemList,item)

	local item = {
		goodsID = 1005,
		goodsCount = 2
	}
	table.insert(itemList,item)

	skynet.send(addressResolver.getAddressByServiceName("LS_model_message"),"lua","sendEmailToUser",userID,itemList,messageTitle,messageInfo)
end	

local function checkIsSameDay(dateTime)
	local nowDate = tonumber(os.date("%Y%m%d", os.time()))
	return dateTime == nowDate
end

local function ActivityOperator(userID,rmb,tempScore,payID)
	local curTime = os.time()
	local nowDate = tonumber(os.date("%Y%m%d", curTime))
	local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
	local timeConfig = skynet.call(configAddress,"lua","GetHuoDongTimeInfo")
	local rewardConfig = skynet.call(configAddress,"lua","GetHuoDongRewardInfo")
	local dbConn = addressResolver.getMysqlConnection()

	for k, v in pairs(timeConfig) do
		if curTime < v.startTime or v.endTime < curTime then
			goto continue
		end

		local bSecLoopFlag = false
		local bThrLoopFlag = false
		local bRedPacketLoopFlag = false

		for kk, vv in pairs(rewardConfig) do
			if v.activityType == vv.activityType then
				if vv.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_EVERYDAY_RECHARGE then
					if rmb == vv.needCondition[1].goodsCount then
						local sql = string.format("SELECT LeftTimes,Date FROM `kffishdb`.`t_user_pay` where UserId=%d and PayType=%d and `Index` = %d",userID,vv.activityId,vv.index)
						local rows = skynet.call(dbConn,"lua","query",sql)
						if rows[1] ~= nil then
							local iLeftTime = tonumber(rows[1].LeftTimes)
							if checkIsSameDay(tonumber(rows[1].Date)) then
								local nowDate = tonumber(os.date("%Y%m%d", os.time()))
								local sql = string.format("update `kffishdb`.`t_user_pay` set LeftTimes=%d,Date=%d where UserId=%d and PayType=%d and `Index` = %d",
									iLeftTime+1,nowDate,userID,vv.activityId,vv.index)
								skynet.call(dbConn, "lua", "query", sql)
							else
								--没有领的奖励发邮件给玩家
								for i = 1, iLeftTime do
									local messageTitle = string.format("单笔充值奖励补偿邮件")
									local messageInfo = string.format("这是您未及时领取的单笔充值奖励，请注意查收附件！祝您游戏愉快！")
									skynet.send(addressResolver.getAddressByServiceName("LS_model_message"),"lua","sendEmailToUser",userID,vv.rewardList,messageTitle,messageInfo)
								
									local sql = string.format("insert into `kfrecorddb`.`t_activity_get_reward_type`(`UserId`,`RewardType`,`ActivityId`,`ActivityIndex`,`date`) values(%d,%d,%d,%d,now())",
										userID,1,vv.activityId,vv.index)
									skynet.call(dbConn, "lua", "query", sql)
								end

								local sql = string.format("update `kffishdb`.`t_user_pay` set LeftTimes=%d,Date=%d where UserId=%d and PayType=%d and `Index` = %d",
									1,nowDate,userID,vv.activityId,vv.index)
								skynet.call(dbConn, "lua", "query", sql)
							end
						else
							local sql = string.format("insert into `kffishdb`.`t_user_pay` values(%d,%d,%d,%d,%d,%d)",userID,vv.activityId,vv.index,1,nowDate,0)
							skynet.call(dbConn, "lua", "query", sql)
						end
					end
				end

				if not bSecLoopFlag and vv.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_EVERYDAY_SUM_RECHARGE then
					bSecLoopFlag = true
					local sql = string.format("SELECT Rmb,Date FROM `kffishdb`.`t_user_pay_rmb` where UserId=%d and PayType=%d",userID,vv.activityId)
					local rows = skynet.call(dbConn,"lua","query",sql)
					if rows[1] ~= nil then
						local iRmb = tonumber(rows[1].Rmb)
						if checkIsSameDay(tonumber(rows[1].Date)) then
							local sql = string.format("update `kffishdb`.`t_user_pay_rmb` set Rmb=%d,Date=%d where UserId=%d and PayType=%d",
								iRmb+rmb,nowDate,userID,vv.activityId)
							skynet.call(dbConn, "lua", "query", sql)
						else
							iRmb = 0
							local sql = string.format("update `kffishdb`.`t_user_pay_rmb` set Rmb=%d,Date=%d where UserId=%d and PayType=%d",
								rmb,nowDate,userID,vv.activityId)
							skynet.call(dbConn, "lua", "query", sql)
						end

						for a, b in pairs(rewardConfig) do
							if v.activityType == b.activityType then
								if b.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_EVERYDAY_SUM_RECHARGE then
									local sql = string.format("SELECT LeftTimes,Date,Flag FROM `kffishdb`.`t_user_pay` where UserId=%d and PayType=%d and `Index` = %d",userID,b.activityId,b.index)
									local rows = skynet.call(dbConn,"lua","query",sql)
									if rows[1] ~= nil then
										local leftTimes = tonumber(rows[1].LeftTimes)
										local flag = tonumber(rows[1].Flag)
										if checkIsSameDay(tonumber(rows[1].Date)) then
											if rmb+iRmb >= b.needCondition[1].goodsCount then
												if leftTimes == 0 and flag == 0 then
													local sql = string.format("update `kffishdb`.`t_user_pay` set LeftTimes=%d,Date=%d where UserId=%d and PayType=%d and `Index` = %d",
														1,nowDate,userID,b.activityId,b.index)
													skynet.call(dbConn, "lua", "query", sql)
												end
											end
										else
											if leftTimes == 1 and flag == 0 then
												for i = 1, leftTimes do
													local messageTitle = string.format("日累计充值奖励补偿邮件")
													local messageInfo = string.format("这是您未及时领取的日累计充值奖励，请注意查收附件！祝您游戏愉快！")
													skynet.send(addressResolver.getAddressByServiceName("LS_model_message"),"lua","sendEmailToUser",userID,b.rewardList,messageTitle,messageInfo)
												end
												local sql = string.format("update `kffishdb`.`t_user_pay` set LeftTimes=%d,Date=%d,flag=%d where UserId=%d and PayType=%d and `Index` = %d",
													0,nowDate,1,userID,b.activityId,b.index)
												skynet.call(dbConn, "lua", "query", sql)

												local sql = string.format("insert into `kfrecorddb`.`t_activity_get_reward_type` (`UserId`,`RewardType`,`ActivityId`,`ActivityIndex`,`date`) values(%d,%d,%d,%d,now())",
													userID,1,b.activityId,b.index)
												skynet.call(dbConn, "lua", "query", sql)
											end

											if rmb+iRmb >= b.needCondition[1].goodsCount then	
												local sql = string.format("update `kffishdb`.`t_user_pay` set LeftTimes=%d,Date=%d,flag=%d where UserId=%d and PayType=%d and `Index` = %d",
													1,nowDate,0,userID,b.activityId,b.index)
												skynet.call(dbConn, "lua", "query", sql)							
											end
										end
									else
										if rmb+iRmb >= b.needCondition[1].goodsCount then										
											local sql = string.format("insert into `kffishdb`.`t_user_pay` values(%d,%d,%d,%d,%d,%d)",userID,b.activityId,b.index,1,nowDate,0)
											skynet.call(dbConn, "lua", "query", sql)
										end
									end
								end
							end
						end
					else
						local sql = string.format("insert into `kffishdb`.`t_user_pay_rmb` values(%d,%d,%d,%d)",userID,vv.activityId,rmb,nowDate)
						skynet.call(dbConn, "lua", "query", sql)

						for a, b in pairs(rewardConfig) do
							if v.activityType == b.activityType then
								if b.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_EVERYDAY_SUM_RECHARGE then
									local sql = string.format("SELECT LeftTimes,Date,Flag FROM `kffishdb`.`t_user_pay` where UserId=%d and PayType=%d and `Index` = %d",userID,b.activityId,b.index)
									local dbConn = addressResolver.getMysqlConnection()
									local rows = skynet.call(dbConn,"lua","query",sql)
									if rows[1] ~= nil then
										local leftTimes = tonumber(rows[1].LeftTimes)
										local flag = tonumber(rows[1].Flag)
										if checkIsSameDay(tonumber(rows[1].Date)) then
											if rmb >= b.needCondition[1].goodsCount then
												if leftTimes == 0 and flag == 0 then
													local sql = string.format("update `kffishdb`.`t_user_pay` set LeftTimes=%d,Date=%d where UserId=%d and PayType=%d and `Index` = %d",
														1,nowDate,userID,b.activityId,b.index)
													skynet.call(dbConn, "lua", "query", sql)
												end
											end
										else
											
											if leftTimes == 1 and flag == 0 then
												for i = 1, leftTimes do
													local messageTitle = string.format("日累计充值奖励补偿邮件")
													local messageInfo = string.format("这是您未及时领取的日累计充值奖励，请注意查收附件！祝您游戏愉快！")
													skynet.send(addressResolver.getAddressByServiceName("LS_model_message"),"lua","sendEmailToUser",userID,b.rewardList,messageTitle,messageInfo)
												end
										
												local sql = string.format("update `kffishdb`.`t_user_pay` set LeftTimes=%d,Date=%d,flag=%d where UserId=%d and PayType=%d and `Index` = %d",
													0,nowDate,1,userID,b.activityId,b.index)
												skynet.call(dbConn, "lua", "query", sql)

												local sql = string.format("insert into `kfrecorddb`.`t_activity_get_reward_type` (`UserId`,`RewardType`,`ActivityId`,`ActivityIndex`,`date`) values(%d,%d,%d,%d,now())",
													userID,1,b.activityId,b.index)
												skynet.call(dbConn, "lua", "query", sql)
											end

											if rmb >= b.needCondition[1].goodsCount then		
												local sql = string.format("update `kffishdb`.`t_user_pay` set LeftTimes=%d,Date=%d,flag=%d where UserId=%d and PayType=%d and `Index` = %d",
													1,nowDate,0,userID,b.activityId,b.index)
												skynet.call(dbConn, "lua", "query", sql)							
											end
										end
									else
										if rmb >= b.needCondition[1].goodsCount then
											local sql = string.format("insert into `kffishdb`.`t_user_pay` values(%d,%d,%d,%d,%d,%d)",userID,b.activityId,b.index,1,nowDate,0)
											skynet.call(dbConn, "lua", "query", sql)
										end
									end
								end
							end
						end	
					end	
				end	

				if not bThrLoopFlag and vv.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_SUM_RECHARGE_IN_HD_TIME then
					bThrLoopFlag = true
					local sql = string.format("SELECT Rmb,Date FROM `kffishdb`.`t_user_pay_rmb` where UserId=%d and PayType=%d",userID,vv.activityId)
					local rows = skynet.call(dbConn,"lua","query",sql)
					if rows[1] ~= nil then
						local iRmb = tonumber(rows[1].Rmb)
						local lastDate = tonumber(rows[1].Date)
						local startTime = tonumber(os.date("%Y%m%d", v.startTime))
						if lastDate < startTime then
							iRmb = 0
						end

						local sql = string.format("update `kffishdb`.`t_user_pay_rmb` set Rmb=%d,Date=%d where UserId=%d and PayType=%d",
							iRmb+rmb,nowDate,userID,vv.activityId)
						skynet.call(dbConn, "lua", "query", sql)
			
						for a, b in pairs(rewardConfig) do
							if v.activityType == b.activityType then
								if b.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_SUM_RECHARGE_IN_HD_TIME then
									local sql = string.format("SELECT LeftTimes,Date,Flag FROM `kffishdb`.`t_user_pay` where UserId=%d and PayType=%d and `Index` = %d",userID,b.activityId,b.index)
									local rows = skynet.call(dbConn,"lua","query",sql)
									if rows[1] ~= nil then
										local leftTimes = tonumber(rows[1].LeftTimes)
										local flag = tonumber(rows[1].Flag)							
										if rmb+iRmb >= b.needCondition[1].goodsCount then
											if leftTimes == 0 and flag == 0 then
												local sql = string.format("update `kffishdb`.`t_user_pay` set LeftTimes=%d,Date=%d where UserId=%d and PayType=%d and `Index` = %d",
													1,nowDate,userID,b.activityId,b.index)
												skynet.call(dbConn, "lua", "query", sql)
											end
										end
									else
										if rmb+iRmb >= b.needCondition[1].goodsCount then
											local sql = string.format("insert into `kffishdb`.`t_user_pay` values(%d,%d,%d,%d,%d,%d)",userID,b.activityId,b.index,1,nowDate,0)									
											skynet.call(dbConn, "lua", "query", sql)
										end
									end
								end
							end
						end
					else
						local sql = string.format("insert into `kffishdb`.`t_user_pay_rmb` values(%d,%d,%d,%d)",userID,vv.activityId,rmb,nowDate)
						skynet.call(dbConn, "lua", "query", sql)

						for a, b in pairs(rewardConfig) do
							if v.activityType == b.activityType then
								if b.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_SUM_RECHARGE_IN_HD_TIME then
									local sql = string.format("SELECT LeftTimes,Date,Flag FROM `kffishdb`.`t_user_pay` where UserId=%d and PayType=%d and `Index` = %d",userID,b.activityId,b.index)
									local rows = skynet.call(dbConn,"lua","query",sql)
									if rows[1] ~= nil then
										local leftTimes = tonumber(rows[1].LeftTimes)
										local flag = tonumber(rows[1].Flag)							
										if rmb >= b.needCondition[1].goodsCount then
											if leftTimes == 0 and flag == 0 then
												local sql = string.format("update `kffishdb`.`t_user_pay` set LeftTimes=%d,Date=%d where UserId=%d and PayType=%d and `Index` = %d",
													1,nowDate,userID,b.activityId,b.index)
												skynet.call(dbConn, "lua", "query", sql)
											end
										end
									else
										if rmb >= b.needCondition[1].goodsCount then
											local sql = string.format("insert into `kffishdb`.`t_user_pay` values(%d,%d,%d,%d,%d,%d)",userID,b.activityId,b.index,1,nowDate,0)									
											skynet.call(dbConn, "lua", "query", sql)
										end
									end
								end
							end
						end
					end
				end

				if not bRedPacketLoopFlag and vv.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_RED_PACKET then
					bRedPacketLoopFlag = true
					local sql = string.format("SELECT Rmb,Date FROM `kffishdb`.`t_user_pay_rmb` where UserId=%d and PayType=%d",userID,vv.activityId)
					local rows = skynet.call(dbConn,"lua","query",sql)
					if rows[1] ~= nil then
						local iRmb = tonumber(rows[1].Rmb)
						if checkIsSameDay(tonumber(rows[1].Date)) then
							local sql = string.format("update `kffishdb`.`t_user_pay_rmb` set Rmb=%d,Date=%d where UserId=%d and PayType=%d",
								iRmb+rmb,nowDate,userID,vv.activityId)
							skynet.call(dbConn, "lua", "query", sql)
						else
							local multiple = 0
							for a, b in pairs(rewardConfig) do
								if v.activityType == b.activityType then
									if b.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_RED_PACKET then
										if iRmb >= b.needCondition[1].goodsCount then
											multiple = b.multiple
										end
									end
								end
							end
								
							if multiple ~= 0 then
								local rewardList = {}
								local goods = {
									goodsID = 1001,
									goodsCount = math.floor(iRmb*10000*(multiple-1)),
								}
								table.insert(rewardList,goods)

								local messageTitle = string.format("充值乐翻天奖励补偿邮件")
								local messageInfo = string.format("这是您未及时领取的充值乐翻天奖励,请注意查收附件!祝您游戏愉快!")
								skynet.send(addressResolver.getAddressByServiceName("LS_model_message"),"lua","sendEmailToUser",userID,rewardList,messageTitle,messageInfo)

								local sql = string.format("insert into `kfrecorddb`.`t_activity_get_reward_type` (`UserId`,`RewardType`,`ActivityId`,`ActivityIndex`,`date`) values(%d,%d,%d,%d,now())",
									userID,1,COMMON_CONST.HUO_DONG_ID.HD_ID_RED_PACKET,1)
								skynet.call(dbConn, "lua", "query", sql)
							end

							local sql = string.format("update `kffishdb`.`t_user_pay_rmb` set Rmb=%d,Date=%d where UserId=%d and PayType=%d",
								rmb,nowDate,userID,vv.activityId)
							skynet.call(dbConn, "lua", "query", sql)
						end
					else
						local sql = string.format("insert into `kffishdb`.`t_user_pay_rmb` values(%d,%d,%d,%d)",userID,vv.activityId,rmb,nowDate)
						skynet.call(dbConn, "lua", "query", sql)
					end	
				end

			end
		end

		if v.activityType == COMMON_CONST.HUO_DONG_TYPE.HD_DOUBLE_GOLD then
			if tempScore > 0 then
				if (2 <= payID and payID <= 6) or (27 <= payID and payID <= 31) or (460 <= payID and payID <= 464) or (36 <= payID and payID <= 40) or payID == 46 or payID == 478 or (48 <= payID and payID <= 52) then
					local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_DOUBLE_GOLD
					local bLimit = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "CheckIsEverydayLimit",userID,limitId,1)
					if not bLimit then

						skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "AddLimit",userID,limitId,1)

						local itemList = {}
						table.insert(itemList,{
							goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
							goodsCount = tempScore,
						})

						local messageTitle = string.format("活动期间每日首充翻倍奖励")
						local messageInfo = string.format("这是活动期间每日充冲翻倍奖励，请注意查收附件！祝您游戏愉快！")
						skynet.send(addressResolver.getAddressByServiceName("LS_model_message"),"lua","sendEmailToUser",userID,itemList,messageTitle,messageInfo,1)
					end	
				end	
			end				
		end

		if v.activityType == COMMON_CONST.HUO_DONG_TYPE.HD_CHOU_JIANG then
			local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_CHARGE_PERDAY
			local flag = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "CheckIsEverydayLimit",userID,limitId,1)
			if not flag then
				skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "AddLimit",userID,limitId,rmb)
			end
		end

		::continue::
	end
end

local function cmd_payOrderConfirm(eventData)
	local payID = math.tointeger(eventData.PayID)
	if payID==nil then
		return false, "payID not found"
	end

	local isSandBox = tonumber(eventData.Sandbox)
	local platformID = tonumber(eventData.UserID)
	local userItem = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getUserItemByPlatformID", platformID)
	if not userItem then
		return false, "101 user not online"
	end

	local attr = ServerUserItem.getAttribute(userItem, {"userID", "agent", "serverID"})
	
	local sql = string.format(
		"call kftreasuredb.sp_pay_order_confirm('%s', %d, %d, '%s', %.2f, %d, '%s',%d)",
		mysqlutil.escapestring(eventData.OrderID),
		eventData.PayChannel,
		eventData.UserID,
		mysqlutil.escapestring(eventData.CurrencyType),
		eventData.CurrencyAmount,
		payID,
		eventData.SubmitTime,
		isSandBox
	)
	
	local mysqlConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(mysqlConn, "lua", "call", sql)
	if tonumber(rows[1].retCode)~=0 then
		return false, rows[1].retMsg
	end

	local score = tonumber(rows[1].Score)
	local tempScore = score
	local memberOrder = tonumber(rows[1].MemberOrder)
	local userRight = tonumber(rows[1].UserRight)
	local currentScore = tonumber(rows[1].currentScore)
	local currentInsure = tonumber(rows[1].currentInsure)
	local contribution = tonumber(rows[1].CurrentContribution)

	local exGold = 1
	local bFind = false
	local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
	local infoConfig = skynet.call(configAddress,"lua","GetvipInfo")
	for k, v in pairs(infoConfig) do 
		if contribution < v.rmb then
			bFind = true
			memberOrder = v.vipLevel - 1
			break
		end 
	end

	if not bFind and contribution ~= 0 then
		memberOrder = #infoConfig
		exGold = infoConfig[memberOrder].exGold
	else
		exGold = infoConfig[memberOrder].exGold
	end

	if payID == 53 or payID == 54 then
		exGold = 1
	end

	score = math.floor(score*exGold) --vip充值加成 

	sql = string.format("UPDATE `kfaccountsdb`.`AccountsInfo` SET `MemberOrder`=%d WHERE `UserID`=%d",memberOrder,attr.userID)
	skynet.call(mysqlConn, "lua", "query", sql)

	ServerUserItem.setAttribute(userItem, {
		insure=currentInsure,
		memberOrder=memberOrder,
		userRight=userRight,
		contribution=contribution,
	})

	if score ~= 0 then
		ServerUserItem.addAttribute(userItem,{score=score})
	
		skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",attr.userID,
			COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,score,COMMON_CONST.ITEM_SYSTEM_TYPE.PAY_ADD)
	end

	local ItemReward = _payOrderItemHash_EX[payID]
	if ItemReward then
		if tonumber(rows[1].varAvailableTimes) ~= 0 then
			for k, v in pairs(ItemReward.rewardList) do
				if v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
					ServerUserItem.addAttribute(userItem,{score=v.goodsCount})

					local sql = string.format("update `kftreasuredb`.`payOrderConfirm` SET `ExtraGold`= %d where `OrderID`='%s'",
						v.goodsCount,mysqlutil.escapestring(eventData.OrderID))
					skynet.call(mysqlConn, "lua", "query", sql)

				elseif v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_FISH then
					ServerUserItem.addAttribute(userItem,{gift=v.goodsCount})
				end
				skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",attr.userID,
					v.goodsID,v.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.PAY_ADD)
			end 
		else
			ItemReward = nil
		end
	end

	if attr.agent~=0 then
		cmd_PaymentNotify(attr.agent,attr.userID)
		skynet.send(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "notifyUserPayChange",attr.agent,contribution)
	end
	
	if attr.serverID~=0 then
		skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", {attr.serverID}, COMMON_CONST.LSNOTIFY_EVENT.EVT_LSNOTIFY_PAY_ORDER_CONFIRM, {
			userID=attr.userID,
			orderID=eventData.OrderID,
			currencyType=eventData.CurrencyType,
			currencyAmount=eventData.CurrencyAmount,
			payID=payID,
			score=score,
			memberOrder=memberOrder,
			userRight=userRight,
			contribution=tonumber(rows[1].Contribution),
			ItemReward = ItemReward,
		})
	end

	--添加玩家总充值记录信息
	addUserPayScoreRecord(platformID, attr.userID, score)
	skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "dispatch", LS_EVENT.EVT_LS_PAY_ORDER_CONFIRM, {
		platformID=platformID,
		userID=tonumber(rows[1].UserID),
	})

	skynet.send(addressResolver.getAddressByServiceName("LS_model_gunUplevel"),"lua","checkGunLevelUp",memberOrder,attr.userID,attr.agent)

	--月卡礼包处理
	if payID == 21 or payID == 465 or payID == 35 then
		monthCardOprator(attr.userID)
	end

	--活动处理
	if math.tointeger(eventData.CurrencyAmount) > 0 then
		ActivityOperator(attr.userID,math.tointeger(eventData.CurrencyAmount),tempScore,payID)
	end
	local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_FIRST_CHARGE
	skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "AddLimit",attr.userID,limitId,1)

	local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_PAY_RMB_NEW
	skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "AddLimit",attr.userID,limitId,tonumber(eventData.CurrencyAmount))
	
	local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_PAY_RMB_NEW_1
	skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "AddLimit",attr.userID,limitId,tonumber(eventData.CurrencyAmount))

	if memberOrder < 4 then
		local bLimit = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "CheckIsForeverLimit",attr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP4,1)
		if not bLimit then
			skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "AddLimit",attr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP4,1)
		end
	end

	--火焰炮台礼包充值增加火焰微利道具掉落池数量
	if payID==58 then
		local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_FIRE_PIECE
		skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "AddLimit",attr.userID,limitId,40)

		skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "AddLimit",attr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_SPEC_CANNON,1)

		skynet.send(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "queryPayOrderItem", attr.agent,attr.userID)
	elseif payID==57 then
		skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "AddLimit",attr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_SPEC_CANNON,1)

		skynet.send(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "queryPayOrderItem", attr.agent,attr.userID)
	end

	return true
end

local function cmd_queryPayOrderItem(agent, userID)		
	local sql = string.format("call kftreasuredb.sp_query_pay_order_item_info(%d)", userID)
	local mysqlConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(mysqlConn, "lua", "call", sql)	
	
	local pbObj = {
		list = {},
		todayFlag = 0,
	}

	local curTime = os.time()
	local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
	local timeConfig = skynet.call(configAddress,"lua","GetHuoDongTimeInfo")
	local rewardConfig = skynet.call(configAddress,"lua","GetHuoDongRewardInfo")

	for k, v in pairs(timeConfig) do
		if v.startTime <= curTime and curTime < v.endTime then
			if v.activityType == COMMON_CONST.HUO_DONG_TYPE.HD_DOUBLE_GOLD then
				local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_DOUBLE_GOLD
				local bLimit = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "CheckIsEverydayLimit",userID,limitId,1)
				if not bLimit then
					pbObj.todayFlag = 1
				end
			end
		end
	end

	local currentTS = math.floor(skynet.time())
	for _, row in ipairs(rows) do
		row.ItemID = tonumber(row.ItemID)
		row.AvailableTimes = tonumber(row.AvailableTimes)
		
		--火焰礼包和寒冰礼包交替出现
		if row.ItemID == 57 then
			local nowPay = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "GetLimitCount",userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_SPEC_CANNON)

			if nowPay%2 == 1 then
				goto continue
			end

			skynet.error(string.format("cmd_queryPayOrderItem nowPay = %d", nowPay))
		elseif row.ItemID == 58 then
			local nowPay = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "GetLimitCount",userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_SPEC_CANNON)

			if nowPay%2 == 0 then
				goto continue
			end

			
			skynet.error(string.format("cmd_queryPayOrderItem nowPay = %d", nowPay))
		end


		local configItem = _payOrderItemHash[row.ItemID]
		
		if configItem then
			local endSecond = configItem.endTimestamp - currentTS

			if configItem.id == 8 or configItem.id == 459 then
				if row.AvailableTimes == 0 then
					goto continue
				end
				local startTime = tonumber(os.date('%H%M%S',configItem.startTimestamp))
				local endTime = tonumber(os.date('%H%M%S',configItem.endTimestamp))
				local nowTime = tonumber(os.date('%H%M%S',CurCounts))
				if nowTime < startTime or nowTime > endTime then
					goto continue
				end

				--203000表示时间:20:30:00
				local endDate = tostring(endTime)
				local endHour= tonumber(string.sub(endDate,1,2))
				local endMin = tonumber(string.sub(endDate,3,4))
				local endSec = tonumber(string.sub(endDate,5,6))

				local nowDate = tostring(nowTime)
				local nowHour= tonumber(string.sub(nowDate,1,2))
				local nowMin = tonumber(string.sub(nowDate,3,4))
				local nowSec = tonumber(string.sub(nowDate,5,6))

				endSecond = endHour*60*60 + endMin*60 + endSec - (nowHour*60*60+nowMin*60+nowSec)
			end

			if endSecond > 0 then
				table.insert(pbObj.list, {
					id = configItem.id,
					price = configItem.price,
					gold = configItem.gold,
					goldExtra = configItem.goldExtra,
					limitTimes = configItem.limitTimes,
					limitDays = configItem.limitDays,
					
					isRecommend = configItem.isRecommend,
					isPepeatable = configItem.isPepeatable,
					startSecond = configItem.startTimestamp - currentTS,
					endSecond = endSecond,
					memberOrder = configItem.memberOrder,
					memberOrderDays = configItem.memberOrderDays,
					name = configItem.name,
					availableTimes = row.AvailableTimes,
				})			
			end
		end

		::continue::
	end
	
	skynet.send(agent, "lua", "forward", 0x000500, pbObj)
end

local function cmd_notifyVipInfo(agent,userId,contribution)
	local pbObj = {
		currentCumulativeRechargeAmount = contribution,
		vipPrivilegeInfo = {}
	}

	local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
	local infoConfig = skynet.call(configAddress,"lua","GetvipInfo")
	for k, v in pairs(infoConfig) do 		
		local info = {
			vipLevel = v.vipLevel,
			vipDesc = v.tips,
			vipCumulativeRechargeAmount = v.rmb
		}
		table.insert(pbObj.vipPrivilegeInfo,info)
	end

	skynet.send(agent,"lua","forward",0x00050B,pbObj)
end

local function cmd_notifyUserPayChange(agent,rmb)
	local pbObj = {
		currentCumulativeRechargeAmount = rmb,
	}

	skynet.send(agent,"lua","forward",0x00050C,pbObj)
end

-- [gm]礼券换实物
local function cmd_presentToItem(data)
	local pid = tonumber(data.pid) -- 统一平台id
	local num = tonumber(data.num) -- 礼券数量
	if pid == nil or num == nil or num <= 0 then
		return false, "101 param error"
	end

	local userItem = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getUserItemByPlatformID", pid)
	if not userItem then
		return false, "102 other error"
	end

	local attr = ServerUserItem.getAttribute(userItem, {"userID","gift"})
	local count = skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "GetItemCount",attr.userID,COMMON_CONST.ITEM_ID.ITEM_ID_FISH)
	if count < num then
		return false, "103 param error"
	end

	local sql = string.format("call kftreasuredb.p_change_present(%d, %d)", pid, -num)
	local dbConn = addressResolver.getMysqlConnection()
	skynet.call(dbConn, "lua", "call", sql)

	ServerUserItem.addAttribute(userItem, {gift = -num})

	skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",attr.userID,
		COMMON_CONST.ITEM_ID.ITEM_ID_FISH,-num,COMMON_CONST.ITEM_SYSTEM_TYPE.EXCHANGE)

	return true, ""
end

local function notifyUserEmailChange(userId)
	if userId ~= 0 then
		local userItem = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getUserItemByUserID", userId)
		if userItem then
			skynet.send(addressResolver.getAddressByServiceName("LS_model_message"),"lua","notifyUserEmailChange",userItem)
		end
	else
		local userList = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getAllUserInfo")
		for _, v in pairs(userList) do 
			skynet.send(addressResolver.getAddressByServiceName("LS_model_message"),"lua","notifyUserEmailChange",v.sui)
		end
	end
end

local function notifyReloadSystemMessage()
	skynet.call(addressResolver.getAddressByServiceName("LS_model_message"),"lua","reloadLogonMessage")
	local userList = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getAllUserInfo")
	for _, v in pairs(userList) do 
		skynet.send(addressResolver.getAddressByServiceName("LS_model_message"),"lua","notifyUserEmailChange",v.sui,true)
	end
end	

local function cmd_delSystemEmail(data)
	local emailId = tonumber(data.emailId)
	local emailType = tonumber(data.emailType)
	if emailId == nil or emailType == nil or emailType < 1 or emailType > 3 then
		return false, "101 param error"
	end

	local dbConn = addressResolver.getMysqlConnection()
	if emailType == 1 then
		local sql = string.format("DELETE FROM `kfaccountsdb`.`LogonSystemMessage` WHERE ID=%d",emailId)
		skynet.call(dbConn, "lua", "query", sql)
	elseif emailType == 2 then
		local sql = string.format("DELETE FROM `kfplatformdb`.`SystemMessage` WHERE ID=%d",emailId)
		skynet.call(dbConn, "lua", "query", sql)
	else
		local sql = string.format("DELETE FROM `kfplatformdb`.`SystemMessage` WHERE ID=%d",emailId)
		skynet.call(dbConn, "lua", "query", sql)
		sql = string.format("DELETE FROM `kfaccountsdb`.`LogonSystemMessage` WHERE ID=%d",emailId)
		skynet.call(dbConn, "lua", "query", sql)
	end

	notifyReloadSystemMessage()

	return true, ""
end	

local function cmd_editSystemEmail(data)
	local emailId = tonumber(data.emailId)
	local emailType = tonumber(data.emailType)
	local messageType = tonumber(data.messageType)
	local serverRange = tonumber(data.serverRange)
	local messageTitle = data.messageTitle
	local messageInfo = data.messageInfo
	local startTime = data.startTime
	local endTime = data.endTime

	if emailId == nil or emailType == nil or emailType < 1 or emailType > 3 or messageType == nil or serverRange == nil or messageTitle == nil or messageInfo == nil or startTime == nil or endTime == nil then
		return false, "101 param error"
	end

	local dbConn = addressResolver.getMysqlConnection()
	if emailType == 1 then
		local sql = string.format("UPDATE `kfaccountsdb`.`LogonSystemMessage` SET Type=%d,ServerRange=%d,MessageTitle='%s',MessageString='%s',StartTime='%s',EndTime='%s' WHERE ID=%d",
			messageType,serverRange,mysqlutil.escapestring(messageTitle),mysqlutil.escapestring(messageInfo),mysqlutil.escapestring(startTime),mysqlutil.escapestring(endTime),emailId)
		skynet.call(dbConn, "lua", "query", sql)
	elseif emailType == 2 then
		local sql = string.format("UPDATE `kfplatformdb`.`SystemMessage` SET Type=%d,ServerRange=%d,MessageTitle='%s',MessageString='%s',StartTime='%s',EndTime='%s' WHERE ID=%d",
			messageType,serverRange,mysqlutil.escapestring(messageTitle),mysqlutil.escapestring(messageInfo),mysqlutil.escapestring(startTime),mysqlutil.escapestring(endTime),emailId)
		skynet.call(dbConn, "lua", "query", sql)
	else
		local sql = string.format("UPDATE `kfplatformdb`.`SystemMessage` SET Type=%d,ServerRange=%d,MessageTitle='%s',MessageString='%s',StartTime='%s',EndTime='%s' WHERE ID=%d",
			messageType,serverRange,mysqlutil.escapestring(messageTitle),mysqlutil.escapestring(messageInfo),mysqlutil.escapestring(startTime),mysqlutil.escapestring(endTime),emailId)
		skynet.call(dbConn, "lua", "query", sql)
	
		sql = string.format("UPDATE `kfaccountsdb`.`LogonSystemMessage` SET Type=%d,ServerRange=%d,MessageTitle='%s',MessageString='%s',StartTime='%s',EndTime='%s' WHERE ID=%d",
			messageType,serverRange,mysqlutil.escapestring(messageTitle),mysqlutil.escapestring(messageInfo),mysqlutil.escapestring(startTime),mysqlutil.escapestring(endTime),emailId)
		skynet.call(dbConn, "lua", "query", sql)
	end

	notifyReloadSystemMessage()

	return true, ""
end	

local function cmd_addSystemEmail(data)
	--1:kfaccountsdb.logonsystemmessage
	--2:qpplstformdb.systemmessage
	--3:上面的两个表都要添加
	local emailType = tonumber(data.emailType)
	local messageType = tonumber(data.messageType)
	local serverRange = tonumber(data.serverRange)
	local messageTitle = data.messageTitle
	local messageInfo = data.messageInfo
	local startTime = data.startTime
	local endTime = data.endTime

	if emailType == nil or emailType < 1 or emailType > 3 or messageType == nil or serverRange == nil or messageTitle == nil or messageInfo == nil or startTime == nil or endTime == nil then
		return false, "101 param error"
	end

	local dbConn = addressResolver.getMysqlConnection()
	if emailType == 1 then
		local sql = string.format("insert into `kfaccountsdb`.`LogonSystemMessage`(Type,ServerRange,MessageTitle,MessageString,StartTime,endTime) values(%d,%d,'%s','%s','%s','%s')",
			messageType,serverRange,mysqlutil.escapestring(messageTitle),mysqlutil.escapestring(messageInfo),mysqlutil.escapestring(startTime),mysqlutil.escapestring(endTime))
		skynet.call(dbConn, "lua", "query", sql)
	elseif emailType == 2 then
		local sql = string.format("insert into `kfplatformdb`.`SystemMessage`(Type,ServerRange,MessageTitle,MessageString,StartTime,endTime) values(%d,%d,'%s','%s','%s','%s')",
			messageType,serverRange,mysqlutil.escapestring(messageTitle),mysqlutil.escapestring(messageInfo),mysqlutil.escapestring(startTime),mysqlutil.escapestring(endTime))
		skynet.call(dbConn, "lua", "query", sql)
	else
		local sql = string.format("insert into `kfaccountsdb`.`LogonSystemMessage`(Type,ServerRange,MessageTitle,MessageString,StartTime,endTime) values(%d,%d,'%s','%s','%s','%s')",
			messageType,serverRange,mysqlutil.escapestring(messageTitle),mysqlutil.escapestring(messageInfo),mysqlutil.escapestring(startTime),mysqlutil.escapestring(endTime))
		skynet.call(dbConn, "lua", "query", sql)
	
		sql = string.format("insert into `kfplatformdb`.`SystemMessage`(Type,ServerRange,MessageTitle,MessageString,StartTime,endTime) values(%d,%d,'%s','%s','%s','%s')",
			messageType,serverRange,mysqlutil.escapestring(messageTitle),mysqlutil.escapestring(messageInfo),mysqlutil.escapestring(startTime),mysqlutil.escapestring(endTime))
		skynet.call(dbConn, "lua", "query", sql)
	end

	notifyReloadSystemMessage()

	return true, ""
end	

local function cmd_addUserEmail(data)
	local userID = tonumber(data.userID)
	local messageTitle = data.messageTitle
	local messageInfo = data.messageInfo
	local startTime = data.startTime
	local goodsInfo = data.goodsInfo

	if userID == nil or messageTitle == nil or messageInfo == nil or startTime == nil then
		return false, "101 param error"
	end

	local dbConn = addressResolver.getMysqlConnection()
	if userID == 0 then
		local sql = string.format("SELECT UserID FROM `kfaccountsdb`.`AccountsInfo` WHERE Status <> 4")
		local rows = skynet.call(dbConn, "lua", "query", sql)
		if type(rows) == "table" then
			for _, row in pairs(rows) do
				if goodsInfo ~= nil then
					local sql = string.format("insert into `kfaccountsdb`.`LogonUsersMessage`(UserID,MessageTitle,MessageString,StartTime,GoodsInfo) values(%d,'%s','%s','%s','%s')",
						row.UserID,mysqlutil.escapestring(messageTitle),mysqlutil.escapestring(messageInfo),mysqlutil.escapestring(startTime),mysqlutil.escapestring(goodsInfo))
					skynet.call(dbConn, "lua", "query", sql)
				else
					local sql = string.format("insert into `kfaccountsdb`.`LogonUsersMessage`(UserID,MessageTitle,MessageString,StartTime,GoodsInfo) values(%d,'%s','%s','%s','')",
						row.UserID,mysqlutil.escapestring(messageTitle),mysqlutil.escapestring(messageInfo),mysqlutil.escapestring(startTime))
					skynet.call(dbConn, "lua", "query", sql)
				end
			end	
		end
	else
		if goodsInfo ~= nil then
			local sql = string.format("insert into `kfaccountsdb`.`LogonUsersMessage`(UserID,MessageTitle,MessageString,StartTime,GoodsInfo) values(%d,'%s','%s','%s','%s')",
				userID,mysqlutil.escapestring(messageTitle),mysqlutil.escapestring(messageInfo),mysqlutil.escapestring(startTime),mysqlutil.escapestring(goodsInfo))
			skynet.call(dbConn, "lua", "query", sql)
		else
			local sql = string.format("insert into `kfaccountsdb`.`LogonUsersMessage`(UserID,MessageTitle,MessageString,StartTime,GoodsInfo) values(%d,'%s','%s','%s','')",
				userID,mysqlutil.escapestring(messageTitle),mysqlutil.escapestring(messageInfo),mysqlutil.escapestring(startTime))
			skynet.call(dbConn, "lua", "query", sql)
		end
	end

	notifyUserEmailChange(userID)

	return true, ""
end

local function cmd_delUserEmail(data)
	local userId = tonumber(data.userId)
	local emailId = tonumber(data.emailId)

	if userId == nil or emailId == nil then
		return false, "101 param error"
	end

	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("DELETE FROM `kfaccountsdb`.`LogonUsersMessage` WHERE ID=%d AND UserID=%d",emailId,userId)
	skynet.call(dbConn, "lua", "query", sql)

	notifyUserEmailChange(userId)

	return true, ""
end	

local function cmd_changeScore(data)
	local userID = tonumber(data.userId)
	local gold = tonumber(data.gold)
	local present = tonumber(data.present)
	local vip = tonumber(data.vip)
	local vipDays = tonumber(data.vipDays)
	local loveliness = tonumber(data.loveliness)

	local dbConn = addressResolver.getMysqlConnection()

	local userItem = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getUserItemByUserID", userID)
	if not userItem then
		return false, "101 user not online"
	end
	local attr = ServerUserItem.getAttribute(userItem, {"userID","agent","serverID","memberOrder","userRight"})
	if attr.serverID ~= 0 then
		return false, "102 user in game"
	end

	if vip ~= nil and vip >= 0 and vipDays > 0 then
		if attr.memberOrder < vip then
			ServerUserItem.setAttribute(userItem,{memberOrder=vip})
			local sql = string.format("UPDATE `kfaccountsdb`.`AccountsInfo` SET `MemberOrder`=%d WHERE `UserID`=%d",vip,attr.userID)
			skynet.call(dbConn, "lua", "query", sql)
		end

		local nowTime = os.time() + vipDays*24*60*60
		local nowDate = os.date("%Y-%m-%d %H:%M:%S", nowTime)
		
		local sql = string.format("INSERT INTO `kfaccountsdb`.`AccountsMember` (`UserID`,`memberOrder`,`UserRight`,`MemberOverDate`) VALUES (%d,%d,%d,'%s') ON DUPLICATE KEY UPDATE `MemberOverDate`='%s'",
		 	attr.userID,vip,attr.userRight,mysqlutil.escapestring(nowDate),mysqlutil.escapestring(nowDate))
		skynet.call(dbConn, "lua", "query", sql)
	end

	if loveliness ~= nil and loveliness ~= 0 then
		ServerUserItem.addAttribute(userItem, {loveliness=loveliness})
		local sql = string.format("UPDATE `kfaccountsdb`.`AccountsInfo` SET `LoveLiness`=`LoveLiness`+%d WHERE `UserID`=%d",loveliness,attr.userID)
		skynet.call(dbConn, "lua", "query", sql)

		if attr.agent ~= 0 then
			skynet.send(attr.agent, "lua", "forward", 0x000102, {loveLiness=attr.loveliness})
		end
	end

	--背包
	if gold ~= nil and gold ~= 0 then
		ServerUserItem.addAttribute(userItem, {score = gold})
		skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",attr.userID,
			COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,gold,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_CHANG_SCORE_API)
	end

	if present ~= nil and present ~= 0 then
		ServerUserItem.addAttribute(userItem, {gift = present})
		skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",attr.userID,
			COMMON_CONST.ITEM_ID.ITEM_ID_FISH,present,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_CHANG_SCORE_API)
	end

	return true, ""
end

local function cmd_kickUser(data)
	--踢人并冻结的话只传userId，解冻的话isCancel=1
	local userID = tonumber(data.userId)
	local isCancel = tonumber(data.isCancel)

	local dbConn = addressResolver.getMysqlConnection()
	if isCancel ~= nil and isCancel == 1 then
		local sql = string.format("UPDATE `kfaccountsdb`.`AccountsInfo` SET `Status`=0 WHERE `UserID`=%d",userID)
		skynet.call(dbConn, "lua", "query", sql)
	else
		local sql = string.format("UPDATE `kfaccountsdb`.`AccountsInfo` SET `Status`=1 WHERE `UserID`=%d",userID)
		skynet.call(dbConn, "lua", "query", sql)

		skynet.send(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "GMkickLS",userID,LS_CONST.USER_STATUS.US_NULL)
	end
end	

local function cmd_testPay(sui,goodsID)
	local test = ServerUserItem.getAttribute(sui, {"platformID"}) -- 获取身上金币
	local testOrder = os.date("%Y%m%d%H%M%S", os.time())
	testOrder = "test________"..testOrder
	local event = {OrderID=testOrder,
	PayChannel="1",
	PayID=goodsID,
	UserID=tostring(test.platformID),
	CurrencyType="CNY",
	CurrencyAmount=tostring(_payOrderItemHash[goodsID].price),
	SubmitTime=os.date("%Y-%m-%d %H:%M:%S", os.time()),
	Sandbox = 1,}

	skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "payOrderConfirm", event)
end	

local function cmd_changeControlRate(data)
	local tableType = tonumber(data.tableType)
	if tableType == 1 then
		local userId = tonumber(data.userId)
		local fishId = tonumber(data.fishId)
		local critRate = tonumber(data.critRate)
		local missRate = tonumber(data.missRate)
		local startTime = data.startTime
		local endTime = data.endTime
		local insertTime = data.insertTime

		local dbConn = addressResolver.getMysqlConnection()
		if fishId == 9999 then
			local sql = string.format("DELETE FROM `kffishdb`.`t_control_crit_rate` WHERE UserId=%d",userId)
			skynet.call(dbConn, "lua", "query", sql)
		end 

		local sql = string.format("insert into `kffishdb`.`t_control_crit_rate` (UserId,FishId,CritRate,MissRate,StartTime,EndTime,InsertTime) values(%d,%d,%f,%f,'%s','%s','%s') ON DUPLICATE KEY UPDATE\
			CritRate=%f,MissRate=%f,StartTime='%s',EndTime='%s',InsertTime='%s'",
			userId,fishId,critRate,missRate,mysqlutil.escapestring(startTime),mysqlutil.escapestring(endTime),mysqlutil.escapestring(insertTime),
			critRate,missRate,mysqlutil.escapestring(startTime),mysqlutil.escapestring(endTime),mysqlutil.escapestring(insertTime))
		skynet.send(dbConn, "lua", "execute", sql)
	elseif tableType == 2 then
		local userId = tonumber(data.userId)
		local fishId = tonumber(data.fishId)
		local addRate = tonumber(data.addRate)
		local startTime = data.startTime
		local endTime = data.endTime
		local insertTime = data.insertTime

		local dbConn = addressResolver.getMysqlConnection()
		if fishId == 9999 then
			local sql = string.format("DELETE FROM `kffishdb`.`t_control_fish_rate` WHERE UserId=%d",userId)
			skynet.call(dbConn, "lua", "query", sql)
		end 

		local sql = string.format("insert into `kffishdb`.`t_control_fish_rate` (UserId,FishId,AddRate,StartTime,EndTime,InsertTime) values(%d,%d,%f,'%s','%s','%s') ON DUPLICATE KEY UPDATE\
			AddRate=%f,StartTime='%s',EndTime='%s',InsertTime='%s'",
			userId,fishId,addRate,mysqlutil.escapestring(startTime),mysqlutil.escapestring(endTime),mysqlutil.escapestring(insertTime),
			addRate,mysqlutil.escapestring(startTime),mysqlutil.escapestring(endTime),mysqlutil.escapestring(insertTime))
		skynet.send(dbConn, "lua", "execute", sql)
	elseif tableType == 3 then
		local userId = tonumber(data.userId)
		local addRate = tonumber(data.addRate)
		local isDel = tonumber(data.isDel)
		local dbConn = addressResolver.getMysqlConnection()
		if isDel == 1 then
			local sql = string.format("DELETE FROM `kffishdb`.`t_control_world_boss_rate` WHERE `Index`=%d",userId)
			skynet.send(dbConn, "lua", "execute", sql)
		else
			local sql = string.format("insert into `kffishdb`.`t_control_world_boss_rate`(UserId,AddRate) VALUES(%d,%f)",userId,addRate)
			skynet.send(dbConn, "lua", "execute", sql)
		end
	elseif tableType == 4 then
		local userId = tonumber(data.userId)
		local addRate = tonumber(data.addRate)
		local isDel = tonumber(data.isDel)
		local dbConn = addressResolver.getMysqlConnection()
		if isDel == 1 then
			local sql = string.format("DELETE FROM `kffishdb`.`t_control_time_boss_rate` WHERE `Index`=%d",userId)
			skynet.send(dbConn, "lua", "execute", sql)
		else
			local sql = string.format("insert into `kffishdb`.`t_control_time_boss_rate`(UserId,AddRate) VALUES(%d,%f)",userId,addRate)
			skynet.send(dbConn, "lua", "execute", sql)
		end
	else
		return false, "101 param error"
	end

	return true, ""
end

local function cmd_addInvitationCode(data)
	local tableType = tonumber(data.tableType)
	local userId = tonumber(data.userId)
	if tableType == 1 then
		local code = data.invitationCode
		local createTime = data.createTime
		if not userId or not code or not createTime then
			return false, "101 param error"
		end

		local dbConn = addressResolver.getMysqlConnection()
		local sql = string.format("insert into `kffishdb`.`t_user_invitation_code` (UserId,invitationCode,CreateTime) values(%d,'%s','%s') ON DUPLICATE KEY UPDATE\
	 		invitationCode='%s',CreateTime='%s'",userId,mysqlutil.escapestring(code),mysqlutil.escapestring(createTime),mysqlutil.escapestring(code),mysqlutil.escapestring(createTime))
		skynet.send(dbConn,"lua","execute",sql)
	elseif tableType == 2 then
		local mark = data.Mark
		if not userId or not mark then
			return false, "102 param error"
		end

		local dbConn = addressResolver.getMysqlConnection()
		local sql = string.format("UPDATE `kffishdb`.`t_user_invitation_user` SET Mark='%s' where UserId=%d",mysqlutil.escapestring(mark),userId)
		skynet.send(dbConn,"lua","execute",sql)
	else
		return false, "103 param error"
	end

	return true, ""
end

local function cmd_changeDeduct(data)
	local appID = tonumber(data.appID)
	local temType = tonumber(date.tableType)
	local deductNum = tonumber(data.num)
	local mark = data.mark
	if not appID or not deductNum or not temType or appID <= 0 or deductNum <= 0 then
		return false, "101 param error"
	end

	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("call `kffishdb`.`sp_deduct_appid` (%d,%d,%d,'%s')",appID,deductNum,temType,mark)
	local ret = skynet.call(dbConn, "lua", "call", sql)[1]
	if tonumber(ret.retCode) ~= 0 then		
		return false, "102 param error"
	end

	return true, ""
end

local function cmd_hideSignature(data)
	local opType = tonumber(data.opType) --操作的是个人还是所有人，0个人，1所有人
	local hideType = tonumber(data.hideType)--是屏蔽还是去掉屏蔽，0屏蔽，1放开屏蔽
	local userID = tonumber(data.userID) --玩家id，如果opType==1,那这边随便传一个数

	if not opType or not hideType then
		return false, "101 param error"
	end 

	if opType == 0 then
		local HideFlag = 0
		if hideType == 0 then
			HideFlag = 1
		end

		local dbConn = addressResolver.getMysqlConnection()
		local sql = string.format("UPDATE `kfaccountsdb`.`accountssignature` SET `HideFlag`=%d WHERE `UserID`=%d",HideFlag,userID)
		skynet.send(dbConn,"lua","execute",sql)
	else
		local HideFlag = 0
		if hideType == 0 then
			HideFlag = 1
		end

		local dbConn = addressResolver.getMysqlConnection()
		local sql = string.format("INSERT INTO `kfrecorddb`.`t_record_hide_all_signature` (`ID`,`HideAllFlag`) VALUES(1,%d) ON DUPLICATE KEY UPDATE HideAllFlag=%d",HideFlag,HideFlag)
		skynet.send(dbConn,"lua","execute",sql)
	end

	return true, ""
end

local function onCheckTimeStartOrEnd()
	local nowDate = tonumber(os.date("%H%M%S",os.time()))
	local bChange = false

	if not bStartFlag then
		if startTime <= nowDate and nowDate <= endTime then
			bChange = true
			bStartFlag = true
		end
	else
		if nowDate < startTime or nowDate > endTime then
			bChange = true
			bStartFlag = false
		end
	end

	if bChange then
		local userList = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getAllUserInfo")
		for _, v in pairs(userList) do 
			local attr = ServerUserItem.getAttribute(v.sui,{"agent","userID","serverID"})
			if attr and attr.agent ~= 0 then
				cmd_queryPayOrderItem(attr.agent,attr.userID)
			end
		end
	end
end

local conf = {
	methods = {
		["queryPayOrderItem"] = {["func"]=cmd_queryPayOrderItem, ["isRet"]=false},
		["payOrderConfirm"] = {["func"]=cmd_payOrderConfirm, ["isRet"]=true},
		
		["PaymentNotify"] = {["func"]=cmd_PaymentNotify, ["isRet"]=false},
		["ChangePaymentNotify"] = {["func"]=cmd_ChangePaymentNotify, ["isRet"]=false},
		["queryFreeScore"] = {["func"]=cmd_queryFreeScore, ["isRet"]=true},
		["getFreeScore"] = {["func"]=cmd_getFreeScore, ["isRet"]=true},
		
		["queryVipFreeScore"] = {["func"]=cmd_queryVipFreeScore, ["isRet"]=false},
		["getVipFreeScore"] = {["func"]=cmd_getVipFreeScore, ["isRet"]=true},
		
		["queryVipInfo"] = {["func"]=cmd_queryVipInfo, ["isRet"]=true},
		
		["getPresentScore"] = {["func"]=cmd_getPresentScore, ["isRet"]=true},
		["getLovelinessScore"] = {["func"]=cmd_getLovelinessScore, ["isRet"]=true},
		["notifyVipInfo"] = {["func"]=cmd_notifyVipInfo, ["isRet"]=false},
		["notifyUserPayChange"] = {["func"]=cmd_notifyUserPayChange, ["isRet"]=false},
		
		-- gm接口
		["presentToItem"] = {["func"]=cmd_presentToItem, ["isRet"]=true},
		["delSystemEmail"] = {["func"]=cmd_delSystemEmail, ["isRet"]=true},
		["editSystemEmail"] = {["func"]=cmd_editSystemEmail, ["isRet"]=true},
		["addSystemEmail"] = {["func"]=cmd_addSystemEmail, ["isRet"]=true},
		["addUserEmail"] = {["func"]=cmd_addUserEmail, ["isRet"]=true},
		["delUserEmail"] = {["func"]=cmd_delUserEmail, ["isRet"]=true},	
		["changeScore"] = {["func"]=cmd_changeScore, ["isRet"]=true},
		["kickUser"] = {["func"]=cmd_kickUser, ["isRet"]=true},
		["testPay"] = {["func"]=cmd_testPay, ["isRet"]=false},	
		["changeControlRate"] = {["func"]=cmd_changeControlRate, ["isRet"]=true},
		["addInvitationCode"] = {["func"]=cmd_addInvitationCode, ["isRet"]=true},	
		["changeDeduct"] = {["func"]=cmd_changeDeduct, ["isRet"]=true},
		["hideSignature"] = {["func"]=cmd_hideSignature, ["isRet"]=true},
	},
	initFunc = function()
		loadPayOrderItemConfig()
		loadVipInfoConfig()
		timerUtility.start(500)
		timerUtility.setInterval(onCheckTimeStartOrEnd, 1)
	end,
}

commonServiceHelper.createService(conf)
