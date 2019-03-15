local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local ServerUserItem = require "sui"
local COMMON_CONST = require "define.commonConst"
local GS_CONST = require "define.gsConst"
local arc4 = require "arc4random"

local _hash = {
	--bagItemList = {},	--用户背包物品
}

local recordList = {}

local function cmd_SaveItemRecord()
	local dbConn = addressResolver.getMysqlConnection()
	for k, v in pairs(recordList) do
		local sql = string.format("INSERT INTO `kfrecorddb`.`t_item_record` (`UserId`, `FromId`, `AddOrDel`, `ItemId`, `ItemCount`, `Date`, `InGame`) VALUES(%d,%d,%d,%d,%d,'%s',1)",
			v.userID,v.fromId,v.addOrDel,v.goodsID,v.goodsCount,v.insertTime)
		skynet.send(dbConn, "lua", "execute", sql)
	end
	recordList = {}
end

local function AddItemRecord(userID,fromId,addOrDel,goodsID,goodsCount)
	local info = {
		userID = userID,
		fromId = fromId,
		addOrDel = addOrDel,
		goodsID = goodsID,
		goodsCount = goodsCount,
		insertTime = os.date("%Y-%m-%d %H:%M:%S", os.time())
	}
	table.insert(recordList,info)

	-- if #recordList >= 100 then
		cmd_SaveItemRecord()
	-- end
end

local function AddItemToBag(userID,goodsID,goodsCount)
	local item = {
		goodsID = goodsID,
		goodsCount = goodsCount,
		isGive = 0,
		isUse = 0,
		isCompositing = 0,
		needGoodsItem = {},
		getGoodsItem = {},
		useTime = 0,
		equipGoodsID = 0,
		useType = 0,
		oldGoodsCount = goodsCount,
	}

	local linkId = 0
	local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
	local itemInfoConfig = skynet.call(configAddress,"lua","GetItemConfigInfo",item.goodsID)
	if itemInfoConfig then
		item.isGive = itemInfoConfig.isGive
		item.isUse = itemInfoConfig.isUse
		item.isCompositing = itemInfoConfig.isCompose
		linkId = itemInfoConfig.linkId
		item.equipGoodsID = itemInfoConfig.equipId
	end

	local composeConfig = skynet.call(configAddress,"lua","GetItemComposeInfo",item.goodsID)
	if composeConfig then
		for _, vv in pairs(composeConfig.sourceItem) do 
			local goods = {
				goodsID = vv.goodsID,
				goodsCount = vv.goodsCount
			}
			table.insert(item.needGoodsItem,goods)
		end
	end

	if linkId ~= 0 then
		local giveConfig = skynet.call(configAddress,"lua","GetItemGiveInfo",linkId)
		if giveConfig then
			for _, v in pairs(giveConfig.itemList) do
				local goods = {
					goodsID = v.itemId,
					goodsCount = v.itemCount
				}
				table.insert(item.getGoodsItem,goods)
			end
			item.useType = giveConfig.itemType
		end
	end

	local endTime = 0
	if COMMON_CONST.CheckIsPaoTaiItem(goodsID) and item.goodsCount ~= 0 then	
		item.useTime = COMMON_CONST.PAO_TAI_USE_TIME
		endTime = os.time() + COMMON_CONST.PAO_TAI_USE_TIME
	end

	if COMMON_CONST.CheckIsTimeCardItem(goodsID) and item.goodsCount ~= 0 then
		item.useTime = COMMON_CONST.TIME_CARD_USE_TIME
		endTime = os.time() + COMMON_CONST.TIME_CARD_USE_TIME
	end

	if COMMON_CONST.CheckIsSpecCannonItem(goodsID) and item.goodsCount ~= 0 then
		item.useTime = COMMON_CONST.SPEC_CANNON_TIME
		endTime = os.time() + COMMON_CONST.SPEC_CANNON_TIME
	end


	table.insert(_hash[userID],item)

	local sql = string.format("insert into `kffishdb`.`t_bag` values(%d,%d,%d,%d)",userID,item.goodsID,item.goodsCount,endTime)
	local dbConn = addressResolver.getMysqlConnection()
	skynet.send(dbConn, "lua", "execute", sql)
end

