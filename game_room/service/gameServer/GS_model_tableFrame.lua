local skynet = require "skynet"
local cluster = require "cluster"
local arc4 = require "arc4random"
local commonServiceHelper = require "serviceHelper.common"
local GS_CONST = require "define.gsConst"
local COMMON_CONST = require "define.commonConst"
local ServerUserItem = require "sui"
local addressResolver = require "addressResolver"
local resourceResolver = require "resourceResolver"
local timerUtility = require "utility.timer"
local queue = require "skynet.queue"
local currencyUtility = require "utility.currency"
local LS_CONST = require "define.lsConst"

local tableFrameSink = require(string.format("%s.lualib.tableFrameSink", skynet.getenv("game")))
local gameMatchSink

local _criticalSection = queue()

local _data = {
	serverConfig = {},
	chairID2UserData = {},	-- index start from 1, [chairID]={item=, isAllowLook=, offlineCount=, offlineTime=}
	
	id = 0,												--桌子号码
	startMode = 0,										-- m_cbStartMode 开始模式 
	drawCount = 0,										-- m_wDrawCount 游戏局数 
	drawStartTime = 0,									-- m_dwDrawStartTime 开始时间
	gameStatus = GS_CONST.GAME_STATUS.FREE,				-- m_cbGameStatus 游戏状态
	isGameStarted = false,								-- m_bGameStarted
	isDrawStarted = false,								-- m_bDrawStarted
	isTableStarted = false,								-- m_bTableStarted
	
	tableOwnerID = 0,									--桌主用户userID m_dwTableOwnerID
	enterPassword = nil,								--进入密码 m_szEnterPassword
	needVipLv=0,										--进入房间需要的vip
	multipleLv=0,										--进入房间需要的炮倍等级
	
	offlineCheckTimerID = nil,
	
	drawID = 0,
	gameScoreRecord = {},								-- m_GameScoreRecordActive 游戏记录
	
	packetBuf = {},

	chairID2LookonUser = {},							--旁观用户信息[chairID]={userItem,}
}

local adjustOfflineTimer, onTimerOfflineWait, concludeGame

local function broadcastTableWithExcept(packetStr, exceptUserItem)
	for _, userData in pairs(_data.chairID2UserData) do
		if userData.item and userData.item ~= exceptUserItem then
			local userAttr = ServerUserItem.getAttribute(userData.item, {"agent","userID"})
			if userAttr.agent ~= 0 then
				skynet.send(userAttr.agent, "lua", "forward", packetStr)
			end
		end
	end
end

local function broadcastTable(packetStr)
	broadcastTableWithExcept(packetStr)
end

local function broadcastLookon(packetStr)
	for _, userDatas in pairs(_data.chairID2LookonUser) do
		for _k, uid in ipairs(userDatas) do
			local userItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "getUserItem", uid)
			if userItem then
				local userAttr = ServerUserItem.getAttribute(userItem, {"agent"})
				if userAttr.agent ~= 0 then
					skynet.send(userAttr.agent, "lua", "forward", packetStr)
				end
			end
		end
	end
end

local function broadcastPaoTaiLevel(userID,chairID,vipLv)
	local respObj = {
		fortOption = vipLv,
		fortLevel = vipLv,
		chairID = chairID,
	}

	for _, userData in pairs(_data.chairID2UserData) do
		if userData.item then
			local userAttr = ServerUserItem.getAttribute(userData.item, {"userID","chairID"})
			if userAttr then
				local limitid = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_PAO_TAI_LV
				local opLimitInfo = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "GetLimitInfo",userAttr.userID,limitid)
				if opLimitInfo then
					respObj.fortOption = opLimitInfo.limitCount
					respObj.chairID = userAttr.chairID
					local pbParser = resourceResolver.get("pbParser")
					local packetStr = skynet.call(pbParser, "lua", "encode", 0x020012, respObj, true)
					if packetStr then
						broadcastTable(packetStr)
					end
				end
			end
		end
	end
end

local function broadcastExperienceGunInfo()
	local pbObj = {
		item = {},
	}

	local nowTick = os.time()

	for _, userData in pairs(_data.chairID2UserData) do
		if userData.item then
			local userAttr = ServerUserItem.getAttribute(userData.item, {"agent","userID","memberOrder"})
			if userAttr then
				local opLimitInfo = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","GetLimitInfo",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP)
				if opLimitInfo then
					if userAttr.memberOrder < opLimitInfo.limitCount then
						if nowTick - opLimitInfo.limitDate < COMMON_CONST.EX_VIP_PAO_TAI_TIME then
							local info = {
								userID = userAttr.userID,
								VipExperienceFortLevel = opLimitInfo.limitCount,
								VipExperienceFortTime = COMMON_CONST.EX_VIP_PAO_TAI_TIME - (nowTick - opLimitInfo.limitDate),
							}

							table.insert(pbObj.item,info)
						end
					end
				end
			end
		end
	end

	local pbParser = resourceResolver.get("pbParser")
	local packetStr = skynet.call(pbParser,"lua","encode",0x012002,pbObj,true)
	if packetStr then
		broadcastTable(packetStr)
	end
end

local function sendLookonPacket(packetStr, chairID)
	--发送给旁观者信息
	if not chairID or not _data.chairID2LookonUser[chairID] then
		return
	end
	for _, uid in ipairs(_data.chairID2LookonUser[chairID]) do
		if uid then
			local userItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "getUserItem", uid)
			if userItem then
				local userAttr = ServerUserItem.getAttribute(userItem, {"agent"})
				if userAttr.agent ~= 0 then
					skynet.send(userAttr.agent, "lua", "forward", packetStr)
				end
			end
		end
	end
end

local function calculateRevenue(chairID, score)
	if chairID > _data.serverConfig.ChairPerTable then return 0 end
	if _data.serverConfig.RevenueRatio > 0 and score >= 0 then
		--计算税收
		local revenue = math.floor(score * (_data.serverConfig.RevenueRatio / 1000))
		return revenue
	end
	return 0
end

local function getBufferedPacket(protocalNo)
	local packet = _data.packetBuf[protocalNo]
	if not packet then
		packet = skynet.call(addressResolver.getAddressByServiceName("simpleProtocalBuffer"), "lua", "get", protocalNo)
		_data.packetBuf[protocalNo] = packet
	end
	return packet
end

local function getOldestOfflineChairID()
	local oldestOfflineTime = math.maxinteger
	local oldestOfflineChairID = GS_CONST.INVALID_CHAIR
	
	for chairID, userData in pairs(_data.chairID2UserData) do
		if userData.offlineTime~=0 and userData.offlineTime < oldestOfflineTime then
			oldestOfflineTime = userData.offlineTime
			oldestOfflineChairID = chairID
		end
	end
	
	return oldestOfflineChairID
end

local function getOfflineUserCount()
	local cnt = 0
	for _, userData in pairs(_data.chairID2UserData) do
		if userData.offlineTime~=0 then
			cnt = cnt + 1
		end
	end
	return cnt;
end

local function createUserDataItem(userItem)
	return {
		item = userItem,
		isAllowLook = true,
		offlineCount = 0,
		offlineTime = 0,
	}
end

local function getSitUserCount()
	local cnt = 0
	for _, _ in pairs(_data.chairID2UserData) do
		cnt = cnt + 1
	end
	return cnt;
end

local function setStartMode(mode)
	_data.startMode = mode
end

local function getServerConfig()
	return _data.serverConfig
end

local function getGameStatus()
	return _data.gameStatus
end

local function setGameStatus(gameStatus)
	_data.gameStatus = gameStatus
	
	local pbParser = resourceResolver.get("pbParser")
	local packetStr = skynet.call(pbParser, "lua", "encode", 0x010203, {gameStatus=_data.gameStatus}, true)
	if packetStr then
		broadcastTable(packetStr)
		broadcastLookon(packetStr)
	end	
end

local function isDrawStarted()
	return _data.isTableStarted
end

local function getSitUserMinScore()
	-- 获取已坐下玩家最低分数
	local minScore
	for _, userData in pairs(_data.chairID2UserData) do
		if userData.item then
			local userAttr = ServerUserItem.getAttribute(userData.item, {"score"})
			if minScore == nil then
				minScore = userAttr.score
			else
				minScore = math.min(userAttr.score, minScore)
			end
		end
	end
	if not minScore then
		minScore = 0
	end
	return minScore
end

