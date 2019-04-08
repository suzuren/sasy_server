local skynet = require "skynet"
local randHandle = require "utility.randNumber"
local commonServiceHelper = require "serviceHelper.common"
local ServerUserItem = require "sui"
local AndroidUserItem = require "aui"
local GS_CONST = require "define.gsConst"
local GS_EVENT = require "define.eventGameServer"
local addressResolver = require "addressResolver"
local resourceResolver = require "resourceResolver"
local controllerResolveConfig = require "define.controllerResolveConfig"
local pbcc = require "pbcc"
local netpack = require "netpack"
local MCClinetUtility = require "utility.mcClient"
local timerUtility = require "utility.timer"
local xpcallUtility = require "utility.xpcall"

local gameType = skynet.getenv("game")
local androidUserItemSink = require(string.format("%s.lualib.androidUserItemSink", gameType))
local GAME_CONST = require(string.format("%s.lualib.const", gameType))

addressResolver.configKey(controllerResolveConfig.getConfig(gameType))
addressResolver.configKey(controllerResolveConfig.getConfig("gameServer"))

local _data = {
	userID = 0,
	androidUserItem = nil,
	connectionIdentity = {addr="127.0.0.1"},							--{session, sui, userID, addr}
	isGameStarted = false,
	status = {
		userStatus = GS_CONST.USER_STATUS.US_NULL,
		tableID = GS_CONST.INVALID_TABLE,
		chairID = GS_CONST.INVALID_CHAIR,
	},
	gameStatus = GS_CONST.GAME_STATUS.FREE,
}

local dispatchProtocal

local function getAndroidUserItem()
	return _data.androidUserItem
end

local function getServerUserItem()
	return _data.connectionIdentity.sui
end

local function getGameStatus()
	return _data.gameStatus
end

local function isGameStarted()
	return _data.isGameStarted
end

--CAndroidUserItem::CloseGameClient
local function stopGameLogic()
	timerUtility.stop()
	--skynet.error(string.format( "%s.stopGameLogic %s 关闭定时器", SERVICE_NAME,  os.date('%Y-%m-%d %H:%M:%S', math.floor(skynet.time())) ))
	_data.isGameStarted = false
	_data.gameStatus = GS_CONST.GAME_STATUS.FREE
	
	if androidUserItemSink.onEventStopGameLogic then
		androidUserItemSink.onEventStopGameLogic()
	end
end

local function exit()
	stopGameLogic()
	_data.androidUserItem = nil
	
	skynet.call(addressResolver.getAddressByServiceName("GS_model_androidManager"), "lua", "unregisterAndroid", _data.userID)
	
	MCClinetUtility.unsubscribeAll()
	
	if _data.connectionIdentity.session then
		skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "dispatch", GS_EVENT.EVT_GS_CLIENT_DISCONNECT, {
			session = _data.connectionIdentity.session, 
			userID = _data.connectionIdentity.userID, 
			agent=skynet.self(),
		})
		_data.connectionIdentity.session = nil		
	end
	
	--skynet.error(string.format("%s.exit %s", SERVICE_NAME, debug.traceback()))
	skynet.exit()
end

local function parseNetPacket(packetStr)
	local protocalNo, protocalStr, protocalObj
	protocalNo, protocalStr = pbcc.unpackNetPayload(string.sub(packetStr, 3))
	if protocalStr~=nil then
		local pbParser = resourceResolver.get("pbParser")
		protocalObj = skynet.call(pbParser, "lua", "reverseDecode", protocalNo, protocalStr)
	else
		protocalObj = {}
	end
	
	return protocalNo, protocalObj
end

local function onSocketRead(protocalNo, protocalObj)
	--skynet.error("onSocketRead", protocalNo, protocalObj)
	if type(protocalNo)=="string" and protocalObj==nil then
		protocalNo, protocalObj = parseNetPacket(protocalNo)
	end
	
	if type(protocalNo)~="number" or type(protocalObj)~="table" then
		skynet.error(string.format("%s: 不能识别的信息格式 no.=%s, obj=%s", SERVICE_NAME, tostring(protocalNo), tostring(protocalObj)))
		return exit()
	end	
	
	local isOK = xpcall(dispatchProtocal, xpcallUtility.errorMessageSaver, protocalNo, protocalObj)
	if not isOK then
		skynet.error(string.format("%s.dispatchProtocal: 错误 protocalNo=0x%06X: %s", SERVICE_NAME, protocalNo, xpcallUtility.getErrorMessage()))
		return exit()
	end
end

