local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local ServerUserItem = require "sui"
local COMMON_CONST = require "define.commonConst"
local randHandle = require "utility.randNumber"
local LS_CONST = require "define.lsConst"
local sysConfig = require "sysConfig"

local _hash = {
	--bagItemList = {},	--用户背包物品
}

local function AddItemRecord(userID,fromId,addOrDel,goodsID,goodsCount)
	local insertTime = os.date("%Y-%m-%d %H:%M:%S", os.time())
	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("INSERT INTO `ssrecorddb`.`t_item_record` (`UserId`, `FromId`, `AddOrDel`, `ItemId`, `ItemCount`, `Date`, `InGame`) VALUES(%d,%d,%d,%d,%d,'%s',0)",
			userID,fromId,addOrDel,goodsID,goodsCount,insertTime)
	skynet.send(dbConn, "lua", "execute", sql)
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
		useType  = 0,
		oldGoodsCount = goodsCount,
	}

	local linkId = 0
	local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
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

	table.insert(_hash[userID],item)

	local sql = string.format("insert into `ssfishdb`.`t_bag` values(%d,%d,%d,%d)",userID,item.goodsID,item.goodsCount,endTime)
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
		-- 		local sql = string.format("SELECT EndTime FROM `ssfishdb`.`t_bag` where UserId=%d and ItemId=%d",tcpAgentData.userID,v.goodsID)
		-- 		local rows = skynet.call(dbConn,"lua","query",sql)
		-- 		if rows[1] ~= nil then
		-- 			local endTime = tonumber(rows[1].EndTime)
		-- 			if endTime ~= 0 then
		-- 				local nowTime = os.time()
		-- 				if endTime <= nowTime then
		-- 					v.useTime = 0
		-- 					v.goodsCount = 0
		-- 					v.oldGoodsCount = 0
		-- 					sql = string.format("update `ssfishdb`.`t_bag` set ItemCount = %d,EndTime=%d where UserId=%d and ItemId=%d",
		-- 						v.goodsCount,0,tcpAgentData.userID,v.goodsID)
		-- 					skynet.send(dbConn, "lua", "execute", sql)
		-- 				else
		-- 					v.useTime = endTime - nowTime
		-- 				end
		-- 			end
		-- 		end 
		-- 	end
		-- end	

		skynet.send(tcpAgent,"lua","forward",0x003000,sendGoods)
	end
end

local function cmd_GoodsInfo(userID,goodsId)
	local userItem = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"),"lua","getUserItemByUserID",userID)
	local attr = ServerUserItem.getAttribute(userItem, {"agent"})
	if attr.agent == 0 then
		return
	end
	local goodsList = {}
	goodsList = _hash[userID]
	if not goodsList then
		return
	end

	for _, v in pairs(goodsList) do
		if v.goodsID == goodsId then
			if COMMON_CONST.CheckIsPaoTaiItem(goodsId) or COMMON_CONST.CheckIsTimeCardItem(goodsId)	then
				-- local dbConn = addressResolver.getMysqlConnection()
				-- local sql = string.format("SELECT EndTime FROM `ssfishdb`.`t_bag` where UserId=%d and ItemId=%d",userID,goodsId)
				-- local rows = skynet.call(dbConn,"lua","query",sql)
				-- if rows[1] ~= nil then
				-- 	local endTime = tonumber(rows[1].EndTime)
				-- 	if endTime ~= 0 then
				-- 		local nowTime = os.time()
				-- 		if endTime <= nowTime then
				-- 			v.useTime = 0
				-- 			v.goodsCount = 0
				-- 			v.oldGoodsCount = 0
				-- 			sql = string.format("update `ssfishdb`.`t_bag` set ItemCount = %d,EndTime=%d where UserId=%d and ItemId=%d",
				-- 				v.goodsCount,0,userID,goodsId)
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
						local sql = string.format("update `ssfishdb`.`t_bag` set ItemCount = %d,EndTime=%d where UserId=%d and ItemId=%d",
							v.goodsCount,0,userID,goodsId)
						local dbConn = addressResolver.getMysqlConnection()
						skynet.send(dbConn, "lua", "execute", sql)
					else
						v.useTime = v.endTime - nowTime
					end
				end
			end
			skynet.send(attr.agent,"lua","forward",0x003001,v)
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

	if sysConfig.isTest then	
		for _, v in pairs(goods.offsetGoodsItem) do 
			skynet.send(addressResolver.getAddressByServiceName("LS_model_pay"),"lua","testPay",tcpAgentData.sui,v.goodsID)
			return goods
		end
	end

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
		local dbConn = addressResolver.getMysqlConnection()
		--local sql = string.format("update `ssfishdb`.`t_bag` set ItemCount = ItemCount - %d where UserId = %d and ItemId = %d",itemCount,tcpAgentData.userID,v.goodsID)
		--skynet.send(dbConn, "lua", "execute", sql)

		local sql = string.format("call `ssfishdb`.`sp_write_bag` (%d,%d,%d)",tcpAgentData.userID,v.goodsID,-itemCount)
		local ret = skynet.call(dbConn, "lua", "call", sql)[1]
		if tonumber(ret.retCode) ~= 0 then		
			skynet.error(string.format("--1111--大厅写背包数据出错了--userID=%d,goodsID=%d,goodsCount=%d--code=%d,mes=%s----",tcpAgentData.userID,v.goodsID,-itemCount,tonumber(ret.retCode),tostring(ret.retMsg)))
		end

		skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",tcpAgentData.userID,
			v.goodsID,-itemCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_USE)
	end

	return goods