local function startGame()
	if _data.isDrawStarted then
		skynet.error(string.format("%s[%d] 游戏已经开始了", SERVICE_NAME, _data.id))
		return
	end
	
	local isGameStartedOld = _data.isGameStarted
	local isTableStartedOld = _data.isTableStarted
	
	_data.isGameStarted = true
	_data.isDrawStarted = true
	_data.isTableStarted = true
	_data.gameStatus = GS_CONST.GAME_STATUS.PLAY
	
	_data.drawStartTime = math.floor(skynet.time())
	
	if not isGameStartedOld then
		for chairID, userData in pairs(_data.chairID2UserData) do
			userData.offlineCount = 0
			userData.offlineTime = 0
			
			if _data.serverConfig.ServiceScore > 0 then
				ServerUserItem.freezeScore(userData.item, _data.serverConfig.ServiceScore)
			end
			
			local userAttr =  ServerUserItem.getAttribute(userData.item, {"userStatus", "userID"})
			if userAttr.userStatus ~= GS_CONST.USER_STATUS.US_OFFLINE and userAttr.userStatus ~= GS_CONST.USER_STATUS.US_PLAYING then
				skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "setUserStatus", userAttr.userID, GS_CONST.USER_STATUS.US_PLAYING, _data.id, chairID)
			end
		end
		
		if not isTableStartedOld then
			skynet.call(addressResolver.getAddressByServiceName("GS_model_tableManager"), "lua", "tableStateChange", _data.id, {
				isLocked = _data.enterPassword~=nil,
				isStarted = _data.isGameStarted,
				sitCount = getSitUserCount(),
				needVipLv = _data.needVipLv,
				multipleLv = _data.multipleLv,
				tablePassword=_data.enterPassword,
			})
		end
	end
	
	local sql = string.format(
		"INSERT INTO `kfrecorddb`.`DrawInfo` (`KindID`, `ServerID`, `TableID`, `StartTime`) VALUES (%d, %d, %d, '%s')",
		_data.serverConfig.KindID, _data.serverConfig.ServerID, _data.id, os.date('%Y-%m-%d %H:%M:%S', _data.drawStartTime)
	)
	
	local mysqlConn = addressResolver.getMysqlConnection()
	_data.drawID = skynet.call(mysqlConn, "lua", "insert", sql)
	
	_data.offlineCheckTimerID = nil
	timerUtility.start(GS_CONST.TIMER.TICK_STEP)
	
	if tableFrameSink.onEventGameStart then
		tableFrameSink.onEventGameStart(_data.multipleLv)
	end

	if tableFrameSink.worldBossInit then
		tableFrameSink.worldBossInit()
	end
	
	if gameMatchSink and gameMatchSink.onEventGameStart then
		gameMatchSink.onEventGameStart()
	end
end

local function storeGameRecord()	
	local sql = string.format(
		"UPDATE `kfrecorddb`.`DrawInfo` SET `ConcludeTime`='%s' WHERE `DrawID`=%d",
		os.date('%Y-%m-%d %H:%M:%S', math.floor(skynet.time())), _data.drawID
	)
	
	local mysqlConn = addressResolver.getMysqlConnection()
	skynet.send(mysqlConn, "lua", "execute", sql)
	
	if #(_data.gameScoreRecord) == 0 then
		return 
	end	
	
	for _, item in ipairs(_data.gameScoreRecord) do
		if item.isAndroid then
			item.isAndroid = 1
		else
			item.isAndroid = 0
		end
		
		if item.grade==nil then
			item.grade = 0
		end
		
		if item.gift==nil then
			item.gift = 0
		end
		
		if item.present==nil then
			item.present = 0
		end
		
		if item.loveliness==nil then
			item.loveliness = 0
		end
		
		if item.loveliness==nil then
			item.loveliness = 0
		end		
		
		
		sql = string.format(
			"INSERT INTO `kfrecorddb`.`DrawScore` (`DrawID`, `UserID`, `ChairID`, `isAndroid`, `Score`, `Grade`, `Revenue`, `Medal`, `Gift`, `Present`, `Loveliness`, `PlayTimeCount`, `InoutIndex`, `InsertTime`,`ServerId`) VALUES (%d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, '%s',%d)",
			_data.drawID, item.userID, item.chairID, item.isAndroid, item.score, item.grade, item.revenue, item.medal, item.gift, item.present, item.loveliness, item.gamePlayTime, item.inoutIndex, os.date('%Y-%m-%d %H:%M:%S', item.insertTime),_data.serverConfig.ServerID
		)
		skynet.send(mysqlConn, "lua", "execute", sql)
	end
	
	_data.gameScoreRecord = {}
end

--[[
tagScoreInfo: {
	type=GS_CONST.SCORE_TYPE, 			--积分类型
	score=, 							--用户分数
	insure=,							--用户银行（这个基本不会用）
	grade=, 							--用户成绩
	revenue=, 							--游戏税收
	medal=,								--奖牌
	gift=,								--礼券
	present=,							--UU游戏的用户的奖牌数
	loveliness=,						--魅力
}
--]]
local function writeUserScore(chairID, tagScoreInfo, gamePlayTime, ignoreGameRecord)
	local userData = _data.chairID2UserData[chairID]
	local userAttr = ServerUserItem.getAttribute(userData.item, {"userID", "score"})
	if not userData then
		skynet.error(string.format("%s[%d] writeUserScore 找不到用户信息 chairID=%d", SERVICE_NAME, _data.id, chairID))
		return
	end

	--比赛场筹码处理
	if _data.serverConfig.ServerType & GS_CONST.GAME_GENRE.MATCH ~= 0 then
		if tagScoreInfo.score==nil then
			tagScoreInfo.score = 0
		end
		local _score = userAttr.score + tagScoreInfo.score
		if _score <= 0 then
			_score = 0
			--设置淘汰用户排名
			skynet.call(addressResolver.getAddressByServiceName("GS_model_matchManager"), "lua", "setOutUserRanking", _data.id, userAttr.userID)
		end
		ServerUserItem.setAttribute(userData.item, {score=_score})
		return
	end
		
	if tagScoreInfo.type==nil then
		error(string.format("%s[%d] writeUserScore 缺少积分类型 chairID=%d", SERVICE_NAME, _data.id, chairID))
	end
	
	if tagScoreInfo.score==nil then
		tagScoreInfo.score = 0
	end
	
	if tagScoreInfo.revenue==nil then
		tagScoreInfo.revenue = 0
	end
	
	if tagScoreInfo.medal==nil then
		tagScoreInfo.medal = 0
	end	
	
	--游戏时间
	if gamePlayTime==nil then
		if _data.isDrawStarted then
			gamePlayTime = math.floor(skynet.time()) - _data.drawStartTime
		else
			gamePlayTime = 0
		end
	end	
	
	if GS_CONST.SCORE_TYPE.ST_WIN<=tagScoreInfo.type and tagScoreInfo.type<=GS_CONST.SCORE_TYPE.ST_FLEE then
		--扣服务费
		if _data.serverConfig.ServiceScore>0 and _data.serverConfig.ServerType==GS_CONST.GAME_GENRE.GOLD then
			tagScoreInfo.score = tagScoreInfo.score - _data.serverConfig.ServiceScore
			tagScoreInfo.revenue = tagScoreInfo.revenue + _data.serverConfig.ServiceScore
			
			local userAttr = ServerUserItem.getAttribute(userData.item, {"frozenedScore"})
			ServerUserItem.unfreezeScore(userData.item, math.min(userAttr.frozenedScore, _data.serverConfig.ServiceScore))
		end
	end

	
	--道具判断(更像是buff效果，由于没用，拿掉)
	
	ServerUserItem.writeUserScore(userData.item, {
		score=tagScoreInfo.score,
		insure=tagScoreInfo.insure,
		grade=tagScoreInfo.grade,
		revenue=tagScoreInfo.revenue,
		medal=tagScoreInfo.medal,
		gift=tagScoreInfo.gift,
		present=tagScoreInfo.present,
		loveliness=tagScoreInfo.loveliness,
	}, tagScoreInfo.type, gamePlayTime)
	if _data.serverConfig.ServerType~=GS_CONST.GAME_GENRE.EDUCATE then
		skynet.call(addressResolver.getAddressByServiceName("GS_model_attemperEngine"), "lua", "writeVariation", userData.item)
	end

	--游戏记录
	if not ignoreGameRecord and (_data.serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_RECORD_GAME_SCORE) ~= 0 then
		local userAttr = ServerUserItem.getAttribute(userData.item, {"userID", "isAndroid", "inoutIndex"})
		table.insert(_data.gameScoreRecord, {
			userID = userAttr.userID,
			chairID = chairID,
			isAndroid = userAttr.isAndroid,
			score = tagScoreInfo.score,
			grade = tagScoreInfo.grade,
			revenue = tagScoreInfo.revenue,
			medal = tagScoreInfo.medal,
			gift = tagScoreInfo.gift,
			present = tagScoreInfo.present,
			loveliness = tagScoreInfo.loveliness,
			gamePlayTime = gamePlayTime,
			inoutIndex = userAttr.inoutIndex,
			insertTime = math.floor(skynet.time()),
		})
	
		if #(_data.gameScoreRecord) > 100 then
			storeGameRecord()
		end
	end
end

local function getTableID()
	return _data.id
end

-- 结束桌子
local function concludeTable()
	if not _data.isGameStarted and _data.isTableStarted then
		if _data.startMode==GS_CONST.START_MODE.ALL_READY or _data.startMode==GS_CONST.START_MODE.PAIR_READY or _data.startMode==GS_CONST.START_MODE.FULL_READY or
				_data.serverConfig.ChairPerTable==GS_CONST.MAX_CHAIR or getSitUserCount()==0 then
					
			_data.isTableStarted = false
		end
	end
end

local function efficacyStartGame(chairID)
	if _data.isGameStarted then
		return false
	end
	
	--模式过滤
	if _data.startMode==GS_CONST.START_MODE.TIME_CONTROL or _data.startMode==GS_CONST.START_MODE.MASTER_CONTROL then
		return false
	end
	
	local readyUserCount = 0
	for cid, userData in pairs(_data.chairID2UserData) do
		local userAttr = ServerUserItem.getAttribute(userData.item, {"isClientReady", "userStatus"})
		if not userAttr.isClientReady or (chairID~=cid and userAttr.userStatus~=GS_CONST.USER_STATUS.US_READY) then
			return false
		end
		readyUserCount = readyUserCount + 1
	end
	
	if _data.startMode==GS_CONST.START_MODE.ALL_READY then
		--所有准备
		if readyUserCount >= 2 then
			return true
		else
			return false
		end
		
	elseif _data.startMode==GS_CONST.START_MODE.FULL_READY then
		--满人开始
		if readyUserCount==_data.serverConfig.ChairPerTable then
			return true
		else
			return false
		end
		
	elseif _data.startMode==GS_CONST.START_MODE.PAIR_READY then
		--配对开始
		
		--数目判断
		if readyUserCount==_data.serverConfig.ChairPerTable then
			return true
		end
		
		if readyUserCount<2 or readyUserCount%2~=0 then
			return false
		end
		
		local halfTableNum = math.floor(_data.serverConfig.ChairPerTable/2)
		for i=1, halfTableNum do
			local ud1 = _data.chairID2UserData[i]
			local ud2 = _data.chairID2UserData[i+halfTableNum]
			
			if (ud1==nil and ud2~=nil) or (ud1~=nil and ud2==nil) then
				return false
			end
		end
		
		return true
	else
		return false
	end
