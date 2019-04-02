local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local resourceResolver = require "resourceResolver"
local timerUtility = require "utility.timer"
local COMMON_CONST = require "define.commonConst"
local ServerUserItem = require "sui"
local inspect = require "inspect"

local _data = {
	poolScore = 0,	--奖池积分
	status = 0,	--0未开始,1开始了
	startTime = 0,
	nextTime = 0,
	needNotifyInvalidScore = false,	--是否要通知无效金币
	killBossUserList = {},			--普通世界boss击杀记录
	killBossuserList_ex = {},		--定时刷的世界boss击杀记录
	worldBossOverTimer = nil,		--结束定时器
	worldBossWriteSocreTimer = nil, --写奖池积分定时器
	FlushWorldBossTimer = nil,		--刷新世界boss定時器
	HourFlushBossFlag = false,		--定点刷boss
	WorldBossFlag = false,			--普通世界boss
	timeConfig = {					--定点刷
		timeFlush = {
			[0] = {hour=3,min=0,poolScore=6666666,isActivity=true},
			[1] = {hour=3,min=30,poolScore=6666666,isActivity=true},
			[2] = {hour=20,min=0,poolScore=3000000,isActivity=false},
			[3] = {hour=20,min=30,poolScore=3000000,isActivity=false},
			[4] = {hour=21,min=0,poolScore=3000000,isActivity=false},
			[5] = {hour=21,min=30,poolScore=3000000,isActivity=false},
			[6] = {hour=22,min=0,poolScore=3000000,isActivity=false},
			[7] = {hour=22,min=30,poolScore=3000000,isActivity=false},
			[8] = {hour=23,min=0,poolScore=3000000,isActivity=false},
			[9] = {hour=23,min=30,poolScore=3000000,isActivity=false},
		},
		notTimeFlush = {
			[0] = {startHour=1,startMin=50,endHour=3,endMin=40,isActivity=true},
			[1] = {startHour=19,startMin=50,endHour=23,endMin=40,isActivity=false},
		},
		activityTime = {
			startTime = 20161223000000,
			endTime = 30170103000000,
		},
		poolScore = 0,
		flushTime = 0,	--判断同一时刻只刷一次用
		notTimeFlushFlag = false,--进入定时boss刷新通知用
		addRateTime = 0,	--定时boss概率提升时间
		worldBossAddRateTime = 0, --世界boss概率提升时间
		activity2normal = false, --活动boss到普通定时boss过度的状态,通知客户端改变icon用
	},
	rateConfig = {
		worldBoss = {},
		timeBoss = {},
	},
	lastKillWorldBossUserId = 0,--上次击杀世界boss玩家id
	bKillFalg = false,			--宝藏boss是否被杀了
}

local function reloadControlConfig()
	_data.rateConfig.worldBoss = {}
	_data.rateConfig.timeBoss = {}

	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("SELECT * FROM `kffishdb`.`t_control_world_boss_rate`")
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, row in ipairs(rows) do
			local info = {
				index = tonumber(row.Index),
				userId = tonumber(row.UserId),
				addRate = tonumber(row.AddRate),
			}
			
			table.insert(_data.rateConfig.worldBoss,info)
		end
	end

	sql = string.format("SELECT * FROM `kffishdb`.`t_control_time_boss_rate`")
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, row in ipairs(rows) do
			local info = {
				index = tonumber(row.Index),
				userId = tonumber(row.UserId),
				addRate = tonumber(row.AddRate),
			}

			table.insert(_data.rateConfig.timeBoss,info)
		end
	end
end