end

local function cmd_LoadUserItem(userItem)
	local itemList = {}
	local attr = ServerUserItem.getAttribute(userItem, {"userID","score","gift"})
	local sql = string.format("SELECT * FROM `ssfishdb`.`t_bag` where UserId = %d", attr.userID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	local bFindFish = false
	local bFindGold = false
	local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
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
				useType  = 0,
				oldGoodsCount = tonumber(row.ItemCount),
				endTime = tonumber(row.EndTime),
			}

			if item.useTime ~= 0 then
				if item.useTime <= os.time() or item.goodsCount == 0 then
					item.useTime = 0
					item.goodsCount = 0
					item.oldGoodsCount = 0
					item.endTime = 0
					sql = string.format("update `ssfishdb`.`t_bag` set ItemCount = %d,EndTime=%d where UserId=%d and ItemId=%d",
						item.goodsCount,item.useTime,attr.userID,item.goodsID)
					skynet.send(dbConn, "lua", "execute", sql)
				else
					item.useTime = item.useTime - os.time()
				end
			end



			if COMMON_CONST.CheckIsSpecCannonItem(item.goodsID) then
				if item.goodsCount > 0 then
					item.goodsCount = 1
					item.oldGoodsCount = 1
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

	local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
	local itemInfoConfig = skynet.call(configAddress,"lua","GetItemInfoHash")


	local bFind = false
	for k, v in pairs(itemInfoConfig) do 
		bFind = false
		for kk, vv in pairs(itemList) do 
			if v.itemId == vv.goodsID then
				bFind = true
				break
			end
		end

		if not bFind then
			AddItemToBag(attr.userID,v.itemId,0)
		end
	end
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

