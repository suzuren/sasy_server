local skynet = require "skynet"
local commonServiceHelper = require "serviceHelper.common"
local addressResolver = require "addressResolver"

local _wealthRankingList
local _loveLinesRankingList
local _boxRankingList

local function reloadWealthRankingList()
	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("DELETE FROM ssfishdb.t_char_title WHERE TitleType = 1")
	local rows = skynet.call(dbConn, "lua", "query", sql)

	local HideAllFlag = 0
	local sql = string.format("SELECT HideAllFlag FROM `ssrecorddb`.`t_record_hide_all_signature` WHERE ID = 1")
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if rows[1] ~= nil then
		HideAllFlag = tonumber(rows[1].HideAllFlag)
	end

	local sql = "call sstreasuredb.sp_load_wealth_ranking_list()"
	local rows = skynet.call(dbConn, "lua", "call", sql)
	local list = {}
	local i = 1
	if type(rows)=="table" then
		for _, row in ipairs(rows) do
			local item = {
				userID = tonumber(row.UserID),
				faceID = tonumber(row.FaceID),
				gender = tonumber(row.Gender),
				nickName = row.NickName,
				medal = tonumber(row.UserMedal),
				loveLiness = tonumber(row.LoveLiness),
				score = tonumber(row.Score),
				gift = tonumber(row.Gift),
				experience = tonumber(row.Experience),
				platformID = tonumber(row.PlatformID),
				memberOrder = tonumber(row.MemberOrder),
				platformFace = row.PlatformFace,
				hide = 0,
			}

			if row.Signature then
				item.signature = row.Signature
			end

			if HideAllFlag == 0 then
				if row.HideFlag then
					if tonumber(row.HideFlag) == 1 then
						item.hide = 1
					end
				end
			else
				item.hide = 1
			end
	
			table.insert(list, item)

			local titleName = skynet.call(addressResolver.getAddressByServiceName("LS_model_item_config"),"lua","GetTitleName",1,i)
			if titleName ~= nil then
				local sql = string.format("INSERT INTO ssfishdb.t_char_title VALUES(%d,%d,%d,'%s',NOW())",item.userID,1,i,titleName)
				skynet.send(dbConn, "lua", "execute", sql)
			end
			i = i + 1
		end
	end
	_wealthRankingList = list
end

local function reloadLoveLinesRankingList()
	local sql = "call sstreasuredb.sp_load_loveLines_ranking_list()"
	local dbConn = addressResolver.getMysqlConnection()
	local rows = skynet.call(dbConn, "lua", "call", sql)
	local list = {}
	if type(rows)=="table" then
		for _, row in ipairs(rows) do
			local item = {
				userID = tonumber(row.UserID),
				faceID = tonumber(row.FaceID),
				gender = tonumber(row.Gender),
				nickName = row.NickName,
				medal = tonumber(row.UserMedal),
				loveLiness = tonumber(row.LoveLiness),
				score = tonumber(row.Score),
				gift = tonumber(row.Gift),
				experience = tonumber(row.Experience),
				platformID = tonumber(row.PlatformID),
				memberOrder = tonumber(row.MemberOrder),
				platformFace = row.PlatformFace,
			}
			
			if row.Signature then
				item.signature = row.Signature
			end
			table.insert(list, item)
		end
	end
	_loveLinesRankingList = list
end

