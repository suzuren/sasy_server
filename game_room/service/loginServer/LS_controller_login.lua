local skynet = require "skynet"
--local mysqlutil = require "mysqlutil"
local pbServiceHelper = require "serviceHelper.pb"
local LS_CONST = require "define.lsConst"
local LS_EVENT = require "define.eventLoginServer"
local addressResolver = require "addressResolver"
local resourceResolver = require "resourceResolver"
local timerUtility = require "utility.timer"
local ServerUserItem = require "sui"
local COMMON_CONST = require "define.commonConst"
local sysConfig = require "sysConfig"

local inspect = require "inspect"

local _cachedProtoStr={}
local _0x000100FrequenceControl = {}

local function checkFrequenceControl()
	local nowTick = skynet.now()
	for session, tick in pairs(_0x000100FrequenceControl) do
		if nowTick - tick > LS_CONST.LOGIN_CONTROL.TIMEOUT_THRESHOLD_TICK then
			_0x000100FrequenceControl[session] = nil
		end
	end
end

local function isFrequenceControlCheckOk(session)
	local result
	--skynet.error("LS_controller_login.lua - isFrequenceControlCheckOk",string.format("session[%s]",session))
	--print("_0x000100FrequenceControl:",_0x000100FrequenceControl[session])
	if _0x000100FrequenceControl[session]~=nil then
		result = false
	else
		_0x000100FrequenceControl[session] = skynet.now()
		result = true
	end

	return result
end

local function doLoginserverLogin(platformID, nickName, ipAddr, machineID)
--[[
	local sql = string.format(
		"call kfaccountsdb.sp_loginserver_login(%d, '%s', '%s', '%s')",
		platformID,
		mysqlutil.escapestring(nickName),
		ipAddr,
		mysqlutil.escapestring(machineID)
	)
	local mysqlConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(mysqlConn, "lua", "call", sql)
	if type(rows)~="table" then
		error(string.format("%s.doLoginserverLogin error sql=%s", SERVICE_NAME, sql))
	end
	
	local result = rows[1]
	for k, v in pairs(result) do
		if k~="retMsg" and k~="NickName" and k~="Signature" and k~="PlatformFace" then
			result[k]=tonumber(v)
		end
	end
	]]
	--SELECT retCode, retMsg, varUserID AS "UserID", inPlatformID AS "PlatformID", varGameID AS "GameID", 
	--varNickName AS "NickName", varSignature AS "Signature",varHideFlag AS "HideFlag", varFaceID AS "FaceID",
	-- varPlatformFace AS "PlatformFace", varGender AS "Gender", varUserMedal AS "UserMedal", 
	--varExperience AS "Experience", varPresent AS "Present", varScore AS "Score", varInsure AS "Insure",
	-- varLoveLiness AS "LoveLiness", varMemberOrder AS "MemberOrder", UNIX_TIMESTAMP(varMemberOverDate) AS "MemberOverDate",
	-- varGift AS "Gift", varUserRight AS "UserRight", varMasterRight AS "MasterRight", varMasterOrder AS "MasterOrder",
	-- varContribution AS "Contribution", varStatus AS "Status", varWinCount AS "WinCount", varLostCount AS "LostCount", 
	--varFleeCount AS "FleeCount", varDrawCount AS "DrawCount", varIsFirstRegister AS "IsFirstRegister";

	local result = 
	{
		retCode = 0,
		retMsg = "success",
		UserID = 1003,
		PlatformID = 3,
		GameID = 10003,
		NickName = "alice",
		Signature = "Signature_1003",
		HideFlag = 1,
		FaceID = 1,
		PlatformFace = "PlatformFace_1003",
		Gender = 1,
		UserMedal = 1,
		Experience = 1,
		Present = 1,
		Score = 1,
		Insure = 1,
		LoveLiness = 1,
		MemberOrder = 1,
		MemberOverDate = 1,
		Gift = 1,
		UserRight = 1,
		MasterRight = 1,
		MasterOrder = 1,
		Contribution = 1,
		WinCount = 1,
		LostCount = 1,
		FleeCount = 1,
		DrawCount = 1,
		IsFirstRegister = 0,
	}
	return result
