local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local timeUtility = require "utility.time"
local mysqlutil = require "utility.mysqlHandle"
local COMMON_CONST = require "define.commonConst"
local LS_EVENT = require "define.eventLoginServer"
local ServerUserItem = require "sui"
local LS_CONST = require "define.lsConst"

local _signinAwardInfoHash = {}

local function loadSigninAwardInfoConfig()
	local sql = "SELECT * FROM `sstreasuredb`.`t_signin_award_info`"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows) == "table" then
		for _, row in pairs(rows) do
			local item = {
				index = tonumber(row.Index),
				itype = tonumber(row.Type),
				dayId = tonumber(row.DayId),
				itemId = tonumber(row.ItemId),
				itemCount = tonumber(row.ItemCount)
			}
			_signinAwardInfoHash[item.index] = item
		end
	end
end

local function cmd_SigninListInfo(agent,userId)
	local pbObj = {
		everyDayList = {},
		cumulativeDayList = {},
	}

	local loginDate = 0
	local signinDate = 0
	local perDayFlag = 0
	local sumDayFlag = 0
	local nowTime = os.time()
	local nowDate = tonumber(os.date("%Y%m%d", nowTime))

	local sql = string.format("SELECT * FROM `ssfishdb`.`t_signin` where UserId = %d", userId)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)

	if rows[1] ~= nil then
		pbObj.currentDay = tonumber(rows[1].SumDay)
		perDayFlag = tonumber(rows[1].PerAwardFlag)
		sumDayFlag = tonumber(rows[1].SumAwardFlag)
		loginDate = tonumber(rows[1].LoginDate)
		signinDate = tonumber(rows[1].SigninDate)

		--判断跨天，跨月，有些数据要重置
		if loginDate ~= nowDate then
			pbObj.currentDay = pbObj.currentDay + 1
			local nowYear = tonumber(os.date("%Y",nowTime))
			local nowMonth = tonumber(os.date("%m",nowTime))
			local nowDay = tonumber(os.date("%d",nowTime))
			local nowtable = {year=nowYear, month=nowMonth, day=nowDay, hour=00,min=00,sec=00,isdst=false}
			local nowTimeTemp = os.time(nowtable)
	
			local oldDate = tostring(loginDate)
			local oldYear = tonumber(string.sub(oldDate,1,4))
			local oldMonth = tonumber(string.sub(oldDate,5,6))
			local oldDay = tonumber(string.sub(oldDate,7,8))

			local tab = {year=oldYear, month=oldMonth, day=oldDay, hour=00,min=00,sec=00,isdst=false}
			local oldTime = os.time(tab)

			local bSwitchMonth = false
			if nowMonth ~= oldMonth then	--跨月了--只重置累计登入的数据，7天的数据不重置
				pbObj.currentDay = 1
				sumDayFlag = 0

				sql = string.format("update `ssfishdb`.`t_signin` set SumDay=%d,SumAwardFlag=%d,LoginDate=%d where UserId=%d",
								pbObj.currentDay,sumDayFlag,nowDate,userId)
				skynet.call(dbConn, "lua", "query", sql)

				bSwitchMonth = true
			else
				if loginDate + 1 ~= nowDate then
					perDayFlag = 0
					sql = string.format("update `ssfishdb`.`t_signin` set SumDay=%d,PerAwardFlag=%d,LoginDate=%d where UserId=%d",pbObj.currentDay,perDayFlag,nowDate,userId)
				else
					sql = string.format("update `ssfishdb`.`t_signin` set SumDay=%d,LoginDate=%d where UserId=%d",pbObj.currentDay,nowDate,userId)
				end

				skynet.call(dbConn, "lua", "query", sql)
			end

			if bSwitchMonth then

				if oldTime+24*60*60 ~= nowTimeTemp then 
					perDayFlag = 0
					sql = string.format("update `ssfishdb`.`t_signin` set PerAwardFlag=%d where UserId=%d",perDayFlag,userId)
					skynet.call(dbConn, "lua", "query", sql)
				end
			end
		end
	else
		pbObj.currentDay = 1

		sql = string.format("insert into `ssfishdb`.`t_signin` values(%d,%d,%d,%d,%d,%d,%d)",userId,pbObj.currentDay,perDayFlag,sumDayFlag,nowDate,signinDate,0)
		skynet.call(dbConn, "lua", "query", sql)
	end

	local doubleReward = 1
	local userItem = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getUserItemByUserID", userId)
	if userItem then
		local attr = ServerUserItem.getAttribute(userItem,{"memberOrder"})
		local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
		local infoConfig = skynet.call(configAddress,"lua","GetvipInfo")
		for k, v in pairs(infoConfig) do 
			if v.vipLevel == attr.memberOrder then
				if v.sign == 1 then
					doubleReward = doubleReward * 2
				end
				break
			end
		end
	end

	local bOneCanGet = false
	local tempPerDayFlag = 6--perDayFlag
	local awardFlag = 0
	for i=1, 6, 1 do
		if perDayFlag ~= 0 then
			perDayFlag = perDayFlag - 1
			awardFlag = 2
		elseif bOneCanGet == false and nowDate ~= signinDate then
			awardFlag = 1
			bOneCanGet = true
		end

		local index = 1000 + i

		table.insert(pbObj.everyDayList,{
			dayID = _signinAwardInfoHash[index].dayId,
			goodsID = _signinAwardInfoHash[index].itemId,
			goodsCount = _signinAwardInfoHash[index].itemCount*doubleReward,
			signinResult = awardFlag,
		})
		awardFlag = 0
	end

	if nowDate == signinDate and perDayFlag ~= 0 then
		local index = 1000 + tempPerDayFlag + 1
		table.insert(pbObj.everyDayList,{
			dayID = _signinAwardInfoHash[index].dayId,
			goodsID = _signinAwardInfoHash[index].itemId,
			goodsCount = _signinAwardInfoHash[index].itemCount*doubleReward,
			signinResult = 2,
		})
	else
		if nowDate ~= signinDate and (perDayFlag ~= 0 or not bOneCanGet) then
			local index = 1000 + tempPerDayFlag + 1
			table.insert(pbObj.everyDayList,{
				dayID = _signinAwardInfoHash[index].dayId,
				goodsID = _signinAwardInfoHash[index].itemId,
				goodsCount = _signinAwardInfoHash[index].itemCount*doubleReward,
				signinResult = 1,
			})
		else	
			local index = 1000 + tempPerDayFlag + 1
			table.insert(pbObj.everyDayList,{
				dayID = _signinAwardInfoHash[index].dayId,
				goodsID = _signinAwardInfoHash[index].itemId,
				goodsCount = _signinAwardInfoHash[index].itemCount*doubleReward,
				signinResult = 0,
			})
		end			
	end

	for k=1, 4, 1 do

		local index = 2000 + k

		awardFlag = 0

		if pbObj.currentDay >= _signinAwardInfoHash[index].dayId then
			awardFlag = 1
		end

		if sumDayFlag ~= 0 then
			sumDayFlag = sumDayFlag - 1
			awardFlag = 2
		end

		table.insert(pbObj.cumulativeDayList,{
			dayID = _signinAwardInfoHash[index].dayId,
			goodsID = _signinAwardInfoHash[index].itemId,
			goodsCount = _signinAwardInfoHash[index].itemCount*doubleReward,
			signinResult = awardFlag,
		})
	end

	if agent~=0 then
		skynet.send(agent,"lua","forward",0x001000,pbObj)
	end
