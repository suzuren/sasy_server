local multicast = require "multicast"

local _channelHash = {}
local _mcReceiver = nil

local function subscribeChannel(channelID)
	local channel = _channelHash[channelID]
	if not channel then
		channel = multicast.new({
			channel = channelID,
			dispatch = _mcReceiver,
		})
		channel:subscribe()
		_channelHash[channelID] = channel
	end
end

local function doUnsubscribe(channelID)
	local channel = _channelHash[channelID]
	channel:unsubscribe()
	_channelHash[channelID] = nil
end


local function unsubscribeChannel(channelIDList)
	for _, channelID in ipairs(channelIDList) do
		local channel = _channelHash[channelID]
		if channel then
			doUnsubscribe(channelID)
		end
	end
end	

local function unsubscribeAll()
	for channelID, _ in pairs(_channelHash) do
		doUnsubscribe(channelID)
	end
end

local function initialize(recFunc)
	_mcReceiver = recFunc
end

return {
	subscribeChannel = subscribeChannel,
	unsubscribeChannel = unsubscribeChannel,
	unsubscribeAll = unsubscribeAll,
	initialize = initialize,
}

