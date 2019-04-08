local skynet = require "skynet"
local randHandle = require "utility.randNumber"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local timerUtility = require "utility.timer"
local GS_CONST = require "define.gsConst"
local GS_EVENT = require "define.eventGameServer"
local queue = require "skynet.queue"
local CItemBuffer = require "utility.cItemBuffer"
local AndroidUserItem = require "aui"
local ServerUserItem = require "sui"
local COMMON_CONST = require "define.commonConst"
CItemBuffer.init(AndroidUserItem)

local _criticalSection = queue()
local _serverConfig = nil
local _data = {
	timerIDHash = {},
	androidMap = {},				--原来的androidUserItemMap用来存放userID=>{addr=android服务的地址, androidUserItem=..., serverUserItem=...}
	androidParameterHash = {},
}

local function getTimeMask()
	local t = os.date("*t", math.floor(skynet.time()))
	local timeMask = 1 << t.hour
	return timeMask
end

local function getAndroidUserInfo(serviceGender)
	local timeMask = getTimeMask()
	
	local ret = {
		free = {},
		sit = {},
		play = {},
	}
		
	for userID, androidMapItem in pairs(_data.androidMap) do
		--绑定判断
		if androidMapItem.serverUserItem==nil then
			goto continue
		end
		
		local androidAttr = AndroidUserItem.getAttribute(androidMapItem.androidUserItem, {"androidParameter", "residualPlayDraw"})
		
		--局数判断
		if androidAttr.residualPlayDraw<=0 then
			goto continue
		end
		
		--服务判断
		if (androidAttr.androidParameter.serviceTime & timeMask)==0 then
			goto continue
		end
		if (androidAttr.androidParameter.serviceGender & serviceGender)==0 then
			goto continue
		end
		
		local userAttr = ServerUserItem.getAttribute(androidMapItem.serverUserItem, {"userStatus"})
		if userAttr.userStatus==GS_CONST.USER_STATUS.US_FREE then
			table.insert(ret.free, {androidItem = androidMapItem.androidUserItem, userItem = androidMapItem.serverUserItem, userID = userID,tableID=androidMapItem.tableID})
		elseif userAttr.userStatus==GS_CONST.USER_STATUS.US_SIT or userAttr.userStatus==GS_CONST.USER_STATUS.US_READY then
			table.insert(ret.sit, {androidItem = androidMapItem.androidUserItem, userItem = androidMapItem.serverUserItem, userID = userID,tableID=androidMapItem.tableID})
		elseif userAttr.userStatus==GS_CONST.USER_STATUS.US_PLAYING or userAttr.userStatus==GS_CONST.USER_STATUS.US_OFFLINE then
			table.insert(ret.play, {androidItem = androidMapItem.androidUserItem, userItem = androidMapItem.serverUserItem, userID = userID,tableID=androidMapItem.tableID})
		end
		
		::continue::
	end
	
	return ret
end

local function exit()
	timerUtility.stop()
	skynet.exit()
end

--CTableFrame::EfficacyEnterTableScoreRule 如果是机器人，调整机器人身上的金币 
local function adjustScore(androidItem, userItem)
	local userAttr = ServerUserItem.getAttribute(userItem, {"score","userID"})
	
	local androidAttr = AndroidUserItem.getAttribute(androidItem, {"androidParameter"})
	local androidParameter = androidAttr.androidParameter
	
	if userAttr.score < androidParameter.minTakeScore or userAttr.score > androidParameter.maxTakeScore then
		local newScore
		if androidParameter.minTakeScore == androidParameter.maxTakeScore then
			newScore = androidParameter.minTakeScore
		else
			newScore = randHandle.random(androidParameter.minTakeScore, androidParameter.maxTakeScore)
		end
		
		ServerUserItem.setAttribute(userItem, {score=newScore})
	end

	local minScoreLimit = math.max(_serverConfig.MinTableScore, _serverConfig.MinEnterScore)
	if minScoreLimit~=0 and userAttr.score < minScoreLimit then
		local newScore = randHandle.random(minScoreLimit, 10*minScoreLimit)
		ServerUserItem.setAttribute(userItem, {score=newScore})
	end
