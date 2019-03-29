/*
Navicat MySQL Data Transfer

Source Server Version : 50621
Source Database       : ssrecorddb

Target Server Type    : MYSQL
Target Server Version : 50621
File Encoding         : 65001

*/

USE `ssrecorddb`;

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for bank
-- ----------------------------
DROP TABLE IF EXISTS `bank`;
CREATE TABLE `bank` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `UserID` int(10) unsigned NOT NULL,
  `Ctime` datetime NOT NULL,
  `Type` enum('withdraw','deposit') NOT NULL,
  `Score` bigint(20) NOT NULL,
  `Insure` bigint(20) NOT NULL,
  `ScoreBefore` bigint(20) NOT NULL,
  `InsureBefore` bigint(20) NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for buyproperty
-- ----------------------------
DROP TABLE IF EXISTS `buyproperty`;
CREATE TABLE `buyproperty` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ServerID` int(10) unsigned NOT NULL,
  `UserID` int(10) unsigned NOT NULL,
  `PropertyID` int(10) unsigned NOT NULL,
  `PropertyCount` int(10) unsigned NOT NULL,
  `ConsumeScore` int(10) unsigned NOT NULL,
  `Ctime` datetime NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `idx1` (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for catchbox
-- ----------------------------
DROP TABLE IF EXISTS `catchbox`;
CREATE TABLE `catchbox` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ServerID` int(10) unsigned NOT NULL COMMENT '房间号码',
  `UserID` int(10) unsigned NOT NULL COMMENT '用户ID',
  `BoxType` char(30) NOT NULL COMMENT '宝箱类型',
  `Present` int(10) unsigned NOT NULL COMMENT '礼券',
  `Score` int(10) unsigned NOT NULL COMMENT '金币',
  `Ctime` datetime NOT NULL COMMENT '打中宝箱时间',
  `SumPresent` int(10) NOT NULL DEFAULT '0',
  `Multiple` int(11) NOT NULL COMMENT '炮倍',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for chat