end

local function notifyLockRoomStauts()
	local respObj = {
		ownerChairID = 0,    
   	 	isLock=0,             
	}

	local sui = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"),"lua","getUserItem",_data.tableOwnerID)
	if sui then
		local attr = ServerUserItem.getAttribute(sui, {"chairID", "tableID"})
		respObj.ownerChairID = attr.chairID
	    local isLock = skynet.call(addressResolver.getAddressByServiceName("GS_model_tableManager"),"lua","GetTableIsLock",attr.tableID)
	    if isLock then
	    	respObj.isLock = 1
	    end

		local pbParser = resourceResolver.get("pbParser")
		local packetStr = skynet.call(pbParser, "lua", "encode", 0x01020B, respObj, true)
		if packetStr then
			broadcastTable(packetStr)
		end
	end
end

local function standUp(userItem, doNotSendTableState)
	local userAttr = ServerUserItem.getAttribute(userItem, {"userStatus", "tableID", "chairID", "userID", "siteDownScore", "isAndroid", "agent", "frozenedScore"})
	local userData = _data.chairID2UserData[userAttr.chairID]
	
	if not userData or userData.item~=userItem then
		if not userData then
			skynet.error(string.format("%s[%d] standUP 桌子用户信息冲突 chairID=%d userItem=%s userData=nil", SERVICE_NAME, _data.id, userAttr.chairID, tostring(userItem)))
		else
			skynet.error(string.format("%s[%d] standUP 桌子用户信息冲突 chairID=%d userItem=%s userData.item=%s", SERVICE_NAME, _data.id, userAttr.chairID, tostring(userItem), tostring(userData.item)))
		end
		return
	end
	
	--解锁游戏币
	if userAttr.frozenedScore > 0 then
		ServerUserItem.unfreezeScore(userItem, userAttr.frozenedScore)
	end
	
	if gameMatchSink and gameMatchSink.onActionUserStandUp then
		gameMatchSink.onActionUserStandUp(userAttr.chairID)
	end	
	
	if tableFrameSink.onActionUserStandUp then
		tableFrameSink.onActionUserStandUp(userAttr.chairID,userAttr.userID)
	end
	
	--如果是练习场
	if _data.serverConfig.ServerType==GS_CONST.GAME_GENRE.EDUCATE then
		ServerUserItem.setAttribute(userItem, {score=userAttr.siteDownScore})
		--推送玩家积分信息
		skynet.call(addressResolver.getAddressByServiceName("GS_model_attemperEngine"), "lua", "broadcastUserScore", userItem)
	end
	
	ServerUserItem.setAttribute(userItem, {isClientReady=false})
	
	local us
	if userAttr.userStatus==GS_CONST.USER_STATUS.US_OFFLINE then
		us = GS_CONST.USER_STATUS.US_NULL
	else
		us = GS_CONST.USER_STATUS.US_FREE
	end
	_data.chairID2UserData[userAttr.chairID] = nil
	_data.chairID2LookonUser[userAttr.chairID] = nil
--[[	
	if us == GS_CONST.USER_STATUS.US_NULL then
		skynet.error(string.format("%s[%d] standUp 清除离线用户数据 chairID=%d userItem=%s userID=%d", SERVICE_NAME, _data.id, userAttr.chairID, tostring(userItem), userAttr.userID))
	else
		skynet.error(string.format("%s[%d] standUp 用户从桌子站起 chairID=%d userItem=%s userID=%d", SERVICE_NAME, _data.id, userAttr.chairID, tostring(userItem), userAttr.userID))
	end
--]]
	skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "setUserStatus", userAttr.userID, us, GS_CONST.INVALID_TABLE, GS_CONST.INVALID_CHAIR)
	
	if _data.tableOwnerID == userAttr.userID then
		local temp = {
			payRmb = 0,
			item = nil,
		}
		for k, v in pairs(_data.chairID2UserData) do
			local attr = ServerUserItem.getAttribute(v.item, {"contribution","userID"})
			if attr.contribution > temp.payRmb then
				temp.payRmb = attr.contribution
				temp.item = v.item
			end
		end

		if temp.item ~= nil then
			local ownerTable = ServerUserItem.getAttribute(temp.item, {"userID","chairID","tableID"})
			_data.tableOwnerID = ownerTable.userID
			notifyLockRoomStauts()
		else
			_data.tableOwnerID = 0
			_data.enterPassword = nil
			_data.needVipLv = 0
			_data.multipleLv = 0
		end
	end
	
	--104百人牛牛一直在跑
	if _data.tableOwnerID == 0 and _data.serverConfig.KindID ~= 104 and _data.serverConfig.KindID ~= 800 then
		--踢走旁观
		local packetStr = getBufferedPacket(0x010205)
		broadcastLookon(packetStr)
	
		--结束桌子
		timerUtility.stop()
		concludeGame(GS_CONST.GAME_STATUS.FREE)
	end	
	
	--开始判断
	if efficacyStartGame(GS_CONST.INVALID_CHAIR) then
		startGame()
	end
	
	if not doNotSendTableState then
		skynet.call(addressResolver.getAddressByServiceName("GS_model_tableManager"), "lua", "tableStateChange", _data.id, {
			isLocked = _data.enterPassword~=nil,
			isStarted = _data.isGameStarted,
			sitCount = getSitUserCount(),
			needVipLv = _data.needVipLv,
			multipleLv = _data.multipleLv,
			tablePassword=_data.enterPassword,
		})
	end

	--换一个机器人
	if userAttr.isAndroid and (_data.serverConfig.KindID == 104 or _data.serverConfig.KindID == 800) then 
		skynet.send(addressResolver.getAddressByServiceName("GS_model_androidManager"),"lua","reloadOneAndroid",_data.serverConfig.ServerID,userAttr.userID,userAttr.tableID)
	end
end

concludeGame = function(gameStatus)	
	if not _data.isGameStarted then
		return
	end
	
	_data.offlineCheckTimerID = nil
	tableFrameSink.onEventGameConclude()
	storeGameRecord()	
	
	_data.isDrawStarted = false
	setGameStatus(gameStatus)
	if _data.gameStatus>=GS_CONST.GAME_STATUS.PLAY then
		_data.isGameStarted = true
	else
		_data.isGameStarted = false
	end
	_data.drawCount = _data.drawCount + 1
	
	if not _data.isGameStarted then
		for chairID, userData in pairs(_data.chairID2UserData) do
			local userAttr = ServerUserItem.getAttribute(userData.item, {"userStatus", "userID", "isAndroid", "score", "masterOrder", "agent", "frozenedScore", "insure"})
			
			if userAttr.frozenedScore > 0 then
				ServerUserItem.unfreezeScore(userData.item, userAttr.frozenedScore)
			end
			
			if userAttr.userStatus==GS_CONST.USER_STATUS.US_OFFLINE then
				standUp(userData.item, true)
			else
				if userAttr.userStatus==GS_CONST.USER_STATUS.US_PLAYING then
					skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "setUserStatus", userAttr.userID, GS_CONST.USER_STATUS.US_SIT, _data.id, chairID)
				end
				
				if (_data.serverConfig.ServerType & GS_CONST.GAME_GENRE.MATCH)==0 and userAttr.isAndroid then
					--TODO CTableFrame::ConcludeGame 机器人局数，时间限制的检查，不符合条件就站起
				end
				
				local kickMsg = nil
				--积分限制
				if _data.serverConfig.MinTableScore > 0 and userAttr.score < _data.serverConfig.MinTableScore then
					if (_data.serverConfig.ServerType & GS_CONST.GAME_GENRE.GOLD)~= 0 then
						kickMsg = string.format("您的游戏筹码少于%s，不能继续游戏！", currencyUtility.formatCurrency(_data.serverConfig.MinTableScore))
					else
						kickMsg = string.format("您的游戏积分少于%s，不能继续游戏！", currencyUtility.formatCurrency(_data.serverConfig.MinTableScore))
					end
				end
				
				if _data.serverConfig.MinEnterScore > 0 and userAttr.score < _data.serverConfig.MinEnterScore then
					if (_data.serverConfig.ServerType & GS_CONST.GAME_GENRE.GOLD)~= 0 then
						kickMsg = string.format("您的游戏筹码少于%s，不能继续游戏！", currencyUtility.formatCurrency(_data.serverConfig.MinEnterScore))
					else
						kickMsg = string.format("您的游戏积分少于%s，不能继续游戏！", currencyUtility.formatCurrency(_data.serverConfig.MinEnterScore))
					end
				end
				
				if _data.serverConfig.MaxEnterScore > 0 and userAttr.score > _data.serverConfig.MaxEnterScore then
					if (_data.serverConfig.ServerType & GS_CONST.GAME_GENRE.GOLD)~= 0 then
						kickMsg = string.format("您的游戏筹码高于%s，不能继续游戏！", currencyUtility.formatCurrency(_data.serverConfig.MaxEnterScore))
					else
						kickMsg = string.format("您的游戏积分高于%s，不能继续游戏！", currencyUtility.formatCurrency(_data.serverConfig.MaxEnterScore))
					end
				end
				
				if (_data.serverConfig.ServerType & GS_CONST.GAME_GENRE.TRY_FORMAL)~= 0 and _data.serverConfig.MaxEnterScore > 0 and 
					(userAttr.score + userAttr.insure) > _data.serverConfig.MaxEnterScore and not userAttr.isAndroid then
					if (_data.serverConfig.ServerType & GS_CONST.GAME_GENRE.GOLD)~= 0 then
						kickMsg = string.format("您的游戏筹码高于%s，不能继续游戏！", currencyUtility.formatCurrency(_data.serverConfig.MaxEnterScore))
					else
						kickMsg = string.format("您的游戏积分高于%s，不能继续游戏！", currencyUtility.formatCurrency(_data.serverConfig.MaxEnterScore))
					end
				end

				if (_data.serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_FORFEND_GAME_ENTER)~=0 and userAttr.masterOrder==0 then
					kickMsg = "由于系统维护，当前游戏桌子禁止用户继续游戏！"
				end
				
				if kickMsg then
					standUp(userData.item, true)
					
					skynet.send(userAttr.agent, "lua", "forward", 0xff0000, {
						msg = kickMsg,
						type = COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_CHAT | COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_EJECT,
					})
				end
			end
		end
	end
		
	if tableFrameSink and tableFrameSink.reset then
		--原来的TableFrameSink::RepositionSink
		tableFrameSink.reset()
	end
	
	concludeTable();
	
	skynet.call(addressResolver.getAddressByServiceName("GS_model_tableManager"), "lua", "tableStateChange", _data.id, {
		isLocked = _data.enterPassword~=nil,
		isStarted = _data.isGameStarted,
		sitCount = getSitUserCount(),
		needVipLv = _data.needVipLv,
		multipleLv = _data.multipleLv,
		tablePassword=_data.enterPassword,
	})

	if gameMatchSink and gameMatchSink.onEventGameEnd then
		gameMatchSink.onEventGameEnd()
	end
