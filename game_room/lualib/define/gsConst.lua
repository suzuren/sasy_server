local GAME_GENRE = {
	GOLD=0x0001,								--金币类型
	SCORE=0x0002,								--点值类型
	MATCH=0x0004,								--比赛类型
	EDUCATE=0x0008,								--训练类型
	BEANS=0x0010,								--欢乐豆类型
	TRY_FORMAL=0x0020,							--试玩转正

}

local USER_STATUS = {
	US_NULL = 0x00,								--没有状态
	US_FREE = 0x01,								--站立状态
	US_SIT = 0x02,								--坐下状态
	US_READY = 0x03,							--同意状态
	US_LOOKON = 0x04,							--旁观状态
	US_PLAYING = 0x05,							--游戏状态
	US_OFFLINE = 0x06,							--断线状态
}

local SERVER_RULE = {
	SR_FORFEND_GAME_CHAT		= 0x00000001,							--禁止公聊
	SR_FORFEND_ROOM_CHAT		= 0x00000002,							--禁止公聊
	SR_FORFEND_WISPER_CHAT		= 0x00000004,							--禁止私聊
	SR_FORFEND_WISPER_ON_GAME	= 0x00000008,							--禁止私聊

	SR_ALLOW_DYNAMIC_JOIN		= 0x00000010,							--动态加入
	SR_ALLOW_OFFLINE_TRUSTEE	= 0x00000020,							--断线代打
	SR_ALLOW_AVERT_CHEAT_MODE	= 0x00000040,							--隐藏信息

	SR_RECORD_GAME_SCORE		= 0x00000100,							--记录积分
	SR_RECORD_GAME_TRACK		= 0x00000200,							--记录过程
	SR_DYNAMIC_CELL_SCORE		= 0x00000400,							--动态底分
	SR_IMMEDIATE_WRITE_SCORE	= 0x00000800,							--即时写分

	SR_FORFEND_ROOM_ENTER		= 0x00001000,							--禁止进入
	SR_FORFEND_GAME_ENTER		= 0x00002000,							--禁止进入
	SR_FORFEND_GAME_LOOKON		= 0x00004000,							--禁止旁观

	SR_FORFEND_TAKE_IN_ROOM		= 0x00010000,							--禁止取款
	SR_FORFEND_TAKE_IN_GAME		= 0x00020000,							--禁止取款
	SR_FORFEND_SAVE_IN_ROOM		= 0x00040000,							--禁止存钱
	SR_FORFEND_SAVE_IN_GAME		= 0x00080000,							--禁止存款

	SR_FORFEND_GAME_RULE		= 0x00100000,							--禁止配置
	SR_FORFEND_LOCK_TABLE		= 0x00200000,							--禁止锁桌
	SR_ALLOW_ANDROID_ATTEND		= 0x00400000,							--允许陪玩
	SR_ALLOW_ANDROID_SIMULATE	= 0x00800000,							--允许占位
}

local MOBILE_USER_RULE = {
	--视图模式
	VIEW_MODE_ALL = 0x0001,							--全部可视
	VIEW_MODE_PART = 0x0002,						--部分可视

	--信息模式
	VIEW_INFO_LEVEL_1 = 0x0010,						--部分信息
	VIEW_INFO_LEVEL_2 = 0x0020,						--部分信息
	VIEW_INFO_LEVEL_3 = 0x0040,						--部分信息
	VIEW_INFO_LEVEL_4 = 0x0080,						--部分信息

	--其他配置
	RECVICE_GAME_CHAT = 0x0100,						--接收聊天
	RECVICE_ROOM_CHAT = 0x0200,						--接收聊天
	RECVICE_ROOM_WHISPER = 0x0400,					--接收私聊

	--行为标识
	BEHAVIOR_LOGON_NORMAL = 0x0000,					--普通登录
	BEHAVIOR_LOGON_IMMEDIATELY = 0x1000,			--立即登录
}

local START_MODE = {								--开始模式
	ALL_READY = 0x00,								--所有准备
	FULL_READY = 0x01,								--满人开始
	PAIR_READY = 0x02,								--配对开始
	TIME_CONTROL = 0x10,							--时间控制
	MASTER_CONTROL = 0x11,							--管理控制
}

local DISTRIBUTE = {								--分组选项
	ALLOW = 0x01,									--允许分组
	IMMEDIATE = 0x02,								--入座选项
	LAST_TABLE = 0x04,								--同桌选项
	SAME_ADDRESS = 0x08,							--地址选项
}

local GAME_STATUS = {
	FREE = 0x0000,									--空闲状态
	PLAY = 0x0001,									--游戏状态
	WAIT = 0x0002,									--等待状态
}