local function cmd_ChangeItemCount(userID,goodsID,goodsCount,fromWhere,bInGame)
	local bAddRecord = true
	local bNeedNotify = true
	local userItem = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getUserItemByUserID", userID)
	if userItem then
		local attr = ServerUserItem.getAttribute(userItem, {"serverID","userStatus"})
		if attr.serverID ~= 0 then
			if attr.userStatus == LS_CONST.USER_STATUS.US_LS_GS then
				bNeedNotify = false
				--return --如果是在游戏里，大厅的背包就不要加道具
			end

			-- if attr.userStatus == LS_CONST.USER_STATUS.US_LS_GS_OFFLINE then
			-- 	--充值，救济金，改名字已经处理过了
			-- 	if fromWhere ~= COMMON_CONST.ITEM_SYSTEM_TYPE.PAY_ADD and fromWhere ~= COMMON_CONST.ITEM_SYSTEM_TYPE.RESCUE_COIN
			-- 	 	and fromWhere ~= COMMON_CONST.ITEM_SYSTEM_TYPE.USE_CHANGE_NAME then

			-- 		skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", {attr.serverID}, 
			-- 			COMMON_CONST.LSNOTIFY_EVENT.EVT_LSNOTIFY_GS_CHANGE_USER_ITEM, 
			-- 			{
			-- 				userID = userID,
			-- 				goodsID = goodsID,
			-- 				goodsCount = goodsCount,
			-- 			})
			-- 	else	
			-- 		bAddRecord = false
			-- 	end
			-- end

			--充值，救济金，改名字已经处理过了
			if fromWhere ~= COMMON_CONST.ITEM_SYSTEM_TYPE.PAY_ADD and fromWhere ~= COMMON_CONST.ITEM_SYSTEM_TYPE.RESCUE_COIN
			  and fromWhere ~= COMMON_CONST.ITEM_SYSTEM_TYPE.USE_CHANGE_NAME then
				skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", {attr.serverID}, 
					COMMON_CONST.LSNOTIFY_EVENT.EVT_LSNOTIFY_GS_CHANGE_USER_ITEM, 
					{
						userID = userID,
						goodsID = goodsID,
						goodsCount = goodsCount,
					})
			end
		end
	end

	local bFind = false
	local itemList = {}
	itemList = _hash[userID]
	if not itemList then
		return
	end

	for _, v in pairs(itemList) do 
		if goodsID == v.goodsID then
			--炮台在背包中最多只有一个，改变的只是时间,炮台这个接口过来只会加不会减，因为倒计时客户端做了

			v.goodsCount = v.goodsCount + goodsCount
			v.oldGoodsCount = v.oldGoodsCount + goodsCount
		
			if COMMON_CONST.CheckIsPaoTaiItem(goodsID) or COMMON_CONST.CheckIsSpecCannonItem(goodsID) then
				if goodsCount > 0 then
					v.goodsCount = 1
					v.oldGoodsCount = 1
				else
					v.goodsCount = 0
					v.oldGoodsCount = 0
					v.useTime = 0
				end
			end

			if v.goodsCount < 0 then
				skynet.error(string.format("---fromWhere=%s----玩家的背包道具变成负数了,userID=%s,itemId=%s,changeCount=%s,itemCount=%s",fromWhere,userID,goodsID,goodsCount,v.goodsCount))
				v.goodsCount = 0
				v.oldGoodsCount = 0
			end

			-- local sql = string.format("update `ssfishdb`.`t_bag` set ItemCount = %d where UserId=%d and ItemId=%d",
			-- 	v.goodsCount,userID,goodsID)
			local sql = string.format("call `ssfishdb`.`sp_write_bag` (%d,%d,%d)",userID,goodsID,goodsCount)
			local dbConn = addressResolver.getMysqlConnection()
			local ret = skynet.call(dbConn,"lua","call",sql)[1]
			if tonumber(ret.retCode) ~= 0 then		
				skynet.error(string.format("----大厅写背包数据出错了--userID=%d,goodsID=%d,goodsCount=%d,fromWhere=%d---code=%d,mes=%s----",userID,goodsID,goodsCount,fromWhere,tonumber(ret.retCode),tostring(ret.retMsg)))
				return
			end

			bFind = true

			if COMMON_CONST.CheckIsPaoTaiItem(goodsID) or COMMON_CONST.CheckIsTimeCardItem(goodsID) or COMMON_CONST.CheckIsSpecCannonItem(goodsID) then
				-- sql = string.format("SELECT EndTime FROM `ssfishdb`.`t_bag` where UserId=%d and ItemId=%d",userID,goodsID)
				-- local rows = skynet.call(dbConn,"lua","query",sql)
				-- if rows[1] ~= nil then
					--local endTime = tonumber(rows[1].EndTime)
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
						sql = string.format("update `ssfishdb`.`t_bag` set EndTime = %d where UserId=%d and ItemId=%d",
							v.endTime,userID,goodsID)
						skynet.call(dbConn,"lua","query",sql)
					end
				--end
			end

			break
		end
	end

	if bFind == false then
		AddItemToBag(userID,goodsID,goodsCount)
	end

	if bNeedNotify then
		cmd_GoodsInfo(userID,goodsID)
	end

	if bAddRecord then
		if goodsCount > 0 then
			AddItemRecord(userID,fromWhere,1,goodsID,math.abs(goodsCount))
		else
			AddItemRecord(userID,fromWhere,2,goodsID,math.abs(goodsCount))
		end	
	end
