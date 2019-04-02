require "utility.string"
local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local COMMON_CONST = require "define.commonConst"
local ServerUserItem = require "sui"
local mysqlutil = require "utility.mysqlHandle"
local timerUtility = require "utility.timer"

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
	local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
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
					skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "CheckIsEverydayLimit",userID,limitId,vv.perDayMax)
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
					local sql = string.format("SELECT * FROM `kffishdb`.`t_user_pay` where UserId=%d and PayType=%d and `Index` = %d",userID,vv.activityId,vv.index)
					local rows = skynet.call(dbConn,"lua","query",sql)
					if rows[1] ~= nil then
						ActivityItemInfo.leftTimes = tonumber(rows[1].LeftTimes)
					end

					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_RMB,
						goodsCount = 0,
					}
					local sql = string.format("SELECT Rmb,Date FROM `kffishdb`.`t_user_pay_rmb` where UserId=%d and PayType=%d",userID,vv.activityId)
					local rows = skynet.call(dbConn,"lua","query",sql)
					if rows[1] ~= nil then
						local iRmb = tonumber(rows[1].Rmb)
						item.goodsCount = iRmb
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
		reCode = 1,
	}

	local curTime = os.time()
	local nowDate = tonumber(os.date("%Y%m%d", curTime))
	local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
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
						skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "CheckIsEverydayLimit",tcpAgentData.userID,limitId,v.perDayMax)
						local iCount = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "GetLimitCount",tcpAgentData.userID,limitId)
						if iCount >= v.perDayMax then
							return re
						end

						local bSuccess = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "CheckItemAndComsume",tcpAgentData.userID,v.needCondition,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG_REWARD)
						if not bSuccess then
							return re
						end

						skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "AddGoodsList",tcpAgentData.userID,v.rewardList,tcpAgentData.sui,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG_REWARD)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",tcpAgentData.userID,limitId,1)

					else
						local sql = string.format("SELECT * FROM `kffishdb`.`t_user_pay` where UserId=%d and PayType=%d and `Index` = %d",tcpAgentData.userID,v.activityId,v.index)
						local dbConn = addressResolver.getMysqlConnection()
						local rows = skynet.call(dbConn,"lua","query",sql)
						if rows[1] ~= nil then
							local iCount = tonumber(rows[1].LeftTimes)
							if iCount <= 0 then
								return re
							end

							skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "AddGoodsList",tcpAgentData.userID,v.rewardList,tcpAgentData.sui,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG_REWARD)

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

local function cmd_SendActivityReward(sui)
	
end

local function onCheckTimeStartOrEnd()
	-- local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
	-- local timeConfig = skynet.call(configAddress,"lua","GetHuoDongTimeInfo")
	-- local rewardConfig = skynet.call(configAddress,"lua","GetHuoDongRewardInfo")

	-- for k, v in pairs(timeConfig) do

	-- end




	-- local nowDate = os.time()
	-- local bChange = false

	-- if not bStartFlag then
	-- 	if startTime <= nowDate and nowDate <= endTime then
	-- 		bChange = true
	-- 		bStartFlag = true
	-- 	end
	-- else
	-- 	if nowDate < startTime or nowDate > endTime then
	-- 		bChange = true
	-- 		bStartFlag = false
	-- 	end
	-- end

	-- if bChange then
	-- 	local userList = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getAllUserInfo")
	-- 	for _, v in pairs(userList) do 
	-- 		local attr = ServerUserItem.getAttribute(v.sui,{"agent","userID","serverID"})
	-- 		if attr and attr.agent ~= 0 then
	-- 			cmd_queryPayOrderItem(attr.agent,attr.userID)
	-- 		end
	-- 	end
	-- end


end

local conf = {
	methods = {
		["ActivityInfoList"] = {["func"]=cmd_ActivityInfoList, ["isRet"]=false},
		["ExchangeActivityReward"] = {["func"]=cmd_ExchangeActivityReward, ["isRet"]=true},
		["SendActivityReward"] = {["func"]=cmd_SendActivityReward, ["isRet"]=false},				
	},
	initFunc = function()
		--timerUtility.start(1000)
		--timerUtility.setInterval(onCheckTimeStartOrEnd, 1)
	end,
}

commonServiceHelper.createService(conf)

