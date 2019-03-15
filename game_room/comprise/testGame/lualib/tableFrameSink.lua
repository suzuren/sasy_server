local skynet = require "skynet"
local arc4 = require "arc4random"
local ServerUserItem = require "sui"
local GS_CONST = require "define.gsConst"
local FISH_CONST = require "fish.lualib.const"
local COMMON_CONST = require "define.commonConst"
local timerUtility = require "utility.timer"
local currencyUtility = require "utility.currency"
local pathUtility = require "utility.path"
local mysqlutil = require "mysqlutil"
local resourceResolver = require "resourceResolver"
local addressResolver = require "addressResolver"
require "utility.table"

local FENG_HUANG_LIVE_TIME = 60

local function isBasicRoom(nodeID)
	-- 判读是否是新手场
	return nodeID == 1100
end

local function isThousandRoom(nodeID)
	return nodeID == 1101
end

local function isWanRoom(nodeID)
	return nodeID == 1102
end

--是否是奖金鱼id
local function isRewardGoldFish(kindId)
	if kindId == 16 or kindId == 18 or kindId == 19 or kindId == 20 or kindId == 26 or kindId == 27 or kindId == 28 then
		return true
	end

	return false
end

local function isBossFish(kindId)
	if kindId == 20 or kindId == 27 or kindId == 28 then
		return true
	end

	return false
end

local function isBaoTuFish(kindId)
	if kindId == 16 or kindId == 17 or kindId == 18 or kindId == 19 or kindId == 20 or kindId == 26 or kindId == 27 or kindId == 28 then
		return true
	end

	return false
end	

local function isSpecialFish(kindId)
	if 21 <= kindId and kindId <= 25 then
		return true
	end

	return false
end

local function isHuoDongFish(kindId)
	return kindId <= 13
end

local function isHuoDongTime()
	local nowDate = tonumber(os.date("%Y%m%d%H%M%S", os.time()))
	return COMMON_CONST.HUO_DONG_TIME.START_TIME <= nowDate and nowDate <= COMMON_CONST.HUO_DONG_TIME.END_TIME
end

local function isWaZiFish(kindId)
	return kindId == 34 or kindId == 35
end

local volcano
local _data = {
	fishID = 0,
	tableFrame = nil,
	config = nil,
	chairID2GameData = {},
	timerIDHash = {},
	fishTypeRefreshTime = {},
	fishTraceHash = {},				--	TableFrameSink::active_fish_trace_vector_
	sweepFishHash = {},
	
	hasRealUser = false,
	isSpecialScene = false,
	specialSceneEndTick = 0,
	currentScene = nil,
	nextScene = nil,
	sceneCnt = 0,					-- TableFrameSink::system_cene_change_time
	normalSceneCnt = 0,				-- TableFrameSink::normal_scene_change_time
	
	mermaidClothesID = 0,
	mermaidClothesResetDate = nil,
	
	pipelineDataHash = {},

	lockFishList = {},--锁定大鱼列表

	bFirstPlayerEnter = true,
	bWorldBossScene = false,	--是否是世界boss场景
	m_iWorldBossLocalPool = 0,	--世界boss无效炮
	worldBossStartTime = 0,		--世界boss开始时间
	rewardPool = 0,				--世界boss奖励金币
	bSpecial = false,			--是否是定时刷的世界boss
	worldBoss = {
		index = 0,
		userID = 0,
		addRate = 0,
		addRateTime = 0,
		worldBossAddRateTime = 0,
		lastKillWorldBossUserId = 0,--上次击杀世界boss玩家id
	},
	fengHuang = {
		startTime = 0,				--凤凰开始时间
		elapseTime = 0,				--凤凰进过了多久了
		bFengHuangScene = false,	--当前是否有凤凰
		fengHuangGunCount = 0,		--凤凰打炮统计
		fengHuangPoolGold = 0,		--凤凰奖励
		minPaoMult = 0,				--打凤凰鱼的最低炮倍
	},

	taskFish = {
		startTime = 0,			--任务鱼开始时间
		taskId	  = 0,			--任务id
	},
	bFishScene = false,			--是否是鱼阵场景
	rateConfig = {},			--玩家个人概率控制
	redPacket = {
		redPacketRank = {},
		redPacketKillRecord = {},
	},
}
local _criticalSection

local function cleanUp()
	_data.bFirstPlayerEnter = true
	_data.bWorldBossScene = false
	_data.m_iWorldBossLocalPool = 0
	_data.worldBossStartTime = 0
	_data.rewardPool = 0
	_data.bSpecial = false
	_data.worldBoss.index = 0
	_data.worldBoss.userID = 0
	_data.worldBoss.addRate = 0
	_data.fengHuang.startTime = 0
	_data.fengHuang.elapseTime = 0
	_data.fengHuang.bFengHuangScene = false
	_data.fengHuang.fengHuangGunCount = 0
	_data.fengHuang.fengHuangPoolGold = 0
	_data.taskFish.startTime = 0
	_data.taskFish.taskId = 0
	_data.bFishScene = false
	_data.redPacket.redPacketRank = {}
	_data.redPacket.redPacketKillRecord = {}
end

local function isJieRiTime()
	local nowDate = tonumber(os.date("%Y%m%d%H%M%S", os.time()))
	return _data.config.jieRiTime.startTime <= nowDate and nowDate <= _data.config.jieRiTime.endTime
end

--红包鱼阵时间
local function redPacketFishSceneTime()
	local nowDate = tonumber(os.date("%Y%m%d%H%M%S", os.time()))
	return _data.config.redPacketTime.startTime <= nowDate and nowDate <= _data.config.redPacketTime.endTime
end

local function getGameDataItem(chairID)
	return _data.chairID2GameData[chairID]
end

local function updateLockFishID(chairID, fishID)
	--更新用户锁定大鱼列表
	_data.lockFishList[chairID] = fishID
end

local function getRandomLockFishID()
	-- 获取玩家锁定大鱼
	local fishIDlist = {}
	local fishid = 0
	for _, _fishid in ipairs(_data.lockFishList) do
		if _fishid ~= 0 then
			table.insert(fishIDlist, _fishid)
		end
	end
	if #(fishIDlist) > 0 then
		local fishK = arc4.random(1, #(fishIDlist))
		fishid = fishIDlist[fishK]
	end
	return fishid
end

local function androidCanLockFish()
	-- 机器人是否可以锁定大鱼
	local index = arc4.random(1, 100)
	if index <= 80 then
		return true
	end
	return false
end

local function createGameDataItem(score)
	return {
		bulletID = 0,
		bulletCompensate = 0,
		bulletInfoHash = {},
		
		isScoreLocked = false,
		fishScore = score,
		countedFishScore = score,
		additionalCredit = {
			score = 0,
			present = 0,
			gift = 0,
		},
		
		enterTime = math.floor(skynet.time()),
		netLose = 0,

		totalScore = 0,--累计捕鱼分数
		totalPresent = 0,--累计获得礼券
		recordScore = 0,--已记录分数
		recordPresent = 0,--已记录礼券

		isPayUser = false,--是否是充值用户
		rmbGold = 0,	--充值的金币
		openBoxSumGold = 0,	--开启宝箱获得的金币
		iWorldBossGold = 0,	--世界boss期间打的炮
		taskFishInfo = {	--任务鱼
			goalInfo = {},
			rewardList = {},
			fishCount = 0,
		},		
	}
end


local function broadcastUserExchangeScore(chairID)
	local gameData = getGameDataItem(chairID)
	
	local pbParser = resourceResolver.get("pbParser")
	local packetStr = skynet.call(pbParser, "lua", "encode", 0x020007, {
		chairID=chairID,
		fishScore=gameData.fishScore,
	}, true)
	if packetStr then
		_data.tableFrame.broadcastTable(packetStr)
		_data.tableFrame.broadcastLookon(packetStr)
	end
end

local function getNewFishID()
	_data.fishID = _data.fishID + 1
	if _data.fishID > 0xffffffff then
		_data.fishID = 1
	end
	return _data.fishID
end

local function createFishTraceItem(fishKind, buildTick)
	if (fishKind == 29 or fishKind == 33) and _data.worldBossStartTime ~= 0 then
		buildTick = buildTick - (os.time() - _data.worldBossStartTime)*GS_CONST.TIMER.TICK_STEP
	end

	local fishTraceItem = {
		fishKind=fishKind,
		buildTick=buildTick,
		fishID=getNewFishID(),
	}
	_data.fishTraceHash[fishTraceItem.fishID] = fishTraceItem
	return fishTraceItem
end

local function clearFishTrace(isForce,isWorldBoss)
	if isForce then
		if isWorldBoss ~= nil then
			for fishID, traceItem in pairs(_data.fishTraceHash) do
				if traceItem.fishKind ~= 30 then
					_data.fishTraceHash[fishID] = nil
				end
			end
		else
			_data.fishTraceHash = {}
		end
	else
		local nowTick = skynet.now()
		for fishID, traceItem in pairs(_data.fishTraceHash) do
			if traceItem.buildTick + FISH_CONST.FISH_LIVE_TICKS <= nowTick then
				_data.fishTraceHash[fishID] = nil
			end
		end
	end
end

local function getPlayerCount()
	local cnt = 0
	for _, _ in pairs(_data.chairID2GameData) do
		cnt = cnt + 1
	end
	return cnt
end

local function getPlayerTryScore()
	return _data.config.tryScore
end

local function checkRealUser()
	_data.hasRealUser = false
	for chairID, _ in pairs(_data.chairID2GameData) do
		local userItem = _data.tableFrame.getUserItem(chairID)
		if userItem then
			local userAttr = ServerUserItem.getAttribute(userItem, {"isAndroid"})
			if not userAttr.isAndroid then
				_data.hasRealUser = true
				break
			end
		end
	end
end

local function onActionUserSitDown(chairID, userItem, isLookon)
	if isLookon then
		return;
	end
	
	local userAttr = ServerUserItem.getAttribute(userItem, {"score", "isAndroid", "userID", "platformID"})
	
	local score = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "GetItemCount",userAttr.userID,
	 			COMMON_CONST.ITEM_ID.ITEM_ID_GOLD)
	 
	_data.chairID2GameData[chairID] = createGameDataItem(score)
	--非机器人时，获取玩家累计获得的金币和礼券
	if not userAttr.isAndroid then
		local sql = string.format("call kfrecorddb.sp_record_user_fish_score_present(%d, %d, %d)",userAttr.userID, 0, 0)
		local dbConn = addressResolver.getMysqlConnection()
		local rows = skynet.call(dbConn, "lua", "call", sql)
		local gameData = getGameDataItem(chairID)
		gameData.totalScore = tonumber(rows[1].Score)
		gameData.totalPresent = tonumber(rows[1].Present)
		gameData.recordScore = tonumber(rows[1].Score)
		gameData.recordPresent = tonumber(rows[1].Present)

		--判断是否是付费用户
		local sql = string.format("SELECT score FROM `kfrecorddb`.`UserPayScore` where platformID = %d", userAttr.platformID)
		local dbConn = addressResolver.getMysqlConnection()
		local rows = skynet.call(dbConn, "lua", "query", sql)
		if rows[1] ~= nil then
			gameData.isPayUser = true
			gameData.rmbGold = rows[1].score
		end

		local sql = string.format("SELECT SumGold FROM `kfrecorddb`.`t_record_gold_by_use_box` where UserId=%d",userAttr.userID)
		local dbConn = addressResolver.getMysqlConnection()
		local rows = skynet.call(dbConn, "lua", "query", sql)
		if rows[1] ~= nil then
			gameData.openBoxSumGold = rows[1].SumGold
		end
	end
	
	if _data.tableFrame.getGameStatus() == GS_CONST.GAME_STATUS.FREE then
		_data.tableFrame.startGame()
	end	
	
	if (not _data.hasRealUser) and (not userAttr.isAndroid) then
		_data.hasRealUser = true
	end
end

local function buildFishTrace(fishCount, fishKindStart, fishKindEnd)
	local buildTick = skynet.now()
	local pbItemList = {}
	for i=1, fishCount do
		local fishTraceItem = createFishTraceItem(arc4.random(fishKindStart, fishKindEnd), buildTick)
		
		local pbItem = {
			fishKind=fishTraceItem.fishKind,
			fishID=fishTraceItem.fishID,
		}
		
		local pathID = pathUtility.getPathID(FISH_CONST.PATH_TYPE.PT_SINGLE, buildTick)
		if pathID == nil then
			skynet.error(string.format("%s.buildFishTrace: 找不到空闲的路径", SERVICE_NAME))
			break
		end

		pbItem.pathID = pathID
		table.insert(pbItemList, pbItem)
	end

	if #pbItemList > 0 and fishKindStart ~= 29 and fishKindStart ~= 33 then
		local pbParser = resourceResolver.get("pbParser")
		local packetStr = skynet.call(pbParser, "lua", "encode", 0x020010, {list=pbItemList}, true)
		if packetStr then
			_data.tableFrame.broadcastTable(packetStr)
			_data.tableFrame.broadcastLookon(packetStr)
		end
	end
end

local function doPipeline(pipelineType)
	_data.timerIDHash[pipelineType] = nil
	local pipelineData = _data.pipelineDataHash[pipelineType]
	if not pipelineData then
		skynet.error(string.format("%s.doPipeline: 找不到pipelineData %s", SERVICE_NAME, pipelineType))
		return
	end
	local nowTick = skynet.now()
	if pipelineData.pathID==nil then
		local pathID = pathUtility.getPathID(FISH_CONST.PATH_TYPE.PT_PIPELINE, nowTick)
		if pathID == nil then
			skynet.error(string.format("%s.doPipeline: %s 不能生成pathID", SERVICE_NAME, pipelineType))
			return
		end
		pipelineData.pathID = pathID
	end

	local fishlist = {}
	for i=1, pipelineData.fishNum do
		local fishTraceItem = createFishTraceItem(pipelineData.fishKind, nowTick)
		local pbItem = {
			fishKind=fishTraceItem.fishKind,
			fishID=fishTraceItem.fishID,
			pathID=pipelineData.pathID,
		}
		table.insert(fishlist, pbItem)
	end

	local pbParser = resourceResolver.get("pbParser")
	local packetStr = skynet.call(pbParser, "lua", "encode", 0x020010, {list=fishlist}, true)
	if packetStr then
		_data.tableFrame.broadcastTable(packetStr)
		_data.tableFrame.broadcastLookon(packetStr)
	end

	_data.pipelineDataHash[pipelineType] = nil
end

local function startPipeline(pipelineType)
	if _data.pipelineDataHash[pipelineType]~=nil then
		return
	end
	
	local fishKind, fishNum
	if pipelineType=="pipeline1" then
		fishKind = arc4.random(0, 1)
		fishNum = arc4.random(5, 6)
	elseif pipelineType=="pipeline2" then
		fishKind = arc4.random(2, 3)
		fishNum = arc4.random(3, 4)
	elseif pipelineType=="pipeline3" then
		fishKind = arc4.random(4, 6)
		fishNum = arc4.random(2, 4)
	elseif pipelineType=="pipeline4" then
		fishKind = arc4.random(7, 8)
		fishNum = arc4.random(2, 4)
	elseif pipelineType=="pipeline5" then
		fishKind = arc4.random(8, 9)
		fishNum = arc4.random(2, 4)
	end
	
	_data.pipelineDataHash[pipelineType]={
		fishKind = fishKind,
		fishNum = fishNum,
	}
	
	doPipeline(pipelineType)
end

local function _onTimerBuildFishTrace()
	local playerCount = getPlayerCount()
	if playerCount<=0 or playerCount>=7 then
		return
	end
	
	local serverConfig = _data.tableFrame.getServerConfig()
	local nowTick = skynet.now()
	pathUtility.checkPathStatus(FISH_CONST.PATH_TYPE.PT_SINGLE, nowTick)
	pathUtility.checkPathStatus(FISH_CONST.PATH_TYPE.PT_PIPELINE, nowTick)
	
	if not isWanRoom(serverConfig.NodeID) then
		for fishType, intervalArray in pairs(_data.config.pipelineBuildInterval) do
			local interval = intervalArray[playerCount] * 100
			if nowTick - _data.fishTypeRefreshTime[fishType] >= interval then
				if pathUtility.isPathAllUsed(FISH_CONST.PATH_TYPE.PT_PIPELINE) then
					break
				end
				
				startPipeline(fishType)
				_data.fishTypeRefreshTime[fishType] = nowTick
			end
		end
	end
	
	for fishType, intervalArray in pairs(_data.config.singleBuildInterval) do
		local interval = intervalArray[playerCount] * 100
		if nowTick - _data.fishTypeRefreshTime[fishType] >= interval then
			if pathUtility.isPathAllUsed(FISH_CONST.PATH_TYPE.PT_SINGLE) then
				break
			end
			
			if fishType=="smallFish" then
				if _data.bFirstPlayerEnter and not isWanRoom(serverConfig.NodeID) then
					_data.bFirstPlayerEnter = false
				 	buildFishTrace(4 + arc4.random(0, 7), 0, 9)
				 end
			elseif fishType=="mediumFish" then
				if isWanRoom(serverConfig.NodeID) then
					buildFishTrace(1 + arc4.random(1, 3), 10, 13)
				else
					buildFishTrace(1 + arc4.random(0, 1), 10, 13)
				end
			elseif fishType=="goldFish" then
				buildFishTrace(1, 14, 15)
			elseif fishType=="fish16" then
				buildFishTrace(1, 16, 16)
			elseif fishType=="fish17" then
				buildFishTrace(1, 17, 17)
			elseif fishType=="fish18" then
				buildFishTrace(1, 18, 18)
			elseif fishType=="fish19" then
				buildFishTrace(1, 19, 19)
			elseif fishType=="fish20" then
				-- 每一秒钟倍数+1，的功能可以在TableFrameSink::OnSubBigFishNetCatchFish里面实现，不需要定时器的
				if isBasicRoom(serverConfig.NodeID) then
					buildFishTrace(1, 20, 20)
				end
			elseif fishType=="bomb" then
				buildFishTrace(1, 22, 22)
			elseif fishType=="superBomb" then
				buildFishTrace(1, 23, 23)
			elseif fishType=="lockBomb" then
				if not isWanRoom(serverConfig.NodeID) then
					buildFishTrace(1, 21, 21)
				end
			elseif fishType=="tripleDouble" then
				buildFishTrace(2, 24, 25)
			elseif fishType=="xiaojinglong" then
				if not isJieRiTime() then
					buildFishTrace(1, 26, 26)
				end
			elseif fishType=="guyu" then
				if isThousandRoom(serverConfig.NodeID) then
					buildFishTrace(1, 27, 27)
				end
			elseif fishType=="jixiexia" then
				if isWanRoom(serverConfig.NodeID) then
					buildFishTrace(1, 28, 28)
				end
			elseif fishType=="nanGuaYu_1" then
				if isJieRiTime() then
					buildFishTrace(1, 36, 36)
				end
			elseif fishType=="nanGuaYu_2" then
				if isJieRiTime() then
					buildFishTrace(1, 37, 37)
				end
			elseif fishType=="big4" then
				--buildFishTrace(2, 27, 29)
			elseif fishType=="fishKing" then
				--buildFishTrace(1, 30, 39)			
			elseif fishType=="goldBox" then
				--buildFishTrace(1, 41, 41)
			elseif fishType=="silverBox" then
				--buildFishTrace(1, 42, 42)
			elseif fishType=="copperBox" then
				--buildFishTrace(1, 43, 43)
			elseif fishType == "smallBox" then
				--buildFishTrace(1, 44, 44)
			elseif fishType == "BigBox" then
				--buildFishTrace(1, 45, 45)
			elseif fishType == "PokerFish" then
				buildFishTrace(1, 99, 103)
			else
				skynet.error(string.format("unrecognized fishtype: %s", tostring(fishType)))
			end
		
			_data.fishTypeRefreshTime[fishType] = nowTick
		end
	end