local function notifyWorldBossInfoToGS()
	local info = {
		status = 2,
		poolScore = _data.poolScore,
		bSpecial = false,
		index = 0,
		userID = 0,
		addRate = 0,
		addRateTime = _data.timeConfig.addRateTime,
		worldBossAddRateTime = _data.timeConfig.worldBossAddRateTime,
		lastKillWorldBossUserId = _data.lastKillWorldBossUserId,
		bKillFalg = _data.bKillFalg,
	}

	if _data.status ~= 0 then
		info.status = _data.status
	end

	if _data.status == 1 then
		if _data.HourFlushBossFlag then
			info.poolScore = _data.timeConfig.poolScore
			info.bSpecial = true
		end

		--reloadControlConfig()

		local userList = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getAllUserInfo")
		local bFind = false
		if _data.WorldBossFlag then
			for k, v in pairs(_data.rateConfig.worldBoss) do
				for kk, vv in pairs(userList) do
					local attr = ServerUserItem.getAttribute(vv.sui, {"userID"})
					if attr then
						if v.userId == attr.userID then
							info.index = v.index
							info.userID = v.userId
							info.addRate = v.addRate
							bFind = true
							break
						end
					end
				end

				if bFind then
					break
				end
			end
		else
			for k, v in pairs(_data.rateConfig.timeBoss) do
				for kk, vv in pairs(userList) do
					local attr = ServerUserItem.getAttribute(vv.sui, {"userID"})
					if attr then
						if v.userId == attr.userID then
							info.index = v.index
							info.userID = v.userId
							info.addRate = v.addRate
							bFind = true
							break
						end
					end
				end

				if bFind then
					break
				end
			end
		end
	end

	local serverList = skynet.call(addressResolver.getAddressByServiceName("LS_model_serverManager"), "lua", "getServerIDListByKindID", 2010)

	--skynet.error(string.format("%s notifyWorldBossInfoToGS func - ",SERVICE_NAME),"serverList-\n",inspect(serverList),"\ninfo-\n",inspect(info))

	if serverList then
		skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", serverList, COMMON_CONST.LSNOTIFY_EVENT.EVT_LSNOTIFY_WORLD_BOSS_START_OR_END, info)
	end
end

local function NotifyWorldBossStart()
	local pbParser = resourceResolver.get("pbParser")
	local packetStr = skynet.call(pbParser, "lua", "encode", 0x007001, {}, true)
	local userList = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getAllUserInfo")
	for _, v in pairs(userList) do 
		local attr = ServerUserItem.getAttribute(v.sui, {"agent"})
		if attr and attr.agent ~= 0 then
			skynet.send(attr.agent, "lua", "forward", packetStr)
		end
	end
end

function CheckWorldBossEnd(userID,nickName)
	local pbObj = {
		killResult = 0,
		nextBossLeftTime = 0,
		userID = 0,	
		killBossGetGoods = {},
		userNickName = nickName,
		bossType = 0,
	}

	_data.timeConfig.notTimeFlushFlag = false

	local bSpecial = false
	local poolScore = _data.poolScore
	if _data.HourFlushBossFlag then
		poolScore = _data.timeConfig.poolScore
		bSpecial = true
		pbObj.bossType = 1
	end

	if userID ~= nil then
		pbObj.userID = userID
		pbObj.killResult = 1
		local goods = {
			goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
			goodsCount = poolScore,
		}
		table.insert(pbObj.killBossGetGoods,goods)

		_data.status = 0
		_data.startTime = 0
		_data.nextTime = 0
		_data.FlushWorldBossTimer = nil

		if _data.HourFlushBossFlag then
			_data.HourFlushBossFlag = false
			_data.timeConfig.poolScore = 0
			_data.timeConfig.addRateTime = 0
			_data.bKillFalg = true
		else
			_data.poolScore = 0
			_data.WorldBossFlag = false
			_data.timeConfig.worldBossAddRateTime = 0
			_data.lastKillWorldBossUserId = userID
			_data.bKillFalg = false
		end
	else
		if _data.HourFlushBossFlag then
			_data.HourFlushBossFlag = false
			_data.timeConfig.poolScore = 0
			_data.timeConfig.addRateTime = _data.timeConfig.addRateTime + COMMON_CONST.WORLD_BOSS.LIVE_TIME
		else
			_data.timeConfig.worldBossAddRateTime = _data.timeConfig.worldBossAddRateTime + COMMON_CONST.WORLD_BOSS.LIVE_TIME
			_data.WorldBossFlag = false
			pbObj.nextBossLeftTime = COMMON_CONST.WORLD_BOSS.DIFF_TIME
			_data.nextTime = os.time() + COMMON_CONST.WORLD_BOSS.DIFF_TIME
			_data.FlushWorldBossTimer = timerUtility.setTimeout(FlushWorldBoss,COMMON_CONST.WORLD_BOSS.DIFF_TIME)
		end
		_data.status = 0
		_data.startTime = 0
		_data.bKillFalg = false
	end

	--通知游戏服务器世界boss结束
	notifyWorldBossInfoToGS()

	local pbParser = resourceResolver.get("pbParser")
	local packetStr = skynet.call(pbParser, "lua", "encode", 0x007002, pbObj, true)
	local userList = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getAllUserInfo")
	for _, v in pairs(userList) do 
		local attr = ServerUserItem.getAttribute(v.sui, {"agent", "userStatus", "serverID"})
		if attr and attr.agent ~= 0 then
			skynet.send(attr.agent, "lua", "forward", packetStr)
		end
	end
