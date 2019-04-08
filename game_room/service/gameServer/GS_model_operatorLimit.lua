local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local ServerUserItem = require "sui"
local COMMON_CONST = require "define.commonConst"

local _opLimitHash = {}	

local function cmd_SaveData(userID)
	local info = _opLimitHash[userID]
	if not info then
		return
	end

	local dbConn = addressResolver.getMysqlConnection()
	for k, v in pairs(info) do 
		if v.limitId == COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_ONLINE_TIME then
			local userItem = skynet.call(addressResolver.getAddressByServiceName("GS_model_userManager"),"lua","getUserItem",userID)
			if userItem then
				local userAttr = ServerUserItem.getAttribute(userItem, {"logonTime"})
				v.limitCount = v.limitCount + os.time() - userAttr.logonTime
			end
		end

		if v.limitId ~= COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_DOUBLE_GOLD then
			local sql = string.format("insert into `ssrecorddb`.`t_user_operator_limit` (`UserId`,`LimitId`,`LimitCount`,`LimitDate`) VALUES(%d,%d,%d,%d) ON DUPLICATE KEY UPDATE LimitCount=%d,LimitDate=%d",
				userID,v.limitId,v.limitCount,v.limitDate,v.limitCount,v.limitDate)
			skynet.call(dbConn,"lua","query",sql)
		end
	end
end

local function cmd_LoadData(userID)
	local info = {}
	local sql = string.format("SELECT * FROM `ssrecorddb`.`t_user_operator_limit` where UserId=%d",userID)
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, row in ipairs(rows) do
			local limitInfo = {
				limitId = tonumber(row.LimitId),
				limitCount = tonumber(row.LimitCount),
				limitDate = tonumber(row.LimitDate)
			}
			table.insert(info,limitInfo)
		end
	end

	_opLimitHash[userID] = info

	local limitId_3 = COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_ONLINE_TIME
	skynet.send(addressResolver.getAddressByServiceName("GS_model_operatorLimit"), "lua", "AddLimit",userID,limitId_3,0)
end

local function cmd_ReleaseUserData(userID)
	_opLimitHash[userID] = nil
end	

local function cmd_CheckIsForeverLimit(userID,limitId,limitCount)
	local info = _opLimitHash[userID]
	if not info then
		return true
	end

	for k, v in pairs(info) do 
		if v.limitId == limitId then
			if v.limitCount >= limitCount then
				return true
			end
			break
		end
	end

	return false
end	

local function cmd_CheckIsEverydayLimit(userID,limitId,limitCount)
	local info = _opLimitHash[userID]
	if not info then
		return true
	end

	local nowDate = tonumber(os.date("%Y%m%d", os.time()))
	for k, v in pairs(info) do 
		if v.limitId == limitId then
			if v.limitDate ~= nowDate then
				v.limitDate = nowDate
				v.limitCount = 0
				return false
			end

			if v.limitCount >= limitCount then
				return true
			end
			break
		end
	end

	return false
end	

local function cmd_CheckIsTimeLimit(userID,limitId,timeSeconds)
	local info = _opLimitHash[userID]
	if not info then
		return true
	end

	--这边做一个特殊处理，这个limitId的时间为时间戳
	--当初limitDate处理有误，不应该这样来存储,有时间去优化吧 2017-02-09 14:09:13
	local nowDate = os.time()
	for k, v in pairs(info) do 
		if v.limitId == limitId then
			if nowDate - v.limitDate > timeSeconds then
				return false
			else
				return true
			end
		end
	end

	return false
end

