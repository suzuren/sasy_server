
local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local ServerUserItem = require "sui"
local randHandle = require "utility.randNumber"

local _invalidGunHash = {}	

local function cmd_SaveData(userID)
	local userItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"),"lua","getUserItem",userID)
	if userItem == nil then
		return
	end

	local attr = ServerUserItem.getAttribute(userItem, {"logonTime"})

	local info = _invalidGunHash[userID]
	if not info then
		return
	end

	if info.lastTime ~= 0 then
		info.timeCount = info.timeCount + os.time() - info.lastTime
	else
		info.timeCount = info.timeCount + os.time() - attr.logonTime
	end

	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("insert into `kffishdb`.`t_user_invalid_gun` (`UserId`,`TimeCount`,`GunCount`,`Gold`,`FishCount`) VALUES(%d,%d,%d,%d,%d) ON DUPLICATE KEY UPDATE `TimeCount`=%d,`GunCount`=%d,`Gold`=%d,`FishCount`=%d",
		userID,info.timeCount,info.gunCount,info.gold,info.iFishCount,info.timeCount,info.gunCount,info.gold,info.iFishCount)
	skynet.send(dbConn,"lua","execute",sql)
end

local function cmd_LoadData(userID)
	local info = {
		timeCount = 0,
		gunCount = 0,
		gold = 0,
		iFishCount = 0,
		lastTime = 0,
	}

	local sql = string.format("SELECT * FROM `kffishdb`.`t_user_invalid_gun` where UserId=%d",userID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if rows[1] ~= nil then
		info.timeCount = tonumber(rows[1].TimeCount)
		info.gunCount = tonumber(rows[1].GunCount)
		info.gold = tonumber(rows[1].Gold)
		info.iFishCount = tonumber(rows[1].FishCount)
	end

	_invalidGunHash[userID]=info
end

local function cmd_ReleaseUserData(userID)
	_invalidGunHash[userID] = nil
end

local function cmd_AddInvalidGunData(userItem,score)
	local userAttr = ServerUserItem.getAttribute(userItem,{"userID","logonTime"})
	if userAttr then
		local info = _invalidGunHash[userAttr.userID]
		if info then
			info.gunCount = info.gunCount + 1
			info.gold = info.gold + score
		end
	end
end

local function cmd_CheckInvalidGun(userItem)
	local userAttr = ServerUserItem.getAttribute(userItem,{"userID","logonTime"})
	if userAttr then
		local info = _invalidGunHash[userAttr.userID]
		if info then
			local timeCount = 0
			if info.lastTime ~= 0 then
				timeCount = info.timeCount + os.time() - info.lastTime
			else
				timeCount = info.timeCount + os.time() - userAttr.logonTime
			end
			
			if timeCount >= 5*60 and info.gunCount >= 30 then
				info.iFishCount = info.iFishCount + 1
				if info.iFishCount >= 30 then
					info.iFishCount = 0
					info.timeCount = 0
					info.gunCount = 0
					info.lastTime = os.time()

					local gold = info.gold
					info.gold = 0
					return gold
				end

				local iRate = randHandle.random(1,100)
				if iRate <= 60 then
					info.iFishCount = 0
					info.timeCount = 0
					info.gunCount = 0
					info.lastTime = os.time()

					local gold = info.gold
					info.gold = 0
					return gold
				end
			end
		end
	end

	return 0
end

local conf = {
	methods = {
		["SaveData"] = {["func"]=cmd_SaveData, ["isRet"]=true},
		["LoadData"] = {["func"]=cmd_LoadData, ["isRet"]=true},
		["ReleaseUserData"] = {["func"]=cmd_ReleaseUserData, ["isRet"]=true},
		
		["AddInvalidGunData"] = {["func"]=cmd_AddInvalidGunData, ["isRet"]=false},
		["CheckInvalidGun"] = {["func"]=cmd_CheckInvalidGun, ["isRet"]=true},
	},
}

commonServiceHelper.createService(conf)