end

function FlushWorldBoss()
	_data.status = 1
	_data.startTime = os.time()
	_data.nextTime = 0
	_data.WorldBossFlag = true
	_data.bKillFalg = false

	notifyWorldBossInfoToGS()
 	NotifyWorldBossStart()

	 _data.worldBossOverTimer = timerUtility.setTimeout(CheckWorldBossEnd, COMMON_CONST.WORLD_BOSS.LIVE_TIME)
end

local function loadData()
	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("SELECT * FROM `kffishdb`.`t_world_boss_score`")
	local rows = skynet.call(dbConn,"lua","query",sql)
	if rows[1] ~= nil then
		_data.poolScore = tonumber(rows[1].PoolScore)

		if _data.poolScore >= COMMON_CONST.WORLD_BOSS.NEED_SCORE then
			_data.FlushWorldBossTimer = timerUtility.setTimeout(FlushWorldBoss,COMMON_CONST.WORLD_BOSS.DIFF_TIME)
			_data.nextTime = os.time() + COMMON_CONST.WORLD_BOSS.DIFF_TIME
		end
	end

	local sql = string.format("SELECT a.UserId,b.NickName,a.WinScore,b.MemberOrder,UNIX_TIMESTAMP(a.Date) as submitTime FROM kfrecorddb.t_world_boss_record a LEFT JOIN kfaccountsdb.accountsinfo b on a.UserId = b.UserID where bossType = 0 ORDER BY submitTime DESC LIMIT 10")
	local rows = skynet.call(dbConn,"lua","query",sql)
	for _, row in ipairs(rows) do
		local info = {
			killDate = tonumber(row.submitTime),
			killBossGetGoods = {},
			userNickName = row.NickName,
			userVip = tonumber(row.MemberOrder), 
		}
		local goods = {
			goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
			goodsCount = tonumber(row.WinScore),
		}
		table.insert(info.killBossGetGoods,goods)
		table.insert(_data.killBossUserList,info)
	end

	local sql = string.format("SELECT a.UserId,b.NickName,a.WinScore,b.MemberOrder,UNIX_TIMESTAMP(a.Date) as submitTime FROM kfrecorddb.t_world_boss_record a LEFT JOIN kfaccountsdb.accountsinfo b on a.UserId = b.UserID where bossType = 1 ORDER BY submitTime DESC LIMIT 10")
	local rows = skynet.call(dbConn,"lua","query",sql)
	for _, row in ipairs(rows) do
		local info = {
			killDate = tonumber(row.submitTime),
			killBossGetGoods = {},
			userNickName = row.NickName,
			userVip = tonumber(row.MemberOrder), 
		}
		local goods = {
			goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
			goodsCount = tonumber(row.WinScore),
		}
		table.insert(info.killBossGetGoods,goods)
		table.insert(_data.killBossuserList_ex,info)
	end

	local sql = string.format("SELECT * FROM  kfrecorddb.t_world_boss_record ORDER BY ID DESC LIMIT 1")
	local rows = skynet.call(dbConn,"lua","query",sql)
	if rows[1] ~= nil then
		_data.lastKillWorldBossUserId = tonumber(rows[1].UserId)
	end
