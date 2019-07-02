local skynet = require "skynet"
local ltls = require "ltls.c"

skynet.start(function()
	skynet.error("Server start")
	skynet.newservice("fortesthttp")
	--skynet.newservice("forsimpleweb","agent","https")
	--local emaild = skynet.uniqueservice("emaild")
	--[[
	mail_opts = {
		 host = 'smtp.qq.com',
		 port = 465,
		 user = "devsoft@foxmail.com",
		 token = "tbnzxdczqbzrdidi",
	},
	local email = {
		 from    = "devsoft@foxmail.com",
		 to      = "tifanys@qq.com",
		 subject = "test tail",
		 html    = "hello world."
	}
	]]
	--skynet.call(emaild, "lua", "send_email", email, mail_opts)

	skynet.exit()
end)
