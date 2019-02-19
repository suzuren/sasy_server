local skynet = require "skynet"
local PBCO = require "pbco"
local pbConfig = require "define.pbConfig"
--local skynetHelper = require "skynetHelper"
local commonServiceHelper = require "serviceHelper.common"

local _pb

local function decodeWrapper(protocalNo, pbBufferPtr, pbBufferSize, isDirectionReversed)
	return _pb:decode(protocalNo, pbBufferPtr, pbBufferSize, isDirectionReversed)
end

local function encodeWrapper(protocalNo, pbObj, returnString)
	return _pb:encode2netPacket(protocalNo, pbObj, returnString)
end

local function doDecode(protocalNo, pbBufferPtr, pbBufferSize, isDirectionReversed)
	--[[
	skynet.error(string.format(
		"pbParser decode: %s\t%s\t%s\n%s",
		tostring(protocalNo),
		tostring(pbBufferPtr),
		tostring(pbBufferSize),
		skynetHelper.dumpHex(pbBufferPtr, pbBufferSize)
	))
	--]]

	local isOK, pbObj = pcall(decodeWrapper, protocalNo, pbBufferPtr, pbBufferSize, isDirectionReversed)
	if not isOK then
		skynet.error(string.format("%s.decode error protocalNo=0x%06X: %s", SERVICE_NAME, protocalNo, pbObj))
		pbObj = nil
	end
	return pbObj
end


local function cmd_start(mode)
	if not _pb then
		_pb = PBCO:new(skynet.getenv("pbs_dir"))
	end
	
	local conf = pbConfig.getConfig(mode)
	_pb:config(conf.c2s, conf.s2c, conf.files)
end

local function cmd_decode(protocalNo, pbBufferPtr, pbBufferSize)
	return doDecode(protocalNo, pbBufferPtr, pbBufferSize)
end

local function cmd_reverseDecode(protocalNo, pbBufferPtr, pbBufferSize)
	return doDecode(protocalNo, pbBufferPtr, pbBufferSize, true)
end

local function cmd_encode(protocalNo, pbObj, returnStr)
	local isOK, resultMsg, resultSz = pcall(encodeWrapper, protocalNo, pbObj, returnStr)
	if not isOK then
		skynet.error(string.format("%s.encode error protocalNo=0x%06X: %s", SERVICE_NAME, protocalNo, resultMsg))
		return nil
	end
	
	return resultMsg, resultSz
end

local conf = {
	methods = {
		["start"] = {["func"]=cmd_start, ["isRet"]=true},
		["decode"] = {["func"]=cmd_decode, ["isRet"]=true},
		["reverseDecode"] = {["func"]=cmd_reverseDecode, ["isRet"]=true},
		["encode"] = {["func"]=cmd_encode, ["isRet"]=true},
	}
}

commonServiceHelper.createService(conf)
