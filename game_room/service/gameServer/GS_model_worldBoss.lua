
local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local COMMON_CONST = require "define.commonConst"
local ServerUserItem = require "sui"

local function cmd_FishSpawn(agent,sui)
	local attr = ServerUserItem.getAttribute(sui, {"userID","tableID"})
	if attr then
		local tableAddress = addressResolver.getTableAddress(attr.tableID)
		if tableAddress then
			skynet.send(tableAddress, "lua", "NotifyWorldBossTime", agent)
		end
	end
end


local conf = {
	methods = {
		["FishSpawn"] = {["func"]=cmd_FishSpawn, ["isRet"]=false},				
	},
}

commonServiceHelper.createService(conf)

