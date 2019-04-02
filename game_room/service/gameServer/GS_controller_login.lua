local skynet = require "skynet"
local cluster = require "cluster"
local mysqlutil = require "utility.mysqlHandle"
local pbServiceHelper = require "serviceHelper.pb"
local ServerUserItem = require "sui"
local GS_CONST = require "define.gsConst"
local GS_EVENT = require "define.eventGameServer"
local COMMON_CONST = require "define.commonConst"
local addressResolver = require "addressResolver"
local timerUtility = require "utility.timer"
local currencyUtility = require "utility.currency"

local _roomConfig
local _serverConfig 
local _LS_sessionManagerAddress
local _isServerClosing = false
local _0x010100FrequenceControl = {}

local function checkRoomConfig(userInfo, isAndroid)
	if userInfo.masterOrder==0 and (_serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_FORFEND_ROOM_ENTER) ~= 0 then
		return false, "RC_ROOM_CONFIG_FORBID"
	end

	if not isAndroid then
		local isFishRoom = skynet.call(addressResolver.getAddressByServiceName("GS_model_serverStatus"),"lua","isFishRoom",_serverConfig.ServerID)
		if isFishRoom then
			local gunMultiple = 1
			local sql = string.format("SELECT CurGunLevel FROM `kffishdb`.`t_gun_uplevel` where UserId=%d",userInfo.userID)
			local dbConn = addressResolver.getMysqlConnection()
			local rows = skynet.call(dbConn,"lua","query",sql)
			if rows[1] ~= nil then
				gunMultiple = tonumber(rows[1].CurGunLevel)
			end
			local configAddress = addressResolver.getAddressByServiceName("GS_model_item_config")
			gunMultiple = skynet.call(configAddress,"lua","GetGunMultiple",gunMultiple)

			if gunMultiple < _roomConfig.cannonMultiple.min then
				local msg = string.format("对不起,解锁%d炮倍才能进入房间",_roomConfig.cannonMultiple.min)
				return false, "RC_MIN_ENTER_SCORE", msg
			end
		end

		if _serverConfig.MinEnterScore~=0 and userInfo.masterOrder==0 and userInfo.score < _serverConfig.MinEnterScore then
			local msg
			if (_serverConfig.ServerType & GS_CONST.GAME_GENRE.GOLD)~= 0 then
				msg = string.format("对不起，您的游戏筹码小于进入房间最低限制%s！", currencyUtility.formatCurrency(_serverConfig.MinEnterScore))
			else
				msg = string.format("对不起，您的游戏积分小于进入房间最低限制%s！", currencyUtility.formatCurrency(_serverConfig.MinEnterScore))
			end
			return false, "RC_MIN_ENTER_SCORE", msg
		end

		if _serverConfig.MaxEnterScore~=0 and userInfo.masterOrder==0 and userInfo.score > _serverConfig.MaxEnterScore then
			local msg
			if (_serverConfig.ServerType & GS_CONST.GAME_GENRE.GOLD)~= 0 then
				msg = string.format("对不起，您的游戏筹码大于进入房间最高限制%s！", currencyUtility.formatCurrency(_serverConfig.MaxEnterScore))
			else
				msg = string.format("对不起，您的游戏积分大于进入房间最高限制%s！", currencyUtility.formatCurrency(_serverConfig.MaxEnterScore))
			end
			return false, "RC_MAX_ENTER_SCORE", msg		
		end
	end

	if _serverConfig.MinEnterMember~=0 and userInfo.masterOrder==0 and userInfo.memberOrder < _serverConfig.MinEnterMember then
		return false, "RC_MIN_ENTER_MEMBER"
	end

	if _serverConfig.MaxEnterMember~=0 and userInfo.masterOrder==0 and userInfo.memberOrder > _serverConfig.MaxEnterMember then
		return false, "RC_MAX_ENTER_MEMBER"
	end
	
	return true
end

