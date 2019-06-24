local skynet = require "skynet"
local ltls = require "ltls.c"

skynet.start(function()
	skynet.error("Server start")
	--skynet.newservice("fortesthttp")
	skynet.newservice("forsimpleweb","agent","https")
	
	skynet.exit()
end)