end

-- CTableFrame::OnMatchScoreChange CAttemperEngineSink::OnMatchScoreChange
local function onMatchScoreChange(userItem, scoreDelt)
	if (_data.serverConfig.ServerType & GS_CONST.GAME_GENRE.MATCH)~=0 then
		skynet.call(addressResolver.getAddressByServiceName("GS_model_matchManager"), "lua", "onMatchScoreChange", userItem, scoreDelt)
	end
end

local function sendSystemMessage(msg, isAll, isKind, isNode, isServer)
	local msgBody = {
		msg=msg,
		type=COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_CHAT | COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_GLOBAL | COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_TABLE_ROLL,
	}
	
	local kid, nid, sid, sendRemote
	if isAll then
		kid = nil
		nid = nil
		sid = nil
		sendRemote = true
	elseif isKind then
		kid = _data.serverConfig.KindID
		nid = nil
		sid = nil
		sendRemote = true
	elseif isNode then
		kid = nil
		nid = _data.serverConfig.NodeID
		sid = nil
		sendRemote = true
	elseif isServer then
		sendRemote = false
	else
		error(string.format("%s[%d] sendSystemMessage 系统消息目标错误", SERVICE_NAME, _data.id))
	end
	
	if sendRemote then
		skynet.send(
			addressResolver.getAddressByServiceName("GS_model_serverStatus"), "lua", "serverBroadCast",
			kid, nid, sid, COMMON_CONST.RELAY_MESSAGE_TYPE.RMT_SYSTEM_MESSAGE, msgBody
		)
	else
		local pbParser = resourceResolver.get("pbParser")
		local packetStr = skynet.call(pbParser, "lua", "encode", 0xff0000, msgBody, true)
		if packetStr then
			skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "broadcast", packetStr)
		end	
	end
end

adjustOfflineTimer = function(oldestOfflineChairID)
	local oldestOfflineUserData = _data.chairID2UserData[oldestOfflineChairID]
	local lapseSecond = math.floor(skynet.time()) - oldestOfflineUserData.offlineTime
	local timeoutTick = GS_CONST.TIMER.TICKSPAN_TABLE_OFFLINE_WAIT * GS_CONST.TIMER.TICK_STEP - (lapseSecond * 100)
	if timeoutTick < 0 then
		timeoutTick = 0
	end

	_data.offlineCheckTimerID = timerUtility.setTimeout(onTimerOfflineWait, math.ceil(timeoutTick / GS_CONST.TIMER.TICK_STEP), oldestOfflineChairID)
end

onTimerOfflineWait = function(offlineChairID)
	_criticalSection(function()
		if _data.offlineCheckTimerID~=nil then
			_data.offlineCheckTimerID = nil
			
			-- 不需要寻找最老的断线用户，实现保证了offlineChairID就是最老的断线用户
			local offlineUserData = _data.chairID2UserData[offlineChairID]
			if offlineUserData then
				standUp(offlineUserData.item)
			else
				error(string.format("%s[%d]: onTimerOfflineWait 找不到断线用户 chairID=%d", SERVICE_NAME, _data.id, offlineChairID))
			end
			
			if _data.isGameStarted then
				local oldestOfflineChairID = getOldestOfflineChairID()
				if oldestOfflineChairID~=GS_CONST.INVALID_CHAIR then
					--调整定时器
					adjustOfflineTimer(oldestOfflineChairID)
				end
			end
		end
	end)
end

local function findRandomEmptyChairID()
	local startIndex = arc4.random(1, _data.serverConfig.ChairPerTable)
	for i=0, _data.serverConfig.ChairPerTable-1 do
		local index = startIndex + i
		if index > _data.serverConfig.ChairPerTable then
			index = 1
			startIndex = startIndex - _data.serverConfig.ChairPerTable
		end
		
		if _data.chairID2UserData[index] == nil then
			return index
		end
	end
end

local function checkUserIPRule(userItem)
	if (_data.serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_FORFEND_GAME_RULE)~=0 or (_data.serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_ALLOW_AVERT_CHEAT_MODE)~=0 then
		return true
	end
	
	local currentUserAttr =  ServerUserItem.getAttribute(userItem, {"userRule", "ipAddr"})
	local performIPCheck = currentUserAttr.userRule.limitSameIP
	if not performIPCheck then
		for _, v in pairs(_data.chairID2UserData) do
			local userAttr = ServerUserItem.getAttribute(v.item, {"userRule"})
			if userAttr.userRule.limitSameIP then
				performIPCheck = true
				break
			end
		end
	end
	
	if performIPCheck then
		for _, v in pairs(_data.chairID2UserData) do
			local userAttr = ServerUserItem.getAttribute(v.item, {"isAndroid", "masterOrder", "ipAddr"})
			
			if not userAttr.isAndroid and userAttr.masterOrder==0 and userAttr.ipAddr==currentUserAttr.ipAddr then
				if not currentUserAttr.userRule.limitSameIP then
					return false, "RC_IP_CONFLICT_WITH_OTHER1"
				else
					return false, "RC_IP_CONFLICT_WITH_OTHER2"
				end
			end
		end
		
		for i=1, _data.serverConfig.ChairPerTable do
			local userData1 = _data.chairID2UserData[i]
			if userData1 then
				local userAttr1 = ServerUserItem.getAttribute(userData1.item, {"isAndroid", "masterOrder", "ipAddr"})
				if not userAttr1.isAndroid and userAttr1.masterOrder==0 then
					for j=i+1, _data.serverConfig.ChairPerTable do
						local userData2 = _data.chairID2UserData[j]
						if userData2 then
							local userAttr2 = ServerUserItem.getAttribute(userData2.item, {"isAndroid", "masterOrder", "ipAddr"})
							if not userAttr2.isAndroid and userAttr2.masterOrder==0 and userAttr1.ipAddr==userAttr2.ipAddr then
								return false, "RC_SAME_IP_EXIST"
							end
						end
					end
				end
			end
		end
	end 
	return true
end

local function checkUserScoreRule(userItem)
	if (_data.serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_FORFEND_GAME_RULE)~=0 or (_data.serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_ALLOW_AVERT_CHEAT_MODE)~=0 then
		return true
	end
	
	local currentUserAttr =  ServerUserItem.getAttribute(userItem, {"winCount", "lostCount", "drawCount", "fleeCount", "score"})
	
	local winRate, fleeRate
	do
		local totalGameCount = currentUserAttr.winCount + currentUserAttr.lostCount + currentUserAttr.drawCount + currentUserAttr.fleeCount
		
		if totalGameCount > 0 then
			winRate = math.floor(currentUserAttr.winCount * 10000 / totalGameCount)
			fleeRate = math.floor(currentUserAttr.fleeCount * 10000 / totalGameCount)
		else
			winRate = 0
			fleeRate = 0
		end	
	end
	
	for _, userData in pairs(_data.chairID2UserData) do
		local userAttr =  ServerUserItem.getAttribute(userData.item, {"userRule", "nickName"})
		
		if userAttr.userRule.limitFleeRate and fleeRate > userAttr.userRule.maxFleeRate then
			return false, "RC_USER_LIMIT_FLEE_RATE", string.format("您的逃跑率太高，与 [%s] 设置的设置不符，不能加入游戏！", userAttr.nickName)
		end
	
		if userAttr.userRule.limitWinRate and winRate < userAttr.userRule.minWinRate then
			return false, "RC_USER_LIMIT_WIN_RATE", string.format("您的胜率太低，与 [%s] 设置的设置不符，不能加入游戏！", userAttr.nickName)
		end
		
		if userAttr.userRule.limitGameScore then
			if currentUserAttr.score > userAttr.userRule.maxGameScore then
				return false, "RC_USER_LIMIT_SCORE_MAX", string.format("您的积分太高，与 [%s] 设置的设置不符，不能加入游戏！", userAttr.nickName)
			end
			
			if currentUserAttr.score < userAttr.userRule.minGameScore then
				return false, "RC_USER_LIMIT_SCORE_MIN", string.format("您的积分太低，与 [%s] 设置的设置不符，不能加入游戏！", userAttr.nickName)
			end
		end
		
	end

	return true
