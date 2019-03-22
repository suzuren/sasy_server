local skynet = require "skynet"
local cluster = require "cluster"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local resourceResolver = require "resourceResolver"
local ServerUserItem = require "sui"
local multicast = require "multicast"
local GS_CONST = require "define.gsConst"
local COMMON_CONST = require "define.commonConst"
local CItemBuffer = require "utility.cItemBuffer"

CItemBuffer.init(ServerUserItem)

local _broadCastChannel
local _serverConfig 
local _LS_sessionManagerAddress
local _userItemHash = {}
local _waitDistributeHash = {}						--等待分配的item Hash 等待定时器IDI_DISTRIBUTE_USER进行分配
local _isServerClosing = false						--telnet关闭服务器标志


local function getUserItemCount(returnLeastScore)

	-- skynet.error(string.format("%s getUserItemCount func - ", SERVICE_NAME),returnLeastScore)

	local count = 0
	local leastScore, leastUserID
	if returnLeastScore then
		leastScore = math.maxinteger
		leastUserID = 0
	end
	
	for userID, item in pairs(_userItemHash) do
		count = count + 1
		if returnLeastScore then
			local itemAttr = ServerUserItem.getAttribute(item, {"score"})
			
			if itemAttr.score < leastScore then
				leastScore = itemAttr.score
				leastUserID = userID
			end
		end
	end
	
	-- skynet.error(string.format("%s getUserItemCount func - count_%d", SERVICE_NAME,count),_userItemHash)

	return count, leastScore, leastUserID
end

--生成gameServer.login.s2c.UserInfo或者gameServer.login.s2c.UserInfoViewPort对象
local function populateUserInfoPbObj(userItem)
	local attr = ServerUserItem.getAttribute(userItem, {
		"userID", "gameID", "platformID", "faceID", "platformFace", "nickName", "signature", "gender", "memberOrder", "masterOrder", "tableID", "chairID", "userStatus",
		"score", "insure", "gift", "present", "grade", "medal", "experience", "loveliness", "winCount", "lostCount", "drawCount", "fleeCount",
	})

	local obj = {
		userID = attr.userID,
		gameID = attr.gameID,
		platformID = attr.platformID,
		faceID = attr.faceID,
		nickName = attr.nickName,
		gender = attr.gender,
		memberOrder = attr.memberOrder,
		masterOrder = attr.masterOrder,
		tableID = attr.tableID,
		chairID = attr.chairID,
		userStatus = attr.userStatus,
		
		score = attr.score,
		insure = attr.insure,
		gift = attr.gift,
		present = attr.present,
		grade = attr.grade,
		medal = attr.medal,
		experience = attr.experience,
		loveLiness = attr.loveliness,
		
		winCount = attr.winCount,
		lostCount = attr.lostCount,
		drawCount = attr.drawCount,
		fleeCount = attr.fleeCount,
		gem = 0,
		signatureIsHide = 0,
	}

	obj.gem = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"),"lua","GetItemCount",attr.userID,COMMON_CONST.ITEM_ID.ITEM_ID_JEWEL)
	
	if string.len(attr.signature) > 0 then
		obj.signature = attr.signature
	end
	
	if string.len(attr.platformFace) > 0 then
		obj.platformFace = attr.platformFace
	end	

	local HideAllFlag = 0
	local sql = string.format("SELECT HideAllFlag FROM `kfrecorddb`.`t_record_hide_all_signature` WHERE ID = 1")
	local mysqlConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(mysqlConn, "lua", "query", sql)
	if rows[1] ~= nil then
		HideAllFlag = tonumber(rows[1].HideAllFlag)
	end

	if HideAllFlag == 0 then
		local sql = string.format("SELECT HideFlag FROM `kfaccountsdb`.`accountssignature` WHERE UserID = %d",attr.userID)
		local rows = skynet.call(mysqlConn, "lua", "query", sql)
		if rows[1] ~= nil then
			if tonumber(rows[1].HideFlag) == 1 then
				obj.signatureIsHide = 1
			end
		end
	else
		obj.signatureIsHide = 1
	end
	
	return obj
	
end

