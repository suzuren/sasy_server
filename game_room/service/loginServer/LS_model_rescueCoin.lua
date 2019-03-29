local skynet = require "skynet"
local randHandle = require "utility.randNumber"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local ServerUserItem = require "sui"
local COMMON_CONST = require "define.commonConst"
local LS_CONST = require "define.lsConst"
local timerUtility = require "utility.timer"

local _itemInfoHash = {}
local lastDay = 0
local lastRankDay = 0

local function loadConfig()
	local sql = "SELECT * FROM `kftreasuredb`.`t_rescue_coin`"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, row in pairs(rows) do
			local item ={
				index = tonumber(row.Index),
				timeCount = tonumber(row.TimeCount),
				goldCount = tonumber(row.GoldCount),
			}
			_itemInfoHash[item.index] = item
		end
	end
end

local function cmd_requestRescueCoin(tcpAgent,tcpAgentData)
	local re = {
		rescueCoinCount = 0,
		CountdownTime = 0,
		code = 0,
		remainingCount = 0,
	}
	local randId = randHandle.random(1, LS_CONST.RESCUE_COIN_MAX_NUM)
	local nowTime = os.time()
	local sql = string.format("SELECT * FROM `kffishdb`.`t_rescue_coin` where UserId = %d",tcpAgentData.userID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if rows[1] == nil then
		sql = string.format("insert into `kffishdb`.`t_rescue_coin` values(%d,%d,%d,0,%d,0,0)",tcpAgentData.userID,nowTime,1,randId)
		skynet.call(dbConn, "lua", "query", sql)

		re.rescueCoinCount = _itemInfoHash[1].goldCount
		re.CountdownTime = _itemInfoHash[1].timeCount
		re.remainingCount = LS_CONST.RESCUE_COIN_MAX_NUM
		re.code = 0
	else
		local brokeTime = tonumber(rows[1].BrokeTime)
		local num = tonumber(rows[1].CurCounts)
		local flag = tonumber(rows[1].ReceiveFlag)
		local randNum = tonumber(rows[1].RandNum)
		local fishCount = tonumber(rows[1].FishCount)

		local bDaySwitch = false
		local brokeDate = tonumber(os.date("%Y%m%d",brokeTime))
		local nowDate = tonumber(os.date("%Y%m%d",nowTime))
		if brokeDate ~= nowDate then
			num = 1
			randNum = randId
			fishCount = 0
			flag = 0
			bDaySwitch = true
		else
			if flag == 1 then
				num = num + 1
				if randNum == 0 then --新老数据处理
					randNum = randHandle.random(num, LS_CONST.RESCUE_COIN_MAX_NUM)
				end
				
				if num > LS_CONST.RESCUE_COIN_MAX_NUM then
					re.code = 2
					return re
				end
			end
		end

		if bDaySwitch == true then
			re.CountdownTime = _itemInfoHash[1].timeCount
		else
			if flag == 0 then
				if nowTime - brokeTime >= _itemInfoHash[num].timeCount then
					re.CountdownTime = 0
				else
					re.CountdownTime = _itemInfoHash[num].timeCount - (nowTime - brokeTime)			
				end
			else 
				re.CountdownTime = _itemInfoHash[num].timeCount
			end
		end

		re.remainingCount = LS_CONST.RESCUE_COIN_MAX_NUM - num + 1

		if flag == 1 or bDaySwitch == true then
			sql = string.format("update `kffishdb`.`t_rescue_coin` set BrokeTime=%d,CurCounts=%d,ReceiveFlag=%d,RandNum=%d,FishCount=%d where UserId=%d",
				nowTime,num,0,randNum,fishCount,tcpAgentData.userID)
			skynet.call(dbConn, "lua", "query", sql)
		end

		re.rescueCoinCount = _itemInfoHash[num].goldCount
	end

	return re
end

local function cmd_RescueCoinSynchronizeTime(tcpAgent,tcpAgentData)
	local re = {
		CountdownTime = 0,		
		code = 0,
	}

	local nowTime = os.time()
	local nowDate = tonumber(os.date("%Y%m%d", nowTime))
	local sql = string.format("SELECT * FROM `kffishdb`.`t_rescue_coin` where UserId = %d",tcpAgentData.userID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if rows[1] == nil then
		re.code = 1
		return re
	end

	local brokeTime = tonumber(rows[1].BrokeTime)
	local num = tonumber(rows[1].CurCounts)
	local flag = tonumber(rows[1].ReceiveFlag)

	if nowTime - brokeTime >= _itemInfoHash[num].timeCount then
		re.CountdownTime = 0
	else
		re.CountdownTime = _itemInfoHash[num].timeCount - (nowTime - brokeTime)			
	end

	re.code = 0
	return re
end

local function cmd_ReceiveRescueCoin(tcpAgent,tcpAgentData)
	local re = {
		rescueCoinCount = 0,		
		code = 0,
		currentScore = 0,
	}

	local nowTime = os.time()
	local sql = string.format("SELECT * FROM `kffishdb`.`t_rescue_coin` where UserId = %d",tcpAgentData.userID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if rows[1] == nil then
		re.code = 1
		return re
	end

	local brokeTime = tonumber(rows[1].BrokeTime)
	local num = tonumber(rows[1].CurCounts)
	local flag = tonumber(rows[1].ReceiveFlag)
	local randNum = tonumber(rows[1].RandNum)
	if nowTime - brokeTime < _itemInfoHash[num].timeCount then
		re.code = 3
		return re
	end

	if flag == 1 then
		re.code = 2
		return re
	end

	re.rescueCoinCount = _itemInfoHash[num].goldCount 
	local bDaySwitch = false
	local brokeDate = tonumber(os.date("%Y%m%d",brokeTime))
	local nowDate = tonumber(os.date("%Y%m%d",nowTime))
	if brokeDate ~= nowDate then
		re.rescueCoinCount = _itemInfoHash[1].goldCount 
		randNum = randHandle.random(1, LS_CONST.RESCUE_COIN_MAX_NUM)
		num = 1
		bDaySwitch = true
		sql = string.format("update `kffishdb`.`t_rescue_coin` set BrokeTime=%d,CurCounts=%d,ReceiveFlag=%d,RandNum=%d,FishCount=%d where UserID = %d",
			nowTime,1,1,randNum,0,tcpAgentData.userID)
	else
		sql = string.format("update `kffishdb`.`t_rescue_coin` set ReceiveFlag=%d where UserID = %d",1,tcpAgentData.userID)		
	end

	skynet.call(dbConn, "lua", "query", sql)

	sql = string.format("update `kftreasuredb`.`GameScoreInfo` set Score=Score+%d where UserID = %d", re.rescueCoinCount, tcpAgentData.userID)
	skynet.call(dbConn, "lua", "query", sql)

	ServerUserItem.addAttribute(tcpAgentData.sui, {score = re.rescueCoinCount})

	local attr = ServerUserItem.getAttribute(tcpAgentData.sui, {"userID", "userStatus", "serverID", "score"}) -- 获取身上金币
	if attr.serverID ~=0 then
		skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", {attr.serverID},
		 COMMON_CONST.LSNOTIFY_EVENT.EVT_LSNOTIFY_USER_RESCUECOIN, {
			userID=attr.userID,
			score=re.rescueCoinCount,
			num = num,
			randNum = randNum,
			bDaySwitch = bDaySwitch,
		})
		--背包
		skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",attr.userID,
			COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,re.rescueCoinCount,COMMON_CONST.ITEM_SYSTEM_TYPE.RESCUE_COIN,true)
	else
		--背包
		skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",attr.userID,
			COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,re.rescueCoinCount,COMMON_CONST.ITEM_SYSTEM_TYPE.RESCUE_COIN)
	end

	sql = string.format("insert into `kfrecorddb`.`rescue_coin` (`UserId`,`CurNum`,`GoldNum`,`ReceiveTime`) values(%d,%d,%d,'%s')",
		attr.userID,num,re.rescueCoinCount,os.date('%Y-%m-%d %H:%M:%S', math.floor(skynet.time())))
	skynet.send(dbConn, "lua", "execute", sql)

	re.currentScore = 100
	re.code = 0
	return re
