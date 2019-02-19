local LOGIN_CONTROL = {
	RETRY_INTERVAL_TICK = 30,
	RETRY_COUNT = 3,
	TIMEOUT_THRESHOLD_TICK=200,
	TIMEOUT_CHECK_INTERVAL_TICK = 100,
}

local SESSION_CONTROL = {
	USER_ITEM_LIFE_TIME = 300,			-- 5 minute
	SESSION_LIFE_TIME = 10800,			-- 3 hours
	CHECK_INTERVAL = 600,				-- 10 minute
}

local USER_STATUS = {
	US_NULL 			= 0x00,								--没有状态
	US_LS 				= 0x01,								--登录服务器
	US_GS 				= 0x02,								--游戏服务器
	US_GS_OFFLINE 		= 0x03,								--游戏掉线
	US_LS_GS 			= 0x04,								--登录在线，游戏在线
	US_LS_GS_OFFLINE 	= 0x05,								--登录在线，游戏掉线
}

local FREESCORE = {
	limit = 1000,	--能够领取免费金币的条件<limit
	gold = 10000,	--每次领取获得的金币
	num = 1, 		--非vip可领次数
	vipNum = 3, 	-- vip可领次数
}

local USER_TYPE = {
	NARMAL 			= 0x00,			--普通账号
	NATIVE 			= 0x01,			--游客账号
	PHONE 			= 0x80,			--手机账号
}

local RESCUE_COIN_MAX_NUM		= 3 --每天领取救济金次数

return {
	SESSION_CONTROL = SESSION_CONTROL,
	LOGIN_CONTROL = LOGIN_CONTROL,
	USER_STATUS = USER_STATUS,
	FREESCORE = FREESCORE,
	USER_TYPE = USER_TYPE,
	RESCUE_COIN_MAX_NUM = RESCUE_COIN_MAX_NUM,
}