-- ----------------------------
DROP TABLE IF EXISTS `chat`;
CREATE TABLE `chat` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ServerID` int(10) unsigned NOT NULL,
  `TableID` int(10) unsigned NOT NULL,
  `SendUserID` int(10) unsigned NOT NULL,
  `Ctime` datetime NOT NULL,
  `Message` text NOT NULL,
  `PayRmb` int(11) DEFAULT '0',
  `UserIdList` char(250) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for drawinfo
-- ----------------------------
DROP TABLE IF EXISTS `drawinfo`;
CREATE TABLE `drawinfo` (
  `DrawID` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '局数标识',
  `KindID` int(11) NOT NULL COMMENT '类型标识',
  `ServerID` int(11) NOT NULL COMMENT '房间标识',
  `TableID` smallint(6) NOT NULL COMMENT '桌子号码',
  `StartTime` datetime NOT NULL COMMENT '开始时间',
  `ConcludeTime` datetime DEFAULT NULL COMMENT '结束时间',
  PRIMARY KEY (`DrawID`)
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for drawscore
-- ----------------------------
DROP TABLE IF EXISTS `drawscore`;
CREATE TABLE `drawscore` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `DrawID` bigint(20) unsigned NOT NULL COMMENT '局数标识',
  `UserID` int(11) NOT NULL COMMENT '用户标识',
  `ChairID` int(11) unsigned NOT NULL COMMENT '椅子号码',
  `isAndroid` tinyint(3) unsigned NOT NULL,
  `Score` bigint(20) NOT NULL COMMENT '用户积分',
  `Grade` bigint(20) NOT NULL COMMENT '用户成绩',
  `Revenue` bigint(20) NOT NULL COMMENT '税收',
  `Medal` bigint(20) NOT NULL COMMENT '用户奖牌',
  `Gift` bigint(20) NOT NULL COMMENT '礼券',
  `Present` bigint(20) NOT NULL COMMENT 'UU游戏的用户的奖牌数',
  `Loveliness` bigint(20) NOT NULL COMMENT '魅力',
  `PlayTimeCount` int(11) NOT NULL COMMENT '游戏时长',
  `InoutIndex` int(10) unsigned NOT NULL COMMENT '进出索引',
  `InsertTime` datetime NOT NULL COMMENT '插入时间',
  `ServerId` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=141 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for lotterysinkrecord
-- ----------------------------
DROP TABLE IF EXISTS `lotterysinkrecord`;
CREATE TABLE `lotterysinkrecord` (
  `id` int(10) NOT NULL COMMENT '金花彩票奖池信息',
  `Score` int(20) DEFAULT '0' COMMENT '奖池累计金额',
  `isOpen` tinyint(2) DEFAULT NULL COMMENT '是否已开奖',
  `RecordTime` datetime DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for matchuserranking
-- ----------------------------
DROP TABLE IF EXISTS `matchuserranking`;
CREATE TABLE `matchuserranking` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `UserID` int(10) DEFAULT NULL COMMENT '用户ID',
  `Ranking` int(10) DEFAULT '0' COMMENT '历史最高排名',
  `Score` int(20) DEFAULT '0' COMMENT '累计奖励筹码',
  `ServerID` int(10) DEFAULT '0' COMMENT '房间id',
  `RecordTime` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for matchuserrecord
-- ----------------------------
DROP TABLE IF EXISTS `matchuserrecord`;
CREATE TABLE `matchuserrecord` (
  `id` int(10) NOT NULL AUTO_INCREMENT COMMENT '用户报名比赛记录表',
  `userID` int(10) DEFAULT '0' COMMENT '用户id',
  `serverID` int(10) DEFAULT '0' COMMENT 'serverID',
  `fee` int(10) DEFAULT '0' COMMENT '比赛费用',
  `recordTime` datetime DEFAULT NULL COMMENT '报名时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for message_record
-- ----------------------------
DROP TABLE IF EXISTS `message_record`;
CREATE TABLE `message_record` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL,
  `EmailID` int(11) NOT NULL COMMENT '公告id',
  `GoodsInfo` varchar(250) NOT NULL COMMENT '奖励的物品',
  `ReceiveTime` datetime NOT NULL COMMENT '领取时间',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for payorderconfirm
-- ----------------------------
DROP TABLE IF EXISTS `payorderconfirm`;
CREATE TABLE `payorderconfirm` (
  `OrderID` char(26) NOT NULL,
  `PayChannel` int(11) NOT NULL DEFAULT '0',
  `UserID` int(11) NOT NULL DEFAULT '0',
  `PlatformID` int(11) NOT NULL DEFAULT '0',
  `CurrencyType` char(10) NOT NULL DEFAULT '',
  `CurrencyAmount` decimal(18,2) NOT NULL DEFAULT '0.00',
  `Score` bigint(20) unsigned NOT NULL DEFAULT '0',
  `MemberOrder` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `MemberOrderDays` smallint(5) unsigned NOT NULL,
  `MemberUserRight` int(10) unsigned NOT NULL DEFAULT '0',
  `SubmitTime` datetime NOT NULL,
  `FinishTime` datetime NOT NULL,
  `ScoreBefore` bigint(20) NOT NULL DEFAULT '0',
  `InsureBefore` bigint(20) NOT NULL DEFAULT '0',
  `PayOrderItemID` int(11) NOT NULL,
  `ReadFlag` tinyint(3) NOT NULL DEFAULT '0' COMMENT '0未读取，1读取过了',
  `SandBox` tinyint(3) NOT NULL DEFAULT '0' COMMENT '1沙盒',
  `PayBeforeScore` int(11) NOT NULL DEFAULT '0' COMMENT '充值之前的金币',
  `ExtraGold` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`OrderID`),
  KEY `idx1` (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for presentchange
-- ----------------------------
DROP TABLE IF EXISTS `presentchange`;
CREATE TABLE `presentchange` (
  `UserID` int(11) DEFAULT NULL,
  `tp` int(11) DEFAULT NULL COMMENT '(1换金币，2换实物)',
  `presentUsed` bigint(20) DEFAULT NULL,
  `scoreAdd` int(11) DEFAULT '0' COMMENT '换金币时增加的金币',
  `Datetime` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for recordalms
-- ----------------------------
DROP TABLE IF EXISTS `recordalms`;
CREATE TABLE `recordalms` (
  `UserID` int(11) DEFAULT NULL,
  `Score` int(11) DEFAULT NULL,
  `Datetime` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for recordmemberscore
-- ----------------------------
DROP TABLE IF EXISTS `recordmemberscore`;
CREATE TABLE `recordmemberscore` (
  `UserID` int(11) NOT NULL DEFAULT '0' COMMENT 'vip免费金币',
  `Score` int(11) NOT NULL,
  `Datetime` datetime NOT NULL,
  `MemberOrder` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for registerscore
-- ----------------------------
DROP TABLE IF EXISTS `registerscore`;
CREATE TABLE `registerscore` (
  `RegisterMachine` char(32) NOT NULL,
  `Score` int(10) unsigned NOT NULL DEFAULT '0',
  `Count` smallint(5) unsigned NOT NULL,
  `CollectDate` datetime DEFAULT NULL,
  PRIMARY KEY (`RegisterMachine`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for rescue_coin
-- ----------------------------
DROP TABLE IF EXISTS `rescue_coin`;
CREATE TABLE `rescue_coin` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL,
  `CurNum` int(11) NOT NULL,
  `GoldNum` int(11) NOT NULL,
  `ReceiveTime` datetime NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `IDX_USERID` (`UserId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for sign_in
