require "utility.string"
local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local COMMON_CONST = require "define.commonConst"
local ServerUserItem = require "sui"
local timerUtility = require "utility.timer"

local _data = {
	m_tActivityTimeConfig = nil,
	m_tActivityRewardConfig = nil,
	m_tStartOrEnd = {},
	m_tRedPacketRank = {},
	m_tRedPacketKillRecord = {},
}

local function checkIsSameDay(dateTime)
	local nowDate = tonumber(os.date("%Y%m%d", os.time()))
	return dateTime == nowDate
end

local function cmd_ActivityInfoList(agent,userID)
	local pbObj = {
		activityInfoList = {},
	}

	local curTime = os.time()
	local nowDate = tonumber(os.date("%Y%m%d", curTime))
	local nowHour = tonumber(os.date("%H", curTime))
	local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
	local timeConfig = skynet.call(configAddress,"lua","GetHuoDongTimeInfo")
	local rewardConfig = skynet.call(configAddress,"lua","GetHuoDongRewardInfo")
	local dbConn = addressResolver.getMysqlConnection()

	for k, v in pairs(timeConfig) do
		if curTime < v.startTime or v.endTime < curTime then
			goto continue
		end

		for kk, vv in pairs(rewardConfig) do
			if v.activityType == vv.activityType then
				local ActivityInfo = {
					activityType = vv.activityId,
					startTime = v.startTime,
					currentTime = curTime,
					entTime = v.endTime,
					ActivityItemInfoList = {},
					activityClass = v.activityClass,		
					activityName = v.tips,			
					tuPianID = v.tuPianID,			
					beiJingID = v.beiJingID,
					activityBtnName = v.textName,
				}			
				local ActivityItemInfo = {
					index = vv.index,
					leftTimes = 0,
					conditionList = vv.needCondition,
					rewardList = vv.rewardList,
					completeGoodsList = {},
					needVipLv = vv.needVipLevel,
					maxLimitTimes = vv.perDayMax,
				}
				if vv.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_WORD then
					local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_GUO_QING_1				
					if vv.index == 2 then
						limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_GUO_QING_2
					end
					skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "CheckIsEverydayLimit",userID,limitId,vv.perDayMax)
					local iCount = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "GetLimitCount",userID,limitId)
					ActivityItemInfo.maxLimitTimes = vv.perDayMax - iCount

					local iItemMinCount = skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "GetMinGoodsCount",userID,vv.needCondition)
					ActivityItemInfo.leftTimes = iItemMinCount
			
				elseif vv.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_EVERYDAY_RECHARGE then
					local sql = string.format("SELECT * FROM `kffishdb`.`t_user_pay` where UserId=%d and PayType=%d and `Index` = %d",userID,vv.activityId,vv.index)
					local rows = skynet.call(dbConn,"lua","query",sql)
					if rows[1] ~= nil then
						if checkIsSameDay(tonumber(rows[1].Date)) then
							ActivityItemInfo.leftTimes = tonumber(rows[1].LeftTimes)
						else
							local sql = string.format("update `kffishdb`.`t_user_pay` set LeftTimes=%d,Date=%d,Flag=%d where UserId=%d and PayType=%d and `Index` = %d",
								0,nowDate,0,userID,vv.activityId,vv.index)
							skynet.call(dbConn, "lua", "query", sql)
						end
					end

					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_RMB,
						goodsCount = 0,
					}

					table.insert(ActivityItemInfo.completeGoodsList,item)

				elseif vv.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_EVERYDAY_SUM_RECHARGE then
					local sql = string.format("SELECT * FROM `kffishdb`.`t_user_pay` where UserId=%d and PayType=%d and `Index` = %d",userID,vv.activityId,vv.index)
					local rows = skynet.call(dbConn,"lua","query",sql)
					if rows[1] ~= nil then
						if checkIsSameDay(tonumber(rows[1].Date)) then
							ActivityItemInfo.leftTimes = tonumber(rows[1].LeftTimes)
						else
							local sql = string.format("update `kffishdb`.`t_user_pay` set LeftTimes=%d,Date=%d,Flag=%d where UserId=%d and PayType=%d and `Index` = %d",
								0,nowDate,0,userID,vv.activityId,vv.index)
							skynet.call(dbConn, "lua", "query", sql)
						end
					end

					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_RMB,
						goodsCount = 0,
					}

					local sql = string.format("SELECT Rmb,Date FROM `kffishdb`.`t_user_pay_rmb` where UserId=%d and PayType=%d",userID,vv.activityId)
					local rows = skynet.call(dbConn,"lua","query",sql)
					if rows[1] ~= nil then
						local iRmb = tonumber(rows[1].Rmb)
						if checkIsSameDay(tonumber(rows[1].Date)) then
							item.goodsCount = iRmb
						else
							sql = string.format("update `kffishdb`.`t_user_pay_rmb` set Rmb=%d,Date=%d where UserId=%d and PayType=%d",0,nowDate,userID,vv.activityId)
							skynet.call(dbConn, "lua", "query", sql)
						end
					end

					table.insert(ActivityItemInfo.completeGoodsList,item)

				elseif vv.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_SUM_RECHARGE_IN_HD_TIME then
					local startTime = tonumber(os.date("%Y%m%d", v.startTime))
					local sql = string.format("SELECT * FROM `kffishdb`.`t_user_pay` where UserId=%d and PayType=%d and `Index` = %d",userID,vv.activityId,vv.index)
					local rows = skynet.call(dbConn,"lua","query",sql)
					if rows[1] ~= nil then
						ActivityItemInfo.leftTimes = tonumber(rows[1].LeftTimes)
						local lastDate = tonumber(rows[1].Date)
						if lastDate < startTime then
							ActivityItemInfo.leftTimes = 0
							local sql = string.format("update `kffishdb`.`t_user_pay` set LeftTimes=%d,Date=%d,Flag=%d where UserId=%d and PayType=%d and `Index` = %d",
								0,nowDate,0,userID,vv.activityId,vv.index)
							skynet.call(dbConn, "lua", "query", sql)
						end 
					end

					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_RMB,
						goodsCount = 0,
					}
					local sql = string.format("SELECT Rmb,Date FROM `kffishdb`.`t_user_pay_rmb` where UserId=%d and PayType=%d",userID,vv.activityId)
					local rows = skynet.call(dbConn,"lua","query",sql)
					if rows[1] ~= nil then
						local iRmb = tonumber(rows[1].Rmb)
						local lastDate = tonumber(rows[1].Date)
						if lastDate < startTime then
							item.goodsCount = 0
							sql = string.format("update `kffishdb`.`t_user_pay_rmb` set Rmb=%d,Date=%d where UserId=%d and PayType=%d",0,nowDate,userID,vv.activityId)
							skynet.call(dbConn, "lua", "query", sql)
						else
							item.goodsCount = iRmb
						end
					end

					table.insert(ActivityItemInfo.completeGoodsList,item)

				elseif vv.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_LOGIN then
					local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_LOGIN_1				
					if vv.index == 2 then
						limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_LOGIN_2
					end

					local bInTimeFlag = false

					if vv.index == 1 then
						if 12 <= nowHour and nowHour <=13 then
							bInTimeFlag = true
						end
					else
						if 19 <= nowHour and nowHour <=20 then
							bInTimeFlag = true
						end
					end

					skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "CheckIsEverydayLimit",userID,limitId,vv.perDayMax)
					local iCount = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "GetLimitCount",userID,limitId)
					ActivityItemInfo.leftTimes = vv.perDayMax - iCount
					if not bInTimeFlag then
						ActivityItemInfo.leftTimes = 0
					end

				elseif vv.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_CHOU_JINAG then 
					local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_CHARGE_PERDAY
					local flag = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "CheckIsEverydayLimit",userID,limitId,1)
					if not flag then
						ActivityItemInfo.leftTimes = 0
					else
						ActivityItemInfo.leftTimes = 1
					end

					local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_REWARD_ID
					skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "CheckIsEverydayLimit",userID,limitId,vv.perDayMax)
					local iCount = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "GetLimitCount",userID,limitId)
					ActivityItemInfo.maxLimitTimes = vv.perDayMax - iCount

				elseif vv.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_RED_PACKET then 
					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_RMB,
						goodsCount = 0,
					}
					local sql = string.format("SELECT Rmb,Date FROM `kffishdb`.`t_user_pay_rmb` where UserId=%d and PayType=%d",userID,vv.activityId)
					local rows = skynet.call(dbConn,"lua","query",sql)
					if rows[1] ~= nil then
						local iRmb = tonumber(rows[1].Rmb)
						if checkIsSameDay(tonumber(rows[1].Date)) then
							item.goodsCount = iRmb
						else
							if iRmb >= 50 then
								ActivityItemInfo.leftTimes = 1
							end
						end
					end

					table.insert(ActivityItemInfo.completeGoodsList,item)

				end

				local bFind = false
				for a, b in pairs(pbObj.activityInfoList) do
					if b.activityType == vv.activityId then
						table.insert(b.ActivityItemInfoList,ActivityItemInfo)
						bFind = true
						break
					end
				end

				if not bFind then
					table.insert(ActivityInfo.ActivityItemInfoList,ActivityItemInfo)
					table.insert(pbObj.activityInfoList,ActivityInfo)
				end
			end
		end

		::continue::
	end

	skynet.send(agent,"lua","forward",0x006000,pbObj)