end

--CAndroidUserManager::OnEventTimerPulse
local function _onTimerAndroidInOut()
--[[	
	do
		local jsonUtil = require "cjson.util"
		skynet.error(string.format("%s.onTimerAndroidInOut\n %s", SERVICE_NAME, jsonUtil.serialise_value(_data.androidMap)))
	end
--]]	

	local timeMask = getTimeMask()
	
	--登录处理
	for _, param in pairs(_data.androidParameterHash) do
		if (_serverConfig.ServerType & GS_CONST.GAME_GENRE.MATCH)~=0 and
			(param.serviceGender & GS_CONST.ANDROID_TYPE.ANDROID_SIMULATE)~=0 and
			(param.serviceGender & GS_CONST.ANDROID_TYPE.ANDROID_PASSIVITY)==0 and
			(param.serviceGender & GS_CONST.ANDROID_TYPE.ANDROID_INITIATIVE)==0 then
			goto continue
		end
		
		--创建机器人
		if (param.serviceTime & timeMask)~=0 then
			_data.androidParameterHash[param.userID] = nil
			
			local item = {
				addr=skynet.newservice("GS_model_android"),
				androidUserItem = CItemBuffer.allocate(),
				serverUserItem = nil,
				tableID = param.tableID,
			}
			_data.androidMap[param.userID] = item
			
			AndroidUserItem.initialize(item.androidUserItem, param, 0, 0)
			skynet.send(item.addr, "lua", "start", item.androidUserItem, _serverConfig.ChairPerTable)
			break
		end
		::continue::
	end
	
	local currentTS = math.floor(skynet.time())
	
	--退出处理
	for _, androidMapItem in pairs(_data.androidMap) do
		if androidMapItem.serverUserItem==nil then
			goto continue
		end
		
		local userAttr = ServerUserItem.getAttribute(androidMapItem.serverUserItem, {"userStatus", "enListStatus", "logonTime","tableID","userID"})
		local androidAttr = AndroidUserItem.getAttribute(androidMapItem.androidUserItem, {"androidParameter", "reposeTime"})
		
		--服务状态
		-- if userAttr.userStatus~=GS_CONST.USER_STATUS.US_FREE and userAttr.userStatus~=GS_CONST.USER_STATUS.US_SIT then
		-- 	goto continue
		-- end
		
		-- --比赛状态
		-- if userAttr.enListStatus~=GS_CONST.MATCH_STATUS.MS_NULL then
		-- 	goto continue
		-- end		
		
		if userAttr.logonTime + androidAttr.reposeTime < currentTS or (androidAttr.androidParameter.serviceTime & timeMask)==0 then
			skynet.send(androidMapItem.addr, "lua", "exit")
			break
		end
		::continue::
	end
end

local function onTimerAndroidInOut()
	_criticalSection(function()
		_onTimerAndroidInOut()
	end)
end


--CAndroidUserManager::SetAndroidStock
local function _onTimerLoadAndroid()
	--现有的机器人全部断线
	for _, androidMapItem in pairs(_data.androidMap) do
		skynet.send(androidMapItem.addr, "lua", "exit")
	end	
	
	local sql = string.format("call ssaccountsdb.sp_load_android(%d)", _serverConfig.ServerID)
	local mysqlConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(mysqlConn, "lua", "call", sql)
	if type(rows)~="table" or #rows==0 then
		skynet.error(string.format("%s: 从数据库刷新机器人信息错误", SERVICE_NAME))
		return
	end
	_data.androidParameterHash = {}
	for _, item in ipairs(rows) do
		local paramItem = {
			userID = math.tointeger(item.UserID),
			serverID = math.tointeger(item.ServerID),
			minPlayDraw = math.tointeger(item.MinPlayDraw),
			maxPlayDraw = math.tointeger(item.MaxPlayDraw),
			minTakeScore = math.tointeger(item.MinTakeScore),
			maxTakeScore = math.tointeger(item.MaxTakeScore),
			minReposeTime = math.tointeger(item.MinReposeTime),
			maxReposeTime = math.tointeger(item.MaxReposeTime),
			serviceTime = math.tointeger(item.ServiceTime),
			serviceGender = math.tointeger(item.ServiceGender),
			tableID = math.tointeger(item.TableId),
		}
		
		_data.androidParameterHash[paramItem.userID] = paramItem
	end