-- ----------------------------
DROP TABLE IF EXISTS `sign_in`;
CREATE TABLE `sign_in` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL,
  `Type` tinyint(3) NOT NULL COMMENT '类型1每日，2累计',
  `DayId` int(11) NOT NULL COMMENT '第几天',
  `GoldNum` int(11) NOT NULL COMMENT '签到获取的金币',
  `SigninTime` datetime NOT NULL COMMENT '签到时间',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for task_record
-- ----------------------------
DROP TABLE IF EXISTS `task_record`;
CREATE TABLE `task_record` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL,
  `TaskType` tinyint(3) NOT NULL,
  `TaskId` int(11) NOT NULL,
  `CommitTime` datetime NOT NULL COMMENT '完成任务时间',
  `RewardGold` int(11) DEFAULT '0' COMMENT '奖励的金币',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for trumpetlog
-- ----------------------------
DROP TABLE IF EXISTS `trumpetlog`;
CREATE TABLE `trumpetlog` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ServerID` int(11) NOT NULL DEFAULT '0',
  `UserID` int(11) NOT NULL DEFAULT '0',
  `TrumpetID` int(11) NOT NULL DEFAULT '0',
  `Color` int(11) NOT NULL DEFAULT '0',
  `Ctime` datetime NOT NULL,
  `Msg` text NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_activity_get_reward_type
-- ----------------------------
DROP TABLE IF EXISTS `t_activity_get_reward_type`;
CREATE TABLE `t_activity_get_reward_type` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL,
  `RewardType` tinyint(4) NOT NULL COMMENT '1邮件2自己领取',
  `ActivityId` int(11) NOT NULL,
  `ActivityIndex` int(11) NOT NULL,
  `date` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_deduct_appid
-- ----------------------------
DROP TABLE IF EXISTS `t_deduct_appid`;
CREATE TABLE `t_deduct_appid` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `AppID` int(11) NOT NULL,
  `DeductNum` int(11) NOT NULL,
  `InsertTime` datetime DEFAULT NULL,
  `Mark` char(250) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `IDX_APPID` (`AppID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for t_fly_bird_run_monster_record_
