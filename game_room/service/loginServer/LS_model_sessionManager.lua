local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local resourceResolver = require "resourceResolver"
local COMMON_CONST = require "define.commonConst"
local LS_CONST = require "define.lsConst"
local timerUtility = require "utility.timer"
local ServerUserItem = require "sui"
local CItemBuffer = require "utility.cItemBuffer"
local inspect = require "inspect"

CItemBuffer.init(ServerUserItem)

local _cachedProtoStr = {}

local _hash = {
	session = {},
	platformID = {},
	userID = {},
	platformIDBinding = {},--用户绑定信息
	--bagItemList = {},	--用户背包物品
}

local function createItem(session, platformID)
	return {
		platformID=platformID,
		session=session,
		sessionActiveTS=skynet.now(),
		sui=nil,
		suiActiveTS=nil,
	}
end

local function cmd_loadUserData(userItem)
	skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "LoadUserItem", userItem)
	skynet.call(addressResolver.getAddressByServiceName("LS_model_gunUplevel"), "lua", "LoadData", userItem)
	skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "LoadData", userItem)
end	

local function getRegistScore()
	-- 获取注册分数
	local sql = string.format("SELECT `StatusValue` FROM `SystemStatusInfo` WHERE `StatusName`='RegisterScore'")
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "query", sql)
	local _userstatus = userStatus
	local score = 0
	if rows[1] ~= nil then
		score = math.tointeger(rows[1].StatusValue)
	end
	return score
end

local function createBindingItem(platformID, userStatus, Tel)
	--创建绑定账号信息
	--[[
	local sql = string.format("SELECT * FROM `ssaccountsdb`.`AccountBinding` where PlatformID = %d", platformID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "query", sql)
	local _userstatus = userStatus
	local gamestatus = 0
	if rows[1] ~= nil then
		gamestatus = math.tointeger(rows[1].GameStatus)
	end
	]]
	return {
		platformID=platformID,
		gameStatus=gamestatus,
		userStatus=_userstatus,--玩家用户注册方式
		tel = Tel,
	}
end

local function addBindingRecord(userID, platformID, gamestatus)
	-- 增加用户绑定记录
	local sql = string.format("SELECT * FROM `ssaccountsdb`.`AccountBinding` where UserID = %d", userID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if rows[1] == nil then
		sql = string.format("insert into `ssaccountsdb`.`AccountBinding` values(%d,%d,%d,'%s')",userID, platformID, gamestatus, os.date('%Y-%m-%d %H:%M:%S', math.floor(skynet.time())))
		skynet.call(dbConn, "lua", "query", sql)
	end
end

local function kickLSAgent(agent)
	if agent ~= 0 then
		local isSuccess, msg = pcall(skynet.call, agent, "lua", "clearCache")
		if not isSuccess then
			skynet.error(string.format("%s.kickLSAgent agent=[:%08x] clearCache error: %s", SERVICE_NAME, agent, tostring(msg)))
		end
		skynet.send(agent, "lua", "forward", _cachedProtoStr["0x000101_ACCOUNT_LOGIN_SOMEWHERE"])
		skynet.send(agent, "lua", "exit")	
	end
end

local function kickLS(item, newUserStatus)
	local attr = ServerUserItem.getAttribute(item.sui, {"agent", "userStatus", "userID"})
	kickLSAgent(attr.agent)
	ServerUserItem.setAttribute(item.sui, {
		agent=0,
		ipAddr='',
		machineID='',
		userStatus=newUserStatus,
	})
	if newUserStatus==LS_CONST.USER_STATUS.US_NULL then
		item.suiActiveTS = skynet.now()
	end
	--skynet.error(string.format("%s.kickLS userID=%d userStatus改变: %d=>%d", SERVICE_NAME, attr.userID, attr.userStatus, newUserStatus))
end

local function kickGS(serverID, userID)
	skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", {serverID}, COMMON_CONST.LSNOTIFY_EVENT.EVT_LSNOTIFY_USER_LOGIN_OTHER_SERVER, {
		userID = userID,
	})
end

local function getUserInitializeInfo(userItem)
	return ServerUserItem.getAttribute(userItem, {
		"userID", "gameID", "platformID", "nickName", "signature", 
		"gender", "faceID", "platformFace", "userRight", "masterRight",
		"memberOrder", "masterOrder", "score", "insure", "medal",
		"gift", "present", "experience", "loveliness", "winCount", 
		"lostCount", "drawCount", "fleeCount", "contribution", "dbStatus",
	})
end