end

local function onTimerLoadAndroid()
	_criticalSection(function()
		_onTimerLoadAndroid()
	end)
end


--CAttemperEngineSink::OnEventTimer
local function _onTimerDistributeAndroid()
	if (_serverConfig.ServerType & GS_CONST.GAME_GENRE.MATCH)==0 and next(_data.androidMap)~=nil then
		local allowDynamicJoin = (_serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_ALLOW_DYNAMIC_JOIN)~=0
		local allowAndroidAttend = (_serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_ALLOW_ANDROID_ATTEND)~=0
		local allowAndroidSimulate = (_serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_ALLOW_ANDROID_SIMULATE)~=0
		local allowAvertCheatMode = (_serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_ALLOW_AVERT_CHEAT_MODE)~=0 and _serverConfig.ChairPerTable < GS_CONST.MAX_CHAIR
		
		--模拟处理
		if allowAndroidSimulate and not allowAvertCheatMode then
			
			local simulateAndroid = getAndroidUserInfo(GS_CONST.ANDROID_TYPE.ANDROID_SIMULATE)
			if #(simulateAndroid.free) > 0 then
				if COMMON_CONST.CheckIsNiuniuServer(_serverConfig.KindID) then
					for _, item in pairs(simulateAndroid.free) do
						local tableAddr = addressResolver.getTableAddress(item.tableID)
						if tableAddr then
							local isSuccess, retCode, msg = skynet.call(tableAddr, "lua", "sitDown", item.userItem, GS_CONST.INVALID_CHAIR)
							if isSuccess then
								skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "dispatch", GS_EVENT.EVT_GS_SIT_DOWN, {userID=item.userID})
							else
								skynet.error(string.format("%s: 00机器人坐下失败 retCode=%s msg=%s", SERVICE_NAME, tostring(retCode), tostring(msg)))
							end
						end
					end
				else
					for i=0, 7 do					
						--随机桌子
						local tableID
						if _serverConfig.TableCount > 10 then
							tableID = randHandle.random(1, math.min(_serverConfig.TableCount, 10))
						else
							tableID = randHandle.random(1, _serverConfig.TableCount)
						end


						local tableAddr = addressResolver.getTableAddress(tableID)
						
						local tableState = skynet.call(tableAddr, "lua", "getState")
						if (not tableState) or (tableState.isGameStarted and not allowDynamicJoin) or tableState.isLocked then
							goto continue
						end
							
						local tableUserCount = skynet.call(tableAddr, "lua", "getUserCount")
						
						--分配判断
						if tableUserCount.user > 0 then
							goto continue
						end
						if tableUserCount.total >= tableUserCount.minUser and _serverConfig.ChairPerTable < GS_CONST.MAX_CHAIR then
							goto continue
						end

						--金花机器人判断
						if COMMON_CONST.IsThisJinHuaServer(_serverConfig.KindID) and tableUserCount.total == _serverConfig.ChairPerTable-1 then
							goto continue
						end
		
						--坐下判断
						if #(simulateAndroid.free) >= tableUserCount.minUser then
							local handleCount = 0
							local wantAndroidCount = tableUserCount.minUser
							
							--数据调整
							if _serverConfig.ChairPerTable > tableUserCount.minUser then
								local freeUserCount = #(simulateAndroid.free)
								local offUserCount = math.min(_serverConfig.ChairPerTable, freeUserCount) - tableUserCount.minUser
								wantAndroidCount = wantAndroidCount + randHandle.random(0, offUserCount)
							end
							
							--坐下处理
							for _, item in pairs(simulateAndroid.free) do
								adjustScore(item.androidItem, item.userItem)
								local isSuccess, retCode, msg = skynet.call(tableAddr, "lua", "sitDown", item.userItem, GS_CONST.INVALID_CHAIR)
								if isSuccess then
									--skynet.error(string.format("%s: 机器人坐下 userID=%d", SERVICE_NAME, item.userID))
									skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "dispatch", GS_EVENT.EVT_GS_SIT_DOWN, {userID=item.userID})
									handleCount = handleCount + 1
									if handleCount >= wantAndroidCount then
										return
									end
								else
									skynet.error(string.format("%s: 1机器人坐下失败 retCode=%s msg=%s", SERVICE_NAME, tostring(retCode), tostring(msg)))
								end
							end
							
							if handleCount > 0 then
								return 
							end
						end
						::continue::
					end
				end
			end	
		end
		
		--陪打处理
		if allowAndroidAttend then
			local passiveAndroid = getAndroidUserInfo(GS_CONST.ANDROID_TYPE.ANDROID_PASSIVITY)
			if #(passiveAndroid.free) > 0 then
				if allowAvertCheatMode then
					local item = passiveAndroid.free[1]
					skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "insertWaitDistribute", item.userID)
					return 
				else
					--百人游戏
					if _serverConfig.ChairPerTable >= GS_CONST.MAX_CHAIR then
						local tableAddr = addressResolver.getTableAddress(1)
						
						local tableState = skynet.call(tableAddr, "lua", "getState")
						if tableState and ( not tableState.isGameStarted or allowDynamicJoin) then
							local tableUserCount = skynet.call(tableAddr, "lua", "getUserCount")
							if tableUserCount.total < (_serverConfig.ChairPerTable * 0.6) then
							
								--坐下处理
								for _, item in pairs(passiveAndroid.free) do
									adjustScore(item.androidItem, item.userItem)
									local isSuccess, retCode, msg = skynet.call(tableAddr, "lua", "sitDown", item.userItem, GS_CONST.INVALID_CHAIR)
									if isSuccess then
										--skynet.error(string.format("%s: 机器人坐下 userID=%d", SERVICE_NAME, item.userID))
										skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "dispatch", GS_EVENT.EVT_GS_SIT_DOWN, {userID=item.userID})
										return
									else
										skynet.error(string.format("%s: 2机器人坐下失败 retCode=%s msg=%s", SERVICE_NAME, tostring(retCode), tostring(msg)))
									end
								end
							end
						end
					else
						for tableID = 1, math.min(_serverConfig.TableCount, 10) do
							local tableAddr = addressResolver.getTableAddress(tableID)
							
							local tableState = skynet.call(tableAddr, "lua", "getState")
							if (not tableState) or (tableState.isGameStarted and not allowDynamicJoin) or tableState.isLocked then
								goto continue
							end
							
							local tableUserCount = skynet.call(tableAddr, "lua", "getUserCount")
							if tableUserCount.total==0 then
								goto continue
							end
							
							if tableUserCount.user==0 then
								goto continue
							end
							
							if tableUserCount.total >=  _serverConfig.ChairPerTable then
								goto continue
							end
							
							if tableUserCount.total > tableUserCount.minUser and randHandle.random(0,1)==1 then
								goto continue
							end

							--金花机器人判断
							if COMMON_CONST.IsThisJinHuaServer(_serverConfig.KindID) and tableUserCount.total == _serverConfig.ChairPerTable-1 then
								goto continue
							end

							--坐下处理
							for _, item in pairs(passiveAndroid.free) do
								adjustScore(item.androidItem, item.userItem)
								local isSuccess, retCode, msg = skynet.call(tableAddr, "lua", "sitDown", item.userItem, GS_CONST.INVALID_CHAIR)
								if isSuccess then
									--skynet.error(string.format("%s: 机器人坐下 userID=%d", SERVICE_NAME, item.userID))
									skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "dispatch", GS_EVENT.EVT_GS_SIT_DOWN, {userID=item.userID})
									return
								else
									skynet.error(string.format("%s: 3机器人坐下失败 retCode=%s msg=%s", SERVICE_NAME, tostring(retCode), tostring(msg)))
								end								
							end
							
							::continue::
						end
					end
				end
			end
		end
		
		--陪打处理
		if allowAndroidAttend then
			local initiativeAndroid = getAndroidUserInfo(GS_CONST.ANDROID_TYPE.ANDROID_INITIATIVE)
			if #(initiativeAndroid.free) > 0 then
				if allowAvertCheatMode then
					local item = initiativeAndroid.free[1]
					skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "insertWaitDistribute", item.userID)
					return 
				else
					for tableID = 1, math.min(_serverConfig.TableCount, 10) do
						local tableAddr = addressResolver.getTableAddress(tableID)
						
						local tableState = skynet.call(tableAddr, "lua", "getState")
						if (not tableState) or (tableState.isGameStarted and not allowDynamicJoin) or tableState.isLocked then
							goto continue
						end
						
						local tableUserCount = skynet.call(tableAddr, "lua", "getUserCount")
						if _serverConfig.ChairPerTable < GS_CONST.MAX_CHAIR and tableUserCount.total>=tableUserCount.minUser then
							goto continue
						end
						
						--金花机器人判断
						if COMMON_CONST.IsThisJinHuaServer(_serverConfig.KindID) and tableUserCount.total == _serverConfig.ChairPerTable-1 then
							goto continue
						end
						
						--坐下处理
						for _, item in pairs(initiativeAndroid.free) do
							adjustScore(item.androidItem, item.userItem)
							local isSuccess, retCode, msg = skynet.call(tableAddr, "lua", "sitDown", item.userItem, GS_CONST.INVALID_CHAIR)
							if isSuccess then
								--skynet.error(string.format("%s: 机器人坐下 userID=%d", SERVICE_NAME, item.userID))
								skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "dispatch", GS_EVENT.EVT_GS_SIT_DOWN, {userID=item.userID})
								return
							else
								skynet.error(string.format("%s: 4机器人坐下失败 retCode=%s msg=%s", SERVICE_NAME, tostring(retCode), tostring(msg)))
							end
						end
						::continue::
					end
				end
			end
		end
		
		
		local standUPCount = randHandle.random(1, 3)
		
		--起立处理
		local startIndex
		if _serverConfig.TableCount>1 then
			startIndex = randHandle.random(0, _serverConfig.TableCount-1)
		else
			startIndex = 0
		end
		for i=1, _serverConfig.TableCount do
			local tableID = startIndex + i
			if tableID > _serverConfig.TableCount then
				startIndex = startIndex - _serverConfig.TableCount
				tableID = tableID - _serverConfig.TableCount
			end
			
			local tableAddr = addressResolver.getTableAddress(tableID)
			local tableState = skynet.call(tableAddr, "lua", "getState")
			if (not tableState) or tableState.isGameStarted then
				goto continue
			end
			
			local tableUserCount = skynet.call(tableAddr, "lua", "getUserCount")
			if tableUserCount.android==0 then
				goto continue
			end
			
			local r = randHandle.random(0, 1)==1
			if tableUserCount.user > 0 and allowAndroidAttend and r then
				goto continue
			end
			
			if tableUserCount.android >= tableUserCount.minUser and r then
				goto continue
			end
			
			for chairID=1, _serverConfig.ChairPerTable do
				local userItem = skynet.call(tableAddr, "lua", "getUserItem", chairID)
				if userItem then
					local userAttr = ServerUserItem.getAttribute(userItem, {"isAndroid", "userID"})
					if userAttr.isAndroid then
						--skynet.error(string.format("%s: 机器人站起 userID=%d", SERVICE_NAME, userAttr.userID))
						skynet.call(tableAddr, "lua", "standUp", userItem)
						standUPCount = standUPCount - 1
						if standUPCount <= 0 then
							return
						end
					end
				end
			end
			
			::continue::
		end
		
		if _serverConfig.TableCount>1 then
			startIndex = randHandle.random(0, _serverConfig.TableCount-1)
		else
			startIndex = 0
		end
		for i=1, _serverConfig.TableCount do
			local tableID = startIndex + i
			if tableID > _serverConfig.TableCount then
				startIndex = startIndex - _serverConfig.TableCount
				tableID = tableID - _serverConfig.TableCount
			end
			
			local tableAddr = addressResolver.getTableAddress(tableID)
			
			local tableState = skynet.call(tableAddr, "lua", "getState")
			if (not tableState) or tableState.isGameStarted then
				goto continue
			end
			
			local tableUserCount = skynet.call(tableAddr, "lua", "getUserCount")
			if tableUserCount.android==0 then
				goto continue
			end
			
			local r = randHandle.random(0, 1)==1
			if tableUserCount.user > 0 and allowAndroidAttend and r then
				goto continue
			end
			
			for chairID=1, _serverConfig.ChairPerTable do
				local userItem = skynet.call(tableAddr, "lua", "getUserItem", chairID)
				if userItem then
					local userAttr = ServerUserItem.getAttribute(userItem, {"isAndroid", "userID"})
					if userAttr.isAndroid then
						--skynet.error(string.format("%s: 机器人站起 userID=%d", SERVICE_NAME, userAttr.userID))
						skynet.call(tableAddr, "lua", "standUp", userItem)
						standUPCount = standUPCount - 1
						if standUPCount <= 0 then
							return
						end
					end
				end
			end			
			
			::continue::
		end
	end
