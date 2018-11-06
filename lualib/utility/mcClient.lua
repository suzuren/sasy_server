local multicast = require "multicast"

local channelHash = {}
local mcReceiver = nil

local function subscribeChannel(channelID)
	local channel = channelHash[channelID]
	if not channel then
		channel = multicast.new({
			channel = channelID,
			dispatch = mcReceiver,
		})			
		channel:subscribe()
		channelHash[channelID] = channel
	end
end

local function doUnsubscribe(channelID)
	local channel = channelHash[channelID]
	channel:unsubscribe()
	channelHash[channelID] = nil
end


local function unsubscribeChannel(channelIDList)
	for _, channelID in ipairs(channelIDList) do
		local channel = channelHash[channelID]
		if channel then
			doUnsubscribe(channelID)
		end
	end
end	

local function unsubscribeAll()
	for channelID, _ in pairs(channelHash) do
		doUnsubscribe(channelID)
	end
end

local function initialize(recFunc)
	mcReceiver = recFunc
end

return {
	subscribeChannel = subscribeChannel,
	unsubscribeChannel = unsubscribeChannel,
	unsubscribeAll = unsubscribeAll,
	initialize = initialize,
}