--[[
local USER_STATUS = {
	US_NULL 			= 0x00,								--没有状态
	US_LS 				= 0x01,								--登录服务器
	US_GS 				= 0x02,								--游戏服务器
	US_GS_OFFLINE 		= 0x03,								--游戏掉线
	US_LS_GS 			= 0x04,								--登录在线，游戏在线
	US_LS_GS_OFFLINE 	= 0x05,								--登录在线，游戏掉线
}
--]]
local function cmd_registerSession(session, platformID, userStatus, Tel)
	--skynet.error("LS_model_sessionManager.lua cmd_registerSession - ",string.format("session:%s,platformID:%d,status:%d,Tel:%s",session,platformID,userStatus,Tel))
	if type(session)~="string" or type(platformID)~="number" then
		return
	end
	
	local item = _hash.platformID[platformID]
	--skynet.error("LS_model_sessionManager.lua cmd_registerSession - item - ",item)
	if item then
		_hash.session[item.session] = nil
		_hash.session[session] = item
		item.session = session
		item.sessionActiveTS=skynet.now()
		
		if item.sui then
			local attr = ServerUserItem.getAttribute(item.sui, {"userStatus", "userID", "serverID"})
			if attr.userStatus == LS_CONST.USER_STATUS.US_LS then
				kickLS(item, LS_CONST.USER_STATUS.US_NULL)
			elseif attr.userStatus == LS_CONST.USER_STATUS.US_GS then
				kickGS(attr.serverID, attr.userID)
				skynet.error(string.format("------1----------kickGS---------userid=%d,status=%s,arrt.serverID=%s---skynet.now=%d-----",attr.userID,attr.userStatus,attr.serverID,skynet.now()))
			elseif attr.userStatus == LS_CONST.USER_STATUS.US_GS_OFFLINE then
				-- do nothing
			elseif attr.userStatus == LS_CONST.USER_STATUS.US_LS_GS then
				kickLS(item, LS_CONST.USER_STATUS.US_GS)
				kickGS(attr.serverID, attr.userID)
				skynet.error(string.format("------2----------kickGS---------uesrid=%d,status=%s,arrt.serverID=%s---skynet.now=%d-----",attr.userID,attr.userStatus,attr.serverID,skynet.now()))
			elseif attr.userStatus == LS_CONST.USER_STATUS.US_LS_GS_OFFLINE then
				kickLS(item, LS_CONST.USER_STATUS.US_GS_OFFLINE)
			end
		end
	else
		item = createItem(session, platformID)
		--skynet.error("LS_model_sessionManager.lua cmd_registerSession - item 2- ",item)
		_hash.platformID[platformID] = item
		_hash.session[session] = item
	end
	
	--增加绑定信息
	_hash.platformIDBinding[platformID] = createBindingItem(platformID, userStatus, Tel)
	
	--skynet.error("LS_model_sessionManager.lua cmd_registerSession - _hash\n",inspect(_hash))

end

local function cmd_getPlatformIDBySession(session)
	
	local item = _hash.session[session]
	--print("LS_model_sessionManager.lua cmd_getPlatformIDBySession - ",string.format("session:-%s-",session))
	--print("LS_model_sessionManager.lua cmd_getPlatformIDBySession - session,item - ",session,item)
	--print("LS_model_sessionManager.lua cmd_getPlatformIDBySession - _hash\n",inspect(_hash))
	--print("LS_model_sessionManager.lua cmd_getPlatformIDBySession - _hash.session\n",inspect(_hash.session))
	--print("LS_model_sessionManager.lua cmd_getPlatformIDBySession - _hash.platformIDBinding\n",inspect(_hash.platformIDBinding))
	if item then
		return item.platformID
	else
		return nil
	end
end

local function cmd_getUserItemByUserID(userID)
	local item = _hash.userID[userID]
	if item then
		return item.sui
	end
end

local function cmd_getUserItemByPlatformID(platformID, updateSuiTS)
	local item = _hash.platformID[platformID]
	--print("LS_model_sessionManager.lua cmd_getUserItemByPlatformID - _hash.platformID\n",platformID, updateSuiTS,item,inspect(_hash.platformID))
	if item and item.sui then
		if updateSuiTS and item.suiActiveTS~=nil then
			item.suiActiveTS = skynet.now()
		end
		return item.sui
	end
end

local function cmd_getUserItemBySession(session)
	local item = _hash.session[session]
	if item and item.sui then
		return item.sui
	end
end

local function cmd_getUserBindingInfo(platformID)
	-- 获取用户绑定信息
	return _hash.platformIDBinding[platformID]
end

local function cmd_getAllUserInfo()
	return _hash.userID
end

