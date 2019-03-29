
local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local mysqlutil = require "mysqlutil"

local inspect = require "inspect"

local _huoDongTimeConfig = {}

local function loadHuoDongTimeConfig()
	local sql = "SELECT `Index`,Tips,ActivityType,UNIX_TIMESTAMP(StartTime) as StartTime,UNIX_TIMESTAMP(EndTime) as EndTime,`TuPianId`,`BeiJingId`,`TextName`,`ActivityClass` FROM `t_huo_dong_time_config`;"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, row in pairs(rows) do
			local info = {
				index = tonumber(row.Index),
				tips = row.Tips,
				activityType = tonumber(row.ActivityType),
				startTime = tonumber(row.StartTime),
				endTime = tonumber(row.EndTime),
				tuPianID = row.TuPianId,
				beiJingID = row.BeiJingId,
				textName = row.TextName,
				activityClass = tonumber(row.ActivityClass),
			}
			_huoDongTimeConfig[info.index] = info
		end
	end
end

local function insertHuoDongTimeConfig()
	local dbConn = addressResolver.getMysqlConnection()
	local sql = "INSERT INTO `t_huo_dong_time_config` (Tips,ActivityType,StartTime,EndTime,TuPianId,BeiJingId,TextName,ActivityClass) VALUES ('规则: 单笔充值特定金额，赢取相应丰厚大奖\n提示：可重复充值领取', '2', '2016-11-26 00:00:00', '2016-12-02 00:00:00', 'Dbcz', 'Cz', 'Qcz', '2');"
	local lastautoid = skynet.call(dbConn, "lua", "insert", sql)
	--skynet.error(string.format("%s insertHuoDongTimeConfig - lastautoid:%d",SERVICE_NAME,lastautoid))
end

local function loadTimeInfo()
	local sql = string.format("call sp_load_time_info(%d)",13)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "call", sql)
	--skynet.error(string.format("%s loadTimeInfo - rows\n",SERVICE_NAME),inspect(rows))
end

local function insertEscapeStringHuoDongTimeConfig()
	local dbConn = addressResolver.getMysqlConnection()
	local sql = "INSERT INTO `t_huo_dong_time_config` (Tips,ActivityType,StartTime,EndTime,TuPianId,BeiJingId,TextName,ActivityClass) VALUES ('规则: 单笔充值特定金额，赢取相应丰厚大奖\n提示：可重复充值领取', '2', '2016-11-26 00:00:00', '2016-12-02 00:00:00', 'Dbcz', 'Cz', 'Qcz', '2');"
	local sql = string.format("INSERT INTO `t_huo_dong_time_config`	(Tips,ActivityType,StartTime,EndTime,TuPianId,BeiJingId,TextName,ActivityClass) VALUES 	('%s', '%d', '%s', '%s', '%s', '%s', '%s', '%d');",	mysqlutil.escapestring("规则: 单笔充值特定金额，赢取相应丰厚大奖\n提示：可重复充值领取"), 2, mysqlutil.escapestring("2016-11-26 00:00:00"), mysqlutil.escapestring("2016-12-02 00:00:00"), mysqlutil.escapestring("Dbcz"), mysqlutil.escapestring("Cz"), mysqlutil.escapestring("Qcz"), 2)
	skynet.error(string.format("%s insertEscapeStringHuoDongTimeConfig - sql:%s",SERVICE_NAME,sql))
	skynet.call(dbConn, "lua", "execute", sql)
end

local function cmd_GetHuoDongTimeInfo()
	return _huoDongTimeConfig
end

local conf = {
	methods = {
		["GetHuoDongTimeInfo"]	= {["func"] = cmd_GetHuoDongTimeInfo, ["isRet"]=true},
	},
	initFunc = function()
		loadHuoDongTimeConfig()
		insertHuoDongTimeConfig()
		loadTimeInfo()
		insertEscapeStringHuoDongTimeConfig()
	end,
}

commonServiceHelper.createService(conf)


--[[


-- ----------------------------
-- Procedure structure for sp_load_time_info
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_load_time_info`;
DELIMITER ;;
CREATE  PROCEDURE `sp_load_time_info`(
IN inIndex int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	DECLARE varIndex INT UNSIGNED;
	DECLARE varTips	VARCHAR(250);
	DECLARE varActivityType TINYINT(4);
	DECLARE varStartTime DATETIME;
	DECLARE varEndTime DATETIME;
	DECLARE varTuPianId VARCHAR(250);
	DECLARE varBeiJingId VARCHAR(250);
	DECLARE varTextName VARCHAR(250);
	DECLARE varActivityClass TINYINT(4);

	SELECT `Index`, `Tips`, `ActivityType`, `StartTime`, `EndTime`, `TuPianId`, `BeiJingId`, `TextName`, `ActivityClass` INTO varIndex, varTips, varActivityType, varStartTime, varEndTime, varTuPianId, varBeiJingId, varTextName, varActivityClass FROM `t_huo_dong_time_config` WHERE `Index`=inIndex; 
	
	IF ISNULL(varIndex) THEN
		SET retCode := 1;
		SET retMsg = "找不到t_huo_dong_time_config记录";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	SET retCode := 0;
	SET retMsg = "SUCCESS";

	SELECT retCode, retMsg, varIndex AS "Index", varTips AS "Tips", varActivityType AS "ActivityType", UNIX_TIMESTAMP(varStartTime) AS "StartTime", UNIX_TIMESTAMP(varEndTime) AS "EndTime", varTuPianId AS "TuPianId", varBeiJingId AS "BeiJingId", varTextName AS "TextName", varActivityClass AS "ActivityClass";
END
;;
DELIMITER ;


call sp_load_time_info(13);
SHOW WARNINGS;

]]