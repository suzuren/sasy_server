local skynet = require "skynet"
local inspect = require "inspect"
local _tableID2tableAddr = {}
local _key2serviceName = {}
local _serviceName2serviceAddress = {}

local function configKey(key2serviceName)
	--skynet.error(string.format("addressResolver.lua_configKey SERVICE_NAME-%s,key2serviceName-%s", SERVICE_NAME, key2serviceName),"\n",inspect(key2serviceName))
	for k, v in pairs(key2serviceName) do
		_key2serviceName[k] = v
	end
end

local function getAddressByServiceName(serviceName)
	local serviceAddress = _serviceName2serviceAddress[serviceName]
	if serviceAddress then
		return serviceAddress
	end

	serviceAddress = skynet.queryservice(serviceName)
	_serviceName2serviceAddress[serviceName] = serviceAddress
	return serviceAddress
end

local function getAddressByKey(key)

	local serviceName = _key2serviceName[key]
	if not serviceName then
		return nil
	end	
	local serviceAddress = _serviceName2serviceAddress[serviceName]
	
	if serviceAddress then
		return serviceAddress
	end
	serviceAddress = skynet.queryservice(serviceName)
	_serviceName2serviceAddress[serviceName] = serviceAddress

	--skynet.error(string.format("addressResolver.lua_getAddressByKey SERVICE_NAME-%s,key-%d,serviceName-%s,serviceAddress-%d", SERVICE_NAME, key,serviceName,serviceAddress))
	
	return serviceAddress
end

local function getMysqlConnection()
	local mysqlConnectionPoolAddress = getAddressByServiceName("mysqlConnectionPool")
	return skynet.call(mysqlConnectionPoolAddress, "lua", "getConnection")
end

local function getTableAddress(tableID)
	local addr = _tableID2tableAddr[tableID]
	if not addr then
		local tableManagerAddress = getAddressByServiceName("GS_model_tableManager")
		addr = skynet.call(tableManagerAddress, "lua", "getTableFrame", tableID)
		if addr then
			_tableID2tableAddr[tableID] = addr
		end
	end
	return addr
end

return {
	configKey = configKey,
	getAddressByServiceName = getAddressByServiceName,
	getAddressByKey = getAddressByKey,
	getMysqlConnection = getMysqlConnection,
	getTableAddress = getTableAddress,
}
