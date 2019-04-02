local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local LS_EVENT = require "define.eventLoginServer"
local inspect = require "inspect"

local _serverResponseHash = {}

local function checkMsg(responseItem)
	if responseItem.responser and #(responseItem.msgBuffer) > 0  then
		local responser = responseItem.responser
		local msgList = responseItem.msgBuffer
		responseItem.responser = nil
		responseItem.msgBuffer = {}
		-- 记录下请求的 source 和 session ，之后发送消息
		-- skynet.response 返回的函数，第一个参数是 true 或 false ，后面是回应的参数。当第一个参数是 false 时，会反馈给调用方一个异常；true 则是正常的回应。

		skynet.error(string.format("%s checkMsg func - ",SERVICE_NAME),"msgList-\n",inspect(msgList))

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

	skynet.error(string.format("%s cmd_gs_pull func - responseItem ", SERVICE_NAME),responseItem)

	if responseItem==nil or responseItem.sign~=sign then
		error(string.format("%s: 服务器还没有注册 serverID=%s sign=%s", SERVICE_NAME, tostring(serverID), tostring(sign)))
	else
		--skynet.error(string.format("%s cmd_gs_pull func - responseItem\n", SERVICE_NAME),inspect(responseItem))

		if responseItem.responser~=nil then
			responseItem.responser(false)
		end

		responseItem.responser = skynet.response()
		--skynet.error(string.format("%s cmd_gs_pull func - responseItem.responser ", SERVICE_NAME),responseItem.responser)

		checkMsg(responseItem)
	end
end

local function cmd_onEventGameServerConnect(data)
	_serverResponseHash[data.serverID] = {
		responser = nil,
		msgBuffer = {},
		sign = data.sign,
	}

	local responseItem = _serverResponseHash[data.serverID]
	local msgData={ index = 0, status = "server_connect",	tips = "hello world",}
	table.insert(responseItem.msgBuffer, {msgNo = 0, msgData = msgData})
	skynet.error(string.format("%s cmd_onEventGameServerConnect func - _serverResponseHash\n", SERVICE_NAME),inspect(_serverResponseHash))
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

