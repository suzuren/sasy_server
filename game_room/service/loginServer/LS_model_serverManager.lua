local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"
local timerUtility = require "utility.timer"
local signUtility = require "utility.sign"
local LS_EVENT = require "define.eventLoginServer"
local COMMON_CONST = require "define.commonConst"
local ServerUserItem = require "sui"
local arc4 = require "arc4random"
local sysConfig = require "sysConfig"


local _timeoutThresholdTick
local _kindHash = {}
local _nodeHash = {}
local _serverHash = {}
local _serverMatchOption = {}
local _serverListStatus = {}

local defenseList = nil

local function sortIDComparer(a, b)
	return a.sortID < b.sortID;
end

local function sortBySortID(idList, id2Item)
	--用户处理idList中可能的重复
	local idHash = {}
	
	local itemList = {}
	for _, id in ipairs(idList) do
		if id2Item[id] and not idHash[id] then
			idHash[id] = true
			table.insert(itemList, id2Item[id])
		end
	end
	table.sort(itemList, sortIDComparer)
	local dstIDList = {}
	for _, item in ipairs(itemList) do
		table.insert(dstIDList, item.id)
	end
	return dstIDList
end

local function deleteServer(serverItem)
	local shallDeleteNode = false
	local shallDeleteKind = false

	local nodeItem = _nodeHash[serverItem.nodeID]
	if #(nodeItem.serverIDList) == 1 and nodeItem.serverIDList[1] == serverItem.id then
		shallDeleteNode = true
	end
	
	local kindItem = _kindHash[serverItem.kindID]
	if shallDeleteNode then
		if #(kindItem.nodeIDList) == 1 and kindItem.nodeIDList[1] == serverItem.nodeID then
			shallDeleteKind = true
		end
	end
	
	skynet.error(string.format("delete server %s", _serverHash[serverItem.id].name))
	_serverMatchOption[serverItem.id] = nil
	_serverHash[serverItem.id] = nil

	_serverListStatus[tostring(serverItem.id)] = false
	
	if shallDeleteNode then
		skynet.error(string.format("delete node %s", nodeItem.name))
		_nodeHash[serverItem.nodeID] = nil
	else
		nodeItem.onlineCount = nodeItem.onlineCount - serverItem.onlineCount
		nodeItem.fullCount = nodeItem.fullCount - serverItem.fullCount
		nodeItem.serverIDList = sortBySortID(nodeItem.serverIDList, _serverHash)	
	end	
	
	
	if shallDeleteKind then
		skynet.error(string.format("delete kind %s", kindItem.name))
		_kindHash[serverItem.kindID] = nil
	else
		kindItem.onlineCount = kindItem.onlineCount - serverItem.onlineCount
		kindItem.fullCount = kindItem.fullCount - serverItem.fullCount
		kindItem.nodeIDList = sortBySortID(kindItem.nodeIDList, _nodeHash)
	end
	skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "dispatch", LS_EVENT.EVT_LS_GAMESERVER_DISCONNECT, {serverID=serverItem.id})
end

local function checkServerTick()
	local nowTick = skynet.now()
	for serverID, serverItem in pairs(_serverHash) do
		if nowTick - serverItem.tick > _timeoutThresholdTick then
			deleteServer(serverItem)
		end
	end
end

local function sendNodeServerList(kindIDList, agent)
	local nodeList = {list={}}
	for k, kindID in ipairs(kindIDList) do
		local kindItem = _kindHash[kindID] 
		if kindItem then
			for _, nodeID in ipairs(kindItem.nodeIDList) do		
				local nodeItem = _nodeHash[nodeID]
				
				local pbListItem={
					nodeID=nodeItem.id,
					kindID=nodeItem.kindID,
					name=nodeItem.name,
					onlineCount=nodeItem.onlineCount,
					fullCount=nodeItem.fullCount,
					serverList={}
				}
				
				for _, serverID in ipairs(nodeItem.serverIDList) do
					local serverItem = _serverHash[serverID]
					if serverItem then
						table.insert(pbListItem.serverList, {
							serverID=serverItem.id,
							serverType=serverItem.type,
							serverAddr=serverItem.ip,
							serverPort=serverItem.port,
							serverName=serverItem.name,
							cellScore=serverItem.cellScore,
							maxEnterScore=serverItem.maxEnterScore,
							minEnterScore=serverItem.minEnterScore,
							minEnterMember=serverItem.minEnterMember,
							maxEnterMember=serverItem.maxEnterMember,
							onlineCount = serverItem.onlineCount,
							fullCount = serverItem.fullCount,
						})
					end
				end
				table.insert(nodeList.list, pbListItem)			
			end
		end
	end
	skynet.send(agent, "lua", "forward", 0x000200, nodeList)