end

local function getUserItem(chairID)
	local userData = _data.chairID2UserData[chairID]
	if userData then
		return userData.item
	end	
end

local function cmd_getUserItem(chairID)
	local userItem
	_criticalSection(function()
		userItem = getUserItem(chairID)
	end)
	return userItem 
end

-- performSitDownAction
local function cmd_sitDown(userItem, chairID, password,needVipLv,multipleLv,tableID,roomType)
	local isSuccess, retCode, msg
	
	_criticalSection(function()
		local userAttr = ServerUserItem.getAttribute(userItem, {"userID", "tableID", "chairID", "masterOrder", "score", "agent", "platformID","memberOrder"})
		assert(userAttr.tableID==GS_CONST.INVALID_TABLE and userAttr.chairID==GS_CONST.INVALID_CHAIR, "用户状态错误")

		--炸金花游戏坐下处理
		if COMMON_CONST.IsThisJinHuaServer(_data.serverConfig.KindID) and chairID == GS_CONST.INVALID_CHAIR then
			local tableUserCount = getSitUserCount()
			if tableUserCount == _data.serverConfig.ChairPerTable-1 then
				local minScore = getSitUserMinScore()
				if userAttr.score < minScore then
					isSuccess, retCode, msg = false, "RC_TABLE_FRAME_SINK", string.format("筹码太低，无法坐下")
					return
				end
			end
		end

		if chairID == GS_CONST.INVALID_CHAIR then
			chairID = findRandomEmptyChairID()
			if chairID == nil then
				--找不到空位那么随便选择一个位置，返回已经被xxx占了
				chairID = arc4.random(1, _data.serverConfig.ChairPerTable)
			end
		end
		
		---------------------------------------------------------------------
		-- 模拟处理
		-- 机器人的三个属性：ANDROID_SIMULATE ANDROID_PASSIVITY ANDROID_INITIATIVE在存储过程GSP_GR_LoadAndroidUser_Ex写死=7了，
		-- 所以再检测没有意义，拿掉了
		---------------------------------------------------------------------	
			
		if _data.isGameStarted and (_data.serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_ALLOW_DYNAMIC_JOIN) == 0 then
			isSuccess, retCode, msg = false, "RC_TABLE_GAME_STARTED"
			return
		end
		
		do
			local tableUserData = _data.chairID2UserData[chairID]
			if tableUserData ~= nil then
				local tableUserAttr = ServerUserItem.getAttribute(tableUserData.item, {"nickName"})
				isSuccess, retCode, msg = false, "RC_CHAIR_ALREADY_TAKEN", string.format("椅子已经被 [%s] 捷足先登了，下次动作要快点了！", tableUserAttr.nickName)
				return
			end
		end
		
		if (_data.serverConfig.ServerType & GS_CONST.GAME_GENRE.MATCH) == 0 then
			if _data.enterPassword and userAttr.masterOrder==0 and _data.enterPassword~=password then
				isSuccess, retCode, msg = false, "RC_PASSWORD_ERROR"
				return
			end
			
			-- 规则效验
			if userAttr.masterOrder==0 then
				isSuccess, retCode, msg = checkUserIPRule(userItem)
				if not isSuccess then
					return
				end
				
				isSuccess, retCode, msg = checkUserScoreRule(userItem)
				if not isSuccess then
					return
				end			
			end

			
			-- 扩展效验
			if tableFrameSink.onUserRequestSitDown then
				isSuccess, msg = tableFrameSink.onUserRequestSitDown(chairID, userItem)
				if not isSuccess then
					retCode = "RC_TABLE_FRAME_SINK"
					return
				end
			end
		end
		
		_data.chairID2UserData[chairID] = createUserDataItem(userItem)
		_data.drawCount = 0	
		
		if (_data.serverConfig.ServerType & GS_CONST.GAME_GENRE.EDUCATE) ~= 0 then
			-- 默认试玩场给的钱
			local tryScore = 100000
			
			if tableFrameSink.getPlayerTryScore then
				tryScore = tableFrameSink.getPlayerTryScore()
			end
			
			ServerUserItem.setAttribute(userItem, {siteDownScore=userAttr.score, score=tryScore})
		end

		ServerUserItem.setAttribute(userItem, {isClientReady=false})
		
		local us
		if not _data.isGameStarted or _data.startMode ~= GS_CONST.START_MODE.TIME_CONTROL then
			if (_data.serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_ALLOW_AVERT_CHEAT_MODE)==0 and (_data.serverConfig.ServerType & GS_CONST.GAME_GENRE.MATCH) == 0 then
				us = GS_CONST.USER_STATUS.US_SIT
			else
				us = GS_CONST.USER_STATUS.US_READY
			end
		else
			if _data.serverConfig.ServiceScore > 0 then
				local userData = _data.chairID2UserData[chairID]
				ServerUserItem.freezeScore(userItem, _data.serverConfig.ServiceScore)
			end
			
			us = GS_CONST.USER_STATUS.US_PLAYING
		end
		
		--skynet.error(string.format("%s[%d] cmd_sitDown 1111 userID=%d agent=[:%08x] userStatsu=%d", SERVICE_NAME, _data.id, userAttr.userID, userAttr.agent, us))
		--skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "setUserStatus", userAttr.userID, us, _data.id, chairID)
		--skynet.error(string.format("%s[%d] cmd_sitDown 2222 userID=%d agent=[:%08x] userStatsu=%d", SERVICE_NAME, _data.id, userAttr.userID, userAttr.agent, us))

		local backTemp = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "setUserStatus", userAttr.userID, us, _data.id, chairID)
		if backTemp == false then -- userItem找不到，已被清除
			_data.chairID2UserData[chairID] = nil
			isSuccess, retCode, msg = false, "RC_CHAIR_ALREADY_TAKEN"
			return
		end
		
		if getSitUserCount()==1 and (_data.serverConfig.ServerType & GS_CONST.GAME_GENRE.MATCH) == 0 then
			if _data.serverConfig.ServerID == 220 and ((tableID ~= GS_CONST.INVALID_TABLE and tableID > GS_CONST.VIP_TABLEID_LOW) or roomType ~= 0) then
				if userAttr.memberOrder < 2 then
					isSuccess, retCode, msg = false, "RE_LOW_VIP_LEVEL", string.format("vip等级不足,无法进入房间")
					return isSuccess, retCode, msg
				end

				if password ~= nil then
					_data.enterPassword = password
				end

				if needVipLv ~= 0 then
					_data.needVipLv = needVipLv
				end

				if multipleLv ~= 0 then
					_data.multipleLv = multipleLv
				end
			end

			_data.tableOwnerID = userAttr.userID
		end	

		if _data.serverConfig.ServerID == 220 and ((tableID ~= GS_CONST.INVALID_TABLE and tableID > GS_CONST.VIP_TABLEID_LOW) or roomType ~= 0) then
			if userAttr.memberOrder < _data.needVipLv then
				isSuccess, retCode, msg = false, "RE_LOW_VIP_LEVEL", string.format("vip等级不足,无法进入房间")
				return isSuccess, retCode, msg
			end

			if _data.enterPassword ~= password then
				isSuccess, retCode, msg = false, "RC_PASSWORD_ERROR", string.format("密码不对,无法进入房间")
				return isSuccess, retCode, msg
			end

			if _data.multipleLv ~= 0 then
				local gunMultiple = 1
				local sql = string.format("SELECT CurGunLevel FROM `kffishdb`.`t_gun_uplevel` where UserId=%d",userAttr.userID)
				local dbConn = addressResolver.getMysqlConnection()
				local rows = skynet.call(dbConn,"lua","query",sql)
				if rows[1] ~= nil then
					gunMultiple = tonumber(rows[1].CurGunLevel)
				end
				local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
				gunMultiple = skynet.call(configAddress,"lua","GetGunMultiple",gunMultiple)

				if gunMultiple < _data.multipleLv then
					isSuccess, retCode, msg = false, "RE_LOW_MULTIPLE_LEVEL", string.format("炮台等级不足,无法进入房间")
					return isSuccess, retCode, msg
				end
			end
		end
		
		skynet.call(addressResolver.getAddressByServiceName("GS_model_tableManager"), "lua", "tableStateChange", _data.id, {
			isLocked = _data.enterPassword~=nil,
			isStarted = _data.isGameStarted,
			sitCount = getSitUserCount(),
			needVipLv = _data.needVipLv,
			multipleLv = _data.multipleLv,
			tablePassword=_data.enterPassword,
		})
		
		if tableFrameSink.onActionUserSitDown then
			tableFrameSink.onActionUserSitDown(chairID, userItem, false)
		end

		--skynet.error(string.format("%s[%d] cmd_sitDown 用户信息写入完成 chairID=%d userItem=%s", SERVICE_NAME, _data.id, chairID, tostring(userItem)))
		
		if gameMatchSink and gameMatchSink.onActionUserSitDown then
			gameMatchSink.onActionUserSitDown(chairID, userItem, false)
		end	
		
		isSuccess, retCode, msg = true
	end)
	return isSuccess, retCode, msg
