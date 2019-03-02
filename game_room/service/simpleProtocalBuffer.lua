local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local resourceResolver = require "resourceResolver"

local _packetBuf = {}

local inspect = require "inspect"

local function cmd_get(protocalNo)
	if not _packetBuf[protocalNo] then
		local protocalObj = {}
		if protocalNo == 0x000000 then
			protocalObj = { index = 127 }
		end
		local packetStr = skynet.call(resourceResolver.get("pbParser"), "lua", "encode", protocalNo, protocalObj, true)
		if packetStr and not _packetBuf[protocalNo] then
			_packetBuf[protocalNo] = packetStr
		end
	end
	
	--skynet.error("_packetBuf-\n",inspect(_packetBuf),"\n-")

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
