require "utility.string"
local skynet = require "skynet"
local randHandle = require "utility.randNumber"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local ServerUserItem = require "sui"
local COMMON_CONST = require "define.commonConst"
local GS_CONST = require "define.gsConst"
local mysqlutil = require "utility.mysqlHandle"
local readFileUtility = require "utility.readFile"

local _taskInfoHash = {}

local function loadTaskInfoConfig()
	local config = {}
	local tableConfig,count = readFileUtility.loadCsvFile("t_task_table_info.csv")
	for i = 1, count do
		local task = {
			taskId = tonumber(tableConfig[i].TaskId),
			taskType = tonumber(tableConfig[i].Type),
			limitFashShoot = tonumber(tableConfig[i].limitFastShoot),
			limitAutoShoot = tonumber(tableConfig[i].limitFastAutoShoot),
			limitFortLevel = tonumber(tableConfig[i].limitFortLevel),
			limitFortMulti = tonumber(tableConfig[i].limitFortMulti),
			goalList = {},
			rewardList = {},
		}

		local list = tableConfig[i].goalInfo:split("|")
		for _, item in pairs(list) do
			local itemPart = item:split(":")
			local goal = {
				goalId = tonumber(itemPart[1]),
				goalCount = tonumber(itemPart[2])
			}
			table.insert(task.goalList,goal)
		end

		local listReward = tableConfig[i].RewardInfo:split("|")
		for _, item in pairs(listReward) do
			local itemPart = item:split(":")
			local goods = {
				goodsID = tonumber(itemPart[1]),
				goodsCount = tonumber(itemPart[2])
			}
			table.insert(task.rewardList,goods)
		end
		
		_taskInfoHash[task.taskId] = task
	end
end

