local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local ServerUserItem = require "sui"
local COMMON_CONST = require "define.commonConst"
local randHandle = require "utility.randNumber"

local _gunUpLevelHash = {}

local function cmd_SaveData(userID)
	local info = _gunUpLevelHash[userID]
	if not info then
		return
	end

	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("insert into `kffishdb`.`t_gun_uplevel` (`UserId`,`CurGunLevel`,`HaveCount`,`Gold`,`FireCount`) VALUES(%d,%d,%d,%d,%d) ON DUPLICATE KEY UPDATE CurGunLevel=%d,HaveCount=%d,Gold=%d,FireCount=%d",
		userID,info.curGunLevel,info.haveCount,info.gold,info.fireCount,info.curGunLevel,info.haveCount,info.gold,info.fireCount)
	skynet.call(dbConn,"lua","query",sql)
end

local function cmd_LoadData(userItem)
	local info = {
		haveCount = 0,
		curGunLevel = 0,
		gold = 0,
		fireCount = 0,
		canDropGem = false,
	}

	local attr = ServerUserItem.getAttribute(userItem, {"userID","memberOrder"})
	local userID = tonumber(attr.userID)
	local sql = string.format("SELECT * FROM `kffishdb`.`t_gun_uplevel` where UserId=%d",userID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if rows[1] ~= nil then
		info.haveCount = tonumber(rows[1].HaveCount)
		info.curGunLevel = tonumber(rows[1].CurGunLevel)
		info.gold = tonumber(rows[1].Gold)
		info.fireCount = tonumber(rows[1].FireCount)
	end

	local bFind = false
	if attr.memberOrder ~= 0 then
		local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
		local infoConfig = skynet.call(configAddress,"lua","GetvipInfo")
		if info.curGunLevel < infoConfig[attr.memberOrder].gunLevel then
			info.curGunLevel = infoConfig[attr.memberOrder].gunLevel
			bFind = true
		end
	end

	_gunUpLevelHash[userID] = info

	if bFind then
		cmd_SaveData(userID)
	end
end	

local function cmd_ReleaseUserData(userID)
	_gunUpLevelHash[userID] = nil
end

local function cmd_FortLevelInfoList(agent,userID)
	local info = {
		fortLevelInfo = {},
		currentFortLevel = 0,
	}

	info.currentFortLevel = _gunUpLevelHash[userID].curGunLevel
	local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
	local infoConfig = skynet.call(configAddress,"lua","GetGunUplevelInfo")
	for k, v in pairs(infoConfig) do 
		local gunInfo = {
			fortMultipleID = v.level,
			fortMultiple = v.multiple,
			upgradeGoodsItem = {},
			upgradeBackGoodsItem = {},
		}
		local needGoods = {
			goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_JEWEL,
			goodsCount = v.needGem
		}
		table.insert(gunInfo.upgradeGoodsItem,needGoods)

		local rewardGoods = {
			goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
			goodsCount = v.rewardGold
		}
		table.insert(gunInfo.upgradeBackGoodsItem,rewardGoods)

		table.insert(info.fortLevelInfo,gunInfo)
	end

	skynet.send(agent,"lua","forward",0x005000,info)
end

local function cmd_RequestFortLevel(tcpAgentData,level)
	local re = {
		fortLevel = 0,
		rewardGoodsItem = {},	
		code = 1,
	}

	local userInfo = _gunUpLevelHash[tcpAgentData.userID]
	if not userInfo or userInfo.curGunLevel ~= (level-1) then
		re.code = 2
		return re
	end

	local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
	local infoConfig = skynet.call(configAddress,"lua","GetGunUplevelInfo")
	if not infoConfig then
		return re
	end

	if infoConfig[level] == nil then
		re.code = 3
		return re
	end

	local curCount = skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "GetItemCount",tcpAgentData.userID,COMMON_CONST.ITEM_ID.ITEM_ID_JEWEL)
	if infoConfig[level].needGem <= 0 or curCount < infoConfig[level].needGem then
		re.code = 4
		return re
	end

	skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",tcpAgentData.userID,
		 COMMON_CONST.ITEM_ID.ITEM_ID_JEWEL,-infoConfig[level].needGem,COMMON_CONST.ITEM_SYSTEM_TYPE.GUN_UP_LEVEL)

	ServerUserItem.addAttribute(tcpAgentData.sui, {score=infoConfig[level].rewardGold})

	skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",tcpAgentData.userID,
		COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,infoConfig[level].rewardGold,COMMON_CONST.ITEM_SYSTEM_TYPE.GUN_UP_LEVEL)

	local goods = {
		goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
		goodsCount = infoConfig[level].rewardGold
	}
	table.insert(re.rewardGoodsItem,goods)
	userInfo.curGunLevel = userInfo.curGunLevel + 1

	cmd_SaveData(tcpAgentData.userID)

	local curGold = skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "GetItemCount",tcpAgentData.userID,COMMON_CONST.ITEM_ID.ITEM_ID_GOLD)
	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("insert into `kfrecorddb`.`t_gun_uplevel` (`UserId`,`GunLevel`,`DelGemCount`,`RemainGemCount`,`GetGold`,`CurSumGold`,`Date`) values(%d,%d,%d,%d,%d,%d,now())",
		tcpAgentData.userID,level,infoConfig[level].needGem,curCount-infoConfig[level].needGem,goods.goodsCount,curGold)
	skynet.send(dbConn, "lua", "execute", sql)

	re.fortLevel = userInfo.curGunLevel
	re.code = 0
	return re
end	

local function cmd_checkGunLevelUp(vipLevel,userID,agent)
	local userInfo = _gunUpLevelHash[userID]
	if not userInfo then
		return
	end

	if vipLevel ~= 0 then
		local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
		local infoConfig = skynet.call(configAddress,"lua","GetvipInfo")
		if userInfo.curGunLevel < infoConfig[vipLevel].gunLevel then
			userInfo.curGunLevel = infoConfig[vipLevel].gunLevel
			local re = {
				fortLevel = userInfo.curGunLevel,
				rewardGoodsItem = {},	
				code = 0,
			}

			skynet.send(agent,"lua","forward",0x005001,re)

			cmd_SaveData(userID)
		end
	end
end	

local conf = {
	methods = {
		["LoadData"] = {["func"]=cmd_LoadData, ["isRet"]=true},
		["ReleaseUserData"] = {["func"]=cmd_ReleaseUserData, ["isRet"]=false},
		["FortLevelInfoList"] = {["func"]=cmd_FortLevelInfoList, ["isRet"]=false},
		["RequestFortLevel"] = {["func"]=cmd_RequestFortLevel, ["isRet"]=true},
		["checkGunLevelUp"] = {["func"]=cmd_checkGunLevelUp, ["isRet"]=false},
	},
}

commonServiceHelper.createService(conf)

