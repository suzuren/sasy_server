local skynet = require "skynet"
local arc4 = require "arc4random"
local GS_CONST = require "define.gsConst"
local FISH_CONST = require "fish.lualib.const"
local timerUtility = require "utility.timer"
local ServerUserItem = require "sui"
local bulletUtility = require "utility.bullet"

local _data = {
	android = nil,
	type = FISH_CONST.ANDROID_TYPE.AT_RANDOM,
	
	currentBulletMultiple = 0,
	currentBulletKind = -1,
	bulletID = 0, 
	
	fishScore = 0,
	
	timerIDHash = {},
	isSpecialScene = false,
}

local function initialize(android, chairPerTable)
	_data.android = android
	bulletUtility.setChairPerTable(chairPerTable)
	if arc4.random(0, 1)==1 then
		_data.type = FISH_CONST.ANDROID_TYPE.AT_RANDOM
	else
		_data.type = FISH_CONST.ANDROID_TYPE.AT_BIGTARGET
	end
	
end

local function checkBulletMultiple()
	local bulletKind = bulletUtility.getBulletKindByScore(_data.fishScore)
	
	if bulletKind > _data.currentBulletKind or _data.fishScore < _data.currentBulletMultiple then
		_data.currentBulletKind = bulletKind
		_data.currentBulletMultiple = bulletUtility.getBulletMultipleByKind(_data.fishScore, _data.currentBulletKind)
	end
end

local function onTimerStandUp()
	_data.timerIDHash.standUP = nil
	_data.android.sendSocketData(0x010204, {isForce=true})
end

local function onTimerFire()
	_data.timerIDHash.fire = nil
	
	checkBulletMultiple()
	if _data.fishScore < _data.currentBulletMultiple then
		--skynet.error("机器人钱不够, 站起")
		_data.timerIDHash.standUP = timerUtility.setTimeout(onTimerStandUp, 3)
	else
		local userItem = _data.android.getServerUserItem()
		local userAttr = ServerUserItem.getAttribute(userItem, {"chairID",})
		_data.bulletID = _data.bulletID + 1
		
		_data.android.sendSocketData(0x020000, {
			bulletKind = _data.currentBulletKind,
			bulletID = _data.bulletID,
			angle = bulletUtility.getAngle(userAttr.chairID),
			bulletMultiple = _data.currentBulletMultiple,
			lockFishID = 0,
			currentScore = _data.fishScore,
		})
		_data.timerIDHash.fire = timerUtility.setTimeout(onTimerFire, arc4.random(1, 2))
		--skynet.error("设置开炮定时器")
	end
end

local function onResponseGameScene(protocalObj)
	local gameStatus = _data.android.getGameStatus()
	--skynet.error(string.format( "%s.onResponseGameScene %s gameStatus=%d", SERVICE_NAME, os.date('%Y-%m-%d %H:%M:%S', math.floor(skynet.time())), gameStatus ))
	if gameStatus==GS_CONST.GAME_STATUS.FREE or gameStatus==GS_CONST.GAME_STATUS.PLAY then
		_data.bulletID = 0
		_data.timerIDHash.fire = timerUtility.setTimeout(onTimerFire, arc4.random(3, 5))
		_data.isSpecialScene = protocalObj.isSpecialScene
		--skynet.error(string.format("%s.onResponseGameScene %s 初始化开炮定时器", SERVICE_NAME, os.date('%Y-%m-%d %H:%M:%S', math.floor(skynet.time()))))
	end
end

local function onResponseExchangeFishScore(protocalObj)
	local userItem = _data.android.getServerUserItem()
	local userAttr = ServerUserItem.getAttribute(userItem, {"chairID",})
	
	if userAttr.chairID==protocalObj.chairID then
		--skynet.error(string.format("onResponseExchangeFishScore currentBulletMultiple=%d", _data.currentBulletMultiple))
		_data.fishScore = protocalObj.fishScore
		_data.currentBulletKind = bulletUtility.getBulletKindByScore(_data.fishScore)
		_data.currentBulletMultiple = bulletUtility.getBulletMultipleByKind(_data.fishScore, _data.currentBulletKind)
		--skynet.error(string.format("onResponseExchangeFishScore fishScore=%d", _data.fishScore))
		--skynet.error(string.format("onResponseExchangeFishScore currentBulletMultiple=%d", _data.currentBulletMultiple))
	end
