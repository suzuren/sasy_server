local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local controllerResolveConfig = require "define.controllerResolveConfig"
local addressResolver = require "addressResolver"

local inspect = require "inspect"

addressResolver.configKey(controllerResolveConfig.getConfig("web"))

local function response(id, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		skynet.error(string.format("fd = %d, %s", id, err))
	end
end

skynet.start(function()
	skynet.dispatch("lua", function (_,_,id,ipAddr)
		socket.start(id)
		-- limit request body size to 8192 (you can pass nil to unlimit)
		local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)		
		skynet.error(string.format("code-%d, url-%s, method-%s, header-%s, body-%s", code, url, method, header, body))		
		skynet.error("header-\n",inspect(header),"\n-")
		if code then
			if code ~= 200 then
				response(id, code)
			else

				local path, query = urllib.parse(url)
				skynet.error(string.format("1 path-%s, query-%s", path, query))

				-- if the first character is '/'
				if string.byte(path, 1) == 0x2f then
					path = string.sub(path, 2)
				end
				skynet.error(string.format("2 path-%s, query-%s", path, query))

				local controllerAddress = addressResolver.getAddressByKey(path)
				if controllerAddress then
					local get = {}
					if query then
						get = urllib.parse_query(query)
					end

					local post = {}
					if string.len(body) > 0 then
						post = urllib.parse_query(body)
					end
					response(id, skynet.call(controllerAddress, "lua", path, {
						method=method,
						header=header,
						get=get,
						post=post,
						ipAddr=ipAddr,
					}))
				else
					response(id, 404)
				end
			end
		else
			if url == sockethelper.socket_error then
				skynet.error("socket closed")
			else
				skynet.error(url)
			end
		end
		socket.close(id)
	end)
end)
