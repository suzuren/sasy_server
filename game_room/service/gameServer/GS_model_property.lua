local skynet = require "skynet"
local ServerUserItem = require "sui"
local GS_CONST = require "define.gsConst"
local COMMON_CONST = require "define.commonConst"
local mysqlutil = require "utility.mysqlHandle"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local resourceResolver = require "resourceResolver"
local wordFilterUtility = require "wordfilter"

local _serverConfig
local _propertyConfigPbStr
local _propertyHash = {}

local function loadProperty()
	local list = {}
	local sql = 'SELECT `ID`, `Gold`, `Discount`, `SendLoveLiness`, `RecvLoveLiness` FROM `sstreasuredb`.`GameProperty` WHERE `Nullity`=0 AND (`IssueArea` & 6)<>0'
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "query", sql)
	
	for _, row in ipairs(rows) do
		for k, v in pairs(row) do
			row[k] = tonumber(v)
		end
		table.insert(list, {
			id = row.ID,
			discount = row.Discount,
			propertyGold = row.Gold,
			sendLoveLiness = row.SendLoveLiness,
			recvLoveLiness = row.RecvLoveLiness,
		})
		_propertyHash[row.ID] = row
	end
	
	local pbParser = resourceResolver.get("pbParser")
	_propertyConfigPbStr = skynet.call(pbParser, "lua", "encode", 0x010300, {list=list}, true)
end

local function getTrumpetScore(mysqlConn, userID, memberOrder, trumpetID)
	local trumpetScore = 0
	do
		local sql = string.format(
			"call sstreasuredb.sp_player_trumpet_score(%d, %d, %d)",
			userID,
			memberOrder,
			trumpetID
		)
		local rows = skynet.call(mysqlConn, "lua", "call", sql)
		if type(rows[1])=="table" then
			if tonumber(rows[1].retCode)==0 then
				trumpetScore = tonumber(rows[1].ConsumeGold)
			else
				skynet.error(string.format("%s.getTrumpetScore 错误：%s", SERVICE_NAME, rows[1].retMsg))
			end
		end
	end	
	
	return trumpetScore
end

local function sendTrumpetScore(dbConn, userItem)
	local userAttr = ServerUserItem.getAttribute(userItem, {"userID", "agent", "memberOrder"})

	local smallTrumpetScore = getTrumpetScore(dbConn, userAttr.userID, userAttr.memberOrder, GS_CONST.SMALL_TRUMPET_PROPERTY_ID)
	local bigTrumpetScore = getTrumpetScore(dbConn, userAttr.userID, userAttr.memberOrder, GS_CONST.BIG_TRUMPET_PROPERTY_ID)
	
	if userAttr.agent~=0 then
		skynet.send(userAttr.agent, "lua", "forward", 0x010303, {smallTrumpetScore=smallTrumpetScore, bigTrumpetScore=bigTrumpetScore})
	end
end


local function sendPropertyRepositoryUpdate(userItem, propertyID)
	local userAttr = ServerUserItem.getAttribute(userItem, {"agent"})

	local newCount = 0
	local propertyRepository = ServerUserItem.getAttribute(userItem, {"propertyRepository"}).propertyRepository
	for _, item in ipairs(propertyRepository) do
		if item.propertyID==propertyID then
			newCount = item.propertyCount
		end
	end
	
	skynet.send(userAttr.agent, "lua", "forward", 0x010306, {
		propertyID=propertyID,
		propertyCount=newCount
	})
end

local function consumeProperty(dbConn, userItem, targetUserID, propertyID, propertyCount)
	local propertyRepositoryItem
	local userAttr = ServerUserItem.getAttribute(userItem, {"userID", "propertyRepository"})
	local propertyRepository = userAttr.propertyRepository
	for _, item in ipairs(propertyRepository) do
		if item.propertyID==propertyID then
			propertyRepositoryItem = item
		end
	end
	
	if propertyRepositoryItem==nil then
		return false
	end
	
	if propertyRepositoryItem.propertyCount < propertyCount then
		return false
	end
	
	local sql = string.format(
		"call sstreasuredb.sp_player_use_property(%d, %d, %d, %d, %d)",
		_serverConfig.ServerID,
		userAttr.userID,
		targetUserID,
		propertyID,
		propertyCount
	)
	
	local rows = skynet.call(dbConn, "lua", "call", sql)
	if type(rows[1])=="table" then
		local retCode = tonumber(rows[1].retCode)
		if retCode~=0 then
			error(string.format("%s sp_player_use_property 错误：%d, %s", SERVICE_NAME, retCode, rows[1].retMsg))
		end
	end	
	
	ServerUserItem.addProperty(userItem, propertyID, -propertyCount)	
	
	sendPropertyRepositoryUpdate(userItem, propertyID)
	
	return true