end

local function WriteWorldBossScore()
	--local dbConn = addressResolver.getMysqlConnection()
	--local sql = string.format("INSERT INTO `kffishdb`.`t_world_boss_score` VALUES (1,%d) ON DUPLICATE KEY UPDATE `PoolScore`=VALUES(`PoolScore`)",_data.poolScore)
	--skynet.send(dbConn,"lua","execute",sql)
end

local function NotifyInvalidScore(agent)
	local poolScore = _data.poolScore
	if _data.HourFlushBossFlag then
		poolScore = _data.timeConfig.poolScore
	end

	if agent ~= nil then
		skynet.send(agent,"lua","forward",0x007003,{invalidCoin=poolScore})
	else
		if _data.needNotifyInvalidScore then
			local userList = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getAllUserInfo")
			for _, v in pairs(userList) do 
				local attr = ServerUserItem.getAttribute(v.sui, {"agent", "userStatus", "serverID"})
				if attr and attr.agent ~= 0 then
					if attr.serverID == 210 or attr.serverID == 220 or attr.serverID == 230 then
						skynet.send(attr.agent,"lua","forward",0x007003,{invalidCoin=poolScore})
					end
				end
			end
			_data.needNotifyInvalidScore = false
		end
	end
end

local function cmd_addWorldBossPoolScore(score)

	_data.poolScore = _data.poolScore + math.floor(score)
	if _data.status ~= 0 then
		return _data.poolScore
	end

	local nowTime = os.time()	
	local nowDate = tonumber(os.date("%Y%m%d%H%M%S",nowTime))
	local nowHour = tonumber(os.date("%H",nowTime))
	local nowMin = tonumber(os.date("%M",nowTime))
	local nowSec = nowHour*60+nowMin
	for k, v in pairs(_data.timeConfig.notTimeFlush) do
		local startTime = tonumber(v.startHour*60 + v.startMin)
		local endTime = tonumber(v.endHour*60 + v.endMin)
		if v.isActivity then
			if _data.timeConfig.activityTime.startTime <= nowDate and nowDate <= _data.timeConfig.activityTime.endTime then
				if startTime <= nowSec and nowSec <= endTime then
					return _data.poolScore
				end
			end
		else
			if startTime <= nowSec and nowSec <= endTime then
				return _data.poolScore
			end
		end
	end

	if _data.poolScore >= COMMON_CONST.WORLD_BOSS.NEED_SCORE and _data.status == 0 and _data.startTime == 0 and _data.FlushWorldBossTimer == nil then
		_data.status = 1
		_data.startTime = os.time()
		_data.nextTime = 0
		_data.WorldBossFlag = true

		_data.needNotifyInvalidScore = true
		NotifyInvalidScore()

		notifyWorldBossInfoToGS()
		NotifyWorldBossStart()

		_data.worldBossOverTimer = timerUtility.setTimeout(CheckWorldBossEnd, COMMON_CONST.WORLD_BOSS.LIVE_TIME)
	end

	_data.needNotifyInvalidScore = true

	return _data.poolScore
end

