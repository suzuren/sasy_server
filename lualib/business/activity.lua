local skynet = require "skynet"
local addressResolver = require "addressResolver"

local function queryScoreActivity(userID)
	local sql = string.format(
		"call kfrecorddb.sp_query_score_activity(%d)", userID)
	local mysqlConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(mysqlConn, "lua", "call", sql)
	return {isAlmsAvailable=rows[1].IsAlmsAvailable=="1", isVIPFreeScoreAvailable=rows[1].IsVIPFreeScoreAvailable=="1"}
end

local function alms(userID)
	
end


return {
	queryScoreActivity = queryScoreActivity,
	alms = alms,
}
