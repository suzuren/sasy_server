local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local resourceResolver = require "resourceResolver"

local _packetBuf = {}

local function cmd_get(protocalNo)
	if not _packetBuf[protocalNo] then
		local packetStr = skynet.call(resourceResolver.get("pbParser"), "lua", "encode", protocalNo, {}, true)
		if packetStr and not _packetBuf[protocalNo] then
			_packetBuf[protocalNo] = packetStr
		end
	end
	
	return _packetBuf[protocalNo]
end

local conf = {
	methods = {
		["get"] = {["func"]=cmd_get, ["isRet"]=true},
	},
	initFunc = function()
		resourceResolver.init()
	end,	
}

commonServiceHelper.createService(conf)