local function cmd_GoodsInfoList(tcpAgent,tcpAgentData)
	local sendGoods = {
		goodsItem = {},
	}
	sendGoods.goodsItem = _hash[tcpAgentData.userID]
	if sendGoods.goodsItem ~= nil then
		-- for k, v in pairs(sendGoods.goodsItem) do
		-- 	if COMMON_CONST.CheckIsPaoTaiItem(v.goodsID) or COMMON_CONST.CheckIsTimeCardItem(v.goodsID) then
		-- 		local dbConn = addressResolver.getMysqlConnection()
		-- 		local sql = string.format("SELECT EndTime FROM `kffishdb`.`t_bag` where UserId=%d and ItemId=%d",tcpAgentData.userID,v.goodsID)
		-- 		local rows = skynet.call(dbConn,"lua","query",sql)
		-- 		if rows[1] ~= nil then
		-- 			local endTime = tonumber(rows[1].EndTime)
		-- 			if endTime ~= 0 then
		-- 				local nowTime = os.time()
		-- 				if endTime <= nowTime then
		-- 					v.useTime = 0
		-- 					v.goodsCount = 0
		-- 					v.oldGoodsCount = 0
		-- 					sql = string.format("update `kffishdb`.`t_bag` set ItemCount = %d,EndTime=%d where UserId=%d and ItemId=%d",
		-- 						v.goodsCount,0,tcpAgentData.userID,v.goodsID)
		-- 					skynet.send(dbConn, "lua", "execute", sql)
		-- 				else
		-- 					v.useTime = endTime - nowTime
		-- 				end
		-- 			end
		-- 		end 
		-- 	end
		-- end
		skynet.send(tcpAgent,"lua","forward",0x010900,sendGoods)
	end
end

local function cmd_GoodsInfo(userID,goodsId)
	local userItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"),"lua","getUserItem",userID)
	if userItem == nil then
		return
	end
	local attr = ServerUserItem.getAttribute(userItem, {"agent"})
	if attr.agent == 0 then
		return
	end
	local goodsList = {}
	goodsList = _hash[userID]
	if not goodsList then
		skynet.error(string.format("----------游戏里玩家请求背包单个物品信息出错-----userid=%d,itemId=%d---------------",userID,goodsId))
		return
	end

	for _, v in pairs(goodsList) do
		if v.goodsID == goodsId then
			if COMMON_CONST.CheckIsPaoTaiItem(goodsId) or COMMON_CONST.CheckIsTimeCardItem(goodsId) or COMMON_CONST.CheckIsSpecCannonItem(goodsId) then
				-- local dbConn = addressResolver.getMysqlConnection()
				-- local sql = string.format("SELECT EndTime FROM `kffishdb`.`t_bag` where UserId=%d and ItemId=%d",userID,goodsId)
				-- local rows = skynet.call(dbConn,"lua","query",sql)
				-- if rows[1] ~= nil then
				-- 	local endTime = tonumber(rows[1].EndTime)
				-- 	if endTime ~= 0 then
				-- 		local nowTime = os.time()
				-- 		if endTime <= nowTime then
				-- 			v.useTime = 0
				-- 			v.goodsCount = 0
				-- 			v.oldGoodsCount = 0
				-- 			local sql = string.format("update `kffishdb`.`t_bag` set ItemCount = %d,EndTime=%d where UserId=%d and ItemId=%d",
				-- 				v.goodsCount,0,userID,goodsId)
				-- 			local dbConn = addressResolver.getMysqlConnection()
				-- 			skynet.send(dbConn, "lua", "execute", sql)
				-- 		else
				-- 			v.useTime = endTime - nowTime
				-- 		end
				-- 	end
				-- end 

				if v.useTime ~= 0 then
					local nowTime = os.time()
					if v.endTime <= nowTime then
						v.useTime = 0
						v.goodsCount = 0
						v.oldGoodsCount = 0
						v.endTime = 0
						local sql = string.format("update `kffishdb`.`t_bag` set ItemCount = %d,EndTime=%d where UserId=%d and ItemId=%d",
							v.goodsCount,0,userID,goodsId)
						local dbConn = addressResolver.getMysqlConnection()
						skynet.send(dbConn, "lua", "execute", sql)
					else
						v.useTime = v.endTime - nowTime
					end
				end
			end
			skynet.send(attr.agent,"lua","forward",0x010901,v)
			break
		end 
	end
end

local function cmd_OffsetGoodsInfo(tcpAgent,pbObj,tcpAgentData)
	local goods = {
		offsetGoodsItem = pbObj.offsetGoodsItem,			
		code = 0,
		callBackAddress = pbObj.callBackAddress,
	}

	local itemList = {}
	itemList = _hash[tcpAgentData.userID]
	if not itemList then
		return goods
	end

	for _, v in pairs(goods.offsetGoodsItem) do 
		local bFind = false
		for _, vv in ipairs(itemList) do
			if v.goodsID == vv.goodsID then
				bFind = true
				if math.abs(v.goodsCount) > vv.goodsCount then
					goods.code = 1
					return goods
				end
				if v.goodsCount == 0 then
					goods.code = 1
					return goods
				end
				goto continue
			end
		end

		if bFind == false then
			goods.code = 1
			return goods
		end

		::continue::
	end

	--消耗道具
	local abs = math.abs
	for _, v in pairs(goods.offsetGoodsItem) do 
		local itemCount = abs(v.goodsCount)

		skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",tcpAgentData.userID,
			v.goodsID,-itemCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_USE,true)
	end

	return goods