--发送用户可以看到的其他用户的信息
local function sendOtherUserInfoInViewPort(currentUserID)
	local currentUserItem = _userItemHash[currentUserID]
	if currentUserItem then
		local currentUserAttr = ServerUserItem.getAttribute(currentUserItem, {"agent", "mobileUserRule", "deskPos", "deskCount"})
		
		local isViewAll = (currentUserAttr.mobileUserRule & GS_CONST.MOBILE_USER_RULE.VIEW_MODE_ALL) ~= 0
		local deskPos = currentUserAttr.deskPos
		local deskPosEnd = deskPos + currentUserAttr.deskCount -1
		
		local list = {}
		for loopUserID, loopItem in pairs(_userItemHash) do
			if loopUserID ~= currentUserID then
				local loopAttr = ServerUserItem.getAttribute(loopItem, {"deskPos"})
				
				if isViewAll or (deskPos <= loopAttr.deskPos and loopAttr.deskPos <= deskPosEnd) then
					table.insert(list, populateUserInfoPbObj(loopItem))
				end
			end
		end
		
		if currentUserAttr.agent > 0 then
			skynet.send(currentUserAttr.agent, "lua", "forward", 0x010107, {list=list})
		end
	end
end

-- CAttemperEngineSink::SendDataBatchToMobileUser 群发数据 (不会挂起)
local function sendData2BatchUser(tableID, protocalNo, packetStr)
	for userID, item in pairs(_userItemHash) do
		local userAttr = ServerUserItem.getAttribute(item, {"userStatus", "tableID", "mobileUserRule", "deskPos", "deskCount", "agent"})
		
		--状态过滤
		if userAttr.userStatus == GS_CONST.USER_STATUS.US_OFFLINE then
			goto continue
		end
		
		--可视范围过滤
		if (userAttr.mobileUserRule & GS_CONST.MOBILE_USER_RULE.VIEW_MODE_ALL) == 0 then
			
			local deskPosStart = userAttr.deskPos
			local deskPosEnd = userAttr.deskPos + userAttr.deskCount - 1

			if not (deskPosStart <= tableID and tableID <= deskPosEnd) then
				goto continue
			end
		end
		
		local isReceiveGameChat = (userAttr.mobileUserRule & GS_CONST.MOBILE_USER_RULE.RECVICE_GAME_CHAT) ~= 0
		local isReceiveRoomChat = (userAttr.mobileUserRule & GS_CONST.MOBILE_USER_RULE.RECVICE_ROOM_CHAT) ~= 0
		local isReceiveRoomWhisper = (userAttr.mobileUserRule & GS_CONST.MOBILE_USER_RULE.RECVICE_ROOM_WHISPER) ~= 0
		
		--聊天过滤
		if (protocalNo==0x010400 or protocalNo==0x010401 or protocalNo==0x010402) and not (isReceiveGameChat and isReceiveRoomChat) then
			goto continue
		end
		
		if userAttr.agent > 0 then
			skynet.send(userAttr.agent, "lua", "forward", packetStr)
		end
		
		::continue::
	end
end

local function notifyLSUserLogout(userID, updateAttr,userStatus)
	local itemList = {}
	local bOffLine = true
	if userStatus ~= GS_CONST.USER_STATUS.US_OFFLINE then
		bOffLine = false
		itemList = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "GetItemList", userID)
	end

	local isSuccess, errMsg = pcall(cluster.call, "loginServer", _LS_sessionManagerAddress, "gs_logout", {
		kindID=_serverConfig.KindID,
		nodeID=_serverConfig.NodeID,
		serverID=_serverConfig.ServerID,
		userID=userID,
		updateAttr = updateAttr,
		itemList = itemList,
		bOffLine = bOffLine,
	})
	if not isSuccess then
		skynet.error(string.format("%s.notifyLSUserLogout failed userID=%d : %s", SERVICE_NAME, userID, tostring(errMsg)))
	end
end

local function notifyLSUserOffline(userID)
	local itemList = skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "GetItemList", userID)
	local isSuccess, errMsg = pcall(cluster.call, "loginServer", _LS_sessionManagerAddress, "gs_offline", {
		kindID=_serverConfig.KindID,
		nodeID=_serverConfig.NodeID,
		serverID=_serverConfig.ServerID,
		userID=userID,
		itemList = itemList
	})
	if not isSuccess then
		skynet.error(string.format("%s.notifyLSUserOffline failed userID=%d : %s", SERVICE_NAME, userID, tostring(errMsg)))
	end
