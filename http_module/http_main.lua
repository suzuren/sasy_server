local skynet = require "skynet"
local ltls = require "ltls.c"

skynet.start(function()
	skynet.error("Server start")
	skynet.newservice("fortesthttp")	
	skynet.exit()
end)
