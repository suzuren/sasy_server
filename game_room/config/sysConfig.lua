local defenseList = {
	isOpen = 0,--0表示关闭，不启用
	vipList = {
		{RMB=488,ipAddr=""},
		{RMB=12,ipAddr=""},
	},

	normalList = {
		{Gold=100000,Sign=3,RescueCoin=6,RMB=1,ipAddr=""},--(Gold and Sign and RescueCoin) or RMB
	},

	dubiousList = {
		{StartUserId=1,EndUserId=6406,ipAddr=""},
	},

	newList = {
		{Sign=5,RescueCoin=6,ipAddr=""},
		{Sign=0,RescueCoin=3,ipAddr=""},
		{Sign=0,RescueCoin=0,ipAddr=""},
	},
}
--[[
local mysqlInfo = {
	mysqlHost = "127.0.0.1",
	mysqlUser = "root",
	mysqlPassword = "game123456",
	mysqlDataBase = "ssaccountsdb",
}
]]

local mysqlInfo = {
	mysqlHost = "127.0.0.1",
	mysqlUser = "root",
	mysqlPassword = "game123456",
	mysqlDataBase = "ssaccountsdb",
}

local applePay = {
	["ths_hall_12"] = 2,
	["ths_hall_50"] = 3,
	["ths_hall_012"] = 22,
	["ths_hall_98"] = 4,
	["ths_hall_298"] = 5,
	["ths_hall_488"] = 6,
	["ths_hall_0050"] = 23,
	["ths_hall_098"] = 24,
	["ths_hall_0298"] = 25,
	["ths_hall_0488"] = 26,
	["ths_hall_6"] = 1,
	["ths_hall_30"] = 21,
}

return {
	applePay = applePay,
	defenseList = defenseList,
	mysqlInfo = mysqlInfo,
	httpInterfaceAllowIPList = "",
	uniformPlatformServerKey = "",

	isTest = true,
}
