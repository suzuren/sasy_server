require "utility.string"
local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local COMMON_CONST = require "define.commonConst"
local ServerUserItem = require "sui"
local mysqlutil = require "utility.mysqlHandle"

local _logonMessageList
local _exchangeMessageList

local function reloadExchangeMessage()
	local sql = "SELECT `MessageString` FROM `ssplatformdb`.`SystemMessage` WHERE `Type` & 0x01 = 0x01 ORDER BY ID DESC LIMIT 20"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "query", sql)
	local list = {}	
	if type(rows)=="table" then
		for _, row in ipairs(rows) do
			table.insert(list, row.MessageString)
		end
	end
	_exchangeMessageList = list
end

local function reloadLogonMessage()
	local sql = "SELECT `ID`, `Type`, `ServerRange`, `MessageTitle`,`MessageString`, UNIX_TIMESTAMP(`StartTime`) as \"StartTime\" FROM `ssaccountsdb`.`LogonSystemMessage` WHERE `Type`<>0 AND `StartTime`<NOW() AND NOW()<`EndTime` ORDER BY ID DESC LIMIT 10"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "query", sql)
	local list = {}
	if type(rows)=="table" then
		for _, row in ipairs(rows) do
			local item = {
				id = tonumber(row.ID),
				type = tonumber(row.Type),
				title=row.MessageTitle,
				msg = row.MessageString,
				startTime = tonumber(row.StartTime),
				sendAllServer = false,
				serverIDHash = {}
			}
			
			local tokens = row.ServerRange:split(",")
			for _, v in ipairs(tokens) do
				local serverID = tonumber(v)
				if serverID then
					if serverID==0 then
						item.sendAllServer = true
						break
					else
						item.serverIDHash[serverID] = true
					end
				end
			end
			table.insert(list, item)
		end
	end
	_logonMessageList = list
end

local function sendSystemLogonMessage(agent, kindIDList)
	local logonMessage = {list={}}
	for k, kindID in ipairs(kindIDList) do
		local serverList = skynet.call(addressResolver.getAddressByServiceName("LS_model_serverManager"), "lua", "getServerIDListByKindID", kindID)
		if not serverList then
			goto continue
		end
		for _, item in ipairs(_logonMessageList) do
			for k, v in pairs(logonMessage.list) do 
				if v.id == item.id then
					goto continue
				end
			end

			if item.sendAllServer then
				local pbItem = {
					id = item.id,
					type = item.type,
					startTime = item.startTime,
					title=item.title,
					msg = item.msg,
					kindID = kindID
				}
				table.insert(logonMessage.list, pbItem)
			else
				for _, serverID in ipairs(serverList) do
					if item.serverIDHash[serverID] then
						local pbItem = {
							id = item.id,
							type = item.type,
							startTime = item.startTime,
							title=item.title,
							msg = item.msg,
							kindID = kindID
						}
						table.insert(logonMessage.list, pbItem)
						break
					end
				end
			end
		end

		::continue::
	end
	
	if #(logonMessage.list) > 0 then
		skynet.send(agent, "lua", "forward", 0x000300, logonMessage)	
	end
end

local function sendUserLogonMessage(agent, userID)
	local sendList = {}
	local sql = string.format("SELECT `ID`,`MessageTitle`,`MessageString`, UNIX_TIMESTAMP(`StartTime`) as \"StartTime\",`GoodsInfo` FROM `ssaccountsdb`.`LogonUsersMessage` WHERE `UserID`=%d AND `StartTime`<NOW() ORDER BY `ID` ASC",userID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if type(rows)=="table" then
		for _, row in ipairs(rows) do
			local itemInfo = {
				id = tonumber(row.ID),
				startTime = tonumber(row.StartTime),
				title=row.MessageTitle,
				msg = row.MessageString,
				goodslist = {}
			}

			local list = row.GoodsInfo:split("|")
			for _, item in pairs(list) do
				local itemPart = item:split(":")
				local goods = {
					goodsID = itemPart[1],
					goodsCount = itemPart[2]
				}
				table.insert(itemInfo.goodslist,goods)
			end

			table.insert(sendList,itemInfo)
		end
	end

	--if #(sendList) > 0 then
	 	skynet.send(agent, "lua", "forward", 0x000301, {list=sendList})
	--end
end

local function cmd_onEventLoginSuccess(data)
	sendSystemLogonMessage(data.agent, data.kindID)
	sendUserLogonMessage(data.agent, data.userID)
end

local function cmd_sendExchangeMessage(agent)
	skynet.send(agent, "lua", "forward", 0x000302, {msg=_exchangeMessageList})
end

local function cmd_RecvGoods(tcpAgent, pbObj, tcpAgentData)
	local sendList = {
		id = pbObj.id,
		goodslist = {},
		code = 0,
	}

	local sql = string.format("SELECT * FROM `ssaccountsdb`.`LogonUsersMessage` where UserId=%d and ID=%d",tcpAgentData.userID,pbObj.id)
	local mysqlConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(mysqlConn,"lua","query",sql)
	if rows[1] == nil then
		sendList.code = 1
		return sendList
	end

	sql = string.format("DELETE FROM `ssaccountsdb`.`LogonUsersMessage` where UserId=%d and ID=%d",tcpAgentData.userID,pbObj.id)
	skynet.call(mysqlConn, "lua", "query", sql)

	local fromWhere = COMMON_CONST.ITEM_SYSTEM_TYPE.EMAIL_REWARD
	local fromId = tonumber(rows[1].FromId)
	if fromId ~= 0 then
		if fromId == 1 then
			fromWhere = COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG_REWARD
		else
			fromWhere = COMMON_CONST.ITEM_SYSTEM_TYPE.EMAIL_REWARD_USER
		end
	end

	local list = rows[1].GoodsInfo:split("|")
	for _, item in pairs(list) do
		local itemPart = item:split(":")
		local goods = {
			goodsID = tonumber(itemPart[1]),
			goodsCount = tonumber(itemPart[2])
		}
		table.insert(sendList.goodslist,goods)
	end

	--给玩家添加物品
	for itemId, goods in pairs(sendList.goodslist) do
		if goods.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
			ServerUserItem.addAttribute(tcpAgentData.sui, {score = goods.goodsCount})
			sql = string.format("update `sstreasuredb`.`GameScoreInfo` set Score=Score+%d where UserID = %d", goods.goodsCount, tcpAgentData.userID)
			skynet.call(mysqlConn, "lua", "query", sql)
		elseif goods.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_FISH then
			ServerUserItem.addAttribute(tcpAgentData.sui, {gift = goods.goodsCount})
			sql = string.format("update `ssaccountsdb`.`AccountsInfo` set Gift=Gift+%d where UserID = %d", goods.goodsCount, tcpAgentData.userID)		
			skynet.call(mysqlConn, "lua", "query", sql)
		end

		--背包
		skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",tcpAgentData.userID,
			goods.goodsID,goods.goodsCount,fromWhere)
	end

	sql = string.format("insert into `ssrecorddb`.`message_record` (`UserId`,`EmailID`,`GoodsInfo`,`ReceiveTime`) values(%d,%d,'%s','%s')",
		tcpAgentData.userID,pbObj.id,mysqlutil.escapestring(rows[1].GoodsInfo),os.date('%Y-%m-%d %H:%M:%S', math.floor(skynet.time())))
	skynet.call(mysqlConn, "lua", "query", sql)

	sendUserLogonMessage(tcpAgent,tcpAgentData.userID)

	sendList.code = 0
	return sendList
