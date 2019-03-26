require "utility.string"
local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
--local mysqlutil = require "mysqlutil"
local arc4 = require "arc4random"
local readFileUtility = require "utility.readFile"

local _itemInfoHash = {}
local _itemComposeInfoHash = {}
local _itemGiveInfoHash = {}
local _vipInfoHash = {}
local _gunUpleveConfig = {}
local _huoDongTimeConfig = {}
local _huoDongRewardConfig = {}
local _chouJiangRewardConfig = {}
local _titleInfoHash = {}

local function loadItemInfoConfig()
	local sql = "SELECT * FROM `kftreasuredb`.`t_item_table_info`"
	--local dbConn = addressResolver.getMysqlConnection()
	--local rows = skynet.call(dbConn,"lua","query",sql)
	local rows = {
		{
			ItemId		= 1001,
			ItemName	= "���",
			Tips		= "���",
			Icon		= 1001,
			ItemType	= 1,
			UpMax		= -1,
			Price		= 0,
			ItemFunction = 0,
			IsGive		= 0,
			IsUse		= 0,
			IsCompose	= 0,
			LinkId		= 0,
			EquipId		= 0,
		},
		{
			ItemId		= 1002,
			ItemName	= "��ʯ",
			Tips		= "��ʯ",
			Icon		= 1002,
			ItemType	= 1,
			UpMax		= -1,
			Price		= 0,
			ItemFunction = 0,
			IsGive		= 0,
			IsUse		= 0,
			IsCompose	= 0,
			LinkId		= 0,
			EquipId		= 0,
		},
		{
			ItemId		= 1003,
			ItemName	= "���Ѷһ�ȯ",
			Tips		= "���Ѷһ�ȯ",
			Icon		= 1003,
			ItemType	= 1,
			UpMax		= -1,
			Price		= 0,
			ItemFunction = 0,
			IsGive		= 0,
			IsUse		= 0,
			IsCompose	= 0,
			LinkId		= 0,
			EquipId		= 0,
		},
		{
			ItemId		= 1004,
			ItemName	= "����",
			Tips		= "����һ��ʱ������������",
			Icon		= 1004,
			ItemType	= 1,
			UpMax		= 999,
			Price		= 0,
			ItemFunction = 0,
			IsGive		= 0,
			IsUse		= 0,
			IsCompose	= 0,
			LinkId		= 0,
			EquipId		= 0,
		},
		{
			ItemId		= 1005,
			ItemName	= "��",
			Tips		= "����һ��ʱ���ڿ�����״̬",
			Icon		= 1005,
			ItemType	= 1,
			UpMax		= 999,
			Price		= 0,
			ItemFunction = 0,
			IsGive		= 0,
			IsUse		= 0,
			IsCompose	= 0,
			LinkId		= 0,
			EquipId		= 0,
		}
	}
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
	--local dbConn = addressResolver.getMysqlConnection()
	--local rows = skynet.call(dbConn,"lua","query",sql)
	local rows = {
		{
			ItemId = 1009,
			SourceItem = "1012:1|1006:1|1002:5",
			TargetItemCount = 1,
		},
		{
			ItemId = 1010,
			SourceItem = "1012:1|1013:1|1007:1|1002:5",
			TargetItemCount = 1,
		},
		{
			ItemId = 1011,
			SourceItem = "1012:1|1013:1|1008:1|1002:10",
			TargetItemCount = 1,
		},
		{
			ItemId = 1022,
			SourceItem = "1020:1|1001:2000000|1002:20",
			TargetItemCount = 1,
		},
		{
			ItemId = 1023,
			SourceItem = "1021:1|1001:10000000|1002:100",
			TargetItemCount = 1,
		},
		{
			ItemId = 1030,
			SourceItem = "1029:10",
			TargetItemCount = 1,
		}
	}
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
	--local dbConn = addressResolver.getMysqlConnection()
	--local rows = skynet.call(dbConn,"lua","query",sql)
	local rows = {
		{
			Id = 1;
			Name = "������";
			Desc = "���Կ���20W��һ��߻��һ����ɫˮ����̨";
			Type = 3;
			Item1 = "1001:200000:1:100";
		},
		{
			Id = 2;
			Name = "����";
			Desc = "���Կ���50W��һ��߻��һ����ɫˮ����̨";
			Type = 3;
			Item1 = "1001:500000:1:100";
		}
		,
		{
			Id = 3;
			Name = "������";
			Desc = "���Կ���100W��һ��߻��һ����ɫˮ����̨";
			Type = 3;
			Item1 = "1001:1000000:1:100";
		},
		{
			Id = 4;
			Name = "�ر�ͼ��";
			Desc = "���ۿ��Ի��1000���";
			Type = 3;
			Item1 = "1001:1000:1:100";
		},
		{
			Id = 5;
			Name = "�ر�ͼ��";
			Desc = "���ۿ��Ի��5000���";
			Type = 3;
			Item1 = "1001:5000:1:100";
		}

	}
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