end

local function doDBUserLogout(userItem)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_attemperEngine"), "lua", "writeVariationWithoutNotify", userItem)
	
	local attr = ServerUserItem.getAttribute(userItem, {"inoutIndex", "userID"})
	local sql = string.format(
		"call kfaccountsdb.sp_gameserver_logout(%d, %d)",
		attr.inoutIndex,
		attr.userID
	)
	local mysqlConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(mysqlConn, "lua", "call", sql)
	local result = rows[1]
	if tonumber(result.retCode)~=0 then
		error(string.format("%s.doDBUserLogout 错误: userID=%d %s", SERVICE_NAME, attr.userID, tostring(result.retMsg)))
	end
	
	return {
		score = math.tointeger(result.Score),
		insure = math.tointeger(result.Insure),
		medal = math.tointeger(result.UserMedal),
		experience = math.tointeger(result.Experience),
		loveliness = math.tointeger(result.LoveLiness),
		gift = math.tointeger(result.Gift),
		present = math.tointeger(result.Present),
		
		masterOrder = math.tointeger(result.MasterOrder),
		memberOrder = math.tointeger(result.MemberOrder),
		userRight = math.tointeger(result.UserRight),
		masterRight = math.tointeger(result.MasterRight),
		contribution = math.tointeger(result.Contribution),
	}
end

local function broadcastUserStatus(oldTableID, userStatus, userID, tableID, chairID)
	if _isServerClosing then
		return 
	end
	
	local pbObj = {
		userID = userID,
		tableID = tableID,
		chairID = chairID,
		userStatus = userStatus,
	}
	local pbParser = resourceResolver.get("pbParser")
	local packetStr = skynet.call(pbParser, "lua", "encode", 0x010201, pbObj, true)
	
	if userStatus >= GS_CONST.USER_STATUS.US_SIT then
		sendData2BatchUser(tableID, 0x010201, packetStr)
	else
		sendData2BatchUser(oldTableID, 0x010201, packetStr)
	end		
end

local function cmd_saveUserData(userID)	
	skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "SaveUserItem",userID)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_protect"), "lua", "SaveFishId",userID)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_reward_gold_fish"), "lua", "SaveData",userID)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_gunUplevel"), "lua", "SaveData",userID)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "SaveData",userID)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_invalidGun"), "lua", "SaveData",userID)
end

local function cmd_loadUserData(userItem,userID)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "LoadUserItem", userItem)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_protect"), "lua", "LoadFishId", userID)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_reward_gold_fish"), "lua", "LoadData", userID)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "LoadData",userID)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_gunUplevel"), "lua", "LoadData", userItem)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_invalidGun"), "lua", "LoadData",userID)
end

local function cmd_releaseUserData(userID)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ReleaseUserItem",userID)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_protect"), "lua", "ReleaseUserFish",userID)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_reward_gold_fish"), "lua", "ReleaseUserData",userID)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_gunUplevel"), "lua", "ReleaseUserData",userID)			
	skynet.call(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "ReleaseUserData",userID)
	skynet.call(addressResolver.getAddressByServiceName("GS_model_invalidGun"), "lua", "ReleaseUserData",userID)
end