local GAME_END_REASON = {
	GER_NORMAL					= 0x00,				--常规结束
	GER_DISMISS					= 0x01,				--游戏解散
	GER_USER_LEAVE				= 0x02,				--用户离开
	GER_NETWORK_ERROR			= 0x03,				--网络错误
}

local SCORE_TYPE = {
	ST_NULL						= 0x00,				--无效积分
	ST_WIN						= 0x01,				--胜局积分
	ST_LOSE						= 0x02,				--输局积分
	ST_DRAW						= 0x03,				--和局积分
	ST_FLEE						= 0x04,				--逃局积分
	ST_PRESENT					= 0x10,				--赠送积分
	ST_SERVICE					= 0x11,				--服务积分
}

local TIMER  = {
	TICK_STEP = 100,
	TICKSPAN_ANDROID_INOUT = 5,
	TICKSPAN_DISTRIBUTE_ANDROID = 8,
	TICKSPAN_LOAD_ANDROID_USER = 3600,
	TICKSPAN_TABLE_OFFLINE_WAIT = 60,
}

local ANDROID_TYPE = {
	ANDROID_SIMULATE					= 0x01,			--相互模拟
	ANDROID_PASSIVITY					= 0x02,			--被动陪打
	ANDROID_INITIATIVE					= 0x04,			--主动陪打
}

local MATCH_STATUS = {
	MS_NULL 					= 0x00,					--没有状态
	MS_SIGNUP 					= 0x01,					--报名状态
	MS_MATCHING 				= 0x02,					--比赛状态
	MS_OUT 						= 0x03,					--淘汰状态
}

local LOGIN_CONTROL = {
	RETRY_INTERVAL_TICK = 50,
	RETRY_COUNT = 4,
	TIMEOUT_THRESHOLD_TICK=300,
	TIMEOUT_CHECK_INTERVAL_TICK=100,
}

local USER_RIGHT = {
	UR_CANNOT_PLAY 					= 0x00000001,						--不能进行游戏
	UR_CANNOT_LOOKON 				= 0x00000002,						--不能旁观游戏
	UR_CANNOT_WISPER				= 0x00000004,						--不能发送私聊
	UR_CANNOT_ROOM_CHAT				= 0x00000008,						--不能大厅聊天
	UR_CANNOT_GAME_CHAT				= 0x00000010,						--不能游戏聊天
	UR_CANNOT_BUGLE					= 0x00000020,						--不能发送喇叭
	
	UR_IS_MEMBER					= 0x00000200,						--是否memberOrder>0
	
	UR_IS_RELEVANT					= 0x40000000,						--是否小号
}

local INVALID_USER = 0xffffffff											--无效用户
local INVALID_CHAIR = 0xffff											--无效椅子
local INVALID_TABLE = 0xffff											--无效桌子

local MAX_CHAIR = 1000

local SMALL_TRUMPET_PROPERTY_ID=18
local BIG_TRUMPET_PROPERTY_ID=19

local PET_DAY_MAX_TASK_NUM		= 3 		--新手日常任务每天最多可以的次数
local TAKS_MAX_NUM				= 6        	--新手日常任务总的次数
local VIP_TABLEID_LOW			= 60   		--大于这个数的都是vip座子

return {
	GAME_GENRE = GAME_GENRE,
	USER_STATUS = USER_STATUS,
	SERVER_RULE = SERVER_RULE,
	MOBILE_USER_RULE = MOBILE_USER_RULE,

	
	START_MODE = START_MODE,
	DISTRIBUTE = DISTRIBUTE,
	GAME_STATUS = GAME_STATUS,
	GAME_END_REASON = GAME_END_REASON,
	SCORE_TYPE = SCORE_TYPE,
	TIMER = TIMER,
	ANDROID_TYPE = ANDROID_TYPE,
	MATCH_STATUS = MATCH_STATUS,
	LOGIN_CONTROL = LOGIN_CONTROL,
	USER_RIGHT = USER_RIGHT,

	INVALID_USER = INVALID_USER,
	INVALID_CHAIR = INVALID_CHAIR,
	INVALID_TABLE = INVALID_TABLE,
	
	MAX_CHAIR = MAX_CHAIR,
	
	SMALL_TRUMPET_PROPERTY_ID = SMALL_TRUMPET_PROPERTY_ID,
	BIG_TRUMPET_PROPERTY_ID = BIG_TRUMPET_PROPERTY_ID,	

	PET_DAY_MAX_TASK_NUM = PET_DAY_MAX_TASK_NUM,
	TAKS_MAX_NUM = TAKS_MAX_NUM,
	VIP_TABLEID_LOW = VIP_TABLEID_LOW,
}