local function cmd_switchUserItem(platformID, newAttribute)
	local item = _hash.platformID[platformID]
	if not item.sui then
		error(string.format("%s.cmd_switchUserItem 错误: 找不到sui platformID=%s", SERVICE_NAME, tostring(platformID)))
	end
	
	item.sessionActiveTS=skynet.now()
	item.suiActiveTS = nil
	
	local newUserStatus
	local attr = ServerUserItem.getAttribute(item.sui, {"agent", "userStatus", "machineID", "isAndroid", "serverID", "userID"})
	if attr.userStatus == LS_CONST.USER_STATUS.US_NULL then
		newUserStatus = LS_CONST.USER_STATUS.US_LS
	elseif attr.userStatus == LS_CONST.USER_STATUS.US_LS then
		kickLSAgent(attr.agent)
		newUserStatus = LS_CONST.USER_STATUS.US_LS
	elseif attr.userStatus == LS_CONST.USER_STATUS.US_GS then
		newUserStatus = LS_CONST.USER_STATUS.US_LS_GS
	elseif attr.userStatus == LS_CONST.USER_STATUS.US_GS_OFFLINE then
		newUserStatus = LS_CONST.USER_STATUS.US_LS_GS_OFFLINE
	elseif attr.userStatus == LS_CONST.USER_STATUS.US_LS_GS then	
		kickLSAgent(attr.agent)
		newUserStatus = LS_CONST.USER_STATUS.US_LS_GS
	elseif attr.userStatus == LS_CONST.USER_STATUS.US_LS_GS_OFFLINE then
		kickLSAgent(attr.agent)
		newUserStatus = LS_CONST.USER_STATUS.US_LS_GS_OFFLINE
	end

	ServerUserItem.setAttribute(item.sui, {
		agent=newAttribute.agent,
		ipAddr=newAttribute.ipAddr,
		machineID=newAttribute.matchineID,
		userStatus=newUserStatus,
	})
	--skynet.error(string.format("%s.cmd_switchUserItem userID=%d userStatus改变: %d=>%d", SERVICE_NAME, attr.userID, attr.userStatus, newUserStatus));

	cmd_loadUserData(item.sui)
	skynet.send(addressResolver.getAddressByServiceName("LS_model_huoDong"), "lua", "CheckActivityReward", item.sui)

	skynet.call(newAttribute.agent, "lua", "setCache", item.session, item.sui, attr.userID)

	--安全提示
	-- if not attr.isAndroid and attr.userStatus ~= LS_CONST.USER_STATUS.US_NULL and attr.machineID ~= newAttribute.matchineID then
	-- 	skynet.send(newAttribute.agent, "lua", "forward", 0xff0000, {
	-- 		type = COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_CHAT | COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_EJECT,
	-- 		msg = "请注意，您的帐号已从另一设备登录，对方被迫离开！"
	-- 	})
	-- end
end

local function checkOldUserVip(sui,attr)
	local bFind = false
	local memberOrder = 0
	local configAddress = addressResolver.getAddressByServiceName("LS_model_item_config")
	local infoConfig = skynet.call(configAddress,"lua","GetvipInfo")
	for k, v in pairs(infoConfig) do 
		if attr.contribution < v.rmb then
			bFind = true
			memberOrder = v.vipLevel - 1
			break
		end 
	end

	if not bFind and attr.contribution ~= 0 then
		memberOrder = #infoConfig
	end

	if memberOrder ~= attr.memberOrder then
		ServerUserItem.setAttribute(sui, {memberOrder=memberOrder})
		local dbConn = addressResolver.getMysqlConnection()
		local sql = string.format("UPDATE `ssaccountsdb`.`AccountsInfo` SET `MemberOrder`=%d WHERE `UserID`=%d",memberOrder,attr.userID)
		skynet.call(dbConn, "lua", "query", sql)
	end
end

local function cmd_registerUser(platformID, userInfo, userInfoPlus)
	local item = _hash.platformID[platformID]
	if not item then
		error(string.format("%s.registerUser platformID=%d item找不到", SERVICE_NAME, platformID))
	end
	
	if item.sui then
		error(string.format("%s.registerUser platformID=%d item.sui~=nil", SERVICE_NAME, platformID))
	end
	
	item.sui = CItemBuffer.allocate()
	ServerUserItem.initialize(item.sui, userInfo, userInfoPlus)
	skynet.error(string.format("%s.cmd_registerUser userID=%d 生成sui数据 userStatus=%d", SERVICE_NAME, userInfo.userID, userInfoPlus.userStatus));
	
	item.sessionActiveTS=skynet.now()
	item.suiActiveTS = nil
	
	local attr = ServerUserItem.getAttribute(item.sui, {"userID", "agent","contribution","memberOrder"})
	_hash.userID[attr.userID] = item

	--老玩家vip调整
	--checkOldUserVip(item.sui,attr)

	--cmd_loadUserData(item.sui)

	--skynet.send(addressResolver.getAddressByServiceName("LS_model_huoDong"), "lua", "CheckActivityReward", item.sui)
	
	skynet.call(attr.agent, "lua", "setCache", item.session, item.sui, attr.userID)
	-- --增加账号绑定信息
	-- addBindingRecord(attr.userID, platformID)
	-- skynet.send(attr.agent, "lua", "forward", 0x000606, {bindingStatus=_hash.platformIDBinding[platformID].gameStatus})

	return item.sui