end

local function onTimerBuildFishTrace()
	_criticalSection(_onTimerBuildFishTrace)
end

local function startBuildFishTraceTimer()
	local nowTick = skynet.now()
	for fishType, _ in pairs(_data.config.singleBuildInterval) do
		_data.fishTypeRefreshTime[fishType] = nowTick
	end
	for fishType, _ in pairs(_data.config.pipelineBuildInterval) do
		_data.fishTypeRefreshTime[fishType] = nowTick
	end	
	if _data.timerIDHash.buildFishTrace then
		timerUtility.clearTimer(_data.timerIDHash.buildFishTrace)
		_data.timerIDHash.buildFishTrace = nil
	end
	_data.timerIDHash.buildFishTrace = timerUtility.setInterval(onTimerBuildFishTrace, FISH_CONST.TIMER.TICKSPAN_BUILD_FISH_TRACE)
end

local function stopBuildFishTraceTimer()
	if _data.timerIDHash.buildFishTrace then
		timerUtility.clearTimer(_data.timerIDHash.buildFishTrace)
		_data.timerIDHash.buildFishTrace = nil
	end
	
	for pipelineType, _ in pairs(_data.pipelineDataHash) do
		if _data.timerIDHash[pipelineType] then
			timerUtility.clearTimer(_data.timerIDHash[pipelineType])
		end
	end
	_data.pipelineDataHash = {}
end

local function sendSwitchScene(sceneKind, fishList)
	local pbParser = resourceResolver.get("pbParser")
	local packetStr = skynet.call(pbParser, "lua", "encode", 0x020003, {sceneKind=sceneKind, fishList=fishList}, true)
	if packetStr then
		_data.tableFrame.broadcastTable(packetStr)
		_data.tableFrame.broadcastLookon(packetStr)
	end
end

local function buildSceneKind100()
	_data.currentScene = FISH_CONST.SCENE_KIND.SCENE_KIND_100
	local bigFishMatrix = 
	{
			1,
		   2,2,
		  2,4,2,
		 2,2,2,2,
		7,7,7,7,7,
	   7,7,7,7,7,7,
	    7,7,7,7,7,
	     7,7,7,7,
		  7,7,7,
		    5,
		   5,5 	
	}
	local buildTick = skynet.now()
	local pbItemlist = {}
	for _, fishtype in ipairs(bigFishMatrix) do
		local fishTraceItem = createFishTraceItem(fishtype, buildTick)
		table.insert(pbItemlist, {fishID=fishTraceItem.fishID, fishKind=fishTraceItem.fishKind})
	end		
	sendSwitchScene(_data.currentScene, pbItemlist)
end

local function buildSceneKind101()
	_data.currentScene = FISH_CONST.SCENE_KIND.SCENE_KIND_101
	local allFishTypes = {16,15,15,17,15,15,19,16}

	local buildTick = skynet.now()
	local pbItemlist = {}
	for _, fishtype in ipairs(allFishTypes) do
		local fishTraceItem = createFishTraceItem(fishtype, buildTick)
		table.insert(pbItemlist, {fishID=fishTraceItem.fishID, fishKind=fishTraceItem.fishKind})
	end		
	sendSwitchScene(_data.currentScene, pbItemlist)
end

local function buildSceneKind102()
	_data.currentScene = FISH_CONST.SCENE_KIND.SCENE_KIND_102

	local allFishTypes ={9,9,15,3,3,9,9,3,3,16,9,9,3,3,15,9,9}

	local buildTick = skynet.now()
	local pbItemlist = {}

	for _, fishtype in ipairs (allFishTypes) do
		local fishTraceItem = createFishTraceItem(fishtype, buildTick)
		table.insert(pbItemlist, {fishID=fishTraceItem.fishID, fishKind=fishTraceItem.fishKind})
	end

	sendSwitchScene(_data.currentScene, pbItemlist)
end

local function buildSceneKind103()
	_data.currentScene = FISH_CONST.SCENE_KIND.SCENE_KIND_103

	local allFishTypes = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
						   2,2,2,2,2,2,2,2,
						   19,
						   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
						   2,2,2,2,2,2,2,2,
						   19}

	local buildTick = skynet.now()
	local pbItemlist = {}

	for _, fishtype in ipairs (allFishTypes) do
		local fishTraceItem = createFishTraceItem(fishtype, buildTick)
		table.insert(pbItemlist, {fishID=fishTraceItem.fishID, fishKind=fishTraceItem.fishKind})
	end

	sendSwitchScene(_data.currentScene, pbItemlist)
end

local function buildSceneKind104()
	_data.currentScene = FISH_CONST.SCENE_KIND.SCENE_KIND_104

	local allFishTypes ={17,7,7,7,7,7,7,7,7,7,7,7,7}

	local buildTick = skynet.now()
	local pbItemlist = {}

	for _, fishtype in ipairs (allFishTypes) do
		local fishTraceItem = createFishTraceItem(fishtype, buildTick)
		table.insert(pbItemlist, {fishID=fishTraceItem.fishID, fishKind=fishTraceItem.fishKind})
	end

	sendSwitchScene(_data.currentScene, pbItemlist)
end

local function buildSceneKind105()
	_data.currentScene = FISH_CONST.SCENE_KIND.SCENE_KIND_105

	local allFishTypes ={25,25,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24}

	local buildTick = skynet.now()
	local pbItemlist = {}

	for _, fishtype in ipairs (allFishTypes) do
		local fishTraceItem = createFishTraceItem(fishtype, buildTick)
		table.insert(pbItemlist, {fishID=fishTraceItem.fishID, fishKind=fishTraceItem.fishKind})
	end		

	sendSwitchScene(_data.currentScene, pbItemlist)
end

local function buildSceneKind106()
	_data.currentScene = FISH_CONST.SCENE_KIND.SCENE_KIND_106

	local allFishTypes ={18,14,14,14,14,6,6,6,6,6,6}

	local buildTick = skynet.now()
	local pbItemlist = {}

	for _, fishtype in ipairs (allFishTypes) do
		local fishTraceItem = createFishTraceItem(fishtype, buildTick)
		table.insert(pbItemlist, {fishID=fishTraceItem.fishID, fishKind=fishTraceItem.fishKind})
	end

	sendSwitchScene(_data.currentScene, pbItemlist)
end

local function buildSceneKind107()
	_data.currentScene = FISH_CONST.SCENE_KIND.SCENE_KIND_107

	local allFishTypes ={15,15,8,8,8,11,11,11,12,12,12,9,9,9,24,24,24,24,24,24,25}

	local buildTick = skynet.now()
	local pbItemlist = {}

	for _, fishtype in ipairs (allFishTypes) do
		local fishTraceItem = createFishTraceItem(fishtype, buildTick)
		table.insert(pbItemlist, {fishID=fishTraceItem.fishID, fishKind=fishTraceItem.fishKind})
	end

	sendSwitchScene(_data.currentScene, pbItemlist)
end

local function buildSceneKind108()
	_data.currentScene = FISH_CONST.SCENE_KIND.SCENE_KIND_108

	local allFishTypes ={16,18,12,16,25,25,12,16}

	local buildTick = skynet.now()
	local pbItemlist = {}

	for _, fishtype in ipairs (allFishTypes) do
		local fishTraceItem = createFishTraceItem(fishtype, buildTick)
		table.insert(pbItemlist, {fishID=fishTraceItem.fishID, fishKind=fishTraceItem.fishKind})
	end

	sendSwitchScene(_data.currentScene, pbItemlist)
end

local function buildSceneKind109()
	_data.currentScene = FISH_CONST.SCENE_KIND.SCENE_KIND_109

	local allFishTypes = {}
	local n = arc4.random(1,7)
	for i = 1, 7 do
		if i == n then
			table.insert(allFishTypes,34)
		else
			table.insert(allFishTypes,35)
		end
	end

	local buildTick = skynet.now()
	local pbItemlist = {}

	for _, fishtype in ipairs (allFishTypes) do
		local fishTraceItem = createFishTraceItem(fishtype, buildTick)
		table.insert(pbItemlist, {fishID=fishTraceItem.fishID, fishKind=fishTraceItem.fishKind})
	end

	sendSwitchScene(_data.currentScene, pbItemlist)
end

local function calcScore(chairID, ignoreGameRecord)
	local gameData = getGameDataItem(chairID)
	if gameData == nil then
		return
	end
	local tagScoreInfo = gameData.additionalCredit
	gameData.additionalCredit = {
		score=0,
		present=0,
		gift = 0,
	}
	
	--玩家捕鱼获得分数和礼券
	local userItem = _data.tableFrame.getUserItem(chairID)
	if userItem then
		local userAttr = ServerUserItem.getAttribute(userItem, {"isAndroid", "userID"})
		local addscore = gameData.totalScore-gameData.recordScore
		local addpresent = gameData.totalPresent-gameData.recordPresent
		local serverConfig = _data.tableFrame.getServerConfig()
		if not userAttr.isAndroid and (addscore > 0 or addpresent > 0) and (isBasicRoom(serverConfig.NodeID) or gameData.isPayUser) then
			local sql = string.format(
				"call kfrecorddb.sp_record_user_fish_score_present(%d, %d, %d)",userAttr.userID, addscore, addpresent
			)
			local dbConn = addressResolver.getMysqlConnection()
			rows = skynet.call(dbConn, "lua", "call", sql)
			gameData.recordScore = tonumber(rows[1].Score)
			gameData.recordPresent = tonumber(rows[1].Present)
		end
	end

	local bulletCompensate = gameData.bulletCompensate
	gameData.fishScore = gameData.fishScore --+ bulletCompensate
	gameData.bulletCompensate = 0
	
	local serverType = _data.tableFrame.getServerConfig().ServerType
	if (serverType & GS_CONST.GAME_GENRE.EDUCATE)==0 and (serverType & GS_CONST.GAME_GENRE.MATCH)==0 then
		tagScoreInfo.score = tagScoreInfo.score + gameData.fishScore - gameData.countedFishScore 
	end
	
	gameData.countedFishScore = gameData.fishScore
	
	if tagScoreInfo.score~=0 or tagScoreInfo.present~=0 or tagScoreInfo.gift~=0 then
		local gamePlayTime
		if (serverType & GS_CONST.GAME_GENRE.EDUCATE)==0 and (serverType & GS_CONST.GAME_GENRE.MATCH)==0 then
			if tagScoreInfo.score > 0 then
				tagScoreInfo.type = GS_CONST.SCORE_TYPE.ST_WIN
				tagScoreInfo.medal = math.floor(tagScoreInfo.score/1000)   --这是经验
			elseif tagScoreInfo.score < 0 then
				tagScoreInfo.type = GS_CONST.SCORE_TYPE.ST_LOSE
			else
				tagScoreInfo.type = GS_CONST.SCORE_TYPE.ST_DRAW
			end
			local currentTS = math.floor(skynet.time())
			gamePlayTime = currentTS - gameData.enterTime			-- experience
			gameData.enterTime = currentTS
		else
			tagScoreInfo.type = GS_CONST.SCORE_TYPE.ST_PRESENT
			gamePlayTime = 0
		end
		_data.tableFrame.writeUserScore(chairID, tagScoreInfo, gamePlayTime, ignoreGameRecord);
	end
end

local function sendGameConfig(agent)	
	local pbObj = {
		bulletMultipleMin = _data.config.cannonMultiple.min,
		bulletMultipleMax = _data.config.cannonMultiple.max,
		bombRangeWidth = _data.config.bombRange.width,
		bombRangeHeight = _data.config.bombRange.height,
		fishList = {},
		bulletList = {},
	}
	
	for fishKind, fishItem in pairs(_data.config.fishHash) do
		table.insert(pbObj.fishList, {
			kind = fishKind,
			multiple = fishItem.multiple,
			speed = fishItem.speed,
			boundingBoxWidth = fishItem.boundingBox[1],
			boundingBoxHeight = fishItem.boundingBox[2],
		})
	end
	
	for bulletKind, bulletItem in pairs(_data.config.bulletHash) do
		table.insert(pbObj.bulletList, {
			kind = bulletKind,
			speed = bulletItem.speed,
		})
	end
	
	skynet.send(agent, "lua", "forward", 0x020005, pbObj)
end

local function sendGameScene(agent)
	local pbObj = {
		isSpecialScene = _data.isSpecialScene,
		scoreList = {},
	}
	if _data.isSpecialScene then
		pbObj.specialSceneLeftTime = math.floor( (_data.specialSceneEndTick - skynet.now()) / 100 )
	end
	
	for chairID, userData in pairs(_data.chairID2GameData) do
		table.insert(pbObj.scoreList, {chairID=chairID, fishScore=userData.fishScore})
	end
	
	skynet.send(agent, "lua", "forward", 0x020006, pbObj)
end

local function notifyUserTaskFishInfo(ChairID)
	if _data.taskFish.taskId ~= 0 then
		local taskInfo = skynet.call(addressResolver.getAddressByServiceName("GS_model_task"), "lua", "GetTaskInfoByTaskId", _data.taskFish.taskId)
		local re = {
			taskType = taskInfo.taskType,
			taskID = taskInfo.taskId,
			code = 0,
			limitFashShoot = taskInfo.limitFashShoot,
			limitAutoShoot = taskInfo.limitAutoShoot,
			limitFortLevel = taskInfo.limitFortLevel,
			limitFortMulti = taskInfo.limitFortMulti,
			taskGoodsInfoList = {},
			taskRewardGoodsInfoList = taskInfo.rewardList,
			taskLeftTime = COMMON_CONST.TASK_FISH_TIME - (os.time()-_data.taskFish.startTime),
		}

		for k, v in pairs(taskInfo.goalList) do
			local goalTemp = {
				goodsID = v.goalId,
				allGoodsCount = v.goalCount,
				currentGoodsCount = 0
			}
			table.insert(re.taskGoodsInfoList,goalTemp)
		end

		if ChairID ~= nil then
			local gameData = getGameDataItem(ChairID)
			gameData.taskFishInfo.goalInfo = taskInfo.goalList
			gameData.taskFishInfo.rewardList = taskInfo.rewardList
			gameData.taskFishInfo.fishCount = 0
			local userItem = _data.tableFrame.getUserItem(ChairID)
			if userItem then
				local attr = ServerUserItem.getAttribute(userItem, {"agent","userID","tableID"})
				if attr.agent ~= 0 then
					skynet.send(attr.agent,"lua","forward",0x010800,re)
				end
			end
		else
			for chairID, v in pairs(_data.chairID2GameData) do
				local userItem = _data.tableFrame.getUserItem(chairID)
				if userItem then

					for kk, vv in pairs(taskInfo.goalList) do
						local goalTemp = {
							goalId = vv.goalId,
							goalCount = vv.goalCount,
						}
						table.insert(v.taskFishInfo.goalInfo,goalTemp)
					end

					--v.taskFishInfo.goalInfo = taskInfo.goalList
					v.taskFishInfo.rewardList = taskInfo.rewardList
					v.taskFishInfo.fishCount = 0
					local attr = ServerUserItem.getAttribute(userItem, {"agent","userID","tableID"})
					if attr.agent ~= 0 then
						skynet.send(attr.agent,"lua","forward",0x010800,re)
					end
				end
			end
		end
	end
end

local function notifyUserTaskFishEnd(bComplete)
	local info = {
		endType = 0,
		rankList = {},
		taskType = 2,
	}

	if bComplete then
		info.endType = 1
	end

	for chairID, v in pairs(_data.chairID2GameData) do
		local infor = {
			chairID = chairID,
			score = v.taskFishInfo.fishCount,
			rankId = 0,
		}

		table.insert(info.rankList,infor)

		v.taskFishInfo.goalInfo = {}
		v.taskFishInfo.rewardList = {}
		v.taskFishInfo.fishCount = 0
	end

	table.sort(info.rankList, function(a, b) return a.score > b.score end)
	for k, v in pairs(info.rankList) do
		v.rankId = k
	end

	for chairID, v in pairs(_data.chairID2GameData) do
		local userItem = _data.tableFrame.getUserItem(chairID)
		if userItem then
			local attr = ServerUserItem.getAttribute(userItem, {"agent","userID"})
			if attr.agent ~= 0 then
				skynet.send(attr.agent,"lua","forward",0x010804,info)
			end
		end
	end

	_data.taskFish.taskId = 0