end

local function cmd_ExchangeActivityReward(agent,tcpAgentData,pbObj)
	local re = {
		activityType = pbObj.activityType,
		activityIndex = pbObj.activityIndex,
		rewardGoodsList = {},
		reCode = 1,
	}

	local curTime = os.time()
	local nowDate = tonumber(os.date("%Y%m%d", curTime))
	local nowHour = tonumber(os.date("%H", curTime))
	local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
	local timeConfig = skynet.call(configAddress,"lua","GetHuoDongTimeInfo")
	local rewardConfig = skynet.call(configAddress,"lua","GetHuoDongRewardInfo")

	for kk, vv in pairs(timeConfig) do
		if curTime < vv.startTime or vv.endTime < curTime then
			goto continue
		end

		for k, v in pairs(rewardConfig) do
			if vv.activityType == v.activityType then
				if v.activityId == re.activityType and v.index == re.activityIndex then
					if v.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_WORD then
						local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_GUO_QING_1				
						if v.index == 2 then
							limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_GUO_QING_2
						end
						skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "CheckIsEverydayLimit",tcpAgentData.userID,limitId,v.perDayMax)
						local iCount = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "GetLimitCount",tcpAgentData.userID,limitId)
						if iCount >= v.perDayMax then
							return re
						end

						local bSuccess = skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "CheckItemAndComsume",tcpAgentData.userID,v.needCondition,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG_REWARD)
						if not bSuccess then
							return re
						end

						skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "AddGoodsList",tcpAgentData.userID,v.rewardList,tcpAgentData.sui,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG_REWARD)
						skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "AddLimit",tcpAgentData.userID,limitId,1)
					
					elseif v.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_LOGIN then
						local attr = ServerUserItem.getAttribute(tcpAgentData.sui, {"memberOrder"})
						local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_LOGIN_1	
						if 12 <= nowHour and nowHour <=13 then
							limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_LOGIN_1
						elseif 19 <= nowHour and nowHour <= 20  then
							limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_LOGIN_2
						else
							return re
						end

						skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "CheckIsEverydayLimit",tcpAgentData.userID,limitId,v.perDayMax)
						local iCount = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "GetLimitCount",tcpAgentData.userID,limitId)
						if iCount >= v.perDayMax then
							return re
						end

						local goods = {
							goodsID = 1001,
							goodsCount = 10000,
						}

						if attr.memberOrder >= 7 then
							goods.goodsCount = 80000
						elseif attr.memberOrder >= 5 then
							goods.goodsCount = 60000
						elseif attr.memberOrder >= 3 then
							goods.goodsCount = 40000
						elseif attr.memberOrder >= 1 then
							goods.goodsCount = 20000
						end

						table.insert(re.rewardGoodsList,goods)

						skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",tcpAgentData.userID,goods.goodsID,goods.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG_REWARD)
						skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "AddLimit",tcpAgentData.userID,limitId,1)
					
					elseif v.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_CHOU_JINAG then 
						local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_CHARGE_PERDAY
						local flag = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "CheckIsEverydayLimit",tcpAgentData.userID,limitId,1)
						if not flag then
							return re
						end
						local rmb = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "GetLimitCount",tcpAgentData.userID,limitId)

						local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_REWARD_ID
						local flag = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "CheckIsEverydayLimit",tcpAgentData.userID,limitId,1)
						if flag then
							return re
						end

						local rewardInfo = skynet.call(addressResolver.getAddressByServiceName("LS_model_item_config"), "lua", "ChouJiang",rmb)
						if rewardInfo ~= nil then
							re.activityIndex = rewardInfo.index
							skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",tcpAgentData.userID,rewardInfo.goodsID,rewardInfo.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG_REWARD)
							skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "AddLimit",tcpAgentData.userID,limitId,1)
						else
							return re
						end

					elseif v.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_RED_PACKET then 
						local dbConn = addressResolver.getMysqlConnection()
						local sql = string.format("SELECT Rmb,Date FROM `kffishdb`.`t_user_pay_rmb` where UserId=%d and PayType=%d",tcpAgentData.userID,v.activityId)
						local rows = skynet.call(dbConn,"lua","query",sql)
						if rows[1] ~= nil then
							local iRmb = tonumber(rows[1].Rmb)
							if checkIsSameDay(tonumber(rows[1].Date)) then
								return re
							else
								local multiple = 0
								for a, b in pairs(rewardConfig) do
									if vv.activityType == b.activityType then
										if b.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_RED_PACKET then
											if iRmb >= b.needCondition[1].goodsCount then
												multiple = b.multiple
											end
										end
									end
								end

								if multiple ~= 0 then
									local goods = {
										goodsID = 1001,
										goodsCount = math.floor(iRmb*10000*(multiple-1)),
									}

									table.insert(re.rewardGoodsList,goods)
										
									skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",tcpAgentData.userID,goods.goodsID,goods.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG_REWARD)

									local sql = string.format("update `kffishdb`.`t_user_pay_rmb` set Rmb=0 where UserId=%d and PayType=%d",tcpAgentData.userID,v.activityId)
									skynet.call(dbConn,"lua","query",sql)
								end
							end
						else
							return re
						end

					else
						local sql = string.format("SELECT * FROM `kffishdb`.`t_user_pay` where UserId=%d and PayType=%d and `Index` = %d",tcpAgentData.userID,v.activityId,v.index)
						local dbConn = addressResolver.getMysqlConnection()
						local rows = skynet.call(dbConn,"lua","query",sql)
						if rows[1] ~= nil then
							local iCount = tonumber(rows[1].LeftTimes)
							if iCount <= 0 then
								return re
							end

							skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "AddGoodsList",tcpAgentData.userID,v.rewardList,tcpAgentData.sui,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG_REWARD)

							if v.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_EVERYDAY_RECHARGE then
								local sql = string.format("update `kffishdb`.`t_user_pay` set LeftTimes=%d,Date=%d where UserId=%d and PayType=%d and `Index` = %d",
									iCount-1,nowDate,tcpAgentData.userID,v.activityId,v.index)
								skynet.call(dbConn, "lua", "query", sql)		
							else
								local sql = string.format("update `kffishdb`.`t_user_pay` set LeftTimes=%d,Date=%d,Flag=%d where UserId=%d and PayType=%d and `Index` = %d",
									0,nowDate,1,tcpAgentData.userID,v.activityId,v.index)
								skynet.call(dbConn, "lua", "query", sql)	
							end				
						end
					end

					local sql = string.format("insert into `kfrecorddb`.`t_activity_get_reward_type`(`UserId`,`RewardType`,`ActivityId`,`ActivityIndex`,`date`) values(%d,%d,%d,%d,now())",
						tcpAgentData.userID,2,v.activityId,v.index)
					local dbConn = addressResolver.getMysqlConnection()
					skynet.send(dbConn, "lua", "execute", sql)

					break
				end
			end
		end
		::continue::
	end

	cmd_ActivityInfoList(agent,tcpAgentData.userID)

	re.reCode = 0
	return re