end

local function resetFreeScoreRecord(userID)
	local nowDate = tonumber(os.date("%Y%m%d", os.time()))
	local sql = string.format("update `sstreasuredb`.`s_free_score_info` set num=0, earnDate=%d where id = %d", nowDate, userID)
	local dbConn = addressResolver.getMysqlConnection()
	skynet.call(dbConn, "lua", "query", sql)
end

local function cmd_bindingAccount(platformID)
	-- 绑定账号
	if _hash.platformIDBinding[platformID] and _hash.platformIDBinding[platformID].gameStatus <= 0 then
		local sql = string.format("update `ssaccountsdb`.`AccountBinding` set GameStatus=1, BindingDate='%s' where PlatformID = %d",os.date('%Y-%m-%d %H:%M:%S', math.floor(skynet.time())), platformID)
		local dbConn = addressResolver.getMysqlConnection()
		skynet.call(dbConn, "lua", "query", sql)
		_hash.platformIDBinding[platformID].gameStatus = 1
		local item = _hash.platformID[platformID]
		local attr = ServerUserItem.getAttribute(item.sui, {"userID"})
		--重置免费领取记录次数
		--resetFreeScoreRecord(attr.userID)
	end
end

local function cmd_changeRegistBinding(platformID, userID, scoreTag)
	-- 变更注册用户绑定信息
	local bindInfo = _hash.platformIDBinding[platformID]
	local gamestatus = 0
	local gamescore = 0
	if bindInfo then
		if scoreTag == true then
			gamestatus = 1
			gamescore = getRegistScore()
		else
			if bindInfo.userStatus == LS_CONST.USER_TYPE.PHONE then
				gamestatus = 1
				gamescore = getRegistScore()
			elseif bindInfo.userStatus == LS_CONST.USER_TYPE.NARMAL then
				gamestatus = 1
				if bindInfo.tel ~= "" and bindInfo.tel ~= nil then
					gamescore = getRegistScore()
				end
			elseif bindInfo.userStatus == LS_CONST.USER_TYPE.NATIVE then

			else
				_hash.platformIDBinding[platformID].gameStatus = gamestatus
				addBindingRecord(userID, platformID, gamestatus)
				return
			end
		end
		_hash.platformIDBinding[platformID].gameStatus = gamestatus
		addBindingRecord(userID, platformID, gamestatus)
		if bindInfo.userStatus ~= LS_CONST.USER_TYPE.NATIVE then
			local item = _hash.platformID[platformID]
			ServerUserItem.setAttribute(item.sui, {score=gamescore})
		end
	end
end

--[[
data = {
	session = pbObj.session,
	kindID = _serverData.KindID,
	nodeID = _serverData.NodeID,
	serverID = _serverData.ServerID,
}
--]]	