end

local function UpdateUserRecordGold(userID,addGold)
	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("INSERT INTO `ssrecorddb`.`t_record_gold_by_use_box` (UserId,SumGold) VALUES(%d,%d) ON DUPLICATE KEY UPDATE SumGold=SumGold+%d",userID,addGold,addGold)
	skynet.send(dbConn, "lua", "execute", sql)
end	

local function ChangeItemCount(userID,itemlist,fromWhere)
	for _, v in pairs(itemlist) do 
		if v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
			UpdateUserRecordGold(userID,v.goodsCount)
		end
		cmd_ChangeItemCount(userID,v.goodsID,v.goodsCount,fromWhere)
	end
end

local function cmd_UseGoodsInfo(userID,goodsID,getGoodsID)
	local re = {
		useGoodsItem = {},
		code = 1,
	}

	local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
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
		local randRate = randHandle.random(1,100)
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

	cmd_ChangeItemCount(userID,goodsID,-1,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_USE)

	ChangeItemCount(userID,itemlist,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_USE)

	re.useGoodsItem = itemlist
	re.code = 0
	return re
end

--清除合成cd所需要添加的道具消耗  暂时只有钻石
local function GetCleanComposeCDItem( userID , ComposeItemID )
	local CDtimes = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "GetLimitComposeCD",userID,ComposeItemID)
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
		local limitCount = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"),"lua","GetLimitCount",userID,limitID)
		if limitCount - os.time() >0 then 
			return  limitCount - os.time()
		else
			return 0
		end
	end
	
	return 0 
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
		local beforeTime = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"),"lua","GetLimitCount",userID,limitid)

		skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua","AddLimit",userID,limitid,limit_count-beforeTime)

		skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "SetLimitComposeCD",userID,ComposeItemID)
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
				cmd_ChangeItemCount(userID,v.goodsID,-v.goodsCount,fromWhere)
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

	local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
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


	cmd_ChangeItemCount(tcpAgentData.userID,goodsId,composeConfig.itemCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_COMPOSE)

	local goods = {
		goodsID = goodsId,
		goodsCount = composeConfig.itemCount
	}
	table.insert(re.getCompositingGoodsItem,goods)

	if COMMON_CONST.ITEM_ID.ITEM_ID_SILVE_BOX <= goodsId and goodsId <= COMMON_CONST.ITEM_ID.ITEM_ID_PT_BOX then
		local userAttr = ServerUserItem.getAttribute(tcpAgentData.sui, {"tableID","nickName"})
		local nickName = COMMON_CONST.HideNickName(userAttr.nickName)
		local msg=string.format("恭喜玩家%s合成了一个%s",nickName,itemInfoConfig.itemName)
		skynet.send(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "sendSystemMessage",msg)
	end

	--如果是有合成CD的 添加CD
	CheckAndAddComposeCD(tcpAgentData.userID,goodsId)

	re.code = 0
	return re
end

local function addGiveItemRecord(userID,giveUserId,itemId,itemCount)
	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("INSERT INTO `ssrecorddb`.`t_record_give_item` (`UserId`,`GiveUserId`,`ItemId`,`ItemCount`,`Date`) VALUES(%d,%d,%d,%d,now())",userID,giveUserId,itemId,itemCount)
	skynet.send(dbConn, "lua", "execute", sql)
end	

