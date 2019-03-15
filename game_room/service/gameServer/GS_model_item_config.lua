require "utility.string"
local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local arc4 = require "arc4random"
local readFileUtility = require "utility.readFile"

local _huoDongTimeConfig = {}
local _huoDongRewardConfig = {}
local _itemInfoHash = {}
local _itemComposeInfoHash = {}
local _itemGiveInfoHash = {}
local _rewardGoldFishConfig = {}
local _gunUpleveConfig = {}
local _dropGemConfig = {}
local _vipInfoHash = {}
local _fengHuangDropConfig = {}
local _flyBirdRunMonsterConfig = {}

local function loadHuoDongTimeConfig()
	local sql = "SELECT `Index`,Tips,ActivityType,UNIX_TIMESTAMP(StartTime) as StartTime,UNIX_TIMESTAMP(EndTime) as EndTime FROM `kftreasuredb`.`t_huo_dong_time_config`"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, row in pairs(rows) do
			local info = {
				index = tonumber(row.Index),
				tips = row.Tips,
				activityType = tonumber(row.ActivityType),
				startTime = tonumber(row.StartTime),
				endTime = tonumber(row.EndTime),
			}
			_huoDongTimeConfig[info.index] = info
		end
	end
end

local function loadHuoDongRewardConfig()
	local sql = "SELECT * FROM `kftreasuredb`.`t_huo_dong_reward_config`"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, row in pairs(rows) do
			local info = {
				activityType = tonumber(row.ActivityType),
				activityId = tonumber(row.ActivityId),
				index = tonumber(row.Index),
				activityName = row.ActivityName,
				needVipLevel = tonumber(row.NeedVip),
				perDayMax = tonumber(row.PerDayMax),
				serverMax = tonumber(row.ServerMax),
				needCondition = {},
				rewardList = {},
			}

			local list = row.NeedCondition:split("|")
			for _, item in pairs(list) do
				local itemPart = item:split(":")
				local goods = {
					goodsID = tonumber(itemPart[1]),
					goodsCount = tonumber(itemPart[2]),
				}
				table.insert(info.needCondition,goods)
			end

			local rewardlist = row.RewardList:split("|")
			for _, item in pairs(rewardlist) do
				local itemPart = item:split(":")
				local goods = {
					goodsID = tonumber(itemPart[1]),
					goodsCount = tonumber(itemPart[2]),
				}
				table.insert(info.rewardList,goods)
			end

			table.insert(_huoDongRewardConfig,info)
		end
	end
end

local function loadItemInfoConfig()
	local sql = "SELECT * FROM `kftreasuredb`.`t_item_table_info`"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, row in pairs(rows) do
			local item ={
				itemId = tonumber(row.ItemId),
				itemName = row.ItemName,
				itemType = tonumber(row.ItemType),
				upMax = tonumber(row.UpMax),
				price = tonumber(row.Price),
				isGive = tonumber(row.IsGive),
				isUse = tonumber(row.IsUse),
				isCompose = tonumber(row.IsCompose),
				linkId = tonumber(row.LinkId),
				equipId = tonumber(row.EquipId),
			}
			_itemInfoHash[item.itemId] = item
		end
	end
end

local function loadItemComposeConfig()
	local sql = "SELECT * FROM `kftreasuredb`.`t_item_compose`"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows) == "table" then
		for _, row in pairs(rows) do 
			local itemInfo = {
				id = tonumber(row.ItemId),
				sourceItem = {},
				itemCount = tonumber(row.TargetItemCount),
			}

			local sorceList = row.SourceItem:split("|")
			for _, items in pairs(sorceList) do
				local itemPart = items:split(":")
				local goods = {
					goodsID = tonumber(itemPart[1]),
					goodsCount = tonumber(itemPart[2])
				}
				table.insert(itemInfo.sourceItem,goods)
			end

			_itemComposeInfoHash[itemInfo.id] = itemInfo
		end
	end
end

