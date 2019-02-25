local skynet = require "skynet"
local inspect = require "inspect"
--[[
local conf = {
	methods = {
		["cmd"] = {["func"]=functionReference, ["isRet"]=false},
	},
	initFunc = function() end,
}
--]]

local function createService(conf)
	skynet.start(function()
		if type(conf.initFunc)=="function" then
			conf.initFunc()
		end

		skynet.dispatch("lua", function(session, source, cmd, ...)
		--print(SERVICE_NAME,session, source, cmd, ...)
			local methodItem = assert(conf.methods[cmd], string.format("%s: handler not found for \"%s\"", SERVICE_NAME, cmd))
			--print(SERVICE_NAME,methodItem)
			--skynet.error(SERVICE_NAME,"\n",inspect(methodItem),"\n-")
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
