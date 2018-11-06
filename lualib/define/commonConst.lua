local GS_LOGIN_CODE = {
	GLC_SUCCESS = 0,
	GLC_INVALID_SESSION = 1,
	GLC_LS_LOGIN_FIRST = 2,
	GLC_RETRY = 3,
}

local RELAY_MESSAGE_TYPE = {
	RMT_SYSTEM_MESSAGE = 0x20000000,
	RMT_BIG_TRUMPET = 0x20000001,
	RMT_MATCH_SIGNUP = 0x20000002, -- 比赛报名
	RMT_MATCH_CANCLE_SIGNUP = 0x20000003, -- 取消比赛
}

local LSNOTIFY_EVENT = {
	EVT_LSNOTIFY_USER_LOGIN_OTHER_SERVER 	= 0x10000000,
	EVT_LSNOTIFY_PAY_ORDER_CONFIRM 			= 0x10000001,
	EVT_LSNOTIFY_USER_BANK 					= 0x10000002,
	EVT_LSNOTIFY_USER_RESCUECOIN 			= 0x10000003,	--领取救济金通知房间
	EVT_LSNOTIFY_WORLD_BOSS_START_OR_END 	= 0x10000004, 	--世界boss开始或者结束
	EVT_LSNOTIFY_GS_CHANGE_USER_ITEM		= 0x10000005,	--通知游戏里改变玩家道具信息
	EVT_LSNOTIFY_GS_CHANGE_USER_NAME		= 0x10000006,
	EVT_LSNOTIFY_GS_NEW_ANDROID_LOGIN		= 0x10000007,	--通知游戏有新的机器人要进入游戏
}


local SYSTEM_MESSAGE_TYPE = {
	--类型掩码
	SMT_CHAT 				= 0x0001,				--聊天消息
	SMT_EJECT 				= 0x0002,				--弹出消息
	SMT_GLOBAL 				= 0x0004,				--全局消息
	SMT_PROMPT 				= 0x0008,				--提示消息
	SMT_TABLE_ROLL 			= 0x0010,				--滚动消息
	SMT_SEND_JIUJI 			= 0x0020,				--发送救济消息
	SMT_SEND_TITLE 			= 0x0030,				--发送称号消息
	
	--控制掩码
	SMT_CLOSE_ROOM 			= 0x0100,				--关闭房间
	SMT_CLOSE_GAME 			= 0x0200,				--关闭游戏
	SMT_CLOSE_LINK 			= 0x0400,				--中断连接
}

local DB_STATUS_MASK = {
	DSM_NULLITY						= 0x01,
	DSM_STUNDOWN					= 0x02,
	DSM_ISANDROID					= 0x04,
	DSM_MOORMACHINE					= 0x08,
	DSM_NOTFREESCORE				= 0x10,
}

local RELAY_MESSAG_MASK = 0x20000000
local LSNOTIFY_EVENT_MASK = 0x10000000

local MONEY_EXCHANGE = {
	NORMAL = {
		SCORE_PER_PRESENT = 10,
	},
	EDUCATE = {
		SCORE_PER_PRESENT = 0.1,
	},
}

local PRESENT_SCORE = 1000 --礼券换金币


--服务器是否是炸金花
local function IsThisJinHuaServer( kindId )
	return kindId == 6
end

local function CheckIsNiuniuServer( kindId )
	return kindId == 104 or kindId == 800
end

