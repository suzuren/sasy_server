--机器人专用协议不需要配置到这里
local _data = {
	common = {
		s2c = {
			[0xff0000] = "common.misc.s2c.SystemMessage",
		},
		c2s = {},
		files = {
			"common.misc.s2c.pb",
		},		
	},
	loginServer = {
		s2c = {
			[0x000000] = "loginServer.heartBeat.s2c.HeartBeat",
			[0x000100] = "loginServer.login.s2c.Login",
			[0x000101] = "loginServer.login.s2c.Logout",
			[0x000102] = "loginServer.login.s2c.ScoreInfo",
			[0x000103] = "loginServer.login.s2c.UploadUserToPlatform",
			[0x000200] = "loginServer.server.s2c.NodeList",
			[0x000201] = "loginServer.server.s2c.MatchConfigList",
			[0x000202] = "loginServer.server.s2c.ServerOnline",
			[0x000299] = "loginServer.server.s2c.UserIPAddr",
			[0x000300] = "loginServer.message.s2c.SystemLogonMessage",
			[0x000301] = "loginServer.message.s2c.UserLogonMessage",
			[0x000302] = "loginServer.message.s2c.ExchangeMessage",
			[0x000303] = "loginServer.message.s2c.RecvGoods",
			[0x000304] = "loginServer.message.s2c.UserSingleMessage",
			[0x000400] = "loginServer.ranking.s2c.WealthRanking",
			[0x000401] = "loginServer.ranking.s2c.LoveLinesRanking",
			[0x000402] = "loginServer.ranking.s2c.BoxRanking",
			[0x000403] = "loginServer.ranking.s2c.SendTitleInfo",
			[0x000500] = "loginServer.pay.s2c.QueryPayOrderItem",
			[0x000501] = "loginServer.pay.s2c.PaymentNotify",
			[0x000502] = "loginServer.pay.s2c.BackQueryFreeScore",
			[0x000503] = "loginServer.pay.s2c.BackGetFreeScore",
			[0x000504] = "loginServer.pay.s2c.BackQueryVipFreeScore",
			[0x000505] = "loginServer.pay.s2c.BackGetVipFreeScore",
			[0x000506] = "loginServer.pay.s2c.BackGetGiftScore",
			[0x000507] = "loginServer.pay.s2c.BackQueryVipInfo",
			[0x000508] = "loginServer.pay.s2c.RefreshGift",
			[0x000509] = "loginServer.pay.s2c.RefreshLoveliness",
			[0x00050A] = "loginServer.pay.s2c.RefreshUserInfo",
			[0x00050B] = "loginServer.pay.s2c.VipPrivilegeInfoList",
			[0x00050C] = "loginServer.pay.s2c.RechargeAmount",
			[0x000513] = "loginServer.pay.s2c.InvitationCode",
			
			[0x000600] = "loginServer.account.s2c.ChangeFaceID",
			[0x000601] = "loginServer.account.s2c.ChangeSignature",
			[0x000602] = "loginServer.account.s2c.ChangeNickname",
			[0x000603] = "loginServer.account.s2c.CheckNickname",
			[0x000604] = "loginServer.account.s2c.ChangeGender",
			[0x000605] = "loginServer.account.s2c.SetPlatformFace",
			[0x000606] = "loginServer.account.s2c.SetBindingInfo",
			
			[0x000700] = "loginServer.bank.s2c.Deposit",
			[0x000701] = "loginServer.bank.s2c.Withdraw",
			[0x000702] = "loginServer.bank.s2c.Query",
			
			[0x000800] = "loginServer.ping.s2c.Ping",

			--[0x000900] = "loginServer.match.s2c.matchSignUp",
			--[0x000901] = "loginServer.match.s2c.userMatchInfo",
			--[0x000902] = "loginServer.match.s2c.queryMatchServerInfo",

			[0x001000] = "loginServer.signin.s2c.SigninListInfo",
			[0x001001] = "loginServer.signin.s2c.Sign",
			[0x002000] = "loginServer.rescueCoin.s2c.RescueCoin",
			[0x002001] = "loginServer.rescueCoin.s2c.RescueCoinSynchronizeTime",
			[0x002002] = "loginServer.rescueCoin.s2c.ReceiveRescueCoin",
			[0x002003] = "loginServer.rescueCoin.s2c.RescueCoinRemainingCount",
			[0x003000] = "loginServer.bag.s2c.GoodsInfoList",
			[0x003001] = "loginServer.bag.s2c.GoodsInfo",
			[0x003002] = "loginServer.bag.s2c.OffsetGoodsInfo",
			[0x003003] = "loginServer.bag.s2c.UseGoodsInfo",
			[0x003004] = "loginServer.bag.s2c.CompositingGoodsInfo",
			[0x003005] = "loginServer.bag.s2c.GiveGoodsInfo",
			[0x003006] = "loginServer.bag.s2c.equipGoodsInfo",
			[0x003007] = "loginServer.bag.s2c.ShopGoodsInfo",
			[0x003008] = "loginServer.bag.s2c.CompositingCDInfo",
			[0x003009] = "loginServer.bag.s2c.GivenHistory",
			[0x004000] = "loginServer.chat.s2c.SendMessageBoardInfo",
			[0x004001] = "loginServer.chat.s2c.MessageBoardInfoList",
			[0x004002] = "loginServer.chat.s2c.MessageBoardInfo",
			[0x005000] = "loginServer.gunUplevel.s2c.FortLevelInfoList",
			[0x005001] = "loginServer.gunUplevel.s2c.RequestFortLevel",
			[0x006000] = "loginServer.huoDong.s2c.ActivityInfoList",
			[0x006001] = "loginServer.huoDong.s2c.ExchangeActivityReward",
			[0x006002] = "loginServer.huoDong.s2c.NotifyActivityStartOrEnd",
			[0x006003] = "loginServer.huoDong.s2c.RedPacketInfo",
			[0x007000] = "loginServer.worldBoss.s2c.WorldBossFishInfo",
			[0x007001] = "loginServer.worldBoss.s2c.WorldBossStartKilled",
			[0x007002] = "loginServer.worldBoss.s2c.WorldBossEndKilled",
			[0x007003] = "loginServer.worldBoss.s2c.InvalidCoin",
			[0x007004] = "loginServer.worldBoss.s2c.SynchronizationBossSwimTime",
			[0x008000] = "loginServer.invitation.s2c.Invitation",
		},
		c2s = {
			[0x000000] = "loginServer.heartBeat.c2s.HeartBeat",
			[0x000100] = "loginServer.login.c2s.Login",
			[0x000103] = "loginServer.login.c2s.SimulatorLogin",
			[0x000104] = "loginServer.login.c2s.VersionStatus",
			[0x000105] = "loginServer.login.c2s.DownlaodVersionReward",
			[0x000202] = "loginServer.server.c2s.QueryServerOnline",
			[0x000302] = "loginServer.message.c2s.QueryExchangeMessage",
			[0x000303] = "loginServer.message.c2s.RecvGoods",
			[0x000400] = "loginServer.ranking.c2s.QueryWealthRanking",
			[0x000401] = "loginServer.ranking.c2s.QueryLoveLinesRanking",
			[0x000402] = "loginServer.ranking.c2s.QueryBoxRanking",
			[0x000403] = "loginServer.ranking.c2s.QueryTitleInfo",
			[0x000500] = "loginServer.pay.c2s.QueryPayOrderItem",
			[0x000501] = "loginServer.pay.c2s.PaymentNotify",
			[0x000502] = "loginServer.pay.c2s.QueryFreeScore",
			[0x000503] = "loginServer.pay.c2s.GetFreeScore",
			[0x000504] = "loginServer.pay.c2s.QueryVipFreeScore",
			[0x000505] = "loginServer.pay.c2s.GetVipFreeScore",
			[0x000506] = "loginServer.pay.c2s.GetGiftScore",
			[0x000507] = "loginServer.pay.c2s.QueryVipInfo",
			[0x000512] = "loginServer.pay.c2s.ChangePaymentNotify",
			[0x000513] = "loginServer.pay.c2s.InvitationCode",
			
			
			[0x000600] = "loginServer.account.c2s.ChangeFaceID",
			[0x000601] = "loginServer.account.c2s.ChangeSignature",
			[0x000602] = "loginServer.account.c2s.ChangeNickname",
			[0x000603] = "loginServer.account.c2s.CheckNickname",
			[0x000604] = "loginServer.account.c2s.ChangeGender",
			[0x000605] = "loginServer.account.c2s.SetPlatformFace",
			[0x000606] = "loginServer.account.c2s.SetBindingInfo",
			
			[0x000700] = "loginServer.bank.c2s.Deposit",
			[0x000701] = "loginServer.bank.c2s.Withdraw",
			[0x000702] = "loginServer.bank.c2s.Query",
			
			[0x000800] = "loginServer.ping.c2s.Ping",

			--[0x000900] = "loginServer.match.c2s.matchSignUp",
			--[0x000902] = "loginServer.match.c2s.queryMatchServerInfo",
			--[0x000903] = "loginServer.match.c2s.cancleSignUp",

			[0x001001] = "loginServer.signin.c2s.Sign",
			[0x002000] = "loginServer.rescueCoin.c2s.requestRescueCoin",
			[0x002001] = "loginServer.rescueCoin.c2s.RescueCoinSynchronizeTime",
			[0x002002] = "loginServer.rescueCoin.c2s.ReceiveRescueCoin",
			[0x003000] = "loginServer.bag.c2s.GoodsInfoList",
			[0x003001] = "loginServer.bag.c2s.GoodsInfo",
			[0x003002] = "loginServer.bag.c2s.OffsetGoodsInfo",
			[0x003003] = "loginServer.bag.c2s.UseGoodsInfo",
			[0x003004] = "loginServer.bag.c2s.CompositingGoodsInfo",
			[0x003005] = "loginServer.bag.c2s.GiveGoodsInfo",
			[0x003006] = "loginServer.bag.c2s.equipGoodsInfo",
			[0x003007] = "loginServer.bag.c2s.ShopGoodsInfo",
			[0x003008] = "loginServer.bag.c2s.CompositingCDInfo",
			[0x003009] = "loginServer.bag.c2s.GivenHistory",
			[0x004000] = "loginServer.chat.c2s.SendMessageBoardInfo",
			[0x005000] = "loginServer.gunUplevel.c2s.FortLevelInfoList",
			[0x005001] = "loginServer.gunUplevel.c2s.RequestFortLevel",
			[0x006000] = "loginServer.huoDong.c2s.ActivityInfoList",
			[0x006001] = "loginServer.huoDong.c2s.ExchangeActivityReward",
			[0x006003] = "loginServer.huoDong.c2s.RedPacketInfo",
			[0x007000] = "loginServer.worldBoss.c2s.WorldBossFishInfo",
			[0x007004] = "loginServer.worldBoss.c2s.SynchronizationBossSwimTime",
			[0x008000] = "loginServer.invitation.c2s.Invitation",
		},
		files = {
			"loginServer.heartBeat.c2s.pb",
			"loginServer.heartBeat.s2c.pb",
			"loginServer.login.c2s.pb",
			"loginServer.login.s2c.pb",
			"loginServer.server.c2s.pb",
			"loginServer.server.s2c.pb",
			"loginServer.message.c2s.pb",
			"loginServer.message.s2c.pb",
			"loginServer.ranking.c2s.pb",
			"loginServer.ranking.s2c.pb",		
			"loginServer.pay.c2s.pb",
			"loginServer.pay.s2c.pb",
			"loginServer.account.c2s.pb",
			"loginServer.account.s2c.pb",
			"loginServer.bank.c2s.pb",
			"loginServer.bank.s2c.pb",
			"loginServer.ping.c2s.pb",
			"loginServer.ping.s2c.pb",
			--"loginServer.match.c2s.pb",
			--"loginServer.match.s2c.pb",
			"loginServer.signin.c2s.pb",
			"loginServer.signin.s2c.pb",
			"loginServer.rescueCoin.c2s.pb",
			"loginServer.rescueCoin.s2c.pb",
			"loginServer.bag.c2s.pb",
			"loginServer.bag.s2c.pb",
			"loginServer.chat.c2s.pb",
			"loginServer.chat.s2c.pb",
			"loginServer.gunUplevel.c2s.pb",
			"loginServer.gunUplevel.s2c.pb",
			"loginServer.huoDong.c2s.pb",
			"loginServer.huoDong.s2c.pb",
			"loginServer.worldBoss.c2s.pb",
			"loginServer.worldBoss.s2c.pb",
			"loginServer.invitation.c2s.pb",
			"loginServer.invitation.s2c.pb",
		},
	},
	gameServer = {
		s2c = {
			[0x010000] = "gameServer.heartBeat.s2c.HeartBeat",
			
			[0x010100] = "gameServer.login.s2c.Login",
			[0x010102] = "gameServer.login.s2c.ServerConfig",
			[0x010104] = "gameServer.login.s2c.TableStatus",
			[0x010105] = "gameServer.login.s2c.TableStatusList",
			[0x010106] = "gameServer.login.s2c.UserInfo",
			[0x010107] = "gameServer.login.s2c.UserInfoViewPort",
			[0x010109] = "gameServer.login.s2c.Logout",
			
			[0x010200] = "gameServer.table.s2c.UserSitDown",
			[0x010201] = "gameServer.table.s2c.UserStatus",
			[0x010203] = "gameServer.table.s2c.GameStatus",
			[0x010204] = "gameServer.table.s2c.UserStandUp",
			[0x010205] = "gameServer.table.s2c.AllPlayerLeft",
			[0x010207] = "gameServer.table.s2c.UserLookon",
			[0x010208] = "gameServer.table.s2c.KickUser",
			[0x010209] = "gameServer.table.s2c.KickUserNotify",
			[0x01020A] = "gameServer.table.s2c.UsersLookonInfo",
			[0x01020B] = "gameServer.table.s2c.LockRoomStatus",
			[0x01020C] = "gameServer.table.s2c.LockRoom",
			
			[0x010300] = "gameServer.property.s2c.PropertyConfig",
			[0x010301] = "gameServer.property.s2c.PropertyRepository",
			[0x010302] = "gameServer.property.s2c.BuyProperty",
			[0x010303] = "gameServer.property.s2c.TrumpetScore",
			[0x010304] = "gameServer.property.s2c.UseProperty",
			[0x010305] = "gameServer.property.s2c.UsePropertyBroadcast",
			[0x010306] = "gameServer.property.s2c.PropertyRepositoryUpdate",
			[0x010307] = "gameServer.property.s2c.SendTrumpet",
			[0x010308] = "gameServer.property.s2c.TrumpetMsg",
			
			[0x010400] = "gameServer.chat.s2c.UserChat",
			[0x010401] = "gameServer.chat.s2c.UserExpression",
			[0x010402] = "gameServer.chat.s2c.UserMultimedia",
			
			[0x010500] = "gameServer.ping.s2c.Ping",

			--[0x010600] = "gameServer.match.s2c.userRanking",
			--[0x010601] = "gameServer.match.s2c.matchInfo",
			[0x010701] = "gameServer.bank.s2c.Withdraw",
			[0x010702] = "gameServer.bank.s2c.Query",
			
			[0x01ff01] = "gameServer.misc.s2c.UserScore",
			[0x01ff02] = "gameServer.misc.s2c.PaymentNotify",
			[0x010800] = "gameServer.task.s2c.TaskInfoList",
			[0x010802] = "gameServer.task.s2c.CompleteTask",
			[0x010803] = "gameServer.task.s2c.taskRankList",
			[0x010804] = "gameServer.task.s2c.TaskEnd",
			[0x010805] = "gameServer.task.s2c.TaskSynchronizationTime",
			[0x010900] = "gameServer.bag.s2c.GoodsInfoList",
			[0x010901] = "gameServer.bag.s2c.GoodsInfo",
			[0x010902] = "gameServer.bag.s2c.OffsetGoodsInfo",
			[0x010903] = "gameServer.bag.s2c.UseGoodsInfo",
			[0x010904] = "gameServer.bag.s2c.CompositingGoodsInfo",
			[0x010905] = "gameServer.bag.s2c.GiveGoodsInfo",
			[0x010906] = "gameServer.bag.s2c.equipGoodsInfo",
			[0x010907] = "gameServer.bag.s2c.CompositingCDInfo",
			[0x011000] = "gameServer.rewardGoldFish.s2c.LotteryInfo",
			[0x011001] = "gameServer.rewardGoldFish.s2c.RequestLotteryItem",
			[0x011002] = "gameServer.rewardGoldFish.s2c.ReceiveLotteryGoodsInfo",
			[0x011003] = "gameServer.rewardGoldFish.s2c.LotteryGoodsInfo",
			[0x012000] = "gameServer.gunUplevel.s2c.FortLevelInfoList",
			[0x012001] = "gameServer.gunUplevel.s2c.RequestFortLevel",
			[0x012002] = "gameServer.gunUplevel.s2c.VipExperienceFortInfoList",
			[0x013000] = "gameServer.huoDong.s2c.ActivityInfoList",
			[0x013001] = "gameServer.huoDong.s2c.ExchangeActivityReward",
			[0x014001] = "gameServer.worldBoss.s2c.WorldBossStartKilled",
			[0x014003] = "gameServer.worldBoss.s2c.InvalidCoin",
			[0x014005] = "gameServer.worldBoss.s2c.FishSpawn",
		},
		c2s = {
			[0x010000] = "gameServer.heartBeat.c2s.HeartBeat",
			[0x010100] = "gameServer.login.c2s.Login",
			[0x010109] = "gameServer.login.c2s.Logout",
			[0x010200] = "gameServer.table.c2s.UserSitDown",
			[0x010202] = "gameServer.table.c2s.GameOption",
			[0x010204] = "gameServer.table.c2s.UserStandUp",
			[0x010206] = "gameServer.table.c2s.UserReady",
			[0x010207] = "gameServer.table.c2s.UserLookon",
			[0x010208] = "gameServer.table.c2s.KickUser",
			[0x01020A] = "gameServer.table.c2s.UsersLookonInfo",
			[0x01020C] = "gameServer.table.c2s.LockRoom",
			
			[0x010302] = "gameServer.property.c2s.BuyProperty",
			[0x010304] = "gameServer.property.c2s.UseProperty",
			[0x010307] = "gameServer.property.c2s.SendTrumpet",
			
			[0x010400] = "gameServer.chat.c2s.UserChat",
			[0x010401] = "gameServer.chat.c2s.UserExpression",
			[0x010402] = "gameServer.chat.c2s.UserMultimedia",
			
			[0x010500] = "gameServer.ping.c2s.Ping",
			
			[0x010701] = "gameServer.bank.c2s.Withdraw",
			[0x010702] = "gameServer.bank.c2s.Query",
			[0x010800] = "gameServer.task.c2s.RequestTask",
			[0x010801] = "gameServer.task.c2s.ChangeTaskGoodsCount",
			[0x010802] = "gameServer.task.c2s.CompleteTask",
			[0x010805] = "gameServer.task.c2s.TaskSynchronizationTime",
			[0x010900] = "gameServer.bag.c2s.GoodsInfoList",
			[0x010901] = "gameServer.bag.c2s.GoodsInfo",
			[0x010902] = "gameServer.bag.c2s.OffsetGoodsInfo",
			[0x010903] = "gameServer.bag.c2s.UseGoodsInfo",
			[0x010904] = "gameServer.bag.c2s.CompositingGoodsInfo",
			[0x010905] = "gameServer.bag.c2s.GiveGoodsInfo",
			[0x010906] = "gameServer.bag.c2s.equipGoodsInfo",
			[0x010907] = "gameServer.bag.c2s.CompositingCDInfo",
			[0x011000] = "gameServer.rewardGoldFish.c2s.LotteryInfo",
			[0x011001] = "gameServer.rewardGoldFish.c2s.RequestLotteryItem",
			[0x011002] = "gameServer.rewardGoldFish.c2s.ReceiveLotteryGoodsInfo",
			[0x012000] = "gameServer.gunUplevel.c2s.FortLevelInfoList",
			[0x012001] = "gameServer.gunUplevel.c2s.RequestFortLevel",
			[0x013000] = "gameServer.huoDong.c2s.ActivityInfoList",
			[0x013001] = "gameServer.huoDong.c2s.ExchangeActivityReward",
			[0x014005] = "gameServer.worldBoss.c2s.FishSpawn",
		},
		files = {
			"gameServer.heartBeat.c2s.pb",
			"gameServer.heartBeat.s2c.pb",
			"gameServer.login.c2s.pb",
			"gameServer.login.s2c.pb",
			"gameServer.table.c2s.pb",
			"gameServer.table.s2c.pb",
			"gameServer.property.c2s.pb",
			"gameServer.property.s2c.pb",			
			"gameServer.chat.c2s.pb",
			"gameServer.chat.s2c.pb",
			"gameServer.ping.c2s.pb",
			"gameServer.ping.s2c.pb",	
			"gameServer.misc.s2c.pb",
			--"gameServer.match.s2c.pb",
			"gameServer.bank.c2s.pb",
			"gameServer.bank.s2c.pb",
			"gameServer.task.c2s.pb",
			"gameServer.task.s2c.pb",
			"gameServer.bag.c2s.pb",
			"gameServer.bag.s2c.pb",
			"gameServer.rewardGoldFish.c2s.pb",
			"gameServer.rewardGoldFish.s2c.pb",
			"gameServer.gunUplevel.c2s.pb",
			"gameServer.gunUplevel.s2c.pb",
			"gameServer.huoDong.c2s.pb",
			"gameServer.huoDong.s2c.pb",
			"gameServer.worldBoss.c2s.pb",
			"gameServer.worldBoss.s2c.pb",
		},
	},
	testGame = {
		s2c = {
			[0x020000] = "testGame.s2c.UserFire",
			[0x020002] = "testGame.s2c.SceneEnd",
			[0x020003] = "testGame.s2c.SwitchScene",
			[0x020004] = "testGame.s2c.Mermaid",
			[0x020005] = "testGame.s2c.GameConfig",
			[0x020006] = "testGame.s2c.GameScene",
			[0x020007] = "testGame.s2c.ExchangeFishScore",
			[0x020009] = "testGame.s2c.CatchSweepFish",
			[0x02000A] = "testGame.s2c.TreasureBox",
			[0x02000B] = "testGame.s2c.CatchFish",
			[0x02000C] = "testGame.s2c.CatchSweepFishResult",
			[0x02000D] = "testGame.s2c.LockTimeout",
			[0x02000E] = "testGame.s2c.BulletCompensate",
			[0x020010] = "testGame.s2c.FishSpawn",
			[0x020011] = "testGame.s2c.UserSkillStatus",
			[0x020012] = "testGame.s2c.UserFort",
			-- [0x020013] = "testGame.s2c.UserLockFish",
			[0x020014] = "testGame.s2c.YnchronizationDataErr",
			[0x020015] = "testGame.s2c.CallFish", 
			[0x020016] = "testGame.s2c.NotifyFishRate", 
			[0x020017] = "testGame.s2c.FrozenFish", 
			
			
			[0x020200] = "testGame.volcano.s2c.PoolStatus",
			[0x020201] = "testGame.volcano.s2c.VolcanoOpen",
		},
		c2s = {
			[0x020000] = "testGame.c2s.UserFire",
			[0x020008] = "testGame.c2s.BigNetCatchFish",
			[0x02000C] = "testGame.c2s.CatchSweepFish",
			[0x02000F] = "testGame.c2s.BigNetCatchFishAndroid",
			[0x020011] = "testGame.c2s.UserSkillStatus",
			[0x020012] = "testGame.c2s.UserFort",
			-- [0x020013] = "testGame.c2s.UserLockFish",
			[0x020015] = "testGame.c2s.CallFish", 
		},
		files = {
			"testGame.c2s.pb",
			"testGame.s2c.pb",
			"testGame.volcano.s2c.pb",
		},
	},
	plane = {
		s2c = {
			[0x040000] = "plane.s2c.UserFire",
		},
		c2s = {
			[0x040000] = "plane.c2s.UserFire",
		},
		files = {
			"plane.c2s.pb",
			"plane.s2c.pb",
		},
	},
	zhajinhua = {
		s2c = {
			[0x050000] = "zhajinhua.s2c.CMD_S_AddScore_Pro",
			[0x050002] = "zhajinhua.s2c.CMD_S_GiveUp_Pro",
			[0x050003] = "zhajinhua.s2c.CMD_S_CompareCard_Pro",
			[0x050004] = "zhajinhua.s2c.CMD_S_LookCard_Pro",
			[0x050005] = "zhajinhua.s2c.CMD_S_OpenCard_Pro",
			[0x050006] = "zhajinhua.s2c.CMD_S_WaitCompare_Pro",
			[0x050008] = "zhajinhua.s2c.CMD_S_ShowCared_Pro",

			[0x050009] = "zhajinhua.s2c.CMD_S_GameStart_Pro",
			[0x05000A] = "zhajinhua.s2c.CMD_S_Clock_Pro",
			[0x05000B] = "zhajinhua.s2c.CMD_S_GameEnd_Pro",
			
			
			[0x05000C] = "zhajinhua.s2c.CMD_S_StatusFree_Pro",
			[0x05000D] = "zhajinhua.s2c.CMD_S_StatusPlay_Pro",

			[0x05000E] = "zhajinhua.s2c.CMD_S_GameInfo_Pro",
			[0x050011] = "zhajinhua.s2c.CMD_S_GameCellInfo",
		},
		c2s = {
			[0x050000] = "zhajinhua.c2s.CMD_C_AddScore_Pro",
			[0x050002] = "zhajinhua.c2s.CMD_C_Common_Pro",
			[0x050003] = "zhajinhua.c2s.CMD_C_CompareCard_Pro",
			[0x050004] = "zhajinhua.c2s.CMD_C_Common_Pro",
			[0x050005] = "zhajinhua.c2s.CMD_C_Common_Pro",
			[0x050006] = "zhajinhua.c2s.CMD_C_Common_Pro",
			[0x050007] = "zhajinhua.c2s.CMD_C_Common_Pro",
			[0x050008] = "zhajinhua.c2s.CMD_C_Common_Pro",
			--[0x050010] = "zhajinhua.c2s.CMD_C_AddScore_Pro",--allin，用于金花比赛场
		},
		files = {
			"zhajinhua.c2s.pb",
			"zhajinhua.s2c.pb",
		},
	},
	doudizhu = {
		s2c = {
			--
			[0x051001] = "doudizhu.s2c.CMD_S_CallScore_Pro",		--用户叫分
			[0x051002] = "doudizhu.s2c.CMD_S_OutCard_Pro",			--用户出牌
			[0x051003] = "doudizhu.s2c.CMD_S_PassCard_Pro",			--用户放弃
			[0x051004] = "doudizhu.s2c.CMD_S_TuoGuan_Pro",			--用户托管

			--主动推送
			[0x051100] = "doudizhu.s2c.CMD_S_BaseScore_Pro",		--底分
			[0x051101] = "doudizhu.s2c.CMD_S_GameStart_Pro",		--游戏开始包
			[0x051102] = "doudizhu.s2c.CMD_S_AndroidCard_Pro",		--机器人开始包
			[0x051103] = "doudizhu.s2c.CMD_S_TuoGuan_Pro",			--托管信息
			[0x051104] = "doudizhu.s2c.CMD_S_BankerInfo_Pro",		--庄家信息
			[0x051105] = "doudizhu.s2c.CMD_S_Common_Pro",			--礼券投注信息
			[0x051106] = "doudizhu.s2c.CMD_S_GameConclude_Pro",		--游戏结束信息
			[0x051107] = "doudizhu.s2c.CMD_S_StatusFree_Pro",		--空闲状态信息
			[0x051108] = "doudizhu.s2c.CMD_S_StatusCall_Pro",		--叫分状态信息
			[0x051109] = "doudizhu.s2c.CMD_S_StatusPlay_Pro",		--游戏状态信息
			[0x051110] = "doudizhu.s2c.CMD_S_GameClock_Pro",		--定时器信息
			[0x051111] = "doudizhu.s2c.CMD_S_StatusFree_Pro",		--基本信息
		},
		c2s = {
			[0x051000] = "doudizhu.c2s.CMD_C_VoucherBetting_Pro",	--用户投注
			[0x051001] = "doudizhu.c2s.CMD_C_CallScore_Pro",		--用户叫分
			[0x051002] = "doudizhu.c2s.CMD_C_OutCard_Pro",			--用户出牌
			[0x051003] = "doudizhu.c2s.CMD_C_Common_Pro",			--用户放弃
			[0x051004] = "doudizhu.c2s.CMD_C_TuoGuan_Pro",			--用户托管
		},
		files = {
			"doudizhu.c2s.pb",
			"doudizhu.s2c.pb",
		},
	},
	niuniubattle = {
		s2c = {
			[0x054100] = "niuniubattle.s2c.CMD_S_PlaceJettonFail_Pro",
			[0x054101] = "niuniubattle.s2c.CMD_S_PlaceJetton_Pro",
			[0x054102] = "niuniubattle.s2c.CMD_S_Common_Pro",
			[0x054110] = "niuniubattle.s2c.CMD_S_GameRecord_Pro",
			[0x054111] = "niuniubattle.s2c.CMD_S_CancelBanker_Pro",
			[0x054112] = "niuniubattle.s2c.CMD_S_ChangeBanker_Pro",
			[0x054113] = "niuniubattle.s2c.CMD_S_ApplyBanker_Pro",
			[0x054114] = "niuniubattle.s2c.CMD_S_SofaSitResult_Pro",
			[0x054115] = "niuniubattle.s2c.CMD_S_SofaInfo_Pro",
			[0x054116] = "niuniubattle.s2c.CMD_S_StatusFree_Pro",
			[0x054117] = "niuniubattle.s2c.CMD_S_StatusPlay_Pro",
			[0x054118] = "niuniubattle.s2c.CMD_S_GameFree_Pro",
			[0x054119] = "niuniubattle.s2c.CMD_S_GameEnd_Pro",
			[0x054120] = "niuniubattle.s2c.CMD_S_SitDown_Pro",
			[0x054121] = "niuniubattle.s2c.CMD_S_RebotApplyBanker_Pro",
			[0x054122] = "niuniubattle.s2c.CMD_S_GameConfig",
			
			[0x05411A] = "niuniubattle.s2c.CMD_S_GameStart_Pro",
			--[0x05411B] = "niuniubattle.s2c.CMD_S_ServerVoucherUpdate",
			--[0x05411C] = "niuniubattle.s2c.CMD_S_UserVoucherUpdate",
			--[0x05411D] = "niuniubattle.s2c.CMD_S_ServerVoucherRecord",
		},
		c2s = {
			[0x054100] = "niuniubattle.c2s.CMD_C_PlaceJetton_Pro",
			[0x054101] = "niuniubattle.c2s.CMD_C_ApplyBanker_Pro",
			[0x054102] = "niuniubattle.c2s.CMD_C_CancelApplyBanker_Pro",
			[0x054103] = "niuniubattle.c2s.CMD_C_SofaSit_Pro",
			[0x054105] = "niuniubattle.c2s.CMD_C_QequestBankerList_Pro",
		},
		files = {
			"niuniubattle.c2s.pb",
			"niuniubattle.s2c.pb",
		},
	},
	flyBirdRunMonster = {
		s2c = {
			[0x055100] = "flyBirdRunMonster.s2c.CMD_S_PlaceJetton_Pro",
			[0x055101] = "flyBirdRunMonster.s2c.CMD_S_ApplyBanker_Pro",
			[0x055102] = "flyBirdRunMonster.s2c.CMD_S_CancelBanker_Pro",
			[0x055103] = "flyBirdRunMonster.s2c.CMD_S_GameRecord_Pro",
			[0x055104] = "flyBirdRunMonster.s2c.CMD_S_ChangeBanker_Pro",
			[0x055105] = "flyBirdRunMonster.s2c.CMD_S_StatusFree_Pro",
			[0x055106] = "flyBirdRunMonster.s2c.CMD_S_StatusPlay_Pro",
			[0x055107] = "flyBirdRunMonster.s2c.CMD_S_GameFree_Pro",
			[0x055108] = "flyBirdRunMonster.s2c.CMD_S_GameEnd_Pro",
			[0x055109] = "flyBirdRunMonster.s2c.CMD_S_SitDown_Pro",
			[0x055110] = "flyBirdRunMonster.s2c.CMD_S_RebotApplyBanker_Pro",
			[0x055111] = "flyBirdRunMonster.s2c.CMD_S_GameStart_Pro",
		},
		c2s = {
			[0x055100] = "flyBirdRunMonster.c2s.CMD_C_PlaceJetton_Pro",
			[0x055101] = "flyBirdRunMonster.c2s.CMD_C_ApplyBanker_Pro",
			[0x055102] = "flyBirdRunMonster.c2s.CMD_C_CancelApplyBanker_Pro",
		},
		files = {
			"flyBirdRunMonster.c2s.pb",
			"flyBirdRunMonster.s2c.pb",
		},
	},
}

