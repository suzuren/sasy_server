local skynet = require "skynet"
require "skynet.manager"
local cluster = require "cluster"
local sysConfig = require "sysConfig"
local xLog = require "xLog"
local inspect = require "inspect"

skynet.start(function()
	if sysConfig.isTest then
		skynet.name(".xLogService", skynet.uniqueservice("xLogService"))
		xLog("log success")
    end

    skynet.uniqueservice("eventDispatcher")
    skynet.uniqueservice("mysqlConnectionPool")
	local mysqlConnectionTestAddress = skynet.uniqueservice("mysqlConnectionTest")
	local timeConfig = skynet.call(mysqlConnectionTestAddress,"lua","GetHuoDongTimeInfo")
	--skynet.error(string.format("%s skynet.start func - timeConfig\n",SERVICE_NAME),inspect(timeConfig))


    local resManager = skynet.uniqueservice("resourceManager")
    skynet.call(resManager, "lua", "initialize", "pbParser", "loginServer", tonumber(skynet.getenv("resManager_pbParserPoolSize")))
    --skynet.call(resManager, "lua", "initialize", "sensitiveWordFilter", tonumber(skynet.getenv("resManager_wordFilterPoolSize")))
	skynet.uniqueservice("simpleProtocalBuffer")
    skynet.uniqueservice("LS_httpWorkerPool")

    cluster.register("LS_model_serverManager", skynet.uniqueservice("LS_model_serverManager"))
    cluster.register("LS_model_sessionManager", skynet.uniqueservice("LS_model_sessionManager"))
    cluster.register("LS_model_GSProxy", skynet.uniqueservice("LS_model_GSProxy"))

    
    skynet.uniqueservice("LS_model_item_config")
	--[[
	skynet.uniqueservice("LS_model_message")
	skynet.uniqueservice("LS_model_ranking")
	skynet.uniqueservice("LS_model_pay")
	skynet.uniqueservice("LS_model_signin")
	skynet.uniqueservice("LS_model_rescueCoin")
	skynet.uniqueservice("LS_model_bag")
    skynet.uniqueservice("LS_model_chat")
    ]]
    skynet.uniqueservice("LS_model_telnet")
    --[[
	skynet.uniqueservice("LS_model_gunUplevel")
	]]
	cluster.register("LS_model_huoDong", skynet.uniqueservice("LS_model_huoDong"))	
	cluster.register("LS_model_worldBoss", skynet.uniqueservice("LS_model_worldBoss"))
	--[[
	skynet.uniqueservice("LS_model_invitation")
    skynet.uniqueservice("LS_model_gm")
    ]]


    skynet.uniqueservice("LS_controller_login")
    --[[
    skynet.uniqueservice("LS_controller_message")
	skynet.uniqueservice("LS_controller_ranking")
	skynet.uniqueservice("LS_controller_server")
	skynet.uniqueservice("LS_controller_pay")
	skynet.uniqueservice("LS_controller_signin")
	skynet.uniqueservice("LS_controller_rescueCoin")
	skynet.uniqueservice("LS_controller_bag")
	skynet.uniqueservice("LS_controller_chat")
	skynet.uniqueservice("LS_controller_account")
	skynet.uniqueservice("LS_controller_bank")
	skynet.uniqueservice("LS_controller_ping")
	skynet.uniqueservice("LS_controller_gunUplevel")
	skynet.uniqueservice("LS_controller_huoDong")
	skynet.uniqueservice("LS_model_operatorLimit")
	skynet.uniqueservice("LS_controller_worldBoss")
	skynet.uniqueservice("LS_controller_invitation")
    ]]

    skynet.uniqueservice("LS_webController_uniformPlatform")
    skynet.uniqueservice("LS_webController_interface")
    
    skynet.uniqueservice("LS_telnetServer", tonumber(skynet.getenv("telnetPort")))
	
    local tcpGateway = skynet.uniqueservice("tcpGateway")
	skynet.call(tcpGateway, "lua", "initialize", "loginServer", sysConfig.isTest)

	local opts ={address = skynet.getenv("address"),port = tonumber(skynet.getenv("port")),nodelay = true,}
	skynet.call(tcpGateway, "lua", "open" , opts)	
    cluster.open "loginServer"
    
	skynet.exit()
end)