end

local function cmd_SaveUserItem(userID)
	local itemList = {}
	itemList = _hash[userID]
	if not itemList then
		skynet.error(string.format("------------游戏来保存玩家数据找不到玩家---------userid=%d--------------------",userID))
		return
	end

	local dbConn = addressResolver.getMysqlConnection()
	for _, v in pairs(itemList) do 
		if v.goodsCount ~= v.oldGoodsCount then
			--时间的物品已经在改变时间的时候处理了
			-- if COMMON_CONST.CheckIsPaoTaiItem(v.goodsID) or COMMON_CONST.CheckIsTimeCardItem(v.goodsID) then
			-- 	goto continue
			-- end

			if v.goodsCount < 0 then
				skynet.error(string.format("----------游戏里保存玩家数据,道具变成负数了---userid=%d,itemid=%d,count=%s--------------------------",userID,v.goodsID,v.goodsCount))
				v.goodsCount = 0
			end

			--local sql = string.format("update `kffishdb`.`t_bag` set `itemCount`=%d where `UserId`=%d and `ItemId`=%d",v.goodsCount,userID,v.goodsID)
			local addCount = v.goodsCount - v.oldGoodsCount
			local sql = string.format("call `kffishdb`.`sp_write_bag` (%d,%d,%d)",userID,v.goodsID,addCount)
			local ret = skynet.call(dbConn, "lua", "call", sql)[1]
			if tonumber(ret.retCode) ~= 0 then		
				skynet.error(string.format("----游戏里写背包数据出错了--userID=%d,goodsID=%d,goodsCount=%d--code=%s,mes=%s----",userID,v.goodsID,addCount,tonumber(ret.retCode),tostring(ret.retMsg)))
			end

			-- if v.goodsID == 1001 then 
			-- 	skynet.error(string.format("----------保存数据-----userid=%d-------count=%d,oldGoodsCount=%d----------------",userID,v.goodsCount,v.oldGoodsCount))
			-- end

			v.oldGoodsCount = v.goodsCount

			-- local userItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "getUserItem", userID)
			-- if userItem then
			-- 	if v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_FISH then
			-- 		ServerUserItem.setAttribute(userItem, {gift = v.goodsCount})
			-- 	elseif v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
			-- 		ServerUserItem.setAttribute(userItem, {score = v.goodsCount})
			-- 	end
			-- end
		end

		--::continue::
	end

	return true
end

