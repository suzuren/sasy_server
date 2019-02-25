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
    local resManager = skynet.uniqueservice("resourceManager")
	skynet.call(resManager, "lua", "initialize", "pbParser", "loginServer", tonumber(skynet.getenv("resManager_pbParserPoolSize")))
	skynet.uniqueservice("simpleProtocalBuffer")
    skynet.uniqueservice("LS_httpWorkerPool")

    cluster.register("LS_model_serverManager", skynet.uniqueservice("LS_model_serverManager"))
    cluster.register("LS_model_sessionManager", skynet.uniqueservice("LS_model_sessionManager"))
    
    skynet.uniqueservice("LS_model_telnet")

    --skynet.uniqueservice("LS_model_pay")
    
    skynet.uniqueservice("LS_webController_uniformPlatform")
    skynet.uniqueservice("LS_webController_interface")
    

    skynet.uniqueservice("LS_telnetServer", tonumber(skynet.getenv("telnetPort")))

    --local tempTable = {1,2,3,4,5,6,7,8,9}
    --xLog(inspect(tempTable))
    
	skynet.exit()
end)