local ITEM_ID ={
	ITEM_ID_GOLD				= 1001,		--金币
	ITEM_ID_JEWEL				= 1002,		--砖石
	ITEM_ID_FISH				= 1003,		--话费券
	ITEM_ID_LOCK				= 1004,		--锁定
	ITEM_ID_FAST				= 1005,		--狂暴
	ITEM_ID_SILVE_KEY			= 1006,		--银色钥匙
	ITEM_ID_GOLD_KEY			= 1007,		--金色钥匙
	ITEM_ID_MOON_KEY			= 1008,		--月牙钥匙
	ITEM_ID_SILVE_BOX			= 1009,		--银宝箱
	ITEM_ID_GOLD_BOX			= 1010,		--金宝箱
	ITEM_ID_PT_BOX				= 1011,		--铂金宝箱
	ITEM_ID_CANG_BAO_TU_1		= 1012,		--藏宝图上
	ITEM_ID_CANG_BAO_TU_2		= 1013,		--藏宝图下
	ITEM_ID_PAO_TAI_1			= 1014,		--炮台
	ITEM_ID_PAO_TAI_2			= 1016,		--炮台
	ITEM_ID_BAG_1				= 1017,		--遗失的袋子
	ITEM_ID_BAG_2				= 1018,		--装满金币的箱子
	ITEM_ID_BAG_3				= 1019,		--船长的宝藏
	ITEM_ID_COMPOSE_CARD_1		= 1020,		--砖石合成卡
	ITEM_ID_COMPOSE_CARD_2		= 1021,		--至尊合成卡
	ITEM_ID_DIAMOND_BOX			= 1022,		--砖石宝箱
	ITEM_ID_MAX_BOX				= 1023,		--至尊宝箱
	ITEM_ID_RED_PACKET_1		= 1024,		--66万红包
	ITEM_ID_RED_PACKET_2		= 1025,		--88万红包
	ITEM_ID_RED_PACKET_3		= 1026,		--5万红包
	ITEM_ID_SPEC_CANNON_1		= 1027,		--特殊炮台 寒冰炮台
	ITEM_ID_SPEC_CANNON_2		= 1028,		--特殊炮台 火焰炮台
	ITEM_ID_FIRE_PIECE			= 1029,		--火焰炮台掉落专属道具 火焰微粒
	ITEM_ID_FIRE_CRYSTAL		= 1030,		--火焰微粒合成 火焰结晶
	ITEM_ID_NEW_FAST			= 1031,		--新增的急速射击道具
	ITEM_ID_WORD_HUAN			= 1201,		--欢
	ITEM_ID_WORD_DU				= 1202,		--度
	ITEM_ID_WORD_GUO			= 1203,		--国
	ITEM_ID_WORD_QING			= 1204,		--庆
	ITEM_ID_WORD_JIE			= 1205,		--节
	ITEM_ID_RMB					= 1208,		--RMB
	ITEM_ID_WORD_JING			= 1211,		--惊
	ITEM_ID_WORD_HU				= 1212,		--魂
	ITEM_ID_WORD_WAN			= 1213,		--万
	ITEM_ID_WORD_SHENG			= 1214,		--圣
	ITEM_ID_WORD_JIE_2			= 1215,		--节
	ITEM_ID_SHEN_DEGN			= 1218,		--神灯
	ITEM_ID_WORD_HUAN_1			= 1221,		--欢
	ITEM_ID_WORD_DU_1			= 1222,		--度
	ITEM_ID_WORD_SHENG_1		= 1223,		--圣
	ITEM_ID_WORD_DAN			= 1224,		--诞
	ITEM_ID_WORD_JIE_1			= 1225,		--节
	ITEM_ID_WORD_LANG			= 1228,		--浪
	ITEM_ID_WORD_MAN			= 1229,		--漫
	ITEM_ID_WORD_QING_1			= 1230,		--情
	ITEM_ID_WORD_REN			= 1231,		--人
	ITEM_ID_WORD_JIE_3			= 1232,		--节
}

local EX_VIP_PAO_TAI_TIME 		= 10*60	  	  --VIP体验炮台时间
local PAO_TAI_USE_TIME			= 24*60*60*3  --一个炮台使用三天时间
local SPEC_CANNON_TIME			= 24*60*60    --特殊炮台每次增加一天时间
-- local SPEC_CANNON_TIME			= 30   --特殊炮台每次增加一天时间
local MONTH_CARD_TIME			= 24*60*60*30 --月卡时间
local TIME_CARD_USE_TIME		= 6*60*60     --合成卡时间	
local FIRECRYSTAL_CD_TIME		= 3*60*60	  --火焰结晶3小时的合成CD时间

