local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"

local function cmd_Invitation(pbObj,userID)
		local re = {
		code = 0,
		err = "",
	}

	local sql = string.format("call `kffishdb`.`sp_user_invitation`('%s',%d)",pbObj.invitation,userID)
	local dbConn = addressResolver.getMysqlConnection()
	local ret = skynet.call(dbConn, "lua", "call", sql)[1]
	re.code = tonumber(ret.retCode)
	re.err = tostring(ret.retMsg)
	return re 
end

local conf = {
	methods = {
		["Invitation"] = {["func"]=cmd_Invitation, ["isRet"]=true},			
	},
}

commonServiceHelper.createService(conf)

