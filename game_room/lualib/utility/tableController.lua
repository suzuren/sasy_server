local skynet = require "skynet"
local GS_CONST = require "define.gsConst"
local ServerUserItem = require "sui"
local addressResolver = require "addressResolver"

local function doProtocalAgent(tcpAgent, pbObj, tcpAgentData, protocalNo)
	local userAttr = ServerUserItem.getAttribute(tcpAgentData.sui, {"tableID", "chairID", "userStatus", "isAndroid","userID"})
	if userAttr.tableID == GS_CONST.INVALID_TABLE or userAttr.chairID == GS_CONST.INVALID_CHAIR then
		if userAttr.isAndroid then
			skynet.error(string.format("%s: 桌子号或椅子号错误", SERVICE_NAME))
			return
		end
		skynet.error(string.format("%s: 桌子号或椅子号错误,userID=%d,tableID=%d,charid=%d", SERVICE_NAME,userAttr.userID,userAttr.tableID,userAttr.chairID))
		return
	end
	
	if userAttr.userStatus == GS_CONST.USER_STATUS.US_LOOKON then
		return
	end
	
	local tableAddress = addressResolver.getTableAddress(userAttr.tableID)
	if not tableAddress then
		error(string.format("%s: 找不到桌子No.%d", SERVICE_NAME, userAttr.tableID))
	end
	
	skynet.call(tableAddress, "lua", "gameMessage", userAttr.chairID, tcpAgentData.sui, protocalNo, pbObj)
end

local function getProtocalHandlerHash(protocalNoList)
	local handlerHash = {}
	for _, protocalNo in ipairs(protocalNoList) do
		handlerHash[protocalNo] = function(tcpAgent, pbObj, tcpAgentData)
			doProtocalAgent(tcpAgent, pbObj, tcpAgentData, protocalNo)
		end
	end
	return handlerHash
end

return {
	getProtocalHandlerHash = getProtocalHandlerHash,
}