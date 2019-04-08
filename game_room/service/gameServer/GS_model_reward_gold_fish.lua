local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local COMMON_CONST = require "define.commonConst"
local GS_CONST = require "define.gsConst"
local ServerUserItem = require "sui"
local mysqlutil = require "utility.mysqlHandle"
local randHandle = require "utility.randNumber"
local timerUtility = require "utility.timer"

local lastDay = 0
local needFishCount = 3

local _rewardGoldFish = {}	

local function cmd_SaveData(userID)
	local info = _rewardGoldFish[userID]
	if not info then
		return
	end

	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("insert into `ssfishdb`.`t_reward_gold_fish` VALUES(%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d) ON DUPLICATE KEY UPDATE FishCount=%d,SumScore=%d,RewardType=%d,rewardIndex=%d,BeforeFirst=%d,BeforeSec=%d,BeforeThr=%d,BeforeFour=%d,BeforeFive=%d,opTime=%d,BeforeSix=%d",
		userID,info.fishCount,info.sumScore,info.rewardType,info.rewardIndex,info.beforeFirst,info.beforeSec,info.beforeThr,info.beforeFour,info.beforeFive,info.opTime,info.beforeSix,
		info.fishCount,info.sumScore,info.rewardType,info.rewardIndex,info.beforeFirst,info.beforeSec,info.beforeThr,info.beforeFour,info.beforeFive,info.opTime,info.beforeSix)
	skynet.call(dbConn,"lua","query",sql)
end

local function cmd_LoadRData(userID)
	local info = {
		fishCount = 0,
		sumScore = 0,
		rewardType = 0,
		rewardIndex = 0,
		beforeFirst = 0,
		beforeSec = 0,
		beforeThr = 0,
		beforeFour = 0,
		beforeFive = 0,
		opTime = tonumber(os.date("%Y%m%d", os.time())),
		beforeSix = 0,
	}
	
	local sql = string.format("SELECT * FROM `ssfishdb`.`t_reward_gold_fish` where UserId=%d",userID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if rows[1] ~= nil then
		info.fishCount = tonumber(rows[1].FishCount)
		info.sumScore = tonumber(rows[1].SumScore)
		info.rewardType = tonumber(rows[1].RewardType)
		info.rewardIndex = tonumber(rows[1].RewardIndex)
		info.beforeFirst = tonumber(rows[1].BeforeFirst)
		info.beforeSec = tonumber(rows[1].BeforeSec)
		info.beforeThr = tonumber(rows[1].BeforeThr)
		info.beforeFour = tonumber(rows[1].BeforeFour)
		info.beforeFive = tonumber(rows[1].BeforeFive)
		info.opTime = tonumber(rows[1].OpTime)
		info.beforeSix = tonumber(rows[1].BeforeSix)

		local nowDate = tonumber(os.date("%Y%m%d", os.time()))
		if info.opTime ~= nowDate then
			info.fishCount = 0
			info.opTime = nowDate
		end
	end
	_rewardGoldFish[userID] = info
end

local function notifySingleData(userID,fishCount,sumScore)
	local info = {
		lotteryCoinCount = sumScore,
		limitFishCount = fishCount
	}
	local userItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "getUserItem",userID)
	local attr = ServerUserItem.getAttribute(userItem,{"agent","isAndroid"})
	if attr and not attr.isAndroid and attr.agent ~= 0 then 
		skynet.send(attr.agent,"lua","forward",0x011003,info)
	end
end

local function cmd_ChangeRewardGfInfo(userID,num,score)
	local info = _rewardGoldFish[userID]
	if not info then
		return
	end

	info.fishCount = info.fishCount + num
	info.sumScore = info.sumScore + score

	if info.fishCount > needFishCount then
		info.fishCount = needFishCount
	end

	notifySingleData(userID,info.fishCount,info.sumScore)
end

local function cmd_ReleaseUserData(userID)
	_rewardGoldFish[userID] = nil
end