end

local function cmd_gameOption(userItem, isAllowLookon)
	_criticalSection(function()
		local userAttr = ServerUserItem.getAttribute(userItem, {"chairID", "userStatus", "agent"})
		--skynet.error(string.format("gameOption received from [:%08x]", userAttr.agent))
		local userData = _data.chairID2UserData[userAttr.chairID]
		if not userData or userData.item~=userItem then
			error(string.format("%s[%d] cmd_gameOption 用户信息冲突 chairID=%d", SERVICE_NAME, _data.id, userAttr.chairID))
		end
		
		-- 断线清理
		if userAttr.userStatus~=GS_CONST.USER_STATUS.US_LOOKON and userData.offlineTime~=0 then
			userData.offlineTime=0
			
			if _data.offlineCheckTimerID then
				timerUtility.clearTimer(_data.offlineCheckTimerID)
				_data.offlineCheckTimerID = nil
				
				local oldestOfflineChairID = getOldestOfflineChairID()
				if oldestOfflineChairID~=GS_CONST.INVALID_CHAIR then
					--调整定时器
					adjustOfflineTimer(oldestOfflineChairID)
				end
			end
		end
		
		ServerUserItem.setAttribute(userItem, {isClientReady=true})
		if userAttr.userStatus~=GS_CONST.USER_STATUS.US_LOOKON then
			userData.isAllowLook = isAllowLookon
		end
		
		skynet.send(userAttr.agent, "lua", "forward", 0x010203, {gameStatus=_data.gameStatus})
		skynet.send(userAttr.agent, "lua", "forward", 0xff0000, {
			type = COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_CHAT,
			msg = string.format("欢迎您进入“%s”游戏，祝您游戏愉快！", _data.serverConfig.KindName),
		})
		
		local sendSecret = userAttr.userStatus~=GS_CONST.USER_STATUS.US_LOOKON or userData.isAllowLook
		tableFrameSink.onActionUserGameOption(userAttr.chairID, userItem, _data.gameStatus, sendSecret)
		
		-- 开始判断
		if userAttr.userStatus==GS_CONST.USER_STATUS.US_READY and efficacyStartGame(userAttr.chairID) then
			startGame()
		end
	end)
end

local function cmd_standUp(userItem)
	_criticalSection(function()
		standUp(userItem)
	end)
end

local function cmd_userReady(userItem)
	_criticalSection(function()
		local userAttr = ServerUserItem.getAttribute(userItem, {"chairID", "userID"})
		if not efficacyStartGame(userAttr.chairID) then
			skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "setUserStatus", userAttr.userID, GS_CONST.USER_STATUS.US_READY, _data.id, userAttr.chairID)
		else
			startGame()
		end
	end)
end

local function removeOldLookonUser(userID)
	-- 移除老的旁观对象
	for _, userIDs in pairs(_data.chairID2LookonUser) do
		for k, _uid in ipairs(userIDs) do
			if _uid == userID then
				skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "setUserStatus", userID, GS_CONST.USER_STATUS.US_FREE, GS_CONST.INVALID_TABLE, GS_CONST.INVALID_CHAIR)
				table.remove(userIDs, k)
				break
			end
		end
	end
end

local function addLookonUserID(chairID, userID)
	-- 添加旁观用户
	if _data.chairID2LookonUser[chairID] == nil then
		_data.chairID2LookonUser[chairID] = {userID}
	else
		removeOldLookonUser(userID)
		table.insert(_data.chairID2LookonUser[chairID], userID)
	end
end

local function cmd_userLookon(userItem, chairID, password)
	--旁观
	local isSuccess, retCode, msg
	
	_criticalSection(function()

		local userAttr = ServerUserItem.getAttribute(userItem, {"userID", "tableID", "chairID", "masterOrder", "score", "agent"})
		assert(userAttr.tableID==GS_CONST.INVALID_TABLE and userAttr.chairID==GS_CONST.INVALID_CHAIR, "用户状态错误")
		
		if chairID == GS_CONST.INVALID_CHAIR then
			isSuccess, retCode, msg = false, "RC_USER_CHAIR_INVAILD"
			return
		end
		
		if _data.chairID2UserData[chairID] == nil then
			isSuccess, retCode, msg = false, "RC_NO_USER"
			return
		end

		---------------------------------------------------------------------
		-- 模拟处理
		-- 机器人的三个属性：ANDROID_SIMULATE ANDROID_PASSIVITY ANDROID_INITIATIVE在存储过程GSP_GR_LoadAndroidUser_Ex写死=7了，
		-- 所以再检测没有意义，拿掉了
		---------------------------------------------------------------------	
	
		if (_data.serverConfig.ServerType & GS_CONST.GAME_GENRE.MATCH) == 0 then
			if _data.enterPassword and userAttr.masterOrder==0 and _data.enterPassword~=password then
				isSuccess, retCode, msg = false, "RC_PASSWORD_ERROR"
				return
			end
			
			-- 规则效验
			-- if userAttr.masterOrder==0 then
			-- 	isSuccess, retCode, msg = checkUserIPRule(userItem)
			-- 	if not isSuccess then
			-- 		return
			-- 	end		
			-- end

			
			-- 扩展效验
			if tableFrameSink.OnUserRequestLookon then
				isSuccess, msg = tableFrameSink.OnUserRequestLookon(chairID, userItem)
				if not isSuccess then
					retCode = "RC_TABLE_FRAME_SINK"
					return
				end
			end
		end
		
		--添加旁观者
		addLookonUserID(chairID, userAttr.userID)

		ServerUserItem.setAttribute(userItem, {isClientReady=false})
		skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "setUserStatus", userAttr.userID, GS_CONST.USER_STATUS.US_LOOKON, _data.id, chairID)

		if tableFrameSink.onActionUserLookon then
			tableFrameSink.onActionUserLookon(chairID, userItem)
		end

		if tableFrameSink.onActionUserSitDown then
			tableFrameSink.onActionUserSitDown(chairID, userItem, true)
		end

		-- if gameMatchSink and gameMatchSink.onActionUserSitDown then
		-- 	gameMatchSink.onActionUserSitDown(chairID, userItem, true)
		-- end

		isSuccess, retCode, msg = true, "RC_USER_LOOKON_OK"
	end)
	
	return isSuccess, retCode, msg
end

local function cmd_usersLookOnInfo(userItem)
	-- 桌上玩家旁观信息
	local userAttr = ServerUserItem.getAttribute(userItem, {"agent"})
	local lookinfos = {}
	for i=1, _data.serverConfig.ChairPerTable do
		local gameData = _data.chairID2UserData[i]
		if gameData then
			table.insert(lookinfos, gameData.isAllowLook)
		else
			table.insert(lookinfos, false)
		end
	end
	skynet.send(userAttr.agent, "lua", "forward", 0x01020A, {isAllowLookon = lookinfos})
end

--通知用户金币记录变动
local function cmd_onUserGoldRecordChange(userItem)
	_criticalSection(function()
		local userAttr = ServerUserItem.getAttribute(userItem, {"chairID","userStatus"})
		local userData = _data.chairID2UserData[userAttr.chairID]			
		if (not userData or userData.item~=userItem) and userAttr.userStatus~=GS_CONST.USER_STATUS.US_LOOKON then
			error(string.format("%s[%d] cmd_onUserScoreNotify 用户信息冲突 chairID=%d", SERVICE_NAME, _data.id, userAttr.chairID))
		end			
			
		if (_data.serverConfig.ServerType & GS_CONST.GAME_GENRE.EDUCATE)==0 and (_data.serverConfig.ServerType & GS_CONST.GAME_GENRE.MATCH)==0 and tableFrameSink.onUserGoldRecordChange then	
			tableFrameSink.onUserGoldRecordChange(userAttr.chairID, userItem)
		end	
	end)
end	

--用户积分变动
local function cmd_onUserScoreNotify(userItem)	
	_criticalSection(function()
		local userAttr = ServerUserItem.getAttribute(userItem, {"chairID","userStatus"})
		local userData = _data.chairID2UserData[userAttr.chairID]			
		if (not userData or userData.item~=userItem) and userAttr.userStatus~=GS_CONST.USER_STATUS.US_LOOKON then
			error(string.format("%s[%d] cmd_onUserScoreNotify 用户信息冲突 chairID=%d", SERVICE_NAME, _data.id, userAttr.chairID))
		end			
			
		if (_data.serverConfig.ServerType & GS_CONST.GAME_GENRE.EDUCATE)==0 and (_data.serverConfig.ServerType & GS_CONST.GAME_GENRE.MATCH)==0 and tableFrameSink.onUserScoreNotify then	
			tableFrameSink.onUserScoreNotify(userAttr.chairID, userItem)
		end	
	end)
end

local function cmd_calcScoreAndLock(userItem)
	_criticalSection(function()
		local userAttr = ServerUserItem.getAttribute(userItem, {"chairID","userStatus"})
		local userData = _data.chairID2UserData[userAttr.chairID]
		if (not userData or userData.item~=userItem) and userAttr.userStatus~=GS_CONST.USER_STATUS.US_LOOKON then
			error(string.format("%s[%d] cmd_calcScoreAndLock 用户信息冲突 chairID=%d", SERVICE_NAME, _data.id, userAttr.chairID))
		end
		
		if tableFrameSink.calcScoreAndLock then
			-- 捕鱼这类没有锁定金币，不是一局一结算的游戏，需要先通知锁定
			tableFrameSink.calcScoreAndLock(userAttr.chairID)
		end
	end)
end