end	

local function cmd_CheckActivityReward(sui)
	local attrr = ServerUserItem.getAttribute(sui,{"userID"})
	if not attrr then
		return
	end

	local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
	local timeConfig = skynet.call(configAddress,"lua","GetHuoDongTimeInfo")
	local rewardConfig = skynet.call(configAddress,"lua","GetHuoDongRewardInfo")

	local bRedPacketFlag = false
	local curTime = os.time()
	local nowDate = tonumber(os.date("%Y%m%d", curTime))
	for k, v in pairs(timeConfig) do
		for kk, vv in pairs(rewardConfig) do
			if v.activityType == vv.activityType then

				if not bRedPacketFlag and vv.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_RED_PACKET then
					if curTime > v.endTime then
						bRedPacketFlag = true
						local dbConn = addressResolver.getMysqlConnection()
						local sql = string.format("SELECT Rmb,Date FROM `kffishdb`.`t_user_pay_rmb` where UserId=%d and PayType=%d",attrr.userID,COMMON_CONST.HUO_DONG_ID.HD_ID_RED_PACKET)
						local rows = skynet.call(dbConn,"lua","query",sql)
						if rows[1] ~= nil then
							local iRmb = tonumber(rows[1].Rmb)
							if not checkIsSameDay(tonumber(rows[1].Date)) then
								local multiple = 0
								for a, b in pairs(rewardConfig) do
									if b.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_RED_PACKET then
										if iRmb >= b.needCondition[1].goodsCount then
											multiple = b.multiple
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
									skynet.send(addressResolver.getAddressByServiceName("LS_model_message"),"lua","sendEmailToUser",attrr.userID,rewardList,messageTitle,messageInfo)

									local sql = string.format("insert into `kfrecorddb`.`t_activity_get_reward_type` (`UserId`,`RewardType`,`ActivityId`,`ActivityIndex`,`date`) values(%d,%d,%d,%d,now())",
										attrr.userID,1,COMMON_CONST.HUO_DONG_ID.HD_ID_RED_PACKET,1)
									skynet.call(dbConn, "lua", "query", sql)
								end

								local sql = string.format("update `kffishdb`.`t_user_pay_rmb` set Rmb=%d,Date=%d where UserId=%d and PayType=%d",
									0,nowDate,attrr.userID,vv.activityId)
								skynet.call(dbConn, "lua", "query", sql)
							end
						end
					end
				end 

				--if vv.activityId ~= COMMON_CONST.HUO_DONG_ID.HD_ID_WORD then
				if vv.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_EVERYDAY_RECHARGE 
					or vv.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_EVERYDAY_SUM_RECHARGE 
					or vv.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_SUM_RECHARGE_IN_HD_TIME then

					local sql = string.format("SELECT * FROM `kffishdb`.`t_user_pay` where UserId=%d and PayType=%d and `Index` = %d",attrr.userID,vv.activityId,vv.index)
					local dbConn = addressResolver.getMysqlConnection()
					local rows = skynet.call(dbConn,"lua","query",sql)
					if rows[1] ~= nil then
						local leftTimes = tonumber(rows[1].LeftTimes)
						local date = tonumber(rows[1].Date)
						local bFind = true
						if nowDate ~= date and leftTimes ~= 0 then
							for i = 1, leftTimes do
								if vv.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_EVERYDAY_RECHARGE then
									local messageTitle = string.format("单笔充值奖励补偿邮件")
									local messageInfo = string.format("这是您未及时领取的单笔充值奖励，请注意查收附件！祝您游戏愉快！")
									skynet.send(addressResolver.getAddressByServiceName("LS_model_message"),"lua","sendEmailToUser",attrr.userID,vv.rewardList,messageTitle,messageInfo)
								elseif vv.activityId == COMMON_CONST.HUO_DONG_ID.HD_ID_EVERYDAY_SUM_RECHARGE then
									local messageTitle = string.format("日累计充值奖励补偿邮件")
									local messageInfo = string.format("这是您未及时领取的日累计充值奖励，请注意查收附件！祝您游戏愉快！")
									skynet.send(addressResolver.getAddressByServiceName("LS_model_message"),"lua","sendEmailToUser",attrr.userID,vv.rewardList,messageTitle,messageInfo)
								else
									bFind = false
									if curTime > v.endTime then
										bFind = true
										local messageTitle = string.format("累计充值奖励补偿邮件")
										local messageInfo = string.format("这是您未及时领取的活动期间累计充值奖励，请注意查收附件！祝您游戏愉快！")
										skynet.send(addressResolver.getAddressByServiceName("LS_model_message"),"lua","sendEmailToUser",attrr.userID,vv.rewardList,messageTitle,messageInfo)
									end
								end

								if bFind then
									local sql = string.format("insert into `kfrecorddb`.`t_activity_get_reward_type` (`UserId`,`RewardType`,`ActivityId`,`ActivityIndex`,`date`) values(%d,%d,%d,%d,now())",
										attrr.userID,1,vv.activityId,vv.index)
									skynet.call(dbConn, "lua", "query", sql)
								end
							end

							if bFind then
								local sql = string.format("update `kffishdb`.`t_user_pay` set LeftTimes=%d,Date=%d where UserId=%d and PayType=%d and `Index` = %d",
									0,nowDate,attrr.userID,vv.activityId,vv.index)
								skynet.call(dbConn, "lua", "query", sql)
							end
						end			
					end
				end
			end
		end
	end