local OPERATOR_LIMIT = {
	OP_LIMIT_ID_1				= 1,		--第一次打掉20号鱼,必掉宝图1号
	OP_LIMIT_ID_2				= 2,		--第一次打掉27号鱼,必掉宝图2号
	OP_LIMIT_ID_3				= 3,		--第一次打掉28号鱼,必掉宝图2号
	OP_LIMIT_ID_4				= 4,		--新手救济金保护--0-12号鱼
	OP_LIMIT_ID_CHANGE_NAME		= 5,		--第一次改名字免费
	OP_LIMIT_ID_BOX_DROP_VALUE	= 6,		--BOSS掉落的宝箱价值
	OP_LIMTI_ID_KILL_BOSS_1		= 7,		--新手场击杀boss
	OP_LIMTI_ID_KILL_BOSS_2		= 8,		--千炮场击杀boss 
	OP_LIMTI_ID_KILL_BOSS_3		= 9,		--万炮场击杀boss 
	OP_LIMTI_ID_HD_KILL_BOSS_1	= 10,		--新手场活动击杀boss
	OP_LIMIT_ID_FIST_TIME_KB_1 	= 11,		--新手场第一次杀boss,用类型7老玩家概率变低了
	OP_LIMTI_ID_GUO_QING_1		= 12,		--国庆活动奖励
	OP_LIMTI_ID_GUO_QING_2		= 13,		--国庆活动奖励
	OP_LIMTI_ID_DOUBLE_GOLD		= 14,		--活动期间每日充值翻倍
	OP_LIMTI_ID_KB_WSJ_1		= 15,		--万圣节新手场击杀boss
	OP_LIMTI_ID_KB_WSJ_2		= 16,		--万圣节千炮场击杀boss
	OP_LIMTI_ID_KB_WSJ_3		= 17,		--万圣节万炮场击杀boss
	OP_LIMTI_ID_KB_WSJ_COUNT	= 18,		--万圣节击杀boss统计
	OP_LIMIT_ID_5				= 19,		--新手救济金保护--13-17号鱼
	OP_LIMIT_ID_FIRST_CHARGE	= 20,		--首冲保护
	OP_LIMIT_ID_VERSION_FALG	= 21,		--更新版本标示
	OP_LIMTI_ID_KB_SDJ_1		= 24,		--圣诞节新手场击杀boss
	OP_LIMTI_ID_KB_SDJ_2		= 25,		--圣诞节千炮场击杀boss
	OP_LIMTI_ID_KB_SDJ_3		= 26,		--圣诞节万炮场击杀boss
	OP_LIMTI_ID_KB_SDJ_COUNT	= 27,		--圣诞节击杀boss统计
	OP_LIMTI_ID_KILL_WORLD_BOSS	= 28,		--击杀世界boss数量统计
	OP_LIMTI_ID_KILL_TIME_BOSS	= 29,		--击杀定时boss数量统计
	OP_LIMTI_ID_ONLINE_TIME		= 30,		--累计在线时间--秒
	OP_LIMTI_ID_PAY_RMB			= 31,		--充值rmb
	OP_LIMTI_ID_LOGIN_1			= 32,		--登入有礼1
	OP_LIMTI_ID_LOGIN_2			= 33,		--登入有礼2
	OP_LIMTI_ID_CHARGE_PERDAY	= 34,		--每日首冲抽奖充值标示
	OP_LIMIT_ID_REWARD_ID 		= 35,		--每日首冲抽奖抽到的奖励id
	OP_LIMIT_ID_KILL_RED_PACKET = 36,		--第一次击杀小红包鱼
	OP_LIMTI_ID_KT_BOSS_TODAY 	= 37,		--当日击杀boss数量
	OP_LIMTI_ID_PAY_RMB_NEW		= 38,		--充值rmb,定时boss使用--31作废
	OP_LIMTI_ID_PAY_RMB_NEW_1   = 39,		--充值rmb,世界boss使用
	OP_LIMTI_ID_KB_QRJ_1		= 40,		--圣诞节新手场击杀boss
	OP_LIMTI_ID_KB_QRJ_2		= 41,		--圣诞节千炮场击杀boss
	OP_LIMTI_ID_KB_QRJ_3		= 42,		--圣诞节万炮场击杀boss
	OP_LIMTI_ID_KB_QRJ_COUNT	= 43,		--圣诞节击杀boss统计
	OP_LIMIT_ID_SEND_TITLE		= 44,		--称号提示
	OP_LIMIT_ID_EXPERIENCE_VIP3 = 45,		--vip体验炮台3
	OP_LIMIT_ID_EXPERIENCE_VIP4 = 46,		--vip体验炮台4
	OP_LIMIT_ID_EXPERIENCE_VIP6 = 47,		--vip体验炮台6 
	OP_LIMIT_ID_EXPERIENCE_VIP 	= 48,		--vip体验炮台--记录时间
	OP_LIMIT_ID_PAO_TAI_LV		= 49,		--当前使用的炮台等级
	OP_LIMIT_ID_FIRE_PIECE		= 50,		--火焰微粒掉落池
	OP_LIMIT_ID_FIRECRYSTAL_CD	= 51,		--合成火焰结晶CD
	OP_LIMIT_ID_SPEC_CANNON		= 52,		--当前能够购买的火炮礼包类型 0-寒冰 1-火焰

}