--CAndroidUserItem::SendSocketData
local function sendSocketData(protocalNo, protocalObj)
	local controllerAddress = addressResolver.getAddressByKey(protocalNo & 0xffff00)
	if not controllerAddress then
		skynet.error(string.format("%s: 找不到处理协议的服务 protocalNo=0x%06X", SERVICE_NAME, protocalNo))
		return exit()
	end	
	
	local isSuccess, responseNo, responseObj = skynet.call(controllerAddress, "lua", "request", skynet.self(), protocalNo, protocalObj, _data.connectionIdentity)
	if not isSuccess then
		skynet.error(string.format("%s: 处理协议失败 protocalNo=0x%06X", SERVICE_NAME, protocalNo))
		return exit()
	end	

	if responseNo~=nil then
		onSocketRead(responseNo, responseObj)
	end
end

--CAndroidUserItem::StartGameClient
local function startGameLogic()
	_data.isGameStarted = true
	--skynet.error("开启定时器")
	timerUtility.setExceptionHandler(function()
		skynet.error(string.format("%s 执行定时器错误，机器人断线 userID=%d", SERVICE_NAME, _data.userID))
		exit()
	end)
	timerUtility.start(GAME_CONST.ANDROID_TIMER.TICK_STEP)
	--skynet.error(string.format( "%s.startGameLogic %s 启动定时器", SERVICE_NAME,  os.date('%Y-%m-%d %H:%M:%S', math.floor(skynet.time())) ))
	--skynet.error("send gameOption")
	sendSocketData(0x010202, {isAllowLookon = false})
	
	if androidUserItemSink.onEventStartGameLogic then
		androidUserItemSink.onEventStartGameLogic()
	end
end

local function onResponseLogin(protocalObj)
	if protocalObj.code~="RC_OK" then
		error(string.format("机器人登录错误: %s", protocalObj.code))
	end
	
	_data.gameStatus = GS_CONST.GAME_STATUS.FREE
	skynet.send(addressResolver.getAddressByServiceName("GS_model_androidManager"), "lua", "setServerUserItem", _data.userID, _data.connectionIdentity.sui)
	
	local userAttr = ServerUserItem.getAttribute(_data.connectionIdentity.sui, {"userID","userStatus", "tableID", "chairID"})
	_data.status = userAttr
	
	if _data.status.tableID ~= GS_CONST.INVALID_TABLE then
		startGameLogic()
	end

	-- local sql = string.format("UPDATE `ssaccountsdb`.`AccountsInfo` SET `LastLogonDate`=NOW() WHERE `UserID`=%d",userAttr.userID)
	-- local dbConn = addressResolver.getMysqlConnection()
	-- skynet.call(dbConn,"lua","query",sql)
end

local function onResponseUserStatus(protocalObj)
	--skynet.error("onResponseUserStatus")
	if protocalObj.userID ~= _data.userID then
		return
	end
	
	local lastStatus = _data.status
	_data.status = {
		userStatus = protocalObj.userStatus,
		tableID = protocalObj.tableID,
		chairID = protocalObj.chairID,
	}
	
	--开始切换
	if lastStatus.userStatus ~= GS_CONST.USER_STATUS.US_READY and _data.status.userStatus == GS_CONST.USER_STATUS.US_READY then
		
	end
	
	--关闭判断
	if _data.isGameStarted and _data.status.tableID==GS_CONST.INVALID_TABLE then
		stopGameLogic()
		return
	end
	
	--启动判断
	--skynet.error(string.format( "%s.onResponseUserStatus _data.isGameStarted=%s _data.status.tableID=%d", SERVICE_NAME, tostring(_data.isGameStarted), _data.status.tableID ))
	if not _data.isGameStarted and _data.status.tableID~=GS_CONST.INVALID_TABLE then
		startGameLogic()
		return
	end

	--准备判断
	if _data.isGameStarted and _data.status.userStatus == GS_CONST.USER_STATUS.US_SIT then
		if androidUserItemSink.onEventChangeUserStatus then
			androidUserItemSink.onEventChangeUserStatus()
		end
	end
end

local function onResponseGameStatus(protocalObj)
	_data.gameStatus = protocalObj.gameStatus
end

local function onResponseSystemMessage(protocalObj)
	--skynet.error(string.format("%s %s", SERVICE_NAME, protocalObj.msg))
end

