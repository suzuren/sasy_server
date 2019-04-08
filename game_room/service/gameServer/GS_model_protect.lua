require "utility.string"
local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local ServerUserItem = require "sui"
local mysqlutil = require "utility.mysqlHandle"

--新手保护的鱼
local _hashForFishId = {}	

local function cmd_SaveFishId(userID)
	local goalInfo = ""
	local chargeInfo = ""
	local fishInfo = _hashForFishId[userID]
	if not fishInfo then
		skynet.error(string.format("--------------cmd_SaveFishId---info---is---nil------userid=%d----------",userID))
		return
	end

	for _, v in pairs(fishInfo.fishIdList) do 
		goalInfo = goalInfo..tostring(v)..":"
	end

	for _, vv in pairs(fishInfo.chargeFishList) do
		chargeInfo = chargeInfo..tostring(vv.fishKind)..":"..tostring(vv.count).."|"
	end

	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("insert into `ssfishdb`.`t_protect_fish` (`UserId`,`FishIdInfo`,`ChargeFishInfo`) VALUES(%d,'%s','%s') ON DUPLICATE KEY UPDATE `FishIdInfo`='%s',`ChargeFishInfo`='%s'",
		userID,mysqlutil.escapestring(goalInfo),mysqlutil.escapestring(chargeInfo),mysqlutil.escapestring(goalInfo),mysqlutil.escapestring(chargeInfo))
	skynet.call(dbConn,"lua","query",sql)

	sql = string.format("update `ssfishdb`.`t_rescue_coin` set FishCount=%d,BigFishCount=%d where UserID = %d",fishInfo.fishCount,fishInfo.bigFishCount,userID)		
	skynet.call(dbConn, "lua", "query", sql)
end

local function cmd_LoadFishId(userID)
	local fishInfo = {
		fishIdList = {},
		chargeFishList = {}, --首冲保护的鱼list
		curId = 0,
		randId = 0,
		fishCount = 0,--0-12号鱼
		bigFishCount = 0,--13-17号鱼
	}

	local sql = string.format("SELECT * FROM `ssfishdb`.`t_protect_fish` where UserId=%d",userID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if rows[1] ~= nil then
		if rows[1].FishIdInfo ~= nil then
			local idList = rows[1].FishIdInfo:split(":")
			for _, v in pairs(idList) do
				table.insert(fishInfo.fishIdList,tonumber(v))
			end
		end

		if rows[1].ChargeFishInfo ~= nil then
			local list = rows[1].ChargeFishInfo:split("|")
			for _, item in pairs(list) do
				local itemPart = item:split(":")
				local fish = {
					fishKind = tonumber(itemPart[1]),
					count = tonumber(itemPart[2]),
				}
				table.insert(fishInfo.chargeFishList,fish)
			end
		end
	end

	sql = string.format("SELECT * FROM `ssfishdb`.`t_rescue_coin` where UserId=%d",userID)
	local rowss = skynet.call(dbConn,"lua","query",sql)
	if rowss[1] ~= nil then
		fishInfo.curId = tonumber(rowss[1].CurCounts)
		fishInfo.randId = tonumber(rowss[1].RandNum)
		fishInfo.fishCount = tonumber(rowss[1].FishCount)
		fishInfo.bigFishCount = tonumber(rowss[1].BigFishCount)
	end

	_hashForFishId[userID] = fishInfo
end

local function cmd_ChangeFishCount(userID,num,randNum,bDaySwitch)
	local fishInfo = _hashForFishId[userID]
	if not fishInfo then
		return
	end

	if bDaySwitch or fishInfo.randId ~= randNum then
		fishInfo.randId = randNum
		fishInfo.fishCount = 0
		fishInfo.bigFishCount = 0
	end

	fishInfo.curId = num
	_hashForFishId[userID] = fishInfo
end

local function cmd_ReleaseUserFish(userID)
	_hashForFishId[userID] = nil
end

local function cmd_CheckFishId(userID,fishId)
	local fishInfo = _hashForFishId[userID]
	if not fishInfo then
		return true
	end

	for _, v in pairs(fishInfo.fishIdList) do 
		if v == fishId then
			return true
		end
	end

	return false
end

local function cmd_AddFishId(userID,fishId)
	local fishInfo = _hashForFishId[userID]
	if not fishInfo then
		return
	end

	for _, v in pairs(fishInfo.fishIdList) do 
		if v == fishId then
			return
		end
	end

	table.insert(fishInfo.fishIdList,fishId)
	_hashForFishId[userID] = fishInfo
end

local function cmd_CheckFishCount(userID,fishId)
	local fishInfo = _hashForFishId[userID]
	if not fishInfo then
		return true
	end

	local fishCount = fishInfo.fishCount
	if 13 <= fishId and fishId <= 17 then
		fishCount = fishInfo.bigFishCount
	end
	if fishInfo.curId ~= 0 and fishInfo.randId ~= 0 and fishInfo.curId == fishInfo.randId then
		if fishCount >= 10 then
			return true
		else
			return false
		end
	end

	return true
end

local function cmd_AddFishCount(userID,fishCount,fishId)
	local fishInfo = _hashForFishId[userID]
	if not fishInfo then
		return
	end

	local count = fishInfo.fishCount
	if 13 <= fishId and fishId <= 17 then
		count = fishInfo.bigFishCount
	end
	if fishInfo.randId ~= 0 then
		if count < 10 then
			_hashForFishId[userID].fishCount = fishInfo.fishCount + fishCount
		end
	end
end

local function cmd_CheckChargeFishCount(userID,fishId)
	local fishInfo = _hashForFishId[userID]
	if not fishInfo then
		return true
	end

	for _, v in pairs(fishInfo.chargeFishList) do
		if v.fishKind == fishId then
			if v.count >= 3 then
				return true
			end
		end
	end

	return false
end

local function cmd_AddChargeFishCount(userID,fishId)
	local bFind = false
	local fishInfo = _hashForFishId[userID]
	for _, v in pairs(fishInfo.chargeFishList) do
		if v.fishKind == fishId then
			v.count = v.count + 1
			bFind = true
			break
		end
	end

	if not bFind then
		local info = {
			fishKind = fishId,
			count = 1
		}
		table.insert(fishInfo.chargeFishList,info)
	end
end

local conf = {
	methods = {
		["SaveFishId"] = {["func"]=cmd_SaveFishId, ["isRet"]=true},
		["LoadFishId"] = {["func"]=cmd_LoadFishId, ["isRet"]=true},
		["ChangeFishCount"] = {["func"]=cmd_ChangeFishCount, ["isRet"]=false},
		["ReleaseUserFish"] = {["func"]=cmd_ReleaseUserFish, ["isRet"]=true},
		["CheckFishId"] = {["func"]=cmd_CheckFishId, ["isRet"]=true},
		["AddFishId"] = {["func"]=cmd_AddFishId, ["isRet"]=false},
		["CheckFishCount"] = {["func"]=cmd_CheckFishCount, ["isRet"]=true},	
		["AddFishCount"] = {["func"]=cmd_AddFishCount, ["isRet"]=false},
		["CheckChargeFishCount"] = {["func"]=cmd_CheckChargeFishCount, ["isRet"]=true},	
		["AddChargeFishCount"] = {["func"]=cmd_AddChargeFishCount, ["isRet"]=false},
	},
}

commonServiceHelper.createService(conf)