local function mergeConfig(...)
	local config = {
		s2c = {},
		c2s = {},
		files = {},
	}
	
	for _, sectionName in ipairs{...} do
		local c = _data[sectionName]
		if c then
			for k, v in pairs(c.s2c) do
				config.s2c[k] = v
			end
			
			for k, v in pairs(c.c2s) do
				config.c2s[k] = v
			end
			
			for _, v in ipairs(c.files) do
				table.insert(config.files, v)
			end
		end
	end
	
	return config
end

local function getConfig(type)
	if type=="loginServer" then
		return mergeConfig("loginServer", "common")
	elseif type=="testGame" then
		return mergeConfig("gameServer", "testGame", "common")
	elseif type=="plane" then
		return mergeConfig("gameServer", "plane", "common")
	elseif type=="zhajinhua" then
		return mergeConfig("gameServer", "zhajinhua", "common")
	elseif type=="doudizhu" then
		return mergeConfig("gameServer", "doudizhu", "common")	
	elseif type=="niuniubattle" then
		return mergeConfig("gameServer", "niuniubattle", "common")
	elseif type=="flyBirdRunMonster" then
		return mergeConfig("gameServer", "flyBirdRunMonster", "common")		
	else
		error(string.format("invalid type \"%s\"", type), 2)
	end
end

return {
	getConfig = getConfig,
}