local function GetTimeBossNextFlushLeftTime()
	local nowTime = os.time()	
	local nowHour = tonumber(os.date("%H",nowTime))
	local nowMin = tonumber(os.date("%M",nowTime))
	local nowSec = tonumber(os.date("%S",nowTime))
	local nowDate = tonumber(os.date("%Y%m%d%H%M%S",nowTime))
	local nowTimeMin = nowHour*60*60+nowMin*60 + nowSec

	for k, v in pairs(_data.timeConfig.notTimeFlush) do
		local startTime = tonumber(v.startHour*60*60 + v.startMin*60)
		local endTime = tonumber(v.endHour*60*60 + v.endMin*60)

		if v.isActivity then
			if _data.timeConfig.activityTime.startTime <= nowDate and nowDate <= _data.timeConfig.activityTime.endTime then
				if nowTimeMin < endTime then
					if nowTimeMin < startTime then
						return false,-1
					end

					if startTime <= nowTimeMin and nowTimeMin <= endTime then
						for k, v in pairs(_data.timeConfig.timeFlush) do
							if v.isActivity then
								local configTime = v.hour*60*60 + v.min*60
								if nowTimeMin <= configTime then
									return true,configTime-nowTimeMin
								end
							end
						end
					end

					return false,0
				end
			end 
		else
			if nowTimeMin < startTime or nowTimeMin >= endTime then
				return false,-1
			end

			if startTime <= nowTimeMin and nowTimeMin <= endTime then
				for k, v in pairs(_data.timeConfig.timeFlush) do
					if not v.isActivity then
						local configTime = v.hour*60*60 + v.min*60
						if nowTimeMin <= configTime then
							return true,configTime-nowTimeMin
						end
					end
				end
			end
		end
	end

	return false,0
end

local function cmd_WorldBossFishInfo(agent,userID,bossType)
	local pbObj = {
		bossFishInfo = {},
		killBossUserInfo = {},
		bossType = bossType,
	}

	local BossFishInfo = {
		bossFishAppearCondition = {},
		bossAllowPaoMult = {},
		bossFishAwardItem = {},
		bossLeftTime = COMMON_CONST.WORLD_BOSS.LIVE_TIME,
		fastFire = 0,
		lockFire = 0,
		nextBossLeftTime = -1,
		bossStatus = 0,
	}

	local needScore = COMMON_CONST.WORLD_BOSS.NEED_SCORE
	if pbObj.bossType == 1 then
		needScore = _data.timeConfig.poolScore
		pbObj.killBossUserInfo = _data.killBossuserList_ex
	else
		pbObj.killBossUserInfo = _data.killBossUserList
	end

	local goods = {
		goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
		goodsCount = needScore,
	}
	table.insert(BossFishInfo.bossFishAppearCondition,goods)

	local goods = {
		goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
		goodsCount = needScore,
	}
	table.insert(BossFishInfo.bossFishAwardItem,goods)

	local multiple = {
		minPaoMult = 100,
		maxPaoMult = 100,
	}
	table.insert(BossFishInfo.bossAllowPaoMult,multiple)

	if _data.startTime ~= 0 then
		BossFishInfo.bossLeftTime = COMMON_CONST.WORLD_BOSS.LIVE_TIME - (os.time()-_data.startTime)
	end

	if pbObj.bossType == 1 then
		BossFishInfo.bossStatus = 1
		if not _data.HourFlushBossFlag then
			local inTimeFlag, time = GetTimeBossNextFlushLeftTime()
			if inTimeFlag then
				BossFishInfo.nextBossLeftTime = time
				BossFishInfo.bossStatus = 2
			else
				if time == -1 then
					BossFishInfo.nextBossLeftTime = 0
					BossFishInfo.bossStatus = 0
				else
					BossFishInfo.nextBossLeftTime = 0
					BossFishInfo.bossStatus = 3
				end
			end
		end
	else
		if _data.WorldBossFlag then
			BossFishInfo.bossStatus = 1
		end

		if _data.poolScore >= COMMON_CONST.WORLD_BOSS.NEED_SCORE and _data.startTime == 0 and _data.nextTime ~= 0 then
			BossFishInfo.nextBossLeftTime = _data.nextTime - os.time()
			BossFishInfo.bossStatus = 2
		end
	end

	table.insert(pbObj.bossFishInfo,BossFishInfo)

	skynet.send(agent,"lua","forward",0x007000,pbObj)
	
	NotifyInvalidScore(agent)