end

local function notifyTaskFishEnd()
	_criticalSection(notifyUserTaskFishEnd)
end

local function NotifyTaskFishRankInfo()
	if _data.taskFish.taskId ~= 0 then
		local rankInfo = {}
		for chairID, v in pairs(_data.chairID2GameData) do
			local info = {
				chairID = chairID,
				score = v.taskFishInfo.fishCount,
				rankId = 0,
			}
			table.insert(rankInfo,info)
		end

		table.sort(rankInfo, function(a, b) return a.score > b.score end)
		for k, v in pairs(rankInfo) do
			v.rankId = k
		end

		local pbParser = resourceResolver.get("pbParser")
		local packetStr = skynet.call(pbParser, "lua", "encode", 0x010803, {rankList=rankInfo}, true)
		if packetStr then
			_data.tableFrame.broadcastTable(packetStr)
			_data.tableFrame.broadcastLookon(packetStr)
		end
	end
end

local function checkFlushTaskFish()
	local tableID = _data.tableFrame.getTableID()
	local serverConfig = _data.tableFrame.getServerConfig()
	if isThousandRoom(serverConfig.NodeID) then
		local nowTick = os.time()
		if _data.taskFish.taskId == 0 then
			if nowTick - _data.taskFish.startTime > 60*30 then
				local iRandRate = arc4.random(1,100)
				if iRandRate <= 30 and getPlayerCount() >= 2 then
					_data.taskFish.startTime = nowTick
					_data.timerIDHash.notifyTaskFishEnd = timerUtility.setTimeout(notifyTaskFishEnd,COMMON_CONST.TASK_FISH_TIME)
					_data.taskFish.taskId = skynet.call(addressResolver.getAddressByServiceName("GS_model_task"), "lua", "GetTaskIdByType", COMMON_CONST.TASK_TYPE.TASK_FISH)
					notifyUserTaskFishInfo()
					NotifyTaskFishRankInfo()
				end
			end
		end
	end
end

local function onActionUserGameOption(chairID, userItem, gameStatus)	
	if gameStatus==GS_CONST.GAME_STATUS.FREE or gameStatus==GS_CONST.GAME_STATUS.PLAY then
		local userAttr = ServerUserItem.getAttribute(userItem, {"isClientReady", "agent","userID","tableID","nickName","memberOrder"})
		if userAttr.isClientReady then
			sendGameConfig(userAttr.agent)
			if volcano then
				volcano.sendVolcanoPoolStatus(userAttr.agent)
			end
			
			sendGameScene(userAttr.agent)
			broadcastUserExchangeScore(chairID)

			notifyUserTaskFishInfo(chairID)
			NotifyTaskFishRankInfo()
		end
		getGameDataItem(chairID).bulletID = 0 

		local sql = string.format("SELECT * FROM kffishdb.t_char_title WHERE UserId = %d",userAttr.userID)
		local dbConn = addressResolver.getMysqlConnection()
		local rows = skynet.call(dbConn, "lua", "query", sql)
		if type(rows)=="table" then
			local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_SEND_TITLE
			local bLimit = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","CheckIsTimeLimit",userAttr.userID,limitId,10*60)
			if not bLimit then
				for _, row in ipairs(rows) do
					local info = {
						titleType = tonumber(row.TitleType),
						titleId = tonumber(row.TitleId),
						titleName = row.TitleName,
					}

					if info.titleType ~= 2 then
						local message = string.format("%s:%s:%s:%s:降临%s",userAttr.nickName,info.titleType,info.titleId,info.titleName,_data.tableFrame.getServerConfig().ServerName)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "sendTitleMessage",message)
					end
				end

				skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,limitId,1)
			end
		end

		_data.tableFrame.broadcastExperienceGunInfo()
		_data.tableFrame.broadcastPaoTaiLevel(userAttr.userID,chairID,userAttr.memberOrder)
		_data.tableFrame.notifyLockRoomStauts()
	end
end

local function _onTimerEndScene()
	_data.isSpecialScene = false
	startBuildFishTraceTimer()
	
	local packet = _data.tableFrame.getBufferedPacket(0x020002)
	_data.tableFrame.broadcastTable(packet)
	_data.tableFrame.broadcastLookon(packet)
	--省略了记录本次宝箱鱼阵吸的钱，因为没用

	--判断刷任务鱼
	if _data.bFishScene then
		checkFlushTaskFish()
		_data.bFishScene = false
	end

	if not _data.bWorldBossScene and _data.fengHuang.bFengHuangScene then
		_data.fengHuang.startTime = 0
		_data.fengHuang.elapseTime = 0
		_data.fengHuang.bFengHuangScene = false
		_data.fengHuang.fengHuangGunCount = 0
		_data.fengHuang.fengHuangPoolGold = 0
	end
end

local function onTimerEndScene()
	_criticalSection(_onTimerEndScene)
end

local function _onTimerSwitchScene()
	stopBuildFishTraceTimer()
	clearFishTrace(true)
	
	_data.bFishScene = true
	_data.isSpecialScene = true
	_data.specialSceneEndTick = skynet.now() + FISH_CONST.TIMER.TICKSPAN_SPECIAL_SCENE * GS_CONST.TIMER.TICK_STEP
	_data.timerIDHash.endScene = timerUtility.setTimeout(onTimerEndScene, FISH_CONST.TIMER.TICKSPAN_SPECIAL_SCENE)
	_data.sceneCnt = _data.sceneCnt + 1
	
	if _data.nextScene == FISH_CONST.SCENE_KIND.SCENE_KIND_100 then
		buildSceneKind100()
	elseif _data.nextScene == FISH_CONST.SCENE_KIND.SCENE_KIND_101 then
		buildSceneKind101()
	elseif _data.nextScene == FISH_CONST.SCENE_KIND.SCENE_KIND_102 then
		buildSceneKind102()
	elseif _data.nextScene == FISH_CONST.SCENE_KIND.SCENE_KIND_103 then
		buildSceneKind103()
	elseif _data.nextScene == FISH_CONST.SCENE_KIND.SCENE_KIND_104 then
		buildSceneKind104()
	elseif _data.nextScene == FISH_CONST.SCENE_KIND.SCENE_KIND_105 then
		buildSceneKind105()
	elseif _data.nextScene == FISH_CONST.SCENE_KIND.SCENE_KIND_106 then
		buildSceneKind106()
	elseif _data.nextScene == FISH_CONST.SCENE_KIND.SCENE_KIND_108 then
		buildSceneKind108()
	elseif _data.nextScene == FISH_CONST.SCENE_KIND.SCENE_KIND_109 then
		buildSceneKind109()
	end
	
	_data.normalSceneCnt = _data.normalSceneCnt + 1
	local n = _data.normalSceneCnt % 6
	if redPacketFishSceneTime() then
		n = _data.normalSceneCnt % 7
		if n==0 then
			_data.nextScene = FISH_CONST.SCENE_KIND.SCENE_KIND_101
		elseif n==1 then
			_data.nextScene = FISH_CONST.SCENE_KIND.SCENE_KIND_109
		elseif n==2 then
			_data.nextScene = FISH_CONST.SCENE_KIND.SCENE_KIND_107
		elseif n==3 then
			_data.nextScene = FISH_CONST.SCENE_KIND.SCENE_KIND_109
		elseif n==4 then
			_data.nextScene = FISH_CONST.SCENE_KIND.SCENE_KIND_102
		elseif n==5 then
			_data.nextScene = FISH_CONST.SCENE_KIND.SCENE_KIND_106
		elseif n==6 then
			_data.nextScene = FISH_CONST.SCENE_KIND.SCENE_KIND_108
		end
	else	
		if n==0 then
			_data.nextScene = FISH_CONST.SCENE_KIND.SCENE_KIND_101
		elseif n==1 then
			_data.nextScene = FISH_CONST.SCENE_KIND.SCENE_KIND_105
		elseif n==2 then
			_data.nextScene = FISH_CONST.SCENE_KIND.SCENE_KIND_103
		elseif n==3 then
			_data.nextScene = FISH_CONST.SCENE_KIND.SCENE_KIND_106
		elseif n==4 then
			_data.nextScene = FISH_CONST.SCENE_KIND.SCENE_KIND_108
		elseif n==5 then
			_data.nextScene = FISH_CONST.SCENE_KIND.SCENE_KIND_104
		end
	end
end

local function onTimerSwitchScene()
	_criticalSection(_onTimerSwitchScene)
end

local function _onTimerClearTrace()
	clearFishTrace(false)
end

local function onTimerClearTrace()
	_criticalSection(_onTimerClearTrace)
end

local function _onTimerWriteScore()
	for chairID, _ in pairs(_data.chairID2GameData) do
		calcScore(chairID)

		local userItem = _data.tableFrame.getUserItem(chairID)
		if userItem then
			local attr = ServerUserItem.getAttribute(userItem, {"userID"})
			skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "saveUserData",attr.userID)
		end

		if not _data.tableFrame.isDrawStarted() then
			-- 防止重入，如果游戏结束那么不需要
			break
		end
	end
end

local function onTimerWriteScore()
	_criticalSection(_onTimerWriteScore)
end

local function _onTimerLockTimeout()
	local packetStr = _data.tableFrame.getBufferedPacket(0x02000D)
	if packetStr then
		_data.tableFrame.broadcastTable(packetStr)
		_data.tableFrame.broadcastLookon(packetStr)
	end
	if not _data.isSpecialScene then--在非鱼阵时发送鱼
		startBuildFishTraceTimer()
	end
end

local function onTimerLockTimeout()
	_criticalSection(_onTimerLockTimeout)
end

local function _onTimerUploadWorldBossPollScore()
	if not _data.bWorldBossScene then
		if _data.m_iWorldBossLocalPool > 0 then
			local tempScore = _data.m_iWorldBossLocalPool
			_data.m_iWorldBossLocalPool = 0
			skynet.send(addressResolver.getAddressByServiceName("GS_model_tableManager"), "lua", "addWorldBossLocalPool", tempScore)
		end
	end

	if next(_data.redPacket.redPacketRank) then
		local data = _data.redPacket.redPacketRank
		skynet.send(addressResolver.getAddressByServiceName("GS_model_tableManager"), "lua", "addRedPacketInfo", data)
		_data.redPacket.redPacketRank = {}
	end

	if next(_data.redPacket.redPacketKillRecord) then
		local data = _data.redPacket.redPacketKillRecord
		skynet.send(addressResolver.getAddressByServiceName("GS_model_tableManager"), "lua", "AddRedPacketKillRecord", data)
		_data.redPacket.redPacketKillRecord = {}
	end
end

local function onTimerUploadWorldBossPollScore()
	_criticalSection(_onTimerUploadWorldBossPollScore)
end

local function SaveInvalidGunGold(chairID,userID)
	local gameData = getGameDataItem(chairID)
	local iGold = gameData.iWorldBossGold
	if iGold ~= 0 then
		skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userID,
			COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,iGold,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)

		gameData.iWorldBossGold = 0
		gameData.fishScore = gameData.fishScore + iGold
	end
end

local function onActionUserStandUp(chairID,userID)
	SaveInvalidGunGold(chairID,userID)

	calcScore(chairID)
	_data.chairID2GameData[chairID] = nil
	checkRealUser()

	NotifyTaskFishRankInfo()

	--保存数据
	--skynet.error(string.format("----------------------------StandUp----to----savedata-----------------------------------"))
	skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "saveUserData",userID)
end

local function onEventGameConclude()
	_data.timerIDHash = {}
	
	_data.pipelineDataHash = {}
	pathUtility.resetAll()
	
	clearFishTrace(true)
	_data.sweepFishHash = {}
	
	_data.nextScene = FISH_CONST.SCENE_KIND.SCENE_KIND_101
	_data.currentScene = _data.nextScene
	_data.isSpecialScene = false
	_data.hasRealUser = false
	_data.bFirstPlayerEnter = false
	if volcano then
		volcano.storeNetWin()
	end
	_data.lockFishList = {}

	cleanUp()
end

--外部积分变动通知游戏
local function onUserScoreNotify(chairID, userItem)
	local gameData = getGameDataItem(chairID)
	if gameData then
		local userAttr = ServerUserItem.getAttribute(userItem, {"score","userID"})
		
		local uncountedScore = gameData.fishScore - gameData.countedFishScore

		if userAttr.score + uncountedScore < 0 then
			skynet.error(string.format("-------外部通知金币改变为负数了----userid=%d,userScore=%d,fishScore=%d,countedFishScore=%d----------------------",userAttr.userID,userAttr.score,gameData.fishScore,gameData.countedFishScore))
		end

		gameData.fishScore = userAttr.score + uncountedScore
		gameData.countedFishScore = userAttr.score

		--背包
		--skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
		 --	COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,gameData.fishScore,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_CHANGE_GOLD,true,true)
		
		skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "AddItemRecord",userAttr.userID,
			COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,gameData.fishScore,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_CHANGE_GOLD)

		broadcastUserExchangeScore(chairID)
	end
end

local function onUserGoldRecordChange(chairID, userItem)
	local gameData = getGameDataItem(chairID)
	if gameData then
		local userAttr = ServerUserItem.getAttribute(userItem, {"userID", "platformID"})
		local sql = string.format("SELECT score FROM `kfrecorddb`.`UserPayScore` where platformID = %d", userAttr.platformID)
		local dbConn = addressResolver.getMysqlConnection()
		local rows = skynet.call(dbConn, "lua", "query", sql)
		if rows[1] ~= nil then
			gameData.isPayUser = true
			gameData.rmbGold = rows[1].score
		end

		sql = string.format("SELECT SumGold FROM `kfrecorddb`.`t_record_gold_by_use_box` where UserId=%d",userAttr.userID)
		local dbConn = addressResolver.getMysqlConnection()
		local rows = skynet.call(dbConn, "lua", "query", sql)
		if rows[1] ~= nil then
			gameData.openBoxSumGold = rows[1].SumGold
		end
	end
end	

-- 增加奖池积分，比如火山和个人纯输赢(系统赢、用户输为+)
local function addSystemScorePool(gameData, score, sspo)
	gameData.netLose = gameData.netLose + score
	if volcano and (not sspo or (sspo & FISH_CONST.SYSTEM_SCORE_POOL_OPERATION.SSPO_DO_NOT_CHANGE_VOLCANO)==0) then
		volcano.addNetWin(score) 
	end
end

local function flushFengHuang(bZhaoHuan)
	if not _data.fengHuang.bFengHuangScene and not bWorldBossScene then --世界boss优先凤凰
		local iRandRate = arc4.random(1,100)
		if iRandRate <= 100 or bZhaoHuan then

			stopBuildFishTraceTimer()
			clearFishTrace(true)
			_data.isSpecialScene = true

			if _data.timerIDHash.switchScene then
				timerUtility.clearTimer(_data.timerIDHash.switchScene)
				_data.timerIDHash.switchScene = nil
			end

			if _data.timerIDHash.endScene then
				timerUtility.clearTimer(_data.timerIDHash.endScene)
				_data.timerIDHash.endScene = nil
			end

			_data.specialSceneEndTick = skynet.now() + FENG_HUANG_LIVE_TIME * GS_CONST.TIMER.TICK_STEP
			_data.timerIDHash.endScene = timerUtility.setTimeout(onTimerEndScene, FENG_HUANG_LIVE_TIME)

			buildFishTrace(1, 30, 30)
			skynet.error(string.format("--------2------召唤凤凰------------------------------"))

			_data.fengHuang.bFengHuangScene = true
			_data.fengHuang.startTime = skynet.now()
		end
	end
end

local function fengHuangEnd()
	_data.fengHuang.startTime = 0
	_data.fengHuang.elapseTime = 0
	_data.fengHuang.bFengHuangScene = false
	_data.fengHuang.fengHuangGunCount = 0
	_data.fengHuang.fengHuangPoolGold = 0

	if _data.timerIDHash.endScene then
		timerUtility.clearTimer(_data.timerIDHash.endScene)
		_data.timerIDHash.endScene = nil
	end

	clearFishTrace(true)
	--timerUtility.setTimeout(onTimerEndScene, 1)
	_onTimerEndScene()
	_data.timerIDHash.switchScene = timerUtility.setInterval(onTimerSwitchScene,FISH_CONST.TIMER.TICKSPAN_SWITCH_SCENE)
end

local function pbUserFire(userItem, protocalData)
	local userAttr = ServerUserItem.getAttribute(userItem, {"chairID", "isAndroid", "agent", "userID","memberOrder"})
	local gameData = getGameDataItem(userAttr.chairID)
	
	if gameData.isScoreLocked then