local function cmd_gs_login(data)
	local item = _hash.session[data.session]
	if not item then
		return COMMON_CONST.GS_LOGIN_CODE.GLC_INVALID_SESSION
	end
	
	if not item.sui then
		return COMMON_CONST.GS_LOGIN_CODE.GLC_LS_LOGIN_FIRST
	end
	
	local retCode, updateAttr
	local attr = ServerUserItem.getAttribute(item.sui, {"userStatus", "agent", "serverID", "userID"})
	if attr.userStatus == LS_CONST.USER_STATUS.US_NULL then
		updateAttr = {kindID=data.kindID, nodeID=data.nodeID, serverID=data.serverID, userStatus=LS_CONST.USER_STATUS.US_GS}
		retCode = COMMON_CONST.GS_LOGIN_CODE.GLC_SUCCESS
	elseif attr.userStatus == LS_CONST.USER_STATUS.US_LS then
		updateAttr = {kindID=data.kindID, nodeID=data.nodeID, serverID=data.serverID, userStatus=LS_CONST.USER_STATUS.US_LS_GS}
		retCode = COMMON_CONST.GS_LOGIN_CODE.GLC_SUCCESS
	elseif attr.userStatus == LS_CONST.USER_STATUS.US_GS then
		if attr.serverID == data.serverID then
			retCode = COMMON_CONST.GS_LOGIN_CODE.GLC_SUCCESS
		else
			retCode = COMMON_CONST.GS_LOGIN_CODE.GLC_RETRY
		end
	elseif attr.userStatus == LS_CONST.USER_STATUS.US_GS_OFFLINE then
		if attr.serverID == data.serverID then
			updateAttr = {userStatus=LS_CONST.USER_STATUS.US_GS}
			retCode = COMMON_CONST.GS_LOGIN_CODE.GLC_SUCCESS
		else
			retCode = COMMON_CONST.GS_LOGIN_CODE.GLC_RETRY
		end
	elseif attr.userStatus == LS_CONST.USER_STATUS.US_LS_GS then
		if attr.serverID == data.serverID then
			retCode = COMMON_CONST.GS_LOGIN_CODE.GLC_SUCCESS
		else
			retCode = COMMON_CONST.GS_LOGIN_CODE.GLC_RETRY
		end
	elseif attr.userStatus == LS_CONST.USER_STATUS.US_LS_GS_OFFLINE then
		if attr.serverID == data.serverID then
			updateAttr = {userStatus=LS_CONST.USER_STATUS.US_LS_GS}
			retCode = COMMON_CONST.GS_LOGIN_CODE.GLC_SUCCESS
		else
			retCode = COMMON_CONST.GS_LOGIN_CODE.GLC_RETRY
		end
	else
		error(string.format("%s.cmd_gs_login 预期外的userStatus userStatus=%d", SERVICE_NAME, attr.userStatus))
	end
	
	if retCode == COMMON_CONST.GS_LOGIN_CODE.GLC_SUCCESS then
		if updateAttr~=nil then
			ServerUserItem.setAttribute(item.sui, updateAttr)
			--skynet.error(string.format("%s.cmd_gs_login userID=%d userStatus改变: %d=>%d", SERVICE_NAME, attr.userID, attr.userStatus, updateAttr.userStatus));
		end
		item.suiActiveTS = nil
		
		return retCode, getUserInitializeInfo(item.sui)--,skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "GetItemList", attr.userID)
	elseif retCode == COMMON_CONST.GS_LOGIN_CODE.GLC_RETRY then
		kickGS(attr.serverID, attr.userID)
		skynet.error(string.format("------3----------kickGS---------userid=%d,status=%s,arrt.serverID=%s,data.serverID=%s---skynet.now=%d-----",attr.userID,attr.userStatus,attr.serverID,data.serverID,skynet.now()))
		return retCode
	else
		error(string.format("%s.cmd_gs_login 预期外的结果 retCode=%d", SERVICE_NAME, retCode))
	end
end

--[[
local data = {
	kindID=,
	nodeID=,
	serverID=,
	userID=,
}
--]]
local function cmd_gs_logout(data)

	local startTime = skynet.now()

	local item = _hash.userID[data.userID]

	if not item then
		skynet.error(string.format("%s.cmd_gs_logout item not found userID=%s", SERVICE_NAME, tostring(data.userID)))
		return
	end
	
	if not item.sui then
		error(string.format("%s.cmd_gs_logout item.sui not found userID=%s", SERVICE_NAME, tostring(data.userID)))
	end	
	
	local attr = ServerUserItem.getAttribute(item.sui, {"userStatus", "kindID", "nodeID", "serverID","userID"})
	local newUserStatus
	
	if attr.userStatus==LS_CONST.USER_STATUS.US_GS or attr.userStatus == LS_CONST.USER_STATUS.US_GS_OFFLINE then
		newUserStatus = LS_CONST.USER_STATUS.US_NULL
	elseif attr.userStatus==LS_CONST.USER_STATUS.US_LS_GS or attr.userStatus==LS_CONST.USER_STATUS.US_LS_GS_OFFLINE then
		newUserStatus = LS_CONST.USER_STATUS.US_LS
	else
		error(string.format("%s.cmd_gs_logout 预期外的userStatus userStatus=%d,userID=%d", SERVICE_NAME, attr.userStatus,data.userID))
	end
	
	if attr.kindID==data.kindID and attr.nodeID==data.nodeID and attr.serverID==data.serverID then
		local updateAttr = data.updateAttr
		if updateAttr==nil then
			updateAttr = {}
		end
		updateAttr.userStatus=newUserStatus
		updateAttr.kindID=0
		updateAttr.nodeID=0
		updateAttr.serverID=0
		
		ServerUserItem.setAttribute(item.sui, updateAttr)

		--重新加载背包的数据
		if not data.bOffLine then
			cmd_loadUserData(item.sui)
		end

		if newUserStatus==LS_CONST.USER_STATUS.US_NULL then
			item.suiActiveTS = skynet.now()
		end
		--skynet.error(string.format("%s.cmd_gs_logout userID=%d userStatus改变: %d=>%d", SERVICE_NAME, data.userID, attr.userStatus, newUserStatus));
		
		if newUserStatus==LS_CONST.USER_STATUS.US_LS and data.updateAttr~=nil then
			local newAttr = ServerUserItem.getAttribute(item.sui, {"agent", "medal", "experience", "loveliness", "score", "insure", "gift", "present"})
			skynet.send(newAttr.agent, "lua", "forward", 0x000102, {
				medal=newAttr.medal,
				experience=newAttr.experience,
				loveLiness=newAttr.loveliness,
				score=newAttr.score,
				insure=newAttr.insure,
				gift=newAttr.gift,
				present=newAttr.present,
			})
		end
	else
		error(string.format(
			"%s.cmd_gs_logout 服务器不匹配 expect[kindID=%d nodeID=%d serverID=%d]   got[kindID=%d nodeID=%d serverID=%d]",
			SERVICE_NAME,
			attr.kindID, attr.nodeID, attr.serverID,
			data.kindID, data.nodeID, data.serverID
		))
	end

	local endTime = skynet.now()

	skynet.error(string.format("----cmd_gs_logout--------userId=%d,status=%s,kindID=%d,nodeID=%d,serverID=%d------skynet.now=%s-------CostTime=%s--------",data.userID,attr.userStatus,data.kindID,data.nodeID,data.serverID,endTime,endTime-startTime))
	