local function cmd_LoadUserItem(userItem)
	local itemList = {}
	local attr = ServerUserItem.getAttribute(userItem, {"userID","score","gift"})
	local sql = string.format("SELECT * FROM `kffishdb`.`t_bag` where UserId = %d", attr.userID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	local bFindFish = false
	local bFindGold = false
	local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
	if type(rows)=="table" then
		for _, row in ipairs(rows) do
			local item = {
				goodsID = tonumber(row.ItemId),
				goodsCount = tonumber(row.ItemCount),
				isGive = 0,
				isUse = 0,
				isCompositing = 0,
				needGoodsItem = {},
				getGoodsItem = {},
				useTime = tonumber(row.EndTime),
				equipGoodsID = 0,
				useType = 0,
				oldGoodsCount = tonumber(row.ItemCount),
				endTime = tonumber(row.EndTime),
			}

			if item.useTime ~= 0 then
				if item.useTime <= os.time() then
					item.useTime = 0
					item.goodsCount = 0
					item.oldGoodsCount = 0
					item.endTime = 0
					sql = string.format("update `kffishdb`.`t_bag` set ItemCount = %d,EndTime=%d where UserId=%d and ItemId=%d",
						item.goodsCount,item.useTime,attr.userID,item.goodsID)
					skynet.send(dbConn, "lua", "execute", sql)
				else
					item.useTime = item.useTime - os.time()
				end
			end

			local linkId = 0
			local itemInfoConfig = skynet.call(configAddress,"lua","GetItemConfigInfo",item.goodsID)
			if itemInfoConfig then
				item.isGive = itemInfoConfig.isGive
				item.isUse = itemInfoConfig.isUse
				item.isCompositing = itemInfoConfig.isCompose
				linkId = itemInfoConfig.linkId
				item.equipGoodsID = itemInfoConfig.equipId
			end

			local composeConfig = skynet.call(configAddress,"lua","GetItemComposeInfo",item.goodsID)
			if composeConfig then
				for _, vv in pairs(composeConfig.sourceItem) do 
					local goods = {
						goodsID = vv.goodsID,
						goodsCount = vv.goodsCount
					}
					table.insert(item.needGoodsItem,goods)
				end
			end

			if linkId ~= 0 then
				local giveConfig = skynet.call(configAddress,"lua","GetItemGiveInfo",linkId)
				if giveConfig then
					for _, v in pairs(giveConfig.itemList) do
						local goods = {
							goodsID = v.itemId,
							goodsCount = v.itemCount
						}
						table.insert(item.getGoodsItem,goods)
					end
					item.useType = giveConfig.itemType
				end
			end

			table.insert(itemList,item)

			if item.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_FISH then
				--bFindFish = true
				ServerUserItem.setAttribute(userItem, {gift = item.goodsCount})
			elseif item.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
				--bFindGold = true
				ServerUserItem.setAttribute(userItem, {score = item.goodsCount})
			end
		end
		_hash[attr.userID] = itemList
	end

	-- if bFindGold == false then
	-- 	AddItemToBag(attr.userID,COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,attr.score)
	-- end

	-- if bFindFish == false then
	-- 	AddItemToBag(attr.userID,COMMON_CONST.ITEM_ID.ITEM_ID_FISH,attr.gift)
	-- end
end

local function cmd_ReleaseUserItem(userID)
	_hash[userID] = nil
end

local function cmd_GetItemCount(userID,goodsID)
	local itemList = {}
	itemList = _hash[userID]
	if not itemList then
		return 0
	end

	for _, v in pairs(itemList) do 
		if goodsID == v.goodsID then
			return v.goodsCount
		end
	end

	return 0
end

--充值,救济金,改名字,大厅改变物品都已经在大厅处理了
local function IsOperatorByLoginServer(fromWhere)
	if fromWhere == COMMON_CONST.ITEM_SYSTEM_TYPE.PAY_ADD or fromWhere == COMMON_CONST.ITEM_SYSTEM_TYPE.RESCUE_COIN 
		or fromWhere == COMMON_CONST.ITEM_SYSTEM_TYPE.USE_CHANGE_NAME or fromWhere == COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FROM_LS then
		return true
	end

	return false
end

local function cmd_ChangeItemCount(userID,goodsID,goodsCount,fromWhere,bNeedNotify,bReset)
	local bFind = false
	local itemList = {}
	itemList = _hash[userID]
	if not itemList then
		skynet.error(string.format("--改变玩家道具数据,找不到玩家背包数据了----fromWhere=%s,userID=%s,itemId=%s,changeCount=%s-------",fromWhere,userID,goodsID,goodsCount))
		return
	end

	for _, v in pairs(itemList) do 
		if goodsID == v.goodsID then
			--炮台在背包中最多只有一个，改变的只是时间,炮台这个接口过来只会加不会减，因为倒计时客户端做了
			if bReset then
				v.goodsCount = goodsCount
			else
				v.goodsCount = v.goodsCount + goodsCount
			end

			if IsOperatorByLoginServer(fromWhere) then
				v.oldGoodsCount = v.oldGoodsCount + goodsCount
			end

			-- if goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
			-- 	skynet.error(string.format("---------userID=%d-----------改变金币---------count=%d----nowCount=%d----------------",userID,goodsCount,v.goodsCount))
			-- end

			if COMMON_CONST.CheckIsPaoTaiItem(goodsID) then
				if goodsCount > 0 then
					v.goodsCount = 1
				else
					v.goodsCount = 0
					v.useTime = 0
				end
			end

			if v.goodsCount < 0 then
				skynet.error(string.format("---fromWhere=%s----玩家的背包道具变成负数了,userID=%s,itemId=%s,changeCount=%s,itemCount=%s",fromWhere,userID,goodsID,goodsCount,v.goodsCount))
				v.goodsCount = 0
			end

			if COMMON_CONST.CheckIsPaoTaiItem(goodsID) or COMMON_CONST.CheckIsTimeCardItem(goodsID) then	
				-- local dbConn = addressResolver.getMysqlConnection()
				-- local sql = string.format("SELECT EndTime FROM `kffishdb`.`t_bag` where UserId=%d and ItemId=%d",userID,goodsID)
				-- local rows = skynet.call(dbConn,"lua","query",sql)
				-- if rows[1] ~= nil then
				-- 	local endTime = tonumber(rows[1].EndTime)
					local nowTime = os.time()
					if v.endTime == nil then
						v.endTime = 0
					end

					if v.goodsCount <= 0 then
						v.endTime = 0
					else
						local useTime = COMMON_CONST.PAO_TAI_USE_TIME
						if COMMON_CONST.CheckIsTimeCardItem(goodsID) then
							useTime = COMMON_CONST.TIME_CARD_USE_TIME
						elseif COMMON_CONST.CheckIsSpecCannonItem(goodsID) then
							useTime = COMMON_CONST.SPEC_CANNON_TIME
						end


						if v.endTime <= nowTime then
							v.useTime = useTime
							v.endTime = nowTime + useTime
						else
							if COMMON_CONST.CheckIsTimeCardItem(goodsID) then 
								if goodsCount>0 then
									v.useTime = useTime
									v.endTime = nowTime + useTime
								end
							else
								v.useTime = v.endTime - nowTime + useTime
								v.endTime = v.endTime + useTime
							end
						end
					end

					if COMMON_CONST.CheckIsTimeCardItem(goodsID) and goodsCount<0 then
						--如果是消耗掉合成卡  不更新时间
					else
						sql = string.format("update `kffishdb`.`t_bag` set EndTime = %d where UserId=%d and ItemId=%d",
							v.endTime,userID,goodsID)
						local dbConn = addressResolver.getMysqlConnection()
						skynet.send(dbConn, "lua", "execute", sql)
					end

				--end
			end

			bFind = true
			break
		end
	end

	if not bFind then
		AddItemToBag(userID,goodsID,goodsCount)
	end

	if bNeedNotify then
		--skynet.error(string.format("--------------通知物品改变---userid=%d,goodsID=%d,count=%d-------fromwhere=%d--------------------------",userID,goodsID,goodsCount,fromWhere))
		cmd_GoodsInfo(userID,goodsID)
	end

	if fromWhere == COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH then
		if goodsID ~= COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
			if goodsCount > 0 then
				AddItemRecord(userID,fromWhere,1,goodsID,math.abs(goodsCount))
			else
				AddItemRecord(userID,fromWhere,2,goodsID,math.abs(goodsCount))
			end
		end
	else
		if not IsOperatorByLoginServer(fromWhere) then
			if goodsCount > 0 then
				AddItemRecord(userID,fromWhere,1,goodsID,math.abs(goodsCount))
			else
				AddItemRecord(userID,fromWhere,2,goodsID,math.abs(goodsCount))
			end
		end
	end
end

local function UpdateUserRecordGold(userID,addGold)
	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("INSERT INTO `kfrecorddb`.`t_record_gold_by_use_box` (UserId,SumGold) VALUES(%d,%d) ON DUPLICATE KEY UPDATE SumGold=SumGold+%d",userID,addGold,addGold)
	skynet.send(dbConn, "lua", "execute", sql)
end	

local function ChangeItemCount(userID,itemlist,sui,fromWhere)
	for _, v in pairs(itemlist) do 
		if v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
			UpdateUserRecordGold(userID,v.goodsCount)
			ServerUserItem.addAttribute(sui, {score=v.goodsCount})
			local userAttr = ServerUserItem.getAttribute(sui, {"tableID"})
			skynet.call(addressResolver.getTableAddress(userAttr.tableID),"lua","onUserScoreNotify",sui)
			skynet.call(addressResolver.getTableAddress(userAttr.tableID),"lua","onUserGoldRecordChange",sui)
		-- 	if v.goodsCount > 0 then
		-- 		AddItemRecord(userID,fromWhere,1,v.goodsID,math.abs(v.goodsCount))
		-- 	else
		-- 		AddItemRecord(userID,fromWhere,2,v.goodsID,math.abs(v.goodsCount))
		-- 	end
		-- else
		-- 	cmd_ChangeItemCount(userID,v.goodsID,v.goodsCount,fromWhere,true)
		end

		cmd_ChangeItemCount(userID,v.goodsID,v.goodsCount,fromWhere,true)
	end
end

local function cmd_UseGoodsInfo(userID,goodsID,getGoodsID,sui)
	local re = {
		useGoodsItem = {},
		code = 1,
	}
	local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
	local itemInfoConfig = skynet.call(configAddress,"lua","GetItemConfigInfo",goodsID)
	if not itemInfoConfig then
		return re
	end

	if itemInfoConfig.isUse ~= 1 then
		return re
	end

	if cmd_GetItemCount(userID,goodsID) <= 0  then
		return re
	end

	local giveConfig = skynet.call(configAddress,"lua","GetItemGiveInfo",itemInfoConfig.linkId)
	if not giveConfig then
		return re
	end

	local itemlist = {}
	--1.随机给1个，2玩家选1，3全给
	if giveConfig.itemType == 1 then
		local randRate = arc4.random(1,100)
		for _, v in pairs(giveConfig.itemList) do
			if v.minRate <= randRate and randRate <= v.maxRate then
				local item = {
					goodsID = v.itemId,
					goodsCount = v.itemCount
				}
				table.insert(itemlist,item)
			end
		end
	elseif giveConfig.itemType == 2 then
		for _, v in pairs(giveConfig.itemList) do 
			if v.itemId == getGoodsID then
				local itemr = {
					goodsID = v.itemId,
					goodsCount = v.itemCount
				}
				table.insert(itemlist,itemr)
				break
			end
		end
	else
		for _, v in pairs(giveConfig.itemList) do
			local itemr = {
				goodsID = v.itemId,
				goodsCount = v.itemCount
			}
			table.insert(itemlist,itemr)
		end
	end

	if #itemlist == 0 then
		return re
	end

	cmd_ChangeItemCount(userID,goodsID,-1,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_USE,true)
	ChangeItemCount(userID,itemlist,sui,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_USE)

	re.useGoodsItem = itemlist
	re.code = 0
	return re
end

--清除合成cd所需要添加的道具消耗  暂时只有钻石
local function GetCleanComposeCDItem( userID , ComposeItemID )
	local CDtimes = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "GetLimitComposeCD",userID,ComposeItemID)
	if CDtimes~=0 then
		local cost=0
		if CDtimes == 1 then
			cost=10
		elseif CDtimes==2 then
			cost=20
		elseif CDtimes==3 then
			cost=50
		elseif CDtimes>=4 then
			cost=100
		end
		local goods = {
			goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_JEWEL,
			goodsCount = cost
		}
		return goods
	else
		return nil
	end

