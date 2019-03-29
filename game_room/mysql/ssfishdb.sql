/*
Navicat MySQL Data Transfer

Source Server Version : 50621
Source Database       : ssfishdb

Target Server Type    : MYSQL
Target Server Version : 50621
File Encoding         : 65001

*/

USE `ssfishdb`;

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for t_bag
-- ----------------------------
DROP TABLE IF EXISTS `t_bag`;
CREATE TABLE `t_bag` (
  `UserId` int(11) NOT NULL,
  `ItemId` int(11) NOT NULL,
  `ItemCount` bigint(20) NOT NULL,
  `EndTime` bigint(20) NOT NULL DEFAULT '0' COMMENT '炮台结束时间',
  PRIMARY KEY (`UserId`,`ItemId`),
  KEY `IDX_ITEMID` (`ItemId`),
  KEY `IDX_ITEMID_ITEMCOUNT` (`ItemId`,`ItemCount`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_char_title
-- ----------------------------
DROP TABLE IF EXISTS `t_char_title`;
CREATE TABLE `t_char_title` (
  `UserId` int(11) DEFAULT NULL,
  `TitleType` tinyint(4) DEFAULT NULL,
  `TitleId` int(11) DEFAULT NULL,
  `TitleName` char(250) DEFAULT NULL,
  `AddTime` datetime DEFAULT NULL,
  KEY `IDX_USERID` (`UserId`) USING BTREE,
  KEY `IDX_TITLE_TYPE` (`TitleType`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for t_control_crit_rate
-- ----------------------------
DROP TABLE IF EXISTS `t_control_crit_rate`;
CREATE TABLE `t_control_crit_rate` (
  `UserId` int(11) NOT NULL,
  `FishId` int(11) NOT NULL,
  `CritRate` decimal(18,10) DEFAULT NULL,
  `MissRate` decimal(18,10) DEFAULT NULL,
  `StartTime` datetime DEFAULT NULL,
  `EndTime` datetime DEFAULT NULL,
  `InsertTime` datetime DEFAULT NULL,
  PRIMARY KEY (`UserId`,`FishId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_control_fish_rate
-- ----------------------------
DROP TABLE IF EXISTS `t_control_fish_rate`;
CREATE TABLE `t_control_fish_rate` (
  `UserId` int(11) NOT NULL,
  `FishId` int(11) NOT NULL,
  `AddRate` decimal(18,10) DEFAULT NULL,
  `StartTime` datetime DEFAULT NULL,
  `EndTime` datetime DEFAULT NULL,
  `InsertTime` datetime DEFAULT NULL,
  PRIMARY KEY (`UserId`,`FishId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_control_time_boss_rate
-- ----------------------------
DROP TABLE IF EXISTS `t_control_time_boss_rate`;
CREATE TABLE `t_control_time_boss_rate` (
  `Index` int(11) NOT NULL AUTO_INCREMENT,
  `UserId` int(11) DEFAULT NULL,
  `AddRate` decimal(18,10) DEFAULT NULL,
  PRIMARY KEY (`Index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_control_world_boss_rate
-- ----------------------------
DROP TABLE IF EXISTS `t_control_world_boss_rate`;
CREATE TABLE `t_control_world_boss_rate` (
  `Index` int(11) NOT NULL AUTO_INCREMENT,
  `UserId` int(11) DEFAULT NULL,
  `AddRate` decimal(18,10) DEFAULT NULL,
  PRIMARY KEY (`Index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_deduct_appid
-- ----------------------------
DROP TABLE IF EXISTS `t_deduct_appid`;
CREATE TABLE `t_deduct_appid` (
  `AppID` int(11) NOT NULL,
  `DeductNum` int(11) NOT NULL,
  `InsertTime` datetime DEFAULT NULL,
  `Mark` char(250) DEFAULT NULL,
  PRIMARY KEY (`AppID`),
  KEY `IDX_APPID` (`AppID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for t_deduct_old_user
-- ----------------------------
DROP TABLE IF EXISTS `t_deduct_old_user`;
CREATE TABLE `t_deduct_old_user` (
  `ID` int(10) NOT NULL,
  `UserID` int(11) NOT NULL,
  `UpdateTime` datetime NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `IDX_USERID` (`UserID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for t_deduct_user
-- ----------------------------
DROP TABLE IF EXISTS `t_deduct_user`;
CREATE TABLE `t_deduct_user` (
  `UserID` int(11) NOT NULL,
  `AppID` int(11) NOT NULL,
  `AppChannel` char(250) DEFAULT NULL,
  `AppVersion` char(250) DEFAULT NULL,
  `DeductFlag` int(11) DEFAULT NULL COMMENT '1不扣,2扣',
  PRIMARY KEY (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for t_dubious_user
-- ----------------------------
DROP TABLE IF EXISTS `t_dubious_user`;
CREATE TABLE `t_dubious_user` (
  `UserId` int(11) NOT NULL,
  PRIMARY KEY (`UserId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_gun_uplevel
-- ----------------------------
DROP TABLE IF EXISTS `t_gun_uplevel`;
CREATE TABLE `t_gun_uplevel` (
  `UserId` int(11) NOT NULL,
  `CurGunLevel` int(11) NOT NULL,
  `HaveCount` int(11) NOT NULL COMMENT '已结获得多少个了 ',
  `Gold` bigint(20) NOT NULL,
  `FireCount` int(11) NOT NULL,
  PRIMARY KEY (`UserId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_hd_drop_box
-- ----------------------------
DROP TABLE IF EXISTS `t_hd_drop_box`;
CREATE TABLE `t_hd_drop_box` (
  `ServerId` int(11) NOT NULL,
  `AddScore` int(11) NOT NULL,
  `DelScore` int(11) NOT NULL,
  PRIMARY KEY (`ServerId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_logon_ip_lv
-- ----------------------------
DROP TABLE IF EXISTS `t_logon_ip_lv`;
CREATE TABLE `t_logon_ip_lv` (
  `LogonMachine` char(32) NOT NULL,
  `ConnectIpLV` smallint(3) DEFAULT NULL,
  `BlackListFlag` tinyint(2) DEFAULT '0' COMMENT '0白名单，1黑名',
  `VipLevel` tinyint(4) DEFAULT '0',
  PRIMARY KEY (`LogonMachine`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for t_month_card
-- ----------------------------
DROP TABLE IF EXISTS `t_month_card`;
CREATE TABLE `t_month_card` (
  `UserId` int(11) NOT NULL,
  `StartTime` bigint(20) NOT NULL,
  `EndTime` bigint(20) NOT NULL,
  PRIMARY KEY (`UserId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_protect_fish
-- ----------------------------
DROP TABLE IF EXISTS `t_protect_fish`;
CREATE TABLE `t_protect_fish` (
  `UserId` int(11) NOT NULL,
  `FishIdInfo` char(250) DEFAULT NULL,
  `ChargeFishInfo` char(250) DEFAULT NULL,
  PRIMARY KEY (`UserId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_rescue_coin
-- ----------------------------
DROP TABLE IF EXISTS `t_rescue_coin`;
CREATE TABLE `t_rescue_coin` (
  `UserId` int(11) NOT NULL,
  `BrokeTime` bigint(20) NOT NULL,
  `CurCounts` int(11) NOT NULL,
  `ReceiveFlag` tinyint(4) NOT NULL,
  `RandNum` tinyint(4) unsigned zerofill NOT NULL DEFAULT '0000' COMMENT '随机第几次给新手保护',
  `FishCount` int(11) unsigned zerofill NOT NULL DEFAULT '00000000000',
  `BigFishCount` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`UserId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_reward_gold_fish
-- ----------------------------
DROP TABLE IF EXISTS `t_reward_gold_fish`;
CREATE TABLE `t_reward_gold_fish` (
  `UserId` int(11) NOT NULL,
  `FishCount` int(11) NOT NULL COMMENT '已结扑中了多少条',
  `SumScore` int(11) NOT NULL COMMENT '积累的积分',
  `RewardType` tinyint(4) NOT NULL,
  `RewardIndex` tinyint(4) NOT NULL,
  `BeforeFirst` tinyint(4) NOT NULL,
  `BeforeSec` tinyint(4) NOT NULL,
  `BeforeThr` tinyint(4) NOT NULL,
  `BeforeFour` tinyint(4) NOT NULL,
  `BeforeFive` tinyint(4) NOT NULL,
  `OpTime` int(11) NOT NULL COMMENT '上次时间',
  `BeforeSix` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`UserId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_signin
-- ----------------------------
DROP TABLE IF EXISTS `t_signin`;
CREATE TABLE `t_signin` (
  `UserId` int(11) NOT NULL,
  `SumDay` int(11) DEFAULT NULL COMMENT '累计登入了多少天了,跨月会重置',
  `PerAwardFlag` int(11) DEFAULT NULL COMMENT '每天签到的奖励标示,比如3=1+2,代表第一天和第二天领取了',
  `SumAwardFlag` int(11) DEFAULT NULL COMMENT '累计登入奖励标示,比如3=1+2,代表第一天和第二天领取了',
  `LoginDate` int(11) DEFAULT NULL,
  `SigninDate` int(11) DEFAULT NULL,
  `AllSumDay` int(11) DEFAULT '0' COMMENT '累计签到次数，不重置',
  PRIMARY KEY (`UserId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_task
-- ----------------------------
DROP TABLE IF EXISTS `t_task`;
CREATE TABLE `t_task` (
  `UserId` int(11) NOT NULL,
  `TaskType` tinyint(4) NOT NULL,
  `TaskId` int(11) NOT NULL,
  `TaskInfo` char(250) DEFAULT NULL COMMENT '任务完成的情况',
  `SuccessNum` int(11) DEFAULT NULL COMMENT '今天完成了多少次了',
  `Date` int(11) DEFAULT NULL,
  `SumNum` int(11) DEFAULT NULL COMMENT '总的任务能完成几次',
  PRIMARY KEY (`UserId`,`TaskType`,`TaskId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_user_control_rate
-- ----------------------------
DROP TABLE IF EXISTS `t_user_control_rate`;
CREATE TABLE `t_user_control_rate` (
  `UserId` bigint(20) NOT NULL COMMENT '玩家id',
  `FishInfo` char(250) DEFAULT NULL COMMENT 'id:rate|id:rate',
  `Crit` int(11) DEFAULT NULL,
  `Miss` int(11) DEFAULT NULL,
  `AddRate` decimal(11,8) DEFAULT NULL,
  `WorldBossAddRate` decimal(11,8) DEFAULT NULL,
  `FengHuangAddRate` decimal(11,8) DEFAULT NULL,
  PRIMARY KEY (`UserId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_user_invalid_gun
-- ----------------------------
DROP TABLE IF EXISTS `t_user_invalid_gun`;
CREATE TABLE `t_user_invalid_gun` (
  `UserId` int(11) NOT NULL,
  `TimeCount` bigint(20) NOT NULL,
  `GunCount` int(11) NOT NULL,
  `Gold` int(11) NOT NULL,
  `FishCount` int(11) NOT NULL,
  PRIMARY KEY (`UserId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_user_invitation_code
-- ----------------------------
DROP TABLE IF EXISTS `t_user_invitation_code`;
CREATE TABLE `t_user_invitation_code` (
  `UserId` int(11) NOT NULL,
  `InvitationCode` char(250) DEFAULT NULL COMMENT '邀请码',
  `CreateTime` datetime DEFAULT NULL COMMENT '生成时间',
  PRIMARY KEY (`UserId`),
  KEY `IndexCode` (`InvitationCode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_user_invitation_user
-- ----------------------------
DROP TABLE IF EXISTS `t_user_invitation_user`;
CREATE TABLE `t_user_invitation_user` (
  `UserId` int(11) NOT NULL,
  `InvitationUserId` int(11) DEFAULT NULL,
  `InvitationCode` char(250) DEFAULT NULL,
  `InvitationTime` datetime DEFAULT NULL,
  `Mark` char(250) DEFAULT NULL,
  PRIMARY KEY (`UserId`),
  KEY `Invitation` (`InvitationUserId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_user_ip
-- ----------------------------
DROP TABLE IF EXISTS `t_user_ip`;
CREATE TABLE `t_user_ip` (
  `UserId` int(11) NOT NULL,
  `Ip` char(20) NOT NULL,
  `LoginTime` datetime DEFAULT NULL,
  `UserIp` char(250) DEFAULT NULL COMMENT '指定使用这个ip',
  PRIMARY KEY (`UserId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_user_pay
-- ----------------------------
DROP TABLE IF EXISTS `t_user_pay`;
CREATE TABLE `t_user_pay` (
  `UserId` int(11) NOT NULL,
  `PayType` tinyint(4) NOT NULL COMMENT '2每日单笔；3每日累计；4活动期间累计',
  `Index` int(11) NOT NULL,
  `LeftTimes` int(11) NOT NULL,
  `Date` int(11) NOT NULL,
  `Flag` tinyint(2) NOT NULL,
  PRIMARY KEY (`UserId`,`PayType`,`Index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_user_pay_rmb
-- ----------------------------
DROP TABLE IF EXISTS `t_user_pay_rmb`;
CREATE TABLE `t_user_pay_rmb` (
  `UserId` int(11) NOT NULL,
  `PayType` tinyint(4) NOT NULL COMMENT '3当日累计，4活动期间累计',
  `Rmb` int(11) NOT NULL,
  `Date` int(11) NOT NULL,
  PRIMARY KEY (`UserId`,`PayType`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_world_boss_score
-- ----------------------------
DROP TABLE IF EXISTS `t_world_boss_score`;
CREATE TABLE `t_world_boss_score` (
  `ID` int(11) NOT NULL,
  `PoolScore` int(11) NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for volcanotablenetwin
-- ----------------------------
DROP TABLE IF EXISTS `volcanotablenetwin`;
CREATE TABLE `volcanotablenetwin` (
  `ServerID` int(11) NOT NULL COMMENT '房间ID',
  `TableID` int(11) NOT NULL COMMENT '桌子ID',
  `Score` bigint(20) NOT NULL COMMENT '房间累计赚取鱼币池',
  PRIMARY KEY (`ServerID`,`TableID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Procedure structure for sp_change_black_list
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_change_black_list`;
DELIMITER ;;
CREATE  PROCEDURE `sp_change_black_list`()
THIS_PROCEDURE:BEGIN
	DECLARE varUserID INT;
	DECLARE varMachineId CHAR(32);
	DECLARE varMachineId_1 CHAR(32);
	DECLARE varVipLevel INT;
	DECLARE varVipLevel_1 INT;
	DECLARE varUserIp CHAR(255);
	DECLARE varBlackListFalg INT;
	DECLARE varBlackListFalg_1 INT;
	DECLARE varExitLoop TINYINT;

	DECLARE varCursor1 CURSOR FOR SELECT a.RegisterMachine,a.MemberOrder,b.UserIp FROM ssaccountsdb.accountsinfo a LEFT JOIN ssfishdb.t_user_ip b on a.UserID = b.UserId WHERE a.RegisterMachine <>""; 

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET varExitLoop := 1;	

	OPEN varCursor1;
	itemLoop: LOOP
		SET varExitLoop := 0;
		FETCH varCursor1 INTO varMachineId, varVipLevel, varUserIp;
		IF varExitLoop=1 THEN
			LEAVE itemLoop;
		END IF;

		SET varBlackListFalg := 0;
		IF varVipLevel = 0 THEN
			IF varUserIp <> "" THEN
				SET varBlackListFalg := 1;
			END IF;
		END IF;

		SELECT `LogonMachine`, `BlackListFlag`, `VipLevel` INTO varMachineId_1, varBlackListFalg_1, varVipLevel_1 FROM `ssfishdb`.`t_logon_ip_lv` WHERE `LogonMachine` = varMachineId;
		IF NOT ISNULL(varMachineId_1) THEN
				IF varVipLevel_1 > varVipLevel THEN
					SET varVipLevel := varVipLevel_1;
					SET varBlackListFalg := 0;
				END IF;
		END IF;

		INSERT INTO `ssfishdb`.`t_logon_ip_lv` (`LogonMachine`, `ConnectIpLV`, `BlackListFlag`, `VipLevel`) VALUES (varMachineId, '0', varBlackListFalg, varVipLevel) ON DUPLICATE KEY UPDATE BlackListFlag=varBlackListFalg,VipLevel=varVipLevel;

END LOOP;
	CLOSE varCursor1;


END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_deduct_appid
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_deduct_appid`;
DELIMITER ;;
CREATE  PROCEDURE `sp_deduct_appid`(IN `inAppID` INT,IN `indeductNum` INT,IN `inType` INT,IN `inMark` CHAR(250))
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);
	DECLARE varMaxUserID INT;
	DECLARE varDeductNum INT;
	DECLARE varInsertTime VARCHAR(255);
	DECLARE varMark VARCHAR(255);

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode = -1;
		SET retMsg = "数据库内部错误";
		SELECT retCode, retMsg;
	END;

	START TRANSACTION;

		IF inType = 1 THEN
			SELECT MAX(UserID) INTO varMaxUserID FROM ssaccountsdb.accountsinfo;
			SELECT DeductNum,InsertTime,Mark INTO varDeductNum,varInsertTime,varMark FROM `ssfishdb`.`t_deduct_appid` WHERE AppID = inAppID;
			IF NOT ISNULL(varDeductNum) THEN
				INSERT INTO `ssrecorddb`.`t_deduct_appid` (AppID,DeductNum,InsertTime,Mark)VALUES(inAppID,varDeductNum,varInsertTime,varMark);
			END IF;

			INSERT INTO `ssfishdb`.`t_deduct_appid` (AppID,DeductNum,InsertTime,Mark)VALUES(inAppID,indeductNum,NOW(),inMark) ON DUPLICATE KEY UPDATE DeductNum=indeductNum,InsertTime=NOW(),Mark=inMark;
			INSERT INTO `ssfishdb`.`t_deduct_old_user` (ID,UserID,UpdateTime)VALUES(1,varMaxUserID,NOW()) ON DUPLICATE KEY UPDATE UserID = varMaxUserID,UpdateTime=NOW();
		ELSE
			UPDATE `ssfishdb`.`t_deduct_appid` SET Mark = inMark WHERE AppID = inAppID;
		END IF;

	COMMIT;

	SET retCode := 0;
	SET retMsg := "success";
	SELECT retCode, retMsg,varMaxUserID;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_deduct_user
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_deduct_user`;
DELIMITER ;;
CREATE  PROCEDURE `sp_deduct_user`(IN `inUserID` INT,IN `inAppID` INT,IN `inAppChannel` CHAR(250),IN `inAppVersion` CHAR(250))
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT; #1不扣量，否则扣
	DECLARE retMsg VARCHAR(255);
	DECLARE varUserID INT;
	DECLARE varOldUserID INT;
	DECLARE varDeductNum INT;
	DECLARE vartempNum INT;
	DECLARE varDeductFlag INT;
	DECLARE varAppVersion VARCHAR(255);

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode = -1;
		SET retMsg = "数据库内部错误";
		SELECT retCode, retMsg;
	END;

	SELECT UserID INTO varOldUserID FROM `ssfishdb`.`t_deduct_old_user`;
	IF ISNULL(varOldUserID) THEN
		SELECT MAX(UserID) INTO varOldUserID FROM ssaccountsdb.accountsinfo;
		INSERT INTO `ssfishdb`.`t_deduct_old_user` (ID,UserID,UpdateTime)VALUES(1,varOldUserID,NOW()) ON DUPLICATE KEY UPDATE UserID = varOldUserID;
	END IF;

	SELECT AppVersion, DeductFlag INTO varAppVersion, varDeductFlag FROM `ssfishdb`.`t_deduct_user` WHERE UserID = inUserID;
	IF not ISNULL(varDeductFlag) THEN
		if varAppVersion != inAppVersion THEN
			SET retCode := 2;
			SET retMsg := "已经统计过了11";
		ELSE
			SET retCode := varDeductFlag;
			SET retMsg := "已经统计过了22";
		END IF;

		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	SELECT DeductNum INTO varDeductNum FROM `ssfishdb`.`t_deduct_appid` WHERE AppID = inAppID;
	IF ISNULL(varDeductNum) THEN
		SET varDeductNum := 0; 
	END IF;

	IF varDeductNum = 0 THEN
		set vartempNum := inUserID%10;
		IF vartempNum >= 3 THEN
			SET retCode := 1; -- 不扣
		ELSE
			SET retCode := 2; -- 扣
		END IF;
	ELSE
		set vartempNum := inUserID%10;
		IF vartempNum >= varDeductNum/10 THEN
			SET retCode := 1; -- 不扣
		ELSE
			SET retCode := 2; -- 扣
		END IF;
	END IF;

	INSERT INTO `ssfishdb`.`t_deduct_user` (UserID,AppID,AppChannel,AppVersion,DeductFlag)VALUES(inUserID,inAppID,inAppChannel,inAppVersion,retCode) ON DUPLICATE KEY UPDATE AppID=inAppID,AppChannel=inAppChannel,AppVersion=inAppVersion,DeductFlag=retCode;
	
	SET retMsg := "success";
	SELECT retCode, retMsg,varOldUserID,varDeductNum,vartempNum;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_dubious_user_generate
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_dubious_user_generate`;
DELIMITER ;;
CREATE  PROCEDURE `sp_dubious_user_generate`(
IN inUserId int(11))
    SQL SECURITY INVOKER
BEGIN
	DECLARE varUserID INT;
	DECLARE i INT DEFAULT 0;
	
	SELECT MAX(`UserId`) INTO varUserID FROM `t_dubious_user`;
	IF ISNULL(varUserID) THEN
		SET varUserID := 1;
	ELSE
		SET varUserID := varUserID + 1;
		SET i := varUserID;
	END IF;

	WHILE i <= inUserId DO
		INSERT INTO t_dubious_user (`UserId`) VALUES (varUserID);
		SET varUserID := varUserID + 1;
		SET i := i + 1;
	END WHILE;

END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_user_invitation
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_user_invitation`;
DELIMITER ;;
CREATE  PROCEDURE `sp_user_invitation`(
IN inInvitationCode char(250),IN inUserID int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);
	DECLARE varUserID INT;
	DECLARE varCreateTime VARCHAR(255);
	DECLARE varRegisterTime VARCHAR(255);
	DECLARE varUserID1 INT;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode = -1;
		SET retMsg = "数据库内部错误";
		SELECT retCode, retMsg;
	END;

		SELECT `UserId`,`CreateTime` INTO varUserID,varCreateTime FROM `ssfishdb`.`t_user_invitation_code` where `InvitationCode`=`inInvitationCode`; 
		IF ISNULL(varUserID) THEN
				SET retCode := 1;
				SET retMsg := "该邀请码无效";
				SELECT retCode, retMsg;
				LEAVE THIS_PROCEDURE;
		END IF;

		SELECT `RegisterDate` INTO varRegisterTime FROM `ssaccountsdb`.`AccountsInfo` where `UserID`=inUserID;
		IF ISNULL(varRegisterTime) THEN
				SET retCode := 2;
				SET retMsg := "找不到用户";
				SELECT retCode, retMsg;
				LEAVE THIS_PROCEDURE;
		END IF;

		IF EXISTS(SELECT `UserId` FROM `ssfishdb`.`t_user_invitation_user` where `UserId`=inUserID) THEN
				SET retCode := 3;
				SET retMsg := "你已经被邀请过了";
				SELECT retCode, retMsg;
				LEAVE THIS_PROCEDURE;
		END IF;

		IF varRegisterTime < varCreateTime THEN
				SET retCode := 4;
				SET retMsg := "您不是新用户,邀请码关联失败";
				SELECT retCode, retMsg;
				LEAVE THIS_PROCEDURE;
		END IF;

		INSERT INTO `ssfishdb`.`t_user_invitation_user` (UserId,InvitationUserId,InvitationCode,InvitationTime)VALUES(inUserID,varUserID,inInvitationCode,NOW());

	SET retCode := 0;
	SET retMsg := "邀请成功";
	SELECT retCode, retMsg, varUserID as "userId",varCreateTime;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_write_bag
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_write_bag`;
DELIMITER ;;
CREATE  PROCEDURE `sp_write_bag`(IN inUserId int(11),IN inGoodsID int(11),IN inGoodsCount int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);
	DECLARE varUserID INT;
	DECLARE varGoodsID INT;
	DECLARE varGoodsCount INT;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode = -1;
		SET retMsg = "数据库内部错误";
		SELECT retCode, retMsg;
	END;

	START TRANSACTION;
	
		SELECT `UserId`,`ItemId`, `ItemCount` INTO varUserID, varGoodsID, varGoodsCount FROM `ssfishdb`.`t_bag` WHERE `UserId`=inUserId AND `ItemId`=inGoodsID;
		IF varGoodsCount + inGoodsCount < 0 THEN
				UPDATE `ssfishdb`.`t_bag` SET `ItemCount`= 0 WHERE `UserId`=inUserId AND `ItemId`=inGoodsID;
				SET retCode := -2;
				SET retMsg := "背包数据变成负数了,重置为0";
		ELSE
				UPDATE `ssfishdb`.`t_bag` SET `ItemCount`=`ItemCount`+inGoodsCount WHERE `UserId`=inUserId AND `ItemId`=inGoodsID;
				SET retCode := 0;
				SET retMsg := "success";
		END IF;
	
	COMMIT;

	SELECT retCode, retMsg, varUserID as "userId";
END
;;
DELIMITER ;