-- CServerUserItem::SetUserStatus, CAttemperEngineSink::OnEventUserItemStatus
local function setUserStatus(userID, userStatus, tableID, chairID)
	local userItem = _userItemHash[userID]
	if userItem==nil then
		skynet.error(string.format("%s setUserStatus userItem找不到 userID=%d userStatus=%d\n%s", SERVICE_NAME, userID, userStatus, debug.traceback(coroutine.running(), nil, 2)))		
		return false
	end
	
	local userAttr = ServerUserItem.getAttribute(userItem, {"tableID", "chairID", "deskPos", "deskCount", "agent", "isAndroid","userStatus"})
	local oldTableID = userAttr.tableID
	
	local attributeToSet = {
		tableID = tableID,
		chairID = chairID,
		userStatus = userStatus,
	}
	
	--CAttemperEngineSink::OnEventUserItemStatus
	if userStatus==GS_CONST.USER_STATUS.US_SIT or userStatus==GS_CONST.USER_STATUS.US_READY or userStatus==GS_CONST.USER_STATUS.US_PLAYING then
		if tableID > (userAttr.deskPos + userAttr.deskCount - 1) or tableID < userAttr.deskPos then
			local newDeskPos = math.floor( (tableID - 1) / userAttr.deskCount) * userAttr.deskCount + 1
			attributeToSet.deskPos=newDeskPos
		end
	elseif userStatus == GS_CONST.USER_STATUS.US_OFFLINE then
		attributeToSet.agent = 0
		if not userAttr.isAndroid then
			if userAttr.tableID ~= GS_CONST.INVALID_TABLE then
				skynet.call(addressResolver.getTableAddress(userAttr.tableID),"lua","SaveInvalidGunGold",userAttr.chairID,userID)
			end

			cmd_saveUserData(userID)
		
			notifyLSUserOffline(userID)
		end
	elseif userStatus == GS_CONST.USER_STATUS.US_NULL then
		_userItemHash[userID] = nil
		_waitDistributeHash[userID] = nil	
		
		if userAttr.agent~=0 then
			skynet.send(userAttr.agent, "lua", "exit")
		end
		
		local isSuccess, updateAttr = pcall(doDBUserLogout, userItem)
		if not isSuccess then
			skynet.error(string.format("doDBUserLogout failed userID=%d : %s", userID, tostring(updateAttr)))
			return
		end
		
		if not userAttr.isAndroid then
			notifyLSUserLogout(userID, updateAttr,userAttr.userStatus)
		end
		
	    cmd_releaseUserData(userID)
	
		CItemBuffer.release(userItem)
		attributeToSet = nil
	end
	
	--CServerUserItem::SetUserStatus
	if attributeToSet then
		ServerUserItem.setAttribute(userItem, attributeToSet)
	end
	
	broadcastUserStatus(oldTableID, userStatus, userID, tableID, chairID)

	return true
end

local function kickUser(userID, message, bCloseRoom)
	local userItem = _userItemHash[userID]
	if not userItem then
		notifyLSUserLogout(userID)	
		return
	end
	
	local userAttr = ServerUserItem.getAttribute(userItem, {"tableID", "agent"})
	if userAttr.agent ~= 0 then
		if type(message)=="string" then
			if bCloseRoom then
				skynet.send(userAttr.agent, "lua", "forward", 0xff0000, {
					msg=message,
					type= COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_CLOSE_ROOM,
				})
			else
				skynet.send(userAttr.agent, "lua", "forward", 0xff0000, {
					msg=message,
					type= COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_PROMPT,
				})
			end
		end	
	end
	
	if userAttr.tableID ~= GS_CONST.INVALID_TABLE then
		local tableAddress = addressResolver.getTableAddress(userAttr.tableID)
		if tableAddress then
			local isSuccess, errMsg = pcall(skynet.call, tableAddress, "lua", "standUp", userItem)
			if not isSuccess then
				skynet.error(string.format("%s kickUser: userID=%d, tableID=%d standUp错误: %s", SERVICE_NAME, userID, userAttr.tableID, tostring(errMsg)))
			end
		else
			skynet.error(string.format("%s kickUser: 找不到桌子地址 userID=%d, tableID=%d", SERVICE_NAME, userID, userAttr.tableID))
		end
	end
	setUserStatus(userID, GS_CONST.USER_STATUS.US_NULL, GS_CONST.INVALID_TABLE, GS_CONST.INVALID_CHAIR)
end

