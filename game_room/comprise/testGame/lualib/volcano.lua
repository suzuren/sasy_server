local skynet = require "skynet"
local ServerUserItem = require "sui"
local FISH_CONST = require "fish.lualib.const"
local currencyUtility = require "utility.currency"
local addressResolver = require "addressResolver"
local resourceResolver = require "resourceResolver"

local _config
local _tableFrame
local _tableFrameSink
local _netWin = 0

local function loadNetWin()
	local serverID = _tableFrame.getServerConfig().ServerID
	local tableID = _tableFrame.getTableID()
	
	local sql = string.format(
		"call ssfishdb.sp_load_table_net_win(%d, %d)",
		serverID, tableID
	)
	local mysqlConn = addressResolver:getMysqlConnection()
	local row = skynet.call(mysqlConn, "lua", "call", sql)[1]
	_netWin = tonumber(row.netWin)
end

local function initialize(config, tableFrame, tableFrameSink)
	_config = config
	_tableFrame = tableFrame
	_tableFrameSink = tableFrameSink
	loadNetWin()
end

local function getVolcanoRate()
	local rate = 0
	if _netWin > 0 then
		rate = _netWin / _config.activePoolThreshold
		if rate > 1 then
			rate = 1
		end
	end
	return rate
end

local function sendVolcanoPoolStatus(agent)
	local protocalNo, protocalObj = 0x020200, {rate=getVolcanoRate()}
	
	if agent then
		skynet.send(agent, "lua", "forward", protocalNo, protocalObj)
	else
		local pbParser = resourceResolver.get("pbParser")
		local packetStr = skynet.call(pbParser, "lua", "encode", protocalNo, protocalObj, true)
		if packetStr then
			_tableFrame.broadcastTable(packetStr)
			_tableFrame.broadcastLookon(packetStr)		
		end
	end
end

local function storeNetWin()
	local serverID = _tableFrame.getServerConfig().ServerID
	local tableID = _tableFrame.getTableID()
	
	local sql = string.format(
		"INSERT INTO `ssfishdb`.`VolcanoTableNetWin` (`ServerID`, `TableID`, `Score`) VALUES (%d, %d, %d) ON DUPLICATE KEY UPDATE `Score`=VALUES(`Score`)",
		serverID, tableID, _netWin
	)
	
	local mysqlConn = addressResolver:getMysqlConnection()
	skynet.call(mysqlConn, "lua", "query", sql)
end


local function addNetWin(score, pbParser)
	local oldRate = math.floor(getVolcanoRate() * 10)
	_netWin = _netWin + score
	local rate = math.floor(getVolcanoRate() * 10)
	if oldRate~=rate then
		sendVolcanoPoolStatus(nil)	
	end
end

local function checkOpen(userItem, fishMultiple)
	local userAttr = ServerUserItem.getAttribute(userItem, {"chairID", "agent", "nickName", "isAndroid", "userID"})
	if _netWin >= _config.activePoolThreshold and fishMultiple >= _config.activeFishMultiple and not userAttr.isAndroid then
		local gameData = _tableFrameSink.getGameDataItem(userAttr.chairID)
		local volcanoScore = _config.giveRate * _config.activePoolThreshold
		
		local serverConfig = _tableFrame.getServerConfig()
		local sql = string.format(
			"insert into `ssrecorddb`.`Volcano` (`KindID`, `NodeID`, `ServerID`, `Ctime`, `UserID`) values (%d, %d, %d, NOW(), %d)",
			serverConfig.KindID, serverConfig.NodeID, serverConfig.ServerID, userAttr.userID
		)	
		local mysqlConn = addressResolver:getMysqlConnection()
		skynet.call(mysqlConn, "lua", "query", sql)	
		
		gameData.fishScore = gameData.fishScore + volcanoScore
		_tableFrame.onMatchScoreChange(userItem, volcanoScore)
		_netWin = 0
		_tableFrameSink.addSystemScorePool(gameData, -volcanoScore, FISH_CONST.SYSTEM_SCORE_POOL_OPERATION.SSPO_DO_NOT_CHANGE_VOLCANO)	
		storeNetWin()
		sendVolcanoPoolStatus(nil)
		
		_tableFrame.sendSystemMessage(
			string.format("恭喜%s在%s中开启火山爆发奖池，获%s金币!", userAttr.nickName, serverConfig.ServerName, currencyUtility.formatCurrency(volcanoScore)),
			false, true, false, false
		)
		
		local pbParser = resourceResolver.get("pbParser")
		local packetStr = skynet.call(pbParser, "lua", "encode", 0x020201, {chairID=userAttr.chairID, fishScore=volcanoScore, fishMulti=fishMultiple}, true)
		if packetStr then
			_tableFrame.broadcastTable(packetStr)
			_tableFrame.broadcastLookon(packetStr)					
		end
	end
end

return {
	initialize = initialize,
	sendVolcanoPoolStatus = sendVolcanoPoolStatus,
	storeNetWin = storeNetWin,
	addNetWin = addNetWin,
	checkOpen = checkOpen,
}