local function getUserInfoFromDb(userID)
	local sql = string.format("call kfaccountsdb.sp_gameserver_login(%d)", userID)
	local mysqlConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(mysqlConn, "lua", "call", sql)
	local dboLogin = rows[1]
	if type(dboLogin)~="table" then
		return nil, "RC_DB_ERROR"
	end
	
	if dboLogin then
		for k, v in pairs(dboLogin) do
			if k~="retMsg" and k~="NickName" and k~="Signature" and k~="PlatformFace" then
				dboLogin[k]=tonumber(v)
			end
		end
	end
	
	if dboLogin.retCode~=0 then
		if dboLogin.retCode==1 then
			return nil, "RC_LOGIN_CLOSED", dboLogin.retMsg
		elseif dboLogin.retCode==4 then
			return nil, "RC_ACCOUNT_NOT_EXIST"
		elseif dboLogin.retCode==5 then
			return nil, "RC_NULLITY"
		elseif dboLogin.retCode==6 then
			return nil, "RC_STUNDOWN"					
		else
			return nil, "RC_DB_ERROR"
		end
	end	

	local HideAllFlag = 0
	local sql = string.format("SELECT HideAllFlag FROM `kfrecorddb`.`t_record_hide_all_signature` WHERE ID = 1")
	local rows = skynet.call(mysqlConn, "lua", "query", sql)
	if rows[1] ~= nil then
		HideAllFlag = tonumber(rows[1].HideAllFlag)
	end

	if HideAllFlag == 0 then
		if dboLogin.HideFlag then
			if tonumber(dboLogin.HideFlag) == 1 then
				dboLogin.Signature = nil
			end
		end
	else
		dboLogin.Signature = nil
	end
	
	return {
		userID=dboLogin.UserID,
		gameID=dboLogin.GameID,
		platformID=dboLogin.PlatformID,
		nickName=dboLogin.NickName,
		signature=dboLogin.Signature,
		
		gender=dboLogin.Gender,
		faceID=dboLogin.FaceID,
		platformFace=dboLogin.PlatformFace,
		userRight=dboLogin.UserRight,
		masterRight=dboLogin.MasterRight,
		
		memberOrder=dboLogin.MemberOrder,
		masterOrder=dboLogin.MasterOrder,
		score=dboLogin.Score,
		insure=dboLogin.Insure,
		medal=dboLogin.UserMedal,
		
		gift=dboLogin.Gift,
		present=dboLogin.Present,
		experience=dboLogin.Experience,
		loveliness=dboLogin.LoveLiness,
		winCount=dboLogin.WinCount,
		
		lostCount=dboLogin.LostCount,
		drawCount=dboLogin.DrawCount,
		fleeCount=dboLogin.FleeCount,
		contribution=dboLogin.Contribution,
		dbStatus=dboLogin.Status,
	}
end

local function checkFrequenceControl()
	local nowTick = skynet.now()
	for session, tick in pairs(_0x010100FrequenceControl) do
		if nowTick - tick > GS_CONST.LOGIN_CONTROL.TIMEOUT_THRESHOLD_TICK then
			_0x010100FrequenceControl[session] = nil
		end
	end
end

local function isFrequenceControlCheckOk(session)
	local result
	if _0x010100FrequenceControl[session]~=nil then
		result = false
	else
		_0x010100FrequenceControl[session] = skynet.now()
		result = true
	end
	return result
end

local function queryLoginServer(session)
	local retCode, userInfo, itemList
	
	local tryCnt = 0
	repeat
		--skynet.error(string.format("%s: %d loginServer.gs_login session=%s", SERVICE_NAME, skynet.now(), pbObj.session))
		retCode, userInfo, itemList = cluster.call("loginServer", _LS_sessionManagerAddress, "gs_login", {
			session = session,
			kindID = _serverConfig.KindID,
			nodeID = _serverConfig.NodeID,
			serverID = _serverConfig.ServerID,
		})
		tryCnt = tryCnt + 1
		if retCode==COMMON_CONST.GS_LOGIN_CODE.GLC_RETRY and tryCnt < GS_CONST.LOGIN_CONTROL.RETRY_COUNT then
			skynet.sleep(GS_CONST.LOGIN_CONTROL.RETRY_INTERVAL_TICK)
		end
		
	until tryCnt>=GS_CONST.LOGIN_CONTROL.RETRY_COUNT or retCode~=COMMON_CONST.GS_LOGIN_CODE.GLC_RETRY
	
	return retCode, userInfo, itemList