end

local function onResponseGameConfig(protocalObj)
	--skynet.error("onResponseGameConfig ", protocalObj.bulletMultipleMin, protocalObj.bulletMultipleMax)
	bulletUtility.setMultipleLimit(protocalObj.bulletMultipleMin, protocalObj.bulletMultipleMax)
	_data.currentBulletMultiple = protocalObj.bulletMultipleMin
	--skynet.error("onResponseGameConfig "..tostring(_data.currentBulletMultiple))
end


local function onResponseCatchFish(protocalObj)
	local userItem = _data.android.getServerUserItem()
	local userAttr = ServerUserItem.getAttribute(userItem, {"chairID",})
	
	if userAttr.chairID==protocalObj.chairID then
		_data.fishScore = _data.fishScore + protocalObj.fishScore
	end
end

local function onResponseCatchSweepFish(protocalObj)
	local userItem = _data.android.getServerUserItem()
	local userAttr = ServerUserItem.getAttribute(userItem, {"chairID",})
	
	if userAttr.chairID==protocalObj.chairID then
		_data.fishScore = _data.fishScore + protocalObj.fishScore
	end
end

local function onResponseSwitchScene(protocalObj)
	if _data.timerIDHash.fire then
		timerUtility.clearTimer(_data.timerIDHash.fire)
		_data.timerIDHash.fire = nil
	end
	_data.isSpecialScene = true
	--skynet.error("设置开炮定时器")
	_data.timerIDHash.fire = timerUtility.setTimeout(onTimerFire, FISH_CONST.ANDROID_TIMER.TICKSPAN_SWITCH_SCENE_WAIT + arc4.random(8, 12))
end

local function onResponseUserFire(protocalObj)
	local userItem = _data.android.getServerUserItem()
	local userAttr = ServerUserItem.getAttribute(userItem, {"chairID",})
	
	if userAttr.chairID==protocalObj.chairID then
		_data.fishScore = _data.fishScore - protocalObj.bulletMultiple
		
		_data.android.sendSocketData(0x02000F, {
			bulletID = protocalObj.bulletID,
			androidType = _data.type,
		})
	end
end

local function onResponseBulletCompensate(protocalObj)
	local userItem = _data.android.getServerUserItem()
	local userAttr = ServerUserItem.getAttribute(userItem, {"chairID",})
	
	if userAttr.chairID==protocalObj.chairID then
		_data.fishScore = _data.fishScore + protocalObj.compensateScore
	end
end

local function onResponseEndScene()
	_data.isSpecialScene = false
end

--CAndroidUserItemSink::OnEventGameMessage
local function dispatchProtocal(protocalNo, protocalObj)
	if protocalNo==0x020005 then
		onResponseGameConfig(protocalObj)		
	elseif protocalNo==0x020006 then
		onResponseGameScene(protocalObj)
	elseif protocalNo==0x020007 then
		onResponseExchangeFishScore(protocalObj)
	elseif protocalNo==0x02000B then
		onResponseCatchFish(protocalObj)
	elseif protocalNo==0x02000C then
		onResponseCatchSweepFish(protocalObj)
	elseif protocalNo==0x020003 then
		onResponseSwitchScene(protocalObj)
	elseif protocalNo==0x020000 then
		onResponseUserFire(protocalObj)
	elseif protocalNo==0x02000E then
		onResponseBulletCompensate(protocalObj)
	elseif protocalNo==0x020002 then
		onResponseEndScene()	
	else
		--skynet.error(string.format("%s: 未处理的协议 0x%X", SERVICE_NAME, protocalNo))
	end
end

local function onEventStopGameLogic()
	_data.currentBulletMultiple = 0
	_data.currentBulletKind = 0
	_data.bulletID = 0
	
	_data.fishScore = 0
	
	for _, timerID in pairs(_data.timerIDHash) do
		timerUtility.clearTimer(timerID)
	end
	
	_data.timerIDHash = {}
	_data.isSpecialScene = false
end

return {
	initialize = initialize,
	dispatchProtocal = dispatchProtocal,
	onEventStopGameLogic = onEventStopGameLogic,
}