local function cmd_releaseScoreLock(userItem)
	_criticalSection(function()
		local userAttr = ServerUserItem.getAttribute(userItem, {"chairID","userStatus"})
		local userData = _data.chairID2UserData[userAttr.chairID]
		if (not userData or userData.item~=userItem) and userAttr.userStatus~=GS_CONST.USER_STATUS.US_LOOKON then
			error(string.format("%s[%d] cmd_releaseScoreLock 用户信息冲突 chairID=%d", SERVICE_NAME, _data.id, userAttr.chairID))
		end
		
		if tableFrameSink.releaseScoreLock then
			tableFrameSink.releaseScoreLock(userAttr.chairID)
		end
	end)
end



--CTableFrame::OnEventUserOffLine
local function cmd_userOffLine(userItem)
	_criticalSection(function()
		local userAttr = ServerUserItem.getAttribute(userItem, {"chairID", "userStatus", "agent", "userID"})
		local userData = _data.chairID2UserData[userAttr.chairID]
		if not userData or userData.item~=userItem then
			skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "setUserStatus", userAttr.userID, GS_CONST.USER_STATUS.US_NULL, GS_CONST.INVALID_TABLE, GS_CONST.INVALID_CHAIR)
			if userAttr.userStatus == GS_CONST.USER_STATUS.US_LOOKON then
				return
			end
			if not userData then
				skynet.error(string.format("%s[%d] cmd_userOffLine 桌子用户信息冲突 chairID=%d userItem=%s userData=nil", SERVICE_NAME, _data.id, userAttr.chairID, tostring(userItem)))
			else
				skynet.error(string.format("%s[%d] cmd_userOffLine 桌子用户信息冲突 chairID=%d userItem=%s userData.item=%s", SERVICE_NAME, _data.id, userAttr.chairID, tostring(userItem), tostring(userData.item)))
			end
			return
		end
		
		if userAttr.userStatus~=GS_CONST.USER_STATUS.US_LOOKON and gameMatchSink and gameMatchSink.setUserOffline then
			gameMatchSink.setUserOffline(userAttr.userID, _data.id)
		end
		
		if userAttr.userStatus==GS_CONST.USER_STATUS.US_PLAYING then
			ServerUserItem.setAttribute(userItem, {isClientReady=false, })
			skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "setUserStatus", userAttr.userID, GS_CONST.USER_STATUS.US_OFFLINE, _data.id, userAttr.chairID)
			userData.offlineCount = userData.offlineCount + 1
			userData.offlineTime = math.floor(skynet.time())
			
			if _data.offlineCheckTimerID==nil and _data.serverConfig.KindID ~= 104 and _data.serverConfig.KindID ~= 800 then
				--百人牛牛,飞禽走兽就不需要这个了,每局结束后会清理断线的机器人
				_data.offlineCheckTimerID = timerUtility.setTimeout(onTimerOfflineWait, GS_CONST.TIMER.TICKSPAN_TABLE_OFFLINE_WAIT, userAttr.chairID)
			end
		else
			--skynet.error(string.format("%s[%d]: cmd_userOffLine 用户起立 userID=%d", SERVICE_NAME, _data.id, userAttr.userID))
			--用户起立
			standUp(userItem)
			--skynet.error(string.format("%s.cmd_userOffLine 清除用户数据 userID=%d tableID=%d", SERVICE_NAME, userAttr.userID, _data.id))
			skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "setUserStatus", userAttr.userID, GS_CONST.USER_STATUS.US_NULL, GS_CONST.INVALID_TABLE, GS_CONST.INVALID_CHAIR)
		end
	end)
end

-- 游戏事件 CTableFrame::OnEventSocketGame
local function cmd_onGameMessage(chairID, userItem, protocalNo, data)
	_criticalSection(function()
		local userData = _data.chairID2UserData[chairID]
		if not userData or userData.item~=userItem then
--[[			
			if not userData then
				skynet.error(string.format("%s[%d] cmd_onGameMessage 桌子用户信息冲突 chairID=%d userItem=%s userData=nil", SERVICE_NAME, _data.id, chairID, tostring(userItem)))
			else
				skynet.error(string.format("%s[%d] cmd_onGameMessage 桌子用户信息冲突 chairID=%d userItem=%s userData.item=%s", SERVICE_NAME, _data.id, chairID, tostring(userItem), tostring(userData.item)))
			end
--]]
			return 
		end
		
		tableFrameSink.pbMessage(userItem, protocalNo, data)
	end)
end

local function clearOfflineRebot(chairId)
	for chairID, userData in pairs(_data.chairID2UserData) do
		if chairId ~= chairID then
			local userAttr = ServerUserItem.getAttribute(userData.item, {"userStatus", "userID", "isAndroid","chairID"})
			if userAttr and userAttr.isAndroid and userAttr.userStatus == GS_CONST.USER_STATUS.US_OFFLINE then
				standUp(userData.item, true)
			end
		end
	end	
end

local interface4sink = {
	getTableID = getTableID,
	getGameStatus = getGameStatus,
	setGameStatus = setGameStatus,
	setStartMode = setStartMode,
	getServerConfig = getServerConfig,
	startGame = startGame,
	broadcastTable = broadcastTable,
	broadcastTableWithExcept = broadcastTableWithExcept,
	broadcastLookon = broadcastLookon,
	writeUserScore = writeUserScore,
	getBufferedPacket = getBufferedPacket,
	concludeGame = concludeGame,
	standUp = standUp,
	onMatchScoreChange = onMatchScoreChange,
	sendSystemMessage = sendSystemMessage,
	isDrawStarted = isDrawStarted,
	getUserItem = getUserItem,
	sendLookonPacket = sendLookonPacket,
	calculateRevenue = calculateRevenue,
	clearOfflineRebot = clearOfflineRebot,
	broadcastPaoTaiLevel = broadcastPaoTaiLevel,
	broadcastExperienceGunInfo = broadcastExperienceGunInfo,
	notifyLockRoomStauts = notifyLockRoomStauts,
}

local function cmd_initialize(tableID, serverConfig)
	_data.serverConfig = serverConfig
	_data.id = tableID

	tableFrameSink.initialize(interface4sink, _criticalSection)
	if (_data.serverConfig.ServerType & GS_CONST.GAME_GENRE.MATCH) ~= 0 then
		gameMatchSink = require "match.gameMatchSink"
		gameMatchSink.initialize(interface4sink, _criticalSection)
	end
end

--CTableFrame::GetTableUserInfo
local function cmd_getUserCount()
	local count = {
		minUser = 0,
		user = 0,
		android = 0,
		ready = 0,
		total = 0,
	}
	
	_criticalSection(function()
		--用户分析
		for _, userData in pairs(_data.chairID2UserData) do
			local userAttr =  ServerUserItem.getAttribute(userData.item, {"userStatus", "isAndroid"})
			if userAttr.isAndroid then
				count.android = count.android + 1
			else
				count.user = count.user + 1
			end
			
			if userAttr.userStatus == GS_CONST.USER_STATUS.US_READY then
				count.ready = count.ready + 1
			end
			
			count.total = count.total + 1
		end
		
		--最少数目
		if _data.startMode == GS_CONST.START_MODE.ALL_READY then			--所有准备
			count.minUser = 2
		elseif _data.startMode == GS_CONST.START_MODE.PAIR_READY then		--配对开始
			count.minUser = 2
		elseif _data.startMode == GS_CONST.START_MODE.TIME_CONTROL then		--时间控制
			count.minUser = 1
		else																--默认模式
			count.minUser = _data.serverConfig.ChairPerTable
		end	
	end)

	return count
end

local function cmd_getState()
	local ret 
	_criticalSection(function()
		ret = {isGameStarted = _data.isGameStarted, isLocked = _data.enterPassword~=nil}
	end)
	return ret
end

local function cmd_enumerateUserItem()
	local list = {}
	_criticalSection(function()
		for _, userData in pairs(_data.chairID2UserData) do
			table.insert(list, userData.item)
		end
	end)

	return list
end

local function cmd_broadcastTable(packetStr)
	broadcastTable(packetStr)
end

local function cmd_broadcastLookon(packetStr)
	broadcastLookon(packetStr)
end