local ITEM_SYSTEM_TYPE = {
	BY_USE				= 1,	--使用
	BY_GIVE				= 2,	--赠送
	BY_COMPOSE			= 3,	--合成
	REWARD_GOLD_FISH	= 4,  	--奖金鱼抽奖
	GUN_UP_LEVEL		= 5,	--炮台升级
	EXCHANGE 			= 6,	--兑换
	PAY_ADD				= 7,	--充值
	SIGN_IN				= 8,	--签到
	RESCUE_COIN 		= 9,	--救济金
	BUG_GOODS			= 10,	--购买物品
	BY_EUQIP			= 11,	--装备
	USE_CHANGE_NAME		= 12,	--改名字消耗
	MESSAGE_BOARD		= 13,	--留言板消耗
	EMAIL_REWARD		= 14,	--领取系统邮件
	GET_FREE_SCORE		= 15,	--领取免费金币
	GET_VIP_SCORE		= 16,	--领取vip免费金币
	BY_CHANG_SCORE_API	= 17,	--统一平台过来改变物品信息
	BY_FISH				= 18,	--捕鱼获得
	BY_TASK				= 19,	--完成任务
	BY_NIUNIUBATTLE		= 20,	--百人牛牛
	BY_ANDROID			= 21,	--机器人改变金币
	BY_DROP_BOX			= 22,	--宝箱价值掉落
	BY_HUO_DONG			= 23,	--扑鱼活动获得
	BY_HUO_DONG_REWARD	= 24,	--活动奖励
	EMAIL_REWARD_USER	= 25,	--领取玩家邮件
	BY_FLY_BIRD_R_M		= 26,	--飞禽走兽
	BY_CHANGE_GOLD		= 1000,	--外部改变金币的时候,玩家身上有多少钱
	BY_FROM_LS			= 1001,	--断线的时候,玩家回到大厅改变了物品信息通知游戏服改变,游戏里不用记录,大厅记录了
}

local HUO_DONG_TIME = {
	START_TIME	= 20160930160000,	--年月日时分秒
	END_TIME	= 20161008000000,
}

local HUO_DONG_TYPE	= {
	HD_GUO_QING			= 1,		--国庆活动
	HD_CHARGE_1			= 2,		--单笔充值活动
	HD_VERSION			= 3,		--版本更新介绍
	HD_EVERYDAY_CHARGE  = 4,		--日累计充值活动
	HD_WAN_SHENG_JIE	= 5,		--万圣节
	HD_SUM_CHARGE  		= 6,		--累计充值
	HD_WORLD_BOSS 		= 7,		--世界BOSS
	HD_DOUBLE_GOLD		= 8,		--每日首充翻倍
	HD_KUANG_KUAN_JIE	= 9,		--捕鱼狂欢节
	HD_TIME_BOSS		= 10,		--定时BOSS
	HD_SHEN_DAN_JIE		= 11,		--欢度圣诞节，集字迎豪礼
	HD_ACTIVITY_BOSS	= 12,		--活动Boss
	HD_LOGIN 			= 13,		--登入有礼
	HD_RED_PACKET 		= 14,		--红包
	HD_CHOU_JIANG 		= 15,		--每日首充的玩家可进行一次抽奖
	HD_RED_PACKET_FISH_SCENE = 16,	--天将红包雨
	HD_VALENTINESDAY	= 17,		--情人节集字
	HD_SPEC_CANNON		= 18,		--神秘炮台
	HD_SPEC_SALE 		= 19,		--超值礼包
}

local HUO_DONG_ID	= {
	HD_ID_WORD						= 1,		--集字
	HD_ID_EVERYDAY_RECHARGE			= 2,		--每日单笔
	HD_ID_EVERYDAY_SUM_RECHARGE		= 3,		--每日累计
	HD_ID_SUM_RECHARGE_IN_HD_TIME	= 4,		--活动期间累计
	HD_ID_VERSION_UPDATE			= 5,		--版本更新介绍
	HD_ID_WORLD_BOSS				= 6,		--世界BOSS
	HD_ID_CHARGE_TO_DOUBLE			= 7,		--首冲翻倍活动
	HD_ID_KUANG_KUAN_JIE			= 8,		--捕鱼狂欢节
	HD_ID_WORLD_TIME_BOSS			= 9,		--定时BOSS
	HD_ID_WORLD_ACTIVITY_BOSS		= 11,		--活动BOSS
	HD_ID_LOGIN						= 12,		--登入有礼
	HD_ID_RED_PACKET				= 13,		--充值乐翻天,拆红包
	HD_ID_CHOU_JINAG				= 14,		--每日充值抽奖
	HD_ID_RED_PACKET_FISH_SCENE		= 15,		--天将红包雨
	HD_ID_RED_PACKET_FISH_SCENE		= 16,		--天将红包雨
	HD_ID_VALENTINESDAY				= 17,		--情人节集字
	HD_ID_SPEC_CANNON				= 18,		--神秘炮台
	HD_ID_SPEC_SALE 				= 19,		--超值礼包
}