--[[		
		skynet.send(userAttr.agent, "lua", "forward", 0xff0000, {
			type = COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_CHAT | COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_EJECT,
			msg = "您处于锁定状态暂时不能开炮",
		})
--]]
		return
	end
	
	gameData.bulletID = gameData.bulletID + 1

	if gameData.bulletID~=protocalData.bulletID then
		skynet.send(userAttr.agent, "lua", "forward", 0x020014,{},true)
		--skynet.error(string.format("[tableID=%d]子弹id不匹配: expect=%d got=%d", _data.tableFrame.getTableID(), gameData.bulletID, protocalData.bulletID))
		return
	end

	if _data.bWorldBossScene then
		if protocalData.bulletMultiple ~= 100 then
			--skynet.error(string.format("[tableID=%d]子弹倍数不正确1111 bulletMultiple=%d", _data.tableFrame.getTableID(), protocalData.bulletMultiple))
			return
		end
	elseif _data.fengHuang.bFengHuangScene then
		if protocalData.bulletMultiple ~= _data.fengHuang.minPaoMult then
			--skynet.error(string.format("[tableID=%d]子弹倍数不正确2222 bulletMultiple=%d", _data.tableFrame.getTableID(), protocalData.bulletMultiple))
			--return
		end
	else
		if protocalData.bulletMultiple < _data.config.cannonMultiple.min or protocalData.bulletMultiple > _data.config.cannonMultiple.max then
			--skynet.error(string.format("[tableID=%d]子弹倍数不正确3333 bulletMultiple=%d", _data.tableFrame.getTableID(), protocalData.bulletMultiple))
			return
		end
	end
	
	if gameData.fishScore < protocalData.bulletMultiple then
		if userAttr.isAndroid then
			_data.tableFrame.standUp(userItem)
		else
			--skynet.send(userAttr.agent, "lua", "forward", 0xff0000, {
			--	type = COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_CHAT | COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_EJECT,
			--	msg = "炮弹不足时可在[获取子弹]处购买子弹!",
			--})
		end
		return
	end
	--机器人开炮判断，在鱼阵出现一定时间间隔内允许机器人开炮
	if userAttr.isAndroid and _data.isSpecialScene then
		local specialSceneLeftTime = math.floor( (_data.specialSceneEndTick - skynet.now()) / GS_CONST.TIMER.TICK_STEP )
		if specialSceneLeftTime < 5 or specialSceneLeftTime > FISH_CONST.TIMER.TICKSPAN_SPECIAL_SCENE-10 then
			return
		end
	end

	if _data.bWorldBossScene then
		gameData.iWorldBossGold = gameData.iWorldBossGold + protocalData.bulletMultiple
	end

	if _data.fengHuang.bFengHuangScene then
		_data.fengHuang.fengHuangGunCount = _data.fengHuang.fengHuangGunCount + 1
		_data.fengHuang.fengHuangPoolGold = _data.fengHuang.fengHuangPoolGold + protocalData.bulletMultiple
	end

	gameData.fishScore = gameData.fishScore - protocalData.bulletMultiple

	if not _data.bWorldBossScene and not _data.fengHuang.bFengHuangScene then --boss,凤凰期间房间不收益
		local serverConfig = _data.tableFrame.getServerConfig()
		skynet.call(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","changeScore",protocalData.bulletMultiple,false)
		local iNeedScore = skynet.call(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","getScore")
		if isWanRoom(serverConfig.NodeID) then
			if iNeedScore >= 400 and getPlayerCount() >= 1 then
				--flushFengHuang()
			end
		end
	end

	for _, v in pairs(protocalData.UserGoodsInfo) do 
		if v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
			if gameData.fishScore == v.goodsCount then
				skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
					COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,-protocalData.bulletMultiple,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)
			else
			--	skynet.error(string.format("------------金币不同步了-----客户端传上来=%d,server=%d---------------------------------",v.goodsCount,gameData.fishScore))
				skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
					COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,-protocalData.bulletMultiple,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH,true)
			end
		elseif v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_JEWEL then
			local curCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "GetItemCount",userAttr.userID,COMMON_CONST.ITEM_ID.ITEM_ID_JEWEL)
			if v.goodsCount ~= curCount then
				skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "GoodsInfo",userAttr.userID,COMMON_CONST.ITEM_ID.ITEM_ID_JEWEL)
			end
		elseif v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_FISH then
			local curCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "GetItemCount",userAttr.userID,COMMON_CONST.ITEM_ID.ITEM_ID_FISH)
			if v.goodsCount ~= curCount then
				skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "GoodsInfo",userAttr.userID,COMMON_CONST.ITEM_ID.ITEM_ID_FISH)
			end
		end
	end

	--体验炮台
	local opLimitInfo = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","GetLimitInfo",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP)
	if opLimitInfo then
		if os.time() - opLimitInfo.limitDate > COMMON_CONST.EX_VIP_PAO_TAI_TIME then
			skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","ResetLimitCount",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP)
			local bFind = false
			if userAttr.memberOrder < 3 then
				local limitCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","GetLimitCount",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP3)
				if limitCount == 1 then
					bFind = true
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP3,1)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP,3)
				end

				if not bFind then
					local limitCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","GetLimitCount",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP4)
					if limitCount == 1 then
						bFind = true
						skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP4,1)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP,4)
					end
				end

				if not bFind then
					local limitCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","GetLimitCount",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP6)
					if limitCount == 1 then
						bFind = true
						skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP6,1)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP,6)
					end
				end

			elseif userAttr.memberOrder < 4 then
				local bFind = false
				local limitCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","GetLimitCount",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP4)
				if limitCount == 1 then
					bFind = true
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP4,1)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP,4)
				end

				if not bFind then
					local limitCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","GetLimitCount",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP6)
					if limitCount == 1 then
						bFind = true
						skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP6,1)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP,6)
					end
				end

			elseif userAttr.memberOrder < 6 then
				local limitCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","GetLimitCount",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP6)
				if limitCount == 1 then
					bFind = true
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP6,1)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP,6)
				end
			end

			if bFind then
				_data.tableFrame.broadcastExperienceGunInfo()
			end
		end 
	end

	if not opLimitInfo then
		local bFind = false
		if userAttr.memberOrder < 3 then
			local limitCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","GetLimitCount",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP3)
			if limitCount == 1 then
				bFind = true
				skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP3,1)
				skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP,3)
			end

			if not bFind then
				local limitCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","GetLimitCount",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP4)
				if limitCount == 1 then
					bFind = true
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP4,1)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP,4)
				end
			end

			if not bFind then
				local limitCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","GetLimitCount",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP6)
				if limitCount == 1 then
					bFind = true
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP6,1)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP,6)
				end
			end

		elseif userAttr.memberOrder < 4 then
			local bFind = false
			local limitCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","GetLimitCount",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP4)
			if limitCount == 1 then
				bFind = true
				skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP4,1)
				skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP,4)
			end

			if not bFind then
				local limitCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","GetLimitCount",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP6)
				if limitCount == 1 then
					bFind = true
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP6,1)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP,6)
				end
			end

		elseif userAttr.memberOrder < 6 then
			local limitCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","GetLimitCount",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP6)
			if limitCount == 1 then
				bFind = true
				skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP6,1)
				skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP,6)
			end
		end

		if bFind then
			_data.tableFrame.broadcastExperienceGunInfo()
		end
	end


	skynet.send(addressResolver.getAddressByServiceName("GS_model_gunUplevel"), "lua", "CheckDropGem",userAttr.userID,protocalData.bulletMultiple)

	_data.tableFrame.onMatchScoreChange(userItem, -protocalData.bulletMultiple)
	if not userAttr.isAndroid then
		addSystemScorePool(gameData, protocalData.bulletMultiple)
	end
	
	if protocalData.lockFishID~=0 and _data.fishTraceHash[protocalData.lockFishID]==nil then
		protocalData.lockFishID = 0
	end
	if not userAttr.isAndroid then
		--更新锁定大鱼
		updateLockFishID(userAttr.chairID, protocalData.lockFishID)
	else
		local canLockFish = androidCanLockFish()
		local lockFishID = getRandomLockFishID()
		if canLockFish and lockFishID > 0 then
			protocalData.lockFishID = lockFishID
		end
	end

	gameData.bulletInfoHash[gameData.bulletID] = {id=gameData.bulletID, kind=protocalData.bulletKind, multiple=protocalData.bulletMultiple}
	
	local respObj = {
		bulletKind = protocalData.bulletKind,
		bulletID = gameData.bulletID,
		chairID = userAttr.chairID,
		angle = protocalData.angle,
		bulletMultiple = protocalData.bulletMultiple,
		UserGoodsInfo = protocalData.UserGoodsInfo,
		lockFishID = protocalData.lockFishID,
	}
	
	local pbParser = resourceResolver.get("pbParser")
	local packetStr = skynet.call(pbParser, "lua", "encode", 0x020000, respObj, true)
	if packetStr then
		if userAttr.isAndroid then
			_data.tableFrame.broadcastTable(packetStr)
		else
			_data.tableFrame.broadcastTableWithExcept(packetStr, userItem)
		end
		
		_data.tableFrame.broadcastLookon(packetStr)
	end
end

local function getfishMultiple(fishKind, fishID)
	if 41<=fishKind and fishKind<=45 then
		return 0
	end
	
	local fishMultiple
	local fishConfigItem = _data.config.fishHash[fishKind]
	local multipleType = type(fishConfigItem.multiple)
	if multipleType=="number" then
		fishMultiple = fishConfigItem.multiple
	elseif multipleType=="table" then
		fishMultiple = arc4.random(fishConfigItem.multiple[1], fishConfigItem.multiple[2])
	end

	return fishMultiple
end

local function getExtraRatio(chairID, extraType, total)
	-- 获取额外加成命中率
	local gameData = getGameDataItem(chairID)
	local valueList, retRatio
	if extraType == FISH_CONST.SCORE_MULTIPLE_TYPE then
		valueList = FISH_CONST.FISH_SCORE_MULTIPLE
	elseif extraType == FISH_CONST.PRESENT_MULTIPLE_TYPE then
		valueList = FISH_CONST.FISH_PRESENT_MULTIPLE
	else
		return retRatio
	end

	for _, item in  ipairs(valueList) do
		if total <= item.Value then
			retRatio = item.Ratio
			break
		end
	end
	if not retRatio then
		retRatio = 1
	end
	return retRatio
end

local function NotifyUserFishRate(agent,fishID,rate,userID)
	local bNeedNotify = false
	for k, v in pairs(_data.config.notifyUserRate) do
		if v.userId == userID then
			bNeedNotify = true
			break
		end
	end

	local host = skynet.getenv("mysqlHost")
	if bNeedNotify or host == "192.168.0.241" or host == "192.168.0.129" then	
		local info = {
			fishId = fishID,
			rate = rate,
		}
		skynet.send(agent,"lua","forward",0x020016,info)

		local score =  skynet.call(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","getScore")
		local limitFirePiece = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_FIRE_PIECE --微粒池子
		local nowFirePieceTotal = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "GetLimitCount",userID,limitFirePiece)

		info.fishId = 9999
		info.rate = tostring(nowFirePieceTotal)


		skynet.send(agent,"lua","forward",0x020016,info)
	end
end

