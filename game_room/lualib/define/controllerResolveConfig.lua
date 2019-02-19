local data = {
	loginServer = {
		[0x000100] = "LS_controller_login",
		[0x000200] = "LS_controller_server",
		[0x000300] = "LS_controller_message",
		[0x000400] = "LS_controller_ranking",
		[0x000500] = "LS_controller_pay",
		[0x000600] = "LS_controller_account",
		[0x000700] = "LS_controller_bank",
		[0x000800] = "LS_controller_ping",
		[0x001000] = "LS_controller_signin",
		[0x002000] = "LS_controller_rescueCoin",
		[0x003000] = "LS_controller_bag",
		[0x004000] = "LS_controller_chat",
		[0x005000] = "LS_controller_gunUplevel",
		[0x006000] = "LS_controller_huoDong",
		[0x007000] = "LS_controller_worldBoss",
		[0x008000] = "LS_controller_invitation",
	},
	gameServer = {
		[0x010100] = "GS_controller_login",
		[0x010200] = "GS_controller_table",
		[0x010300] = "GS_controller_property",
		[0x010400] = "GS_controller_chat",
		[0x010500] = "GS_controller_ping",
		[0x010700] = "GS_controller_bank",
		[0x010800] = "GS_controller_task",
		[0x010900] = "GS_controller_bag",
		[0x011000] = "GS_controller_reward_gold_fish",
		[0x012000] = "GS_controller_gunUplevel",
		[0x013000] = "GS_controller_huoDong",
		[0x014000] = "GS_controller_worldBoss",
	},
	web = {
		["uniformpay"] = "LS_webController_uniformPlatform",
		["uniformother"] = "LS_webController_uniformPlatform",
		["interface"] = "LS_webController_interface",
		["GetServerListStatus"] = "LS_webController_interface",
	},
	fish = {
		[0x020000] = "fish_controller",
	},
	plane = {
		[0x040000] = "plane_controller",
	},
	zhajinhua = {
		[0x050000] = "zhajinhua_controller",
	},
	doudizhu = {
		[0x051000] = "doudizhu_controller",
	},
	niuniubattle = {
		[0x054100] = "niuniubattle_controller",
	},
	flyBirdRunMonster = {
		[0x055100] = "flyBirdRunMonster_controller",
	},
}

local function getConfig(type)
	local c = data[type]
	if c then
		return data[type]
	else
		error(string.format("controller resolve config not found for \"%s\"", tostring(type)), 2)
	end
end

return {
	getConfig = getConfig,
}
