local skynet = require "skynet"
local inspect = require "inspect"

local _resourceManagerAddress
local _data = {}
local _resourceKindHash = {
	pbParser = true,
	sensitiveWordFilter = true,
}

local function get(kind)
	local dataItem = _data[kind]
	if dataItem==nil then
		if not _resourceKindHash[kind] then
			return error(string.format("没有这类资源: %s", tostring(kind)))
		end
		
		dataItem = {
			pool = {},
			poolSize = 0,
			pacer = 0,
			isCollected = false,
		}
		_data[kind] = dataItem
	end
	
	dataItem.pacer = dataItem.pacer + 1
	--skynet.error("_data-\n",inspect(_data),"\n-",kind,"\n-")
	--skynet.error("_resourceKindHash-\n",inspect(_resourceKindHash),"\n-",kind,"\n-")

	if not dataItem.isCollected then
		local res = skynet.call(_resourceManagerAddress, "lua", "get", kind, dataItem.pacer)
		for _, r in ipairs(dataItem.pool) do
			if r==res then
				dataItem.isCollected = true
				break
			end
		end
		
		if not dataItem.isCollected then
			table.insert(dataItem.pool, res)
			dataItem.poolSize = #(dataItem.pool)
		end
	end
		
	if dataItem.pacer > dataItem.poolSize then
		dataItem.pacer = 1
	end
	--skynet.error("dataItem-\n",inspect(dataItem),"\n-")
	return dataItem.pool[dataItem.pacer]
end

local function init()
	if not _resourceManagerAddress then
		_resourceManagerAddress = skynet.queryservice("resourceManager")
	end
end


return {
	init = init,
	get = get,
}