end

--获取合成还有多少冷却时间 
local function CheckComposeCD(userID,ComposeItemID)
	local limitID=0;
	if ComposeItemID == COMMON_CONST.ITEM_ID.ITEM_ID_FIRE_CRYSTAL then  --暂时只有火焰结晶需要cd
		limitID = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_FIRECRYSTAL_CD
	end

	if limitID~=0 then 
		local limitCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","GetLimitCount",userID,limitID)
		if limitCount - os.time() >0 then 
			return  limitCount - os.time()
		else
			return 0
		end
	else
		return 0 
	end
end

--合成成功 刷新cd
local function CheckAndAddComposeCD( userID,ComposeItemID )
	local limitid = 0
	local limit_count = 0
	if ComposeItemID == COMMON_CONST.ITEM_ID.ITEM_ID_FIRE_CRYSTAL then
		limitid = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_FIRECRYSTAL_CD
		limit_count = os.time()+COMMON_CONST.FIRECRYSTAL_CD_TIME
	end

	if limitid~=0 then
		skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua","AddLimit",userID,limitid,limit_count)

		skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "SetLimitComposeCD",userID,ComposeItemID)
	end
end


local function CheckItemAndComsume(userID,itemlist,fromWhere)
	local List = {}
	List = _hash[userID]
	if not List then
		return false
	end

	local findCount = 0
	for k, v in pairs(itemlist) do 
		for kk, vv in pairs(List) do 
			if v.goodsID == vv.goodsID then
				findCount = findCount + 1
				if vv.goodsCount < v.goodsCount then
					return false
				end
				break
			end
		end
	end

	if findCount < #itemlist then
		return false
	end

	for k, v in pairs(itemlist) do 
		for kk, vv in pairs(List) do 
			if v.goodsID == vv.goodsID then
				if v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
					local userItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"),"lua","getUserItem",userID)
					if userItem == nil then
						break
					end

					ServerUserItem.addAttribute(userItem, {score=-v.goodsCount})
					local userAttr = ServerUserItem.getAttribute(userItem, {"tableID"})
					skynet.call(addressResolver.getTableAddress(userAttr.tableID),"lua","onUserScoreNotify",userItem)
				end

				cmd_ChangeItemCount(userID,v.goodsID,-v.goodsCount,fromWhere,true)
				
				break
			end
		end
	end

	return true