end

local function cmd_AddRedPacketRank(data)
	for k, v in pairs(data) do
		for kk, vv in pairs(v) do
			local bFind = false
			for a, b in pairs(_data.m_tRedPacketRank) do
				if b.userID == vv.userID then
					bFind = true
					b.score = b.score + vv.score
				end
			end

			if not bFind then
				local temp = {
					userID = vv.userID,
					userName = vv.userName,
					score = vv.score
				}
				table.insert(_data.m_tRedPacketRank,temp)
			end
		end
	end

	table.sort(_data.m_tRedPacketRank,function(a, b) return a.score > b.score end)

	return 0
end

local function cmd_AddRedPacketKillRecord(data)
	for k, v in pairs(data) do
		for kk, vv in pairs(v) do
			table.insert(_data.m_tRedPacketKillRecord,vv)
			local recordCount = #_data.m_tRedPacketKillRecord + 1
			if recordCount > 3 then
				table.remove(_data.m_tRedPacketKillRecord, 1)
			end
		end

	end

	table.sort(_data.m_tRedPacketKillRecord,function(a, b) return a.killTime > b.killTime end)

	return 0
end

local function cmd_RedPacketInfo(agent,userID)
	local pbObj = {
		rankInfoList = {},
		killRecordInfoList = {},
		myRank = 0,
		myScore = 0,
	}

	local iCount = 0
	local iMyRank = 0
	for k, v in pairs(_data.m_tRedPacketRank) do
		if iCount < 3 then
			table.insert(pbObj.rankInfoList,v)
			iCount = iCount + 1
		end

		iMyRank = iMyRank + 1
		if v.userID == userID then
			pbObj.myRank = iMyRank
			pbObj.myScore = v.score
		end
	end

	pbObj.killRecordInfoList = _data.m_tRedPacketKillRecord

	skynet.send(agent,"lua","forward",0x006003,pbObj)
