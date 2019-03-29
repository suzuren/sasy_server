require "utility.string"
local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local GS_CONST = require "define.gsConst"
local addressResolver = require "addressResolver"
local resourceResolver = require "resourceResolver"
local randHandle = require "utility.randNumber"
local timerUtility = require "utility.timer"
local timeUtility = require "utility.time"
local cluster = require "cluster"
local inspect = require "inspect"

local _serverConfig
local _tableHash = {}

local _data = { --世界boss
	status = 0,
	localPool = 0,
	rewardPool = 0,
	startTime = 0,
	bSpecial = false, --true 为定时刷出的boss
	index = 0,
	userID = 0,
	addRate = 0,
	addRateTime = 0,
	worldBossAddRateTime = 0,
	lastKillWorldBossUserId = 0,
}
local _LS_worldBossAddress
local ls_huoDong = {
	_LS_huoDong = nil,
	redPacketRank = {},
	redPacketKillRecord = {}
}

local function cmd_onEventLoginSuccess(data)
	if not data.isAndroid then	
		local tableList = {
			list = {},
			vipList= {},
		}
		for tableID, item in ipairs(_tableHash) do
			if data.serverID == 220 then
				if tableID <= GS_CONST.VIP_TABLEID_LOW then
					table.insert(tableList.list, {tableID=tableID, isLocked=item.state.isLocked, isStarted=item.state.isStarted, sitCount=item.state.sitCount,needVipLv=item.state.needVipLv,multipleLv=item.state.multipleLv,tablePassword=item.state.tablePassword,tableType=item.state.tableType})
				else
					if item.state.sitCount > 0 then
						table.insert(tableList.vipList, {tableID=tableID, isLocked=item.state.isLocked, isStarted=item.state.isStarted, sitCount=item.state.sitCount,needVipLv=item.state.needVipLv,multipleLv=item.state.multipleLv,tablePassword=item.state.tablePassword,tableType=item.state.tableType})
					end
				end
			else
				table.insert(tableList.list, {tableID=tableID, isLocked=item.state.isLocked, isStarted=item.state.isStarted, sitCount=item.state.sitCount,needVipLv=item.state.needVipLv,multipleLv=item.state.multipleLv,tablePassword=item.state.tablePassword,tableType=item.state.tableType})
			end
		end
		
		skynet.send(data.agent, "lua", "forward", 0x010105, tableList)
	end
end

local function cmd_getTableFrame(tableID)
	local item = _tableHash[tableID]
	if item then
		return item.addr
	end
end