--插入用户
local function cmd_insertUserItem(userInfo, userInfoPlus,itemList)
	local userItem = _userItemHash[userInfo.userID]
	if userItem~=nil then
		return userItem
	end
	
	local onlineCount, leastScore, leastUserID = getUserItemCount(true)

	local userIDToKick = nil
	if onlineCount >= _serverConfig.MaxPlayer then
		if userInfo.score > leastScore then
			-- 踢人
			userIDToKick = leastUserID
		else
			return nil
		end
	end
	
	userInfoPlus.logonTime = math.floor(skynet.time())
	userInfoPlus.restrictScore = _serverConfig.RestrictScore
	userInfoPlus.enListStatus = 0
	userInfoPlus.inoutIndex = 0
	userItem = CItemBuffer.allocate()
	ServerUserItem.initialize(userItem, userInfo, userInfoPlus)
	_userItemHash[userInfo.userID] = userItem

	cmd_loadUserData(userItem,userInfo.userID)

	do
		local sql = string.format(
			"call kfrecorddb.sp_record_user_in(%d, \"%s\", \"%s\", %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d)",
			userInfo.userID,
			userInfoPlus.ipAddr,
			userInfoPlus.machineID,
			_serverConfig.KindID,
			_serverConfig.ServerID,
			
			userInfo.score,
			userInfo.insure,
			userInfo.medal,
			userInfo.experience,
			userInfo.loveliness,
			userInfo.gift,
			userInfo.present,
			
			userInfo.winCount,
			userInfo.lostCount,
			userInfo.drawCount,
			userInfo.fleeCount
		)
		local mysqlConn = addressResolver.getMysqlConnection()
		local rows = skynet.call(mysqlConn, "lua", "call", sql)
		local inoutIndex = tonumber(rows[1].InOutID)
		
		--重入检查
		userItem = _userItemHash[userInfo.userID]
		if userItem==nil then
			sql = string.format("DELETE FROM `kfrecorddb`.`UserInOut` WHERE `ID`=%d", inoutIndex)
			skynet.send(mysqlConn, "lua", "execute", sql)
			return userItem
		end
		
		ServerUserItem.setAttribute(userItem, {["inoutIndex"]=inoutIndex})
	end	
	
	if userIDToKick ~= nil then
		kickUser(userIDToKick, "抱歉，您的筹码最少，被人挤出了房间！")
	end
			
	skynet.send(userInfoPlus.agent, "lua", "subscribeChannel", _broadCastChannel.channel)
	skynet.call(userInfoPlus.agent, "lua", "setCache", userInfoPlus.session, userItem, userInfo.userID)
	return userItem
end

local function cmd_getUserItemCount()
--[[	
	do
		local jsonUtil = require "cjson.util"
		skynet.error(string.format("%s\n _userItemHash=%s", SERVICE_NAME, jsonUtil.serialise_value(_userItemHash)))
	end	
--]]	
	return getUserItemCount()
end

local function cmd_getUserItem(userID)
	return _userItemHash[userID]
end

local function cmd_broadcast(packetStr)
	_broadCastChannel:publish(packetStr)
end

-- CServerUserItem::SetUserStatus, CAttemperEngineSink::OnEventUserItemStatus
local function cmd_setUserStatus(userID, userStatus, tableID, chairID)
	return setUserStatus(userID, userStatus, tableID, chairID)
end

local function cmd_insertWaitDistribute(userID)
	local userItem = _userItemHash[userID]
	if userItem then
		_waitDistributeHash[userID] = userItem
	end
end

local function cmd_removeWaitDistribute(userID)
	_waitDistributeHash[userID] = nil
end

local function cmd_onEventLoginSuccess(data)
	if not data.isAndroid then
		local userItem = _userItemHash[data.userID]
		if userItem then
			skynet.send(data.agent, "lua", "forward", 0x010106, populateUserInfoPbObj(userItem))
			sendOtherUserInfoInViewPort(data.userID)
		end
	end
end

local function cmd_onEventSitDown(data)
	local currentUserItem = _userItemHash[data.userID]
	if currentUserItem then
		local pbObj = populateUserInfoPbObj(currentUserItem)
		
		local pbParser = resourceResolver.get("pbParser")
		local packetStr = skynet.call(pbParser, "lua", "encode", 0x010106, pbObj, true)
		if packetStr then
			sendData2BatchUser(pbObj.tableID, 0x010106, packetStr)
			
			--如果是百人场，不推送其他用户信息
			if _serverConfig.ChairPerTable < GS_CONST.MAX_CHAIR then
				sendOtherUserInfoInViewPort(data.userID)
			end
		end
	end
end