dispatchProtocal = function(protocalNo, protocalObj)
	if protocalNo==0x010108 then
		onResponseLogin(protocalObj)
	elseif _data.connectionIdentity.sui~=nil then
		if protocalNo==0x010201 then
			onResponseUserStatus(protocalObj)
		elseif protocalNo==0x010203 then
			onResponseGameStatus(protocalObj)
		elseif protocalNo==0xff0000 then
			onResponseSystemMessage(protocalObj)		
		elseif _data.isGameStarted then
			androidUserItemSink.dispatchProtocal(protocalNo, protocalObj)
		end
	end
end


local function cmd_getAndroidParameter()
	return AndroidUserItem.getAttribute(_data.androidUserItem, {"androidParameter"})
end

local function cmd_exit()
	exit()
end

local function cmd_forward(protocalNo, protocalObj)
	onSocketRead(protocalNo, protocalObj)
end

local function cmd_forwardMultiple(msgList)
	for _, item in ipairs(msgList) do
		onSocketRead(item[1], item[2])
	end
end

local function cmd_setCache(session, sui, userID)
	_data.connectionIdentity.session = session
	_data.connectionIdentity.sui = sui
	_data.connectionIdentity.userID = userID
end

local function cmd_clearCache()
	_data.connectionIdentity.session = nil
	_data.connectionIdentity.sui = nil
	_data.connectionIdentity.userID = nil
end

local interface4sink = {
	getAndroidUserItem = getAndroidUserItem,
	getServerUserItem = getServerUserItem,
	getGameStatus = getGameStatus,
	sendSocketData = sendSocketData,
	isGameStarted = isGameStarted,
}

local function cmd_start(androidItem, chairPerTable)
	_data.androidUserItem = androidItem
	local androidAttr = AndroidUserItem.getAttribute(_data.androidUserItem, {"androidParameter"})
	_data.userID = androidAttr.androidParameter.userID
	--skynet.error(string.format("%s start userID=%d", SERVICE_NAME, _data.userID))
	
	local setAttr = {}
	
	--服务时间
	if androidAttr.androidParameter.minReposeTime > 0 and androidAttr.androidParameter.maxReposeTime > 0 then
		if androidAttr.androidParameter.minReposeTime < androidAttr.androidParameter.maxReposeTime then
			setAttr.reposeTime = randHandle.random(androidAttr.androidParameter.minReposeTime, androidAttr.androidParameter.maxReposeTime)
		else
			setAttr.reposeTime = androidAttr.androidParameter.minReposeTime
		end
	else
		setAttr.reposeTime = 1800
	end
	
	--游戏局数
	if androidAttr.androidParameter.minPlayDraw > 0 and androidAttr.androidParameter.maxPlayDraw > 0 then
		if androidAttr.androidParameter.minPlayDraw < androidAttr.androidParameter.maxPlayDraw then
			setAttr.residualPlayDraw = randHandle.random(androidAttr.androidParameter.minPlayDraw, androidAttr.androidParameter.maxPlayDraw)
		else
			setAttr.residualPlayDraw = androidAttr.androidParameter.minPlayDraw
		end
	else
		setAttr.residualPlayDraw = 10
	end
	
	AndroidUserItem.setAttribute(_data.androidUserItem, setAttr)
	
	MCClinetUtility.initialize(function(channel, source, protocalNo, protocalObj)
		onSocketRead(protocalNo, protocalObj)
	end)

	androidUserItemSink.initialize(interface4sink, chairPerTable)
	
	sendSocketData(0x010108, {
		userID = _data.userID,
		machineID = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		behaviorFlags = 0,
		pageTableCount = 5,
	})
	--skynet.error(string.format("%s.cmd_start send 0x010108", SERVICE_NAME))
end


local conf = {
	methods = {
		["getAndroidParameter"] = {["func"]=cmd_getAndroidParameter, ["isRet"]=true},
		
		["start"] = {["func"]=cmd_start, ["isRet"]=false},
		["exit"] = {["func"]=cmd_exit, ["isRet"]=false},
		["forward"] = {["func"]=cmd_forward, ["isRet"]=false},
		["forwardMultiple"] = {["func"]=cmd_forwardMultiple, ["isRet"]=false},
		["setCache"] = {["func"]=cmd_setCache, ["isRet"]=true},
		["clearCache"] = {["func"]=cmd_clearCache, ["isRet"]=true},		
		["subscribeChannel"] = {["func"]=MCClinetUtility.subscribeChannel, ["isRet"]=false},
		["unsubscribeChannel"] = {["func"]=MCClinetUtility.unsubscribeChannel, ["isRet"]=false},		
	},
	initFunc = function()
		resourceResolver.init()
	end,
}

commonServiceHelper.createService(conf)