local function cmd_findAvailableTable(roomType)
	local allowDynamicJoin = (_serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_ALLOW_DYNAMIC_JOIN) ~= 0
	--选桌方式优化，优先选择有人的桌--现在改为：对半选择桌子
	local tableAddrList = {}--桌上没人列表
	local validAddrList = {}--桌上有人列表
	local vipAddrList = {} --vip桌子没人列表
	for k, v in ipairs(_tableHash) do
		if (not v.state.isStarted or allowDynamicJoin) and v.state.sitCount < _serverConfig.ChairPerTable and not v.state.isLocked then
			if _serverConfig.ServerID == 220 then
				if k <= GS_CONST.VIP_TABLEID_LOW then
					if v.state.sitCount > 0 then
						table.insert(validAddrList, v.addr)
					else
						table.insert(tableAddrList, v.addr)
					end
				else
					if v.state.sitCount == 0 then
						table.insert(vipAddrList, v.addr)
					end
				end
			else
				if v.state.sitCount > 0 then
					table.insert(validAddrList, v.addr)
				else
					table.insert(tableAddrList, v.addr)
				end
			end
		end
	end

	if roomType == 1 then 
		if #(vipAddrList) > 0 then
			return vipAddrList[1]
		else
			return
		end
	end	

	local iRandValue = randHandle.random(0,2)
	if iRandValue <= 1 then
		if #(validAddrList) > 0 then
			local index = randHandle.random(1, #(validAddrList))
			return validAddrList[index]
		end
	else
		if #(tableAddrList) > 0 then
			local index = randHandle.random(1, #(tableAddrList))
			return tableAddrList[index]
		end
	end

	if #(validAddrList) > 0 then
		local index = randHandle.random(1, #(validAddrList))
		return validAddrList[index]
	end
	if #(tableAddrList) > 0 then
		local index = randHandle.random(1, #(tableAddrList))
		return tableAddrList[index]
	end
	return
end

local function cmd_findAvailableTableByScore(score)
	--根据用户分数选择桌子
	local allowDynamicJoin = (_serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_ALLOW_DYNAMIC_JOIN) ~= 0
	--选桌方式优化，优先选择有人的桌
	local tableAddrList = {}--桌上没人列表
	local validAddrList = {}--桌上有人列表
	for _, v in ipairs(_tableHash) do
		if (not v.state.isStarted or allowDynamicJoin) and v.state.sitCount < _serverConfig.ChairPerTable then
			if v.state.sitCount > 0 and v.state.sitCount == _serverConfig.ChairPerTable-1 then
				local minScore = skynet.call(v.addr, "lua", "getSitUserMinScore")
				if score > minScore then
					table.insert(validAddrList, v.addr)
				end
			else
				if v.state.sitCount > 0 then					
					table.insert(validAddrList, v.addr)
				else
					table.insert(tableAddrList, v.addr)
				end
			end
		end
	end

	local iRandValue = randHandle.random(0,2)
	if iRandValue <= 1 then
		if #(validAddrList) > 0 then
			local index = randHandle.random(1, #(validAddrList))
			return validAddrList[index]
		end
	else
		if #(tableAddrList) > 0 then
			local index = randHandle.random(1, #(tableAddrList))
			return tableAddrList[index]
		end
	end

	if #(validAddrList) > 0 then
		local index = randHandle.random(1, #(validAddrList))
		return validAddrList[index]
	end
	if #(tableAddrList) > 0 then
		local index = randHandle.random(1, #(tableAddrList))
		return tableAddrList[index]
	end
	return
end

local function cmd_findAvailableTableForNiuniu(score,userID,platformID)
	local validAddrList = {}
	local rmbGold = 0
	local openBoxSumGold = 0

	for _, v in ipairs(_tableHash) do
		table.insert(validAddrList, v.addr)
	end

	local sql = string.format("SELECT score FROM `kfrecorddb`.`UserPayScore` where platformID = %d",platformID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if rows[1] ~= nil then
		rmbGold = rows[1].score
	end

	local sql = string.format("SELECT SumGold FROM `kfrecorddb`.`t_record_gold_by_use_box` where UserId=%d",userID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if rows[1] ~= nil then
		openBoxSumGold = rows[1].SumGold
	end

	if score >= 4*(openBoxSumGold+rmbGold) + 2000000 then
		return validAddrList[#(validAddrList)]
	else
		local iCount = #(validAddrList)-1
		if iCount == 0 then
			iCount = #(validAddrList)
		end
		local index = randHandle.random(1,iCount)
		return validAddrList[index]
	end

	return nil
end	

local function cmd_tableStateChange(tableID, stateObj)
	local item = _tableHash[tableID]
	if item then
		if stateObj.isLocked ~= nil then
			item.state.isLocked = stateObj.isLocked
		end
		
		if stateObj.isStarted ~= nil then
			item.state.isStarted = stateObj.isStarted
		end
		
		if stateObj.sitCount ~= nil then
			item.state.sitCount = stateObj.sitCount
		end

		if stateObj.needVipLv ~= nil then
			item.state.needVipLv = stateObj.needVipLv
		end	

		if stateObj.multipleLv ~= nil then
			item.state.multipleLv = stateObj.multipleLv
		end

		if stateObj.tablePassword ~= nil then
			item.state.tablePassword = stateObj.tablePassword
		end

		local pbParser = resourceResolver.get("pbParser")
		local packetStr = skynet.call(pbParser, "lua", "encode", 0x010104, {
			tableID=tableID,
			isLocked=item.state.isLocked,
			isStarted=item.state.isStarted,
			sitCount=item.state.sitCount,
			needVipLv = item.state.needVipLv,
			multipleLv = item.state.multipleLv,
			tablePassword = item.state.tablePassword,
			tableType = item.state.tableType,
		}, true)
		if packetStr then
			skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "broadcast", packetStr)
		end		
	end
end

local function cmd_reloadTableFrameConfig()
	for _, v in ipairs(_tableHash) do
		skynet.send(v.addr, "lua", "reloadTableFrameConfig")
	end
end	

local function cmd_NotifyWorldBossStartOrEnd(data)
	if data.status == 1 then
		_data.status = 1
		_data.startTime = os.time()
		_data.rewardPool = data.poolScore
		_data.bSpecial = data.bSpecial
		_data.index = data.index
		_data.userID = data.userID
		_data.addRate = data.addRate
		_data.addRateTime = data.addRateTime
		_data.worldBossAddRateTime = data.worldBossAddRateTime
		_data.lastKillWorldBossUserId = data.lastKillWorldBossUserId
		for _, v in ipairs(_tableHash) do
			if v.state.isStarted then
				skynet.send(v.addr, "lua", "NotifyWorldBossStart",_data)
			end
		end
	elseif data.status == 2 then
		_data.status = 0
		_data.bSpecial = false
		_data.index = 0
		_data.userID = 0
		_data.addRate = 0
		_data.addRateTime = 0
		_data.worldBossAddRateTime = 0
		for _, v in ipairs(_tableHash) do
			if v.state.isStarted then
				skynet.send(v.addr, "lua", "NotifyWorldBossEnd",data.bKillFalg)
			end
		end
	end
end

local function cmd_killWorldBoss(data)
	cluster.call("loginServer", _LS_worldBossAddress, "killWorldBoss", data)
end

local function cmd_addWorldBossLocalPool(num) -- 每个房间上传奖池
	_data.localPool = _data.localPool + num
end

local function uploadWorldBossPoolAdd() -- 每5s上传同步一次
	if not _data.bSpecial then
		if _data.localPool > 0 then
			local score = _data.localPool
			_data.localPool = 0
			if _LS_worldBossAddress ~= nil then
				_data.rewardPool = cluster.call("loginServer", _LS_worldBossAddress, "addWorldBossPoolScore", score)
			end
		end
	end
end

local  function cmd_GetTableStatus()
	return _data
end

local function LoadControlRateConfig()
	local rateConfig = {
		normalConfig = {},
		fishConfig = {},
		critConfig = {},
		worldBoss = {},
		timeBoss = {},
	}

	local sql = string.format("SELECT * FROM `kffishdb`.`t_user_control_rate`")
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, row in ipairs(rows) do
			local info = {
				userId = tonumber(row.UserId),
				fishList = {},
				crit = 0,
				miss = 0,
				addRate = 0,
				worldBossAddRate = 0,
				fengHuangAddRate = 0,
			}

			if row.FishInfo ~= nil then
				local list = row.FishInfo:split("|")
				for _, item in pairs(list) do
					local itemPart = item:split(":")
					local fish = {
						fishKind = tonumber(itemPart[1]),
						rate = tonumber(itemPart[2])
					}
					table.insert(info.fishList,fish)
				end
			end

			if row.Crit ~= nil then
				info.crit = tonumber(row.Crit)
			end

			if row.Miss ~= nil then
				info.miss = tonumber(row.Miss)
			end

			if row.AddRate ~= nil then
				info.addRate = tonumber(row.AddRate)
			end

			if row.WorldBossAddRate ~= nil then
				info.worldBossAddRate = tonumber(row.WorldBossAddRate)
			end

			if row.FengHuangAddRate ~= nil then
				info.fengHuangAddRate = tonumber(row.FengHuangAddRate)
			end

			table.insert(rateConfig.normalConfig,info)
		end
	end

	sql = string.format("SELECT * FROM `kffishdb`.`t_control_fish_rate`")
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, row in ipairs(rows) do
			local info = {
				userId = tonumber(row.UserId),
				fishKind = tonumber(row.FishId),
				addRate = tonumber(row.AddRate),
				startTime = timeUtility.makeTimeStamp(row.StartTime),
				endTime = timeUtility.makeTimeStamp(row.EndTime),
			}

			local tempInfo = rateConfig.fishConfig[info.userId]
			if tempInfo then
				table.insert(tempInfo,info)
				rateConfig.fishConfig[info.userId] = tempInfo
			else
				local tempInfo = {}
				table.insert(tempInfo,info)
				rateConfig.fishConfig[info.userId] = tempInfo
			end
		end
	end

	sql = string.format("SELECT * FROM `kffishdb`.`t_control_crit_rate`")
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, row in ipairs(rows) do
			local info = {
				userId = tonumber(row.UserId),
				fishKind = tonumber(row.FishId),
				critRate = tonumber(row.CritRate),
				missRate = tonumber(row.MissRate),
				startTime = timeUtility.makeTimeStamp(row.StartTime),
				endTime = timeUtility.makeTimeStamp(row.EndTime),
			}

			local tempInfo = rateConfig.critConfig[info.userId]
			if tempInfo then
				table.insert(tempInfo,info)
				rateConfig.critConfig[info.userId] = tempInfo
			else
				local tempInfo = {}
				table.insert(tempInfo,info)
				rateConfig.critConfig[info.userId] = tempInfo
			end
		end
	end

	sql = string.format("SELECT * FROM `kffishdb`.`t_control_world_boss_rate`")
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, row in ipairs(rows) do
			local info = {
				index = tonumber(row.Index),
				userId = tonumber(row.UserId),
				addRate = tonumber(row.AddRate),
			}
			
			table.insert(rateConfig.worldBoss,info)
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

			table.insert(rateConfig.timeBoss,info)
		end
	end

	for _, v in ipairs(_tableHash) do
		skynet.send(v.addr, "lua", "setControlRateConfig",rateConfig)
	end
end

local function cmd_addRedPacketInfo(data) 
	table.insert(ls_huoDong.redPacketRank,data)
end

local function cmd_AddRedPacketKillRecord(data)
	table.insert(ls_huoDong.redPacketKillRecord,data)
end

local function uploadRedPacketInfo() -- 每10s上传同步一次
	if next(ls_huoDong.redPacketRank) then
		local data = ls_huoDong.redPacketRank
		ls_huoDong.redPacketRank = {}
		if ls_huoDong._LS_huoDong ~= nil then
			cluster.call("loginServer", ls_huoDong._LS_huoDong, "AddRedPacketRank", data)
		end
	end

	if next(ls_huoDong.redPacketKillRecord) then
		local data = ls_huoDong.redPacketKillRecord
		ls_huoDong.redPacketKillRecord = {}
		if ls_huoDong._LS_huoDong ~= nil then
			cluster.call("loginServer", ls_huoDong._LS_huoDong, "AddRedPacketKillRecord", data)
		end
	end
end

local function cmd_GetTableIsLock(tableID)
	local item = _tableHash[tableID]
	if item then
		return item.state.isLocked
	end

	return false
end

local conf = {
	methods = {
		["getTableFrame"] = {["func"]=cmd_getTableFrame, ["isRet"]=true},
		["findAvailableTable"] = {["func"]=cmd_findAvailableTable, ["isRet"]=true},
		["tableStateChange"] = {["func"]=cmd_tableStateChange, ["isRet"]=true},
		["findAvailableTableByScore"] = {["func"]=cmd_findAvailableTableByScore, ["isRet"]=true},
		["findAvailableTableForNiuniu"] = {["func"]=cmd_findAvailableTableForNiuniu, ["isRet"]=true},
		
		["onEventLoginSuccess"] = {["func"]=cmd_onEventLoginSuccess, ["isRet"]=false},
		["reloadTableFrameConfig"] = {["func"]=cmd_reloadTableFrameConfig, ["isRet"]=false},

		["NotifyWorldBossStartOrEnd"] = {["func"]=cmd_NotifyWorldBossStartOrEnd, ["isRet"]=true},
		["killWorldBoss"] = {["func"]=cmd_killWorldBoss, ["isRet"]=false},
		["addWorldBossLocalPool"] = {["func"]=cmd_addWorldBossLocalPool, ["isRet"]=false},
		["GetTableStatus"] = {["func"]=cmd_GetTableStatus, ["isRet"]=true},
		["addRedPacketInfo"] = {["func"]=cmd_addRedPacketInfo, ["isRet"]=false},
		["AddRedPacketKillRecord"] = {["func"]=cmd_AddRedPacketKillRecord, ["isRet"]=false},
		["GetTableIsLock"] = {["func"]=cmd_GetTableIsLock, ["isRet"]=true},
	},
	-- CAttemperEngineSink::OnAttemperEngineStart
	initFunc = function()
		resourceResolver.init()
		
		_serverConfig = skynet.call(addressResolver.getAddressByServiceName("GS_model_serverStatus"), "lua", "getServerData")
		if not _serverConfig then
			error("server config not initialized")
		end
		
		for i=1, _serverConfig.TableCount do
			local tbAddr = skynet.newservice("GS_model_tableFrame")
			skynet.call(tbAddr, "lua", "initialize", i, _serverConfig)

			local tableType = 0
			if _serverConfig.ServerID == 220 then
				if i > GS_CONST.VIP_TABLEID_LOW then
					tableType = 1
				end
			end
			_tableHash[i] = {addr=tbAddr, state={isLocked=false, isStarted=false, sitCount=0, needVipLv=0, multipleLv=0, tablePassword=nil,tableType=tableType}}
		end
		
		skynet.error(string.format("%s initFunc func - ",SERVICE_NAME),
		"_serverConfig-\n",inspect(_serverConfig),
		"\n_tableHash-\n",inspect(_tableHash))

		local GS_EVENT = require "define.eventGameServer"
		skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "addEventListener", GS_EVENT.EVT_GS_LOGIN_SUCCESS, skynet.self(), "onEventLoginSuccess")
	
		ls_huoDong._LS_huoDong = cluster.query("loginServer", "LS_model_huoDong")
		_LS_worldBossAddress = cluster.query("loginServer", "LS_model_worldBoss")
		local temp = cluster.call("loginServer", _LS_worldBossAddress, "GetWorldBossInfo")
		_data.status = temp.status
		_data.rewardPool = temp.poolScore
		_data.startTime = temp.startTime
		_data.localPool = 0

		timerUtility.start(GS_CONST.TIMER.TICK_STEP)
		timerUtility.setInterval(uploadWorldBossPoolAdd, 5)
		timerUtility.setInterval(LoadControlRateConfig, 10)
		timerUtility.setInterval(uploadRedPacketInfo, 10)
	end,
}

commonServiceHelper.createService(conf)