local function cmd_LotteryInfo(agent,userID)
	local info = {
		lotteryItemInfo = {}
	}

	local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
	local infoConfig = skynet.call(configAddress,"lua","GetRewardGfInfo")
	for k, v in pairs(infoConfig) do 
		local tempInfo = {
			type = v.rewardType,
			goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
			goodsCount = v.needScore,
			lotteryGoodsItem = {},
		}
		for kk, vv in pairs(v.itemList) do
			local goods = {
				itemID = vv.index,
				goodsID = vv.itemId,
				goodsCount = vv.itemCount
			}
			table.insert(tempInfo.lotteryGoodsItem,goods)	 
		end
		table.insert(info.lotteryItemInfo,tempInfo)
	end
	
	skynet.send(agent,"lua","forward",0x011000,info)

	local userInfo = _rewardGoldFish[userID]
	if userInfo then
		notifySingleData(userID,userInfo.fishCount,userInfo.sumScore)
	end
end

local function cmd_RequestLotteryItem(userID,type)
	local re = {
		lotteryType = type,
		itemID = 0,
		code = 1
	}
	if type < 1 then
		return re
	end
	
	local userInfo = _rewardGoldFish[userID]
	if not userInfo then
		return re
	end
	--[[
	if userInfo.rewardType ~= 0 then
		re.itemID = userInfo.rewardIndex
		re.code = 0
		return re
	end
	--]]

	if userInfo.fishCount < needFishCount then
		return re
	end

	local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
	local infoConfig = skynet.call(configAddress,"lua","GetRewardGfInfo")
	for k, v in pairs(infoConfig) do 
		if v.rewardType == type then
			if userInfo.sumScore < v.needScore then
				return re
			end

			local beforeCount = 0
			if type == 1 then
				beforeCount = userInfo.beforeFirst
				if userInfo.beforeFirst < v.beforeCount then
					userInfo.beforeFirst = userInfo.beforeFirst + 1
				end
			elseif type == 2 then
				beforeCount = userInfo.beforeSec
				if userInfo.beforeSec < v.beforeCount then
					userInfo.beforeSec = userInfo.beforeSec + 1
				end 
			elseif type == 3 then
				beforeCount = userInfo.beforeThr
				if userInfo.beforeThr < v.beforeCount then
					userInfo.beforeThr = userInfo.beforeThr + 1
				end 
			elseif type == 4 then
				beforeCount = userInfo.beforeFour
				if userInfo.beforeFour < v.beforeCount then
					userInfo.beforeFour = userInfo.beforeFour + 1
				end
			elseif type == 5 then 
				beforeCount = userInfo.beforeFive
				if userInfo.beforeFive < v.beforeCount then
					userInfo.beforeFive = userInfo.beforeFive + 1
				end
			else
				beforeCount = userInfo.beforeSix
				if userInfo.beforeSix < v.beforeCount then
					userInfo.beforeSix = userInfo.beforeSix + 1
				end
			end

			local randId = 0
			if beforeCount < v.beforeCount then
				local rand = randHandle.random(1,#v.beforeReward)
				for kk, vv in pairs(v.beforeReward) do 
					if kk == rand then
						randId = vv
						break
					end
				end
			else
				local rand = randHandle.random(1,100)
				for kk, vv in pairs(v.itemList) do 
					if vv.minRate <= rand and rand <= vv.maxRate then
						randId = vv.index
						break
					end
				end
			end

			re.itemID = randId
			userInfo.rewardIndex = randId
			userInfo.rewardType = type
			break
		end
	end

	re.code = 0
	return re
end

local function cmd_ReceiveLotteryGoodsInfo(pbObj,tcpAgentData)
	local re = {
		code = 1,
		receiveGoodsItem = {},
	}

	local userInfo = _rewardGoldFish[tcpAgentData.userID]
	if not userInfo then
		return re
	end

	if userInfo.rewardType == 0 or userInfo.rewardIndex == 0 then
		return re
	end

	local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
	local infoConfig = skynet.call(configAddress,"lua","GetRewardGfInfo")
	for k, v in pairs(infoConfig) do 
		if v.rewardType == userInfo.rewardType then
			for kk, vv in pairs (v.itemList) do 
				if vv.index == userInfo.rewardIndex then
					local userAttr = ServerUserItem.getAttribute(tcpAgentData.sui, {"tableID","nickName","memberOrder"})
					if vv.itemId == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
						ServerUserItem.addAttribute(tcpAgentData.sui, {score=vv.itemCount})
						local tableAddress
						if userAttr.tableID~=GS_CONST.INVALID_TABLE then
							tableAddress = addressResolver.getTableAddress(userAttr.tableID)
						end

						if tableAddress then
							skynet.call(tableAddress, "lua", "onUserScoreNotify", tcpAgentData.sui)
							--skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "AddItemRecord",tcpAgentData.userID,
							--	vv.itemId,vv.itemCount,COMMON_CONST.ITEM_SYSTEM_TYPE.REWARD_GOLD_FISH)
						end
					-- else
					-- 	skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",tcpAgentData.userID,
		 		-- 			vv.itemId,vv.itemCount,COMMON_CONST.ITEM_SYSTEM_TYPE.REWARD_GOLD_FISH,true)
					end

					skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",tcpAgentData.userID,
		 				vv.itemId,vv.itemCount,COMMON_CONST.ITEM_SYSTEM_TYPE.REWARD_GOLD_FISH,true)

					local goods = {
						goodsID = vv.itemId,
						goodsCount = vv.itemCount
					}
					table.insert(re.receiveGoodsItem,goods)

					local dbConn = addressResolver.getMysqlConnection()
					local sql = string.format("insert into `ssrecorddb`.`t_reward_gold_fish` (`UserId`,`RewardType`,`RewardId`,`RewardCount`,`Date`) values(%d,%d,%d,%d,now())",
						tcpAgentData.userID,userInfo.rewardType,goods.goodsID,goods.goodsCount)
					skynet.send(dbConn, "lua", "execute", sql)

					if COMMON_CONST.ITEM_ID.ITEM_ID_SILVE_KEY <= vv.itemId and vv.itemId <= COMMON_CONST.ITEM_ID.ITEM_ID_MOON_KEY then
						local itemInfoConfig = skynet.call(configAddress,"lua","GetItemConfigInfo",vv.itemId)
						if itemInfoConfig then
							local nickName = COMMON_CONST.HideNickName(userAttr.nickName)
							local msg = string.format("恭喜%s好运当头,在奖池中抽中%s*%s",nickName,itemInfoConfig.itemName,vv.itemCount)
							local tableAddress
							if userAttr.tableID~=GS_CONST.INVALID_TABLE then
								tableAddress = addressResolver.getTableAddress(userAttr.tableID)
							end

							if tableAddress then
								skynet.send(tableAddress,"lua","sendSystemMessage",msg,false,true,false,false)
							end
						end
					end

					--触发体验炮台
					if userAttr.memberOrder < 6 then
						local bLimit = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "CheckIsForeverLimit",tcpAgentData.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP6,1)
						if not bLimit then
							skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",tcpAgentData.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP6,1)
						end
					end

					break
				end
			end
			break
		end
	end	

	userInfo.sumScore = 0
	userInfo.fishCount = 0
	userInfo.rewardType = 0
	userInfo.rewardIndex = 0

	notifySingleData(tcpAgentData.userID,0,0)

	re.code = 0
	return re