local function loadHuoDongTimeConfig()
	local sql = "SELECT `Index`,Tips,ActivityType,UNIX_TIMESTAMP(StartTime) as StartTime,UNIX_TIMESTAMP(EndTime) as EndTime,`TuPianId`,`BeiJingId`,`TextName`,`ActivityClass` FROM `kftreasuredb`.`t_huo_dong_time_config`"
	--local dbConn = addressResolver.getMysqlConnection()
	--local rows = skynet.call(dbConn,"lua","query",sql)

	if type(rows)=="table" then
		for _, row in pairs(rows) do
			local info = {
				index = tonumber(row.Index),
				tips = row.Tips,
				activityType = tonumber(row.ActivityType),
				startTime = tonumber(row.StartTime),
				endTime = tonumber(row.EndTime),
				tuPianID = row.TuPianId,
				beiJingID = row.BeiJingId,
				textName = row.TextName,
				activityClass = tonumber(row.ActivityClass),
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
				multiple = tonumber(row.Multiple),
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

local function loadChouJiangRewardConfig()
	local sql = "SELECT * FROM `kftreasuredb`.`t_frist_charge_reward`"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, row in pairs(rows) do
			local info = {
				ID = tonumber(row.ID),
				MinRmb = tonumber(row.MinRmb),
				MaxRmb = tonumber(row.MaxRmb),
				rewardList = {},
			}

			local rewardlist = row.RewardList:split("|")
			for _, item in pairs(rewardlist) do
				local itemPart = item:split(":")
				local goods = {
					index = tonumber(itemPart[1]),
					goodsID = tonumber(itemPart[2]),
					goodsCount = tonumber(itemPart[3]),
					minRate = tonumber(itemPart[4]),
					maxRate = tonumber(itemPart[5]),
				}
				table.insert(info.rewardList,goods)
			end

			table.insert(_chouJiangRewardConfig,info)
		end
	end
end

local function loadTitleConfig()
	local sql = "SELECT * FROM `kftreasuredb`.`t_title_table_info`"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, row in pairs(rows) do
			local info = {
				ID = tonumber(row.ID),
				titleType = tonumber(row.TitleType),
				titleId = tonumber(row.TitleID),
				titleName = row.TitleName,
			}

			table.insert(_titleInfoHash,info)
		end
	end
end

local function cmd_GetItemConfigInfo(itemId)
	return _itemInfoHash[itemId]
end

local function cmd_GetItemInfoHash()
	return _itemInfoHash
end	

local function cmd_GetItemComposeInfo(itemId)
	return _itemComposeInfoHash[itemId]
end

local function cmd_GetItemGiveInfo(linkId)
	return _itemGiveInfoHash[linkId]
end

local function cmd_GetvipInfo()
	return _vipInfoHash
end	

local function cmd_GetGunUplevelInfo()
	return _gunUpleveConfig
end	

local function cmd_GetHuoDongTimeInfo()
	return _huoDongTimeConfig
end	

local function cmd_GetHuoDongRewardInfo()
	return _huoDongRewardConfig
end	

local function cmd_ChouJiang(rmb)
	for k, v in pairs(_chouJiangRewardConfig) do 
		if v.MinRmb <= rmb and rmb <= v.MaxRmb then
			local iRandRate = arc4.random(1,100)
			for kk, vv in pairs(v.rewardList) do
				if vv.minRate <= iRandRate and iRandRate <= vv.maxRate then
					return vv
				end
			end
			break
		end
	end

	return nil
end

local function cmd_GetTitleName(titleType,titleId)
	for k, v in pairs(_titleInfoHash) do
		if v.titleType == titleType and v.titleId == titleId then
			return v.titleName
		end
	end

	return nil
end

local conf = {
	methods = {
		["GetItemConfigInfo"] = {["func"]=cmd_GetItemConfigInfo, ["isRet"]=true},
		["GetItemInfoHash"] = {["func"]=cmd_GetItemInfoHash, ["isRet"]=true},
		["GetItemComposeInfo"] = {["func"]=cmd_GetItemComposeInfo, ["isRet"]=true},	
		["GetItemGiveInfo"]	= {["func"] = cmd_GetItemGiveInfo, ["isRet"]=true},
		["GetvipInfo"]	= {["func"] = cmd_GetvipInfo, ["isRet"]=true},
		["GetGunUplevelInfo"] = {["func"]=cmd_GetGunUplevelInfo, ["isRet"]=true},
		["GetHuoDongTimeInfo"]	= {["func"] = cmd_GetHuoDongTimeInfo, ["isRet"]=true},
		["GetHuoDongRewardInfo"] = {["func"]=cmd_GetHuoDongRewardInfo, ["isRet"]=true},
		["ChouJiang"] = {["func"]=cmd_ChouJiang, ["isRet"]=true},
		["GetTitleName"] = {["func"]=cmd_GetTitleName, ["isRet"]=true},
	},
	initFunc = function()
		loadItemInfoConfig()
		loadItemComposeConfig()
		loadItemGiveConfig()
		--loadVipInfoConfig()
		--loadGunUplevelConfig()
		--loadHuoDongTimeConfig()
		--loadHuoDongRewardConfig()
		--loadChouJiangRewardConfig()
		--loadTitleConfig()
	end,
}

commonServiceHelper.createService(conf)