end

local function cmd_CompositingGoodsInfo(tcpAgentData,goodsId)
	local re = {
		getCompositingGoodsItem = {},
		code = 1,
	}

	local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
	local itemInfoConfig = skynet.call(configAddress,"lua","GetItemConfigInfo",goodsId)
	if not itemInfoConfig then
		return re
	end

	local composeConfig = skynet.call(configAddress,"lua","GetItemComposeInfo",goodsId)
	if not composeConfig then
		return re
	end

	if CheckComposeCD(tcpAgentData.userID,goodsId) >0 then
		--如果有CD时间 添加消除CD时间所需要的道具
		local needItem = GetCleanComposeCDItem(tcpAgentData.userID,goodsId) 
		if needItem~=nil then
			table.insert(composeConfig.sourceItem,needItem)
		end
	end

	if not CheckItemAndComsume(tcpAgentData.userID,composeConfig.sourceItem,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_COMPOSE) then
		return re
	end

	cmd_ChangeItemCount(tcpAgentData.userID,goodsId,composeConfig.itemCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_COMPOSE,true)

	local goods = {
		goodsID = goodsId,
		goodsCount = composeConfig.itemCount
	}
	table.insert(re.getCompositingGoodsItem,goods)

	if COMMON_CONST.ITEM_ID.ITEM_ID_SILVE_BOX <= goodsId and goodsId <= COMMON_CONST.ITEM_ID.ITEM_ID_PT_BOX then
		local userAttr = ServerUserItem.getAttribute(tcpAgentData.sui, {"tableID","nickName"})
		local nickName = COMMON_CONST.HideNickName(userAttr.nickName)
		local msg = string.format("恭喜玩家%s合成了一个%s",nickName,itemInfoConfig.itemName)
		local tableAddress
		if userAttr.tableID~=GS_CONST.INVALID_TABLE then
			tableAddress = addressResolver.getTableAddress(userAttr.tableID)
		end

		if tableAddress then
			skynet.send(tableAddress,"lua","sendSystemMessage",msg,false,true,false,false)
		end
	end

	--如果是有合成CD的 添加CD
	CheckAndAddComposeCD()

	re.code = 0
	return re