end

local function onTimerDistributeAndroid()
	_criticalSection(function()
		_onTimerDistributeAndroid()
	end)
end


local function cmd_start()
	if (_serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_ALLOW_ANDROID_ATTEND)==0 and (_serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_ALLOW_ANDROID_SIMULATE)==0 then
		skynet.error(string.format("%s: ServerRule不允许机器人，退出", SERVICE_NAME))
		return exit()
	end
	
	local sql = string.format("call ssaccountsdb.sp_is_android_config_ok(%d)", _serverConfig.ServerID)
	local mysqlConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(mysqlConn, "lua", "call", sql)
	if type(rows)~="table" or #rows~=1 or tonumber(rows[1].retCode)~=0 then
		local errMsg
		if type(rows)=="table" and #rows==1 then
			errMsg = rows[1].retMsg
		else
			errMsg = "检查数据库机器人配置出错"
		end
		
		skynet.error(string.format("%s: %s，退出", SERVICE_NAME, errMsg))
		return exit()
	end	
	
	timerUtility.start(GS_CONST.TIMER.TICK_STEP)
	timerUtility.setTimeout(onTimerLoadAndroid, 0)
	
	_data.timerIDHash.androidInout = timerUtility.setInterval(onTimerAndroidInOut, GS_CONST.TIMER.TICKSPAN_ANDROID_INOUT)
	if _serverConfig.KindID ~= 104 and _serverConfig.KindID ~= 800 then 
		_data.timerIDHash.loadAndroid = timerUtility.setInterval(onTimerLoadAndroid, GS_CONST.TIMER.TICKSPAN_LOAD_ANDROID_USER)
	end
	_data.timerIDHash.distributeAndroid = timerUtility.setInterval(onTimerDistributeAndroid, GS_CONST.TIMER.TICKSPAN_DISTRIBUTE_ANDROID)