end

local function checkRecordCount()
	if _data.HourFlushBossFlag then
		local iMinIndex = 1
		local iCount = 0
		local tempMinTime = _data.killBossuserList_ex[1].killDate
		for k, v in pairs(_data.killBossuserList_ex) do
			iCount = iCount + 1
			if v.killDate < tempMinTime then
				tempMinTime = v.killDate
				iMinIndex = k
			end
		end

		if iCount > 10 then
			table.remove(_data.killBossuserList_ex,iMinIndex)
		end
	else
		local iMinIndex = 1
		local iCount = 0
		local tempMinTime = _data.killBossUserList[1].killDate
		for k, v in pairs(_data.killBossUserList) do
			iCount = iCount + 1
			if v.killDate < tempMinTime then
				tempMinTime = v.killDate
				iMinIndex = k
			end
		end

		if iCount > 10 then
			table.remove(_data.killBossUserList,iMinIndex)
		end
	end
end

local function cmd_killWorldBoss(data)
	if _data.status == 1 then
		local info = {
			killDate = os.time(),
			killBossGetGoods = {},
			userNickName = data.name,
			userVip = data.vipLv, 
		}

		local bossType = 0
		local poolScore = _data.poolScore
		if _data.HourFlushBossFlag then
			bossType = 1
			poolScore = _data.timeConfig.poolScore
		end

		local goods = {
			goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
			goodsCount = poolScore,
		}
		table.insert(info.killBossGetGoods,goods)

		if _data.HourFlushBossFlag then
			table.insert(_data.killBossuserList_ex,info)
		else
			table.insert(_data.killBossUserList,info)
		end

		checkRecordCount()

		local sql = string.format("insert into `kfrecorddb`.`t_world_boss_record`(UserId,WinScore,Date,bossType) VALUES(%d,%d,NOW(),%d)",data.userID,poolScore,bossType)
		local dbConn = addressResolver.getMysqlConnection()
		skynet.send(dbConn, "lua", "execute", sql)

		if _data.worldBossOverTimer then
			timerUtility.clearTimer(_data.worldBossOverTimer)
			_data.worldBossOverTimer = nil 
		end
		CheckWorldBossEnd(data.userID,data.name)
	end
end

local function cmd_GetWorldBossInfo()
	return {
		status = _data.status,
		poolScore = _data.poolScore,
		startTime = _data.startTime,
	}
end

--活动结束后各个房间
local function cmd_worldBossOverCal(data)
	
end

local function cmd_SynchronizationBossSwimTime(agent,userID)
	local pbObj = {
		bossSwimTime = -1,
	}

	if _data.startTime ~= 0 then
		pbObj.bossSwimTime = os.time() - _data.startTime
	end

	skynet.send(agent,"lua","forward",0x007004,pbObj)
end