local function doCatchFish(userItem, fishID, bulletInfo, catchCount)
	local userAttr = ServerUserItem.getAttribute(userItem, {"userID", "isAndroid", "contribution", "chairID", "agent", "nickName","score", "insure","memberOrder","logonTime"})
	local gameData = getGameDataItem(userAttr.chairID)
	
	local fishTraceInfo = _data.fishTraceHash[fishID]
	
	if fishTraceInfo == nil then
		return
	end

	local fishConfigItem = _data.config.fishHash[fishTraceInfo.fishKind]
	if fishConfigItem == nil then
		return
	end
	
	local nowTime = os.time()
	local probabilityUpperLimit = fishConfigItem.probability

		
	if _data.bWorldBossScene then
		if fishTraceInfo.fishKind ~= 29 and fishTraceInfo.fishKind ~= 33 then
			return
		end

		local nowTick =	skynet.now()
		local difftime = (nowTick - fishTraceInfo.buildTick)/GS_CONST.TIMER.TICK_STEP
		if difftime <= 30 then
			if _data.bSpecial then
				if userAttr.memberOrder <= 1 then
					return
				end
			else
				return
			end
		end

		if userAttr.memberOrder <= 1 then
			local rate = arc4.random(1,100)
			if rate <= 75 then
				return
			end
		end

		local limitId_1 = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_KILL_WORLD_BOSS
		local limitId_2 = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_KILL_TIME_BOSS
		local limitId_3 = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_PAY_RMB_NEW
		local limitId_4 = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_PAY_RMB_NEW_1
		local limitId_TODAY = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_KT_BOSS_TODAY

		if _data.bSpecial then

			local bLimit = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","CheckIsEverydayLimit",userAttr.userID,limitId_TODAY,2)
			if bLimit then
				return
			end

			local timeBossCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "GetLimitCount",userAttr.userID,limitId_2)
			local rmbCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "GetLimitCount",userAttr.userID,limitId_3)
			local bossAddRate_x = 1 + math.floor(rmbCount/200)*2

			local temp = 0
			local addRateCount = math.floor((difftime + _data.worldBoss.addRateTime)/20)

			if userAttr.memberOrder == 1 then
				temp = bossAddRate_x*2
			elseif userAttr.memberOrder == 2 then
				temp = bossAddRate_x*3*1.5^addRateCount
			elseif userAttr.memberOrder == 3 then
				temp = bossAddRate_x*4*1.7^addRateCount
			elseif userAttr.memberOrder == 4 then
				temp = bossAddRate_x*5*1.6^addRateCount
			elseif userAttr.memberOrder == 5 then
				temp = bossAddRate_x*6*2^addRateCount
			elseif userAttr.memberOrder == 6 then
				temp = bossAddRate_x*7*2^addRateCount
			elseif userAttr.memberOrder == 7 then
				temp = bossAddRate_x*10*2^addRateCount
			end

			if temp < 50 then
				return
			end

			probabilityUpperLimit = probabilityUpperLimit*temp

		else

			if _data.worldBoss.lastKillWorldBossUserId == userAttr.userID then
				return
			end

			local wordBossCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "GetLimitCount",userAttr.userID,limitId_1)
			local rmbCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "GetLimitCount",userAttr.userID,limitId_4)
			local bossAddRate_x = 1 + math.floor(rmbCount/100)*0.1

			probabilityUpperLimit = probabilityUpperLimit*(0.7*bossAddRate_x+0.3)

			local addRateCount = math.floor((difftime + _data.worldBoss.worldBossAddRateTime)/90)

			if userAttr.memberOrder == 1 then
				probabilityUpperLimit = probabilityUpperLimit*2
			elseif userAttr.memberOrder == 2 then
				probabilityUpperLimit = probabilityUpperLimit*3
			elseif userAttr.memberOrder == 3 then
				probabilityUpperLimit = probabilityUpperLimit*4*1.2^addRateCount
			elseif userAttr.memberOrder == 4 then
				probabilityUpperLimit = probabilityUpperLimit*5*1.2^addRateCount
			elseif userAttr.memberOrder == 5 then
				probabilityUpperLimit = probabilityUpperLimit*6*1.2^addRateCount
			elseif userAttr.memberOrder == 6 then
				probabilityUpperLimit = probabilityUpperLimit*7*1.4^addRateCount
			elseif userAttr.memberOrder == 7 then
				probabilityUpperLimit = probabilityUpperLimit*10*1.4^addRateCount
			end

		end

		for k, v in pairs(_data.rateConfig.normalConfig) do
			if v.userId == userAttr.userID then
				probabilityUpperLimit = probabilityUpperLimit*(v.worldBossAddRate+1)
			end
		end

		if _data.worldBoss.userID == userAttr.userID then
			probabilityUpperLimit = probabilityUpperLimit*(_data.worldBoss.addRate+1)
		end

		if not _data.bSpecial then
			for k, v in pairs(_data.rateConfig.worldBoss) do
				if v.userId == userAttr.userID then
					probabilityUpperLimit = probabilityUpperLimit*(v.addRate+1)
					_data.worldBoss.index = v.index
					_data.worldBoss.userID = v.userId
					_data.worldBoss.addRate = v.addRate
					break
				end
			end
		else
			for k, v in pairs(_data.rateConfig.timeBoss) do
				if v.userId == userAttr.userID then
					probabilityUpperLimit = probabilityUpperLimit*(v.addRate+1)
					_data.worldBoss.index = v.index
					_data.worldBoss.userID = v.userId
					_data.worldBoss.addRate = v.addRate
					break
				end
			end
		end

		NotifyUserFishRate(userAttr.agent,fishTraceInfo.fishKind,probabilityUpperLimit,userAttr.userID)

		local probability = arc4.random()
		if probability > probabilityUpperLimit then
			return
		end

		_data.fishTraceHash[fishID] = nil
		local fishMultiple = getfishMultiple(fishTraceInfo.fishKind, fishID)

		local addScore = 0
		if _data.rewardPool ~= nil then
			addScore = _data.rewardPool
		end

		gameData.fishScore = gameData.fishScore + addScore

		--背包
		skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
		  	COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,addScore,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)

		--增加记录增加的分数
		gameData.totalScore = gameData.totalScore + addScore

		local nickName = COMMON_CONST.HideNickName(userAttr.nickName)
		local msg = string.format("恭喜%s玩家击杀世界boss%s,获得%d金币",nickName,fishConfigItem.name,addScore)
		_data.tableFrame.sendSystemMessage(msg, true, false, false, false)

		skynet.send(addressResolver.getAddressByServiceName("GS_model_tableManager"), "lua", "killWorldBoss", {userID=userAttr.userID,name=userAttr.nickName,vipLv=userAttr.memberOrder})

		local serverConfig = _data.tableFrame.getServerConfig()
		local insertTime = os.date("%Y-%m-%d %H:%M:%S", os.time())
		local sql = string.format("INSERT INTO `kfrecorddb`.`t_reward_gold_fish_or_boss` (`UserId`, `Type`, `ServerId`, `FishiId`, `Multiple`, `AddGold`, `CurGold`, `Date`) values (%d,3,%d,%d,%d,%d,%d,'%s')",
			userAttr.userID,serverConfig.ServerID,fishTraceInfo.fishKind,bulletInfo.multiple,addScore,gameData.fishScore,insertTime)	
		local mysqlConn = addressResolver.getMysqlConnection()
		skynet.send(mysqlConn, "lua", "execute", sql)

		if _data.worldBoss.userID == userAttr.userID then
			if not _data.bSpecial then
				sql = string.format("DELETE FROM `kffishdb`.`t_control_world_boss_rate` where `Index`=%d and UserId=%d",_data.worldBoss.index,_data.worldBoss.userID)
			else
				sql = string.format("DELETE FROM `kffishdb`.`t_control_time_boss_rate` where `Index`=%d and UserId=%d",_data.worldBoss.index,_data.worldBoss.userID)
			end

			skynet.send(mysqlConn, "lua", "execute", sql)
		end
		
		if not _data.bSpecial then
			skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitId_4,-500)
			skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitId_1,1)
		else
			skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitId_3,-200)
			skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitId_2,1)
			skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitId_TODAY,1)
		end

		return
	end

	if _data.fengHuang.bFengHuangScene then
		if fishTraceInfo.fishKind ~= 30 then
			return
		end

		if _data.fengHuang.fengHuangGunCount >= 150 then
			probabilityUpperLimit = probabilityUpperLimit*1.6
		elseif _data.fengHuang.fengHuangGunCount >= 100 then
			probabilityUpperLimit = probabilityUpperLimit*1.4
		elseif _data.fengHuang.fengHuangGunCount >= 50 then
			probabilityUpperLimit = probabilityUpperLimit*1.2
		end

		for k, v in pairs(_data.rateConfig.normalConfig) do
			if v.userId == userAttr.userID then
				probabilityUpperLimit = probabilityUpperLimit*(v.fengHuangAddRate+1)
			end
		end

		NotifyUserFishRate(userAttr.agent,fishTraceInfo.fishKind,probabilityUpperLimit,userAttr.userID)

		local probability = arc4.random()
		if probability > probabilityUpperLimit then
			return
		end

		_data.fishTraceHash[fishID] = nil

		local fishScore = _data.fengHuang.fengHuangPoolGold

		local fishMultiple = getfishMultiple(fishTraceInfo.fishKind, fishID)

		gameData.fishScore = gameData.fishScore + fishScore

		--背包
		skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
		  	COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,fishScore,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)

		--增加记录增加的分数
		gameData.totalScore = gameData.totalScore + fishScore

		local catchFishGoodsItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_item_config"), "lua", "GetFengHuangDrop")

		local itemInfo = ""
		local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
		for k, v in pairs(catchFishGoodsItem) do 
			if v.goodsID ~= COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
				local itemInfoConfig = skynet.call(configAddress,"lua","GetItemConfigInfo",v.goodsID)
				if itemInfoConfig then
					itemInfo = itemInfo..itemInfoConfig.itemName.."*".. tostring(v.goodsCount).."!"
				end
			else
				gameData.fishScore = gameData.fishScore + v.goodsCount
				gameData.totalScore = gameData.totalScore + v.goodsCount
				fishScore = fishScore + v.goodsCount

				skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
		  			COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,v.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)
			end
		end

		local nickName = COMMON_CONST.HideNickName(userAttr.nickName)
		local msg = string.format("恭喜%s玩家击杀%s,获得%d金币",nickName,fishConfigItem.name,_data.fengHuang.fengHuangPoolGold)
		if itemInfo ~= "" then
			msg = msg .. ",掉落" .. itemInfo
		end

		_data.tableFrame.sendSystemMessage(msg, true, false, false, false)

		fengHuangEnd()

		local serverConfig = _data.tableFrame.getServerConfig()
		local insertTime = os.date("%Y-%m-%d %H:%M:%S", os.time())
		local sql = string.format("INSERT INTO `kfrecorddb`.`t_reward_gold_fish_or_boss` (`UserId`, `Type`, `ServerId`, `FishiId`, `Multiple`, `AddGold`, `CurGold`, `Date`) values (%d,4,%d,%d,%d,%d,%d,'%s')",
			userAttr.userID,serverConfig.ServerID,fishTraceInfo.fishKind,bulletInfo.multiple,fishScore,gameData.fishScore,insertTime)	
		local mysqlConn = addressResolver.getMysqlConnection()
		skynet.send(mysqlConn, "lua", "execute", sql)

		return
	end

	--根据亏损调整话费鱼的概率
	if fishTraceInfo.fishKind == 24 or fishTraceInfo.fishKind == 25 then
		local sumGoldToMoney = (gameData.fishScore + userAttr.insure)/10000
		if userAttr.contribution > sumGoldToMoney then
			local diffValue = userAttr.contribution - sumGoldToMoney
			for _, item in ipairs(_data.config.telephoneFishRate) do
				if item.minValue <= diffValue and (diffValue <= item.maxValue or item.maxValue ==0) then
					probabilityUpperLimit = probabilityUpperLimit/item.ratio
					break
				end
			end
		end
	end

	--新手保护调整概率--start
	local bFishId = true
	if fishTraceInfo.fishKind ~= 22 then
		--玩家身上的金币减去玩家充值的金币大于100W时,取消新手概率保护机制对此玩家的作用
		if gameData.fishScore - userAttr.contribution*10000 > 1000000 then
			goto continue
		end

		bFishId = skynet.call(addressResolver.getAddressByServiceName("GS_model_protect"), "lua", "CheckFishId",userAttr.userID,fishTraceInfo.fishKind)
		if not bFishId then
			probabilityUpperLimit = probabilityUpperLimit*2
		end

		::continue::
	end
	--新手保护调整概率--end

	--救济金保护调整概率--start
	local bFishCount = true
	if fishTraceInfo.fishKind <= 17 then
		--玩家金币<30000时命中概率*1.5
        --30000<玩家金币<100000时命中概率*1.3
        --玩家金币>100000时，命中概率不改变,并且当天都没有这个保护了
        local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_4
        if fishTraceInfo.fishKind >= 13 then 
        	limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_5
        end
        local isLimit = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "CheckIsEverydayLimit",userAttr.userID,limitId,1)
		if not isLimit then
			bFishCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_protect"), "lua", "CheckFishCount",userAttr.userID,fishTraceInfo.fishKind)
			if not bFishCount then
				if gameData.fishScore <= 30000 then
					probabilityUpperLimit = probabilityUpperLimit*1.5
				elseif 30000 < gameData.fishScore and gameData.fishScore < 100000 then
					probabilityUpperLimit = probabilityUpperLimit*1.3
				else
					bFishCount = true
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_4,1)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_5,1)
				end
			end
		end
	end
	--救济金保护调整概率--end

	--首冲保护--start
	local bChargeFish = true
	-- if bFishId and fishTraceInfo.fishKind ~= 22 and fishTraceInfo.fishKind ~= 24 and fishTraceInfo.fishKind ~= 25 then
	-- 	local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_FIRST_CHARGE
	-- 	local isLimit = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "CheckIsForeverLimit",userAttr.userID,limitId,1)
	-- 	if isLimit then
	-- 		bChargeFish = skynet.call(addressResolver.getAddressByServiceName("GS_model_protect"), "lua", "CheckChargeFishCount",userAttr.userID,fishTraceInfo.fishKind)
	-- 		if not bChargeFish then
	-- 			probabilityUpperLimit = probabilityUpperLimit*1.2
	-- 		end
	-- 	end
	-- end
	--首冲保护--end

	--预判将要命中的鱼的分数和礼券值
	local serverConfig = _data.tableFrame.getServerConfig()
	local fishMultiple = getfishMultiple(fishTraceInfo.fishKind, fishID)
	local fishScore = fishMultiple * bulletInfo.multiple
	local score = 0
	local present = 0
	if 24<=fishTraceInfo.fishKind and fishTraceInfo.fishKind<=25 then--话费类
		local boxMultiple, boxPresent
		local multipleType = type(fishConfigItem.multiple)
		if multipleType=="number" then
			boxMultiple = fishConfigItem.multiple
		elseif multipleType=="table" then
			boxMultiple = arc4.random(fishConfigItem.multiple[1], fishConfigItem.multiple[2])
		end
		present = bulletInfo.multiple/100

		if 25 == fishTraceInfo.fishKind then
			present = present * 4
		end

		fishScore = present
	end
	--非机器人变更命中率
	if not userAttr.isAndroid and (isBasicRoom(serverConfig.NodeID) or gameData.isPayUser) then
		if fishTraceInfo.fishKind~=21 and fishTraceInfo.fishKind~=22 and fishTraceInfo.fishKind~=23 then
			local extraRatio
			if fishTraceInfo.fishKind==44 or fishTraceInfo.fishKind==45 then--宝箱类型
				extraRatio = getExtraRatio(userAttr.chairID, FISH_CONST.PRESENT_MULTIPLE_TYPE, gameData.totalPresent+present)
			else
				extraRatio = getExtraRatio(userAttr.chairID, FISH_CONST.SCORE_MULTIPLE_TYPE, gameData.totalScore+fishScore)
			end
			if extraRatio then
				probabilityUpperLimit = probabilityUpperLimit * extraRatio
			end
		end
	end
		
	if not userAttr.isAndroid and userAttr.memberOrder ~= 0 then
		local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
		local infoConfig = skynet.call(configAddress,"lua","GetvipInfo")
		--vip提升奖金鱼概率
		if isRewardGoldFish(fishTraceInfo.fishKind) and not isBossFish(fishTraceInfo.fishKind) then
			probabilityUpperLimit = infoConfig[userAttr.memberOrder].awardFish * probabilityUpperLimit
		end
		--vip提升boss鱼概率
		if isBossFish(fishTraceInfo.fishKind) then
			probabilityUpperLimit = infoConfig[userAttr.memberOrder].bossFish * probabilityUpperLimit
		end
		--vip提升话费券概率
		if 24<=fishTraceInfo.fishKind and fishTraceInfo.fishKind<=25 then
			probabilityUpperLimit = infoConfig[userAttr.memberOrder].gift * probabilityUpperLimit
		end
	end

	--赢取太多金币后的概率惩罚
	if gameData.fishScore > gameData.openBoxSumGold+10*gameData.rmbGold + 6000000 then
		probabilityUpperLimit = probabilityUpperLimit*0.4
	elseif gameData.fishScore > gameData.openBoxSumGold+7*gameData.rmbGold + 4000000 then
		probabilityUpperLimit = probabilityUpperLimit*0.5
	elseif gameData.fishScore > gameData.openBoxSumGold+5*gameData.rmbGold + 3000000 then
		probabilityUpperLimit = probabilityUpperLimit*0.7
	elseif gameData.fishScore > gameData.openBoxSumGold+4*gameData.rmbGold + 2000000 then
		probabilityUpperLimit = probabilityUpperLimit*0.8
	elseif gameData.fishScore > gameData.openBoxSumGold+3*gameData.rmbGold + 2000000 then
		probabilityUpperLimit = probabilityUpperLimit*0.9
	end
	
	probabilityUpperLimit = probabilityUpperLimit / catchCount
	
	--提升玩家概率
	for k, v in pairs(_data.rateConfig.normalConfig) do
		if v.userId == userAttr.userID then
			for kk, vv in pairs(v.fishList) do
				if vv.fishKind == fishTraceInfo.fishKind then
					probabilityUpperLimit = probabilityUpperLimit*(vv.rate+1)
					break
				end
			end

			probabilityUpperLimit = probabilityUpperLimit*(v.addRate+1)
			break
		end
	end

	for k, v in pairs(_data.rateConfig.fishConfig) do
		if k == userAttr.userID then
			for kk, vv in pairs(v) do
				if vv.fishKind == fishTraceInfo.fishKind or vv.fishKind == 9999 then
					if vv.startTime <= nowTime and nowTime <= vv.endTime then
						probabilityUpperLimit = probabilityUpperLimit*(vv.addRate+1)
					end
					break
				end
			end
			
			break
		end
	end

	--vip体验炮台提升概率
	if isRewardGoldFish(fishTraceInfo.fishKind) and not isBossFish(fishTraceInfo.fishKind) then
		local opLimitInfo = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"),"lua","GetLimitInfo",userAttr.userID,COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP)
		if opLimitInfo then
			if opLimitInfo.limitCount == 6 then
				if os.time() - opLimitInfo.limitDate < COMMON_CONST.EX_VIP_PAO_TAI_TIME then
					probabilityUpperLimit = probabilityUpperLimit*1.2
				end
			end
		end
	end


	NotifyUserFishRate(userAttr.agent,fishTraceInfo.fishKind,probabilityUpperLimit,userAttr.userID)
		
	local probability = 1 - arc4.random()													-- (0, 1]

	if probability > probabilityUpperLimit then
		return
	end

	--是否是暴击双倍--start
	local bCrit = false
	local bFindControl = false
	if fishTraceInfo.fishKind ~= 28 then
		if isRewardGoldFish(fishTraceInfo.fishKind) or isBossFish(fishTraceInfo.fishKind) then
			for k, v in pairs(_data.rateConfig.normalConfig) do
				if v.userId == userAttr.userID then
					if v.crit ~= 0 or v.miss ~= 0 then
						bFindControl = true
						local iRandRate = arc4.random(1,100)
						if iRandRate <= v.crit then 
							bCrit = true
						elseif iRandRate <= v.miss then
							return
						end
					end
				end
			end

			if not bFindControl then
				for k, v in pairs(_data.rateConfig.critConfig) do
					if k == userAttr.userID then
						for kk, vv in pairs(v) do
							if vv.fishKind == fishTraceInfo.fishKind or vv.fishKind == 9999 then
								if vv.startTime <= nowTime and nowTime <= vv.endTime then
									bFindControl = true
									local iRandRate = arc4.random(1,100)
									if iRandRate <= vv.critRate then
										bCrit = true
									elseif iRandRate <= vv.missRate then
										return
									end
								end
							end
						end
					end
				end
			end

			if not bFindControl then
				local iRandRate = arc4.random(1,100)
				if iRandRate <= _data.config.controlCritRate.normalRate.crit then
					bCrit = true
				elseif iRandRate <= _data.config.controlCritRate.normalRate.miss then
					return
				end
			end
		end
	end

	if bCrit then
		fishScore = fishScore*2
	end
	--是否是暴击双倍--end


	--玩家特殊处理--土猪男
	for kk, vv in pairs(_data.config.punishmentList) do
		if vv.userId == userAttr.userID then
			if fishTraceInfo.fishKind == 24 or fishTraceInfo.fishKind == 25 then
				return
			end
		end
	end

	--新手保护调整概率--start
	if fishTraceInfo.fishKind ~= 22 and not bFishId then
		skynet.send(addressResolver.getAddressByServiceName("GS_model_protect"), "lua", "AddFishId",userAttr.userID,fishTraceInfo.fishKind)
	end

	if not bFishCount and fishTraceInfo.fishKind <= 17 then
		skynet.send(addressResolver.getAddressByServiceName("GS_model_protect"), "lua", "AddFishCount",userAttr.userID,1,fishTraceInfo.fishKind)			
	end

	if not bChargeFish and fishTraceInfo.fishKind ~= 22 and fishTraceInfo.fishKind ~= 24 and fishTraceInfo.fishKind ~= 25 then
		skynet.send(addressResolver.getAddressByServiceName("GS_model_protect"), "lua", "AddChargeFishCount",userAttr.userID,fishTraceInfo.fishKind)			
	end
	--新手保护调整概率--end
	
	_data.fishTraceHash[fishID] = nil
	-- 局部炸弹, 超级炸弹, 鱼王
	if fishTraceInfo.fishKind==21 or fishTraceInfo.fishKind==22 or fishTraceInfo.fishKind==23 then
		_data.sweepFishHash[fishID]={
			chairID=userAttr.chairID,
			fishID = fishTraceInfo.fishID,
			fishKind = fishTraceInfo.fishKind,
			bulletKind = bulletInfo.kind,
			bulletMultiple = bulletInfo.multiple,
		}

		local pbParser = resourceResolver.get("pbParser")
		local packetStr = skynet.call(pbParser, "lua", "encode", 0x020009, {
			chairID=userAttr.chairID,
			fishID=fishTraceInfo.fishID,
			fishScore=fishScore,
			fishMulti=fishMultiple,
			catchSweepFishGoodsItem = {},
			},true)

		if packetStr then
			_data.tableFrame.broadcastTable(packetStr)
			_data.tableFrame.broadcastLookon(packetStr)
		end

		return
	end

	local catchFishGoodsItem = {
		--required int32 goodsID=1;
		--required sint64 goodsCount=2;
	}
	
	-- 捕中宝箱，比赛场没有宝箱鱼阵
	if 24<=fishTraceInfo.fishKind and fishTraceInfo.fishKind<=25 then--话费类	
		--增加得分记录
		gameData.totalPresent = gameData.totalPresent + present
		gameData.additionalCredit.gift = gameData.additionalCredit.gift + present

		--背包
		skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
		  	COMMON_CONST.ITEM_ID.ITEM_ID_FISH,present,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)

		if present >= 10 then
			if not isBasicRoom(serverConfig.NodeID) and not userAttr.isAndroid then
				local nickName = COMMON_CONST.HideNickName(userAttr.nickName)
				local msg = string.format("恭喜%s捕中话费鱼，获得%d话费券奖励。",nickName,present)
				_data.tableFrame.sendSystemMessage(msg, true, false, false, false)
			end
		end
		
		local curGift = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "GetItemCount",userAttr.userID,COMMON_CONST.ITEM_ID.ITEM_ID_FISH)
		local sql = string.format("insert into `kfrecorddb`.`CatchBox` (`ServerID`, `UserID`, `BoxType`, `Present`,`Score`,`Ctime`,`SumPresent`,`Multiple`) values (%d,%d,'%s',%d,%d,now(),%d,%d)",
			serverConfig.ServerID, userAttr.userID, mysqlutil.escapestring(fishConfigItem.name), present, score, curGift,bulletInfo.multiple)	
		local mysqlConn = addressResolver.getMysqlConnection()
		skynet.send(mysqlConn, "lua", "execute", sql)
	else
		--判断是不是奖金鱼
		if not userAttr.isAndroid and isRewardGoldFish(fishTraceInfo.fishKind) then
			local rewardGold = math.floor(fishScore*0.1)
			skynet.send(addressResolver.getAddressByServiceName("GS_model_reward_gold_fish"),"lua","ChangeRewardGfInfo",userAttr.userID,1,rewardGold)

			local insertTime = os.date("%Y-%m-%d %H:%M:%S", os.time())
		  	local sql = string.format("INSERT INTO `kfrecorddb`.`t_reward_gold_fish_or_boss` (`UserId`, `Type`, `ServerId`, `FishiId`, `Multiple`, `AddGold`, `CurGold`, `Date`) values (%d,1,%d,%d,%d,%d,%d,'%s')",
				userAttr.userID,serverConfig.ServerID,fishTraceInfo.fishKind,bulletInfo.multiple,fishScore,gameData.fishScore+fishScore,insertTime)	
			local mysqlConn = addressResolver.getMysqlConnection()
			skynet.send(mysqlConn, "lua", "execute", sql)

			local item = {
				goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
				goodsCount = rewardGold
			}
			table.insert(catchFishGoodsItem,item)

			fishScore = fishScore - rewardGold
		end

		--判断是不是红包鱼--start
		if 34 <= fishTraceInfo.fishKind and fishTraceInfo.fishKind <= 35 then
			if fishTraceInfo.fishKind == 34 then
				local randRate = arc4.random(1,100)
				if isBasicRoom(serverConfig.NodeID) then
					if randRate <= 5 then
						local item = {
							goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_SILVE_KEY,
							goodsCount = 1
						}
						
						table.insert(catchFishGoodsItem,item)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
							item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG)
					end
				else
					local iNeedScore = skynet.call(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","getScore")
					if iNeedScore >= 1000000 then
						if randRate <= 20 then
							skynet.call(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","changeScore",1000000,true)
							local item = {
								goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD_KEY,
								goodsCount = 1
							}
							table.insert(catchFishGoodsItem,item)
							skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
								item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG)
						end

						if isWanRoom(serverConfig.NodeID) then
							if iNeedScore >= 2000000 then
								if 21 <= randRate and randRate <= 40 then
									skynet.call(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","changeScore",2000000,true)
									local item = {
										goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_MOON_KEY,
										goodsCount = 1
									}
									table.insert(catchFishGoodsItem,item)
									skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
										item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG)
								end
							end
						end

						if 41 <= randRate and randRate <= 45 then
							skynet.call(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","changeScore",1000000,true)
							local item = {
								goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
								goodsCount = 660000
							}

							fishScore = fishScore + item.goodsCount
							table.insert(catchFishGoodsItem,item)
						end

						if 45 <= randRate and randRate <= 50 then
							skynet.call(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","changeScore",1000000,true)
							local item = {
								goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
								goodsCount = 880000
							}

							fishScore = fishScore + item.goodsCount
							table.insert(catchFishGoodsItem,item)
						end
					end
				end

				if fishScore >= 1500000 then
					local sql = string.format("INSERT INTO `kfrecorddb`.`t_red_packet_kill_record` (`UserId`,`Multiple`,`AddGold`,`AddTime`) VALUES (%d,%d,%d,NOW())",
						userAttr.userID,_data.config.cannonMultiple.min,fishScore)
					local mysqlConn = addressResolver.getMysqlConnection()
					skynet.send(mysqlConn, "lua", "execute", sql)

					local info = {
						userID = userAttr.userID,
						userName = userAttr.nickName,
						killTime = os.time(),
						multiple = _data.config.cannonMultiple.min,
						score = fishScore,
					}

					table.insert(_data.redPacket.redPacketKillRecord,info)
				end

			else

				local randRate = arc4.random(1,100)
				if randRate <= 2 then
					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_CANG_BAO_TU_1,
						goodsCount = 1
					}
					
					table.insert(catchFishGoodsItem,item)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
						item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG)
				end

				if not isBasicRoom(serverConfig.NodeID) then
					if 3 <= randRate and randRate <= 7 then
						local item = {
							goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_CANG_BAO_TU_2,
							goodsCount = 1
						}
						
						table.insert(catchFishGoodsItem,item)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
							item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG)
					end
				end

				if 8 <= randRate and randRate <= 9 then
					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_FAST,
						goodsCount = 1
					}
					
					table.insert(catchFishGoodsItem,item)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
						item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG,true)
				end

				if 10 <= randRate and randRate <= 11 then
					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_LOCK,
						goodsCount = 1
					}
					
					table.insert(catchFishGoodsItem,item)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
						item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG,true)
				end

				local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_KILL_RED_PACKET
	 			local isLimit = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "CheckIsForeverLimit",userAttr.userID,limitId,1)
			 	if not isLimit then
			 		if randRate > 30 then
			 			local item = {
							goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
							goodsCount = 50000
						}

						fishScore = fishScore + item.goodsCount
						table.insert(catchFishGoodsItem,item)
			 		end
			 		skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitId,1)
			 	else
			 		if 12 <= randRate and randRate <= 16 then
			 			local item = {
							goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
							goodsCount = 50000
						}

						fishScore = fishScore + item.goodsCount				
						table.insert(catchFishGoodsItem,item)
			 		end
			 	end
			end

			local sql = string.format("INSERT INTO `kfrecorddb`.`t_red_packet_user_gold_record` (`UserId`,`SumGold`) VALUES (%d,%d) ON DUPLICATE KEY UPDATE `SumGold`=`SumGold`+%d",
				userAttr.userID,fishScore,fishScore)	
			local mysqlConn = addressResolver.getMysqlConnection()
			skynet.send(mysqlConn, "lua", "execute", sql)

			local info = {
				userID = userAttr.userID,
				userName = userAttr.nickName,
				score = fishScore,
			}

			table.insert(_data.redPacket.redPacketRank,info)
		end
		--判断是不是红包鱼--end

		gameData.fishScore = gameData.fishScore + fishScore

		skynet.call(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","changeScore",fishScore,true)

		--背包
		skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
		  	COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,fishScore,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)

		--增加记录增加的分数
		gameData.totalScore = gameData.totalScore + fishScore

		_data.tableFrame.onMatchScoreChange(userItem, fishScore)
		if not userAttr.isAndroid then
			addSystemScorePool(gameData, -fishScore)
		end	

		--掉落合成卡
		if isRewardGoldFish(fishTraceInfo.fishKind) then
			if userAttr.memberOrder >= 2 then
				local itemId = COMMON_CONST.ITEM_ID.ITEM_ID_COMPOSE_CARD_1
				local randRate = arc4.random(1,100)
				if gameData.fishScore >= 8000000 then
					if randRate <= 15 then
						if randRate%2 == 0 then
							itemId = COMMON_CONST.ITEM_ID.ITEM_ID_COMPOSE_CARD_2
						end
					 	local iCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "GetItemCount",userAttr.userID,itemId)
						if iCount == 0 then
							local item = {
								goodsID = itemId,
								goodsCount = 1
							}
							table.insert(catchFishGoodsItem,item)
							skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
								item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH,true)
						end
					end
				elseif gameData.fishScore >= 4000000 then
					if randRate <= 15 then
					 	local iCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "GetItemCount",userAttr.userID,itemId)
						if iCount == 0 then
							local item = {
								goodsID = itemId,
								goodsCount = 1
							}
							table.insert(catchFishGoodsItem,item)
							skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
								item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH,true)
						end
					end
				end
			end
		end

		if isHuoDongTime() then
			if isHuoDongFish(fishTraceInfo.fishKind) then
				local randRate = arc4.random()*100
				if randRate <= 0.5 then
					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_WORD_HUAN,
						goodsCount = 1
					}
					
					table.insert(catchFishGoodsItem,item)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
						item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG)
				end

				local randRate = arc4.random()*100
				if randRate <= 0.5 then
					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_WORD_DU,
						goodsCount = 1
					}
					table.insert(catchFishGoodsItem,item)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
						item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG)
				end
			end

			if isRewardGoldFish(fishTraceInfo.fishKind) then
				local randRate = arc4.random(1,100)
				if randRate <= 5 then
					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_WORD_GUO,
						goodsCount = 1
					}
					table.insert(catchFishGoodsItem,item)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
						item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG)
				end
			end

			if isBossFish(fishTraceInfo.fishKind) then
				if isBasicRoom(serverConfig.NodeID) then
					local limitId_1 = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_FIST_TIME_KB_1
					local limitId_hd = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_HD_KILL_BOSS_1
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitId_hd,1)

	        		local isLimit = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "CheckIsForeverLimit",userAttr.userID,limitId_1,1)
					if not isLimit then
						local item = {
							goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_WORD_QING,
							goodsCount = 1
						}
						table.insert(catchFishGoodsItem,item)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
							item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitId_1,1)
					else

		        		local iKillBossCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "GetLimitCount",userAttr.userID,limitId_hd)
						local iRate = 30 + iKillBossCount*10
						local iRandRate = arc4.random(1,100)
						if iRandRate <= iRate then
							local item = {
								goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_WORD_QING,
								goodsCount = 1
							}
							table.insert(catchFishGoodsItem,item)
							skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
	  							item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG)
							skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "ResetLimitCount",userAttr.userID,limitId_hd)
						end
					end
				else
					local iNeedScore = skynet.call(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","getScore")
					if iNeedScore >= 2000000 then
						local randRate = arc4.random(1,100)
						if randRate <= 30 then
							skynet.call(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","changeScore",2000000,true)
							local item = {
								goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_WORD_JIE,
								goodsCount = 1
							}
							table.insert(catchFishGoodsItem,item)
							skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
								item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG)
						end
					end
				end
			end
		end

		if isJieRiTime() then
			if isHuoDongFish(fishTraceInfo.fishKind) or fishTraceInfo.fishKind == 36 then
				local randRate = arc4.random()*100
				local iRate = 0.5
				if fishTraceInfo.fishKind == 36 then
					iRate = 5
				end
				if randRate <= iRate then
					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_WORD_LANG,
						goodsCount = 1
					}
					
					table.insert(catchFishGoodsItem,item)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
						item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG)
				end

				local randRate = arc4.random()*100
				if randRate <= iRate then
					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_WORD_MAN,
						goodsCount = 1
					}
					table.insert(catchFishGoodsItem,item)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
						item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG)
				end
			end

			if isRewardGoldFish(fishTraceInfo.fishKind) then
				local randRate = arc4.random(1,100)
				if randRate <= 5 then
					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_WORD_QING_1,
						goodsCount = 1
					}
					table.insert(catchFishGoodsItem,item)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
						item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG)
				end
			end

			if isBossFish(fishTraceInfo.fishKind) or isWaZiFish(fishTraceInfo.fishKind) then
				local limitId_1 = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_KB_QRJ_1
				local limitId_hd = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_KB_QRJ_COUNT
				if isThousandRoom(serverConfig.NodeID) then
					limitId_1 = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_KB_QRJ_2
				elseif isWanRoom(serverConfig.NodeID) then
					limitId_1 = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_KB_QRJ_3
				end
				
				skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitId_hd,1)

        		local isLimit = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "CheckIsForeverLimit",userAttr.userID,limitId_1,1)
				if not isLimit then
					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_WORD_REN,
						goodsCount = 1
					}
					table.insert(catchFishGoodsItem,item)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
						item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitId_1,1)
				else

	        		local iKillBossCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "GetLimitCount",userAttr.userID,limitId_hd)
					local iRate = 20 + iKillBossCount*10
					local iRandRate = arc4.random(1,100)
					if iRandRate <= iRate then
						local item = {
							goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_WORD_REN,
							goodsCount = 1
						}
						table.insert(catchFishGoodsItem,item)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
  							item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "ResetLimitCount",userAttr.userID,limitId_hd)
					end
				end

				if isThousandRoom(serverConfig.NodeID) or isWanRoom(serverConfig.NodeID) then
					local iNeedScore = skynet.call(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","getScore")
					if iNeedScore >= 2000000 then
						local randRate = arc4.random(1,100)
						if randRate <= 30 then
							skynet.call(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","changeScore",2000000,true)
							local item = {
								goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_WORD_JIE_3,
								goodsCount = 1
							}
							table.insert(catchFishGoodsItem,item)
							skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
								item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG)
						end
					end
				end
			end

			if fishTraceInfo.fishKind == 37 then
				local randRate = arc4.random(1,100)
				if randRate <= 40 then
					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_WORD_REN,
						goodsCount = 1
					}
					table.insert(catchFishGoodsItem,item)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
						item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_HUO_DONG)
				end
			end
		end

		local haveSend = false
		if isBossFish(fishTraceInfo.fishKind) then
			local insertTime = os.date("%Y-%m-%d %H:%M:%S", os.time())
		  	local sql = string.format("INSERT INTO `kfrecorddb`.`t_reward_gold_fish_or_boss` (`UserId`, `Type`, `ServerId`, `FishiId`, `Multiple`, `AddGold`, `CurGold`, `Date`) values (%d,2,%d,%d,%d,%d,%d,'%s')",
				userAttr.userID,serverConfig.ServerID,fishTraceInfo.fishKind,bulletInfo.multiple,fishScore,gameData.fishScore,insertTime)	
			local mysqlConn = addressResolver.getMysqlConnection()
			skynet.send(mysqlConn, "lua", "execute", sql)

			local isOpen = skynet.call(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","changeScore",fishScore,true)
			if isOpen then
				local serverConfig = _data.tableFrame.getServerConfig()
				local mysqlConn = addressResolver.getMysqlConnection()
				local randRate = arc4.random(1,100)
				if isThousandRoom(serverConfig.NodeID) then
					if randRate <= 50 then
						local item = {
							goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD_KEY,
							goodsCount = 1
						}
						table.insert(catchFishGoodsItem,item)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
  							item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)
						local sql = string.format("insert into `kfrecorddb`.`t_record_key` (`UserId`,`ServerId`,`KeyId`,`KeyCount`,`Date`) values (%d,%d,%d,%d,now())",
							userAttr.userID,serverConfig.ServerID,item.goodsID,item.goodsCount)	
						skynet.send(mysqlConn, "lua", "execute", sql)	
					end
				elseif isWanRoom(serverConfig.NodeID) then
					if randRate <= 50 then
						local item = {
							goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_MOON_KEY,
							goodsCount = 1
						}
						table.insert(catchFishGoodsItem,item)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
  							item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)
						local sql = string.format("insert into `kfrecorddb`.`t_record_key` (`UserId`,`ServerId`,`KeyId`,`KeyCount`,`Date`) values (%d,%d,%d,%d,now())",
							userAttr.userID,serverConfig.ServerID,item.goodsID,item.goodsCount)	
						skynet.send(mysqlConn, "lua", "execute", sql)
					end
				end	

				skynet.send(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","resetScore")
			end

			--宝箱价值:银宝箱=20元 金宝箱=50元 铂金宝箱=100元
			local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_BOX_DROP_VALUE
        	local iSumBoxValue = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "GetLimitCount",userAttr.userID,limitId)
			local iRandRate = arc4.random(1,100)
			if isBasicRoom(serverConfig.NodeID) then
				local limitId_1 = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_KILL_BOSS_1
        		local iKillBossCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "GetLimitCount",userAttr.userID,limitId_1)
				local iMaxBoxDropValue = 40 - iSumBoxValue
				if userAttr.contribution - 200 > 0 then
					iMaxBoxDropValue = iMaxBoxDropValue + (userAttr.contribution-200)*0.2
				end
				local iRate = 10 + iKillBossCount*0.15
				skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitId_1,1)

				if iMaxBoxDropValue - 20 >= 0 then
					if iRandRate <= iRate then
						local item = {
							goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_SILVE_BOX,
							goodsCount = 1
						}
						table.insert(catchFishGoodsItem,item)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
  							item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_DROP_BOX)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitId,20)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "ResetLimitCount",userAttr.userID,limitId_1)
					end
				end
			elseif isThousandRoom(serverConfig.NodeID) then
				local limitId_2 = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_KILL_BOSS_2
        		local iKillBossCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "GetLimitCount",userAttr.userID,limitId_2)
				local iMaxBoxDropValue = 40 - iSumBoxValue
				if userAttr.contribution - 200 > 0 then
					iMaxBoxDropValue = iMaxBoxDropValue + (userAttr.contribution-200)*0.2
				end
				local iRate = 10 + iKillBossCount*0.15
				skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitId_2,1)
				
				if iMaxBoxDropValue - 50 >= 0 then
					if iRandRate <= iRate then
						local item = {
							goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD_KEY,
							goodsCount = 1
						}
						table.insert(catchFishGoodsItem,item)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
  							item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_DROP_BOX)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitId,50)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "ResetLimitCount",userAttr.userID,limitId_2)
					end
				end
			else
				local limitId_3 = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_KILL_BOSS_3
        		local iKillBossCount = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "GetLimitCount",userAttr.userID,limitId_3)
				local iMaxBoxDropValue = 40 - iSumBoxValue
				if userAttr.contribution - 200 > 0 then
					iMaxBoxDropValue = iMaxBoxDropValue + (userAttr.contribution-200)*0.2
				end
				local iRate = 10 + iKillBossCount*0.15
				skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitId_3,1)

				if iMaxBoxDropValue - 100 >= 0 then
					if iRandRate <= iRate then
						local item = {
							goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_MOON_KEY,
							goodsCount = 1
						}	
						table.insert(catchFishGoodsItem,item)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
  							item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_DROP_BOX)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitId,100)
						skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "ResetLimitCount",userAttr.userID,limitId_3)
					end
				end
			end

			-- if isWanRoom(serverConfig.NodeID) then
			-- 	local iRandRate = arc4.random(1,100)
			-- 	if iRandRate <= 50 then
			-- 		local item = {
			-- 			goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_SHEN_DEGN,
			-- 			goodsCount = _data.fengHuang.fengHuangPoolGold
			-- 		}
			-- 		table.insert(catchFishGoodsItem,item)

			-- 		skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
  	-- 					item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)

			-- 		local iScore = skynet.call(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","getScore")
			-- 		if iScore < 4000000 then
			-- 			skynet.send(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","resetScore")
			-- 		end
			-- 	end
			-- end

			local itemInfo = ""
			local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
			for k, v in pairs(catchFishGoodsItem) do 
				if v.goodsID ~= COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
					local itemInfoConfig = skynet.call(configAddress,"lua","GetItemConfigInfo",v.goodsID)
					if itemInfoConfig then
						itemInfo = itemInfo..itemInfoConfig.itemName.."*".. tostring(v.goodsCount).."!"
					end
				end
			end
			
			local nickName = COMMON_CONST.HideNickName(userAttr.nickName)
			local msg = string.format("恭喜%s玩家击杀%d倍%s,获得%d金币",nickName,fishMultiple,fishConfigItem.name,fishScore)
			if itemInfo ~= "" then
				msg = msg .. ",掉落" .. itemInfo
			end

			haveSend = true
			_data.tableFrame.sendSystemMessage(msg, true, false, false, false)
		end	
		
		if fishMultiple >= 321 and haveSend == false then
			local nickName = COMMON_CONST.HideNickName(userAttr.nickName)
			local msg = string.format("恭喜%s玩家捕中%d倍%s,获得%d金币!",nickName,fishMultiple,fishConfigItem.name,fishScore)
			_data.tableFrame.sendSystemMessage(msg, true, false, false, false)
		end
	end
	
	if volcano then
		volcano.checkOpen(userItem, fishMultiple)
	end
	
	if fishTraceInfo.fishKind==40 then				--如果是美人鱼
		if _data.mermaidClothesID < 3 then
			_data.mermaidClothesID = _data.mermaidClothesID + 1
		end
		
		timerUtility.clearTimer(_data.timerIDHash.endScene)
		timerUtility.setTimeout(onTimerEndScene, FISH_CONST.TIMER.TICKSPAN_AFTER_MERMAID)
	elseif fishTraceInfo.fishKind==21 then			--如果是定屏炸弹
		timerUtility.setTimeout(onTimerLockTimeout, FISH_CONST.TIMER.TICKSPAN_FREEZE_BOMB)
		stopBuildFishTraceTimer()
	end
	
	--无效炮掉落
	if fishTraceInfo.fishKind ~= 34 and fishTraceInfo.fishKind ~= 35 then
	 	local iGold = skynet.call(addressResolver.getAddressByServiceName("GS_model_invalidGun"), "lua", "CheckInvalidGun",userItem)
	 	if iGold ~= 0 then
	 		local goods = {
				goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_BAG_1,
				goodsCount = math.floor(iGold*0.9)
			}

			if goods.goodsCount > 100000 then
				goods.goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_BAG_3
			elseif goods.goodsCount > 50000 then
				goods.goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_BAG_2
			end

			table.insert(catchFishGoodsItem,goods)

			gameData.fishScore = gameData.fishScore + goods.goodsCount
			fishScore = fishScore + goods.goodsCount

			gameData.totalScore = gameData.totalScore + goods.goodsCount

			skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
			  	COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,goods.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)

			local sql = string.format("insert into `kfrecorddb`.`t_user_invalid_gun_record`(`UserId`,`ItemId`,`ItemCount`,`Date`) values(%d,%d,%d,NOW())",userAttr.userID,goods.goodsID,goods.goodsCount)
			local dbConn = addressResolver.getMysqlConnection()
			skynet.send(dbConn,"lua","execute",sql)
	 	end
	 end

	if not isSpecialFish(fishTraceInfo.fishKind) then
		local randRate = arc4.random()*100
		if randRate <= 1 then
			local goods = {
				goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_FAST,
				goodsCount = 1
			}
			table.insert(catchFishGoodsItem,goods)
			skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
				goods.goodsID,goods.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)
		elseif 1 < randRate and randRate <=  2 then
			local goods = {
				goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_LOCK,
				goodsCount = 1
			}
			table.insert(catchFishGoodsItem,goods)
			skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
				goods.goodsID,goods.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)
		end

		if fishTraceInfo.fishKind ~= 34 and fishTraceInfo.fishKind ~= 35 then
			local item = { 
				goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_JEWEL,
				goodsCount = 0,
			}

			--if fishMultiple >= 35 then
			if isRewardGoldFish(fishTraceInfo.fishKind) then
				local baseRate = 40
				local gunLevel = skynet.call(addressResolver.getAddressByServiceName("GS_model_gunUplevel"), "lua", "GetGunLevel",userAttr.userID)
				if gunLevel >= 11 then
					baseRate = 10
				end

				local randRate = arc4.random()*100
				if userAttr.memberOrder ~= 0 then 
					local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
					local infoConfig = skynet.call(configAddress,"lua","GetvipInfo")
					if randRate <= baseRate*infoConfig[userAttr.memberOrder].gem then
						item.goodsCount = arc4.random(5,10)
					end
				else
					if arc4.random(1,100) <= baseRate then	
						item.goodsCount = arc4.random(5,10)
					end
				end
			end

			local canDrop = skynet.call(addressResolver.getAddressByServiceName("GS_model_gunUplevel"), "lua", "IsDropGem",userAttr.userID)
			if canDrop then
				item.goodsCount = item.goodsCount + 1
				skynet.send(addressResolver.getAddressByServiceName("GS_model_gunUplevel"), "lua", "DropGem",userAttr.userID)
			end

			if item.goodsCount ~= 0 then
				table.insert(catchFishGoodsItem,item)
				skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
					item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)
			end
		end
	end

	if isBaoTuFish(fishTraceInfo.fishKind) then
		local rate = arc4.random(1,100)
		local isLimit = true
		local limitId = 0
		local goodsId = COMMON_CONST.ITEM_ID.ITEM_ID_CANG_BAO_TU_1
		if isBasicRoom(serverConfig.NodeID) then
			limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_1
		elseif isThousandRoom(serverConfig.NodeID) then
			limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_2
			if rate > 50 then
				goodsId = COMMON_CONST.ITEM_ID.ITEM_ID_CANG_BAO_TU_2
			end
		else
			limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_3
			if rate > 50 then
				goodsId = COMMON_CONST.ITEM_ID.ITEM_ID_CANG_BAO_TU_2
			end
		end

		isLimit = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "CheckIsForeverLimit",userAttr.userID,limitId,1)
		if not isLimit then
			skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitId,1)
		end

		local randRate = arc4.random(1,100)
		if randRate <= 10 or not isLimit then
			local goods = {
				goodsID = goodsId,
				goodsCount = 1
			}
			table.insert(catchFishGoodsItem,goods)
			skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
				goods.goodsID,goods.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)
		end
	end


	--当前炮台是火焰炮台时 掉落增加
	local limitId_PAOTAI = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_PAO_TAI_LV
	local nowPaotai = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "GetLimitCount",userAttr.userID,limitId_PAOTAI)
	if nowPaotai == COMMON_CONST.SPEC_CANNON.CANNON_FIRE then
		--处理掉落池子 boss鱼每次掉落2-3 黄金鱼25%掉落1个
		--当池子用完 减少宝箱池子10/个
		local limitFirePiece = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_FIRE_PIECE --微粒池子
		local nowFirePieceTotal = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "GetLimitCount",userAttr.userID,limitFirePiece)
		local limitBoxValue = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_BOX_DROP_VALUE --宝箱池子
		local nowBoxValue = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "GetLimitCount",userAttr.userID,limitBoxValue)

		local iMaxBoxDropValue = 0
		iMaxBoxDropValue = 40 - nowBoxValue
		if userAttr.contribution - 200 > 0 then
			iMaxBoxDropValue = iMaxBoxDropValue + (userAttr.contribution-200)*0.2
		end		

		if nowFirePieceTotal>0 then
			if isRewardGoldFish(fishTraceInfo.fishKind) then
				local iRandRate = arc4.random(1,100)
				if iRandRate<20 then
					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_FIRE_PIECE,
						goodsCount = 1
					}	
					table.insert(catchFishGoodsItem,item)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
  						item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitFirePiece,-1)
				end
			elseif isBossFish(fishTraceInfo.fishKind) then
				local iRandRate = arc4.random(1,100)
				local _count = 2+iRandRate%2;
				if iRandRate<80 then
					if nowFirePieceTotal < _count then
						_count=nowFirePieceTotal
					end
					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_FIRE_PIECE,
						goodsCount = _count
					}	
					table.insert(catchFishGoodsItem,item)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
  						item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitFirePiece,_count*(-1))
				end
			end
		elseif iMaxBoxDropValue>=10 then --当火焰微粒池子耗尽 使用宝箱掉落池
			if isRewardGoldFish(fishTraceInfo.fishKind) then
				local iRandRate = arc4.random(1,100)
				if iRandRate<20 then
					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_FIRE_PIECE,
						goodsCount = 1
					}	
					table.insert(catchFishGoodsItem,item)		

					skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
  						item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitBoxValue,10)								

				end
			elseif isBossFish(fishTraceInfo.fishKind) then
				local iRandRate = arc4.random(1,100)
				local _count = 2+iRandRate%2;
				if iRandRate<80 then
					if iMaxBoxDropValue/10 < _count then
						_count = math.ceil (nowFirePieceTotal/10)
					end
					local item = {
						goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_FIRE_PIECE,
						goodsCount = _count
					}	
					table.insert(catchFishGoodsItem,item)	

					skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
  						item.goodsID,item.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)
					skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitBoxValue,_count*10)				
				end
			end	
		end

	end


	local pbParser = resourceResolver.get("pbParser")
	local packetStr = skynet.call(pbParser, "lua", "encode", 0x02000B, {
		chairID=userAttr.chairID,
		fishID=fishTraceInfo.fishID,
		fishKind=fishTraceInfo.fishKind,
		fishScore=fishScore,
		fishMulti=fishMultiple,
		catchFishGoodsItem = catchFishGoodsItem,
		bCirt = bCrit,
	}, true)
	if packetStr then
		_data.tableFrame.broadcastTable(packetStr)
		_data.tableFrame.broadcastLookon(packetStr)
	end