end

local REQUEST = {
	[0x010100] = function(tcpAgent, pbObj, tcpAgentData)

		local startTime = skynet.now()

		if _isServerClosing then
			return 0x010100, {code="RC_LOGIN_CLOSED"}
		end
		
		if not isFrequenceControlCheckOk(pbObj.session) then
			return
		end
		
		local retCode, userInfo,itemList = queryLoginServer(pbObj.session)
		--skynet.error(string.format("retCode: %s %s    userInfo: %s %s", type(retCode), tostring(retCode), type(userInfo), tostring(userInfo)))

		if retCode~=COMMON_CONST.GS_LOGIN_CODE.GLC_SUCCESS then
			local code
			if retCode==COMMON_CONST.GS_LOGIN_CODE.GLC_INVALID_SESSION then
				code = "RC_INVALID_SESSION"
			elseif retCode==COMMON_CONST.GS_LOGIN_CODE.GLC_LS_LOGIN_FIRST then
				code = "RC_NO_ACCOUNT"
			elseif retCode==COMMON_CONST.GS_LOGIN_CODE.GLC_RETRY then
				code = "RC_KICK_TIMEOUT"
			else
				error(string.format("%s gs_login返回意外的值 %s", SERVICE_NAME, tostring(retCode)))
			end
			return 0x010100, {code=code}
		end

		local userItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "getUserItem", userInfo.userID)
			
		if userItem then
			skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "switchUserItem", userInfo.userID, tcpAgent, {
				ipAddr=tcpAgentData.addr,
				matchineID=pbObj.machineID,
				mobileUserRule=pbObj.behaviorFlags,
				deskCount=pbObj.pageTableCount,
				session = pbObj.session,
			})

			-- if itemList ~= nil then
			-- 	skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "SetUserItemList", userItem,itemList)
			-- end

			skynet.error(string.format("----------游戏里有玩家数据---------userInfo.userID=%s-----skynet.now=%d-------",userInfo.userID,skynet.now()))
			--skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "LoadUserItem", userItem)
		else
			local isSuccess, code, msg = checkRoomConfig(userInfo, false)
			if isSuccess then
				userItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "insertUserItem", userInfo, {
					tableID=GS_CONST.INVALID_TABLE,
					chairID=GS_CONST.INVALID_CHAIR,
					userStatus=GS_CONST.USER_STATUS.US_FREE,

					isAndroid = false,
					agent = tcpAgent,
					ipAddr = tcpAgentData.addr,
					machineID = pbObj.machineID,
					deskCount = pbObj.pageTableCount,
					mobileUserRule = pbObj.behaviorFlags,
					
					session = pbObj.session,
				},itemList)
			
				if not userItem then
					code="RC_ONLINE_FULL_LEAST_SCORE"
				end
			end
			
			if not userItem then
				local errorMsg
				isSuccess, errorMsg = pcall(cluster.call, "loginServer", _LS_sessionManagerAddress, "gs_logout", {
					kindID=_serverConfig.KindID,
					nodeID=_serverConfig.NodeID,
					serverID=_serverConfig.ServerID,
					userID=userInfo.userID,
				})
				if not isSuccess then
					skynet.error(string.format("%s 0x010100 cluster.call(gs_logout) failed userID=%d : %s", SERVICE_NAME, userInfo.userID, tostring(errorMsg)))
				end			
			
				return 0x010100, {code=code, msg=msg}
			end
		end

		skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "dispatch", GS_EVENT.EVT_GS_LOGIN_SUCCESS, {
			agent=tcpAgent,
			userID=userInfo.userID,
			sui=userItem,
			isAndroid=false,
			serverID = _serverConfig.ServerID,
		})
		
		skynet.send(tcpAgent, "lua", "forward", 0x010102, {
			tableCount = _serverConfig.TableCount,
			chairCount = _serverConfig.ChairPerTable,
			serverType = _serverConfig.ServerType,
			serverRule = _serverConfig.ServerRule,
		})
	
		skynet.send(tcpAgent, "lua", "forward", 0x010100, {code="RC_OK"})
			
		
		if (pbObj.behaviorFlags & GS_CONST.MOBILE_USER_RULE.BEHAVIOR_LOGON_IMMEDIATELY) ~= 0 and
			((_serverConfig.ServerRule & GS_CONST.SERVER_RULE.SR_FORFEND_GAME_ENTER) == 0 or userInfo.masterOrder ~= 0) then
		
			local availableTable = skynet.call(addressResolver.getAddressByServiceName("GS_model_tableManager"), "lua", "findAvailableTable")
			if availableTable then
				skynet.call(availableTable, "lua", "performSitDownAction", userInfo.userID, GS_CONST.INVALID_CHAIR)
			end
		end

		local endTime = skynet.now()
		skynet.error(string.format("--0x010100------游戏登入----costTime=%d----userid=%d------------",endTime-startTime,userInfo.userID))

	end,
	[0x010108] = function(tcpAgent, pbObj, tcpAgentData)
		if _isServerClosing then
			return 0x010108, {code="RC_LOGIN_CLOSED"}
		end
		
		local userItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "getUserItem", pbObj.userID)
		if userItem then
			skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "switchUserItem", pbObj.userID, tcpAgent, {
				ipAddr=tcpAgentData.addr,
				matchineID=pbObj.machineID,
				mobileUserRule=pbObj.behaviorFlags,
				deskCount=pbObj.pageTableCount,
				session = pbObj.session,
			})
		else
			local isSuccess, code, userInfo
			userInfo, code = getUserInfoFromDb(pbObj.userID)
			if userInfo then
				isSuccess, code = checkRoomConfig(userInfo, true)
				if isSuccess then
					userItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "insertUserItem", userInfo, {
						tableID=GS_CONST.INVALID_TABLE,
						chairID=GS_CONST.INVALID_CHAIR,
						userStatus=GS_CONST.USER_STATUS.US_FREE,

						isAndroid = true,
						agent = tcpAgent,
						ipAddr = tcpAgentData.addr,
						machineID = pbObj.machineID,
						deskCount = pbObj.pageTableCount,
						mobileUserRule = pbObj.behaviorFlags,
						
						session = "androidSession",
					})
				
					if not userItem then
						code="RC_ONLINE_FULL_LEAST_SCORE"
					end
				end		
			end
			
			if not userItem then
				return 0x010108, {code=code}
			end
		end
		skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "dispatch", GS_EVENT.EVT_GS_LOGIN_SUCCESS, {
			agent=tcpAgent,
			userID=pbObj.userID,
			sui=userItem,
			isAndroid=true,
		})
		return 0x010108, {code="RC_OK"}
	end,
	[0x010109] = function(tcpAgent, pbObj, tcpAgentData)


		local startTime = skynet.now()

		local attr = ServerUserItem.getAttribute(tcpAgentData.sui, {"userID"})		
		skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"), "lua", "kickUser", attr.userID)
			
		local endTime = skynet.now()
		skynet.error(string.format("--0x010109------游戏logout----costTime=%d----userid=%s------------",endTime-startTime,attr.userID))

		return 0x010109, {code="RC_OK"}
	end,
}

local function cmd_closeLogin()
	_isServerClosing = true
end

local conf = {
	loginCheck = false,
	protocalHandlers = REQUEST,
	methods = {
		["closeLogin"] = {["func"]=cmd_closeLogin, ["isRet"]=true},
	},	
	initFunc = function()
		_serverConfig = skynet.call(addressResolver.getAddressByServiceName("GS_model_serverStatus"), "lua", "getServerData")
		if not _serverConfig then
			error("获取服务器信息失败")
		end
		local isFishRoom = skynet.call(addressResolver.getAddressByServiceName("GS_model_serverStatus"),"lua","isFishRoom",_serverConfig.ServerID)
		if isFishRoom then
			_roomConfig = require(string.format("config.fish_%d", _serverConfig.ServerID))
		end	

		_LS_sessionManagerAddress = cluster.query("loginServer", "LS_model_sessionManager")
		
		timerUtility.start(GS_CONST.LOGIN_CONTROL.TIMEOUT_CHECK_INTERVAL_TICK)
		timerUtility.setInterval(checkFrequenceControl, 1)
	end
}

pbServiceHelper.createService(conf)