local function NotifyUserTimeFlushStart()
	local pbObj = {
		bossFishInfo = {},
		killBossUserInfo = {},
		bossType = 1,
	}

	local BossFishInfo = {
		bossFishAppearCondition = {},
		bossAllowPaoMult = {},
		bossFishAwardItem = {},
		bossLeftTime = COMMON_CONST.WORLD_BOSS.LIVE_TIME,
		fastFire = 0,
		lockFire = 0,
		nextBossLeftTime = -1,
		bossStatus = 0,
	}

	local needScore = COMMON_CONST.WORLD_BOSS.NEED_SCORE
	if pbObj.bossType == 0 then
		pbObj.killBossUserInfo = _data.killBossUserList
	else
		needScore = _data.timeConfig.poolScore
		pbObj.killBossUserInfo = _data.killBossuserList_ex
	end

	local goods = {
		goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
		goodsCount = needScore,
	}
	table.insert(BossFishInfo.bossFishAppearCondition,goods)

	local goods = {
		goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
		goodsCount = needScore,
	}
	table.insert(BossFishInfo.bossFishAwardItem,goods)

	local multiple = {
		minPaoMult = 100,
		maxPaoMult = 100,
	}
	table.insert(BossFishInfo.bossAllowPaoMult,multiple)

	if _data.startTime ~= 0 then
		BossFishInfo.bossLeftTime = COMMON_CONST.WORLD_BOSS.LIVE_TIME - (os.time()-_data.startTime)
	end

	if pbObj.bossType == 1 then
		BossFishInfo.bossStatus = 1
		if not _data.HourFlushBossFlag then
			local inTimeFlag, time = GetTimeBossNextFlushLeftTime()
			if inTimeFlag then
				BossFishInfo.nextBossLeftTime = time
				BossFishInfo.bossStatus = 2
			else
				if time == -1 then
					BossFishInfo.nextBossLeftTime = 0
					BossFishInfo.bossStatus = 0
				else
					BossFishInfo.nextBossLeftTime = 0
					BossFishInfo.bossStatus = 3
				end
			end
		end
	else
		if _data.WorldBossFlag then
			BossFishInfo.bossStatus = 1
		end
		
		if _data.poolScore >= COMMON_CONST.WORLD_BOSS.NEED_SCORE and _data.startTime == 0 and _data.nextTime ~= 0 then
			BossFishInfo.nextBossLeftTime = _data.nextTime - os.time()
			BossFishInfo.bossStatus = 2
		end
	end


	table.insert(pbObj.bossFishInfo,BossFishInfo)

	local pbParser = resourceResolver.get("pbParser")
	local packetStr = skynet.call(pbParser, "lua", "encode", 0x007000, pbObj, true)
	local userList = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getAllUserInfo")
	for _, v in pairs(userList) do 
		local attr = ServerUserItem.getAttribute(v.sui, {"agent", "userID"})
		if attr and attr.agent ~= 0 then
			skynet.send(attr.agent, "lua", "forward", packetStr)
		end
	end
end