end

local function getRandomFishID()
	local fishIDList = {}
	for fishID, fishTrace in pairs(_data.fishTraceHash) do
		local fishTime = FISH_CONST.FISH_KIND_VALID_TIME[fishTrace.fishKind]
		if not fishTime then
			goto continue
		end
		fishTime = fishTime*GS_CONST.TIMER.TICK_STEP--变为毫秒
		local nowTick = skynet.now()
		local difftime = nowTick - fishTrace.buildTick
		if fishTime and difftime <= fishTime then
			if difftime >= 3 and difftime+3 <= fishTime then 
				table.insert(fishIDList, fishID)
			end
		end
		::continue::
	end
	
	local length = #fishIDList
	if length>0 then
		return fishIDList[arc4.random(1, length)]
	end
end

local function pbAndroidBigNetCatchFish(userItem, protocalData)
	local userAttr = ServerUserItem.getAttribute(userItem, {"userID","chairID", "isAndroid", "agent", "userID"})
	if not userAttr.isAndroid then
		error(string.format("onAndroidBigNetCatchFish: 非机器人用户发了机器人专用协议 userID=%d", userAttr.userID))
	end
	
	local gameData = getGameDataItem(userAttr.chairID)
	
	local bulletInfo = gameData.bulletInfoHash[protocalData.bulletID]
	if not bulletInfo then
		return
	end

	local catchIDList = {}
	if _data.currentScene == FISH_CONST.SCENE_KIND.SCENE_KIND_6 and _data.hasRealUser then
		--由于美人鱼鱼阵只有一条鱼，故有玩家的时候不让打到美人鱼
	else
		if protocalData.androidType == FISH_CONST.ANDROID_TYPE.AT_RANDOM then
			--普通随机打鱼的机器人
			local fishID = getRandomFishID()
			if fishID then
				table.insert(catchIDList, fishID)
			end
		else
			for fishID, traceItem in pairs(_data.fishTraceHash) do
				if traceItem.fishKind > 16 then
					table.insert(catchIDList, fishID)
					break
				end
			end
		end
	end


	for _, fishID in ipairs(catchIDList) do
		doCatchFish(userItem, fishID, bulletInfo, #catchIDList)

	end

	gameData.bulletInfoHash[protocalData.bulletID] = nil
end

local function pbUserSkillStatus( userItem, protocalData )
	local userAttr = ServerUserItem.getAttribute(userItem, {"chairID", "isAndroid", "agent"})
	
	local respObj = {
		chairID = protocalData.chairID,
		skillType = protocalData.skillType,
		skillStutus = protocalData.skillStutus,
		skillLeftOverTime = protocalData.skillLeftOverTime,
	}

	local pbParser = resourceResolver.get("pbParser")
	local packetStr = skynet.call(pbParser, "lua", "encode", 0x020011, respObj, true)
	if packetStr then
		if userAttr.isAndroid then
			_data.tableFrame.broadcastTable(packetStr)
		else
			_data.tableFrame.broadcastTable(packetStr)
			--_data.tableFrame.broadcastTableWithExcept(packetStr, userItem)
		end
		
		_data.tableFrame.broadcastLookon(packetStr)
	end
end

local function pbUserFort( userItem, protocalData )
	local respObj = {
		fortOption = protocalData.fortOption,
		fortLevel = protocalData.fortLevel,
		chairID = protocalData.chairID,
	}
	local pbParser = resourceResolver.get("pbParser")
	local packetStr = skynet.call(pbParser, "lua", "encode", 0x020012, respObj, true)
	if packetStr then
		_data.tableFrame.broadcastTableWithExcept(packetStr, userItem)
		-- _data.tableFrame.broadcastTable(packetStr)
		_data.tableFrame.broadcastLookon(packetStr)
	end

	local userAttr = ServerUserItem.getAttribute(userItem, {"chairID","userID",})
	if userAttr then
		local limitid = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_PAO_TAI_LV
		skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "ResetLimitCount",userAttr.userID,limitid)
		skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userAttr.userID,limitid,protocalData.fortOption)
	end