local function cmd_GiveGoodsInfo(tcpAgent,pbObj,userID,sui)
	local re = { 
		code = 1
	}

	if pbObj.UserID == userID then
		re.code = 4
		return re
	end

	local attr = ServerUserItem.getAttribute(sui,{"memberOrder","nickName"})
	if attr.memberOrder < 2 then
		re.code = 2
		return re
	end

	local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
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

	local sql2 = string.format("SELECT `NickName` FROM `ssaccountsdb`.`AccountsInfo` where UserId = %d ",pbObj.UserID )
	local dbConn = addressResolver.getMysqlConnection()
	local rows2 = skynet.call(dbConn,"lua","query",sql2)
	if rows2[1] == nil then
		re.code = 3
		return re
	end



	cmd_ChangeItemCount(userID,pbObj.goodsID,-pbObj.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_GIVE)
	local itemList = {}
	local item = {
		goodsID = pbObj.goodsID,
		goodsCount = pbObj.goodsCount
	}
	table.insert(itemList,item)
	local messageTitle = string.format("来自好友赠送")
	local messageInfo = string.format("来自 %s 赠送",attr.nickName)
	skynet.send(addressResolver.getAddressByServiceName("LS_model_message"),"lua","sendEmailToUser",pbObj.UserID,itemList,messageTitle,messageInfo,userID)

	addGiveItemRecord(userID,pbObj.UserID,item.goodsID,item.goodsCount)

	--推送新的赠送历史记录
	-- cmd_GivenHistory(tcpAgent,pbObj,userID)
	skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "GivenHistory",tcpAgent,pbObj,userID)

	re.code = 0
	return re
end

local function cmd_equipGoodsInfo(pbObj,userID)
	local re = { 
		code = 1
	}

	local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
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

	cmd_ChangeItemCount(userID,pbObj.goodsID,-1,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_EUQIP)
	cmd_ChangeItemCount(userID,itemInfoConfig.equipId,1,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_EUQIP)

	re.code = 0
	return re
end

local function cmd_ShopGoodsInfo(pbObj,userID)
	local re = { 
		code = 1
	}

	if pbObj.useShopGoodsID ~= COMMON_CONST.ITEM_ID.ITEM_ID_JEWEL then
		re.code = 2
		return re
	end 

	if pbObj.shopGoodsID ~= COMMON_CONST.ITEM_ID.ITEM_ID_LOCK and pbObj.shopGoodsID ~= COMMON_CONST.ITEM_ID.ITEM_ID_FAST 
		and pbObj.shopGoodsID ~= COMMON_CONST.ITEM_ID.ITEM_ID_NEW_FAST and pbObj.shopGoodsID ~= COMMON_CONST.ITEM_ID.ITEM_ID_SHEN_DEGN then
		re.code = 3
		return re
	end

	local multiple = 2000
	if pbObj.shopGoodsID == COMMON_CONST.ITEM_ID.ITEM_ID_LOCK or pbObj.shopGoodsID == COMMON_CONST.ITEM_ID.ITEM_ID_FAST 
		or pbObj.shopGoodsID == COMMON_CONST.ITEM_ID.ITEM_ID_NEW_FAST then
		multiple = 5
	end

	if pbObj.shopGoodsCount <= 0 then
		re.code = 4
		return re
	end

	if cmd_GetItemCount(userID,pbObj.useShopGoodsID) < multiple*pbObj.shopGoodsCount then
		return re 
	end

	cmd_ChangeItemCount(userID,pbObj.useShopGoodsID,-multiple*pbObj.shopGoodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BUG_GOODS)
	cmd_ChangeItemCount(userID,pbObj.shopGoodsID,pbObj.shopGoodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BUG_GOODS)

	re.code = 0
	return re
end	

local function cmd_CheckItemAndComsume(userID,itemlist,fromWhere)
	return CheckItemAndComsume(userID,itemlist,fromWhere)
end

local function cmd_AddGoodsList(userID,itemlist,sui,fromWhere)
	for _, v in pairs(itemlist) do 
		cmd_ChangeItemCount(userID,v.goodsID,v.goodsCount,fromWhere)
	end
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

local function cmd_GetItemList(userID)
	return _hash[userID]
end

