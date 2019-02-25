local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"

local function cmd_reloadDefense()
	skynet.call(addressResolver.getAddressByServiceName("LS_model_serverManager"), "lua", "reloadDefenseList")
end

local conf = {
	methods = {
		["reloadDefense"] = {["func"]=cmd_reloadDefense, ["isRet"]=true},
	},
	initFunc = function()
	end,
}

commonServiceHelper.createService(conf)