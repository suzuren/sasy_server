root_dir = "."

thread = 4
logger = "./program_log/loginserver.log"
daemon = "./program_log/loginserver.pid"
harbor = 0
start = "mainLoginServer"
bootstrap = "snlua bootstrap"

cluster = root_dir.."/config/clustername.lua"
pbs_dir = root_dir.."/pbs"
lualoader = root_dir.."/skynet/lualib/loader.lua"
cpath =  root_dir.."/cservice/?.so;"..root_dir.."/skynet/cservice/?.so"
lua_cpath = root_dir.."/luaclib-src/?.so;"..root_dir.."/skynet/luaclib/?.so"
luaservice = root_dir.."/service/loginServer/?.lua;"..root_dir.."/skynet/service/?.lua;"..root_dir.."/service/?.lua;"..root_dir.."/lualib/?.lua;"..root_dir.."/skynet/lualib/http/?.lua;"
lua_path = root_dir.."/lualib/?.lua;"..root_dir.."/skynet/lualib/?.lua;"..root_dir.."/service/?.lua;"..root_dir.."/skynet/lualib/skynet/?.lua;"..root_dir.."/skynet/lualib/http/?.lua;"..root_dir.."/config/?.lua;"

resManager_pbParserPoolSize = 3
resManager_wordFilterPoolSize = 1

tcpGatewayTimeoutThreshold = 12
tcpGatewayTimeoutCheckInterval = 5

port = 3001
address = "0.0.0.0"

httpPort = 3002
httpAddress = "0.0.0.0"
httpWorkerPoolSize = 3
httpInterfaceAllowIPList = "192.168.0.1,127.0.0.1"

uniformApp = "580dd5a8fd59427bbecc8601e58a72da:355;"
uniformPlatformServerKey = "355:954:9FY35ZC8Z2ETUZ8ITCAOEDOHCW95PTT2;1001:1:asdfgh;"

mysqlPoolSize = 3
mysqlConnectionTimeOut = 14400

sessionLifeTime = 21600				-- six hours
sessionCheckInterval = 600			-- 10 minutes

serverManagerTickerStep = 1000				-- 10 seconds
serverManagerTimerInterval = 1				-- 30 seconds
serverManagerTimeoutThreshold = 20			-- 40 seconds

telnetPort = 3003

logPath = "./logs"
logLevel = "DEBUG"
