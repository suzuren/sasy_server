local skynet = require "skynet"
local webServiceHelper = require "serviceHelper.web"
local uniformPlatformHttpUtility = require "utility.uniformPlatformHttp"
local jsonHttpResponseUtility = require "utility.jsonHttpResponse"
local addressResolver = require "addressResolver"
local ServerUserItem = require "sui"
require "utility.string"

local inspect = require "inspect"

local CMD = {}
function CMD.uniformpay(param)
	skynet.error("uniformpay - param-\n",inspect(param),"\n-")
	local isOK, appid, serverid, event = uniformPlatformHttpUtility.getUniformPlatformData(param.method, param.post)
	if not isOK then
		return jsonHttpResponseUtility.getSimpleResponse(isOK, appid)
	end

	if event.TYPE == "EVENT_PAY_ORDER_CONFIRM" then
		local isSuccess, msg = skynet.call(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "payOrderConfirm", event.DATA)
		
		if isSuccess then
			return jsonHttpResponseUtility.getSimpleResponse(true)
		else
			return jsonHttpResponseUtility.getSimpleResponse(false, msg)
		end
	else
		return jsonHttpResponseUtility.getSimpleResponse(false, "unknown event")
	end
end

function CMD.uniformother(param)
	skynet.error("uniformother - param-\n",inspect(param),"\n-")
	local isOK, appid, serverid, event = uniformPlatformHttpUtility.getUniformPlatformData(param.method, param.post)
	skynet.error("uniformother uniformPlatformHttpUtility - ", isOK, appid, serverid, event)
	if not isOK then
		return jsonHttpResponseUtility.getSimpleResponse(isOK, appid)
	end
	skynet.error("uniformother - event-\n",inspect(event),"\n-")
	if event.TYPE == "EVENT_ACCOUNT_SESSION" then
		local platformID = math.tointeger(event.DATA.UserID)
		local session = event.DATA.SessionID
		local userStatus = math.tointeger(event.DATA.UserStatus)
		local Tel = event.DATA.Phone

		skynet.send(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "registerSession", session, platformID, userStatus, Tel)
		return jsonHttpResponseUtility.getSimpleResponse(true)
	elseif event.TYPE == "EVENT_BIND_PHONE" then
		local platformID = math.tointeger(event.DATA.UserID)

		skynet.send(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "bindingAccount", platformID)

		local userItem = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getUserItemByPlatformID", platformID)
		if userItem then
			local userAttr = ServerUserItem.getAttribute(userItem, {"userID"})
			local messageTitle = string.format("绑定手机活动奖励邮件")
			local messageInfo = string.format("亲爱的玩家,这是您参与绑定手机活动,获得的奖励,请注意查收附件.祝您游戏愉快!")
			local itemList = {}
			local item = {
				goodsID = 1001,
				goodsCount = 20000
			}
			table.insert(itemList,item)

			skynet.send(addressResolver.getAddressByServiceName("LS_model_message"),"lua","sendEmailToUser",userAttr.userID,itemList,messageTitle,messageInfo)
		end

		return jsonHttpResponseUtility.getSimpleResponse(true)
	else
		return jsonHttpResponseUtility.getSimpleResponse(false, "unknown event")
	end
end

local conf = {
	methods = CMD,
	initFunc = function()
		local serverKeyString = skynet.getenv("uniformPlatformServerKey")
		if type(serverKeyString)~="string" then
			error(string.format("不正确的配置项 uniformPlatformServerKey: %s", tostring(serverKeyString)))
		end
		
		local hash = {}
		local list = serverKeyString:split(";")
		for _, item in pairs(list) do
			local itemPart = item:split(":")
			local appID = math.tointeger(itemPart[1])
			local serverID = math.tointeger(itemPart[2])
			local serverKey = itemPart[3]
			
			if appID==nil or serverID==nil or serverKey==nil then
				error(string.format("不正确的配置项 uniformPlatformServerKey: %s", tostring(serverKeyString)))
			end
			
			if type(hash[appID])~="table" then
				hash[appID] = {}
			end
			hash[appID][serverID] = serverKey
		end
		--skynet.error("conf - hash-\n",math.abs(os.time()),inspect(hash),"\n-")
		uniformPlatformHttpUtility.setUpServerKeyHash(hash)
	end,
}

webServiceHelper.createService(conf)