end

local function addGiveItemRecord(userID,giveUserId,itemId,itemCount)
	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("INSERT INTO `kfrecorddb`.`t_record_give_item` (`UserId`,`GiveUserId`,`ItemId`,`ItemCount`,`Date`) VALUES(%d,%d,%d,%d,now())",userID,giveUserId,itemId,itemCount)
	skynet.send(dbConn, "lua", "execute", sql)
end	

local function cmd_GiveGoodsInfo(pbObj,userID,sui)
	local re = { 
		code = 1
	}

	local attr = ServerUserItem.getAttribute(sui,{"memberOrder"})
	if attr.memberOrder < 2 then
		re.code = 2
		return re
	end

	local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
	local itemInfoConfig = skynet.call(configAddress,"lua","GetItemConfigInfo",pbObj.goodsID)
	if not itemInfoConfig then
		return re
	end

	if itemInfoConfig.isGive ~= 1 or pbObj.goodsCount == nil or pbObj.goodsCount <= 0 then
		return re
	end

	local itemCount = cmd_GetItemCount(userID,pbObj.goodsID)
	if itemCount < pbObj.goodsCount then
		return re
	end

	cmd_ChangeItemCount(userID,pbObj.goodsID,-pbObj.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_GIVE,true)
	local itemList = {}
	local item = {
		goodsID = pbObj.goodsID,
		goodsCount = pbObj.goodsCount
	}
	table.insert(itemList,item)
	--skynet.send(addressResolver.getAddressByServiceName("LS_model_message"),"lua","sendEmailToUser",pbObj.UserID,itemList)

	addGiveItemRecord(userID,pbObj.UserID,item.goodsID,item.goodsCount)
	
	re.code = 0
	return re
end

local function cmd_equipGoodsInfo(pbObj,userID)
	local re = { 
		code = 1
	}

	local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
	local itemInfoConfig = skynet.call(configAddress,"lua","GetItemConfigInfo",pbObj.goodsID)
	if not itemInfoConfig then
		return re
	end

	if itemInfoConfig.equipId == 0 then
		return re
	end

	local itemCount = cmd_GetItemCount(userID,pbObj.goodsID)
	if itemCount < 1 then
		return re
	end

	cmd_ChangeItemCount(userID,pbObj.goodsID,-1,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_EUQIP,true)
	cmd_ChangeItemCount(userID,itemInfoConfig.equipId,1,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_EUQIP,true)

	re.code = 0
	return re
end

local function cmd_CheckItemAndComsume(userID,itemlist,fromWhere)
	return CheckItemAndComsume(userID,itemlist,fromWhere)
end

local function cmd_AddGoodsList(userID,itemlist,sui,fromWhere)
	ChangeItemCount(userID,itemlist,sui,fromWhere)
end