end

local function RescueCoinRemainingCount(sui)
	local pbObj = {
		remainingCount = LS_CONST.RESCUE_COIN_MAX_NUM,
	}

	local attr = ServerUserItem.getAttribute(sui, {"agent"})
	if attr.agent ~= 0 then
		skynet.send(attr.agent,"lua","forward",0x002003 ,pbObj)
	end
end

local function monthCardOprator()
	local nowTime = os.time()	
	local nowYear = tonumber(os.date("%Y",nowTime))
	local nowMonth = tonumber(os.date("%m",nowTime))
	local nowDay = tonumber(os.date("%d",nowTime))
	local nowtable = {year=nowYear, month=nowMonth, day=nowDay, hour=00,min=00,sec=00,isdst=false}
	local nowTimeTemp = os.time(nowtable)

	local messageTitle = string.format("月卡礼包")
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

	local sql = string.format("SELECT * from `kffishdb`.`t_month_card` WHERE EndTime > %d",nowTime)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, v in ipairs(rows) do
			local startTime = tonumber(v.StartTime)
			local endTime = tonumber(v.EndTime)
			local startYear = tonumber(os.date("%Y",startTime))
			local startMonth = tonumber(os.date("%m",startTime))
			local startDay = tonumber(os.date("%d",startTime))
			local userID = tonumber(v.UserId)

			local tab = {year=startYear, month=startMonth, day=startDay, hour=00,min=00,sec=00,isdst=false}
			local startTimeTemp = os.time(tab)

			remainDay = math.floor((endTime-startTime)/(24*60*60)) - (math.floor((nowTimeTemp-startTimeTemp)/(24*60*60)))

			local messageInfo = string.format("您的月卡礼包,还剩%d天",remainDay)
			skynet.send(addressResolver.getAddressByServiceName("LS_model_message"),"lua","sendEmailToUser",userID,itemList,messageTitle,messageInfo)
		end
	end	