local function cmd_SetUserItemList(userItem,itemList,bLogOut)
	local attr = ServerUserItem.getAttribute(userItem,{"userID"})
	if not attr then
		return
	end

	if bLogOut then
		if next(itemList) ~= nil then
			_hash[attr.userID] = itemList
			 for k, v in pairs(itemList) do
				if v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_FISH then
					ServerUserItem.setAttribute(userItem, {gift = v.goodsCount})
				elseif v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
					ServerUserItem.setAttribute(userItem, {score = v.goodsCount})
				end
			end
		end
	else
		if next(itemList) == nil then
			cmd_LoadUserItem(userItem)
		else
			_hash[attr.userID] = itemList
			 for k, v in pairs(itemList) do
				if v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_FISH then
					ServerUserItem.setAttribute(userItem, {gift = v.goodsCount})
				elseif v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
					ServerUserItem.setAttribute(userItem, {score = v.goodsCount})
				end
			end
		end
	end
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
		-- re.needGoodsItem=needItem
	end


	return re
end



local function cmd_GivenHistory(tcpAgent,pbObj,userID)
	local sendHistory = {
		givenItemHistory = {},
	}

	local sql = string.format("SELECT ItemId, GiveUserId, UNIX_TIMESTAMP(Date) as Date FROM `ssrecorddb`.`t_record_give_item` where UserId = %d and Date > FROM_UNIXTIME(%d)", userID,os.time()-24*60*60*2)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	for _, row in ipairs(rows) do
		local item = {
			goodsID=row.ItemId;
			givenUserID=row.GiveUserId;						--被赠送的ID
			givenUserIcon=0;								--用户icon
			givenUserFace=nil;								--自定义头像
			givenUserVip=0;									--用户VIP
			givenUserNickname=nil;							--发送用户名称
			givenTime = tonumber(row.Date);			--发送时间
		}
	

		local sql2 = string.format("SELECT `NickName`,`FaceID`,`MemberOrder` FROM `ssaccountsdb`.`AccountsInfo` where UserId = %d ",row.GiveUserId )
		local dbConn = addressResolver.getMysqlConnection()
		local rows2 = skynet.call(dbConn,"lua","query",sql2)
		if rows2[1] ~= nil then
			item.givenUserIcon = rows2[1].FaceID
			item.givenUserVip = rows2[1].MemberOrder
			item.givenUserNickname = rows2[1].NickName
		end

		local sql3 = string.format("SELECT `PlatformFace` FROM `ssaccountsdb`.`accountsface` where UserId = %d ",row.GiveUserId )
		local dbConn = addressResolver.getMysqlConnection()
		local rows3 = skynet.call(dbConn,"lua","query",sql3)

		if rows3[1] ~= nil then
			item.givenUserFace = rows3[1].PlatformFace
		end

		table.insert(sendHistory.givenItemHistory,item)
	end
	skynet.send(tcpAgent,"lua","forward",0x003009,sendHistory)
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
		["ShopGoodsInfo"] = {["func"]=cmd_ShopGoodsInfo, ["isRet"]=true},


		["LoadUserItem"] = {["func"]=cmd_LoadUserItem, ["isRet"]=true},
		["ReleaseUserItem"] = {["func"]=cmd_ReleaseUserItem, ["isRet"]=false},
		["GetItemCount"] = {["func"]=cmd_GetItemCount, ["isRet"]=true},
		["ChangeItemCount"] = {["func"]=cmd_ChangeItemCount, ["isRet"]=false},	
		["CheckItemAndComsume"] = {["func"]=cmd_CheckItemAndComsume, ["isRet"]=true},
		["AddGoodsList"] = {["func"]=cmd_AddGoodsList, ["isRet"]=false},
		["GetMinGoodsCount"] = {["func"]=cmd_GetMinGoodsCount, ["isRet"]=true},
		["GetItemList"] = {["func"]=cmd_GetItemList, ["isRet"]=true},
		["SetUserItemList"] = {["func"]=cmd_SetUserItemList, ["isRet"]=false},	

		["CompositingCDInfo"] = {["func"]=cmd_CompositingCDInfo, ["isRet"]=true},	

		["GivenHistory"] = {["func"]=cmd_GivenHistory, ["isRet"]=false},	
	},
}

commonServiceHelper.createService(conf)