end

local function onCheckDaySwitch()
	local curDay = os.date("%d",os.time())
	if lastDay == 0 then
		lastDay = curDay
	else
		if lastDay ~= curDay then
			local nowDate = tonumber(os.date("%Y%m%d",os.time()))
			lastDay = curDay
			for k, v in pairs(_rewardGoldFish) do
				v.fishCount = 0
				v.opTime = nowDate

				notifySingleData(k,v.fishCount,v.sumScore)
			end
		end
	end
end

local conf = {
	methods = {
		["SaveData"] = {["func"]=cmd_SaveData, ["isRet"]=true},
		["LoadData"] = {["func"]=cmd_LoadRData, ["isRet"]=true},
		["ChangeRewardGfInfo"] = {["func"]=cmd_ChangeRewardGfInfo, ["isRet"]=false},
		["ReleaseUserData"] = {["func"]=cmd_ReleaseUserData, ["isRet"]=true},

		["LotteryInfo"] = {["func"]=cmd_LotteryInfo, ["isRet"]=false},
		["RequestLotteryItem"] = {["func"]=cmd_RequestLotteryItem, ["isRet"]=true},
		["ReceiveLotteryGoodsInfo"] = {["func"]=cmd_ReceiveLotteryGoodsInfo, ["isRet"]=true},
	},

	initFunc = function()
		timerUtility.start(500)
		timerUtility.setInterval(onCheckDaySwitch,1)
	end,
}

commonServiceHelper.createService(conf)