end

local function ReloadRankInfo()
	skynet.send(addressResolver.getAddressByServiceName("LS_model_ranking"), "lua", "reloadWealthRankingList")
	skynet.send(addressResolver.getAddressByServiceName("LS_model_ranking"), "lua", "reloadLoveLinesRankingList")
	skynet.send(addressResolver.getAddressByServiceName("LS_model_ranking"), "lua", "reloadBoxRankingList")
end  

local function onCheckDaySwitch()
	local curDay = os.date("%d",os.time())
	if lastDay == 0 then
		lastDay = curDay
	else
		if lastDay ~= curDay then
			lastDay = curDay
			local userList = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getAllUserInfo")
			for _, v in pairs(userList) do 
				RescueCoinRemainingCount(v.sui)
			end

			monthCardOprator()
			-- ReloadRankInfo()
		end
	end

	if lastRankDay == 0 then
		lastRankDay = curDay
	else
		-- 暂时凌晨4点刷新排行榜
		if lastRankDay ~= curDay and tonumber(os.date("%H", os.time())) > 4 then
			lastRankDay = curDay

			ReloadRankInfo()
		end
	end
	
end

local conf = {
	methods = {
		["RequestRescueCoin"] = {["func"]=cmd_requestRescueCoin, ["isRet"]=true},
		["RescueCoinSynchronizeTime"] = {["func"]=cmd_RescueCoinSynchronizeTime, ["isRet"]=true},
		["ReceiveRescueCoin"] = {["func"]=cmd_ReceiveRescueCoin, ["isRet"]=true},				
	},
	initFunc = function()
		loadConfig()
		timerUtility.start(1000)
		timerUtility.setInterval(onCheckDaySwitch, 1)
	end,
}

commonServiceHelper.createService(conf)