end

local function prepareTrumpet(trumpetID, userItem, color, msg)
	local userAttr = ServerUserItem.getAttribute(userItem, {"userID", "agent", "nickName"})
	
	local mysqlConn = addressResolver.getMysqlConnection()
	if not consumeProperty(mysqlConn, userItem, userAttr.userID, trumpetID, 1) then
		skynet.send(userAttr.agent, "lua", "forward", 0x010307, {code="RC_PROPERTY_NOT_ENOUGH"})
		return		
	end
	
	local sql = string.format(
		"insert into `ssrecorddb`.`TrumpetLog`(`ServerID`, `UserID`, `TrumpetID`, `Color`, `Ctime`, `Msg`) values (%d, %d, %d, %d, now(), '%s')",
		_serverConfig.ServerID,
		userAttr.userID,
		trumpetID,
		color,
		mysqlutil.escapestring(msg)
	)
	skynet.send(mysqlConn, "lua", "execute", sql)	
	
	local swfObj = resourceResolver.get("sensitiveWordFilter")
	msg = wordFilterUtility.doFiltering(swfObj, msg)
	
	--skynet.send(userAttr.agent, "lua", "forward", 0x010307, {code="RC_OK"})
	
	return {
		trumpetID=trumpetID,
		sendUserID=userAttr.userID,
		sendNickName=userAttr.nickName,
		color=color,
		msg=msg,
	}
end

local function cmd_useProperty(userItem, propertyID, propertyCount, targetUserID)
	local userAttr = ServerUserItem.getAttribute(userItem, {"userID", "agent", "loveliness", "score", "memberOrder", "tableID"})
	
	
	local propertyItem = _propertyHash[propertyID]
	if not propertyItem then
		skynet.send(userAttr.agent, "lua", "forward", 0x010304, {code="RC_NO_PROPERTY_FOUND"})
		return
	end	
	
	if userAttr.loveliness < 0 and propertyItem.RecvLoveLiness < 0 then
		skynet.send(userAttr.agent, "lua", "forward", 0x010304, {code="RC_NEGATIVE_LOVELINESS_CANNOT_USE_HARMFULL_PROPERTY"})
		return
	end	
	
	local targetUserItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "getUserItem", targetUserID)
	if not targetUserItem then
		skynet.send(userAttr.agent, "lua", "forward", 0x010304, {code="RC_TARGET_USER_NOT_FOUND"})
		return
	end
	local targetUserAttr = ServerUserItem.getAttribute(userItem, {"userID", "agent"})	
	
	local mysqlConn = addressResolver.getMysqlConnection()
	if not consumeProperty(mysqlConn, userItem, targetUserID, propertyID, propertyCount) then
		skynet.send(userAttr.agent, "lua", "forward", 0x010304, {code="RC_PROPERTY_NOT_ENOUGH"})
		return		
	end
	
	if propertyItem.SendLoveLiness ~= 0 then
		ServerUserItem.writeUserScore(userItem, {
			loveliness = propertyItem.SendLoveLiness * propertyCount,
		}, GS_CONST.SCORE_TYPE.ST_SERVICE, 0)

		if userItem~=targetUserItem then
			skynet.call(addressResolver.getAddressByServiceName("GS_model_attemperEngine"), "lua", "writeVariation", userItem)
		end
	end
	
	if propertyItem.RecvLoveLiness ~= 0 then
		ServerUserItem.writeUserScore(targetUserItem, {
			loveliness = propertyItem.RecvLoveLiness * propertyCount,
		}, GS_CONST.SCORE_TYPE.ST_SERVICE, 0)

		skynet.call(addressResolver.getAddressByServiceName("GS_model_attemperEngine"), "lua", "writeVariation", targetUserItem)
	end
	
	local propertySuccess = {
		code="RC_OK",
		propertyID=propertyID,
		propertyCount=propertyCount,
		sourceUserID=userAttr.userID,
		targetUserID=targetUserID,
	}
	
	skynet.send(userAttr.agent, "lua", "forward", 0x010304, propertySuccess)
	if targetUserAttr.userID~=userAttr.userID and targetUserAttr.agent ~= 0 then
		skynet.send(targetUserAttr.agent, "lua", "forward", 0x010304, propertySuccess)
	end
	
	local tableAddress
	if userAttr.tableID~=GS_CONST.INVALID_TABLE then
		tableAddress = addressResolver.getTableAddress(userAttr.tableID)
	end
	
	if tableAddress then
		local pbParser = resourceResolver.get("pbParser")
		local packetStr = skynet.call(pbParser, "lua", "encode", 0x010305, {
			propertyID=propertyID,
			propertyCount=propertyCount,
			sourceUserID=userAttr.userID,
			targetUserID=targetUserID,
		}, true)
		skynet.send(tableAddress, "lua", "broadcastTable", packetStr)
		skynet.send(tableAddress, "lua", "broadcastLookon", packetStr)
	end