end

local function sendMatchOption(kindIDList, agent)
	local configList={list={}}
	for k, kindID in pairs(kindIDList) do
		for serverID, item in pairs(_serverMatchOption) do
			if item.kindID == kindID then
				table.insert(configList.list, item.data)
			end
		end
	end
	
	if #(configList.list) > 0 then
		skynet.send(agent, "lua", "forward", 0x000201, configList)
	end
end

local function getServerIDListByNodeID(nodeID)
	local nodeItem = _nodeHash[nodeID]
	if nodeItem then
		if #(nodeItem.serverIDList) > 0 then
			return nodeItem.serverIDList
		end
	end
end

local function getServerIDListByKindID(kindID)
	local kindItem = _kindHash[kindID]
	if kindItem then
		local list = {}
		for _, nodeID in ipairs(kindItem.nodeIDList) do
			local nodeServerIDList = getServerIDListByNodeID(nodeID)
			if nodeServerIDList then
				for _, serverID in ipairs(nodeServerIDList) do
					table.insert(list, serverID)
				end
			end
		end
		
		if #list > 0 then
			return list
		end
	end
	return 
end


local function cmd_gs_registerServer(data)
--[[
data={
	kindID=,
	nodeID=,
	sortID=,
	serverID=,
	serverIP=,
	serverPort=,
	serverType=,
	serverName=,
	onlineCount=,
	fullCount=,
	cellScore=,
	maxEnterScore=,
	minEnterScore=,
	minEnterMember=,
	maxEnterMember=,
}
--]]
	if _serverHash[data.serverID] then
		error(string.format("服务器已经注册 serverID=%d", data.serverID))

		local serverItem = _serverHash[data.serverID]

		skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "dispatch", LS_EVENT.EVT_LS_GAMESERVER_CONNECT, {serverID=serverItem.id, sign=serverItem.sign})
		return serverItem.sign
	end

	local kindItem = _kindHash[data.kindID]
	local nodeItem = _nodeHash[data.nodeID]
	if not kindItem then
		--local sql = string.format("select * from `kfplatformdb`.`GameKindItem` where KindID=%d", data.kindID)
		--local dbConn = addressResolver.getMysqlConnection()
		--local rows = skynet.call(dbConn, "lua", "query", sql)

		local rows =
		{
			{
				KindID = 2010,
				KindName = "李逵捕鱼",
			}
		}
		if #rows ~= 1 then
			error(string.format("kindID=%d not found", data.kindID))
		end
		local row=rows[1]
		kindItem = {
			id = tonumber(row.KindID),
			name = row.KindName,
			onlineCount = 0,
			fullCount = 0,
			nodeIDList = {}
		}
	end
	
	if not nodeItem then
		--local sql = string.format("select * from `kfplatformdb`.`GameNodeItem` where NodeID=%d", data.nodeID)
		--local dbConn = addressResolver.getMysqlConnection()
		--local rows = skynet.call(dbConn, "lua", "query", sql)

		local rows =
		{
			{
				NodeID = 1100,
				KindID = 2010,
				SortID = 1,
				NodeName = "李逵捕鱼初级场",
			}
		}

		if #rows ~= 1 then
			error(string.format("nodeID=%d not found", data.nodeID))
		end
		local row=rows[1]
		nodeItem = {
			kindID = tonumber(row.KindID),
			id = tonumber(row.NodeID),
			name = row.NodeName,
			onlineCount = 0,
			fullCount = 0,
			sortID = tonumber(row.SortID),
			serverIDList = {}
		}
		_nodeHash[data.nodeID] = nodeItem
	end
	
	if not _kindHash[data.kindID] then
		_kindHash[data.kindID] = kindItem
	end
	
	local serverItem = {
		kindID = data.kindID,
		nodeID = data.nodeID,
		sortID = data.sortID,
		id = data.serverID,
		ip = data.serverIP,
		port = data.serverPort,
		name = data.serverName,
		type = data.serverType,
		cellScore = data.cellScore,
		maxEnterScore = data.maxEnterScore,
		minEnterScore = data.minEnterScore,
		minEnterMember = data.minEnterMember,
		maxEnterMember = data.maxEnterMember,
		onlineCount = data.onlineCount,
		fullCount = data.fullCount,
		tick = skynet.now(),
		sign = signUtility.getSign(),
	}
	_serverHash[data.serverID] = serverItem
	_serverListStatus[tostring(data.serverID)] = true

	kindItem.onlineCount = kindItem.onlineCount + serverItem.onlineCount
	kindItem.fullCount = kindItem.fullCount + serverItem.fullCount
	nodeItem.onlineCount = nodeItem.onlineCount + serverItem.onlineCount
	nodeItem.fullCount = nodeItem.fullCount + serverItem.fullCount
	
	table.insert(kindItem.nodeIDList, data.nodeID)
	kindItem.nodeIDList = sortBySortID(kindItem.nodeIDList, _nodeHash)
	table.insert(nodeItem.serverIDList, data.serverID)
	nodeItem.serverIDList = sortBySortID(nodeItem.serverIDList, _serverHash)
	
	skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "dispatch", LS_EVENT.EVT_LS_GAMESERVER_CONNECT, {serverID=serverItem.id, sign=serverItem.sign})
	return serverItem.sign