-- ----------------------------
DROP TABLE IF EXISTS `t_fly_bird_run_monster_record_`;
CREATE TABLE `t_fly_bird_run_monster_record_` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `BankerUserId` int(11) DEFAULT NULL,
  `RebotBankerScore` int(11) DEFAULT NULL,
  `UserBankerScore` int(11) DEFAULT NULL,
  `Date` datetime DEFAULT NULL,
  `IsSpecial` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for t_gun_uplevel
-- ----------------------------
DROP TABLE IF EXISTS `t_gun_uplevel`;
CREATE TABLE `t_gun_uplevel` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL,
  `GunLevel` int(11) NOT NULL COMMENT '升级的炮台等级',
  `DelGemCount` int(11) NOT NULL COMMENT '消耗宝石',
  `RemainGemCount` int(11) NOT NULL COMMENT '剩余宝石',
  `GetGold` int(11) NOT NULL COMMENT '获得金币',
  `CurSumGold` int(11) NOT NULL COMMENT '现在身上金币',
  `Date` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_item_record
-- ----------------------------
DROP TABLE IF EXISTS `t_item_record`;
CREATE TABLE `t_item_record` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL,
  `FromId` int(11) NOT NULL COMMENT '来着系统',
  `AddOrDel` tinyint(2) NOT NULL COMMENT '1加，2消耗',
  `ItemId` int(11) NOT NULL,
  `ItemCount` int(11) NOT NULL,
  `Date` datetime DEFAULT NULL,
  `InGame` tinyint(2) DEFAULT '0' COMMENT '是否是游戏了1是，0否',
  PRIMARY KEY (`ID`),
  KEY `IDX_USERID` (`UserId`) USING BTREE,
  KEY `IDX_USERID_AND_ITEMID` (`UserId`,`ItemId`) USING BTREE,
  KEY `IDX_ITEMID` (`ItemId`) USING BTREE,
  KEY `IDX_FROMID_AND_ITEMID` (`FromId`,`ItemId`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=492 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_niuniu_battle_record
-- ----------------------------
DROP TABLE IF EXISTS `t_niuniu_battle_record`;
CREATE TABLE `t_niuniu_battle_record` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `Tian` int(11) NOT NULL,
  `Di` int(11) NOT NULL,
  `Xuan` int(11) NOT NULL,
  `Huang` int(11) NOT NULL,
  `BankerUserId` int(11) NOT NULL COMMENT '庄家id',
  `BankerScore` int(11) NOT NULL COMMENT '庄家输赢多少',
  `RebotBankerScore` int(11) NOT NULL COMMENT '上庄机器人输赢多少',
  `UserBankerScore` int(11) NOT NULL COMMENT '玩家上庄输赢多少',
  `Date` datetime DEFAULT NULL,
  `SpecialServer` tinyint(2) NOT NULL DEFAULT '0',
  `UserSumScore` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_record_give_item
-- ----------------------------
DROP TABLE IF EXISTS `t_record_give_item`;
CREATE TABLE `t_record_give_item` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL COMMENT '发起用户',
  `GiveUserId` int(11) NOT NULL COMMENT '赠送用户',
  `ItemId` int(10) NOT NULL,
  `ItemCount` int(10) NOT NULL,
  `Date` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `idx_userID_Date` (`UserId`,`Date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_record_gold_by_use_box
-- ----------------------------
DROP TABLE IF EXISTS `t_record_gold_by_use_box`;
CREATE TABLE `t_record_gold_by_use_box` (
  `UserId` int(11) NOT NULL,
  `SumGold` int(11) NOT NULL COMMENT '使用宝箱累计获得的金币',
  PRIMARY KEY (`UserId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_record_hide_all_signature
-- ----------------------------
DROP TABLE IF EXISTS `t_record_hide_all_signature`;
CREATE TABLE `t_record_hide_all_signature` (
  `ID` tinyint(4) NOT NULL,
  `HideAllFlag` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for t_record_key
-- ----------------------------
DROP TABLE IF EXISTS `t_record_key`;
CREATE TABLE `t_record_key` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL,
  `ServerId` int(11) NOT NULL,
  `KeyId` int(11) NOT NULL,
  `KeyCount` int(11) NOT NULL,
  `Date` datetime NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_red_packet_kill_record
-- ----------------------------
DROP TABLE IF EXISTS `t_red_packet_kill_record`;
CREATE TABLE `t_red_packet_kill_record` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL,
  `Multiple` int(11) NOT NULL,
  `AddGold` int(11) NOT NULL,
  `AddTime` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for t_red_packet_user_gold_record
-- ----------------------------
DROP TABLE IF EXISTS `t_red_packet_user_gold_record`;
CREATE TABLE `t_red_packet_user_gold_record` (
  `UserId` int(11) NOT NULL,
  `SumGold` int(11) NOT NULL,
  PRIMARY KEY (`UserId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for t_reward_gold_fish
-- ----------------------------
DROP TABLE IF EXISTS `t_reward_gold_fish`;
CREATE TABLE `t_reward_gold_fish` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL,
  `RewardType` tinyint(3) NOT NULL COMMENT '抽奖类型',
  `RewardId` int(11) NOT NULL COMMENT '奖励的金币',
  `RewardCount` int(11) NOT NULL,
  `Date` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_reward_gold_fish_or_boss
-- ----------------------------
DROP TABLE IF EXISTS `t_reward_gold_fish_or_boss`;
CREATE TABLE `t_reward_gold_fish_or_boss` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL,
  `Type` tinyint(2) NOT NULL COMMENT '1奖金鱼，2boss',
  `ServerId` int(11) NOT NULL COMMENT '房间',
  `FishiId` int(10) NOT NULL,
  `Multiple` int(11) NOT NULL COMMENT '炮倍',
  `AddGold` int(11) NOT NULL COMMENT '获得金币',
  `CurGold` int(11) NOT NULL COMMENT '当前金币',
  `Date` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=65 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_user_invalid_gun_record
-- ----------------------------
DROP TABLE IF EXISTS `t_user_invalid_gun_record`;
CREATE TABLE `t_user_invalid_gun_record` (
  `ID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL,
  `ItemId` int(11) NOT NULL,
  `ItemCount` int(11) NOT NULL,
  `Date` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_user_operator_limit
-- ----------------------------
DROP TABLE IF EXISTS `t_user_operator_limit`;
CREATE TABLE `t_user_operator_limit` (
  `UserId` int(11) NOT NULL,
  `LimitId` int(11) NOT NULL,
  `LimitCount` bigint(20) NOT NULL,
  `LimitDate` int(11) DEFAULT NULL,
  PRIMARY KEY (`UserId`,`LimitId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_word_record
-- ----------------------------
DROP TABLE IF EXISTS `t_word_record`;
CREATE TABLE `t_word_record` (
  `Id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL,
  `UserName` char(250) NOT NULL,
  `Gender` tinyint(3) NOT NULL,
  `VipLevel` tinyint(4) NOT NULL,
  `Content` varchar(500) NOT NULL COMMENT '留言信息',
  `GoodsInfo` varchar(500) NOT NULL COMMENT '展示的道具',
  `WordTime` datetime NOT NULL COMMENT '留言时间',
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_world_boss_record
-- ----------------------------
DROP TABLE IF EXISTS `t_world_boss_record`;
CREATE TABLE `t_world_boss_record` (
  `ID` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `UserId` int(11) NOT NULL,
  `WinScore` int(11) NOT NULL,
  `Date` datetime DEFAULT NULL,
  `BossType` tinyint(2) DEFAULT '0' COMMENT '0普通boss，1定时boss',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for useproperty
-- ----------------------------
DROP TABLE IF EXISTS `useproperty`;
CREATE TABLE `useproperty` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ServerID` int(10) unsigned NOT NULL,
  `UserID` int(10) unsigned NOT NULL,
  `TargetUserID` int(10) unsigned NOT NULL,
  `PropertyID` int(10) unsigned NOT NULL,
  `PropertyCount` int(10) unsigned NOT NULL,
  `Ctime` datetime NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for userfishscore
-- ----------------------------
DROP TABLE IF EXISTS `userfishscore`;
CREATE TABLE `userfishscore` (
  `UserID` int(10) NOT NULL COMMENT '玩家id,玩家捕鱼记录表',
  `Score` bigint(20) DEFAULT '0' COMMENT '累计得到的分数（捕鱼获得）',
  `Present` bigint(20) DEFAULT '0' COMMENT '累计得到的礼券（打宝箱获得）',
  `RecordTime` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`UserID`),
  KEY `IX_userID` (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for userinout
-- ----------------------------
DROP TABLE IF EXISTS `userinout`;
CREATE TABLE `userinout` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '索引标识',
  `UserID` int(11) DEFAULT NULL,
  `KindID` int(11) DEFAULT NULL,
  `ServerID` int(11) DEFAULT NULL,
  `IP` char(15) DEFAULT NULL,
  `Machine` char(32) DEFAULT NULL,
  `EnterTime` datetime DEFAULT NULL,
  `EnterScore` bigint(20) NOT NULL DEFAULT '0',
  `EntreInsure` bigint(20) NOT NULL DEFAULT '0',
  `EnterMedal` int(11) NOT NULL DEFAULT '0',
  `EnterExp` int(11) NOT NULL DEFAULT '0',
  `EnterLove` int(11) NOT NULL DEFAULT '0',
  `EnterGift` int(11) NOT NULL DEFAULT '0',
  `EnterPresent` int(11) NOT NULL DEFAULT '0',
  `EnterWinCount` int(11) NOT NULL DEFAULT '0',
  `EnterLostCount` int(11) NOT NULL DEFAULT '0',
  `EnterDrawCount` int(11) NOT NULL DEFAULT '0',
  `EnterFleeCount` int(11) NOT NULL DEFAULT '0',
  `LeaveTime` datetime DEFAULT NULL,
  `LeaveScore` bigint(20) NOT NULL DEFAULT '0',
  `LeaveInsure` bigint(20) NOT NULL DEFAULT '0',
  `LeaveMedal` int(11) NOT NULL DEFAULT '0',
  `LeaveExp` int(11) NOT NULL DEFAULT '0',
  `LeaveLove` int(11) NOT NULL DEFAULT '0',
  `LeaveGift` int(11) NOT NULL DEFAULT '0',
  `LeavePresent` int(11) NOT NULL DEFAULT '0',
  `LeaveWinCount` int(11) NOT NULL DEFAULT '0',
  `LeaveLostCount` int(11) NOT NULL DEFAULT '0',
  `LeaveDrawCount` int(11) NOT NULL DEFAULT '0',
  `LeaveFleeCount` int(11) NOT NULL DEFAULT '0',
  `EnterGem` int(11) NOT NULL DEFAULT '0' COMMENT '进入宝石数量',
  `LeaveGem` int(11) NOT NULL DEFAULT '0' COMMENT '离开宝石数量',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for userlottery
-- ----------------------------
DROP TABLE IF EXISTS `userlottery`;
CREATE TABLE `userlottery` (
  `id` int(10) NOT NULL AUTO_INCREMENT COMMENT '玩家金花彩票投注记录表',
  `UserID` int(10) DEFAULT NULL COMMENT '玩家id',
  `LotteryID` int(10) DEFAULT '0' COMMENT '开奖期数id',
  `Score` int(10) DEFAULT '0' COMMENT '投注金额',
  `Revenue` int(10) DEFAULT '0' COMMENT '税收金额',
  `ReceiveScore` int(20) DEFAULT '0' COMMENT '中奖金额',
  `CardType` int(5) DEFAULT NULL COMMENT '牌型',
  `RecordTime` datetime DEFAULT NULL COMMENT '投注时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for userpayscore
-- ----------------------------
DROP TABLE IF EXISTS `userpayscore`;
CREATE TABLE `userpayscore` (
  `platformID` int(10) NOT NULL COMMENT '统一平台id',
  `userID` int(10) DEFAULT NULL COMMENT '用户id',
  `score` int(20) DEFAULT NULL COMMENT '累计获取筹码',
  PRIMARY KEY (`platformID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for uservariateday
-- ----------------------------
DROP TABLE IF EXISTS `uservariateday`;
CREATE TABLE `uservariateday` (
  `UserID` int(10) unsigned NOT NULL,
  `KindID` int(10) unsigned NOT NULL,
  `RecordDate` date NOT NULL,
  `Score` bigint(20) NOT NULL DEFAULT '0',
  `Insure` bigint(20) NOT NULL DEFAULT '0',
  `Medal` bigint(20) NOT NULL DEFAULT '0',
  `Experience` bigint(20) NOT NULL DEFAULT '0',
  `Loveliness` bigint(20) NOT NULL DEFAULT '0',
  `Gift` bigint(20) NOT NULL DEFAULT '0',
  `Present` bigint(20) NOT NULL DEFAULT '0',
  PRIMARY KEY (`RecordDate`,`UserID`,`KindID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for volcano
-- ----------------------------
DROP TABLE IF EXISTS `volcano`;
CREATE TABLE `volcano` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `KindID` int(11) NOT NULL,
  `NodeID` int(11) NOT NULL,
  `ServerID` int(11) NOT NULL,
  `Ctime` datetime NOT NULL,
  `UserID` int(11) NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Procedure structure for sp_load_payorder_list
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_load_payorder_list`;
DELIMITER ;;
CREATE  PROCEDURE `sp_load_payorder_list`(
)
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE varUserID INT;
	DECLARE varPlatformID INT;
	DECLARE varExitLoop TINYINT;
	DECLARE varScore INT;
	DECLARE varCursor1 CURSOR FOR SELECT P.PlatformID,P.UserID, (I.Gold+I.GoldExtra) AS Score FROM `sstreasuredb`.`PayOrderConfirm`as P LEFT JOIN `sstreasuredb`.`PayOrderItem` as I ON P.PayOrderItemID=I.ID WHERE P.PayOrderItemID > 0;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET varExitLoop := 1;

	OPEN varCursor1;
	itemLoop: LOOP
		FETCH varCursor1 INTO varPlatformID, varUserID, varScore;
		IF varExitLoop=1 THEN
			LEAVE itemLoop;
		END IF;
		UPDATE `UserPayScore` SET `score`=`score`+varScore WHERE `platformID`=varPlatformID;
		IF ROW_COUNT() = 0 THEN
			INSERT INTO `UserPayScore` (`platformID`, `userID`, `score`) VALUES (varPlatformID, varUserID, varScore);
		END IF;
	END LOOP;
	CLOSE varCursor1;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_record_user_fish_score_present
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_record_user_fish_score_present`;
DELIMITER ;;
CREATE  PROCEDURE `sp_record_user_fish_score_present`(
IN inUserID int(11),IN inScore int(11),IN inPresent int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN

	#UPDATE `UserFishScore` SET `Present`=`Present`+inPresent, `Score`=`Score`+inScore, `RecordTime`=NOW() WHERE `UserID`=inUserID;
	#IF ROW_COUNT() = 0 THEN
		#INSERT INTO `UserFishScore` (`UserID`, `Score`, `Present`, `RecordTime`) VALUES (inUserID, inScore, inPresent, NOW());
	#END IF;
	INSERT INTO `userfishscore` (UserID,Score,Present,RecordTime) VALUES(inUserID,inPresent,inScore,NOW()) ON DUPLICATE KEY UPDATE `Present`=`Present`+inPresent, `Score`=`Score`+inScore;
	SELECT `Score`, `Present` FROM `UserFishScore` WHERE `UserID`=inUserID;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_record_user_in
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_record_user_in`;
DELIMITER ;;
CREATE  PROCEDURE `sp_record_user_in`(
IN inUserID int(11),IN inIPAddr char(15),IN inMachineSerial char(32),IN inKindID int(11),IN inServerID int(11),IN inScore bigint(20),IN inInsure bigint(20),IN inUserMedal int(11),IN inExp int(11),IN inLove int(11),IN inGift int(11),IN inPresent int(11),IN inWinCount int(11),IN inLostCount int(11),IN inDrawCount int(11),IN inFleeCount int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE varInOutID INT;
	DECLARE varEnterGem INT;


	#SELECT `Gem` INTO varEnterGem from (select UserId, SUM(Gem) as Gem FROM (select UserId, ifnull(case ItemId WHEN 1002 then ItemCount end, 0) AS Gem from `ssfishdb`.`t_bag` where ItemId in(1002) ) a GROUP BY UserId) as a  WHERE a.UserId = inUserID;
	SELECT itemCount INTO varEnterGem  FROM ssfishdb.t_bag WHERE ItemId=1002 and UserId = inUserID;
	if ISNULL(varEnterGem) THEN
		SET varEnterGem := 0;
	END IF;
	
	INSERT INTO `UserInOut` (`UserID`, `KindID`, `ServerID`, `IP`, `Machine`, `EnterTime`, `EnterScore`, `EntreInsure`, `EnterMedal`, `EnterExp`, `EnterLove`, `EnterGift`, `EnterPresent`, `EnterWinCount`, `EnterLostCount`, `EnterDrawCount`, `EnterFleeCount`,`EnterGem`) VALUES (inUserID, inKindID, inServerID, inIPAddr, inMachineSerial, NOW(), inScore, inInsure, inUserMedal, inExp, inLove, inGift, inPresent, inWinCount, inLostCount, inDrawCount, inFleeCount,varEnterGem);
	SET varInOutID := LAST_INSERT_ID();

	INSERT INTO `ssaccountsdb`.`SystemStreamInfo` (`CollectDate`, `GameLogonSuccess`) VALUES (CURRENT_DATE(), 1) ON DUPLICATE KEY UPDATE `GameLogonSuccess`=`GameLogonSuccess`+1;

	SELECT varInOutID AS "InOutID";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_record_user_match_ranking
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_record_user_match_ranking`;
DELIMITER ;;
CREATE  PROCEDURE `sp_record_user_match_ranking`(
IN inUserID int(11),IN inScore int(11),IN inRanking int(11),IN inServerID int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE varRanking INT;

	SELECT `Ranking` INTO varRanking FROM `MatchUserRanking` WHERE `UserID`=inUserID and `ServerID`=inServerID;
	IF ISNULL(varRanking) THEN
		INSERT INTO `MatchUserRanking` (`UserID`, `Ranking`, `Score`, `ServerID`, `RecordTime`) VALUES (inUserID, inRanking, inScore, inServerID, NOW());
	ELSE
		IF varRanking < inRanking THEN
			UPDATE `MatchUserRanking` SET `Ranking`=inRanking, `Score`=`Score`+inScore, `RecordTime`=NOW() WHERE `UserID`=inUserID and `ServerID`=inServerID;
		ELSE
			UPDATE `MatchUserRanking` SET `Score`=`Score`+inScore, `RecordTime`=NOW() WHERE `UserID`=inUserID and `ServerID`=inServerID;
		END IF;
	END IF;

END
;;
DELIMITER ;