end

local function getPlatformIDBySession(session)
	local platformID
	local tryCnt = 0
	repeat
		platformID = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getPlatformIDBySession", session)
		--print("getPlatformIDBySession(session)",session,platformID);
		tryCnt = tryCnt + 1
		if platformID==nil and tryCnt < LS_CONST.LOGIN_CONTROL.RETRY_COUNT then
			skynet.sleep(LS_CONST.LOGIN_CONTROL.RETRY_INTERVAL_TICK)
		end
	until tryCnt>=LS_CONST.LOGIN_CONTROL.RETRY_COUNT or platformID~=nil
	return platformID
end

local function registerUser(userInfo, platformID, agent, ipAddr, machineID)

	-- local HideAllFlag = 0
	-- local sql = string.format("SELECT HideAllFlag FROM `kfrecorddb`.`t_record_hide_all_signature` WHERE ID = 1")
	-- local dbConn = addressResolver.getMysqlConnection()
	-- local rows = skynet.call(dbConn, "lua", "query", sql)
	-- if rows[1] ~= nil then
	-- 	HideAllFlag = tonumber(rows[1].HideAllFlag)
	-- end

	-- if HideAllFlag == 0 then
	-- 	if userInfo.HideFlag then
	-- 		if tonumber(userInfo.HideFlag) == 1 then
	-- 			if userInfo.Signature then
	-- 				userInfo.Signature = nil
	-- 			end
	-- 		end
	-- 	end
	-- else
	-- 	userInfo.Signature = nil
	-- end


	return skynet.call(
		addressResolver.getAddressByServiceName("LS_model_sessionManager"), 
		"lua", 
		"registerUser", 
		platformID,
		{
			userID=userInfo.UserID,
			gameID=userInfo.GameID,
			platformID=userInfo.PlatformID,
			nickName=userInfo.NickName,
			signature=userInfo.Signature,
			
			gender=userInfo.Gender,
			faceID=userInfo.FaceID,
			platformFace=userInfo.PlatformFace,
			userRight=userInfo.UserRight,
			masterRight=userInfo.MasterRight,
			memberOrder=userInfo.MemberOrder,
			masterOrder=userInfo.MasterOrder,
			score=userInfo.Score,
			insure=userInfo.Insure,
			medal=userInfo.UserMedal,
			gift=userInfo.Gift,
			present=userInfo.Present,
			experience=userInfo.Experience,
			loveliness=userInfo.LoveLiness,
			winCount=userInfo.WinCount,
			lostCount=userInfo.LostCount,
			drawCount=userInfo.DrawCount,
			fleeCount=userInfo.FleeCount,
			contribution=userInfo.Contribution,
			dbStatus=userInfo.Status,
		},
		{
			logonTime = math.floor(skynet.time()),
			userStatus=LS_CONST.USER_STATUS.US_LS,
			isAndroid = false,
			agent = agent,
			ipAddr = ipAddr,
			machineID = machineID,
		}
	)
end

local function UploadUserToPlatform(agent,userID,pbObj)

	local bFlag = false

	if pbObj.appID ~= nil and pbObj.appChannel ~= nil and pbObj.appVersion ~= nil then
		local dbConn = addressResolver.getMysqlConnection()
		local sql = string.format("call `kffishdb`.`sp_deduct_user` (%d,%d,'%s','%s')",userID,pbObj.appID,pbObj.appChannel,pbObj.appVersion)
		local ret = skynet.call(dbConn, "lua", "call", sql)[1]
		if tonumber(ret.retCode) == 1 then		
			bFlag = true
		end
	else
		bFlag = true
	end

	skynet.send(agent, "lua", "forward", 0x000103, {bUploadUser=bFlag})
end