end

local function cmd_gs_registerMatch(sign, kindID, data)
	local serverItem = _serverHash[data.serverID]
	if serverItem and serverItem.sign==sign then
		--将每张桌子的椅子数量注销
		local chairPerTable = data.chairPerTable
		data.chairPerTable = nil
		_serverMatchOption[data.serverID] = {kindID=kindID, data=data}
	else
		error(string.format("注册比赛信息失败 serverID=%s", tostring(data.serverID)))
	end
	--比赛场初始信息
	skynet.send(addressResolver.getAddressByServiceName("LS_model_matchManager"), "lua", "initMatchInfo", data.serverID, chairPerTable)
end

local function cmd_gs_reportOnline(sign, serverID, onlineCount)
	--skynet.error("reprotOnline", serverID, onlineCount)
	local serverItem = _serverHash[serverID]
	if serverItem and serverItem.sign==sign then
		local oldServerOnlineCount = serverItem.onlineCount
		serverItem.onlineCount = onlineCount
		serverItem.tick = skynet.now()

		if onlineCount == 0 then
			_serverListStatus[tostring(serverID)] = false
		else
			_serverListStatus[tostring(serverID)] = true
		end
		
		local nodeItem = _nodeHash[serverItem.nodeID]
		if nodeItem then
			nodeItem.onlineCount = nodeItem.onlineCount - oldServerOnlineCount + onlineCount
		end
		
		local kindItem = _kindHash[serverItem.kindID]
		if kindItem then
			kindItem.onlineCount = kindItem.onlineCount - oldServerOnlineCount + onlineCount
		end
		
		return true
	else
		return false
	end
end

local function cmd_gs_relay(sourceServerID, sign, targetKindID, targetNodeID, targetServerID, msgNo, msgBody)
	local sourceServerItem = _serverHash[sourceServerID]
	if not sourceServerItem or sourceServerItem.sign~=sign then
		error("服务器还没有注册")
	end
	
	
	if targetServerID then							--指定服务器
		if _serverHash[targetServerID] then
			skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", {targetServerID}, msgNo, msgBody)
		else
			skynet.error(string.format("找不到指定的服务器: targetServerID=%s, sourceServerID=%s", tostring(targetServerID), tostring(sourceServerID)))
		end
	elseif targetNodeID then						--指定节点
		local sidList = getServerIDListByNodeID(targetNodeID)
		if sidList then
			skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", sidList, msgNo, msgBody)
		else
			skynet.error(string.format("找不到指定的服务器: targetNodeID=%s, sourceServerID=%s", tostring(targetNodeID), tostring(sourceServerID)))
		end
		
	elseif targetKindID then						--指定游戏
		local sidList = getServerIDListByKindID(targetKindID)
		if sidList then
			skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", sidList, msgNo, msgBody)
		else
			skynet.error(string.format("找不到指定的服务器: targetKindID=%s, sourceServerID=%s", tostring(targetKindID), tostring(sourceServerID)))
		end
	else											--全部服务器
		-- local sidList = {}
		-- for serverID, _ in pairs(_serverHash) do
		-- 	table.insert(sidList, serverID)
		-- end
		
		-- if #sidList> 0 then
		-- 	skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", sidList, msgNo, msgBody)
		-- end

		skynet.send(addressResolver.getAddressByServiceName("LS_model_sessionManager"), "lua", "sendSystemMessage",msgBody.msg)
	end
