local skynet = require "skynet"
local cluster = require "cluster"
require "skynet.manager"
local sysConfig = require "sysConfig"
local xLog = require "xLog"

skynet.start(function()
	if sysConfig.isTest then
		skynet.name(".xLogService", skynet.uniqueservice("xLogService"))
		xLog("log success")
	end
	local gameName = skynet.getenv("gameName")

	skynet.uniqueservice("resourceManager")
	skynet.uniqueservice("eventDispatcher")
	--skynet.uniqueservice("mysqlConnectionPool")
	local resManager = skynet.uniqueservice("resourceManager")
	skynet.call(resManager, "lua", "initialize", "pbParser", gameName, tonumber(skynet.getenv("resManager_pbParserPoolSize")))
	--skynet.call(resManager, "lua", "initialize", "sensitiveWordFilter", tonumber(skynet.getenv("resManager_wordFilterPoolSize")))
	skynet.uniqueservice("simpleProtocalBuffer")
	
	-- models
	skynet.uniqueservice("GS_model_LSPuller")
	local serverStatus = skynet.uniqueservice("GS_model_serverStatus")
	skynet.call(serverStatus, "lua", "start", tonumber(skynet.getenv("serverID")))
	local serverConfig = skynet.call(serverStatus, "lua", "getServerData")
	
	if serverConfig.telnetPort~=0 then
		skynet.uniqueservice("telnetServer", serverConfig.TelnetPort)
	end
	
	--[[
	skynet.uniqueservice("GS_model_item_config")
	skynet.uniqueservice("GS_model_property")
	skynet.uniqueservice("GS_model_attemperEngine")
	skynet.uniqueservice("GS_model_userManager")
	skynet.uniqueservice("GS_model_tableManager")
	
	local androidManager = skynet.uniqueservice("GS_model_androidManager")
	skynet.send(androidManager, "lua", "start")

	skynet.uniqueservice("GS_model_task")
	skynet.uniqueservice("GS_model_bag")
	skynet.uniqueservice("GS_model_protect")
	skynet.uniqueservice("GS_model_reward_gold_fish")
	skynet.uniqueservice("GS_model_gunUplevel")
	skynet.uniqueservice("GS_model_operatorLimit")
	skynet.uniqueservice("GS_model_huoDong")
	skynet.uniqueservice("GS_model_invalidGun")
	skynet.uniqueservice("GS_model_worldBoss")
	-- controllers
	skynet.uniqueservice("GS_controller_login")
	skynet.uniqueservice("GS_controller_table")
	skynet.uniqueservice("GS_controller_property")
	skynet.uniqueservice("GS_controller_chat")
	skynet.uniqueservice("GS_controller_ping")
	skynet.uniqueservice("GS_controller_bank")
	skynet.uniqueservice(string.format("%s_controller", game))

	skynet.uniqueservice("GS_controller_task")
	skynet.uniqueservice("GS_controller_bag")
	skynet.uniqueservice("GS_controller_reward_gold_fish")
	skynet.uniqueservice("GS_controller_gunUplevel")
	skynet.uniqueservice("GS_model_hd_dropBox")
	skynet.uniqueservice("GS_controller_huoDong")
	skynet.uniqueservice("GS_controller_worldBoss")
	]]

	local tcpGateway = skynet.uniqueservice("tcpGateway")
	skynet.call(tcpGateway, "lua", "initialize", game, sysConfig.isTest)
	skynet.call(tcpGateway, "lua", "open" , {
		-- address = serverConfig.ServerAddr,
		address = '0.0.0.0',
		port = serverConfig.ServerPort,
		nodelay = true,
	})

	skynet.exit()
end)