end

--[[
local data = {
	kindID=,
	nodeID=,
	serverID=,
	userID=,
}
local USER_STATUS = {
	US_NULL 			= 0x00,								--没有状态
	US_LS 				= 0x01,								--登录服务器
	US_GS 				= 0x02,								--游戏服务器
	US_GS_OFFLINE 		= 0x03,								--游戏掉线
	US_LS_GS 			= 0x04,								--登录在线，游戏在线
	US_LS_GS_OFFLINE 	= 0x05,								--登录在线，游戏掉线
}
--]]
local function cmd_gs_offline(data)
	local item = _hash.userID[data.userID]
	if not item then
		skynet.error(string.format("%s.cmd_gs_offline item not found userID=%s", SERVICE_NAME, tostring(data.userID)))
		return
	end
	
	if not item.sui then
		error(string.format("%s.cmd_gs_offline item.sui not found userID=%s", SERVICE_NAME, tostring(data.userID)))
	end	
	
	local attr = ServerUserItem.getAttribute(item.sui, {"userStatus", "kindID", "nodeID", "serverID","userID"})
	local newUserStatus
	
	if attr.userStatus==LS_CONST.USER_STATUS.US_GS or attr.userStatus == LS_CONST.USER_STATUS.US_GS_OFFLINE then
		newUserStatus = LS_CONST.USER_STATUS.US_GS_OFFLINE
	elseif attr.userStatus==LS_CONST.USER_STATUS.US_LS_GS or attr.userStatus==LS_CONST.USER_STATUS.US_LS_GS_OFFLINE then
		newUserStatus = LS_CONST.USER_STATUS.US_LS_GS_OFFLINE
	else
		error(string.format("%s.cmd_gs_offline 预期外的userStatus userStatus=%d,userID=%s", SERVICE_NAME, attr.userStatus,data.userID))
	end
	
	if attr.kindID==data.kindID and attr.nodeID==data.nodeID and attr.serverID==data.serverID then
		
		skynet.error(string.format("-------------------gs_offline------userid=%d,status=%s,kindID=%d,nodeID=%d,serverID=%d------skynet.now=%s---------------",data.userID,attr.userStatus,data.kindID,data.nodeID,data.serverID,skynet.now()))

		--cmd_loadUserData(item.sui)

		ServerUserItem.setAttribute(item.sui, {userStatus=newUserStatus})
		--skynet.error(string.format("%s.cmd_gs_offline userID=%d userStatus改变: %d=>%d", SERVICE_NAME, data.userID, attr.userStatus, newUserStatus));
	else
		error(string.format(
			"%s.cmd_gs_offline 服务器不匹配 expect[kindID=%d nodeID=%d serverID=%d]   got[kindID=%d nodeID=%d serverID=%d]",
			SERVICE_NAME,
			attr.kindID, attr.nodeID, attr.serverID,
			data.kindID, data.nodeID, data.serverID
		))
	end
