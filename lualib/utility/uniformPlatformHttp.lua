local md5 = require "md5"
local json = require "cjson"

local _serverKeyHash={}

local function getSign(param, key)
	local keyList = {}
	for k, _ in pairs(param) do
		if k ~= "sign" then
			table.insert(keyList, k)
		end
	end
	table.sort(keyList)

	local signPair = {}
	for _, v in ipairs(keyList) do
		table.insert(signPair, string.format("%s=%s", v, param[v]))
	end
	local signStr = table.concat(signPair, "&");
	signStr = signStr .. string.format("&serverkey=%s", key)
	return md5.sumhexa(signStr)
end

local function getEvent(param)
	if type(param.event) ~= "string" then
		return nil
	end

	local isOK, event = pcall(json.decode, param.event)
	if isOK then
		return event;
	else
		return nil
	end
end

local function getUniformPlatformData(method, post)
	if string.lower(method) ~= "post" then
		return false, "request method not support"
	end

	local appid = tonumber(post.appid)
	local serverid = tonumber(post.serverid)
	if (not _serverKeyHash[appid]) or (not _serverKeyHash[appid][serverid]) then
		return false, "server not found"
	end
	
	local ts = tonumber(post.ts)
	if math.abs(os.time() - ts) > 1800 then
		return false, "request timed out"
	end
	
	local serverkey = _serverKeyHash[appid][serverid]
	if getSign(post, serverkey) ~= post.sign then
		return false, "invalid sign"
	end
	local event = getEvent(post)
	if not event then
		return false, "invalid message format"
	end
	return true, appid, serverid, event
end

local function setUpServerKeyHash(hash)
	_serverKeyHash = hash
end

return {
	getUniformPlatformData = getUniformPlatformData,
	setUpServerKeyHash = setUpServerKeyHash,
}
