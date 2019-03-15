require "utility.string"
local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local COMMON_CONST = require "define.commonConst"
local mysqlutil = require "mysqlutil"
local ServerUserItem = require "sui"
local resourceResolver = require "resourceResolver"
local wordFilterUtility = require "wordfilter"
local timerUtility = require "utility.timer"

local chatDataHash = {}

local function loadChatData()
	local sql = "SELECT `Id`,`UserId`,`UserName`,`Gender`,`VipLevel`,`Content`,`GoodsInfo`,UNIX_TIMESTAMP(`WordTime`) as \"WordTime\" FROM `kfrecorddb`.`t_word_record` where TIMESTAMPDIFF(HOUR,WordTime, NOW()) < 24 ORDER BY Id DESC LIMIT 20"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn,"lua","query",sql)
	if type(rows)=="table" then
		for _, row in pairs(rows) do
			local message ={
				userIcon = tonumber(row.Gender),
				sendUserID = tonumber(row.UserId),
				sendUserVip = tonumber(row.VipLevel),
				sendNickname = row.UserName,
				content = row.Content,
				userGoodsItem = {},
				wordTime = tonumber(row.WordTime)
			}

			local list = row.GoodsInfo:split("|")
			for _, item in pairs(list) do
				local itemPart = item:split(":")
				local goods = {
					goodsID = itemPart[1],
					goodsCount = itemPart[2]
				}
				table.insert(message.userGoodsItem,goods)
			end

			table.insert(chatDataHash,message)
		end
	end
end	

local function cmd_SendMessageBoardInfo(pbObj,tcpAgentData)
	local re = { 
		code = 0 
	}

	local attr = ServerUserItem.getAttribute(tcpAgentData.sui,{"agent","userID","memberOrder","nickName","gender"})
	if attr.memberOrder < 2 then
		re.code = 1
		return re
	end
	
	-- local itemCount = skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "GetItemCount",tcpAgentData.userID,COMMON_CONST.ITEM_ID.ITEM_ID_JEWEL)
	-- if itemCount < 100 then
	-- 	re.code = 2
	-- 	return re
	-- end

	local itemCountGold = skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "GetItemCount",tcpAgentData.userID,COMMON_CONST.ITEM_ID.ITEM_ID_GOLD)
	if itemCountGold < 100000 then
		re.code = 5
		return re
	end

	if string.len(pbObj.content) > 180 then
		re.code = 3
		return re
	end

	local swfObj = resourceResolver.get("sensitiveWordFilter")
	if wordFilterUtility.hasMatch(swfObj, pbObj.content) then
		re.code = 4
		return re
	end	

	--skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",tcpAgentData.userID,COMMON_CONST.ITEM_ID.ITEM_ID_JEWEL,-100,COMMON_CONST.ITEM_SYSTEM_TYPE.MESSAGE_BOARD)
	skynet.send(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "ChangeItemCount",tcpAgentData.userID,COMMON_CONST.ITEM_ID.ITEM_ID_GOLD,-100000,COMMON_CONST.ITEM_SYSTEM_TYPE.MESSAGE_BOARD)

	local message = {
		userIcon = attr.gender,
		sendUserID = attr.userID,
		sendUserVip = attr.memberOrder,
		sendNickname = attr.nickName,
		content = pbObj.content,
		userGoodsItem = {},
		wordTime = os.time()
	}

	local goal = ""
	local goods1 = {
		goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_SILVE_BOX,
		goodsCount = skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "GetItemCount",tcpAgentData.userID,COMMON_CONST.ITEM_ID.ITEM_ID_SILVE_BOX)
	}
	goal = goal..tostring(goods1.goodsID)..":"..tostring(goods1.goodsCount).."|" 
	table.insert(message.userGoodsItem,goods1)

	local goods2 = {
		goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_GOLD_BOX,
		goodsCount = skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "GetItemCount",tcpAgentData.userID,COMMON_CONST.ITEM_ID.ITEM_ID_GOLD_BOX)
	}
	goal = goal..tostring(goods2.goodsID)..":"..tostring(goods2.goodsCount).."|"
	table.insert(message.userGoodsItem,goods2)

	local goods3 = {
		goodsID = COMMON_CONST.ITEM_ID.ITEM_ID_PT_BOX,
		goodsCount = skynet.call(addressResolver.getAddressByServiceName("LS_model_bag"), "lua", "GetItemCount",tcpAgentData.userID,COMMON_CONST.ITEM_ID.ITEM_ID_PT_BOX)
	}
	goal = goal..tostring(goods3.goodsID)..":"..tostring(goods3.goodsCount).."|"
	table.insert(message.userGoodsItem,goods3)
	
	table.insert(chatDataHash,1,message)
	if #chatDataHash > 20 then
		table.remove(chatDataHash)
	end

	local nowtime = os.date('%Y-%m-%d %H:%M:%S', os.time())
	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("insert into `kfrecorddb`.`t_word_record`(UserId,UserName,Gender,VipLevel,Content,GoodsInfo,WordTime) values(%d,'%s',%d,%d,'%s','%s','%s')",
			attr.userID,mysqlutil.escapestring(attr.nickName),attr.gender,attr.memberOrder,mysqlutil.escapestring(pbObj.content),mysqlutil.escapestring(goal),mysqlutil.escapestring(nowtime))
	skynet.call(dbConn, "lua", "query", sql)

	local userList = skynet.call(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "getAllUserInfo")
	local sendlist = {}
	table.insert(sendlist,message)
	for _, v in pairs(userList) do 
		local attrr = ServerUserItem.getAttribute(v.sui,{"agent","userID","nickName"})
		local nickName = COMMON_CONST.HideNickName(attr.nickName)
		if attrr.agent ~= 0 then
			skynet.send(attrr.agent,"lua","forward",0x004002,{messageBoardItemInfo=sendlist})
			skynet.send(attrr.agent, "lua", "forward", 0xff0000, {
				type = COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_GLOBAL,
				msg = nickName ..":".. pbObj.content,
			})

			skynet.send(attrr.agent, "lua", "forward", 0xff0000, {
				type = COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_GLOBAL,
				msg = nickName ..":".. pbObj.content,
			})

			skynet.send(attrr.agent, "lua", "forward", 0xff0000, {
				type = COMMON_CONST.SYSTEM_MESSAGE_TYPE.SMT_GLOBAL,
				msg = nickName ..":".. pbObj.content,
			})
		end
	end

	return re
end

local function cmd_MessageBoardInfoList(agent)
	skynet.send(agent,"lua","forward",0x004001,{messageBoardItemInfo=chatDataHash})
end

local function onCheckWordOverdue()
	local nowTick = os.time()
	for i = #chatDataHash, 1, -1 do
		if nowTick - chatDataHash[i].wordTime > 24*60*60 then
			table.remove(chatDataHash,i)
		end
	end
end

local conf = {
	methods = {
		["SendMessageBoardInfo"] = {["func"]=cmd_SendMessageBoardInfo, ["isRet"]=true},
		["MessageBoardInfoList"] = {["func"]=cmd_MessageBoardInfoList, ["isRet"]=false},						
	},

	initFunc = function()
		loadChatData()
		resourceResolver.init()
		timerUtility.start(100)
		timerUtility.setInterval(onCheckWordOverdue, 60)
	end,
}

commonServiceHelper.createService(conf)