end

local function _unregisterAndroid(userID)
	--skynet.error(string.format("%s: unregisterAndroid userid=%d (%s)", SERVICE_NAME, userID, type(userID)))
	local androidMapItem = _data.androidMap[userID]
	_data.androidMap[userID] = nil
	if androidMapItem and androidMapItem.androidUserItem then
		CItemBuffer.release(androidMapItem.androidUserItem)
	end
end

local function cmd_unregisterAndroid(userID)
	_criticalSection(function()
		_unregisterAndroid(userID)
	end)
end

local function _setServerUserItem(userID, userItem)
	local item = _data.androidMap[userID]
	if item then
		item.serverUserItem = userItem
	end
end

local function cmd_setServerUserItem(userID, userItem)
	_criticalSection(function()
		_setServerUserItem(userID, userItem)
	end)
end

local function _auiStatistic()
	local inUseCount = 0
	for k, v in pairs(_data.androidMap) do
		inUseCount = inUseCount + 1
	end
	
	local ret = CItemBuffer.statistic()
	ret.inUseCount = inUseCount
	return ret
end

local function cmd_auiStatistic()
	local ret
	_criticalSection(function()
		ret = _auiStatistic()
	end)
	return ret
end

local function _androidList()
	local ret = {}
	local totalCount = 0
	for userID, item in pairs(_data.androidMap) do
		if item.serverUserItem then
			local itemAttr = ServerUserItem.getAttribute(item.serverUserItem, {"userID", "nickName", "isAndroid", "userStatus", "tableID", "chairID", "agent"})
			ret[tostring(userID)] = string.format(
				"isAndroid=%s\tuserStatus=%d\ttableID=%d\tchairID=%d\tagent=0x%06x\tnickName=%s", 
				tostring(itemAttr.isAndroid), itemAttr.userStatus, itemAttr.tableID, itemAttr.chairID, itemAttr.agent, itemAttr.nickName
			)
			totalCount = totalCount + 1
		end
	end
	ret.total = totalCount
	return ret