end

local function NotifyActivityStartOrEnd(activityType,bStartOrEnd)
	local pbObj = {
		activityType = activityType,		
		bStartOrEnd	= bStartOrEnd,	
	}

	local userList = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getAllUserInfo")
	for _, v in pairs(userList) do 
		local attr = ServerUserItem.getAttribute(v.sui,{"agent","userID"})
		if attr.agent ~= 0 then
			skynet.send(attr.agent,"lua","forward",0x006002,pbObj)
		end
	end
end	

local function CheckActivityStartOrEnd()
	local curTime = os.time()
	for k, v in pairs(_data.m_tActivityTimeConfig) do
		for kk, vv in pairs(_data.m_tStartOrEnd) do
			if v.activityType == vv.activityType then
				if not vv.bStartOrEnd then
					if v.startTime < curTime and curTime < v.endTime then
						vv.bStartOrEnd = true
						NotifyActivityStartOrEnd(vv.activityType,vv.bStartOrEnd)
					end
				else
					if v.endTime < curTime then
						vv.bStartOrEnd = false
						NotifyActivityStartOrEnd(vv.activityType,vv.bStartOrEnd)
					end
				end
			end
		end
	end
end

local function loadData()
	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("SELECT a.UserId,b.NickName,a.SumGold FROM `kfrecorddb`.`t_red_packet_user_gold_record` a LEFT JOIN kfaccountsdb.accountsinfo b ON a.UserId = b.UserID")
	local rows = skynet.call(dbConn,"lua","query",sql)
	for _, row in ipairs(rows) do
		local info = {
			userID = tonumber(row.UserId),
			userName = row.NickName,
			score = tonumber(row.SumGold), 
		}

		table.insert(_data.m_tRedPacketRank,info)
	end

	table.sort(_data.m_tRedPacketRank,function(a, b) return a.score > b.score end)

	local sql = string.format("SELECT a.UserId,b.NickName,a.Multiple,a.AddGold,UNIX_TIMESTAMP(a.AddTime) as submitTime FROM kfrecorddb.t_red_packet_kill_record a LEFT JOIN kfaccountsdb.accountsinfo b on a.UserId = b.UserID ORDER BY submitTime DESC LIMIT 3")
	local rows = skynet.call(dbConn,"lua","query",sql)
	for _, row in ipairs(rows) do
		local info = {
			userID = tonumber(row.UserId),
			userName = row.NickName,
			killTime = tonumber(row.submitTime), 
			multiple = tonumber(row.Multiple), 
			score    = tonumber(row.AddGold), 
		}

		table.insert(_data.m_tRedPacketKillRecord,info)
	end

	table.sort(_data.m_tRedPacketKillRecord,function(a, b) return a.killTime > b.killTime end)