end

-- local function pbUserLockFish( userItem, protocalData )
-- 	local respObj = {
-- 		chairID = protocalData.chairID,
-- 		fishID = protocalData.fishID,
-- 	}
	
-- 	local pbParser = resourceResolver.get("pbParser")
-- 	local packetStr = skynet.call(pbParser, "lua", "encode", 0x020013, respObj, true)
-- 	if packetStr then
-- 		_data.tableFrame.broadcastTable(packetStr)
-- 		_data.tableFrame.broadcastLookon(packetStr)
-- 	end
-- end

local function pbCallFish( userItem, protocalData )
	local pbObj = {
		code = 0,
	}
	local userAttr = ServerUserItem.getAttribute(userItem, {"agent", "userID"})

	if pbObj.code == 0 then
		if _data.fengHuang.bFengHuangScene then
			pbObj.code = 2
		end
		if _data.bWorldBossScene then
			pbObj.code = 3
		end
	end

	if pbObj.code == 0 then
		local serverConfig = _data.tableFrame.getServerConfig()
		if not isWanRoom(serverConfig.NodeID) then
			pbObj.code = 4
		end
	end

	if pbObj.code == 0 then
		local itemList = {}
		local goods = {
			goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_SHEN_DEGN,
			goodsCount = 1,
		}
		table.insert(itemList,goods)

		local bSuccess = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "CheckItemAndComsume",userAttr.userID,itemList,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_USE)
		if not bSuccess then
			--神灯不够的时候消耗砖石
			itemList = {}
			goods.goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_JEWEL
			goods.goodsCount = 2000
			table.insert(itemList,goods)
			local bSuccess_1 = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "CheckItemAndComsume",userAttr.userID,itemList,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_USE)
			if not bSuccess_1 then
				pbObj.code = 1
			end
		end
	end

	if pbObj.code == 0 then
		skynet.error(string.format("----------------召唤凤凰------------------------"))
		flushFengHuang(true)
	end

	skynet.send(userAttr.agent, "lua", "forward", 0x020015,pbObj)
end