end

local function cmd_buyProperty(userItem, propertyID, propertyCount)
	local userAttr = ServerUserItem.getAttribute(userItem, {"userID", "agent", "loveliness", "score", "memberOrder", "tableID"})
	
	if (_serverConfig.ServerType & GS_CONST.GAME_GENRE.EDUCATE)~=0 or (_serverConfig.ServerType & GS_CONST.GAME_GENRE.MATCH)~=0 then
		skynet.send(userAttr.agent, "lua", "forward", 0x010302, {code="RC_SERVER_TYPE_CANNOT_BUY"})
		return
	end
	
	local propertyItem = _propertyHash[propertyID]
	if not propertyItem then
		skynet.send(userAttr.agent, "lua", "forward", 0x010302, {code="RC_NO_PROPERTY_FOUND"})
		return
	end
	
	local mysqlConn = addressResolver.getMysqlConnection()
	
	local unitPrice
	if propertyID==GS_CONST.SMALL_TRUMPET_PROPERTY_ID or propertyID==GS_CONST.BIG_TRUMPET_PROPERTY_ID then
		propertyCount = 1
		unitPrice = getTrumpetScore(mysqlConn, userAttr.userID, userAttr.memberOrder, propertyID)
	else
		if userAttr.memberOrder > 0 then
			unitPrice = math.ceil(propertyItem.Gold * propertyItem.Discount / 100)
		else
			unitPrice = propertyItem.Gold
		end
	end	
	local totalPrice = unitPrice * propertyCount
	
	local tableAddress
	if userAttr.tableID~=GS_CONST.INVALID_TABLE then
		tableAddress = addressResolver.getTableAddress(userAttr.tableID)
	end
	if tableAddress then
		skynet.call(tableAddress, "lua", "calcScoreAndLock", userItem)
		userAttr = ServerUserItem.getAttribute(userItem, {"userID", "agent", "loveliness", "score", "memberOrder", "tableID"})
	end
	
	if userAttr.score < totalPrice then
		skynet.send(userAttr.agent, "lua", "forward", 0x010302, {code="RC_NOT_ENOUGH_SCORE"})
		if tableAddress then
			skynet.call(tableAddress, "lua", "releaseScoreLock", userItem)
		end
		return
	end
	
	local sql = string.format(
		"call sstreasuredb.sp_player_buy_property(%d, %d, %d, %d, %d)",
		_serverConfig.ServerID,
		userAttr.userID,
		propertyID,
		propertyCount,
		totalPrice
	)
	local rows = skynet.call(mysqlConn, "lua", "call", sql)
	if type(rows[1])=="table" then
		local retCode = tonumber(rows[1].retCode)
		if retCode~=0 then
			error(string.format("%s sp_player_buy_property 错误：%d, %s", SERVICE_NAME, retCode, rows[1].retMsg))
		end
	end	
	
	ServerUserItem.addProperty(userItem, propertyID, propertyCount)
	ServerUserItem.writeUserScore(userItem, {
		score = -totalPrice,
	}, GS_CONST.SCORE_TYPE.ST_SERVICE, 0)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_attemperEngine"), "lua", "writeVariation", userItem)
	
	if tableAddress then
		skynet.call(tableAddress, "lua", "onUserScoreNotify", userItem)
		skynet.call(tableAddress, "lua", "releaseScoreLock", userItem)
	end
	
	sendPropertyRepositoryUpdate(userItem, propertyID)
	
	if propertyID==GS_CONST.SMALL_TRUMPET_PROPERTY_ID or propertyID==GS_CONST.BIG_TRUMPET_PROPERTY_ID then
		sendTrumpetScore(mysqlConn, userItem)
	end
	
	skynet.send(userAttr.agent, "lua", "forward", 0x010302, {
		code="RC_OK",
		propertyID=propertyID,
		propertyCount=propertyCount
	})
