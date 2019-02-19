local skynet = require "skynet"
local xpcallUtility = require "utility.xpcall"
local ServerUserItem = require "sui"

local _conf

local function cmd_request(tcpAgent, protocalNo, protocalObj, connectionIdentity)
	local handler = _conf.protocalHandlers[protocalNo]
	if not handler then
		skynet.error(string.format("%s: 找不到协议处理函数 protocalNo=0x%06X", SERVICE_NAME, protocalNo))
		return false
	end
	
	if _conf.loginCheck then
		if not connectionIdentity.sui then
			skynet.error(string.format("%s: loginCheck检测失败, protocalNo=0x%06X，没有sui", SERVICE_NAME, protocalNo))
			return false
		end
	end	

	-- ret格式：{protoNo=..., protoObj=...}如果返回是protocbuf协议号和协议对象; {str=...}如果返回是lua string
	local isOK, responseNo, responseObj = xpcall(handler, xpcallUtility.errorMessageSaver, tcpAgent, protocalObj, connectionIdentity)
	--local isOK, responseNo, responseObj = pcall(handler, tcpAgent, protocalObj, connectionIdentity)
	if not isOK then
		skynet.error(string.format("%s: 执行错误 protocalNo=0x%06X: %s", SERVICE_NAME, protocalNo, xpcallUtility.getErrorMessage()))
		return false
	end
	
	return true, responseNo, responseObj
end

--[[
local conf = {
	loginCheck = true,				-- 是否对连接的session进行检查
	protocalHandlers = {},				-- 哈希表: 协议号->协议处理函数（连接对象，protocBuffer对象）
	methods = {							-- 服务注册的lua命令
		["cmd"] = {["func"]=functionReference, ["isRet"]=false},
	},
	initFunc = function() end,			-- 服务初始化函数，如果有值，那么在创建服务时调用
}
--]]

local function createService(conf)
	if type(conf.methods)~="table" then
		conf.methods = {}
	end

	conf.methods.request = {["func"]=cmd_request, ["isRet"]=true}
	_conf = conf

	skynet.start(function()
		if type(_conf.initFunc)=="function" then
			_conf.initFunc()
		end

		skynet.dispatch("lua", function(session, source, cmd, ...)
			local methodItem = assert(_conf.methods[cmd], string.format("%s: handler not found for \"%s\"", SERVICE_NAME, cmd))
			if methodItem.isRet then
				skynet.ret(skynet.pack(methodItem.func(...)))
			else
				methodItem.func(...)
			end
		end)
	end)
end

return {
	createService = createService,
}
