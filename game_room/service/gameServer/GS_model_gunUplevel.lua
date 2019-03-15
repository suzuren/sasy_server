local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local ServerUserItem = require "sui"
local COMMON_CONST = require "define.commonConst"
local arc4 = require "arc4random"

local _gunUpLevelHash = {}
local _dropGemConfig

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

		if attr.memberOrder ~= 0 then
			local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
			local infoConfig = skynet.call(configAddress,"lua","GetvipInfo")
			if info.curGunLevel < infoConfig[attr.memberOrder].gunLevel then
				info.curGunLevel = infoConfig[attr.memberOrder].gunLevel
			end
		end
	end

	_gunUpLevelHash[userID] = info
end	

local function cmd_ReleaseUserData(userID)
	_gunUpLevelHash[userID] = nil
end

local function cmd_FortLevelInfoList(agent,userID)
	local info = {
		fortLevelInfo = {},
		currentFortLevel = 0,
	}

	local infoTemp = _gunUpLevelHash[userID]
	if not infoTemp then
		return
	end

	info.currentFortLevel = infoTemp.curGunLevel
	local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
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

	

	skynet.send(agent,"lua","forward",0x012000,info)
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

	local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
	local infoConfig = skynet.call(configAddress,"lua","GetGunUplevelInfo")
	if not infoConfig then
		return re
	end

	if infoConfig[level] == nil then
		re.code = 3
		return re
	end

	local curCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "GetItemCount",tcpAgentData.userID,COMMON_CONST.ITEM_ID.ITEM_ID_JEWEL)
	if infoConfig[level].needGem <= 0 or curCount < infoConfig[level].needGem then
		re.code = 4
		return re
	end

	skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",tcpAgentData.userID,
		 COMMON_CONST.ITEM_ID.ITEM_ID_JEWEL,-infoConfig[level].needGem,COMMON_CONST.ITEM_SYSTEM_TYPE.GUN_UP_LEVEL,true)

	ServerUserItem.addAttribute(tcpAgentData.sui, {score=infoConfig[level].rewardGold})
	local userAttr = ServerUserItem.getAttribute(tcpAgentData.sui, {"tableID","memberOrder"})
	skynet.call(addressResolver.getTableAddress(userAttr.tableID), "lua", "onUserScoreNotify", tcpAgentData.sui)
	-- skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "AddItemRecord",tcpAgentData.userID,
	-- 	1001,infoConfig[level].rewardGold,COMMON_CONST.ITEM_SYSTEM_TYPE.GUN_UP_LEVEL)

	skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",tcpAgentData.userID,
		 COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,infoConfig[level].rewardGold,COMMON_CONST.ITEM_SYSTEM_TYPE.GUN_UP_LEVEL,true)

	local goods = {
		goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
		goodsCount = infoConfig[level].rewardGold
	}
	table.insert(re.rewardGoodsItem,goods)
	userInfo.curGunLevel = userInfo.curGunLevel + 1

	local curGold = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "GetItemCount",tcpAgentData.userID,COMMON_CONST.ITEM_ID.ITEM_ID_GOLD)
	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("insert into `kfrecorddb`.`t_gun_uplevel` (`UserId`,`GunLevel`,`DelGemCount`,`RemainGemCount`,`GetGold`,`CurSumGold`,`Date`) values(%d,%d,%d,%d,%d,%d,now())",
		tcpAgentData.userID,level,infoConfig[level].needGem,curCount-infoConfig[level].needGem,goods.goodsCount,curGold)
	skynet.send(dbConn, "lua", "execute", sql)

	--触发体验炮台
	if userAttr.memberOrder < 3 then
		local bLimit = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "CheckIsForeverLimit",tcpAgentData.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP3,1)
		if not bLimit then
			skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",tcpAgentData.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP3,1)
		end
	end

	re.fortLevel = userInfo.curGunLevel
	re.code = 0
	return re
end	

local function cmd_CheckDropGem(userID,gold)
	local userInfo = _gunUpLevelHash[userID]
	if not userInfo then
		return
	end

	local config = _dropGemConfig[userInfo.haveCount+1]
	if not config then
		return
	end

	userInfo.fireCount = userInfo.fireCount + 1
	userInfo.gold = userInfo.gold + gold
	if userInfo.gold < config.needGold then
		return
	end

	local randnum = arc4.random(15,25)
	if userInfo.fireCount >= randnum then
		userInfo.canDropGem = true
	end
end	

local function cmd_IsDropGem(userID)
	local userInfo = _gunUpLevelHash[userID]
	if not userInfo then
		return false
	end

	if userInfo.curGunLevel >= 10 then
		return false
	end

	return userInfo.canDropGem
end	

local function cmd_DropGem(userID)
	local userInfo = _gunUpLevelHash[userID]
	if not userInfo then
		return
	end

	userInfo.fireCount = 0
	userInfo.canDropGem = false
	userInfo.gold = 0
	userInfo.haveCount = userInfo.haveCount + 1
end	

local function cmd_checkGunLevelUp(vipLevel,userID,agent)
	local userInfo = _gunUpLevelHash[userID]
	if not userInfo then
		return
	end

	if vipLevel ~= 0 then
		local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
		local infoConfig = skynet.call(configAddress,"lua","GetvipInfo")
		if userInfo.curGunLevel < infoConfig[vipLevel].gunLevel then
			userInfo.curGunLevel = infoConfig[vipLevel].gunLevel
			local re = {
				fortLevel = userInfo.curGunLevel,
				rewardGoodsItem = {},	
				code = 0,
			}

			skynet.send(agent,"lua","forward",0x012001,re)
		end
	end
end	

local function cmd_GetGunLevel(userID)
	local userInfo = _gunUpLevelHash[userID]
	if not userInfo then
		return 0
	end

	return userInfo.curGunLevel
end

local conf = {
	methods = {
		["SaveData"] = {["func"]=cmd_SaveData, ["isRet"]=true},
		["LoadData"] = {["func"]=cmd_LoadData, ["isRet"]=true},
		["ReleaseUserData"] = {["func"]=cmd_ReleaseUserData, ["isRet"]=true},
		["FortLevelInfoList"] = {["func"]=cmd_FortLevelInfoList, ["isRet"]=false},
		["RequestFortLevel"] = {["func"]=cmd_RequestFortLevel, ["isRet"]=true},
		["CheckDropGem"] = {["func"]=cmd_CheckDropGem, ["isRet"]=false},
		["IsDropGem"] = {["func"]=cmd_IsDropGem, ["isRet"]=true},
		["DropGem"] = {["func"]=cmd_DropGem, ["isRet"]=false},
		["checkGunLevelUp"] = {["func"]=cmd_checkGunLevelUp, ["isRet"]=false},
		["GetGunLevel"] = {["func"]=cmd_GetGunLevel, ["isRet"]=true},
	},

	initFunc = function()
		_dropGemConfig = skynet.call(addressResolver.getAddressByServiceName("GS_model_item_config"),"lua","GetDropGemInfo")
		if not _dropGemConfig then
			error("server _dropGemConfig not initialized in gunUplevel model")
		end
	end,
}

commonServiceHelper.createService(conf)