local function cmd_AddLimit(userID,limitId,limitCount)
	local info = _opLimitHash[userID]
	if not info then
		return
	end

	local bFind = false
	for k, v in pairs(info) do 
		if v.limitId == limitId then
			bFind = true
			v.limitCount = v.limitCount + limitCount
			v.limitDate = tonumber(os.date("%Y%m%d", os.time()))

			if limitId == COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_PAY_RMB_NEW then
				if v.limitCount >= 800 then
					v.limitCount = 800
				end

				if v.limitCount <= 0 then
					v.limitCount = 0
				end
			end

			if limitId == COMMON_CONST.OPERATOR_LIMIT.OP_LIMTI_ID_PAY_RMB_NEW_1 then
				if v.limitCount >= 2000 then
					v.limitCount = 2000
				end

				if v.limitCount <= -1000 then
					v.limitCount = -1000
				end
			end

			if limitId == COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_SEND_TITLE or 
				limitId == COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP then
				v.limitDate = os.time()
			end

			break
		end
	end

	if not bFind then
		local limitInfo = {
			limitId = limitId,
			limitCount = limitCount,
			limitDate = tonumber(os.date("%Y%m%d", os.time()))
		}

		if limitId == COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_SEND_TITLE 
			or limitId == COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP then
			limitInfo.limitDate = os.time()
		end

		table.insert(info,limitInfo)
	end
end

local function cmd_GetLimitCount(userID,limitId)
	local info = _opLimitHash[userID]
	if not info then
		return 0
	end

	for k, v in pairs(info) do 
		if v.limitId == limitId then
			return v.limitCount
		end
	end

	return 0
end	

local function cmd_ResetLimitCount(userID,limitId)
	local info = _opLimitHash[userID]
	if not info then
		return
	end
	
	for k, v in pairs(info) do 
		if v.limitId == limitId then
			v.limitCount = 0
			v.limitDate = tonumber(os.date("%Y%m%d", os.time()))

			if limitId == COMMON_CONST.OPERATOR_LIMIT.OP_LIMIT_ID_EXPERIENCE_VIP then
				v.limitDate = os.time()
			end
		end
	end
end	

local function cmd_GetLimitInfo(userID,limitId)
	local info = _opLimitHash[userID]
	if not info then
		return nil
	end

	for k, v in pairs(info) do 
		if v.limitId == limitId then
			return v
		end
	end
end

local function cmd_GetLimitComposeCD( userID,ItemID )
	local info = _opLimitHash[userID]
	if not info then
		return 0
	end	

	for k, v in pairs(info) do 
		if v.limitId == ItemID then
			local now = tonumber(os.date("%Y%m%d", os.time()));
			if now == v.limitDate then
				return v.limitCount
			else
				cmd_ResetLimitCount(userID,ItemID);
			end
		end
	end

	return 0
end

local function cmd_SetLimitComposeCD( userID,ItemID)
	local info = _opLimitHash[userID]
	if not info then
		return
	end	

	local bFind = false
	for k, v in pairs(info) do 
		if v.limitId == ItemID then
			local now = tonumber(os.date("%Y%m%d", os.time()));
			if now == v.limitDate then
				bFind = true
				cmd_AddLimit(userID,ItemID,v.limitCount+1)
			end
		end
	end

	if not bFind then
		cmd_AddLimit(userID,ItemID,1)
	end
end

local conf = {
	methods = {
		["SaveData"] = {["func"]=cmd_SaveData, ["isRet"]=true},
		["LoadData"] = {["func"]=cmd_LoadData, ["isRet"]=true},
		["ReleaseUserData"] = {["func"]=cmd_ReleaseUserData, ["isRet"]=true},

		["CheckIsForeverLimit"] = {["func"]=cmd_CheckIsForeverLimit, ["isRet"]=true},
		["CheckIsEverydayLimit"] = {["func"]=cmd_CheckIsEverydayLimit, ["isRet"]=true},
		["CheckIsTimeLimit"] = {["func"]=cmd_CheckIsTimeLimit, ["isRet"]=true},
		["AddLimit"] = {["func"]=cmd_AddLimit, ["isRet"]=false},
		["GetLimitCount"] = {["func"]=cmd_GetLimitCount, ["isRet"]=true},
		["ResetLimitCount"] = {["func"]=cmd_ResetLimitCount, ["isRet"]=false},
		["GetLimitInfo"] = {["func"]=cmd_GetLimitInfo, ["isRet"]=true},
		["GetLimitComposeCD"] = {["func"]=cmd_GetLimitComposeCD, ["isRet"]=true},
		["SetLimitComposeCD"] = {["func"]=cmd_SetLimitComposeCD, ["isRet"]=false},
	},
}

commonServiceHelper.createService(conf)