local REQUEST = {
	-- 登录
	[0x000100] = function(tcpAgent, pbObj, tcpAgentData)

		local startTime = skynet.now()

		if tcpAgentData.session then
			return _cachedProtoStr["0x000100_ALREADY_LOGIN"]
		end
		--print("11111111111111111111");
		if not isFrequenceControlCheckOk(pbObj.session) then
			return
		end
		--print("2222222222222222222222");
		local platformID = getPlatformIDBySession(pbObj.session)
		--print("2222222222222222222222 - platformID- ",platformID);
		if not platformID then
			return _cachedProtoStr["0x000100_INVALID_SESSION"]
		end
		--print("333333333333333333");
		local isFirstRegister = false
		local userItem = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getUserItemByPlatformID", platformID, true)
		--print("444444444444444444 - userItem- ",userItem);
		if userItem then
			skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "switchUserItem", platformID, {
				agent=tcpAgent,
				ipAddr=tcpAgentData.addr,
				matchineID=pbObj.machineID,
			})
		else
			local row = doLoginserverLogin(platformID, pbObj.nickName, tcpAgentData.addr, pbObj.machineID)
			if row.retCode~=0 then
				if row.retCode==1 then
					return 0x000100, {code="RC_LOGIN_CLOSED", msg=row.retMsg}
				elseif row.retCode==2 then
					return _cachedProtoStr["0x000100_IP_BANNED"]
				elseif row.retCode==3 then
					return _cachedProtoStr["0x000100_MACHINE_BANNED"]
				elseif row.retCode==4 then
					return _cachedProtoStr["0x000100_ACCOUNT_NULLITY"]				
				elseif row.retCode==5 then
					return _cachedProtoStr["0x000100_ACCOUNT_STUNDOWN"]			
				else
					return _cachedProtoStr["0x000100_INTERAL_DB_ERROR"]
				end
			end
			
			if math.tointeger(row.IsFirstRegister)==1 then
				isFirstRegister = true
			end
			userItem = registerUser(row, platformID, tcpAgent, tcpAgentData.addr, pbObj.machineID)
		end
		--skynet.error("LS_controller_login.lua REQUEST - userItem-\n",inspect(userItem),"\n-")

		local attr = ServerUserItem.getAttribute(userItem, {
			"userID", "gameID", "faceID", "gender", "nickName", "memberOrder", "signature", "platformFace",
			"medal", "experience", "loveliness", "score", "insure", "gift", "present", "contribution",
		})
		--skynet.error("LS_controller_login.lua REQUEST - attr-\n",inspect(attr),"\n-")
		--变更玩家初始金币
		if isFirstRegister then
			skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "changeRegistBinding", platformID, attr.userID, pbObj.scoreTag)
			--重新获取用户信息
			attr = ServerUserItem.getAttribute(userItem, {
				"userID", "gameID", "faceID", "gender", "nickName", "memberOrder", "signature", "platformFace",
				"medal", "experience", "loveliness", "score", "insure", "gift", "present", "contribution",
			})
		end

		local loginSuccess = {
			userID = attr.userID,
			gameID = attr.gameID,
			faceID = attr.faceID,
			gender = attr.gender,
			nickName = attr.nickName,
			isRegister = isFirstRegister,
			memberOrder = attr.memberOrder,
		}
		
		if string.len(attr.signature) > 0 then
			loginSuccess.signature = attr.signature
		end
		
		if string.len(attr.platformFace) > 0 then
			loginSuccess.platformFace = attr.platformFace
		end

		local isChangeNickName = false
		local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_CHANGE_NAME
		--local sql = string.format("select * from `kfrecorddb`.`t_user_operator_limit` where UserId = %d and LimitId = %d",attr.userID,limitId)
       	--local dbConn = addressResolver.getMysqlConnection()
        --local rowss = skynet.call(dbConn, "lua", "call", sql)
        --if rowss[1] ~= nil then
        --	isChangeNickName = true
        --end
		loginSuccess.isChangeNickName = isChangeNickName
		
		skynet.error("LS_controller_login.lua REQUEST - loginSuccess-\n",inspect(loginSuccess),"\n-")

		skynet.send(tcpAgent, "lua", "forward", 0x000100, {code="RC_OK",msg="success",data=loginSuccess})
		
		--[[
		skynet.send(tcpAgent, "lua", "forward", 0x000102, {
			medal=attr.medal,
			experience=attr.experience,
			loveLiness=attr.loveliness,
			score=attr.score,
			insure=attr.insure,
			gift=attr.gift,
			present=attr.present,
		})

		--UploadUserToPlatform(tcpAgent,attr.userID,pbObj)
	
		--通过发送事件来发送其他需要的协议
		skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "dispatch", LS_EVENT.EVT_LS_LOGIN_SUCCESS, {
			platformID=platformID,
			session=pbObj.session,
			userID=attr.userID,
			agent = tcpAgent,
			kindID = pbObj.kindID,
			contribution = attr.contribution,
		})
		]]

		local endTime = skynet.now()
		skynet.error(string.format("--0x000100------大厅登入----costTime=%d------userid=%d------------",endTime-startTime,attr.userID))
	end,

	[0x000103] = function(tcpAgent, pbObj, tcpAgentData)
		if not sysConfig.isTest then
			return
		end

		local startTime = skynet.now()

		--模拟器登陆
		skynet.send(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "registerSession",pbObj.session, tonumber(pbObj.session))

		if tcpAgentData.session then
			return _cachedProtoStr["0x000100_ALREADY_LOGIN"]
		end		
		
		if not isFrequenceControlCheckOk(pbObj.session) then
			return
		end
		
		local platformID = getPlatformIDBySession(pbObj.session)
		if not platformID then
			return _cachedProtoStr["0x000100_INVALID_SESSION"]
		end
		
		local isFirstRegister = false
		local userItem = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getUserItemByPlatformID", platformID, true)
		if userItem then
			skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "switchUserItem", platformID, {
				agent=tcpAgent,
				ipAddr=tcpAgentData.addr,
				matchineID=pbObj.machineID,
			})
		else
			local row = doLoginserverLogin(platformID, pbObj.nickName, tcpAgentData.addr, pbObj.machineID)
			if row.retCode~=0 then
				if row.retCode==1 then
					return 0x000100, {code="RC_LOGIN_CLOSED", msg=row.retMsg}
				elseif row.retCode==2 then
					return _cachedProtoStr["0x000100_IP_BANNED"]
				elseif row.retCode==3 then
					return _cachedProtoStr["0x000100_MACHINE_BANNED"]
				elseif row.retCode==4 then
					return _cachedProtoStr["0x000100_ACCOUNT_NULLITY"]				
				elseif row.retCode==5 then
					return _cachedProtoStr["0x000100_ACCOUNT_STUNDOWN"]			
				else
					return _cachedProtoStr["0x000100_INTERAL_DB_ERROR"]
				end
			end
			
			if math.tointeger(row.IsFirstRegister)==1 then
				isFirstRegister = true
			end
			userItem = registerUser(row, platformID, tcpAgent, tcpAgentData.addr, pbObj.machineID)
		end
				
		local attr = ServerUserItem.getAttribute(userItem, {
			"userID", "gameID", "faceID", "gender", "nickName", "memberOrder", "signature", "platformFace",
			"medal", "experience", "loveliness", "score", "insure", "gift", "present", "contribution",
		})

		--变更玩家初始金币
		if isFirstRegister then
			skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "changeRegistBinding", platformID, attr.userID, pbObj.scoreTag)
		end
				
		local loginSuccess = {
			userID = attr.userID,
			gameID = attr.gameID,
			faceID = attr.faceID,
			gender = attr.gender,
			nickName = attr.nickName,
			isRegister = isFirstRegister,
			memberOrder = attr.memberOrder,
		}
		
		if string.len(attr.signature) > 0 then
			loginSuccess.signature = attr.signature
		end
		
		if string.len(attr.platformFace) > 0 then
			loginSuccess.platformFace = attr.platformFace
		end

		local isChangeNickName = false
		local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_CHANGE_NAME
		local sql = string.format("select * from `kfrecorddb`.`t_user_operator_limit` where UserId = %d and LimitId = %d",attr.userID,limitId)
        local dbConn = addressResolver.getMysqlConnection()
        local rowss = skynet.call(dbConn, "lua", "call", sql)
        if rowss[1] ~= nil then
        	isChangeNickName = true
        end
        loginSuccess.isChangeNickName = isChangeNickName
		
		skynet.send(tcpAgent, "lua", "forward", 0x000100, {code="RC_OK", data=loginSuccess})
		skynet.send(tcpAgent, "lua", "forward", 0x000102, {
			medal=attr.medal,
			experience=attr.experience,
			loveLiness=attr.loveliness,
			score=attr.score,
			insure=attr.insure,
			gift=attr.gift,
			present=attr.present,
		})

		UploadUserToPlatform(tcpAgent,attr.userID,pbObj)
	
		--通过发送事件来发送其他需要的协议
		skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "dispatch", LS_EVENT.EVT_LS_LOGIN_SUCCESS, {
			platformID=platformID,
			session=pbObj.session,
			userID=attr.userID,
			agent = tcpAgent,
			kindID = pbObj.kindID,
			contribution = attr.contribution,
		})

		local endTime = skynet.now()
		skynet.error(string.format("--0x000103------大厅登入----costTime=%d------userid=%d------------",endTime-startTime,attr.userID))

	end,
	[0x000104] = function(tcpAgent, pbObj, tcpAgentData)
		local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_VERSION_FALG
		local bLimit = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "CheckIsForeverLimit",tcpAgentData.userID,limitId,1)
		if not bLimit then   
			skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "AddLimit",tcpAgentData.userID,limitId,1)
        end
	end,
	[0x000105] = function(tcpAgent, pbObj, tcpAgentData)
		local limitId = COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_VERSION_FALG
		local iCount = skynet.call(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "GetLimitCount",tcpAgentData.userID,limitId)
		if iCount == 1 then
			local itemList = {}
			table.insert(itemList,{
				goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,
				goodsCount = 50000,
			})
			local messageTitle = string.format("新版更新福利")
			local messageInfo = string.format("恭喜你获得下载最新版本的福利50000金币,请查收附件")
			skynet.send(addressResolver.getAddressByServiceName("LS_model_message"),"lua","sendEmailToUser",tcpAgentData.userID,itemList,messageTitle,messageInfo)
			skynet.send(addressResolver.getAddressByServiceName("LS_model_operatorLimit"), "lua", "AddLimit",tcpAgentData.userID,limitId,1)
		end
	end,
}