local function loadItemGiveConfig()
	local sql = "SELECT * FROM `kftreasuredb`.`t_table_give`"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows) == "table" then
		for _, row in pairs(rows) do 
			local itemInfo = {
				linkId = tonumber(row.Id),
				itemType = tonumber(row.Type),
				itemList = {},
			}

			local sorceList = row.Item1:split("|")
			for _, items in pairs(sorceList) do
				local itemPart = items:split(":")
				local item = {
					itemId = tonumber(itemPart[1]),
					itemCount = tonumber(itemPart[2]),
					minRate = tonumber(itemPart[3]),
					maxRate = tonumber(itemPart[4])
				}
				table.insert(itemInfo.itemList,item)
			end

			_itemGiveInfoHash[itemInfo.linkId] = itemInfo
		end
	end
end

local function loadRewardGoldFishConfig()
	local sql = "SELECT * FROM `kftreasuredb`.`t_table_reward_gold_fish`"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, row in pairs(rows) do
			local itemInfo ={
				rewardType = tonumber(row.Type),
				typeName = row.TypeName,
				needScore = tonumber(row.NeedScore),
				itemList = {},
				beforeCount = tonumber(row.BeforeCount),
				beforeReward = {},
			}

			local sorceList = row.GoodsInfo:split("|")
			for _, items in pairs(sorceList) do
				local itemPart = items:split(":")
				local item = {
					index = tonumber(itemPart[1]),
					itemId = tonumber(itemPart[2]),
					itemCount = tonumber(itemPart[3]),
					minRate = tonumber(itemPart[4]),
					maxRate = tonumber(itemPart[5])
				}
				table.insert(itemInfo.itemList,item)
			end

			local beforeList = row.BeforeReward:split("|")
			for _, items in pairs(beforeList) do
				local itemPart = items:split(":")
				local item = tonumber(itemPart[1])
				table.insert(itemInfo.beforeReward,item)
				item = tonumber(itemPart[2])
				table.insert(itemInfo.beforeReward,item)
				item = tonumber(itemPart[3])
				table.insert(itemInfo.beforeReward,item)
			end

			_rewardGoldFishConfig[itemInfo.rewardType] = itemInfo

		end
	end
end

local function loadGunUplevelConfig()
	local sql = "SELECT * FROM `kftreasuredb`.`t_table_gun_uplevel`"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, row in pairs(rows) do
			local info = {
				level = tonumber(row.Level),
				multiple = tonumber(row.Multiple),
				needGem = tonumber(row.NeedGem),
				rewardGold = tonumber(row.RewardGold),
			}
			_gunUpleveConfig[info.level] = info
		end
	end
end	

local function loadDropGemConfig()
	local sql = "SELECT * FROM `kftreasuredb`.`t_table_drop_gem`"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, row in pairs(rows) do
			local info = {
				index = tonumber(row.Index),
				needGold = tonumber(row.NeedGold),
			}
			_dropGemConfig[info.index] = info
		end
	end
end

local function loadVipInfoConfig()
	local sql = "SELECT * FROM `kftreasuredb`.`t_table_vip`"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows) == "table" then
		for _, row in pairs(rows) do 
			local info = {
				vipLevel = tonumber(row.VipLevel),
				tips = row.Tips,
				rmb = tonumber(row.RMB),
				sign = tonumber(row.Sign),
				gem = tonumber(row.Gem),
				exGold = tonumber(row.ExGold),
				gift = tonumber(row.Gift),
				awardFish = tonumber(row.AwardFish),
				bossFish = tonumber(row.BossFish),
				gunLevel = tonumber(row.GunLevel),
			}

			_vipInfoHash[info.vipLevel] = info
		end
	end
end

local function loadFengHuangDropConig()
	local tableConfig,count = readFileUtility.loadCsvFile("DropTable.csv")
	for i = 1, count do
		local info = {
			id = tonumber(tableConfig[i].Id),
			rewardList = {},
			minRate = tonumber(tableConfig[i].MinRate),
			maxRate = tonumber(tableConfig[i].MaxRate),
		}

		local max = tonumber(tableConfig[i].MaxRate)

		local itemList = tableConfig[i].Drop:split("|")
		for _, items in pairs(itemList) do
			local itemPart = items:split(":")
			local goods = {
				goodsID = tonumber(itemPart[1]),
				goodsCount = tonumber(itemPart[2]),
			}
			table.insert(info.rewardList,goods)
		end

		table.insert(_fengHuangDropConfig,info)
	end