end

local conf = {
	methods = {
		["ActivityInfoList"] = {["func"]=cmd_ActivityInfoList, ["isRet"]=false},
		["ExchangeActivityReward"] = {["func"]=cmd_ExchangeActivityReward, ["isRet"]=true},
		["CheckActivityReward"] = {["func"]=cmd_CheckActivityReward, ["isRet"]=false},
		["AddRedPacketRank"] = {["func"]=cmd_AddRedPacketRank, ["isRet"]=true},
		["AddRedPacketKillRecord"] = {["func"]=cmd_AddRedPacketKillRecord, ["isRet"]=true},
		["RedPacketInfo"] = {["func"]=cmd_RedPacketInfo, ["isRet"]=false},			
	},

	initFunc = function()
		local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
	 	_data.m_tActivityTimeConfig = skynet.call(configAddress,"lua","GetHuoDongTimeInfo")
		_data.m_tActivityRewardConfig = skynet.call(configAddress,"lua","GetHuoDongRewardInfo")
		for k, v in pairs(_data.m_tActivityTimeConfig) do
			local info = {
				activityType = v.activityType,
				bStartOrEnd = false,
			}
			table.insert(_data.m_tStartOrEnd,info)
		end

		timerUtility.start(1000)
		timerUtility.setInterval(CheckActivityStartOrEnd, 1)

		loadData()
	end,
}

commonServiceHelper.createService(conf)