local function cmd_kickUser(userItem, kickChairID)
	-- 踢出用户
	local isSuccess, retCode, userID, msg
	_criticalSection(function()
		local kickUserItem = getUserItem(kickChairID)
		if not kickUserItem then
			isSuccess, retCode, userID, msg = false, "RC_USER_CHAIR_INVAILD", GS_CONST.INVALID_USER, string.format("玩家不存在")
			return
		end
		local kickAttr = ServerUserItem.getAttribute(kickUserItem, {"chairID", "userStatus", "nickName", "agent", "loveliness", "score", "experience", "memberOrder", "userID"})

		--练习场不允许踢人
		if _data.serverConfig.ServerType & GS_CONST.GAME_GENRE.EDUCATE ~= 0 then
			isSuccess, retCode, userID, msg = false, "RC_USER_TABLE_EDUCATE", kickAttr.userID, string.format("试玩场不允许踢人")
			return
		end

		local userAttr = ServerUserItem.getAttribute(userItem, {"chairID", "userStatus", "nickName", "agent", "loveliness", "score", "experience", "memberOrder"})
		if userAttr.loveliness < 0 then
			isSuccess, retCode, userID, msg = false, "RC_LOVELINESS_NO_ENOUGH", kickAttr.userID, string.format("魅力值小于0不允许踢人")
			return
		end

		if kickAttr.userStatus == GS_CONST.USER_STATUS.US_PLAYING then
			isSuccess, retCode, userID, msg = false, "RC_KICKUSER_IS_PLAYING", kickAttr.userID, string.format(" %s 正在游戏中无法踢出", kickAttr.nickName)
			return
		end
		--踢出标记
		local bkicked = false
		if userAttr.memberOrder > kickAttr.memberOrder then
			bkicked = true
			isSuccess, retCode, userID, msg = true, "RC_USER_KICK_OK", kickAttr.userID, string.format("踢人成功")
		elseif userAttr.memberOrder == kickAttr.memberOrder then
			if userAttr.score > kickAttr.score then--and userAttr.experience > kickAttr.experience
				bkicked = true
				isSuccess, retCode, userID, msg = true, "RC_USER_KICK_OK", kickAttr.userID, string.format("踢人成功")
			else
				isSuccess, retCode, userID, msg = false, "RC_USER_KICK_UNSUCESS", kickAttr.userID, string.format("您的金币少于目标，无法踢人")
				-- if userAttr.score <= kickAttr.score then
				-- 	isSuccess, retCode, userID, msg = false, "RC_USER_SCORE_NOT_ENOUGH", kickAttr.userID
				-- else
				-- 	isSuccess, retCode, userID, msg = false, "RC_USER_EXP_NOT_ENOUGH", kickAttr.userID
				-- end
			end
		else
			isSuccess, retCode, userID, msg = false, "RC_USER_SCORE_NOT_ENOUGH", kickAttr.userID, string.format("您的VIP等级低于目标，无法踢人")
		end

		if bkicked then
			--被踢者站起
			standUp(kickUserItem)
			msg=string.format("%s 把 %s 踢出了房间", userAttr.nickName, kickAttr.nickName)
			skynet.send(kickAttr.agent, "lua", "forward", 0x010209, {msg=string.format("%s 把你踢出了房间", userAttr.nickName)})
			skynet.send(kickAttr.agent, "lua", "forward", 0x010208, {code=retCode,msg=msg,userID=kickAttr.userID})
			local pobj = {msg=msg}
			local pbParser = resourceResolver.get("pbParser")
			local packetStr = skynet.call(pbParser, "lua", "encode", 0x010209, pobj, true)
			broadcastTable(packetStr)
			broadcastLookon(packetStr)
		-- else
		-- 	skynet.send(kickAttr.agent, "lua", "forward", 0x010208, {code=retCode,msg=msg,userID=kickAttr.userID})
		-- 	local pobj = {msg=string.format("%s 武功高强，挡住了 %s 一脚踢人", kickAttr.nickName, userAttr.nickName)}
		-- 	local pbParser = resourceResolver.get("pbParser")
		-- 	local packetStr = skynet.call(pbParser, "lua", "encode", 0x010209, pobj, true)
		-- 	broadcastTable(packetStr)
		-- 	broadcastLookon(packetStr)
		end
	end)
	return isSuccess, retCode, userID, msg
end

local function cmd_reloadTableFrameConfig()
	tableFrameSink.reloadTableFrameConfig()
end

local function cmd_sendSystemMessage(msg, isAll, isKind, isNode, isServer)
	sendSystemMessage(msg, isAll, isKind, isNode, isServer)
end

local function cmd_NotifyWorldBossStart(data)
	if tableFrameSink.worldBossStart then
		tableFrameSink.worldBossStart(data)
	end
end

local function cmd_NotifyWorldBossEnd(bKillFalg)
	if tableFrameSink.worldBossEnd then
 		tableFrameSink.worldBossEnd()
 	end

 	if bKillFalg then
 		for chairID, userData in pairs(_data.chairID2UserData) do
			skynet.send(addressResolver.getAddressByServiceName("GS_model_task"),"lua","CheckKillBossTask",userData.item)
		end	
 	end
end

local function cmd_SaveInvalidGunGold(chairID,userID)
	if tableFrameSink.SaveInvalidGunGold then
		tableFrameSink.SaveInvalidGunGold(chairID,userID)
	end
end

local function cmd_NotifyWorldBossTime(agent)
	if tableFrameSink.NotifyWorldBossTime then
		tableFrameSink.NotifyWorldBossTime(agent)
	end
end

local function cmd_ChangeTaskGoodsCount(chairID,pbObj)
	if tableFrameSink.ChangeTaskGoodsCount then
		tableFrameSink.ChangeTaskGoodsCount(chairID,pbObj)
	end
end

local function cmd_CompleteTask(chairID,pbObj)
	if tableFrameSink.CompleteTask then
		tableFrameSink.CompleteTask(chairID,pbObj)
	end
end

local function cmd_TaskSynchronizationTime(chairID)
	if tableFrameSink.TaskSynchronizationTime then
		tableFrameSink.TaskSynchronizationTime(chairID)
	end
end

local function cmd_setControlRateConfig(rateConfig)
	if tableFrameSink.setControlRateConfig then
		tableFrameSink.setControlRateConfig(rateConfig)
	end
end

local function cmd_getTableUserIdList()
	local useridList = ""
	for _, userData in pairs(_data.chairID2UserData) do
		local userAttr = ServerUserItem.getAttribute(userData.item, {"userID"})
		useridList = useridList..tostring(userAttr.userID)..":"
	end

	return useridList
end

local function cmd_LockRoom(sui,pbObj)
	local re = {
		code = 0,
	}

	local userAttr = ServerUserItem.getAttribute(sui, {"memberOrder","userID","chairID","tableID"})
	if userAttr.memberOrder < 5 then
		re.code = 1
		return re
	end

	if _data.tableOwnerID ~= userAttr.userID then
		re.code = 2
		return re
	end
	
	local bLock = false
	if pbObj.isLock == 1 then
		bLock = true
	end

	skynet.call(addressResolver.getAddressByServiceName("GS_model_tableManager"), "lua", "tableStateChange", _data.id, {
			isLocked = bLock,
			isStarted = _data.isGameStarted,
			sitCount = getSitUserCount(),
			needVipLv = _data.needVipLv,
			multipleLv = _data.multipleLv,
			tablePassword=_data.enterPassword,
		})

	notifyLockRoomStauts(userAttr.chairID,userAttr.tableID)

	return re
end
 
local conf = {
	methods = {
		["initialize"] = {["func"]=cmd_initialize, ["isRet"]=true},
		["getState"] = {["func"]=cmd_getState, ["isRet"]=true},
		["getUserItem"] = {["func"]=cmd_getUserItem, ["isRet"]=true},
		["getUserCount"] = {["func"]=cmd_getUserCount, ["isRet"]=true},
		["sitDown"] = {["func"]=cmd_sitDown, ["isRet"]=true},
		["gameOption"] = {["func"]=cmd_gameOption, ["isRet"]=true},
		["standUp"] = {["func"]=cmd_standUp, ["isRet"]=true},
		["userOffLine"] = {["func"]=cmd_userOffLine, ["isRet"]=true},
		["gameMessage"] = {["func"]=cmd_onGameMessage, ["isRet"]=true},
		["calcScoreAndLock"] = {["func"]=cmd_calcScoreAndLock, ["isRet"]=true},
		["releaseScoreLock"] = {["func"]=cmd_releaseScoreLock, ["isRet"]=true},
		["enumerateUserItem"] = {["func"]=cmd_enumerateUserItem, ["isRet"]=true},
		["broadcastTable"] = {["func"]=cmd_broadcastTable, ["isRet"]=false},
		["broadcastLookon"] = {["func"]=cmd_broadcastLookon, ["isRet"]=false},
		
		["onUserGoldRecordChange"] = {["func"]=cmd_onUserGoldRecordChange, ["isRet"]=true},
		["onUserScoreNotify"] = {["func"]=cmd_onUserScoreNotify, ["isRet"]=true},
		["userReady"] = {["func"]=cmd_userReady, ["isRet"]=true},
		["userLookon"] = {["func"]=cmd_userLookon, ["isRet"]=true},
		["removeOldLookonUser"] = {["func"]=removeOldLookonUser, ["isRet"]=true},
		["kickUser"] = {["func"]=cmd_kickUser, ["isRet"]=true},
		
		["getSitUserMinScore"] = {["func"]=getSitUserMinScore, ["isRet"]=true},
		["usersLookOnInfo"] = {["func"]=cmd_usersLookOnInfo, ["isRet"]=true},
		["reloadTableFrameConfig"] = {["func"]=cmd_reloadTableFrameConfig, ["isRet"]=false},
		["sendSystemMessage"] = {["func"]=cmd_sendSystemMessage, ["isRet"]=false},

		["NotifyWorldBossStart"] = {["func"]=cmd_NotifyWorldBossStart, ["isRet"]=false},
		["NotifyWorldBossEnd"] = {["func"]=cmd_NotifyWorldBossEnd, ["isRet"]=false},
		["SaveInvalidGunGold"] = {["func"]=cmd_SaveInvalidGunGold, ["isRet"]=true},
		["NotifyWorldBossTime"] = {["func"]=cmd_NotifyWorldBossTime, ["isRet"]=false},
		["ChangeTaskGoodsCount"] = {["func"]=cmd_ChangeTaskGoodsCount, ["isRet"]=false},
		["CompleteTask"] = {["func"]=cmd_CompleteTask, ["isRet"]=false},
		["TaskSynchronizationTime"] = {["func"]=cmd_TaskSynchronizationTime, ["isRet"]=false},
		["setControlRateConfig"] = {["func"]=cmd_setControlRateConfig, ["isRet"]=false},
		["getTableUserIdList"] = {["func"]=cmd_getTableUserIdList, ["isRet"]=true},
		["LockRoom"] = {["func"]=cmd_LockRoom, ["isRet"]=true},
	},
	initFunc = function()
		resourceResolver.init()
	end,
}

commonServiceHelper.createService(conf)