local function cmd_GetMinGoodsCount(userID,itemlist)
	local iMinCount = 0
	local List = {}
	List = _hash[userID]
	if not List then
		return 0
	end

	for k, v in pairs(itemlist) do 
		for kk, vv in pairs(List) do 
			if v.goodsID == vv.goodsID then

				if iMinCount == 0 then
					iMinCount = vv.goodsCount
				end

				if vv.goodsCount == 0 then
					iMinCount = 0
					return iMinCount
				end

				if vv.goodsCount < iMinCount then
					iMinCount = vv.goodsCount
				end
			end
		end
	end

	return iMinCount
end

local function cmd_SetUserItemList(userItem,itemList)
	local attr = ServerUserItem.getAttribute(userItem,{"userID"})
	if not attr then
		return
	end

	if not itemList then
		cmd_LoadUserItem(userItem)
	else
		_hash[attr.userID] = itemList
		for k, v in pairs(itemList) do
			if v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_FISH then
				skynet.error(string.format("--------------SetUserItemList-----1-----userid=%d-----礼券=%d-------------------------",attr.userID,v.goodsCount))
				ServerUserItem.setAttribute(userItem, {gift = v.goodsCount})
			elseif v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
				skynet.error(string.format("--------------SetUserItemList------2----userid=%d-----金币=%d-------------------------",attr.userID,v.goodsCount))
				ServerUserItem.setAttribute(userItem, {score = v.goodsCount})
			end
		end
	end
end

local function cmd_AddItemRecord(userID,goodsID,goodsCount,fromWhere)
	if goodsCount > 0 then
		AddItemRecord(userID,fromWhere,1,goodsID,math.abs(goodsCount))
	else
		AddItemRecord(userID,fromWhere,2,goodsID,math.abs(goodsCount))
	end
end

local function cmd_GetItemList(userID)
	return _hash[userID]
end

local function cmd_CompositingCDInfo(pbObj,userID)
	local re = {
		goodsID = pbObj.goodsID,
		isUseCD = 0,
		needGoodsItem = {},
		CDTime = CheckComposeCD(userID,pbObj.goodsID) ,
	}
	if re.CDTime ~= 0 then
		re.isUseCD = 1
	end

	local needItem = GetCleanComposeCDItem(userID,pbObj.goodsID)
	if needItem~=nil then
		table.insert(re.needGoodsItem,needItem)
	end
	return re
end


local conf = {
	methods = {
		["GoodsInfoList"] = {["func"]=cmd_GoodsInfoList, ["isRet"]=false},
		["GoodsInfo"] = {["func"]=cmd_GoodsInfo, ["isRet"]=false},
		["OffsetGoodsInfo"] = {["func"]=cmd_OffsetGoodsInfo, ["isRet"]=true},
		["UseGoodsInfo"] = {["func"]=cmd_UseGoodsInfo, ["isRet"]=true},
		["CompositingGoodsInfo"] = {["func"]=cmd_CompositingGoodsInfo, ["isRet"]=true},
		["GiveGoodsInfo"] = {["func"]=cmd_GiveGoodsInfo, ["isRet"]=true},
		["equipGoodsInfo"] = {["func"]=cmd_equipGoodsInfo, ["isRet"]=true},	

		["SaveUserItem"] = {["func"]=cmd_SaveUserItem, ["isRet"]=true},
		["LoadUserItem"] = {["func"]=cmd_LoadUserItem, ["isRet"]=true},
		["ReleaseUserItem"] = {["func"]=cmd_ReleaseUserItem, ["isRet"]=true},
		["GetItemCount"] = {["func"]=cmd_GetItemCount, ["isRet"]=true},
		["ChangeItemCount"] = {["func"]=cmd_ChangeItemCount, ["isRet"]=false},
		["CheckItemAndComsume"] = {["func"]=cmd_CheckItemAndComsume, ["isRet"]=true},
		["AddGoodsList"] = {["func"]=cmd_AddGoodsList, ["isRet"]=false},
		["GetMinGoodsCount"] = {["func"]=cmd_GetMinGoodsCount, ["isRet"]=true},	
		["SetUserItemList"] = {["func"]=cmd_SetUserItemList, ["isRet"]=false},
		["AddItemRecord"] = {["func"]=cmd_AddItemRecord, ["isRet"]=false},
		["GetItemList"] = {["func"]=cmd_GetItemList, ["isRet"]=true},
		["SaveItemRecord"] = {["func"]=cmd_SaveItemRecord, ["isRet"]=false},

		["CompositingCDInfo"] = {["func"]=cmd_CompositingCDInfo, ["isRet"]=true},	
	},
}

commonServiceHelper.createService(conf)

