local skynet = require "skynet"
local inspect = require "inspect"
--[[
local conf = {
	methods = {},
	initFunc = function() end,
}
--]]

local function createService(conf)
	skynet.start(function()
		if type(conf.initFunc)=="function" then
			conf.initFunc()
		end

		skynet.dispatch("lua", function(session, source, path, method, header, get, post)
			local handler = conf.methods[path]
			if handler then
				local isOK, code, body, respHeader = pcall(handler, method, header, get, post)
				--skynet.error(string.format("isOK-%s, code-%d, body-%s, respHeader-%s", isOK, code, body, respHeader))
				--skynet.error("respHeader-\n",inspect(respHeader),"\n-")
				if isOK then
					skynet.ret(skynet.pack(code, body, respHeader))
				else
					skynet.error("http error: ", code)
					skynet.ret(skynet.pack(500))
				end
			else
				skynet.ret(skynet.pack(404))
			end
		end)
	end)
end

return {
	createService = createService,
}
