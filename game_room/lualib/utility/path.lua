local arc4 = require "arc4random"
require "utility.table"

local _pathConfigItemHash = {}

local function initPathConfig(name, min, max, intervalTicks)
	_pathConfigItemHash[name] = {
		min = min,
		max = max,
		count = max - min + 1,
		intervalTicks = intervalTicks,
		idHash = {},
	}
end

local function getPathConfigItem(name)
	local pathConfigItem = _pathConfigItemHash[name]
	if not pathConfigItem then
		error(string.format("%s 找不到路径配置 %s", SERVICE_NAME, name))
	end
	return pathConfigItem
end


local function checkPathStatus(name, nowTick)
	local pathConfigItem = getPathConfigItem(name)
	
	for pathID, tick in pairs(pathConfigItem.idHash) do
		if tick+pathConfigItem.intervalTicks < nowTick then
			pathConfigItem.idHash[pathID] = nil
		end
	end
end

local function checkAllPathStatus(nowTick)
	for name, _ in pairs(_pathConfigItemHash) do
		checkPathStatus(name, nowTick)
	end
end

local function getPathID(name, nowTick)
	local pathConfigItem = getPathConfigItem(name)
	
	local pathID = arc4.random(pathConfigItem.min, pathConfigItem.max)
	if pathConfigItem.idHash[pathID] then
		local originalPathID = pathID
		repeat
			pathID = pathID + 1
			if pathID > pathConfigItem.max then
				pathID = pathConfigItem.min
			end
			
			if not pathConfigItem.idHash[pathID] then
				break
			end
		until pathID==originalPathID
		
		if pathID==originalPathID then
			pathID = nil
		end
	end
	
	if pathID~=nil then
		pathConfigItem.idHash[pathID] = nowTick
	end	

	return pathID
end

local function isPathAllUsed(name)
	local pathConfigItem = getPathConfigItem(name)
	
	local r
	if table.countHash(pathConfigItem.idHash) >= pathConfigItem.count then
		r = true
	else
		r = false
	end
	return r
end

local function reset(name)
	local pathConfigItem = getPathConfigItem(name)
	pathConfigItem.idHash = {}
end

local function resetAll()
	for name, _ in pairs(_pathConfigItemHash) do
		reset(name)
	end
end


return {
	initPathConfig = initPathConfig,
	checkPathStatus = checkPathStatus,
	checkAllPathStatus = checkAllPathStatus,
	getPathID = getPathID,
	isPathAllUsed = isPathAllUsed,
	reset = reset,
	resetAll = resetAll,
}