local function cmd_RequestTask(taskType,sui)
	local re = {
		taskType = taskType,
		taskID = 0,
		code = 0,
		limitFashShoot = 0,
		limitAutoShoot = 0,
		limitFortLevel = 0,
		limitFortMulti = 0,
		taskGoodsInfoList = {},
		taskRewardGoodsInfoList = {},
		taskLeftTime = 0,
	}

	if taskType == COMMON_CONST.TASK_TYPE.TASK_FISH then --任务鱼不请求,服务器主动下发的
		return
	end
	
	local nowTime = os.time()
	local nowDate = tonumber(os.date("%Y%m%d", nowTime))
	local count = 0 --今日次数
	local sumCount = 0 --总次数
	local attr = ServerUserItem.getAttribute(sui, {"userID", "agent"})
	local sql = string.format("SELECT * FROM `kffishdb`.`t_task` where UserId = %d and TaskType = %d", attr.userID,taskType)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if rows[1] == nil then
		local taskList = {}
		for k, v in pairs(_taskInfoHash) do 
			if v.taskType == taskType then
				table.insert(taskList,v.taskId)
			end
		end

		if #(taskList) > 0 then
			local randValue = randHandle.random(1, #(taskList))
			re.taskID = taskList[randValue]

			local goal = ""
			for k, v in pairs(_taskInfoHash[re.taskID].goalList) do
				local goalTemp = {
					goodsID = v.goalId,
					allGoodsCount = v.goalCount,
					currentGoodsCount = 0
				}
				table.insert(re.taskGoodsInfoList,goalTemp)
				goal = goal..tostring(goalTemp.goodsID)..":"..tostring(goalTemp.allGoodsCount)..":"..tostring(goalTemp.currentGoodsCount).."|" 
			end

			sql = string.format("insert into `kffishdb`.`t_task` values(%d,%d,%d,'%s',%d,%d,%d)",
				attr.userID,re.taskType,re.taskID,mysqlutil.escapestring(goal),0,nowDate,0)
			skynet.call(dbConn, "lua", "query", sql)
		else
			re.code = 2
			goto continue	
		end
	else
		re.taskID = tonumber(rows[1].TaskId)
		count = tonumber(rows[1].SuccessNum)
		sumCount = tonumber(rows[1].SumNum)
		local lastDate = tonumber(rows[1].Date)
	
		local taskInfo = rows[1].TaskInfo:split("|")
		for _, item in pairs(taskInfo) do
			local itemPart = item:split(":")
			local goal = {
				goodsID = tonumber(itemPart[1]),
				allGoodsCount = tonumber(itemPart[2]),
				currentGoodsCount = tonumber(itemPart[3])
			}
			table.insert(re.taskGoodsInfoList,goal)
		end

		if lastDate ~= nowDate then
			count = 0

			local goalInfo = ""
			for k, v in pairs(re.taskGoodsInfoList) do
				v.currentGoodsCount = 0
				goalInfo = goalInfo..tostring(v.goodsID)..":"..tostring(v.allGoodsCount)..":"..tostring(v.currentGoodsCount).."|" 
			end

			sql = string.format("update `kffishdb`.`t_task` set SuccessNum = %d,TaskInfo = '%s',Date = %d where UserId = %d and TaskType = %d and TaskId = %d",
				count,mysqlutil.escapestring(goalInfo),nowDate,attr.userID,re.taskType,re.taskID)
			skynet.call(dbConn,"lua","query",sql)
		end
	end	

	if taskType == COMMON_CONST.TASK_TYPE.KILL_BOSS then
		if sumCount >= 1 then
			re.code = 1
			goto continue
		end
	end

	if sumCount >= GS_CONST.TAKS_MAX_NUM then
		re.code = 1
		goto continue
	end

	if count >= GS_CONST.PET_DAY_MAX_TASK_NUM then
		re.code = 1
	else
		re.limitFashShoot = _taskInfoHash[re.taskID].limitFashShoot
		re.limitAutoShoot = _taskInfoHash[re.taskID].limitAutoShoot
		re.limitFortLevel = _taskInfoHash[re.taskID].limitFortLevel
		re.limitFortMulti = _taskInfoHash[re.taskID].limitFortMulti
		re.taskRewardGoodsInfoList = _taskInfoHash[re.taskID].rewardList
	end

	::continue::

	skynet.send(attr.agent,"lua","forward",0x010800,re)
end

local function cmd_ChangeTaskGoodsCount(pbObj,sui)
	local re = {
		TaskType = pbObj.taskType,
		taskID = pbObj.taskID,
		taskGoodsInfoList = pbObj.taskGoodsInfoList
	}

	if re.TaskType == COMMON_CONST.TASK_TYPE.TASK_FISH then
		local taskInfo = _taskInfoHash[re.taskID]
		if not taskInfo then
			return
		end
		local attr = ServerUserItem.getAttribute(sui, {"tableID","chairID"})
		if attr then
			local tableAddress = addressResolver.getTableAddress(attr.tableID)
			if tableAddress then
				skynet.send(tableAddress, "lua", "ChangeTaskGoodsCount", attr.chairID, pbObj)
			end
		end

		return
	end

	local attr = ServerUserItem.getAttribute(sui, {"userID", "agent"})
	local sql = string.format("SELECT * FROM `kffishdb`.`t_task` where UserId = %d and TaskType = %d and TaskId = %d",
		attr.userID,re.TaskType,re.taskID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if rows[1] ~= nil then
		local taskList = {}
		local taskInfo = rows[1].TaskInfo:split("|")
		for _, item in pairs(taskInfo) do
			local itemPart = item:split(":")
			local goal = {
				goodsID = tonumber(itemPart[1]),
				allGoodsCount = tonumber(itemPart[2]),
				currentGoodsCount = tonumber(itemPart[3])
			}
			table.insert(taskList,goal)
		end

		for k, v in pairs(taskList) do 
			for kk, vv in pairs(re.taskGoodsInfoList) do 
				if v.goodsID == vv.goodsID then
					v.currentGoodsCount = v.currentGoodsCount + vv.goodsCount
					break
				end
			end
		end

		local goal = ""
		for k, v in pairs(taskList) do		
			goal = goal..tostring(v.goodsID)..":"..tostring(v.allGoodsCount)..":"..tostring(v.currentGoodsCount).."|" 
		end

		sql = string.format("update `kffishdb`.`t_task` set TaskInfo = '%s' where UserId = %d and TaskType = %d and TaskId = %d",
			mysqlutil.escapestring(goal),attr.userID,re.TaskType,re.taskID)
		skynet.call(dbConn,"lua","query",sql)
	end
end

local function cmd_CompleteTask(pbObj,sui)
	local re = {
		taskType = pbObj.taskType,
		taskID = pbObj.taskID,
		taskRewardGoodsInfoList = {},
		code = 0
	}

	if re.taskType == COMMON_CONST.TASK_TYPE.TASK_FISH then
		local taskInfo = _taskInfoHash[pbObj.taskID]
		if not taskInfo then
			return re
		end
		local attr = ServerUserItem.getAttribute(sui, {"tableID","chairID"})
		if attr then
			local tableAddress = addressResolver.getTableAddress(attr.tableID)
			if tableAddress then
				skynet.send(tableAddress, "lua", "CompleteTask", attr.chairID, pbObj)
			end
		end

		return re
	end

	local attr = ServerUserItem.getAttribute(sui, {"userID", "agent","tableID"})
	local sql = string.format("SELECT * FROM `kffishdb`.`t_task` where UserId = %d and TaskType = %d and TaskId = %d",
		attr.userID,re.taskType,re.taskID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if rows[1] == nil then
		re.code = 1
		return re 
	end

	local count = tonumber(rows[1].SuccessNum)
	local sumCount = tonumber(rows[1].SumNum)
	local lastDate = tonumber(rows[1].Date)

	local nowTime = os.time()
	local nowDate = tonumber(os.date("%Y%m%d", nowTime))

	if re.taskType == COMMON_CONST.TASK_TYPE.KILL_BOSS then
		if sumCount >= 1 then
			re.code = 1
			return re
		end
	end

	if sumCount >= GS_CONST.TAKS_MAX_NUM then
		re.code = 1
		return re
	end

	if count >= GS_CONST.PET_DAY_MAX_TASK_NUM then
		re.code = 1
		return re 
	end

	local taskList = {}
	local taskInfo = rows[1].TaskInfo:split("|")
	for _, item in pairs(taskInfo) do
		local itemPart = item:split(":")
		local goal = {
			goodsID = tonumber(itemPart[1]),
			allGoodsCount = tonumber(itemPart[2]),
			currentGoodsCount = tonumber(itemPart[3])
		}
		table.insert(taskList,goal)
	end
 
	local bFind = false
	for kk, vv in pairs(taskList) do 
		if vv.allGoodsCount > vv.currentGoodsCount then
			bFind = true 
			break
		end
	end

	if bFind == true then
		re.code = 1
		return re
	end

	local rewardGold = 0
	for k, v in pairs(_taskInfoHash[re.taskID].rewardList) do 
		if v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
			local tableAddress
			if attr.tableID~=GS_CONST.INVALID_TABLE then
				tableAddress = addressResolver.getTableAddress(attr.tableID)
			end
	
			if tableAddress then
				ServerUserItem.addAttribute(sui, {score=v.goodsCount})
				skynet.call(tableAddress, "lua", "onUserScoreNotify", sui)
				-- skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "AddItemRecord",attr.userID,
				-- 	1001,v.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_TASK)
			end

			rewardGold = rewardGold + v.goodsCount
		-- else
		-- 	skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",attr.userID,
		--  		v.goodsID,v.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_TASK,true)
		end

		skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",attr.userID,
		 	v.goodsID,v.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_TASK,true)
	end

	if lastDate ~= nowDate then
		count = 1
	else
		count = count + 1
	end
	sumCount = sumCount + 1

	if count < GS_CONST.PET_DAY_MAX_TASK_NUM then
		sql = string.format("delete from `kffishdb`.`t_task` where UserId = %d and TaskType = %d and TaskId = %d",
				attr.userID,re.taskType,re.taskID)
		skynet.call(dbConn, "lua", "query", sql)

		local taskList = {}
		for k, v in pairs(_taskInfoHash) do 
			if v.taskType == re.taskType then
				table.insert(taskList,v.taskId)
			end
		end
	
		if #(taskList) > 0 then
			local randValue = randHandle.random(1, #(taskList))
			local taskId = taskList[randValue]

			local goal = ""
			for k, v in pairs(_taskInfoHash[taskId].goalList) do
				local goalTemp = {
					goodsID = v.goalId,
					allGoodsCount = v.goalCount,
					currentGoodsCount = 0
				}
				goal = goal..tostring(goalTemp.goodsID)..":"..tostring(goalTemp.allGoodsCount)..":"..tostring(goalTemp.currentGoodsCount).."|" 
			end

			sql = string.format("insert into `kffishdb`.`t_task` values(%d,%d,%d,'%s',%d,%d,%d)",
				attr.userID,re.taskType,taskId,mysqlutil.escapestring(goal),count,nowDate,sumCount)
			skynet.call(dbConn, "lua", "query", sql)
		end
	else
		sql = string.format("update `kffishdb`.`t_task` set SuccessNum = %d, SumNum = %d where UserId = %d and TaskType = %d and TaskId = %d",
		 count,sumCount,attr.userID,re.taskType,re.taskID)
		skynet.call(dbConn,"lua","query",sql)
	end

	re.taskRewardGoodsInfoList = _taskInfoHash[re.taskID].rewardList

	sql = string.format("insert into `kfrecorddb`.`task_record` (`UserId`,`TaskType`,`TaskId`,`CommitTime`,`RewardGold`) values(%d,%d,%d,'%s',%d)",
		attr.userID,re.taskType,re.taskID,os.date('%Y-%m-%d %H:%M:%S', math.floor(skynet.time())),rewardGold)
	skynet.send(dbConn, "lua", "execute", sql)

	return re 
end

local function cmd_GetTaskIdByType(taskType)
	local taskList = {}
	for k, v in pairs(_taskInfoHash) do 
		if v.taskType == taskType then
			table.insert(taskList,v.taskId)
		end
	end

	if #(taskList) > 0 then
		local randValue = randHandle.random(1, #(taskList))
		return taskList[randValue]
	end

	return 0
end

local function cmd_GetTaskInfoByTaskId(taskID)
	return _taskInfoHash[taskID]
end

local function cmd_TaskSynchronizationTime(taskType,sui)
	if taskType == COMMON_CONST.TASK_TYPE.TASK_FISH then
		local attr = ServerUserItem.getAttribute(sui, {"tableID","chairID"})
		if attr then
			local tableAddress = addressResolver.getTableAddress(attr.tableID)
			if tableAddress then
				skynet.send(tableAddress, "lua", "TaskSynchronizationTime", attr.chairID)
			end
		end
	end
end

local function cmd_CheckKillBossTask(sui)
	local re = {
		taskType = COMMON_CONST.TASK_TYPE.KILL_BOSS,
		taskID = 3001,
		taskRewardGoodsInfoList = {},
		code = 0,
	}

	local attr = ServerUserItem.getAttribute(sui, {"agent","userID"})

	local sql = string.format("SELECT * FROM `kffishdb`.`t_task` where UserId = %d and TaskType = %d and TaskId = %d",
		attr.userID,re.taskType,re.taskID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if rows[1] == nil then
		re.code = 1
		return
	end

	local count = tonumber(rows[1].SuccessNum)
	local sumCount = tonumber(rows[1].SumNum)
	local lastDate = tonumber(rows[1].Date)

	local nowTime = os.time()
	local nowDate = tonumber(os.date("%Y%m%d", nowTime))

	if sumCount >= 1 then
		re.code = 1
		return
	end

	local rewardGold = 0
	for k, v in pairs(_taskInfoHash[re.taskID].rewardList) do 
		if v.goodsID == COMMON_CONST.ITEM_ID.ITEM_ID_GOLD then
			local tableAddress
			if attr.tableID~=GS_CONST.INVALID_TABLE then
				tableAddress = addressResolver.getTableAddress(attr.tableID)
			end
	
			if tableAddress then
				ServerUserItem.addAttribute(sui, {score=v.goodsCount})
				skynet.call(tableAddress, "lua", "onUserScoreNotify", sui)
			end

			rewardGold = rewardGold + v.goodsCount
		end

		skynet.send(addressResolver.getAddressByServiceName("GS_model_bag"), "lua", "ChangeItemCount",attr.userID,
		 	v.goodsID,v.goodsCount,COMMON_CONST.ITEM_SYSTEM_TYPE.BY_TASK,true)
	end

	sumCount = sumCount + 1

	sql = string.format("update `kffishdb`.`t_task` set SuccessNum = %d, SumNum = %d where UserId = %d and TaskType = %d and TaskId = %d",
		1,sumCount,attr.userID,re.taskType,re.taskID)
	skynet.call(dbConn,"lua","query",sql)

	re.taskRewardGoodsInfoList = _taskInfoHash[re.taskID].rewardList

	sql = string.format("insert into `kfrecorddb`.`task_record` (`UserId`,`TaskType`,`TaskId`,`CommitTime`,`RewardGold`) values(%d,%d,%d,'%s',%d)",
		attr.userID,re.taskType,re.taskID,os.date('%Y-%m-%d %H:%M:%S', math.floor(skynet.time())),rewardGold)
	skynet.send(dbConn, "lua", "execute", sql)

	skynet.send(attr.agent,"lua","forward",0x010802,re)

end

local conf = {
	methods = {
		["RequestTask"] = {["func"]=cmd_RequestTask, ["isRet"]=false},
		["ChangeTaskGoodsCount"] = {["func"]=cmd_ChangeTaskGoodsCount, ["isRet"]=false},
		["CompleteTask"] = {["func"]=cmd_CompleteTask, ["isRet"]=true},
		["GetTaskIdByType"] = {["func"]=cmd_GetTaskIdByType, ["isRet"]=true},
		["GetTaskInfoByTaskId"] = {["func"]=cmd_GetTaskInfoByTaskId, ["isRet"]=true},
		["TaskSynchronizationTime"] = {["func"]=cmd_TaskSynchronizationTime, ["isRet"]=false},
		["CheckKillBossTask"] = {["func"]=cmd_CheckKillBossTask, ["isRet"]=false},
	},
	initFunc = function()
		loadTaskInfoConfig()
	end,
}

commonServiceHelper.createService(conf)

