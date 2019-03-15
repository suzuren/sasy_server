local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local LS_EVENT = require "define.eventLoginServer"

local _serverResponseHash = {}

local function checkMsg(responseItem)
	if responseItem.responser and #(responseItem.msgBuffer) > 0  then
		local responser = responseItem.responser
		local msgList = responseItem.msgBuffer
		responseItem.responser = nil
		responseItem.msgBuffer = {}
		responser(true, msgList)
	end
end

local function sendMsgToServer(serverID, msgNo, msgData)
	local responseItem = _serverResponseHash[serverID]
	if responseItem==nil then
		return
	end
	
	table.insert(responseItem.msgBuffer, {msgNo=msgNo, msgData=msgData})
	if #(responseItem.msgBuffer) > 100 then
		table.remove(responseItem.msgBuffer, 1)
	end
	
	checkMsg(responseItem)
end

local function cmd_send(serverIDList, msgNo, msgData)
--[[	
	do
		local jsonUtil = require "cjson.util"
		skynet.error(SERVICE_NAME, "send", jsonUtil.serialise_value(serverIDList), msgNo, jsonUtil.serialise_value(msgData))
	end
--]]	
	for _, serverID in ipairs(serverIDList) do
		sendMsgToServer(serverID, msgNo, msgData)
	end
end

local function cmd_gs_pull(serverID, sign)
	local responseItem = _serverResponseHash[serverID]
	if responseItem==nil or responseItem.sign~=sign then
		error(string.format("%s: 服务器还没有注册 serverID=%s sign=%s", SERVICE_NAME, tostring(serverID), tostring(sign)))
	else
		if responseItem.responser~=nil then
			responseItem.responser(false)
		end
		responseItem.responser = skynet.response()
		checkMsg(responseItem)
	end
end

local function cmd_onEventGameServerConnect(data)
	_serverResponseHash[data.serverID] = {
		responser = nil,
		msgBuffer = {},
		sign = data.sign,
	}
end

local function cmd_onEventGameServerDisconnect(data)
	_serverResponseHash[data.serverID] = nil
end

local conf = {
	methods = {
		["send"] = {["func"]=cmd_send, ["isRet"]=false},
		["gs_pull"] = {["func"]=cmd_gs_pull, ["isRet"]=false},
		
		["onEventGameServerConnect"] = {["func"]=cmd_onEventGameServerConnect, ["isRet"]=false},
		["onEventGameServerDisconnect"] = {["func"]=cmd_onEventGameServerDisconnect, ["isRet"]=false},
	},
	initFunc = function()
		skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "addEventListener", LS_EVENT.EVT_LS_GAMESERVER_CONNECT, skynet.self(), "onEventGameServerConnect")
		skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "addEventListener", LS_EVENT.EVT_LS_GAMESERVER_DISCONNECT, skynet.self(), "onEventGameServerDisconnect")
	end,
}

commonServiceHelper.createService(conf)

