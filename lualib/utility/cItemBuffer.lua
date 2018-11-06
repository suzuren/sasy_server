local CLibrary = nil    --must have method: new & reset
local _itemList = {}
local _newCount = 0

local function allocate()
	local userItem = nil
	if #_itemList > 0 then
		userItem = table.remove(_itemList, 1)
	else
		userItem = CLibrary.new()
		_newCount = _newCount + 1
	end
	return userItem
end

local function release(userItem)
	CLibrary.reset(userItem)
	table.insert(_itemList, userItem)
end

local function init(cl)
	CLibrary = cl
end

local function statistic()
	return {
		newCount = _newCount,
		repositoryCount = #_itemList,
	}
end


return {
	init = init,
	allocate = allocate,
	release = release,
	statistic = statistic,
}