local function reloadBoxRankingList()
	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("DELETE FROM ssfishdb.t_char_title WHERE TitleType = 2")
	local rows = skynet.call(dbConn, "lua", "query", sql)

	local HideAllFlag = 0
	local sql = string.format("SELECT HideAllFlag FROM `ssrecorddb`.`t_record_hide_all_signature` WHERE ID = 1")
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if rows[1] ~= nil then
		HideAllFlag = tonumber(rows[1].HideAllFlag)
	end

	local sql = "call sstreasuredb.sp_load_box_ranking_list()"	
	local rows = skynet.call(dbConn, "lua", "call", sql)
	local list = {}
	local i = 1
	for _, row in ipairs(rows) do
		local info = {
			userID = tonumber(row.UserID),
			faceID = tonumber(row.FaceID),
			gender = tonumber(row.Gender),
			nickName = row.NickName,
			goodsInfoList = {},
			memberOrder = tonumber(row.MemberOrder),
			platformFace = row.PlatformFace,
			hide = 0,
		}

		local goodsInfo_1 = {
			goodsID = 1011,
			goodsCount = tonumber(row.PtBox),
		}
		table.insert(info.goodsInfoList,goodsInfo_1)

		local goodsInfo_2 = {
			goodsID = 1022,
			goodsCount = tonumber(row.GemBox),
		}
		table.insert(info.goodsInfoList,goodsInfo_2)

		local goodsInfo_3 = {
			goodsID = 1023,
			goodsCount = tonumber(row.ZhiZhunBox),
		}
		table.insert(info.goodsInfoList,goodsInfo_3)

		if row.Signature then
			info.signature = row.Signature
		end

		if HideAllFlag == 0 then
			if row.HideFlag then
				if tonumber(row.HideFlag) == 1 then
					info.hide = 1
				end
			end
		else
			info.hide = 1
		end

		table.insert(list, info)

		local titleName = skynet.call(addressResolver.getAddressByServiceName("LS_model_item_config"),"lua","GetTitleName",2,i)
		if titleName ~= nil then
			local sql = string.format("INSERT INTO ssfishdb.t_char_title VALUES(%d,%d,%d,'%s',NOW())",info.userID,2,i,titleName)
			skynet.send(dbConn, "lua", "execute", sql)
		end
		i = i + 1
	end
	
	_boxRankingList = list
end

local function cmd_sendWealthRankingList(agent)
	skynet.send(agent, "lua", "forward", 0x000400, {list=_wealthRankingList})
end

local function cmd_sendLoveLinesRankingList(agent)
	skynet.send(agent, "lua", "forward", 0x000401, {list=_loveLinesRankingList})
end

local function cmd_sendBoxRankingList(agent)
	skynet.send(agent, "lua", "forward", 0x000402, {list=_boxRankingList})
end

local function cmd_sendTitleList(agent,userID)
	local pbobj = {
		list = {},
	}
	local dbConn = addressResolver.getMysqlConnection()
	local sql = string.format("SELECT * FROM ssfishdb.t_char_title WHERE UserId = %d",userID)
	local rows = skynet.call(dbConn, "lua", "query", sql)
	if type(rows)=="table" then
		for _, row in ipairs(rows) do
			local info = {
				titleType = tonumber(row.TitleType),
				titleId = tonumber(row.TitleId),
				titleName = row.TitleName,
			}
			table.insert(pbobj.list,info)
		end
	end

	skynet.send(agent, "lua", "forward", 0x000403, pbobj)
end

local function cmd_reloadWealthRankingList()
	reloadWealthRankingList()
end

local function cmd_reloadLoveLinesRankingList()
	reloadLoveLinesRankingList()
end	

local function cmd_reloadBoxRankingList()
	reloadBoxRankingList()
end	

local conf = {
	methods = {
		["sendWealthRankingList"] = {["func"]=cmd_sendWealthRankingList, ["isRet"]=false},
		["sendLoveLinesRankingList"] = {["func"]=cmd_sendLoveLinesRankingList, ["isRet"]=false},
		["sendBoxRankingList"] = {["func"]=cmd_sendBoxRankingList, ["isRet"]=false},
		["sendTitleList"] = {["func"]=cmd_sendTitleList, ["isRet"]=false},
		["reloadWealthRankingList"] = {["func"]=cmd_reloadWealthRankingList, ["isRet"]=false},
		["reloadLoveLinesRankingList"] = {["func"]=cmd_reloadLoveLinesRankingList, ["isRet"]=false},
		["reloadBoxRankingList"] = {["func"]=cmd_reloadBoxRankingList, ["isRet"]=false},
	},
	initFunc = function()
		reloadWealthRankingList()
		--reloadLoveLinesRankingList()
		reloadBoxRankingList()

		-- skynet.fork(function()
		-- 	while true do
		-- 		reloadWealthRankingList()
		-- 		--reloadLoveLinesRankingList()
		-- 		reloadBoxRankingList()
		-- 		skynet.sleep(60000)
		-- 	end
		-- end)
	end,
}

commonServiceHelper.createService(conf)