end

local function cmd_reloadConfig(data)
	defenseList = data
end

local function sendUserAddr(userID, platformID, agent, contribution)
	local beforeIp 
	local ipAddr
	local ip
	local isDubiousUser = false 
	local inDubiousUser = false

	local ip_level_dubious = -1;
	local ip_level_new = 0;
	local ip_level_normal = 1;
	local ip_level_vip1 = 2;
	local ip_level_vip2 = 3;
	local ip_level = ip_level_new;

	local curAllSumDay = 0
	local curGold = 0
	local rescueCoin = 0
	local sumRMB = contribution
	if sumRMB == nil then
		sumRMB = 0;
	end

	local dbConn = addressResolver.getMysqlConnection()

	if defenseList then
		local sql = string.format("select Ip,UserIp FROM `kffishdb`.`t_user_ip` where UserId = %d", userID)
		local rowss = skynet.call(dbConn, "lua", "query", sql)
		if rowss[1] ~= nil then
			beforeIp = rowss[1].Ip
			local userIp = rowss[1].UserIp
			if userIp ~= nil then
				ipAddr = userIp
				ip = beforeIp
				ip_level = ip_level_dubious
			end
		end

		sql = string.format("select * FROM `kffishdb`.`t_dubious_user` where UserId = %d", userID)
		local rowss = skynet.call(dbConn, "lua", "query", sql)
		if rowss[1] ~= nil then
			local ID = tonumber(rowss[1].UserId)
			if ID ~= nil then
				inDubiousUser = true
			end
		end


		sql = string.format("select AllSumDay FROM `kffishdb`.`t_signin` where UserId = %d", userID)
		local rowss = skynet.call(dbConn, "lua", "query", sql)
		if rowss[1] ~= nil then
			curAllSumDay = tonumber(rowss[1].AllSumDay)
			if curAllSumDay == nil then
				curAllSumDay = 0
			end
		end


		sql = string.format("select SUM(1) AS Count FROM `kfrecorddb`.`rescue_coin` where UserId = %d", userID)
		local rowss = skynet.call(dbConn, "lua", "query", sql)
		if rowss[1] ~= nil then
			rescueCoin = tonumber(rowss[1].Count)
			if rescueCoin == nil then
				rescueCoin = 0
			end
		end

		if not ipAddr then
			for i, v in ipairs(defenseList.vipList) do
				if sumRMB >= v.RMB then
					ipAddr = v.ipAddr
					ip = v.ip
					if i==1 then
						ip_level = ip_level_vip2
					else
						ip_level = ip_level_vip1
					end
					break
				end
			end
		end

		if not ipAddr then
			sql = string.format("select ItemCount FROM `kffishdb`.`t_bag` where UserId = %d and ItemId=1001", userID)
			local rowss = skynet.call(dbConn, "lua", "query", sql)
			if rowss[1] ~= nil then
				curGold = tonumber(rowss[1].ItemCount)
				if curGold == nil then
					curGold = 0
				end
			end

			for k, v in ipairs(defenseList.normalList) do 
				if (curGold >= v.Gold and curAllSumDay >= v.Sign and rescueCoin >= v.RescueCoin) or sumRMB >= v.RMB then
					ipAddr = v.ipAddr
					ip = v.ip
					ip_level = ip_level_normal
					break
				end
			end
		end

		if not ipAddr then
			for kk, vv in ipairs(defenseList.dubiousList) do 
				if vv.StartUserId <= userID and userID <= vv.EndUserId then
					ipAddr = vv.ipAddr
					ip = vv.ip
					isDubiousUser = true
					ip_level = ip_level_dubious
					break
				end
			end
		end	

		if not ipAddr then
			for kk, vv in ipairs(defenseList.newList) do 
				if curAllSumDay >= vv.Sign and rescueCoin >= vv.RescueCoin then
					ipAddr = vv.ipAddr
					ip = vv.ip
					ip_level = ip_level_new
					break
				end
			end
		end
	end

	if ipAddr then
		local MachineID = nil
		local VipLv = 0;
		local sql = string.format("select `LastLogonMachine`, `MemberOrder` FROM `kfaccountsdb`.`accountsinfo` where UserID = %d", userID)
		local rowss = skynet.call(dbConn, "lua", "query", sql)
		if rowss[1] ~= nil then
			MachineID = rowss[1].LastLogonMachine
			VipLv =  tonumber(rowss[1].MemberOrder)
		end		

		if MachineID and MachineID ~= "" then
			local sql = string.format("select `ConnectIpLV`, `BlackListFlag`, `VipLevel` FROM `kffishdb`.`t_logon_ip_lv` where LogonMachine = '%s'", MachineID)
			local rowss = skynet.call(dbConn, "lua", "query", sql)
			if rowss[1] ~= nil then
				local sqlTopIplv = tonumber(rowss[1].ConnectIpLV)
				local blackListFlag = tonumber(rowss[1].BlackListFlag)
				local sqlVipLv = tonumber(rowss[1].VipLevel)
				if VipLv < sqlVipLv then
					VipLv = sqlVipLv
				end
				if blackListFlag==1 or ip_level==ip_level_dubious then
					blackListFlag=1
				end
				if VipLv>=1 then
					blackListFlag=0
				elseif blackListFlag==1 then
					for kk, vv in ipairs(defenseList.dubiousList) do 
						if vv.StartUserId <= userID and userID <= vv.EndUserId then
							ipAddr = vv.ipAddr
							ip = vv.ip
							isDubiousUser = true
							ip_level = ip_level_dubious
							break
						end
					end
				end

				if sqlTopIplv < ip_level then
					sqlTopIplv = ip_level
				elseif sqlTopIplv > ip_level_new  and blackListFlag==0 then
					if sqlTopIplv == ip_level_normal then
						for k, v in ipairs(defenseList.normalList) do 
							if (curGold >= v.Gold and curAllSumDay >= v.Sign and rescueCoin >= v.RescueCoin) or sumRMB >= v.RMB then
								ipAddr = v.ipAddr
								ip = v.ip
								break
							end
						end				
					elseif sqlTopIplv == ip_level_vip1 then
						for i, v in ipairs(defenseList.vipList) do
							if i==2 then
								ipAddr = v.ipAddr
								ip = v.ip
							end
						end					
					elseif sqlTopIplv == ip_level_vip2 then
						for i, v in ipairs(defenseList.vipList) do
							if i==1 then
								ipAddr = v.ipAddr
								ip = v.ip
							end
						end						
					end
				end

				local sql = string.format("UPDATE `kffishdb`.`t_logon_ip_lv` SET ConnectIpLV = %d , `BlackListFlag`= %d, `VipLevel`= %d WHERE LogonMachine = '%s'",sqlTopIplv,blackListFlag,VipLv,MachineID)
				skynet.call(dbConn, "lua", "query", sql)

			else 
				local blackListFlag = 0
				if ip_level == ip_level_dubious then
					blackListFlag=1
				end
				local sql = string.format("insert into `kffishdb`.`t_logon_ip_lv` (`LogonMachine`,`ConnectIpLV`, `BlackListFlag`, `VipLevel`) VALUES('%s',%d,%d,%d) ",MachineID,ip_level,blackListFlag,VipLv)
				-- local sql = string.format("insert into `kffishdb`.`t_logon_ip_lv` (`LogonMachine`,`ConnectIpLV`, `BlackListFlag`, `VipLevel`) VALUES('%s',%d,%d,%d) ON DUPLICATE KEY UPDATE ConnectIpLV=%d",MachineID,ip_level,blackListFlag,VipLv,ip_level)
				skynet.call(dbConn, "lua", "query", sql)

			end	
		end


		if agent then
			skynet.send(agent, "lua", "forward", 0x000299, {ip=ipAddr})
		end

		local sql = string.format("insert into `kffishdb`.`t_user_ip` (`UserId`,`Ip`,`LoginTime`) VALUES(%d,'%s',NOW()) ON DUPLICATE KEY UPDATE ip='%s',LoginTime=NOW()",userID,ip,ip)
		skynet.call(dbConn, "lua", "query", sql)

		if inDubiousUser and not isDubiousUser then
			sql = string.format("DELETE FROM `kffishdb`.`t_dubious_user` WHERE UserId = %d",userID)
			skynet.call(dbConn, "lua", "query", sql)
		end
	else
		skynet.send(agent, "lua", "forward", 0x000299, {ip=""})
	end