end

local function cmd_androidList()
	local ret
	_criticalSection(function()
		ret = _androidList()
	end)
	return ret
end

local function cmd_reloadOneAndroid(serverID,userID,tableID)
	local sql = string.format("call ssaccountsdb.sp_reload_one_android(%d,%d,%d)",serverID,userID,tableID)
	local mysqlConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(mysqlConn, "lua", "call", sql)
	if type(rows)~="table" or #rows==0 then
		skynet.error(string.format("%s:cmd_reloadOneAndroid从数据库刷新机器人信息错误", SERVICE_NAME))
		return
	end

	for _, item in ipairs(rows) do
		local paramItem = {
			userID = math.tointeger(item.UserID),
			serverID = math.tointeger(item.ServerID),
			minPlayDraw = math.tointeger(item.MinPlayDraw),
			maxPlayDraw = math.tointeger(item.MaxPlayDraw),
			minTakeScore = math.tointeger(item.MinTakeScore),
			maxTakeScore = math.tointeger(item.MaxTakeScore),
			minReposeTime = math.tointeger(item.MinReposeTime),
			maxReposeTime = math.tointeger(item.MaxReposeTime),
			serviceTime = math.tointeger(item.ServiceTime),
			serviceGender = math.tointeger(item.ServiceGender),
			tableID = math.tointeger(item.TableId),
		}
		
		_data.androidParameterHash[paramItem.userID] = paramItem
	end
end	

local function cmd_RebotStandUp(userID)
	for userId, item in pairs(_data.androidMap) do
		if userId == userID then
			skynet.send(item.addr, "lua", "exit")
		end
	end
end

local conf = {
	methods = {
		["start"] = {["func"]=cmd_start, ["isRet"]=false},
		["setServerUserItem"] = {["func"]=cmd_setServerUserItem, ["isRet"]=false},
		["unregisterAndroid"] = {["func"]=cmd_unregisterAndroid, ["isRet"]=true},
		["auiStatistic"] = {["func"]=cmd_auiStatistic, ["isRet"]=true},
		["androidList"] = {["func"]=cmd_androidList, ["isRet"]=true},
		["reloadOneAndroid"] = {["func"]=cmd_reloadOneAndroid, ["isRet"]=false},
		["RebotStandUp"] = {["func"]=cmd_RebotStandUp, ["isRet"]=false},
	},
	initFunc = function() 
		_serverConfig = skynet.call(addressResolver.getAddressByServiceName("GS_model_serverStatus"), "lua", "getServerData")
	end,
}

commonServiceHelper.createService(conf)