local function checkTimeFlushBoss()
	local nowTime = os.time()
	local nowHour = tonumber(os.date("%H",nowTime))
	local nowMin = tonumber(os.date("%M",nowTime))
	local nowDate = tonumber(os.date("%Y%m%d%H%M%S",nowTime))
	local nowTimeMin = nowHour*60 + nowMin

	--skynet.error(string.format("%s checkTimeFlushBoss func - nowTime:%d,nowHour:%d,nowMin:%d,nowDate:%d,nowTimeMin:%d",SERVICE_NAME,nowTime,nowHour,nowMin,nowDate,nowTimeMin))

	if not _data.timeConfig.notTimeFlushFlag or _data.timeConfig.activity2normal then
		for k, v in pairs(_data.timeConfig.notTimeFlush) do
			local startTime = tonumber(v.startHour*60 + v.startMin) 
			local endTime = tonumber(v.startHour*60 + v.endMin)

			if v.isActivity then
				if not _data.timeConfig.activity2normal then
					if _data.timeConfig.activityTime.startTime <= nowDate and nowDate <= _data.timeConfig.activityTime.endTime then
						if nowTimeMin == startTime then
							if _data.FlushWorldBossTimer then
								timerUtility.clearTimer(_data.FlushWorldBossTimer)
								_data.FlushWorldBossTimer = nil
							end
						end

						if nowTimeMin == startTime or nowTimeMin == endTime then
							NotifyUserTimeFlushStart()
							_data.timeConfig.notTimeFlushFlag = true
							if nowTimeMin == endTime then
								_data.timeConfig.activity2normal = true
							end
							break
						end
					end
				end
			else
				if nowTimeMin == startTime then
					if _data.FlushWorldBossTimer then
						timerUtility.clearTimer(_data.FlushWorldBossTimer)
						_data.FlushWorldBossTimer = nil
					end
				end

				if nowTimeMin == startTime or nowTimeMin == endTime then
					NotifyUserTimeFlushStart()
					_data.timeConfig.notTimeFlushFlag = true
					_data.timeConfig.activity2normal = falses
					break
				end
			end
		end
	end

	--skynet.error(string.format("%s checkTimeFlushBoss func - nowTime:%d,nowHour:%d,nowMin:%d,nowDate:%d,nowTimeMin:%d",SERVICE_NAME,nowTime,nowHour,nowMin,nowDate,nowTimeMin),inspect(_data.timeConfig.timeFlush))

	for k, v in pairs(_data.timeConfig.timeFlush) do
		local configTime = v.hour*60 + v.min
		if v.isActivity then
			if nowDate < _data.timeConfig.activityTime.startTime or _data.timeConfig.activityTime.endTime < nowDate then
				goto continue
			end 
		end

		--skynet.error(string.format("%s checkTimeFlushBoss func - nowTimeMin:%d,configTime:%d,HourFlushBossFlag:%s,status:%d,flushTime:%d,nowTimeMin:%d",SERVICE_NAME,nowTimeMin,configTime,_data.HourFlushBossFlag,_data.status,_data.timeConfig.flushTime,nowTimeMin))
		if nowTimeMin == configTime then
		--if nowTimeMin ~= configTime then
			if not _data.HourFlushBossFlag and _data.status == 0 and _data.timeConfig.flushTime ~= nowTimeMin then
				_data.HourFlushBossFlag = true
				_data.timeConfig.poolScore = v.poolScore
				_data.timeConfig.flushTime = nowTimeMin

				if _data.FlushWorldBossTimer then
					timerUtility.clearTimer(_data.FlushWorldBossTimer)
					_data.FlushWorldBossTimer = nil
				end

				_data.status = 1
				_data.startTime = os.time()
				_data.nextTime = 0
				_data.bKillFalg = false
				
				notifyWorldBossInfoToGS()
				NotifyWorldBossStart()

				_data.worldBossOverTimer = timerUtility.setTimeout(CheckWorldBossEnd, COMMON_CONST.WORLD_BOSS.LIVE_TIME)

				_data.needNotifyInvalidScore = true
				NotifyInvalidScore()
			end
		end

		::continue::
	end
end

local conf = {
	methods = {
		["addWorldBossPoolScore"] = {["func"]=cmd_addWorldBossPoolScore, ["isRet"]=true},
		["WorldBossFishInfo"] = {["func"]=cmd_WorldBossFishInfo, ["isRet"]=false},
		["killWorldBoss"] = {["func"]=cmd_killWorldBoss, ["isRet"]=false},
		["GetWorldBossInfo"] = {["func"]=cmd_GetWorldBossInfo, ["isRet"]=true},
		["worldBossOverCal"] = {["func"]=cmd_worldBossOverCal, ["isRet"]=true},
		["SynchronizationBossSwimTime"] = {["func"]=cmd_SynchronizationBossSwimTime, ["isRet"]=false},
	},
	initFunc = function()
		resourceResolver.init()
		timerUtility.start(100)
		_data.worldBossWriteSocreTimer = timerUtility.setInterval(WriteWorldBossScore, 10)
		local timerID_checkTimeFlushBoss = timerUtility.setInterval(checkTimeFlushBoss, 10)
		local timerID_NotifyInvalidScore = timerUtility.setInterval(NotifyInvalidScore, 10)

		--skynet.error(string.format("%s initFunc func - worldBossWriteSocreTimer_%d,timerID_checkTimeFlushBoss_%d,timerID_NotifyInvalidScore_%d", SERVICE_NAME,_data.worldBossWriteSocreTimer,timerID_checkTimeFlushBoss,timerID_NotifyInvalidScore))

		--loadData()
	end,
}

commonServiceHelper.createService(conf)
