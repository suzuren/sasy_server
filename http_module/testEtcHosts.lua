
local inspect = require "inspect"

local dns = {}
local request_pool = {}
local local_hosts -- local static table lookup for hostnames

dns.DEFAULT_HOSTS = "/etc/hosts"
dns.DEFAULT_RESOLV_CONF = "/etc/resolv.conf"

-- return name type: 'ipv4', 'ipv6', or 'hostname'
local function guess_name_type(name)
	if name:match("^[%d%.]+$") then
		return "ipv4"
	end

	if name:find(":") then
		return "ipv6"
	end

	return "hostname"
end

local function parse_hosts()
	if not dns.DEFAULT_HOSTS then
		return
	end

	local f = io.open(dns.DEFAULT_HOSTS)
	if not f then
		return
	end

	local rts = {}
	for line in f:lines() do
		local ip, hosts = string.match(line, "^%s*([%[%]%x%.%:]+)%s+([^#;]+)")
		--print("ip -"..ip)
		--print("hosts -"..hosts)
		if not ip or not hosts then
			goto continue
		end
		
		local family = guess_name_type(ip)
		--print("family -"..family)
		if family == "hostname" then
			goto continue
		end
		
		for host in hosts:gmatch("%S+") do
			host = host:lower()
			local rt = rts[host]
			--print("host -"..host)
			if not rt then
				rt = {}
				rts[host] = rt
			end

			if not rt[family] then
				rt[family] = {}
			end
			table.insert(rt[family], ip)
		end

		::continue::
	end
	return rts
end


-- lookup local static table
local function local_resolve(name, ipv6)
	if not local_hosts then
		local_hosts = parse_hosts()
	end

	if not local_hosts then
		return
	end
	print(inspect(local_hosts))

	local family = ipv6 and "ipv6" or "ipv4"
	local t = local_hosts[name]
	if t then
		local answers = t[family]
		if answers then
			return answers[1], answers
		end
	end
	return nil
end

local_resolve(name, ipv6)

--[[
[root@forest http_module]# lua testEtcHosts.lua 
{
  ["github.com"] = {
    ipv4 = { "192.30.255.113" }
  },
  localhost = {
    ipv4 = { "127.0.0.1" },
    ipv6 = { "::1" }
  },
  ["localhost.localdomain"] = {
    ipv4 = { "127.0.0.1" },
    ipv6 = { "::1" }
  },
  localhost4 = {
    ipv4 = { "127.0.0.1" }
  },
  ["localhost4.localdomain4"] = {
    ipv4 = { "127.0.0.1" }
  },
  localhost6 = {
    ipv6 = { "::1" }
  },
  ["localhost6.localdomain6"] = {
    ipv6 = { "::1" }
  }
}
[root@forest http_module]# 
[root@forest http_module]# cat -n /etc/hosts
     1	127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
     2	::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
     3	192.30.255.113 github.com
[root@forest http_module]# 


]]