end

local function cmd_onEventLoginSuccess(data)
	sendNodeServerList(data.kindID, data.agent)
	sendMatchOption(data.kindID, data.agent)
	sendUserAddr(data.userID, data.platformID, data.agent, data.contribution )

	--登入的时候发送签到信息给客户端
	skynet.send(addressResolver.getAddressByServiceName("LS_model_signin"), "lua", "SigninListInfo", data.agent, data.userID)
	skynet.send(addressResolver.getAddressByServiceName("LS_model_chat"), "lua", "MessageBoardInfoList", data.agent)
	skynet.send(addressResolver.getAddressByServiceName("LS_model_pay"), "lua", "notifyVipInfo", data.agent,data.userID,data.contribution)
end

local function cmd_sendServerOnline(agent, serverIDList)
	local list = {}
	for _, serverID in ipairs(serverIDList) do
		local item = {serverID=serverID, onLineCount=0}
		local serverItem = _serverHash[serverID]
		if serverItem then
			item.onLineCount = serverItem.onlineCount
		end
		table.insert(list, item)
	end
	
	skynet.send(agent, "lua", "forward", 0x000202, {list=list})
end

local function cmd_getServerName(serverID)
	local item = _serverHash[serverID]
	if item then
		return string.format("%s-%s", _kindHash[item.kindID].name, _nodeHash[item.nodeID].name)
	else
		return "其他游戏"
	end
