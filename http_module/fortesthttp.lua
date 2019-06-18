local skynet = require "skynet"
local httpc = require "http.httpc"
local dns = require "skynet.dns"

local function http_test(protocol)
	--httpc.dns()	-- set dns server
	httpc.timeout = 100	-- set timeout 1 second
	print("GET baidu.com")
	protocol = protocol or "http"
	local respheader = {}
	local host = string.format("%s://baidu.com", protocol)
	print("geting... ".. host)
	local status, body = httpc.get(host, "/", respheader)
	print("[header] =====>")
	for k,v in pairs(respheader) do
		print(k,v)
	end
	print("[body] =====>", status)
	print(body)

	local respheader = {}
	local ip = dns.resolve "baidu.com"
	print(string.format("GET %s (baidu.com)", ip))
	local status, body = httpc.get(host, "/", respheader, { host = "baidu.com" })
	print(status)
end

-- https://tg.safeabc.cn/admin/ApiTest/getPhone
-- 有时候会超时 不能返回 出现 false	[Socket Error]
local function for_get_http_test()
	httpc.timeout = 900	-- set timeout 1 second
	local host = "https://tg.safeabc.cn"
	local uri = "/admin/ApiTest/getPhone"
	local respheader = {}
	local header = nil
	local content = nil
	local status, body = httpc.get(host, uri, respheader, header, content)
	print("[header] =====>")
	for k,v in pairs(respheader) do
		print(k,v)
	end
	print("[body] =====>", status)
	print("-------------------------start")
	print(body)
	print("-------------------------end")
	local respheader = {}
	local ip = dns.resolve "tg.safeabc.cn"
	print(string.format("GET %s (getPhone.com)", ip))
	local status, body = httpc.get(host, "/admin/ApiTest/getPhone", respheader, { host = "tg.safeabc.cn" })
	print(status)
	print("-------------------------start")
	print(body)
	print("-------------------------end")
end

--[[
[:0100000b] LAUNCH snlua fortesthttp
[header] =====>
server	nginx
date	Tue, 18 Jun 2019 07:31:31 GMT
x-powered-by	PHP/7.2.6
connection	keep-alive
transfer-encoding	chunked
content-type	application/json; charset=utf-8
[body] =====>	200
-------------------------start
{"phone":"15245865427","id":"5c75e2859dc6d623724bec0f"}
-------------------------end
[:0100000b] Udp server open 8.8.8.8:53 (6)
GET 61.132.229.14 (getPhone.com)
200
-------------------------start
{"phone":"15707162446","id":"5c75e2859dc6d623724bec0f"}
-------------------------end
true
]]

local function for_post_http_test()
	httpc.timeout = 900	-- set timeout 1 second
	local host = "http://47.94.250.154:38018"
	local uri = "/landlords-pokerbot/register"
	local form = { "mac_address=FC-AA-14-D3-A4-E8" }
	local respheader = {}
	local header = {["content-type"] = "application/x-www-form-urlencoded"}
	local content = "mac_address=FC-AA-14-D3-A4-E8"
	--local status, body = httpc.post(host, url, form, recvheader)
	local status, body = httpc.request("POST", host, uri, respheader, header, content)

	print("[header] =====>")
	for k,v in pairs(respheader) do
		print(k,v)
	end
	print("[body] =====>", status)
	print("-------------------------start")
	print(body)
	print("-------------------------end")
end

--[[
[header] =====>
content-type	application/json;charset=utf-8
content-length	44
date	Tue, 18 Jun 2019 08:19:50 GMT
[body] =====>	200
-------------------------start
{"result":"无权限访问","status":"0999"}
-------------------------end
true

]]


local function main()
	dns.server()
	--http_test("http")
	--for_post_http_test()
	if not pcall(require,"ltls.c") then
		print "No ltls module, https is not supported"
	else
		--http_test("https")
		for_get_http_test()
	end
end

skynet.start(function()
	print(pcall(main))
	skynet.exit()
end)
