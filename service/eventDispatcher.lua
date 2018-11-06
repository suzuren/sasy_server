local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"

local _eventType2handler = {}

local function isTableEmpty(t)
	local isEmpty = true
	for k,v in pairs(t) do
		isEmpty = false
		break
	end
	return isEmpty
end

local function cmd_addEventListener(eventType, address, method)
	if type(address)~="number" then
		address = assert(skynet.localname(address), "invalid address")
	end

	if type(_eventType2handler[eventType])~="table" then
		_eventType2handler[eventType] = {}
	end

	if type(_eventType2handler[eventType][address])~="table" then
		_eventType2handler[eventType][address] = {}
	end

	_eventType2handler[eventType][address][method] = true
end

local function cmd_removeEventListener(eventType, address, method)
	if _eventType2handler[eventType] and _eventType2handler[eventType][address] and _eventType2handler[eventType][address][method] then
		_eventType2handler[eventType][address][method] = nil
		if isTableEmpty(_eventType2handler[eventType][address]) then
			_eventType2handler[eventType][address] = nil
			if isTableEmpty(_eventType2handler[eventType]) then
				_eventType2handler[eventType] = nil
			end
		end
	end
end

local function cmd_dispatch(eventType, eventData)
	if eventType and _eventType2handler[eventType] then
		for address, methodTable in pairs(_eventType2handler[eventType]) do
			for method, _ in pairs(methodTable) do
				skynet.send(address, "lua", method, eventData)
			end
		end
	end
end


local conf = {
	methods = {
		["addEventListener"] = {["func"]=cmd_addEventListener, ["isRet"]=false},
		["removeEventListener"] = {["func"]=cmd_removeEventListener, ["isRet"]=false},
		["dispatch"] = {["func"]=cmd_dispatch, ["isRet"]=false},
	}
}

commonServiceHelper.createService(conf)