end

local function cmd_getMatchServerInfo(serverID)
	-- 获取比赛场信息
	local match = _serverMatchOption[serverID]
	if match then
		return match.data
	end
	return nil
end

local function cmd_gs_info(targetServerID, msgNo, msgBody)
	-- 大厅向游戏服发送信息
	local targetServerItem = _serverHash[targetServerID]
	if not targetServerItem then
		return
	end
	skynet.send(addressResolver.getAddressByServiceName("LS_model_GSProxy"), "lua", "send", {targetServerID}, msgNo, msgBody)

end

local function cmd_GetServerListStatus()
	return _serverListStatus
end

local function cmd_reloadDefenseList()
	skynet.error(string.format("LS_model_serverManager.lua file cmd_reloadDefenseList function"))
	return true
end


local conf = {
	methods = {
		["gs_registerServer"] = {["func"]=cmd_gs_registerServer, ["isRet"]=true},
		["gs_registerMatch"] = {["func"]=cmd_gs_registerMatch, ["isRet"]=true},
		["gs_onlineReport"] = {["func"]=cmd_gs_reportOnline, ["isRet"]=true},
		["gs_relay"] = {["func"]=cmd_gs_relay, ["isRet"]=true},
		["gs_info"] = {["func"]=cmd_gs_info, ["isRet"]=true},
		
		["getServerName"] = {["func"]=cmd_getServerName, ["isRet"]=true},
		["sendServerOnline"] = {["func"]=cmd_sendServerOnline, ["isRet"]=false},
		["onEventLoginSuccess"] = {["func"]=cmd_onEventLoginSuccess, ["isRet"]=false},

		["getMatchServerInfo"] = {["func"]=cmd_getMatchServerInfo, ["isRet"]=true},
		["getServerIDListByKindID"] = {["func"]=getServerIDListByKindID, ["isRet"]=true},
		["reloadConfig"] = {["func"]=cmd_reloadConfig, ["isRet"]=false},
		["sendUserAddr"] = {["func"]=sendUserAddr, ["isRet"]=false},
		["GetServerListStatus"] = {["func"]=cmd_GetServerListStatus, ["isRet"]=true},
		["reloadDefenseList"] = {["func"]=cmd_reloadDefenseList, ["isRet"]=true},
	},
	initFunc = function()		
		local tickerStep = tonumber(skynet.getenv("serverManagerTickerStep"))
		if not tickerStep or tickerStep<=0 then
			error(string.format("invalid tickerStep: %s", tostring(tickerStep)))
		end
		
		local timerInterval = tonumber(skynet.getenv("serverManagerTimerInterval"))	
		if not timerInterval or timerInterval<=0 then
			error(string.format("invalid timerInterval: %s", tostring(timerInterval)))
		end
		
		local timeoutThreshold = tonumber(skynet.getenv("serverManagerTimeoutThreshold"))	
		if not timeoutThreshold or timeoutThreshold<=0 then
			error(string.format("invalid timeoutThreshold: %s", tostring(timeoutThreshold)))
		end
		_timeoutThresholdTick = timeoutThreshold * 100
		
		skynet.send(addressResolver.getAddressByServiceName("eventDispatcher"), "lua", "addEventListener", LS_EVENT.EVT_LS_LOGIN_SUCCESS, skynet.self(), "onEventLoginSuccess")
		defenseList = sysConfig.defenseList
		timerUtility.start(tickerStep)
		timerUtility.setInterval(checkServerTick, timerInterval)
	end,
}

commonServiceHelper.createService(conf)