end

local function cmd_Sign(agent,userID,sui,signType,dayId)
	local re = {
		signType = signType;			
		dayID = dayId;
		code = 1;
	}

	local nowTime = os.time()
	local nowDate = tonumber(os.date("%Y%m%d", nowTime))
	local sql = string.format("SELECT * FROM `ssfishdb`.`t_signin` where UserId = %d", userID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if rows[1] == nil then
		re.code = 1
		return re
	end
	local SumDay = tonumber(rows[1].SumDay)
	local PerAwardFlag = tonumber(rows[1].PerAwardFlag)
	local SumAwardFlag = tonumber(rows[1].SumAwardFlag)
	local SigninDate = tonumber(rows[1].SigninDate)
	local AllSumDay = tonumber(rows[1].AllSumDay)

	if signType == 1 then
		if SigninDate == nowDate then 
			re.code = 2
			return re
		end

		if PerAwardFlag >= 7 then
			PerAwardFlag = 6
		end

		if PerAwardFlag+1 ~= dayId then 
			re.code = 1
			return re
		end
	elseif signType == 2 then
		if SumDay < dayId then
			re.code = 3
			return re
		end

		local temCount = 0
		for _, awardInfo in pairs(_signinAwardInfoHash) do
			if signType == awardInfo.itype and awardInfo.dayId <= dayId then
				temCount = temCount + 1
			end
		end

		if temCount <= SumAwardFlag then
			re.code = 1
			return re
		end
	else
		re.code = 1
		return re	
	end

	local valueScore = 0
	for _, awardInfo in pairs(_signinAwardInfoHash) do
		if signType == awardInfo.itype and dayId == awardInfo.dayId then
			valueScore = awardInfo.itemCount
			break
		end
	end

	if valueScore == 0 then
		re.code = 1
		return re	
	end

	local attr = ServerUserItem.getAttribute(sui,{"memberOrder"})
	if attr ~= nil then
		local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
		local infoConfig = skynet.call(configAddress,"lua","GetvipInfo")
		for k, v in pairs(infoConfig) do 
			if v.vipLevel == attr.memberOrder then
				if v.sign == 1 then
					valueScore = valueScore * 2
				end
				break
			end
		end
	end

	if signType == 1 then
		sql = string.format("update `ssfishdb`.`t_signin` set SigninDate=%d,PerAwardFlag=%d,AllSumDay=%d where UserId=%d",nowDate,PerAwardFlag+1,AllSumDay+1,userID)
	else
		sql = string.format("update `ssfishdb`.`t_signin` set SumAwardFlag=%d,AllSumDay=%d where UserId=%d",SumAwardFlag+1,AllSumDay+1,userID)
	end
	
	skynet.call(dbConn, "lua", "query", sql)

	sql = string.format("update `sstreasuredb`.`GameScoreInfo` set Score=Score+%d where UserID = %d", valueScore, userID)
	skynet.send(dbConn, "lua", "execute", sql)

	ServerUserItem.addAttribute(sui, {score = valueScore})
	--背包
	skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",userID,
			COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,valueScore,COMMON_CONST.ITEM_SYSTEM_TYPE.SIGN_IN)

	cmd_SigninListInfo(agent,userID)

	sql = string.format("insert into `ssrecorddb`.`sign_in` (`UserId`,`Type`,`DayId`,`GoldNum`,`SigninTime`) values(%d,%d,%d,%d,'%s')",
		userID,signType,dayId,valueScore,os.date('%Y-%m-%d %H:%M:%S', math.floor(skynet.time())))
	skynet.send(dbConn, "lua", "execute", sql)
	
	re.code = 0
	return re
end

local conf = {
	methods = {
		["SigninListInfo"] = {["func"]=cmd_SigninListInfo, ["isRet"]=false},
		["Sign"] = {["func"]=cmd_Sign, ["isRet"]=true},				
	},
	initFunc = function()
		loadSigninAwardInfoConfig()
	end,
}

commonServiceHelper.createService(conf)

