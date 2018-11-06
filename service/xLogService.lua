local skynet = require "skynet"

local CMD = {}
local fd = 0
local logPath
local logLevel
local logDate = os.date("%Y%m%d", os.time())

-- 日志级别
local level = {
	["DEBUG"] = 1,
	["INFO"] = 2,
	["WARN"] = 3,
	["ERROR"] = 4,
	["FATAL"] = 5,
	["NON"] = 6
}

function CMD.logOpen()
	logPath = skynet.getenv("logPath")
	logLevel = skynet.getenv("logLevel")
	if logPath == nil then
		return
	end
	if logLevel == nil then
		logLevel = "DEBUG"
	end
	os.execute("mkdir -p " .. logPath)
	
	fd = io.open(logPath .. "/temp.log", "a+")
	if fd == nil then
		print("can't open log file[".. logPath .. "/temp.log]")
	end
end

function CMD.xLog(lev, logStr)
	if logPath == nil then
		return
	end
	if tonumber(os.date("%Y%m%d")) > tonumber(logDate) then
		fd:close()
		os.execute("mv " .. logPath .. "/temp.log " ..logPath.."/"..logDate..".log")
		logDate = os.date("%Y%m%d")
		fd = io.open(logPath .. "/temp.log", "w+")
	end
	local tempDate = os.date("%Y%m%d %H:%M:%S")
	if fd ~= nil and fd ~= 0 then
		if level[lev] >= level[logLevel] then
			fd:write("["..tempDate .. "][".. lev .. "]" .. logStr .. "\n")
			fd:flush()
  			--skynet.error("["..tempDate .. "][".. lev .. "]" .. logStr)
		end
	end
end

function CMD.logClose()
	if fd ~= nil and fd ~= 0 then
		fd:close()
	end
end

skynet.start(function()
	CMD.logOpen()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], string.format("%s: handler not found for \"%s\"", SERVICE_NAME, cmd))
		f(...)
	end)
end)