end

local function loadFlyBirdRunMonsterConfig()
	local sql = "SELECT * FROM `kftreasuredb`.`t_table_fly_bird_run_monster`"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows) == "table" then
		for _, row in pairs(rows) do 
			local info = {
				id = tonumber(row.ID),
				monsterType =tonumber(row.MonsterType),
				monsterName = row.MonsterName,
				minRate = tonumber(row.MinRate),
				maxRate = tonumber(row.MaxRate),
				multiple = tonumber(row.Multiple),
			}

			_flyBirdRunMonsterConfig[info.id] = info
		end
	end
end



local function cmd_GetHuoDongTimeInfo()
	return _huoDongTimeConfig
end	

local function cmd_GetHuoDongRewardInfo()
	return _huoDongRewardConfig
end	

local function cmd_GetItemConfigInfo(itemId)
	return _itemInfoHash[itemId]
end

local function cmd_GetItemComposeInfo(itemId)
	return _itemComposeInfoHash[itemId]
end

local function cmd_GetItemGiveInfo(linkId)
	return _itemGiveInfoHash[linkId]
end

local function cmd_RewardGoldFishConfigInfo()
	return _rewardGoldFishConfig
end

local function cmd_GetGunUplevelInfo()
	return _gunUpleveConfig
end	

local function cmd_GetDropGemInfo()
	return _dropGemConfig
end

local function cmd_GetGunMultiple(level)
	if level == nil or level == 0 then
		level = 1
	elseif level > #_gunUpleveConfig then
		level = #_gunUpleveConfig
	end

	return _gunUpleveConfig[level].multiple
end	

local function cmd_GetvipInfo()
	return _vipInfoHash
end

local function cmd_GetFengHuangDrop()
	local iRandRate = arc4.random(0,100)
	for k, v in pairs(_fengHuangDropConfig) do
		if v.minRate <= iRandRate and iRandRate <= v.maxRate then
			return v.rewardList 
		end
	end

	return nil
end

local function cmd_GetFlyBirdRmInfo()
	return _flyBirdRunMonsterConfig
end	

local conf = {
	methods = {
		["GetHuoDongTimeInfo"]	= {["func"] = cmd_GetHuoDongTimeInfo, ["isRet"]=true},
		["GetHuoDongRewardInfo"] = {["func"]=cmd_GetHuoDongRewardInfo, ["isRet"]=true},
		["GetItemConfigInfo"] = {["func"]=cmd_GetItemConfigInfo, ["isRet"]=true},
		["GetItemComposeInfo"] = {["func"]=cmd_GetItemComposeInfo, ["isRet"]=true},	
		["GetItemGiveInfo"]	= {["func"] = cmd_GetItemGiveInfo, ["isRet"]=true},
		["GetRewardGfInfo"] = {["func"]=cmd_RewardGoldFishConfigInfo, ["isRet"]=true},
		["GetGunUplevelInfo"] = {["func"]=cmd_GetGunUplevelInfo, ["isRet"]=true},
		["GetDropGemInfo"] = {["func"]=cmd_GetDropGemInfo, ["isRet"]=true},
		["GetGunMultiple"] = {["func"]=cmd_GetGunMultiple, ["isRet"]=true},
		["GetvipInfo"]	= {["func"] = cmd_GetvipInfo, ["isRet"]=true},
		["GetFengHuangDrop"]	= {["func"] = cmd_GetFengHuangDrop, ["isRet"]=true},
		["GetFlyBirdRmInfo"] = {["func"] = cmd_GetFlyBirdRmInfo, ["isRet"]=true},
	},
	initFunc = function()
		loadItemInfoConfig()
		loadItemComposeConfig()
		loadItemGiveConfig()
		loadRewardGoldFishConfig()
		loadGunUplevelConfig()
		loadDropGemConfig()
		loadVipInfoConfig()
		loadFengHuangDropConig()
		loadFlyBirdRunMonsterConfig()
	end,
}

commonServiceHelper.createService(conf)