end

local function cmd_checkOnline(userIDList)
	local ret = {}
	for _, userID in ipairs(userIDList) do
		local item = _hash.userID[userID]
		local retValue
		if item then
			local attr = ServerUserItem.getAttribute(item.sui, {"userStatus", "kindID", "nodeID", "serverID"})
			retValue = {
				kindID = attr.kindID,
				nodeID = attr.nodeID,
				serverID = attr.serverID,
			}
		else
			retValue = false
		end
		ret[tostring(userID)] = retValue
	end
	return ret
end

local function cmd_viewOnline()
	local ret = {}
	for _, item in pairs(_hash.userID) do
		if item.sui then
			local attr = ServerUserItem.getAttribute(item.sui, {"userID", "userStatus", "serverID", "nickName"})
			table.insert(ret, attr)
		end
	end
	return ret
end

local function cmd_onEventClientDisconnect(data)
	local item = _hash.userID[data.userID]
	if not item or not item.sui then
		return
	end
	
	local attr = ServerUserItem.getAttribute(item.sui, {"userStatus"})
	local newUserStatus
	if attr.userStatus==LS_CONST.USER_STATUS.US_NULL or attr.userStatus==LS_CONST.USER_STATUS.US_LS then
		newUserStatus = LS_CONST.USER_STATUS.US_NULL
	elseif attr.userStatus==LS_CONST.USER_STATUS.US_GS or attr.userStatus==LS_CONST.USER_STATUS.US_LS_GS then
		newUserStatus = LS_CONST.USER_STATUS.US_GS
	elseif attr.userStatus==LS_CONST.USER_STATUS.US_GS_OFFLINE or attr.userStatus==LS_CONST.USER_STATUS.US_LS_GS_OFFLINE then
		newUserStatus = LS_CONST.USER_STATUS.US_GS_OFFLINE
	else
		error(string.format("%s.cmd_onEventClientDisconnect 预期外的userStatus=%d", SERVICE_NAME, attr.userStatus))
	end
	
	ServerUserItem.setAttribute(item.sui, {
		agent=0,
		ipAddr='',
		machineID='',
		userStatus=newUserStatus,
	})
	--skynet.error(string.format("%s.cmd_onEventClientDisconnect userID=%d userStatus改变: %d=>%d", SERVICE_NAME, data.userID, attr.userStatus, newUserStatus));
	if newUserStatus==LS_CONST.USER_STATUS.US_NULL then
		item.suiActiveTS = skynet.now()
	end
end

local function cmd_onEventGameServerDisconnect(data)
	for session, item in pairs(_hash.session) do
		if item.sui then
			local attr = ServerUserItem.getAttribute(item.sui, {"agent", "serverID", "userID"})
			if attr.serverID==data.serverID then
				kickLSAgent(attr.agent)
				_hash.userID[attr.userID] = nil
				CItemBuffer.release(item.sui)
				item.sui = nil
				item.suiActiveTS = nil

				--背包
				skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ReleaseUserItem",attr.userID)
				skynet.send(addressResolver.getAddressByServiceName("LS_model_gunUplevel"), "lua", "ReleaseUserData",attr.userID)
				skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "ReleaseUserData",attr.userID)
			end
		end
	end
end

local function cmd_ping()

end

local function cleanExpiredInfo()
	local currentTS = skynet.now()
	
	local userItemLifeTimeThreshold = LS_CONST.SESSION_CONTROL.USER_ITEM_LIFE_TIME * 100
	local sessionLifeTimeThreshold = LS_CONST.SESSION_CONTROL.SESSION_LIFE_TIME * 100
	
	for session, item in pairs(_hash.session) do
		if item.sui and item.suiActiveTS then
			if currentTS - item.suiActiveTS > userItemLifeTimeThreshold then
				local attr = ServerUserItem.getAttribute(item.sui, {"userStatus", "userID"})
				if attr.userStatus~=LS_CONST.USER_STATUS.US_NULL then
					error(string.format("%s.cleanExpiredInfo 预期外的userStatus userID=%d userStatus=%d", SERVICE_NAME, attr.userID, attr.userStatus))
				end
				_hash.userID[attr.userID] = nil
				CItemBuffer.release(item.sui)
				item.sui = nil
				item.suiActiveTS = nil

				--背包
				skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ReleaseUserItem",attr.userID)
				skynet.send(addressResolver.getAddressByServiceName("LS_model_gunUplevel"), "lua", "ReleaseUserData",attr.userID)
				skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "ReleaseUserData",attr.userID)
				--skynet.error(string.format("%s.cleanExpiredInfo 清除sui数据 userID=%d", SERVICE_NAME, attr.userID));
			end
		end
		
		if item.sui==nil then
			if currentTS - item.sessionActiveTS > sessionLifeTimeThreshold then
				_hash.session[item.session]=nil
				_hash.platformID[item.platformID]=nil
				_hash.platformIDBinding[item.platformID]=nil
			end
		end
	end