end

local function cmd_onEventLoginSuccess(data)
	local userAttr = ServerUserItem.getAttribute(data.sui, {"memberOrder"})
	
	if not data.isAndroid then
		skynet.send(data.agent, "lua", "forward", _propertyConfigPbStr)
		
		local mysqlConn = addressResolver.getMysqlConnection()
		
		sendTrumpetScore(mysqlConn, data.sui)
		
		local sql = string.format("SELECT `PropertyID` AS 'propertyID', `PropertyCount` AS 'propertyCount' FROM `sstreasuredb`.`UserPropertyVendor` WHERE UserID=%d", data.userID)
		local rows = skynet.call(mysqlConn, "lua", "query", sql)
		if type(rows)=="table" then
			local list = {}
			for _, row in ipairs(rows) do
				table.insert(list, {
					propertyID=tonumber(row.propertyID),
					propertyCount=tonumber(row.propertyCount),
				})
			end
			
			if #list > 0 then
				ServerUserItem.setAttribute(data.sui, {propertyRepository=list})
			end
			skynet.send(data.agent, "lua", "forward", 0x010301, {list=list})
		end
	end	
end

local function cmd_sendSmallTrumpet(userItem, color, msg)
	local trumpetMsg = prepareTrumpet(GS_CONST.SMALL_TRUMPET_PROPERTY_ID, userItem, color, msg)
	if trumpetMsg then
		local pbParser = resourceResolver.get("pbParser")
		local pbStr = skynet.call(pbParser, "lua", "encode", 0x010308, trumpetMsg, true)	
		skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "broadcast", pbStr)
	end
end

local function cmd_sendBigTrumpet(userItem, color, msg)
	local trumpetMsg = prepareTrumpet(GS_CONST.BIG_TRUMPET_PROPERTY_ID, userItem, color, msg)
	if trumpetMsg then
		skynet.send(
			addressResolver.getAddressByServiceName("GS_model_serverStatus"), "lua", "serverBroadCast",
			nil, nil, nil, COMMON_CONST.RELAY_MESSAGE_TYPE.RMT_BIG_TRUMPET, trumpetMsg
		)
	end
end

local conf = {
	methods = {
		["useProperty"] = {["func"]=cmd_useProperty, ["isRet"]=true},
		["buyProperty"] = {["func"]=cmd_buyProperty, ["isRet"]=true},
		["sendSmallTrumpet"] = {["func"]=cmd_sendSmallTrumpet, ["isRet"]=true},
		["sendBigTrumpet"] = {["func"]=cmd_sendBigTrumpet, ["isRet"]=true},
		
		["onEventLoginSuccess"] = {["func"]=cmd_onEventLoginSuccess, ["isRet"]=false},
	},
	initFunc = function()
		resourceResolver.init()
		
		loadProperty()
		
		_serverConfig = skynet.call(addressResolver.getAddressByServiceName("GS_model_serverStatus"), "lua", "getServerData")
		if not _serverConfig then
			error("server config not initialized")
		end		
		
		local GS_EVENT = require "define.eventGameServer"
		skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "addEventListener", GS_EVENT.EVT_GS_LOGIN_SUCCESS, skynet.self(), "onEventLoginSuccess")
	end,
}

commonServiceHelper.createService(conf)