local WORLD_BOSS = {
	NEED_SCORE 		= 10000000, --世界boss出现需要的金币
	LIVE_TIME		= 2*60, --世界boss生存时间
	DIFF_TIME		= 15*60,  --隔多长时间刷一下世界boss 
}

local TASK_TYPE = {
	ERERY_DAY	= 1,		--日常任务
	TASK_FISH 	= 2,		--任务鱼
	KILL_BOSS   = 3,		--打boss
}

local TASK_FISH_TIME 	= 300		--任务鱼时间	

local function CheckIsTimeCardItem(itemId)
	if itemId == ITEM_ID.ITEM_ID_COMPOSE_CARD_1 or itemId == ITEM_ID.ITEM_ID_COMPOSE_CARD_2 then
		return true
	end

	return false
end

local function CheckIsPaoTaiItem(itemId)
	if ITEM_ID.ITEM_ID_PAO_TAI_1 <= itemId and itemId <= ITEM_ID.ITEM_ID_PAO_TAI_2 then
		return true
	end

	return false
end

local function CheckIsSpecCannonItem(itemId)
	if ITEM_ID.ITEM_ID_SPEC_CANNON_1 <= itemId and itemId <= ITEM_ID.ITEM_ID_SPEC_CANNON_2 then
		return true
	end

	return false
end

local SPEC_CANNON = {
	CANNON_ICE = 12,
	CANNON_FIRE = 13
}

local function HideNickName(strName)
	local count = string.len(strName)
	if count == 12 then
		local firstWorld = string.sub(strName,0,1)
		local mynumber = tonumber(string.sub(strName,2,12))

		if type(mynumber) == "number" then
			local first = string.sub(strName,2,4)
			local thr = string.sub(strName,9,12)
			strName = firstWorld .. first .. "****" .. thr
		end
	end

	return strName
end

return {
	RELAY_MESSAGE_TYPE 		= RELAY_MESSAGE_TYPE,
	GS_LOGIN_CODE 			= GS_LOGIN_CODE,
	LSNOTIFY_EVENT 			= LSNOTIFY_EVENT,
	SYSTEM_MESSAGE_TYPE 	= SYSTEM_MESSAGE_TYPE,
	RELAY_MESSAG_MASK 		= RELAY_MESSAG_MASK,
	LSNOTIFY_EVENT_MASK 	= LSNOTIFY_EVENT_MASK,
	DB_STATUS_MASK 			= DB_STATUS_MASK,
	MONEY_EXCHANGE 			= MONEY_EXCHANGE,
	PRESENT_SCORE 			= PRESENT_SCORE,
	IsThisJinHuaServer 		= IsThisJinHuaServer,
	CheckIsNiuniuServer     = CheckIsNiuniuServer,
	ITEM_ID 				= ITEM_ID,
	EX_VIP_PAO_TAI_TIME 	= EX_VIP_PAO_TAI_TIME,
	PAO_TAI_USE_TIME 		= PAO_TAI_USE_TIME,
	MONTH_CARD_TIME 		= MONTH_CARD_TIME,
	TIME_CARD_USE_TIME		= TIME_CARD_USE_TIME,
	SPEC_CANNON_TIME        = SPEC_CANNON_TIME,
	FIRECRYSTAL_CD_TIME		= FIRECRYSTAL_CD_TIME,
	OPERATOR_LIMIT 			= OPERATOR_LIMIT,
	ITEM_SYSTEM_TYPE 		= ITEM_SYSTEM_TYPE,
	HUO_DONG_TIME 			= HUO_DONG_TIME,
	HUO_DONG_TYPE			= HUO_DONG_TYPE,
	HUO_DONG_ID				= HUO_DONG_ID,
	WORLD_BOSS 				= WORLD_BOSS,
	TASK_TYPE 				= TASK_TYPE,
	TASK_FISH_TIME			= TASK_FISH_TIME,
	CheckIsTimeCardItem		= CheckIsTimeCardItem,
	CheckIsPaoTaiItem 		= CheckIsPaoTaiItem,
	CheckIsSpecCannonItem	= CheckIsSpecCannonItem,
	HideNickName			= HideNickName,
	SPEC_CANNON 			= SPEC_CANNON,
}