end

local function cmd_sendSystemMessage(msg)
	for k, v in pairs(_hash.session) do
		if v.sui ~= nil then
			local attrr = ServerUserItem.getAttribute(v.sui,{"agent"})
			if attrr.agent ~= 0 then
				skynet.send(attrr.agent, "lua", "forward", 0xff0000, {
					type = COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_CHAT | COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_GLOBAL | COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_TABLE_ROLL,
					msg = msg,
				})
			end	
		end
	end	
end

local function cmd_sendTitleMessage(msg)
	for k, v in pairs(_hash.session) do
		if v.sui ~= nil then
			local attrr = ServerUserItem.getAttribute(v.sui,{"agent","serverID"})
			if attrr.agent ~= 0 and (attrr.serverID == 210 or attrr.serverID == 220 or attrr.serverID == 230) then
				skynet.send(attrr.agent, "lua", "forward", 0xff0000, {
					type = COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_SEND_TITLE,
					msg = msg,
				})
			end	
		end
	end	

	return 0
end

local conf = {
	methods = {
		["getPlatformIDBySession"] = {["func"]=cmd_getPlatformIDBySession, ["isRet"]=true},
		["getUserItemByUserID"] = {["func"]=cmd_getUserItemByUserID, ["isRet"]=true},
		["getUserItemByPlatformID"] = {["func"]=cmd_getUserItemByPlatformID, ["isRet"]=true},
		["getUserItemBySession"] = {["func"]=cmd_getUserItemBySession, ["isRet"]=true},
		["getUserBindingInfo"] = {["func"]=cmd_getUserBindingInfo, ["isRet"]=true},
		["getAllUserInfo"] = {["func"] = cmd_getAllUserInfo, ["isRet"]=true},
		
		["registerSession"] = {["func"]=cmd_registerSession, ["isRet"]=false},
		["registerUser"] = {["func"]=cmd_registerUser, ["isRet"]=true},
		["switchUserItem"] = {["func"]=cmd_switchUserItem, ["isRet"]=true},
		["bindingAccount"] = {["func"]=cmd_bindingAccount, ["isRet"]=true},
		["changeRegistBinding"] = {["func"]=cmd_changeRegistBinding, ["isRet"]=true},
		
		["gs_login"] = {["func"]=cmd_gs_login, ["isRet"]=true},
		["gs_logout"] = {["func"]=cmd_gs_logout, ["isRet"]=true},
		["gs_offline"] = {["func"]=cmd_gs_offline, ["isRet"]=true},
		
		["checkOnline"] = {["func"]=cmd_checkOnline, ["isRet"]=true},
		["viewOnline"] = {["func"]=cmd_viewOnline, ["isRet"]=true},
		
		["ping"] = {["func"]=cmd_ping, ["isRet"]=true},
		
		["onEventClientDisconnect"] = {["func"]=cmd_onEventClientDisconnect, ["isRet"]=false},
		["onEventGameServerDisconnect"] = {["func"]=cmd_onEventGameServerDisconnect, ["isRet"]=false},
		["sendSystemMessage"] = {["func"]=cmd_sendSystemMessage, ["isRet"]=false},
		["loadUserData"] = {["func"]=cmd_loadUserData, ["isRet"]=true},
		["sendTitleMessage"] = {["func"]=cmd_sendTitleMessage, ["isRet"]=true},
	},
	initFunc = function()
		resourceResolver.init()
		
		_cachedProtoStr["0x000101_ACCOUNT_LOGIN_SOMEWHERE"] = skynet.call(resourceResolver.get("pbParser"), "lua", "encode", 0x000101, {code="RC_ACCOUNT_LOGIN_SOMEWHERE"}, true)
	
		local LS_EVENT = require "define.eventLoginServer"
		skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "addEventListener", LS_EVENT.EVT_LS_CLIENT_DISCONNECT, skynet.self(), "onEventClientDisconnect")
		skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "addEventListener", LS_EVENT.EVT_LS_GAMESERVER_DISCONNECT, skynet.self(), "onEventGameServerDisconnect")
	
		timerUtility.start(LS_CONST.SESSION_CONTROL.CHECK_INTERVAL * 100)
		timerUtility.setInterval(cleanExpiredInfo, 1)
	end
}

commonServiceHelper.createService(conf)
