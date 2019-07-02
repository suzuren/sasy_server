local skynet = require "skynet"
local ltls = require "ltls.c"

skynet.start(function()
	skynet.error("Server start")
	--skynet.newservice("fortesthttp")
	--skynet.newservice("forsimpleweb","agent","https")
	local emaild = skynet.uniqueservice("emaild")
	
	local mail_opts = {
		 host = 'smtp.qq.com',
		 port = 465,
		 user = "devsoft@foxmail.com",
		 token = "fortbnzxdczqbzrdidiest",
	}
	local email = {
		 from    = "devsoft@foxmail.com",
		 to      = "tifanys@qq.com",
		 subject = "test tail",
		 content = "hello world."
	}
	
	skynet.call(emaild, "lua", "send_email", email, mail_opts)

	skynet.exit()
end)