local function pbBigNetCatchFish(userItem, protocalData)
	local userAttr = ServerUserItem.getAttribute(userItem, {"userID","chairID", "isAndroid", "agent"})
	local gameData = getGameDataItem(userAttr.chairID)
	
	local bulletInfo = gameData.bulletInfoHash[protocalData.bulletID]
	if not bulletInfo then
		return
	end
	
	if protocalData.catchFishIDList == nil then
		protocalData.catchFishIDList = {}
	end

	local catchIDList = {}
	for _, fishID in ipairs(protocalData.catchFishIDList) do
		if _data.fishTraceHash[fishID] then
			table.insert(catchIDList, fishID)
		end
	end
	
	if #catchIDList==0 then
		gameData.bulletCompensate = gameData.bulletCompensate + bulletInfo.multiple
		if not userAttr.isAndroid then
			addSystemScorePool(gameData, -bulletInfo.multiple)

			skynet.send(addressResolver.getAddressByServiceName("GS_model_invalidGun"),"lua","AddInvalidGunData",userItem,bulletInfo.multiple)
		
			if not _data.bWorldBossScene then
				_data.m_iWorldBossLocalPool = _data.m_iWorldBossLocalPool + bulletInfo.multiple*0.04
				--skynet.error(string.format("-------无效炮=%d,现在总的分数=%d--------------",bulletInfo.multiple,_data.m_iWorldBossLocalPool))
			end
		end
	end

	--冰冻炮台效果判断和分发
	local limitId_PAOTAI = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_PAO_TAI_LV
	local nowPaotai = skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "GetLimitCount",userAttr.userID,limitId_PAOTAI)
	local frozenIDList = {}

	for _, fishID in ipairs(catchIDList) do
		doCatchFish(userItem, fishID, bulletInfo, #catchIDList)
		if nowPaotai == COMMON_CONST.SPEC_CANNON.CANNON_ICE then
			local iRandRate = arc4.random(1,100)			
			if iRandRate==1 then
				table.insert(frozenIDList, fishID)
			end
		end
	end

	if #frozenIDList>0 then
		local pbParser = resourceResolver.get("pbParser")
		local packetStr = skynet.call(pbParser, "lua", "encode", 0x020017, {fishIDList=frozenIDList}, true)
		if packetStr then
			_data.tableFrame.broadcastTable(packetStr)
			_data.tableFrame.broadcastLookon(packetStr)
		end

	end
	
	gameData.bulletInfoHash[protocalData.bulletID] = nil
end

local function pbCatchSweepFish(userItem, protocalData)
	local sweepFishInfo = _data.sweepFishHash[protocalData.sweepID]
	if not sweepFishInfo then
		return
	end

	local userAttr = ServerUserItem.getAttribute(userItem, {"chairID", "isAndroid", "agent", "nickName", "userID"})
	local gameData = getGameDataItem(userAttr.chairID)

	if sweepFishInfo.chairID ~= userAttr.chairID then
		--error(string.format("---fish----error---userid=%d---charid=%d,usercharid=%d---",userAttr.userID,sweepFishInfo.chairID,userAttr.chairID))
		return
	end

	_data.sweepFishHash[protocalData.sweepID] = nil
	
	-- 局部炸弹:22  超级炸弹:23    鱼王:30~39
	if sweepFishInfo.fishKind~=21 and sweepFishInfo.fishKind~=22 and sweepFishInfo.fishKind~=23 then
		error(string.format("fishKind=%d, 鱼的种类不属于炸弹", sweepFishInfo.fishKind))
	end
	
	local fishMultipleMax = getfishMultiple(sweepFishInfo.fishKind)
	local fishMultiple = 0
	
	for _, fishID in ipairs(protocalData.fishIDList) do
		local fishTraceInfo = _data.fishTraceHash[fishID]
		if fishTraceInfo then
			if fishTraceInfo.fishKind~=21 and fishTraceInfo.fishKind~=22 and fishTraceInfo.fishKind~=23 then
				fishMultiple = fishMultiple + getfishMultiple(fishTraceInfo.fishKind, fishTraceInfo.fishID)
			end
			_data.fishTraceHash[fishID] = nil
		end
	end
	if fishMultiple > fishMultipleMax then
		fishMultiple = fishMultipleMax
	end
	
	local score = fishMultiple * sweepFishInfo.bulletMultiple
	if not userAttr.isAndroid and isRewardGoldFish(sweepFishInfo.fishKind) then
		skynet.send(addressResolver.getAddressByServiceName("GS_model_reward_gold_fish"),"lua","ChangeRewardGfInfo",userAttr.userID,1,math.floor(score*0.1))
		 score = score - math.floor(score*0.1)
	end

	gameData.fishScore = gameData.fishScore + score

	skynet.call(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","changeScore",score,true)

	skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
	 		COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,score,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH)

	_data.tableFrame.onMatchScoreChange(userItem, score)
	if not userAttr.isAndroid then
		addSystemScorePool(gameData, -score)
	end


	-- if fishMultiple>= 280 then
	-- 	local fishConfigItem = _data.config.fishHash[sweepFishInfo.fishKind]
	-- 	if fishConfigItem ~= nil then
	-- 		local msg = string.format("恭喜%s玩家捕中%d倍%s,获得%d金币!",userAttr.nickName,fishMultiple,fishConfigItem.name,score)
	-- 		_data.tableFrame.sendSystemMessage(msg, true, false, false, false)
	-- 	end
	-- end
	
	if volcano then
		volcano.checkOpen(userItem, fishMultiple)
	end
	
	local pbParser = resourceResolver.get("pbParser")
	local packetStr = skynet.call(pbParser, "lua", "encode", 0x02000C, {
		chairID=userAttr.chairID,
		sweepID=protocalData.sweepID,
		fishScore=score,
		fishMulti=fishMultiple,
		fishIDList=protocalData.fishIDList,
		catchSweepFishResultGoodsItem = {},
	}, true)
	if packetStr then
		_data.tableFrame.broadcastTable(packetStr)
		_data.tableFrame.broadcastLookon(packetStr)
	end
end

local function pbMessage(userItem, protocalNo, protocalData)
	if protocalNo==0x020000 then
		pbUserFire(userItem, protocalData)
	elseif protocalNo==0x020008 then
		pbBigNetCatchFish(userItem, protocalData)
	elseif protocalNo==0x02000C then
		pbCatchSweepFish(userItem, protocalData)
	elseif protocalNo==0x02000F then
		pbAndroidBigNetCatchFish(userItem, protocalData)
	elseif protocalNo == 0x020011 then
		pbUserSkillStatus( userItem, protocalData )
	elseif protocalNo == 0x020012 then
		pbUserFort( userItem, protocalData )
	-- elseif protocalNo == 0x020013 then
	-- 	pbUserLockFish( userItem, protocalData )
	elseif protocalNo == 0x020015 then
		pbCallFish( userItem, protocalData )
	end
end

local function onEventGameStart(multipleLv) 
	startBuildFishTraceTimer()
	
	_data.timerIDHash.switchScene = timerUtility.setInterval(onTimerSwitchScene,FISH_CONST.TIMER.TICKSPAN_SWITCH_SCENE)
	_data.timerIDHash.clearTrace = timerUtility.setInterval(onTimerClearTrace, FISH_CONST.TIMER.TICKSPAN_CLEAR_TRACE)
	_data.timerIDHash.writeScore = timerUtility.setInterval(onTimerWriteScore, FISH_CONST.TIMER.TICKSPAN_WRITE_SCORE)
	timerUtility.setInterval(onTimerUploadWorldBossPollScore, 2)

	if volcano then
		_data.timerIDHash.volcanoStoreNetWin = timerUtility.setInterval(volcano.storeNetWin, FISH_CONST.TIMER.TICKSPAN_VOLCANO_STORE_NET_WIN)
	end

	if multipleLv ~= nil and multipleLv ~= 0 then
		_data.fengHuang.minPaoMult = multipleLv
		skynet.error(string.format("-----------设置炮台等级--lv=%d-------------------------",multipleLv))
	end

	--checkFlushTaskFish()
end

local function calcScoreAndLock(chairID)
	local gameData = getGameDataItem(chairID)
	gameData.isScoreLocked = true
	calcScore(chairID, true)
end

local function releaseScoreLock(chairID)
	local gameData = getGameDataItem(chairID)
	gameData.isScoreLocked = false
end

local function initialize(tableFrame, criticalSection)
	cleanUp()

	_data.tableFrame = tableFrame
	_criticalSection = criticalSection
	
	_data.config = require(string.format("config.fish_%d", _data.tableFrame.getServerConfig().ServerID))
	_data.tableFrame.setStartMode(GS_CONST.START_MODE.TIME_CONTROL)
	_data.fengHuang.minPaoMult = _data.config.cannonMultiple.min
	
	_data.nextScene = FISH_CONST.SCENE_KIND.SCENE_KIND_101
	_data.currentScene = _data.nextScene
	
	for pathType, pathConfig in pairs(_data.config.pathType) do
		pathUtility.initPathConfig(pathType, pathConfig.min, pathConfig.max, pathConfig.intervalTicks)
	end
	
	local tableFrameSink = {
		addSystemScorePool = addSystemScorePool,
		getGameDataItem = getGameDataItem,
	}
	
	local serverType = _data.tableFrame.getServerConfig().ServerType
	if (serverType & GS_CONST.GAME_GENRE.MATCH)==0 and (serverType & GS_CONST.GAME_GENRE.EDUCATE)==0 and _data.config.volcano and _data.config.volcano.isEnable then
		volcano = require "fish.lualib.volcano"
		volcano.initialize(_data.config.volcano, _data.tableFrame, tableFrameSink)
	end
end

local function reloadTableFrameConfig()
	local t = skynet.getenv("tablfFrameConfig")
	if t == nil then
		return
	end
	local f = io.open(skynet.getenv("tablfFrameConfig"), "rb")
	if not f then
		return
	end
	local source = f:read "*a"
	f:close()
	_data.config = load(source)()
end

local function _flushWorldBoss()
	_data.specialSceneEndTick = skynet.now() + COMMON_CONST.WORLD_BOSS.LIVE_TIME * GS_CONST.TIMER.TICK_STEP
	_data.timerIDHash.endScene = timerUtility.setTimeout(onTimerEndScene, COMMON_CONST.WORLD_BOSS.LIVE_TIME)

	if _data.bSpecial then
		buildFishTrace(1, 33, 33)
	else
		buildFishTrace(1, 29, 29)
	end

	if _data.fengHuang.bFengHuangScene then
		_data.fengHuang.elapseTime = skynet.now() - _data.fengHuang.startTime
	end

	local pbParser = resourceResolver.get("pbParser")
	local packetStr = skynet.call(pbParser,"lua","encode",0x014001,{},true)
	if packetStr then
		_data.tableFrame.broadcastTable(packetStr)
		_data.tableFrame.broadcastLookon(packetStr)
	end
end

local function flushWorldBoss()
	_criticalSection(_flushWorldBoss)
end

local function worldBossStart(data,startTime)
	stopBuildFishTraceTimer()
	clearFishTrace(true,true)
	_data.bWorldBossScene = true
	_data.isSpecialScene = true
	_data.rewardPool = data.rewardPool
	_data.bSpecial = data.bSpecial
	_data.worldBoss.index = data.index
	_data.worldBoss.userID = data.userID
	_data.worldBoss.addRate = data.addRate
	_data.worldBoss.addRateTime = data.addRateTime
	_data.worldBoss.worldBossAddRateTime = data.worldBossAddRateTime
	_data.worldBoss.lastKillWorldBossUserId = data.lastKillWorldBossUserId
	if startTime ~= nil then
		_data.worldBossStartTime = startTime
	end

	if _data.timerIDHash.switchScene then
		timerUtility.clearTimer(_data.timerIDHash.switchScene)
		_data.timerIDHash.switchScene = nil
	end

	if _data.timerIDHash.endScene then
		timerUtility.clearTimer(_data.timerIDHash.endScene)
		_data.timerIDHash.endScene = nil
	end

	if _data.timerIDHash.clearTrace then
		timerUtility.clearTimer(_data.timerIDHash.clearTrace)
		_data.timerIDHash.clearTrace = nil
	end

	flushWorldBoss()
end

local function sendWorldBossInvalidGold()
	for chairId, v in pairs(_data.chairID2GameData) do
		if v.iWorldBossGold ~= 0 then
			local userItem = _data.tableFrame.getUserItem(chairId)
			if userItem then
				local userAttr = ServerUserItem.getAttribute(userItem, {"userID"})
				v.fishScore = v.fishScore + v.iWorldBossGold
				skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",userAttr.userID,
					COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,v.iWorldBossGold,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_FISH,true)
				v.iWorldBossGold = 0
			end
		end
	end
end

local function worldBossEnd()
	if _data.timerIDHash.endScene then
		timerUtility.clearTimer(_data.timerIDHash.endScene)
		_data.timerIDHash.endScene = nil
	end

	clearFishTrace(true,true)
	_data.bWorldBossScene = false
	_data.worldBossStartTime = 0
	_data.rewardPool = 0
	_data.bSpecial = false
	_data.worldBoss.index = 0
	_data.worldBoss.userID = 0
	_data.worldBoss.addRate = 0
	_data.worldBoss.addRateTime = 0
	_data.worldBoss.worldBossAddRateTime = 0
	--timerUtility.setTimeout(onTimerEndScene, 1)
	_onTimerEndScene()
	_data.timerIDHash.clearTrace = timerUtility.setInterval(onTimerClearTrace, FISH_CONST.TIMER.TICKSPAN_CLEAR_TRACE)
	_data.timerIDHash.switchScene = timerUtility.setInterval(onTimerSwitchScene,FISH_CONST.TIMER.TICKSPAN_SWITCH_SCENE)
		
	sendWorldBossInvalidGold()

	if _data.fengHuang.bFengHuangScene then
		stopBuildFishTraceTimer()
		clearFishTrace(true,true)
		_data.isSpecialScene = true

		if _data.timerIDHash.switchScene then
			timerUtility.clearTimer(_data.timerIDHash.switchScene)
			_data.timerIDHash.switchScene = nil
		end

		if _data.timerIDHash.endScene then
			timerUtility.clearTimer(_data.timerIDHash.endScene)
			_data.timerIDHash.endScene = nil
		end

		local iLeftTime = FENG_HUANG_LIVE_TIME - _data.fengHuang.elapseTime/GS_CONST.TIMER.TICK_STEP,

		skynet.error(string.format("--------------凤凰时间-----iLeftTime=%s,elapseTime=%s----------------------------",iLeftTime,_data.fengHuang.elapseTime))


		_data.specialSceneEndTick = skynet.now() +  iLeftTime*GS_CONST.TIMER.TICK_STEP
		_data.timerIDHash.endScene = timerUtility.setTimeout(onTimerEndScene, iLeftTime)

		for fishID, traceItem in pairs(_data.fishTraceHash) do
			if traceItem.fishKind == 30 then
				traceItem.buildTick = skynet.now() - _data.fengHuang.elapseTime
				break
			end
		end
	end
end

local function worldBossInit()
	local data = skynet.call(addressResolver.getAddressByServiceName("GS_model_tableManager"), "lua", "GetTableStatus")
	if data.status == 1 then
		worldBossStart(data,data.startTime)
	end
end

local function NotifyWorldBossTime(agent)
	local pbObj = {
		list = {},
		bossType = 0,
	}

	local nowTick = skynet.now()
	local bFind = false
	for fishID, traceItem in pairs(_data.fishTraceHash) do
		if traceItem.fishKind == 29 or traceItem.fishKind == 33 then
			table.insert(pbObj.list,{
				fishKind=traceItem.fishKind,
				fishID=traceItem.fishID,
				pathID = 0,
				fishElapsedTime = math.floor((nowTick - traceItem.buildTick)/GS_CONST.TIMER.TICK_STEP),
			})

			bFind = true
			if _data.bSpecial then
				pbObj.bossType = 1
			end

			skynet.send(agent,"lua","forward",0x014005,pbObj)
		end
	end

	--boss优先凤凰
	if not bFind then
		for fishID, traceItem in pairs(_data.fishTraceHash) do
			if traceItem.fishKind == 30 then
				table.insert(pbObj.list,{
					fishKind=traceItem.fishKind,
					fishID=traceItem.fishID,
					pathID = 0,
					fishElapsedTime = math.floor((nowTick - traceItem.buildTick)/GS_CONST.TIMER.TICK_STEP),
				})


				skynet.error(string.format("--------凤凰出生时间=%s,nowTick=%s------------------------",traceItem.buildTick,nowTick))

				skynet.send(agent,"lua","forward",0x014005,pbObj)
			end
		end
	end
end

local function ChangeTaskGoodsCount(chairID,pbObj)

	local bFind = false

	local gameData = getGameDataItem(chairID)
	if gameData then
		if pbObj.taskType == COMMON_CONST.TASK_TYPE.TASK_FISH and pbObj.taskID == _data.taskFish.taskId then
			for k, v in pairs(gameData.taskFishInfo.goalInfo) do
				for kk, vv in pairs(pbObj.taskGoodsInfoList) do 
					if v.goalId == vv.goodsID then
						v.goalCount = v.goalCount - vv.goodsCount

						if v.goalCount >= 0 then
							gameData.taskFishInfo.fishCount = gameData.taskFishInfo.fishCount + 1
							bFind = true
						end
						break
					end
				end
			end
		end 
	end

	if bFind then
	 	NotifyTaskFishRankInfo()
	 end
end

local function CompleteTask(chairID,pbObj)
	local gameData = getGameDataItem(chairID)
	if gameData then
		if pbObj.taskType == COMMON_CONST.TASK_TYPE.TASK_FISH and pbObj.taskID == _data.taskFish.taskId then
			local bFind = false
			for k, v in pairs(gameData.taskFishInfo.goalInfo) do
				if v.goalCount > 0 then
					bFind = true
					break
				end
			end

			if not bFind then
				local rewardGold = 0
				local userItem = _data.tableFrame.getUserItem(chairID)
				if userItem then
					local attr = ServerUserItem.getAttribute(userItem, {"userID"})
					for kk, vv in pairs(gameData.taskFishInfo.rewardList) do
						if vv.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
							ServerUserItem.addAttribute(userItem, {score=vv.goodsCount})
							onUserScoreNotify(chairID,userItem)
							rewardGold = rewardGold + vv.goodsCount
						end

						skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",attr.userID,
				 			vv.goodsID,vv.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_TASK,true)
					end

					local dbConn = addressResolver.getMysqlConnection()
					local sql = string.format("insert into `kfrecorddb`.`task_record` (`UserId`,`TaskType`,`TaskId`,`CommitTime`,`RewardGold`) values(%d,%d,%d,'%s',%d)",
						attr.userID,pbObj.taskType,pbObj.taskID,os.date('%Y-%m-%d %H:%M:%S', math.floor(skynet.time())),rewardGold)
					skynet.send(dbConn, "lua", "execute", sql)

				end

				if _data.timerIDHash.notifyTaskFishEnd then
					timerUtility.clearTimer(_data.timerIDHash.notifyTaskFishEnd)
					_data.timerIDHash.notifyTaskFishEnd = nil
				end

				notifyUserTaskFishEnd(true)
			end
		end 
	end
end

local function TaskSynchronizationTime(chairID)
	if _data.taskFish.taskId == 0 then
		return
	end

	local info = {
		taskType = 2,
		taskLeftTime = COMMON_CONST.TASK_FISH_TIME - (os.time()-_data.taskFish.startTime)
	}

	local gameData = getGameDataItem(chairID)
	if gameData then
		local userItem = _data.tableFrame.getUserItem(chairID)
		if userItem then
			local attr = ServerUserItem.getAttribute(userItem, {"agent","userID"})
			if attr.agent ~= 0 then
				skynet.send(attr.agent,"lua","forward",0x010805 ,info)
			end
		end
	end
end

local function setControlRateConfig(rateConfig)
	_data.rateConfig = rateConfig
end

return {
	initialize = initialize,
	getPlayerTryScore = getPlayerTryScore,
	pbMessage = pbMessage,
	calcScoreAndLock = calcScoreAndLock,
	releaseScoreLock = releaseScoreLock,
	
	onActionUserSitDown = onActionUserSitDown,
	onActionUserStandUp = onActionUserStandUp,
	onActionUserGameOption = onActionUserGameOption,
	onEventGameStart = onEventGameStart,
	onEventGameConclude = onEventGameConclude,
	onUserScoreNotify = onUserScoreNotify,
	onUserGoldRecordChange = onUserGoldRecordChange,
	reloadTableFrameConfig = reloadTableFrameConfig,

	worldBossStart = worldBossStart,
	worldBossEnd = worldBossEnd,
	worldBossInit = worldBossInit,
	SaveInvalidGunGold = SaveInvalidGunGold,
	NotifyWorldBossTime = NotifyWorldBossTime,
	ChangeTaskGoodsCount = ChangeTaskGoodsCount,
	CompleteTask = CompleteTask,
	TaskSynchronizationTime = TaskSynchronizationTime,
	setControlRateConfig = setControlRateConfig,
}