local conf = {
	loginCheck = false,
	protocalHandlers = REQUEST,
	initFunc = function()
		resourceResolver.init()
		local pbParser = resourceResolver.get("pbParser")
		--_cachedProtoStr["0x000100_INVALID_SESSION"] = skynet.call(pbParser, "lua", "encode", 0x000100, {code="RC_INVALID_SESSION"}, true)
		--_cachedProtoStr["0x000100_IP_BANNED"] = skynet.call(pbParser, "lua", "encode", 0x000100, {code="RC_IP_BANNED"}, true)
		--_cachedProtoStr["0x000100_MACHINE_BANNED"] = skynet.call(pbParser, "lua", "encode", 0x000100, {code="RC_MACHINE_BANNED"}, true)
		--_cachedProtoStr["0x000100_INTERAL_DB_ERROR"] = skynet.call(pbParser, "lua", "encode", 0x000100, {code="RC_INTERAL_DB_ERROR"}, true)
		--_cachedProtoStr["0x000100_ACCOUNT_NULLITY"] = skynet.call(pbParser, "lua", "encode", 0x000100, {code="RC_ACCOUNT_NULLITY"}, true)
		--_cachedProtoStr["0x000100_ACCOUNT_STUNDOWN"] = skynet.call(pbParser, "lua", "encode", 0x000100, {code="RC_ACCOUNT_STUNDOWN"}, true)
		--_cachedProtoStr["0x000100_ALREADY_LOGIN"] = skynet.call(pbParser, "lua", "encode", 0x000100, {code="RC_ALREADY_LOGIN"}, true)
		
		timerUtility.start(LS_CONST.LOGIN_CONTROL.TIMEOUT_CHECK_INTERVAL_TICK)
		timerUtility.setInterval(checkFrequenceControl, 1)
	end
}

pbServiceHelper.createService(conf)