end

local function cmd_notifyUserEmailChange(sui,emailType)
	local attr = ServerUserItem.getAttribute(sui,{"userID","agent","kindID"})
	if attr.agent ~= 0 then
		if not emailType then
			sendUserLogonMessage(attr.agent, attr.userID)
		else
			local kindList = {}
			table.insert(kindList,2010)
			sendSystemLogonMessage(attr.agent, kindList)
		end
	end
end	

local function cmd_reloadLogonMessage()
	reloadLogonMessage()
end

local function cmd_sendEmailToUser(userID,itemlist,messageTitle,messageInfo,fromUserId)
	local goodsInfo = ""
	for k, v in pairs(itemlist) do
		goodsInfo = goodsInfo..tostring(v.goodsID)..":"..tostring(v.goodsCount).."|" 
	end

	local fromId = 0--0系统，1活动，>1玩家
	if fromUserId ~= nil then
		fromId = fromUserId
	end

	local startTime = os.date('%Y-%m-%d %H:%M:%S', math.floor(skynet.time()))
	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("insert into `ssaccountsdb`.`LogonUsersMessage`(UserID,MessageTitle,MessageString,StartTime,GoodsInfo,FromId) values(%d,'%s','%s','%s','%s',%d)",
		userID,mysqlutil.escapestring(messageTitle),mysqlutil.escapestring(messageInfo),mysqlutil.escapestring(startTime),mysqlutil.escapestring(goodsInfo),fromId)
	local emailId = skynet.call(dbConn, "lua", "insert", sql)

	local userItem = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getUserItemByUserID", userID)
	if userItem then
		--cmd_notifyUserEmailChange(userItem)
		local attr = ServerUserItem.getAttribute(userItem, {"agent"})
		if attr.agent ~= 0 then
			local sendList = {}
			local itemInfo = {
				id = emailId,
				startTime = os.time(),
				title=messageTitle,
				msg = messageInfo,
				goodslist = itemlist,
			}

			table.insert(sendList,itemInfo)

		 	skynet.send(attr.agent, "lua", "forward", 0x000304, {list=sendList})
		 end
	end
end

local conf = {
	methods = {
		["onEventLoginSuccess"] = {["func"]=cmd_onEventLoginSuccess, ["isRet"]=false},
		["sendExchangeMessage"] = {["func"]=cmd_sendExchangeMessage, ["isRet"]=false},
		["RecvGoods"] = {["func"]=cmd_RecvGoods, ["isRet"]=true},
		["notifyUserEmailChange"] = {["func"]=cmd_notifyUserEmailChange, ["isRet"]=false},
		["reloadLogonMessage"] = {["func"]=cmd_reloadLogonMessage, ["isRet"]=true},
		["sendEmailToUser"] = {["func"]=cmd_sendEmailToUser, ["isRet"]=false},
	},

	initFunc = function()
		local eventList = require "define.eventLoginServer"
		skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "addEventListener", eventList.EVT_LS_LOGIN_SUCCESS, skynet.self(), "onEventLoginSuccess")
		
		reloadExchangeMessage()
		reloadLogonMessage()

		--[[
		skynet.fork(function()
			while true do
				reloadExchangeMessage()
				reloadLogonMessage()
				skynet.sleep(60000)
			end
		end)
		--]]
	end,
}

commonServiceHelper.createService(conf)