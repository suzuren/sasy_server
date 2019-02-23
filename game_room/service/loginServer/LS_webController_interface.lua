local skynet = require "skynet"
local webServiceHelper = require "serviceHelper.web"
local addressResolver = require "addressResolver"
local jsonHttpResponseUtility = require "utility.jsonHttpResponse"
require "utility.string"

local inspect = require "inspect"

local _allowIPHash = {}

local function onlineView()
	local ret = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "viewOnline")
	skynet.error("onlineView-\n",inspect(ret),"\n-")
	return jsonHttpResponseUtility.getResponse({isSuccess=true, data=ret})
end

local function onlineQuery(post)
	local uidlist = post.uidlist
	if type(uidlist)~="string" or string.len(uidlist)==0 then
		return jsonHttpResponseUtility.getSimpleResponse(false, "invalid argument")
	end
	
	local userIDList = {}
	local temp = uidlist:split(",")
	for _, v in pairs(temp) do
		local iv = math.tointeger(v)
		if iv ~= nil then
			table.insert(userIDList, iv)
		end
	end
	
	if #userIDList==0 then
		return jsonHttpResponseUtility.getSimpleResponse(false, "no userID specified")
	end
	
	local ret = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "checkOnline", userIDList)
	return jsonHttpResponseUtility.getResponse({isSuccess=true, data=ret})
end

local function ping()
	return jsonHttpResponseUtility.getResponse({isSuccess=true})
end

local CMD = {}
function CMD.GetServerListStatus()
	local ret = skynet.call(addressResolver.getAddressByServiceName("LS_model_serverManager"), "lua", "GetServerListStatus")
	return jsonHttpResponseUtility.getResponse({isSuccess=true, data=ret})
end

function CMD.interface(param)
	skynet.error("interface - param-\n",inspect(param),"\n-")
	if string.lower(param.method) ~= "post" then
		return jsonHttpResponseUtility.getSimpleResponse(false, "request method not support")
	end	
	
	if not _allowIPHash[param.ipAddr] then
		return 403
	end
	
	local requestType = param.post.type
	--skynet.error(string.format("requestType-%s", requestType))
	if requestType=="onlineQuery" then
		return onlineQuery(param.post)
	elseif requestType=="ping" then
		return ping()
	elseif requestType=="onlineView" then
		return onlineView()
	elseif requestType == "presentToItem" then
		local isSuccess, msg = skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "presentToItem", param.post)
		return jsonHttpResponseUtility.getSimpleResponse(isSuccess, msg)
	elseif requestType == "delSystemEmail" then
		local isSuccess, msg = skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "delSystemEmail", param.post)
		return jsonHttpResponseUtility.getSimpleResponse(isSuccess, msg)
	elseif requestType == "editSystemEmail" then
		local isSuccess, msg = skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "editSystemEmail", param.post)
		return jsonHttpResponseUtility.getSimpleResponse(isSuccess, msg)
	elseif requestType == "addSystemEmail" then
		local isSuccess, msg = skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "addSystemEmail", param.post)
		return jsonHttpResponseUtility.getSimpleResponse(isSuccess, msg)
	elseif requestType == "addUserEmail" then
		local isSuccess, msg = skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "addUserEmail", param.post)
		return jsonHttpResponseUtility.getSimpleResponse(isSuccess, msg)
	elseif requestType == "delUserEmail" then
		local isSuccess, msg = skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "delUserEmail", param.post)
		return jsonHttpResponseUtility.getSimpleResponse(isSuccess, msg)
	elseif requestType == "changeScore" then
		local isSuccess, msg = skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "changeScore", param.post)
		return jsonHttpResponseUtility.getSimpleResponse(isSuccess, msg)
	elseif requestType == "kickUser" then
		local isSuccess, msg = skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "kickUser", param.post)
		return jsonHttpResponseUtility.getSimpleResponse(isSuccess, msg)
	elseif requestType == "changeControlRate" then
		local isSuccess, msg = skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "changeControlRate", param.post)
		return jsonHttpResponseUtility.getSimpleResponse(isSuccess, msg)
	elseif requestType == "addInvitationCode" then
		local isSuccess, msg = skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "addInvitationCode", param.post)
		return jsonHttpResponseUtility.getSimpleResponse(isSuccess, msg)
	elseif requestType == "changeDeduct" then
		local isSuccess, msg = skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "changeDeduct", param.post)
		return jsonHttpResponseUtility.getSimpleResponse(isSuccess, msg)
	elseif requestType == "hideSignature" then
		local isSuccess, msg = skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "hideSignature", param.post)
		return jsonHttpResponseUtility.getSimpleResponse(isSuccess, msg)
	else
		return jsonHttpResponseUtility.getSimpleResponse(false, "unknown request type")
	end
end

local conf = {
	methods = CMD,
	initFunc = function() 
		local allowIPList = skynet.getenv("httpInterfaceAllowIPList")
		if type(allowIPList)~="string" then
			error(string.format("invalid config entry httpInterfaceAllowIPList: %s", tostring(allowIPList)))
		end
		
		local ipList = allowIPList:split(",")
		for _, ip in pairs(ipList) do
			_allowIPHash[ip] = true
		end
	end,
}

webServiceHelper.createService(conf)
