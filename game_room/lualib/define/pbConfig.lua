--机器人专用协议不需要配置到这里
local _data = {
	common = {
		s2c = {
			[0xff0000] = "common.misc.s2c.SystemMessage",
		},
		c2s = {},
		files = {
			"common.misc.s2c.pb",
		},		
	},
	loginServer = {
		s2c = {
			[0x000000] = "loginServer.heartBeat.s2c.HeartBeat",
			[0x000100] = "loginServer.login.s2c.Login",
			[0x000101] = "loginServer.login.s2c.Logout",
		},
		c2s = {
			[0x000000] = "loginServer.heartBeat.c2s.HeartBeat",
			[0x000100] = "loginServer.login.c2s.Login",
		},
		files = {
			"loginServer.heartBeat.c2s.pb",
			"loginServer.heartBeat.s2c.pb",
			"loginServer.login.c2s.pb",
			"loginServer.login.s2c.pb",
		},
	},
}

local function mergeConfig(...)
	local config = {
		s2c = {},
		c2s = {},
		files = {},
	}
	
	for _, sectionName in ipairs{...} do
		local c = _data[sectionName]
		if c then
			for k, v in pairs(c.s2c) do
				config.s2c[k] = v
			end
			
			for k, v in pairs(c.c2s) do
				config.c2s[k] = v
			end
			
			for _, v in ipairs(c.files) do
				table.insert(config.files, v)
			end
		end
	end
	
	return config
end

local function getConfig(type)
	if type=="loginServer" then
		return mergeConfig("loginServer", "common")
	elseif type=="fish" then
		return mergeConfig("gameServer", "fish", "common")
	else
		error(string.format("invalid type \"%s\"", type), 2)
	end
end

return {
	getConfig = getConfig,
}