local function cmd_onEventClientDisconnect(data)
	local userItem = _userItemHash[data.userID]
	if not userItem then
		return
	end
	
	local userAttr = ServerUserItem.getAttribute(userItem, {"userID","tableID","isAndroid"})
	if userAttr.tableID~=GS_CONST.INVALID_TABLE then
		local tableAddress = addressResolver.getTableAddress(userAttr.tableID)
		if tableAddress then--牛牛,飞禽走兽掉线的直接站起来,不然会出现刷分
			if not userAttr.isAndroid and (_serverConfig.KindID == 104 or _serverConfig.KindID == 800) then 
				skynet.call(tableAddress, "lua", "standUp", userItem)
				setUserStatus(userAttr.userID, GS_CONST.USER_STATUS.US_NULL, GS_CONST.INVALID_TABLE, GS_CONST.INVALID_CHAIR)
				return
			end
			
			skynet.call(tableAddress, "lua", "userOffLine", userItem)

			return
		else
			skynet.error(string.format("%s: onEventClientDisconnect找不到桌子服务地址", SERVICE_NAME))
		end
	end
	
	--skynet.error(string.format("%s cmd_onEventClientDisconnect set userState null userID=%d", SERVICE_NAME, data.userID))
	setUserStatus(data.userID, GS_CONST.USER_STATUS.US_NULL, GS_CONST.INVALID_TABLE, GS_CONST.INVALID_CHAIR)
end

local function cmd_kickUser(userID, message)
	kickUser(userID, message)
end

local function cmd_kickAllUserBeforeServerClosing()
	_isServerClosing = true
	
	local userIDList = {}
	for userID, _ in pairs(_userItemHash) do
		table.insert(userIDList, userID)
	end
	
	for _, userID in ipairs(userIDList) do
		kickUser(userID, "对不起，服务器维护中，请在维护结束后再进行游戏")
	end

	skynet.send(addressResolver.getAddressByServiceName("GS_model_hd_dropBox"),"lua","savedata")
	skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"),"lua","SaveItemRecord")
end

local function cmd_suiStatistic()
	local inUseCount = 0
	for k, v in pairs(_userItemHash) do
		inUseCount = inUseCount + 1
	end
	
	local ret = CItemBuffer.statistic()
	ret.inUseCount = inUseCount
	return ret
end

local function cmd_userList()
	local ret = {}
	local totalCount = 0
	for userID, item in pairs(_userItemHash) do
		local itemAttr = ServerUserItem.getAttribute(item, {"userID", "nickName", "isAndroid", "userStatus", "tableID", "chairID", "agent", "logonTime","memberOrder","contribution"})
		ret[tostring(userID)] = string.format(
			"isAndroid=%s\tuserStatus=%d\ttableID=%d\tchairID=%d\tagent=0x%06x\tuserID=%d\tlogin=%s\tnickName=%s\tvipLevel=%s\tRMB=%s", 
			tostring(itemAttr.isAndroid), itemAttr.userStatus, itemAttr.tableID, itemAttr.chairID, itemAttr.agent, itemAttr.userID, os.date('%Y-%m-%d %H:%M:%S', itemAttr.logonTime), itemAttr.nickName,itemAttr.memberOrder,itemAttr.contribution
		)
		totalCount = totalCount + 1
	end
	ret.total = totalCount
	return ret
end

local function cmd_switchUserItem(userID, agent, newAttribute)
	local userItem = _userItemHash[userID]
	if not userItem then
		error(string.format("%s.cmd_switchUserItem 错误: 找不到userItem userID=%s", SERVICE_NAME, tostring(userID)))
	end
	
	local attr = ServerUserItem.getAttribute(userItem, {"agent", "userStatus", "tableID", "chairID", "machineID", "isAndroid"})
	if attr.agent ~= 0 then
		-- 解除绑定
		local isSuccess, msg = pcall(skynet.call, attr.agent, "lua", "clearCache")
		if not isSuccess then
			skynet.error(string.format("%s.cmd_switchUserItem agent=[:%08x] clearCache error: %s", SERVICE_NAME, attr.agent, tostring(msg)))
		end
		--skynet.send(attr.agent, "lua", "forward", 0xff0000, {
		--	type = COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_CHAT | COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_EJECT | COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_CLOSE_ROOM,
		--	msg = "请注意，您的帐号在另一地方进入了此游戏房间，您被迫离开！"
		--})
		skynet.send(attr.agent, "lua", "exit")
	end
	
	--状态切换
	if attr.userStatus == GS_CONST.USER_STATUS.US_OFFLINE then
		setUserStatus(userID, GS_CONST.USER_STATUS.US_PLAYING, attr.tableID, attr.chairID)
	end
		
	ServerUserItem.setAttribute(userItem, {
		agent=agent,
		ipAddr=newAttribute.ipAddr,
		machineID=newAttribute.matchineID,
		isClientReady=false,
		mobileUserRule=newAttribute.mobileUserRule,
		deskCount=newAttribute.deskCount,
	})

	skynet.send(agent, "lua", "subscribeChannel", _broadCastChannel.channel)
	skynet.call(agent, "lua", "setCache", newAttribute.session, userItem, userID)

	--安全提示
	if not attr.isAndroid and attr.userStatus ~= GS_CONST.USER_STATUS.US_OFFLINE and attr.machineID ~= newAttribute.matchineID then
		skynet.send(agent, "lua", "forward", 0xff0000, {
			type = COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_CHAT | COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_EJECT,
			msg = "请注意，您的帐号在另一地方进入了此游戏房间，对方被迫离开！"
		})
	end
end

local function cmd_ping()
end

local function cmd_sendTitleMessage(message)
	cluster.call("loginServer", _LS_sessionManagerAddress, "sendTitleMessage",message)
end

local conf = {
	methods = {
		["getUserItem"] = {["func"]=cmd_getUserItem, ["isRet"]=true},
		["insertUserItem"] = {["func"]=cmd_insertUserItem, ["isRet"]=true},
		["switchUserItem"] = {["func"]=cmd_switchUserItem, ["isRet"]=true},
		["getUserItemCount"] = {["func"]=cmd_getUserItemCount, ["isRet"]=true},
		["setUserStatus"] = {["func"]=cmd_setUserStatus, ["isRet"]=true},
		["broadcast"] = {["func"]=cmd_broadcast, ["isRet"]=true},
		["insertWaitDistribute"] = {["func"]=cmd_insertWaitDistribute, ["isRet"]=true},
		["removeWaitDistribute"] = {["func"]=cmd_removeWaitDistribute, ["isRet"]=false},
		["kickUser"] = {["func"]=cmd_kickUser, ["isRet"]=true},
		["kickAllUserBeforeServerClosing"] = {["func"]=cmd_kickAllUserBeforeServerClosing, ["isRet"]=true},
		["suiStatistic"] = {["func"]=cmd_suiStatistic, ["isRet"]=true},
		["userList"] = {["func"]=cmd_userList, ["isRet"]=true},
		
		["ping"] = {["func"]=cmd_ping, ["isRet"]=true},
		
		["onEventLoginSuccess"] = {["func"]=cmd_onEventLoginSuccess, ["isRet"]=false},
		["onEventClientDisconnect"] = {["func"]=cmd_onEventClientDisconnect, ["isRet"]=false},
		["onEventSitDown"] = {["func"]=cmd_onEventSitDown, ["isRet"]=false},
		["saveUserData"] = {["func"]=cmd_saveUserData, ["isRet"]=true},
		["loadUserData"] = {["func"]=cmd_loadUserData, ["isRet"]=true},
		["releaseUserData"] = {["func"]=cmd_releaseUserData, ["isRet"]=true},
		["sendTitleMessage"] = {["func"]=cmd_sendTitleMessage, ["isRet"]=false},
	},
	initFunc = function() 
		resourceResolver.init()
		
		_serverConfig = skynet.call(addressResolver.getAddressByServiceName("GS_model_serverStatus"), "lua", "getServerData")
		if not _serverConfig then
			error("server config not initialized")
		end	
		_LS_sessionManagerAddress = cluster.query("loginServer", "LS_model_sessionManager")
		
		local GS_EVENT = require "define.eventGameServer"
		skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "addEventListener", GS_EVENT.EVT_GS_LOGIN_SUCCESS, skynet.self(), "onEventLoginSuccess")
		skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "addEventListener", GS_EVENT.EVT_GS_SIT_DOWN, skynet.self(), "onEventSitDown")
		skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "addEventListener", GS_EVENT.EVT_GS_CLIENT_DISCONNECT, skynet.self(), "onEventClientDisconnect")
		_broadCastChannel = multicast.new()
	end,
}

commonServiceHelper.createService(conf)
