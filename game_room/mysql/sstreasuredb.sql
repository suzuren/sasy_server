/*
Navicat MySQL Data Transfer

Source Server Version : 50621
Source Database       : sstreasuredb

Target Server Type    : MYSQL
Target Server Version : 50621
File Encoding         : 65001

*/

USE `sstreasuredb`;

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for gameproperty
-- ----------------------------
DROP TABLE IF EXISTS `gameproperty`;
CREATE TABLE `gameproperty` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '道具标识',
  `Name` varchar(255) NOT NULL COMMENT '道具名字',
  `Gold` bigint(20) NOT NULL COMMENT '道具金币',
  `Discount` smallint(6) NOT NULL DEFAULT '90' COMMENT '会员折扣',
  `IssueArea` smallint(6) NOT NULL DEFAULT '3' COMMENT '发行范围',
  `ServiceArea` smallint(6) NOT NULL COMMENT '使用范围',
  `SendLoveLiness` bigint(20) NOT NULL COMMENT '增加魅力',
  `RecvLoveLiness` bigint(20) NOT NULL COMMENT '增加魅力',
  `RegulationsInfo` varchar(255) NOT NULL COMMENT '使用说明',
  `Nullity` tinyint(4) NOT NULL DEFAULT '0' COMMENT '禁止标志',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=212 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for gamescoreinfo
-- ----------------------------
DROP TABLE IF EXISTS `gamescoreinfo`;
CREATE TABLE `gamescoreinfo` (
  `UserID` int(10) unsigned NOT NULL DEFAULT '0',
  `Score` bigint(20) NOT NULL DEFAULT '0' COMMENT '用户积分（货币）',
  `Revenue` bigint(20) NOT NULL DEFAULT '0' COMMENT '游戏税收',
  `InsureScore` bigint(20) NOT NULL DEFAULT '0' COMMENT '银行金币',
  `WinCount` int(11) NOT NULL DEFAULT '0' COMMENT '胜局数目',
  `LostCount` int(11) NOT NULL DEFAULT '0' COMMENT '输局数目',
  `FleeCount` int(11) NOT NULL DEFAULT '0' COMMENT '逃局数目',
  `DrawCount` int(11) NOT NULL DEFAULT '0' COMMENT '和局数目',
  PRIMARY KEY (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for payorderconfirm
-- ----------------------------
DROP TABLE IF EXISTS `payorderconfirm`;
CREATE TABLE `payorderconfirm` (
  `OrderID` char(32) NOT NULL,
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
-- Table structure for payorderitem
-- ----------------------------
DROP TABLE IF EXISTS `payorderitem`;
CREATE TABLE `payorderitem` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `Price` decimal(18,2) NOT NULL DEFAULT '0.00',
  `Gold` int(10) unsigned NOT NULL DEFAULT '0',
  `GoldExtra` int(10) unsigned NOT NULL DEFAULT '0',
  `LimitTimes` smallint(6) NOT NULL DEFAULT '0',
  `LimitDays` smallint(6) NOT NULL DEFAULT '0',
  `IsRecommend` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `IsRepeatable` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `IsAllowRelevantBuy` tinyint(3) NOT NULL DEFAULT '0' COMMENT '是否允许小号购买',
  `StartDate` datetime NOT NULL,
  `EndDate` datetime NOT NULL,
  `MemberOrder` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `MemberOrderDays` smallint(6) unsigned NOT NULL DEFAULT '0',
  `Name` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=473 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for payorderitem_ex
-- ----------------------------
DROP TABLE IF EXISTS `payorderitem_ex`;
CREATE TABLE `payorderitem_ex` (
  `ID` int(11) NOT NULL COMMENT '充值id',
  `ItemInfo` char(250) DEFAULT NULL COMMENT '道具',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for s_free_score_info
-- ----------------------------
DROP TABLE IF EXISTS `s_free_score_info`;
CREATE TABLE `s_free_score_info` (
  `id` int(11) NOT NULL COMMENT 'userId',
  `earnDate` int(11) DEFAULT NULL COMMENT '领取时间(20151202）',
  `num` int(11) DEFAULT NULL COMMENT '领取次数',
  `vipFreeState` int(11) DEFAULT NULL COMMENT '各钻领取情况',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_fish_config
-- ----------------------------
DROP TABLE IF EXISTS `t_fish_config`;
CREATE TABLE `t_fish_config` (
  `FishId` int(11) NOT NULL,
  `FishName` char(32) DEFAULT NULL,
  `ConfigRate` decimal(18,10) DEFAULT NULL,
  `CritFlag` tinyint(2) DEFAULT '0' COMMENT '是否可以暴击，0否，1是',
  PRIMARY KEY (`FishId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_frist_charge_reward
-- ----------------------------
DROP TABLE IF EXISTS `t_frist_charge_reward`;
CREATE TABLE `t_frist_charge_reward` (
  `ID` int(11) NOT NULL,
  `MinRmb` int(11) NOT NULL,
  `MaxRmb` int(11) NOT NULL,
  `RewardList` varchar(2000) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for t_huo_dong_reward_config
-- ----------------------------
DROP TABLE IF EXISTS `t_huo_dong_reward_config`;
CREATE TABLE `t_huo_dong_reward_config` (
  `ActivityType` int(11) DEFAULT NULL,
  `ActivityId` int(11) DEFAULT NULL,
  `Index` int(11) DEFAULT NULL,
  `ActivityName` char(32) DEFAULT NULL,
  `NeedVip` tinyint(4) DEFAULT NULL,
  `PerDayMax` tinyint(4) DEFAULT NULL,
  `ServerMax` int(11) DEFAULT NULL,
  `NeedCondition` char(250) DEFAULT NULL,
  `RewardList` char(250) DEFAULT NULL,
  `Multiple` decimal(11,10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_huo_dong_time_config
-- ----------------------------
DROP TABLE IF EXISTS `t_huo_dong_time_config`;
CREATE TABLE `t_huo_dong_time_config` (
  `Index` int(11) NOT NULL,
  `Tips` char(250) DEFAULT NULL,
  `ActivityType` tinyint(4) DEFAULT NULL,
  `StartTime` datetime DEFAULT NULL,
  `EndTime` datetime DEFAULT NULL,
  `TuPianId` char(250) DEFAULT NULL,
  `BeiJingId` char(250) DEFAULT NULL,
  `TextName` char(250) DEFAULT NULL,
  `ActivityClass` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_item_compose
-- ----------------------------
DROP TABLE IF EXISTS `t_item_compose`;
CREATE TABLE `t_item_compose` (
  `ItemId` int(11) NOT NULL,
  `SourceItem` varchar(250) NOT NULL COMMENT '合成需要的道具',
  `TargetItemCount` int(11) NOT NULL COMMENT '合成生成的道具数量',
  PRIMARY KEY (`ItemId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_item_table_info
-- ----------------------------
DROP TABLE IF EXISTS `t_item_table_info`;
CREATE TABLE `t_item_table_info` (
  `ItemId` int(11) NOT NULL,
  `ItemName` char(250) NOT NULL,
  `Tips` char(250) NOT NULL,
  `Icon` int(11) NOT NULL,
  `ItemType` int(11) NOT NULL COMMENT '1.普通物品2箱子类3特殊物品',
  `UpMax` int(11) NOT NULL COMMENT '物品叠加上限',
  `Price` int(11) NOT NULL COMMENT '物品价格',
  `ItemFunction` int(11) NOT NULL,
  `IsGive` tinyint(3) NOT NULL DEFAULT '0' COMMENT '是否可以赠送 0 否，1是',
  `IsUse` tinyint(3) NOT NULL DEFAULT '0' COMMENT '是否可以使用 0否，1是',
  `IsCompose` tinyint(3) NOT NULL DEFAULT '0' COMMENT '是否可以合成 0 否 1 是',
  `LinkId` int(11) NOT NULL DEFAULT '0' COMMENT '适用后生成的物品，对于givetable表中去',
  `EquipId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ItemId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- ----------------------------
-- Table structure for t_rescue_coin
-- ----------------------------
DROP TABLE IF EXISTS `t_rescue_coin`;
CREATE TABLE `t_rescue_coin` (
  `Index` int(11) NOT NULL,
  `TimeCount` int(11) DEFAULT NULL,
  `GoldCount` int(11) DEFAULT NULL,
  PRIMARY KEY (`Index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- ----------------------------
-- Table structure for t_signin_award_info
-- ----------------------------
DROP TABLE IF EXISTS `t_signin_award_info`;
CREATE TABLE `t_signin_award_info` (
  `Index` int(11) NOT NULL,
  `Type` tinyint(4) DEFAULT NULL COMMENT '1连续登入奖励，2累计登入奖励',
  `DayId` int(11) DEFAULT NULL COMMENT '第几天',
  `ItemId` int(11) DEFAULT NULL,
  `ItemCount` int(11) DEFAULT NULL,
  PRIMARY KEY (`Index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- ----------------------------
-- Table structure for t_table_drop_gem
-- ----------------------------
DROP TABLE IF EXISTS `t_table_drop_gem`;
CREATE TABLE `t_table_drop_gem` (
  `Index` int(11) NOT NULL,
  `NeedGold` int(11) NOT NULL,
  PRIMARY KEY (`Index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_table_fly_bird_run_monster
-- ----------------------------
DROP TABLE IF EXISTS `t_table_fly_bird_run_monster`;
CREATE TABLE `t_table_fly_bird_run_monster` (
  `ID` int(11) NOT NULL,
  `MonsterType` tinyint(3) DEFAULT NULL,
  `MonsterName` char(32) DEFAULT NULL,
  `MinRate` int(11) DEFAULT NULL,
  `MaxRate` int(11) DEFAULT NULL,
  `Multiple` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for t_table_give
-- ----------------------------
DROP TABLE IF EXISTS `t_table_give`;
CREATE TABLE `t_table_give` (
  `Id` int(11) NOT NULL,
  `Name` char(250) NOT NULL,
  `Desc` char(250) NOT NULL,
  `Type` tinyint(3) NOT NULL COMMENT '1.随机给一，2玩家选1，3全给',
  `Item1` varchar(500) NOT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_table_gun_uplevel
-- ----------------------------
DROP TABLE IF EXISTS `t_table_gun_uplevel`;
CREATE TABLE `t_table_gun_uplevel` (
  `Level` int(11) NOT NULL COMMENT '炮等级',
  `Multiple` int(11) NOT NULL COMMENT '炮台等级',
  `NeedGem` int(11) NOT NULL COMMENT '升级需要的宝石',
  `RewardGold` int(11) NOT NULL COMMENT '奖级的金币',
  PRIMARY KEY (`Level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_table_reward_gold_fish
-- ----------------------------
DROP TABLE IF EXISTS `t_table_reward_gold_fish`;
CREATE TABLE `t_table_reward_gold_fish` (
  `Type` int(11) NOT NULL,
  `TypeName` char(250) NOT NULL,
  `NeedScore` int(11) NOT NULL COMMENT '抽奖需要的分数',
  `GoodsInfo` char(250) NOT NULL COMMENT 'id:count:minrate:maxrate|',
  `BeforeCount` tinyint(4) NOT NULL COMMENT '前多少次做一个固定的序列',
  `BeforeReward` char(250) NOT NULL COMMENT '前几次的奖励',
  PRIMARY KEY (`Type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_table_vip
-- ----------------------------
DROP TABLE IF EXISTS `t_table_vip`;
CREATE TABLE `t_table_vip` (
  `VipLevel` int(11) NOT NULL,
  `Tips` char(250) NOT NULL,
  `RMB` decimal(11,2) NOT NULL,
  `Sign` tinyint(3) NOT NULL,
  `Gem` decimal(11,10) NOT NULL,
  `ExGold` decimal(11,10) NOT NULL,
  `Gift` decimal(11,10) NOT NULL,
  `AwardFish` decimal(11,10) NOT NULL,
  `BossFish` decimal(11,10) NOT NULL,
  `GunLevel` int(11) NOT NULL,
  PRIMARY KEY (`VipLevel`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for t_task_table_info
-- ----------------------------
DROP TABLE IF EXISTS `t_task_table_info`;
CREATE TABLE `t_task_table_info` (
  `TaskId` int(11) NOT NULL,
  `Type` tinyint(4) NOT NULL,
  `limitFashShoot` tinyint(4) DEFAULT NULL COMMENT '快速射击',
  `limitAutoShoot` tinyint(4) DEFAULT NULL COMMENT '自动射击',
  `limitFortLevel` int(11) DEFAULT NULL COMMENT '炮台等级',
  `limitFortMulti` int(11) DEFAULT NULL COMMENT 'limitFortMulti',
  `goalInfo` char(250) DEFAULT NULL COMMENT '任务物品',
  `RewardInfo` char(250) DEFAULT NULL COMMENT 'id:count|id:count| 奖励物品',
  PRIMARY KEY (`TaskId`,`Type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC;

-- ----------------------------
-- Table structure for t_title_table_info
-- ----------------------------
DROP TABLE IF EXISTS `t_title_table_info`;
CREATE TABLE `t_title_table_info` (
  `ID` int(11) NOT NULL,
  `TitleType` tinyint(4) DEFAULT NULL COMMENT '1金币，2宝箱',
  `TitleID` int(11) DEFAULT NULL COMMENT '称号id',
  `TitleName` char(250) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for userpresenttoitem
-- ----------------------------
DROP TABLE IF EXISTS `userpresenttoitem`;
CREATE TABLE `userpresenttoitem` (
  `id` int(10) NOT NULL COMMENT '角色礼券兑换记录表， 角色id',
  `totalPay` int(10) DEFAULT NULL COMMENT '消费礼券',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for userpropertyvendor
-- ----------------------------
DROP TABLE IF EXISTS `userpropertyvendor`;
CREATE TABLE `userpropertyvendor` (
  `UserID` int(10) unsigned NOT NULL DEFAULT '0',
  `PropertyID` int(10) unsigned NOT NULL,
  `PropertyCount` int(11) NOT NULL,
  PRIMARY KEY (`UserID`,`PropertyID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for vipawardinfo
-- ----------------------------
DROP TABLE IF EXISTS `vipawardinfo`;
CREATE TABLE `vipawardinfo` (
  `id` int(10) NOT NULL COMMENT 'vip等级',
  `desc` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT '' COMMENT '描述信息',
  `freeScore` int(10) DEFAULT '0' COMMENT '可领取金币',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Procedure structure for p_change_present
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_change_present`;
DELIMITER ;;
CREATE  PROCEDURE `p_change_present`(
IN inPlatformID int(11),IN inVariationPresent int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);
	DECLARE varUserID INT;
	DECLARE varPresent INT;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode = -1;
		SET retMsg = "数据库内部错误";
		SELECT retCode, retMsg;
	END;

	START TRANSACTION;
	
		SELECT `UserID`, `Present` INTO varUserID, varPresent FROM `ssaccountsdb`.`AccountsInfo` WHERE `PlatformID`=inPlatformID;
/*
		IF varPresent+ inVariationPresent < 0 THEN
			SET retCode = -1;
			SET retMsg = "礼券不足";
			SELECT retCode, retMsg;
			LEAVE THIS_PROCEDURE;
		END IF;
		UPDATE `ssaccountsdb`.`AccountsInfo` SET `Present`=`Present`+inVariationPresent WHERE `PlatformID`=inPlatformID;
		*/
		INSERT INTO `ssrecorddb`.`PresentChange` SET `UserID`=varUserID, tp=2, `presentUsed`=(-inVariationPresent), `Datetime`=now();
	COMMIT;

	SET retCode := 0;
	SET retMsg := "success";
	SELECT retCode, retMsg, varUserID as "userId";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_bank_deposit
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_bank_deposit`;
DELIMITER ;;
CREATE  PROCEDURE `sp_bank_deposit`(
IN inUserID int(11),IN inAmount bigint(20))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	DECLARE varBankPrerequisite INT;
	DECLARE varRevenueRate INT;
	DECLARE varMemberOrder TINYINT UNSIGNED;
	DECLARE varRevenue BIGINT;
	DECLARE varScoreBefore BIGINT;
	DECLARE varInsureBefore BIGINT;
	DECLARE varScore BIGINT;
	DECLARE varInsure BIGINT;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode := -1;
		SET retMsg := "internel database error";
		SELECT retCode, retMsg;
	END;


	SELECT `StatusValue` INTO varBankPrerequisite FROM `ssaccountsdb`.`SystemStatusInfo` WHERE `StatusName`="BankPrerequisite";
	IF ISNULL(varBankPrerequisite) THEN
		SET varBankPrerequisite := 0;
	END IF;

	IF inAmount < varBankPrerequisite THEN
		SET retCode := 1;
		SET retMsg := CONCAT("存入保险柜的游戏币数目不能少于", varBankPrerequisite, ", 存入失败");
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	SELECT `MemberOrder` INTO varMemberOrder FROM `ssaccountsdb`.`AccountsInfo` WHERE `UserID`=inUserID;
	IF varMemberOrder > 0 THEN
		SELECT `StatusValue` INTO varRevenueRate FROM `ssaccountsdb`.`SystemStatusInfo` WHERE `StatusName`=CONCAT("RevenueRateSaveMember", varMemberOrder);
	ELSE
		SELECT `StatusValue` INTO varRevenueRate FROM `ssaccountsdb`.`SystemStatusInfo` WHERE `StatusName`="RevenueRateSave";
	END IF;
	IF ISNULL(varRevenueRate) THEN
		SET varRevenueRate := 1;
	END IF;

	-- 税收调整
	IF varRevenueRate > 300 THEN
		SET varRevenueRate := 300;
	END IF;
	SET varRevenue := inAmount * varRevenueRate / 1000;

	START TRANSACTION;
		SELECT `Score`, `InsureScore` INTO varScoreBefore, varInsureBefore FROM `GameScoreInfo` WHERE `UserID`=inUserID;
		IF ISNULL(varScoreBefore) THEN
			ROLLBACK;
			
			SET retCode := 2;
			SET retMsg := "找不到您的金币数据";
			SELECT retCode, retMsg;
			LEAVE THIS_PROCEDURE;
		END IF;


		UPDATE `GameScoreInfo` SET `Score`=`Score`-inAmount, `Revenue`=`Revenue`+varRevenue, `InsureScore`=`InsureScore`+inAmount-varRevenue WHERE `UserID`=inUserID;

		SELECT `Score`, `InsureScore` INTO varScore, varInsure FROM `GameScoreInfo` WHERE `UserID`=inUserID;
		IF varScore < 0 THEN
			ROLLBACK;
			
			SET retCode := 3;
			SET retMsg := "您当前金币的可用余额不足，存入失败！";
			SELECT retCode, retMsg;
			LEAVE THIS_PROCEDURE;
		END IF;

		INSERT INTO `ssrecorddb`.`Bank` (`UserID`, `Ctime`, `Type`, `Score`, `Insure`, `ScoreBefore`, `InsureBefore`) VALUES (inUserID, NOW(), 'deposit', varScore, varInsure, varScoreBefore, varInsureBefore);

	COMMIT;


	SET retCode := 0;
	SET retMsg := "success";

	SELECT retCode, retMsg, varScore AS "Score", varInsure AS "Insure";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_bank_query
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_bank_query`;
DELIMITER ;;
CREATE  PROCEDURE `sp_bank_query`(
IN inUserID int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	DECLARE varScore BIGINT;
	DECLARE varInsure BIGINT;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		SET retCode := -1;
		SET retMsg := "internel database error";
		SELECT retCode, retMsg;
	END;

	SELECT `Score`, `InsureScore` INTO varScore, varInsure FROM `GameScoreInfo` WHERE `UserID`=inUserID;
	IF ISNULL(varScore) THEN		
		SET retCode := 2;
		SET retMsg := "找不到您的金币数据";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	SET retCode := 0;
	SET retMsg := "success";

	SELECT retCode, retMsg, varScore AS "Score", varInsure AS "Insure";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_bank_withdraw
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_bank_withdraw`;
DELIMITER ;;
CREATE  PROCEDURE `sp_bank_withdraw`(
IN inUserID int(11),IN inAmount bigint(20))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	DECLARE varBankPrerequisite INT;
	DECLARE varRevenueRate INT;
	DECLARE varRevenue BIGINT;
	DECLARE varScoreBefore BIGINT;
	DECLARE varInsureBefore BIGINT;
	DECLARE varScore BIGINT;
	DECLARE varInsure BIGINT;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode := -1;
		SET retMsg := "internel database error";
		SELECT retCode, retMsg;
	END;

	SELECT `StatusValue` INTO varBankPrerequisite FROM `ssaccountsdb`.`SystemStatusInfo` WHERE `StatusName`="BankPrerequisite";
	IF ISNULL(varBankPrerequisite) THEN
		SET varBankPrerequisite := 0;
	END IF;
	IF inAmount < varBankPrerequisite THEN
		SET retCode := 1;
		SET retMsg := CONCAT("从保险柜取出的游戏币数目不能少于", varBankPrerequisite, ", 提取失败");
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	SELECT `StatusValue` INTO varRevenueRate FROM `ssaccountsdb`.`SystemStatusInfo` WHERE `StatusName`="RevenueRateTake";
	IF ISNULL(varRevenueRate) THEN
		SET varRevenueRate := 1;
	END IF;

	-- 税收调整
	IF varRevenueRate > 300 THEN
		SET varRevenueRate := 300;
	END IF;
	SET varRevenue := inAmount * varRevenueRate / 1000;

	START TRANSACTION;
		SELECT `Score`, `InsureScore` INTO varScoreBefore, varInsureBefore FROM `GameScoreInfo` WHERE `UserID`=inUserID;
		IF ISNULL(varScoreBefore) THEN
			ROLLBACK;
			
			SET retCode := 2;
			SET retMsg := "找不到您的金币数据";
			SELECT retCode, retMsg;
			LEAVE THIS_PROCEDURE;
		END IF;


		UPDATE `GameScoreInfo` SET `Score`=`Score`+inAmount-varRevenue, `Revenue`=`Revenue`+varRevenue, `InsureScore`=`InsureScore`-inAmount WHERE `UserID`=inUserID;

		SELECT `Score`, `InsureScore` INTO varScore, varInsure FROM `GameScoreInfo` WHERE `UserID`=inUserID;
		IF varInsure < 0 THEN
			ROLLBACK;
			
			SET retCode := 3;
			SET retMsg := "您当前保险柜的游戏币余额不足，提取失败！";
			SELECT retCode, retMsg;
			LEAVE THIS_PROCEDURE;
		END IF;

		INSERT INTO `ssrecorddb`.`Bank` (`UserID`, `Ctime`, `Type`, `Score`, `Insure`, `ScoreBefore`, `InsureBefore`) VALUES (inUserID, NOW(), 'withdraw', varScore, varInsure, varScoreBefore, varInsureBefore);

	COMMIT;


	SET retCode := 0;
	SET retMsg := "success";

	SELECT retCode, retMsg, varScore AS "Score", varInsure AS "Insure";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_inner_pay_order_item_available_time
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_inner_pay_order_item_available_time`;
DELIMITER ;;
CREATE  PROCEDURE `sp_inner_pay_order_item_available_time`(
IN inUserID int(11),IN inPayOrderItemID int(11),IN inLimitTimes smallint(6),IN inLimitDays smallint(6),IN inIsRepeatable tinyint(3) unsigned,OUT outAvailableTimes smallint(6))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE varOrderCount INT;

	IF inIsRepeatable = 1 THEN
		IF inLimitTimes>0 AND inLimitDays>0 THEN
			SELECT COUNT(`UserID`) INTO varOrderCount FROM `sstreasuredb`.`PayOrderConfirm` WHERE `UserID`=inUserID AND `PayOrderItemID`=inPayOrderItemID AND TO_DAYS(FinishTime)>=TO_DAYS(NOW());
			SET outAvailableTimes := inLimitTimes - varOrderCount;
			IF outAvailableTimes < 0 THEN
				SET outAvailableTimes := 0;
			END IF;
		ELSE
			SET outAvailableTimes := -1;
		END IF;
	ELSE
		SELECT COUNT(`UserID`) INTO varOrderCount FROM `sstreasuredb`.`PayOrderConfirm` WHERE `UserID`=inUserID AND `PayOrderItemID`=inPayOrderItemID;
		SET outAvailableTimes := inLimitTimes - varOrderCount;
		IF outAvailableTimes < 0 THEN
			SET outAvailableTimes := 0;
		END IF;
	END IF;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_load_box_ranking_list
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_load_box_ranking_list`;
DELIMITER ;;
CREATE  PROCEDURE `sp_load_box_ranking_list`()
THIS_PROCEDURE:BEGIN

	SELECT A.UserID, A.NickName, A.FaceID, A.Gender,A.MemberOrder,B.PtBox,B.GemBox,B.ZhiZhunBox,C.Signature,C.HideFlag ,B.PtBox*100 + B.GemBox*200 + B.ZhiZhunBox*1000 AS varSumValue
	FROM 
		(
			select UserId, SUM(PtBox) as PtBox,SUM(GemBox) as GemBox,SUM(ZhiZhunBox) as ZhiZhunBox 
			FROM 
			(
				select UserId, ifnull(case ItemId WHEN 1011 then ItemCount end, 0) AS PtBox,
					ifnull(CASE ItemId when 1022 then ItemCount END, 0) as GemBox,
						ifnull(CASE ItemId when 1023 then ItemCount END, 0) as ZhiZhunBox 
				from `ssfishdb`.`t_bag` where ItemId in(1011,1022,1023)
			) a GROUP BY UserId
		) AS B 
	LEFT JOIN `ssaccountsdb`.`AccountsInfo` AS A  ON A.UserID=B.UserId 
	LEFT JOIN `ssaccountsdb`.`AccountsSignature` AS C ON  A.UserID=C.UserID AND A.`Status` <> 4
	ORDER BY varSumValue DESC
	LIMIT 10;

END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_load_loveLines_ranking_list
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_load_loveLines_ranking_list`;
DELIMITER ;;
CREATE  PROCEDURE `sp_load_loveLines_ranking_list`(
)
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE varUserID INT;
	DECLARE varNickName CHAR(32);
	DECLARE varFaceID SMALLINT;
	DECLARE varGender TINYINT;
	DECLARE varGift INT;
	DECLARE varLoveLiness INT;
	DECLARE varUserMedal INT;
	DECLARE varScore BIGINT;
	DECLARE varSignature VARCHAR(255);
	DECLARE varPlatformID INT;
	DECLARE varExperience INT;
	DECLARE varMemberOrder INT;
	DECLARE varPlatformFace CHAR(32);

	DECLARE varExitLoop TINYINT;
	DECLARE varCursor1 CURSOR FOR SELECT A.UserID, A.NickName, A.FaceID, A.Gender, A.Gift, A.LoveLiness, A.UserMedal, A.PlatformID, A.Experience, A.MemberOrder, B.Score, C.Signature, F.PlatformFace FROM `ssaccountsdb`.`AccountsInfo` AS A LEFT JOIN `sstreasuredb`.`GameScoreInfo` AS B ON A.UserID=B.UserID LEFT JOIN `ssaccountsdb`.`AccountsSignature` AS C ON  A.UserID=C.UserID LEFT JOIN `ssaccountsdb`.`AccountsFace` AS F ON A.UserID=F.UserID WHERE TIMESTAMPDIFF(DAY, A.LastLogonDate, NOW()) < 7 ORDER BY A.LoveLiness DESC LIMIT 10;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET varExitLoop := 1;

	DROP TEMPORARY TABLE IF EXISTS `TEMP_LoveLines_rank`;
	CREATE TEMPORARY TABLE `TEMP_LoveLines_rank` (
		`UserID` int(10) unsigned NOT NULL,
		`NickName` char(32) DEFAULT NULL,
		`FaceID` smallint(3) NOT NULL DEFAULT '1',
		`Gender` tinyint(4) NOT NULL DEFAULT '0',
		`Gift` int(11) NOT NULL DEFAULT '0',
		`LoveLiness` int(11) NOT NULL DEFAULT '0',
		`UserMedal` int(11) NOT NULL DEFAULT '0',
		`Score` bigint(20) NOT NULL DEFAULT '0',
		`Signature` varchar(255) DEFAULT NULL,
		`PlatformID` int(10) DEFAULT '0',
		`Experience` int(10) DEFAULT '0',
		`MemberOrder` int(10) DEFAULT '0',
		`PlatformFace` varchar(32) DEFAULT NULL,
		PRIMARY KEY (`UserID`)
	) DEFAULT CHARSET=utf8;

	OPEN varCursor1;
	itemLoop: LOOP
		FETCH varCursor1 INTO varUserID, varNickName, varFaceID, varGender, varGift, varLoveLiness, varUserMedal, varPlatformID, varExperience, varMemberOrder, varScore, varSignature, varPlatformFace;
		IF varExitLoop=1 THEN
			LEAVE itemLoop;
		END IF;

		INSERT INTO `TEMP_LoveLines_rank` (`UserID`, `NickName`, `FaceID`, `Gender`, `Gift`, `LoveLiness`, `UserMedal`, `Score`, `Signature`, `PlatformID`, `Experience`, `MemberOrder`, `PlatformFace`) VALUES (varUserID, varNickName, varFaceID, varGender, varGift, varLoveLiness, varUserMedal, varScore, varSignature, varPlatformID, varExperience, varMemberOrder, varPlatformFace);
	END LOOP;
	CLOSE varCursor1;

	SELECT * FROM `TEMP_LoveLines_rank` ORDER BY `LoveLiness` DESC;

	DROP TEMPORARY TABLE IF EXISTS `TEMP_LoveLines_rank`;

END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_load_wealth_ranking_list
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_load_wealth_ranking_list`;
DELIMITER ;;
CREATE  PROCEDURE `sp_load_wealth_ranking_list`()
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE varUserID INT;
	DECLARE varNickName CHAR(32);
	DECLARE varFaceID SMALLINT;
	DECLARE varGender TINYINT;
	DECLARE varGift INT;
	DECLARE varLoveLiness INT;
	DECLARE varUserMedal INT;
	DECLARE varScore BIGINT;
	DECLARE varSignature VARCHAR(255);
	DECLARE varHideFlag SMALLINT;
	DECLARE varPlatformID INT;
	DECLARE varExperience INT;
	DECLARE varMemberOrder INT;
	DECLARE varPlatformFace CHAR(32);

	DECLARE varExitLoop TINYINT;
	#DECLARE varCursor1 CURSOR FOR SELECT A.UserID, A.NickName, A.FaceID, A.Gender, A.Gift, A.LoveLiness, A.UserMedal, A.PlatformID, A.Experience, A.MemberOrder, B.Score, C.Signature, F.PlatformFace FROM `ssaccountsdb`.`AccountsInfo` AS A LEFT JOIN `sstreasuredb`.`GameScoreInfo` AS B ON A.UserID=B.UserID LEFT JOIN `ssaccountsdb`.`AccountsSignature` AS C ON  A.UserID=C.UserID LEFT JOIN `ssaccountsdb`.`AccountsFace` AS F ON A.UserID=F.UserID WHERE TIMESTAMPDIFF(DAY, A.LastLogonDate, NOW()) < 7 ORDER BY B.Score DESC LIMIT 10;
	DECLARE varCursor1 CURSOR FOR SELECT A.UserID, A.NickName, A.FaceID, A.Gender, B.Gift, A.LoveLiness, A.UserMedal, A.PlatformID, A.Experience, A.MemberOrder, B.Score, C.Signature,C.HideFlag,F.PlatformFace FROM `ssaccountsdb`.`AccountsInfo` AS A LEFT JOIN (select UserId, SUM(Gift) as Gift,SUM(Score) as Score FROM (select UserId, ifnull(case ItemId WHEN 1003 then ItemCount end, 0) AS Gift,ifnull(CASE ItemId when 1001 then ItemCount END, 0) as Score from `ssfishdb`.`t_bag` where ItemId in(1001,1003) ) a GROUP BY UserId) AS B ON A.UserID=B.UserId LEFT JOIN `ssaccountsdb`.`AccountsSignature` AS C ON  A.UserID=C.UserID LEFT JOIN `ssaccountsdb`.`AccountsFace` AS F ON A.UserID=F.UserID WHERE A.`Status` <> 4 AND TIMESTAMPDIFF(DAY, A.LastLogonDate, NOW()) < 7 ORDER BY B.Score DESC LIMIT 10;
	#DECLARE varCursor2 CURSOR FOR SELECT A.UserID, A.NickName, A.FaceID, A.Gender, B.Gift, A.LoveLiness, A.UserMedal, A.PlatformID, A.Experience, A.MemberOrder, B.Score, C.Signature,C.HideFlag,F.PlatformFace FROM `ssaccountsdb`.`AccountsInfo` AS A LEFT JOIN (select UserId, SUM(Gift) as Gift,SUM(Score) as Score FROM (select UserId, ifnull(case ItemId WHEN 1003 then ItemCount end, 0) AS Gift,ifnull(CASE ItemId when 1001 then ItemCount END, 0) as Score from `ssfishdb`.`t_bag` where ItemId in(1001,1003) ) a GROUP BY UserId) AS B ON A.UserID=B.UserId LEFT JOIN `ssaccountsdb`.`AccountsSignature` AS C ON  A.UserID=C.UserID LEFT JOIN `ssaccountsdb`.`AccountsFace` AS F ON A.UserID=F.UserID WHERE A.`Status` = 4 AND TIMESTAMPDIFF(HOUR, A.LastLogonDate, NOW()) < 24 ORDER BY B.Score DESC LIMIT 3;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET varExitLoop := 1;	

	DROP TEMPORARY TABLE IF EXISTS `TEMP_Wealth_rank`;
	CREATE TEMPORARY TABLE `TEMP_Wealth_rank` (
		`UserID` int(10) unsigned NOT NULL,
		`NickName` char(32) DEFAULT NULL,
		`FaceID` smallint(3) NOT NULL DEFAULT '1',
		`Gender` tinyint(4) NOT NULL DEFAULT '0',
		`Gift` int(11) NOT NULL DEFAULT '0',
		`LoveLiness` int(11) NOT NULL DEFAULT '0',
		`UserMedal` int(11) NOT NULL DEFAULT '0',
		`Score` bigint(20) NOT NULL DEFAULT '0',
		`Signature` varchar(255) DEFAULT NULL,
		`HideFlag` int(10) DEFAULT '0',
		`PlatformID` int(10) DEFAULT '0',
		`Experience` int(10) DEFAULT '0',
		`MemberOrder` int(10) DEFAULT '0',
		`PlatformFace` varchar(32) DEFAULT NULL,
		PRIMARY KEY (`UserID`)
	) DEFAULT CHARSET=utf8;

	OPEN varCursor1;
	itemLoop: LOOP
		FETCH varCursor1 INTO varUserID, varNickName, varFaceID, varGender, varGift, varLoveLiness, varUserMedal, varPlatformID, varExperience, varMemberOrder, varScore, varSignature,varHideFlag, varPlatformFace;
		IF varExitLoop=1 THEN
		LEAVE itemLoop;
		END IF;

		INSERT INTO `TEMP_Wealth_rank` (`UserID`, `NickName`, `FaceID`, `Gender`, `Gift`, `LoveLiness`, `UserMedal`, `Score`, `Signature`,`HideFlag`, `PlatformID`, `Experience`, `MemberOrder`, `PlatformFace`) VALUES (varUserID, varNickName, varFaceID, varGender, varGift, varLoveLiness, varUserMedal, varScore, varSignature,varHideFlag, varPlatformID, varExperience, varMemberOrder, varPlatformFace);
	END LOOP;
	CLOSE varCursor1;

	#SET varExitLoop := 0;

	#OPEN varCursor2;
	#itemLoop2: LOOP
	#	FETCH varCursor2 INTO varUserID, varNickName, varFaceID, varGender, varGift, varLoveLiness, varUserMedal, varPlatformID, varExperience, varMemberOrder, varScore, varSignature,varHideFlag, varPlatformFace;
		#IF varExitLoop=1 THEN
			#LEAVE itemLoop2;
		#END IF;

		#INSERT INTO `TEMP_Wealth_rank` (`UserID`, `NickName`, `FaceID`, `Gender`, `Gift`, `LoveLiness`, `UserMedal`, `Score`, `Signature`,`HideFlag`, `PlatformID`, `Experience`, `MemberOrder`, `PlatformFace`) VALUES (varUserID, varNickName, varFaceID, varGender, varGift, varLoveLiness, varUserMedal, varScore, varSignature,varHideFlag, varPlatformID, varExperience, varMemberOrder, varPlatformFace);
	#END LOOP;
	#CLOSE varCursor2;



	SELECT * FROM `TEMP_Wealth_rank` ORDER BY `Score` DESC LIMIT 10;

	DROP TEMPORARY TABLE IF EXISTS `TEMP_Wealth_rank`;

END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_pay_order_confirm
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_pay_order_confirm`;
DELIMITER ;;
CREATE  PROCEDURE `sp_pay_order_confirm`(IN inOrderID char(32),IN inPayChannel int(11),IN inPlatformID int(11),IN inCurrencyType char(5),IN inCurrencyAmount decimal(18,2),IN inPayID int(11),IN inSubmitTime datetime,IN inSandBox int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	DECLARE varUserID INT;
	DECLARE varStatus TINYINT UNSIGNED;
	DECLARE varScoreBefore BIGINT;
	DECLARE varInsureBefore BIGINT;

	DECLARE varGold INT;
	DECLARE varExtraGold INT;
	DECLARE varTotalGold INT;

	DECLARE varLimitTimes SMALLINT;
	DECLARE varLimitDays SMALLINT;
	DECLARE varIsRepeatable TINYINT;
	DECLARE varMemberOrder TINYINT;
	DECLARE varMemberOrderDays SMALLINT;

	-- 会员信息
	DECLARE varMemberOverDate DATETIME;
	DECLARE varMemberSwitchDate DATETIME;

	DECLARE varAvailableTimes SMALLINT;
	DECLARE varMemberUserRight INT UNSIGNED;
	DECLARE varContribution INT;

	DECLARE varCurrentScore BIGINT;
	DECLARE varCurrentInsure BIGINT;

	DECLARE varCurrentContribution INT;
	DECLARE varCurrentMemberOrder TINYINT UNSIGNED;
	DECLARE varCurrentUserRight INT;
	DECLARE varPayBeforeScore INT;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode := -1;
		SET retMsg := "internel database error";
		SELECT retCode, retMsg;
	END;

	-- 查询用户
	SELECT `UserID`, `Status` INTO varUserID, varStatus FROM `ssaccountsdb`.`AccountsInfo` WHERE `PlatformID`=inPlatformID;
	IF ISNULL(varUserID) THEN
		SET retCode := 1;
		SET retMsg := "account not exist";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	CALL `ssaccountsdb`.`sp_inner_is_nullity`(varStatus, retCode);
	IF retCode=1 THEN
		SET retCode := 2;
		SET retMsg := "account nullity";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	CALL `ssaccountsdb`.`sp_inner_is_stundown`(varStatus, retCode);
	IF retCode=1 THEN
		SET retCode := 3;
		SET retMsg := "account stundown";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	IF EXISTS(SELECT `OrderID` FROM `PayOrderConfirm` where `OrderID`=inOrderID) THEN
		SET retCode := 4;
		SET retMsg := "order already exists";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	SELECT `Score`, `InsureScore` INTO varScoreBefore, varInsureBefore FROM `GameScoreInfo` WHERE `UserID`=varUserID;
	IF ISNULL(varScoreBefore) THEN
		SET retCode := 5;
		SET retMsg := "score info not found";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	SELECT `Gold`, `GoldExtra`, `LimitTimes`, `LimitDays`, `IsRepeatable`, `MemberOrder`, `MemberOrderDays` INTO varGold, varExtraGold, varLimitTimes, varLimitDays, varIsRepeatable, varMemberOrder, varMemberOrderDays FROM `PayOrderItem` WHERE `ID`=inPayID;
	IF ISNULL(varGold) THEN
		SET retCode := 6;
		SET retMsg := "pay order item not found";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;


	SET varAvailableTimes := -1; 
	CALL sp_inner_pay_order_item_available_time(varUserID, inPayID, varLimitTimes, varLimitDays, varIsRepeatable, varAvailableTimes);
	IF varAvailableTimes = 0 THEN
		SET varTotalGold := varGold;
	ELSE
		SET varTotalGold := varGold + varExtraGold;
	END IF;

	IF varMemberOrder>0 AND varMemberOrderDays>0 THEN
		SET varMemberUserRight := 512;
	ELSE
		SET varMemberUserRight := 0; 
		SET varMemberOrder := 0;
		SET varMemberOrderDays := 0;
	END IF;

	SET varContribution := CONVERT(inCurrencyAmount, SIGNED);

	SELECT `ItemCount` INTO varPayBeforeScore FROM `ssfishdb`.`t_bag` WHERE `UserID`=varUserID and `ItemId`=1001;

	START TRANSACTION;
		INSERT INTO `PayOrderConfirm` (`OrderID`, `PayChannel`, `UserID`, `PlatformID`, `CurrencyType`, `CurrencyAmount`, `Score`, `MemberOrder`, `MemberOrderDays`, `MemberUserRight`, `SubmitTime`, `FinishTime`, `ScoreBefore`, `InsureBefore`, `PayOrderItemID`,`SandBox`,`PayBeforeScore`) VALUES (inOrderID, inPayChannel, varUserID, inPlatformID, inCurrencyType, inCurrencyAmount, varTotalGold, varMemberOrder, varMemberOrderDays, varMemberUserRight, inSubmitTime, NOW(), varScoreBefore, varInsureBefore, inPayID,inSandBox,varPayBeforeScore);

		IF varMemberOrder>0 THEN
			DELETE FROM `ssaccountsdb`.`AccountsMember` WHERE `UserID`=varUserID  AND `MemberOverDate`<=NOW();
			SELECT `MemberOverDate` INTO varMemberOverDate FROM `ssaccountsdb`.`AccountsMember` WHERE `UserID`=varUserID AND `MemberOrder`=varMemberOrder AND `MemberOverDate`>NOW();
			IF ISNULL(varMemberOverDate) THEN
				SET varMemberOverDate := CONVERT(DATE_ADD(CURDATE(), INTERVAL varMemberOrderDays DAY), DATETIME);
				INSERT INTO `ssaccountsdb`.`AccountsMember` (`UserID`, `MemberOrder`, `UserRight`, `MemberOverDate`) VALUES (varUserID, varMemberOrder, varMemberUserRight, varMemberOverDate);
			ELSE
				SET varMemberOverDate := CONVERT(DATE_ADD(CONVERT(varMemberOverDate, DATE), INTERVAL varMemberOrderDays DAY), DATETIME);
				UPDATE `ssaccountsdb`.`AccountsMember` SET `MemberOverDate`=varMemberOverDate WHERE `UserID`=varUserID AND `MemberOrder`=varMemberOrder;
			END IF;

			CALL `ssaccountsdb`.`sp_inner_member_update`(varUserID, varCurrentMemberOrder, varMemberOverDate, varMemberSwitchDate);
		END IF;

		UPDATE `ssaccountsdb`.`AccountsInfo` SET `Contribution`=`Contribution`+varContribution WHERE `UserID`=varUserID;

		UPDATE `GameScoreInfo` SET `Score`=`Score`+varTotalGold WHERE `UserID`=varUserID;

		SELECT `Score`, `InsureScore` INTO varCurrentScore, varCurrentInsure FROM `sstreasuredb`.`GameScoreInfo` WHERE `UserID`=varUserID;
		SELECT `MemberOrder`, `UserRight`, `Contribution` INTO varCurrentMemberOrder, varCurrentUserRight, varCurrentContribution FROM `ssaccountsdb`.`AccountsInfo` WHERE `UserID`=varUserID;
	COMMIT;

	SET retCode := 0;
	SET retMsg := "success";

	SELECT retCode, retMsg, varAvailableTimes, varUserID AS "UserID", varCurrentMemberOrder AS "MemberOrder", varCurrentUserRight AS "UserRight", varTotalGold AS "Score", varCurrentScore AS "currentScore", varCurrentInsure AS "currentInsure", varContribution AS "Contribution", varCurrentContribution AS "CurrentContribution";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_player_buy_property
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_player_buy_property`;
DELIMITER ;;
CREATE  PROCEDURE `sp_player_buy_property`(
IN inServerID int(11),IN inUserID int(11),IN inPropertyID int(11),IN inPropertyCount int(11),IN inConsumeScore int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode = -1;
		SET retMsg = "数据库内部错误";
		SELECT retCode, retMsg;
	END;

	START TRANSACTION;
		INSERT INTO `UserPropertyVendor` (`UserID`, `PropertyID`, `PropertyCount`) VALUES (inUserID, inPropertyID, inPropertyCount) ON DUPLICATE KEY UPDATE `PropertyCount`=`PropertyCount`+VALUES(`PropertyCount`);


		INSERT INTO `ssrecorddb`.`BuyProperty` (`ServerID`, `UserID`, `PropertyID`, `PropertyCount`, `ConsumeScore`, `Ctime`) VALUES (inServerID, inUserID, inPropertyID, inPropertyCount, inConsumeScore, NOW());
	COMMIT;


	SET retCode := 0;
	SET retMsg = "success";

	SELECT retCode, retMsg;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_player_trumpet_score
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_player_trumpet_score`;
DELIMITER ;;
CREATE  PROCEDURE `sp_player_trumpet_score`(
IN inUserID int(11),IN inMemberOrder int(11),IN inTrumpetID int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	DECLARE varGold BIGINT;
	DECLARE varDiscount SMALLINT;

	DECLARE varConsumeGold BIGINT;

	DECLARE varTodayCnt INT;

	-- 道具判断
	SELECT `Gold`, `Discount` INTO varGold, varDiscount FROM `GameProperty` WHERE `Nullity`=0 AND `ID`=inTrumpetID;
	IF ISNULL(varGold) THEN
		SET retCode := 1;
		SET retMsg = CONCAT("找不到道具 propertyID=", inTrumpetID);
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	-- 如果是大小喇叭，根据当天发送的次数，判断当前的需要的筹码（单个筹码*发送当前次数），15次以后价格封顶，不再上涨
	SELECT COUNT(`UserID`) INTO varTodayCnt FROM `ssrecorddb`.`BuyProperty` WHERE  `UserID`=inUserID AND `PropertyID`=inTrumpetID AND DATEDIFF(`Ctime`, CURRENT_DATE())=0;
	SET varTodayCnt := varTodayCnt + 1;
	IF varTodayCnt > 15 THEN
		SET varTodayCnt := 15;
	END IF;

	IF inMemberOrder=0 THEN
		SET varConsumeGold := varGold * varTodayCnt;
	ELSE
		SET varConsumeGold := varGold * varTodayCnt * varDiscount / 100;
	END IF;

	SET retCode := 0;
	SET retMsg = "success";

	SELECT retCode, retMsg, varConsumeGold AS "ConsumeGold";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_player_use_property
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_player_use_property`;
DELIMITER ;;
CREATE  PROCEDURE `sp_player_use_property`(
IN inServerID int(11),IN inUserID int(11),IN inTargetUserID int(11),IN inPropertyID int(11),IN inPropertyCount int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	DECLARE varPropertyCount INT;
	DECLARE varPropertyCountNew INT;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode = -1;
		SET retMsg = "数据库内部错误";
		SELECT retCode, retMsg;
	END;

	SELECT `PropertyCount` INTO varPropertyCount FROM `UserPropertyVendor` WHERE `UserID`=inUserID AND `PropertyID`=inPropertyID;
	IF ISNULL(varPropertyCount) THEN
		SET retCode := 1;
		SET retMsg = CONCAT("找不到道具 propertyID=", inPropertyID);
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	IF varPropertyCount < inPropertyCount THEN
		SET retCode := 2;
		SET retMsg = CONCAT("道具不够 current=", varPropertyCount, " required=", inPropertyCount);
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	START TRANSACTION;
		UPDATE `UserPropertyVendor` SET `PropertyCount`=`PropertyCount`-inPropertyCount WHERE `UserID`=inUserID AND `PropertyID`=inPropertyID;

		IF ROW_COUNT()<>1 THEN
			ROLLBACK;
			
			SET retCode = 3;
			SET retMsg = "数据冲突";
			SELECT retCode, retMsg;
			LEAVE THIS_PROCEDURE;
		END IF;

		SELECT `PropertyCount` INTO varPropertyCountNew FROM `UserPropertyVendor` WHERE `UserID`=inUserID AND `PropertyID`=inPropertyID;
		IF ISNULL(varPropertyCountNew) THEN
			ROLLBACK;
			
			SET retCode = 4;
			SET retMsg = "数据冲突";
			SELECT retCode, retMsg;
			LEAVE THIS_PROCEDURE;
		END IF;

		IF varPropertyCountNew < 0 THEN
			ROLLBACK;
			
			SET retCode = 5;
			SET retMsg = "数据冲突";
			SELECT retCode, retMsg;
			LEAVE THIS_PROCEDURE;
		END IF;


		IF varPropertyCountNew = 0 THEN
			DELETE FROM `UserPropertyVendor` WHERE `UserID`=inUserID AND `PropertyID`=inPropertyID;
		END IF;

		INSERT INTO `ssrecorddb`.`UseProperty` (`ServerID`, `UserID`, `TargetUserID`, `PropertyID`, `PropertyCount`, `Ctime`) VALUES (inServerID, inUserID, inTargetUserID, inPropertyID, inPropertyCount, NOW());

	COMMIT;

	SET retCode := 0;
	SET retMsg := "SUCCESS";
	SELECT retCode, retMsg;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_query_pay_order_item_info
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_query_pay_order_item_info`;
DELIMITER ;;
CREATE  PROCEDURE `sp_query_pay_order_item_info`(
IN inUserID int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE varUserRight INT UNSIGNED;
	DECLARE varIsRelevant TINYINT UNSIGNED;
	DECLARE varAvailableTimes SMALLINT;

	DECLARE varItemID INT;
	DECLARE varLimitTimes SMALLINT;
	DECLARE varLimitDays SMALLINT;
	DECLARE varIsRepeatable TINYINT UNSIGNED;
	DECLARE varIsAllowRelevantBuy TINYINT UNSIGNED;

	DECLARE varExitLoop TINYINT;
	DECLARE varCursor1 CURSOR FOR SELECT `ID`, `LimitTimes`, `LimitDays`, `IsRepeatable`, `IsAllowRelevantBuy` FROM `PayOrderItem` WHERE `EndDate`>NOW();
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET varExitLoop := 1;

	SELECT `UserRight` INTO varUserRight FROM `ssaccountsdb`.`AccountsInfo` WHERE `UserID`=inUserID;
	IF NOT ISNULL(varUserRight) THEN
		IF (varUserRight & 0x40000000) =  0x40000000 THEN
			SET varIsRelevant := 1;
		ELSE
			SET varIsRelevant := 0;
		END IF;
	END IF;

	IF ISNULL(varIsRelevant) THEN
		SET varIsRelevant := 0;
	END IF;

	DROP TEMPORARY TABLE IF EXISTS `TEMP_PayOrderInfo`;
	CREATE TEMPORARY TABLE `TEMP_PayOrderInfo` (
		`ItemID` int(10) unsigned NOT NULL DEFAULT '0',
		`AvailableTimes` smallint(6) NOT NULL DEFAULT '0',
		PRIMARY KEY (`ItemID`)
	) DEFAULT CHARSET=utf8;

	OPEN varCursor1;
	itemLoop: LOOP
		FETCH varCursor1 INTO varItemID, varLimitTimes, varLimitDays, varIsRepeatable, varIsAllowRelevantBuy;
		IF varExitLoop=1 THEN
			LEAVE itemLoop;
		END IF;

		IF varIsRelevant = 1 THEN
			SET varAvailableTimes := 0;
		ELSE
			CALL sp_inner_pay_order_item_available_time(inUserID, varItemID, varLimitTimes, varLimitDays, varIsRepeatable, varAvailableTimes);
		END IF;

		INSERT INTO `TEMP_PayOrderInfo` (`ItemID`, `AvailableTimes`) VALUES (varItemID, varAvailableTimes);
	END LOOP;
	CLOSE varCursor1;

	SELECT * FROM `TEMP_PayOrderInfo`;

	DROP TEMPORARY TABLE IF EXISTS `TEMP_PayOrderInfo`;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_write_score
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_write_score`;
DELIMITER ;;
CREATE  PROCEDURE `sp_write_score`(
IN inUserID int(11),IN inVariationRevenue bigint(20),IN inVariationScore bigint(20),IN inVariationInsure bigint(20),IN inVariationGrade bigint(20),IN inVariationMedal bigint(20),IN inVariationGift bigint(20),IN inVariationPresent bigint(20),IN inVariationExperience bigint(20),IN inVariationLoveliness bigint(20),IN inVariationPlayTimeCount int(11),IN inVariationWinCount int(11),IN inVariationLostCount int(11),IN inVariationDrawCount int(11),IN inVariationFleeCount int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	DECLARE varScoreBefore BIGINT;
	DECLARE varInsureBefore BIGINT;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode = -1;
		SET retMsg = "数据库内部错误";
		SELECT retCode, retMsg;
	END;

/*--老的结构，因为金币和礼券走t_bag了，所以老的不适用
	IF inVariationScore < 0 OR inVariationInsure < 0 THEN
		SELECT `Score`, `InsureScore` INTO varScoreBefore, varInsureBefore FROM `sstreasuredb`.`GameScoreInfo` WHERE `UserID`=inUserID;
		IF varScoreBefore + inVariationScore < 0 THEN
			SET retCode := 1;
			SET retMsg = "score成负数了！";
			SELECT retCode, retMsg;
			LEAVE THIS_PROCEDURE;
		END IF;

		IF varInsureBefore + inVariationInsure < 0 THEN
			SET retCode := 2;
			SET retMsg = "insure成负数了！";
			SELECT retCode, retMsg;
			LEAVE THIS_PROCEDURE;
		END IF;
		
	END IF;

	START TRANSACTION;
		UPDATE `sstreasuredb`.`GameScoreInfo` SET `Revenue`=`Revenue`+inVariationRevenue, `Score`=`Score`+inVariationScore, `InsureScore`=`InsureScore`+inVariationInsure, `WinCount`=`WinCount`+inVariationWinCount, `LostCount`=`LostCount`+inVariationLostCount, `FleeCount`=`FleeCount`+inVariationFleeCount, `DrawCount`=`DrawCount`+inVariationDrawCount WHERE `UserID`=inUserID;

		UPDATE `ssaccountsdb`.`AccountsInfo` SET `Present`=`Present`+inVariationPresent, `UserMedal`=`UserMedal`+inVariationMedal, `Experience`=`Experience`+inVariationExperience, `LoveLiness`=`LoveLiness`+inVariationLoveliness, `Gift`=`Gift`+inVariationGift, `PlayTimeCount`=`PlayTimeCount`+inVariationPlayTimeCount WHERE `UserID`=inUserID;
	COMMIT;
*/

	IF inVariationScore < 0 OR inVariationInsure < 0 THEN
		SELECT `InsureScore` INTO varInsureBefore FROM `sstreasuredb`.`GameScoreInfo` WHERE `UserID`=inUserID;

		IF varInsureBefore + inVariationInsure < 0 THEN
			SET retCode := 2;
			SET retMsg = "insure成负数了！";
			SELECT retCode, retMsg;
			LEAVE THIS_PROCEDURE;
		END IF;
		
	END IF;

	START TRANSACTION;
		UPDATE `sstreasuredb`.`GameScoreInfo` SET `Revenue`=`Revenue`+inVariationRevenue, `InsureScore`=`InsureScore`+inVariationInsure, `WinCount`=`WinCount`+inVariationWinCount, `LostCount`=`LostCount`+inVariationLostCount, `FleeCount`=`FleeCount`+inVariationFleeCount, `DrawCount`=`DrawCount`+inVariationDrawCount WHERE `UserID`=inUserID;

		UPDATE `ssaccountsdb`.`AccountsInfo` SET `Present`=`Present`+inVariationPresent, `UserMedal`=`UserMedal`+inVariationMedal, `Experience`=`Experience`+inVariationExperience, `LoveLiness`=`LoveLiness`+inVariationLoveliness, `PlayTimeCount`=`PlayTimeCount`+inVariationPlayTimeCount WHERE `UserID`=inUserID;
	COMMIT;


	SET retCode := 0;
	SET retMsg := "success";
	SELECT retCode, retMsg;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for s_game_wintask_calc
-- ----------------------------
DROP PROCEDURE IF EXISTS `s_game_wintask_calc`;
DELIMITER ;;
CREATE  PROCEDURE `s_game_wintask_calc`(
IN inUserID int(11),IN inGameType int(11),IN inWealthType int(11),IN inKindID int(11),IN inIsWin int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);
	DECLARE nComboWinCount INT;
	DECLARE nWinCount INT;
	
	DECLARE nTypeComboWin INT;			-- 连胜类型
	DECLARE nTypeWin 	 INT;			-- 每胜10场类型

	DECLARE nAwardItemTypeComboWin INT;	-- 连胜的奖励类型 
	DECLARE	nAwardItemTypeWin INT;		-- 每胜10场的奖励类型 
	DECLARE nAwardItemCountComboWin INT;-- 连胜的奖励数量
	DECLARE	nAwardItemCountWin INT;		-- 每胜10场的奖励数量 
	DECLARE nWinCountPower INT;		-- 每胜多少场的定义
	DECLARE nWinAwardTypeStart INT;	-- 连胜类任务奖励类型起始值
	DECLARE nPerWinAwardType INT;	-- 每胜类任务奖励类型

	DECLARE nAwardItemType INT;		-- 奖励物品类型 1: 金币 2:礼券
	DECLARE nAwardItemCount INT;	-- 奖励物品数量   奖励物品计算类型 1: 值时(数量) 2: 百分比时(百分比*10000)
	DECLARE	nAwardType INT;			-- 奖励类型 1.连胜为 10 + 连胜次数  2.每胜10局 30

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode := -1;
		SET retMsg := "数据库内部错误";
		SELECT retCode, retMsg;
	END;

	IF inGameType <> 1 OR (inWealthType <> 8 AND inWealthType <> 72) OR (inKindID <> 200 AND inKindID <> 201) THEN
		SET retCode := 1;
		SET retMsg = "目前只支持斗地主免费场和二人斗地主免费场!";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	-- 记录玩家胜场数据
	SELECT  `ComboWinCount`, `WinCount` INTO nComboWinCount, nWinCount FROM `sstreasuredb`.`UserWinCounts` WHERE `UserID` = inUserID AND `KindId` = inKindID;
	IF ISNULL(nComboWinCount) THEN 	-- 没有数据
		IF inIsWin = 0 THEN 	-- 负
			INSERT INTO `sstreasuredb`.`UserWinCounts` (`UserID`,`KindId`) VALUES(inUserID, inKindID);
		ELSE 					-- 胜
			INSERT INTO `sstreasuredb`.`UserWinCounts` (`UserID`,`KindId`,`WinCount`,`ComboWinCount`) VALUES(inUserID, inKindID,1,1);
		END IF;
	ELSE 							-- 已有数据
		IF inIsWin = 0 THEN 	-- 负
			UPDATE `sstreasuredb`.`UserWinCounts` SET `ComboWinCount` = 0  WHERE `UserID` = inUserID AND `KindId` = inKindID;
		ELSE 					-- 胜
			-- 超过10连胜清0
			IF nComboWinCount >= 10 THEN SET nComboWinCount := 0; END IF;
			SET nComboWinCount := nComboWinCount + 1;
			SET nWinCount := nWinCount + 1;
			UPDATE `sstreasuredb`.`UserWinCounts` SET `ComboWinCount` = nComboWinCount, `WinCount` = nWinCount WHERE `UserID` = inUserID AND `KindId` = inKindID;
		END IF;
	END IF;

	-- 计算胜场任务奖励
	SET nAwardItemTypeComboWin := 0;
	SET nAwardItemTypeWin := 0;
	SET nAwardItemCountComboWin := 0;
	SET nAwardItemCountWin := 0;
	SET nWinCountPower := 10;		-- 每胜10场
	SET nWinAwardTypeStart := 10;	-- 胜利类任务奖励类型起始值
	SET nPerWinAwardType := 30;	-- 奖励类型 每胜10局 固定为 30

	-- 结算玩家胜场数据
	IF inIsWin = 1 THEN 	-- 只有赢的情况 才可能完成任务

		
		-- 计算连胜奖励类型
		IF nComboWinCount > 0 THEN 
			SET nAwardType := nComboWinCount + nWinAwardTypeStart; -- 奖励类型 1.连胜为 nWinAwardTypeStart + 连胜次数
			-- 取得奖励配置
			SELECT  `AwardItemType`, `AwardItemCount` INTO nAwardItemType, nAwardItemCount
			FROM `sstreasuredb`.`VoucherAwardConf` 
			WHERE `GameType` = inGameType AND `AwardType` = nAwardType AND `WealthType` & inWealthType <> 0;
			IF ISNULL(nAwardItemType) OR ISNULL(nAwardItemCount) THEN 	-- 只有赢的情况 才可能完成任务
				SET retCode := 2;
				SET retMsg = "对应的奖励不存在!";
				SELECT retCode, retMsg;
				LEAVE THIS_PROCEDURE;
			END IF;
			
			SET nTypeComboWin := nAwardType;
			SET nAwardItemTypeComboWin := nAwardItemType;
			SET nAwardItemCountComboWin := nAwardItemCount;

			-- 插入日志
			INSERT INTO `ssrecorddb`.`RecordGameWinTask` (`UserID`,`GameType`,`AwardType`,`WealthType`,`AwardItemType`,`AwardItemCount`,`RecordTime`)
			VALUES(inUserID, inGameType, nAwardType, inWealthType, nAwardItemType, nAwardItemCount, NOW());
		END IF;
		-- 计算每胜10场的奖励类型
		IF nWinCount % nWinCountPower = 0 THEN 		-- 每胜10场就给奖励
			SET nAwardType := nPerWinAwardType; 	-- 奖励类型 每胜10局 固定为 30
			SELECT  `AwardItemType`, `AwardItemCount` INTO nAwardItemType, nAwardItemCount 
			FROM `sstreasuredb`.`VoucherAwardConf` 
			WHERE `GameType` = inGameType AND `AwardType` = nAwardType AND `WealthType` & inWealthType <> 0;
			IF ISNULL(nAwardItemType) OR ISNULL(nAwardItemCount) THEN 	-- 只有赢的情况 才可能完成任务
				SET retCode := 3;
				SET retMsg = "对应的奖励不存在!";
				SELECT retCode, retMsg;
				LEAVE THIS_PROCEDURE;
			END IF;

			SET nTypeWin := nAwardType;
			SET nAwardItemTypeWin := nAwardItemType;
			SET nAwardItemCountWin := nAwardItemCount;
			-- 插入日志
			INSERT INTO `ssrecorddb`.`RecordGameWinTask` (`UserID`,`GameType`,`AwardType`,`WealthType`,`AwardItemType`,`AwardItemCount`,`RecordTime`)
			VALUES(inUserID, inGameType, nAwardType, inWealthType, nAwardItemType, nAwardItemCount, NOW());
		
		END IF;

	END IF;

	-- 输出结果
	SET retCode := 0;
	SET retMsg := "success";
	SELECT retCode, retMsg, 
		inUserID AS UserID,
		nAwardItemTypeComboWin 		AS AwardItemTypeComboWin,
		nAwardItemCountComboWin 	AS AwardItemCountComboWin,
		nAwardItemTypeWin 			AS AwardItemTypeWin,
		nAwardItemCountWin 			AS AwardItemCountWin,
		nTypeComboWin 				AS TypeComboWin,
		nTypeWin 					AS TypeWin,
		nComboWinCount 				AS ComboWinCount,
		nWinCount % nWinCountPower 	AS WinCount;

END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for s_query_last_drawed_user
-- ----------------------------
DROP PROCEDURE IF EXISTS `s_query_last_drawed_user`;
DELIMITER ;;
CREATE  PROCEDURE `s_query_last_drawed_user`(
IN inVoucherPoolType int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	-- DECLARE retCode INT;
	-- DECLARE retMsg VARCHAR(255);

	-- DECLARE EXIT HANDLER FOR SQLEXCEPTION
	-- BEGIN
	-- 	ROLLBACK;
		
	-- 	SET retCode := -1;
	-- 	SET retMsg := "数据库内部错误";
	-- 	SELECT retCode, retMsg;
	-- END;

	SELECT RVD.`UserID` AS UserID, RVD.`GameType` AS GameType, RVD.`AwardItemCount` AS AwardItemCount,
	     ACC.`NickName` AS NickName, ACC.`MemberOrder` AS MemberOrder, ACC.`FaceID` AS FaceID, ACF.`PlatformFace` AS PlatformFace,
	     ACC.`PlatformID` AS PlatformID
	FROM `ssrecorddb`.`RecordVoucherDrawing`  AS RVD
	LEFT OUTER JOIN `ssaccountsdb`.`AccountsInfo` AS ACC ON ACC.`UserID` = RVD.`UserID`
	LEFT OUTER JOIN `ssaccountsdb`.`AccountsFace` AS ACF ON ACF.`UserID` = RVD.`UserID`
	WHERE `GameType` = inVoucherPoolType AND  `WealthType` = 1  AND `AwardItemType` = 2 -- 只查询金币场和类型为礼券
	ORDER BY `RecordTime` DESC
	LIMIT 3;

END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for s_query_poolvoucher_count
-- ----------------------------
DROP PROCEDURE IF EXISTS `s_query_poolvoucher_count`;
DELIMITER ;;
CREATE  PROCEDURE `s_query_poolvoucher_count`(
IN inVoucherPoolType int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);
	DECLARE	lTotalVoucherCount BIGINT;	-- 礼券池中礼券总量

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode := -1;
		SET retMsg := "数据库内部错误";
		SELECT retCode, retMsg;
	END;

	SELECT `VoucherCount` INTO lTotalVoucherCount FROM `sstreasuredb`.`VoucherPoolInfo` WHERE `VoucherPoolType` = inVoucherPoolType;
	IF ISNULL(lTotalVoucherCount) THEN
		SET lTotalVoucherCount := 0;
	END IF;

	SET retCode := 0;
	SET retMsg := "success";
	SELECT retCode, retMsg, lTotalVoucherCount;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for s_query_user_drawed_count
-- ----------------------------
DROP PROCEDURE IF EXISTS `s_query_user_drawed_count`;
DELIMITER ;;
CREATE  PROCEDURE `s_query_user_drawed_count`(
IN inUserID int(11),IN inGameType int(11),IN inWealthType int(11),IN inKindID int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	-- DECLARE retCode INT;
	-- DECLARE retMsg VARCHAR(255);

	-- DECLARE EXIT HANDLER FOR SQLEXCEPTION
	-- BEGIN
	-- 	ROLLBACK;
		
	-- 	SET retCode := -1;
	-- 	SET retMsg := "数据库内部错误";
	-- 	SELECT retCode, retMsg;
	-- END;

	DECLARE nBigCard1Type INT;
	DECLARE nBigCard2Type INT;
	DECLARE nComboWinType INT;
	DECLARE nWinType 	  INT;
	DECLARE nBigCard1Count INT;
	DECLARE nBigCard2Count INT;
	DECLARE nComboWinCount INT;
	DECLARE nWinCount 	   INT;

	SET nBigCard1Type := 3;
	SET nBigCard2Type := 4;
	SET nComboWinType := 10;
	SET nWinType 	  := 30; 


	SELECT  `ComboWinCount`, `WinCount` INTO nComboWinCount, nWinCount FROM `sstreasuredb`.`UserWinCounts` 
	WHERE `UserID` = inUserID AND `KindId` = inKindID;
	SELECT count(*) INTO nBigCard1Count FROM `ssrecorddb`.`RecordVoucherDrawing` 
	WHERE GameType = inGameType AND WealthType = inWealthType AND UserID = inUserID AND AwardType = nBigCard1Type;
	SELECT count(*) INTO nBigCard2Count FROM `ssrecorddb`.`RecordVoucherDrawing` 
	WHERE GameType = inGameType AND WealthType = inWealthType AND UserID = inUserID AND AwardType = nBigCard2Type;

	IF ISNULL(nBigCard1Count) THEN	SET nBigCard1Count := 0;	END IF;
	IF ISNULL(nBigCard2Count) THEN	SET nBigCard2Count := 0;	END IF;
	IF ISNULL(nComboWinCount) THEN	SET nComboWinCount := 0;	END IF;
	IF ISNULL(nWinCount 	) THEN	SET nWinCount 	   := 0;	END IF;

	SELECT	nBigCard1Type 					AS Type1,	nBigCard1Count	AS Count1,
			nBigCard2Type 					AS Type2,	nBigCard2Count	AS Count2,
			nComboWinType + nComboWinCount 	AS Type3,	nComboWinCount	AS Count3,
			nWinType 						AS Type4,	nWinCount % 10 	AS Count4;

END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for s_voucherpool_drawing
-- ----------------------------
DROP PROCEDURE IF EXISTS `s_voucherpool_drawing`;
DELIMITER ;;
CREATE  PROCEDURE `s_voucherpool_drawing`(
IN inUserID int(11),IN inGameType int(11),IN inAwardType int(11),IN inWealthType int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);
	DECLARE nSystemSubsidy INT;				-- 系统补助量
	DECLARE nIsSystemSubsidyUsing INT;		-- 是否开启系统补助 0 :否 1:是
	DECLARE nMemberOrder INT;				-- 玩家会员
	DECLARE szNickName VARCHAR(32); 		-- 玩家昵称
	
	DECLARE nAwardItemType INT;				-- 奖励物品类型 1: 金币 2:礼券
	DECLARE nAwardItemCalcType INT;			-- 奖励物品计算类型 1: 值 2: 百分比
	DECLARE nAwardItemCount INT;			-- 奖励物品数量   奖励物品计算类型 1: 值时(数量) 2: 百分比时(百分比*10000)
	DECLARE nTotalVoucherCount INT;			-- 礼券池中礼券总量
	DECLARE nTotalVoucherCountBefore INT;	-- 礼券池中礼券总量(领取前)
	DECLARE nAwardItemRealCount INT;		-- 奖励物品真实数量
	DECLARE nPercentagePower INT;			-- 百分比权值

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode := -1;
		SET retMsg := "数据库内部错误";
		SELECT retCode, retMsg;
	END;

	SET nIsSystemSubsidyUsing := 0;
	SET nMemberOrder := 0;
	SET szNickName := N'';
	SET nPercentagePower := 10000;

	SELECT  `AwardItemType`, `AwardItemCalcType`, `AwardItemCount` INTO nAwardItemType, nAwardItemCalcType, nAwardItemCount
	FROM `sstreasuredb`.`VoucherAwardConf`
	WHERE `GameType` = inGameType AND `AwardType` = inAwardType AND `WealthType` & inWealthType <> 0;

	IF ISNULL(nAwardItemType) OR ISNULL(nAwardItemCalcType) OR ISNULL(nAwardItemCount) THEN
		SET retCode := 1;
		SET retMsg = "对应的奖励不存在!";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	START TRANSACTION;
		IF nAwardItemType = 1 THEN 			-- 奖励物品类型 1: 金币
			IF nAwardItemCalcType = 1 THEN 	-- 奖励物品计算类型 1: 值
				SET nAwardItemRealCount := nAwardItemCount;
				-- 此处返回给服务端修改金币
				-- UPDATE `sstreasuredb`.`GameScoreInfo` SET `Score` = `Score` + nAwardItemCount WHERE UserID = inUserID 
			END IF;	
		ELSEIF nAwardItemType = 2 THEN		-- 奖励物品类型 2: 礼券
			-- 查询礼券池数量
			SELECT  IFNULL(`VoucherCount`, 0) INTO nTotalVoucherCount FROM `sstreasuredb`.`VoucherPoolInfo` WHERE `VoucherPoolType` = inGameType;
			IF ISNULL(nTotalVoucherCount) THEN
				SET nTotalVoucherCount := 0;
			END IF;
			SET nTotalVoucherCountBefore := nTotalVoucherCount;
			IF nAwardItemCalcType = 1 		THEN -- 奖励物品计算类型 1: 值
				SET nAwardItemRealCount := nAwardItemCount;
				IF nTotalVoucherCount < nAwardItemRealCount THEN
					SET nAwardItemRealCount := nTotalVoucherCount;
				END IF;
			ELSEIF nAwardItemCalcType = 2  	THEN -- 奖励物品计算类型 2: 百分比
				SET nPercentagePower := 10000;
				IF nAwardItemCount > nPercentagePower THEN
					SET nAwardItemCount := nPercentagePower;
				END IF;

				IF nTotalVoucherCount > 0 THEN
					SET nAwardItemRealCount := CEILING(nAwardItemCount / nPercentagePower * nTotalVoucherCount);
				ELSE
					SET nAwardItemRealCount := 0;
				END IF;
			END IF;
			-- 更新礼券池的礼券
			IF inWealthType & 1 <> 0 THEN	-- 金币场才修改礼券池
				SET nTotalVoucherCount := nTotalVoucherCount - nAwardItemRealCount;
				IF nTotalVoucherCount < 100 THEN	-- 礼券池中礼券过少了 启用系统补助
					SET nIsSystemSubsidyUsing := 1;
					-- 系统补助量查询
					SELECT `StatusValue` INTO nSystemSubsidy FROM `ssaccountsdb`.`SystemStatusInfo` WHERE `StatusName` = N'VoucherSystemSubsidy';
					IF ISNULL(nSystemSubsidy) THEN
						SET nSystemSubsidy := 1000;
					END IF;
					UPDATE `sstreasuredb`.`VoucherPoolInfo`  SET `VoucherCount` = nSystemSubsidy  WHERE `VoucherPoolType` = inGameType;
				ELSE 								-- 礼券池中礼券足够
					UPDATE `sstreasuredb`.`VoucherPoolInfo`  SET `VoucherCount` = `VoucherCount` - nAwardItemRealCount  WHERE `VoucherPoolType` = inGameType;
				END IF;
				-- 全服公告需要会员和昵称
				SELECT `MemberOrder`, `NickName` INTO nMemberOrder, szNickName FROM `ssaccountsdb`.`AccountsInfo` WHERE `UserID` = inUserID;
			END IF;
			-- 更新用户的礼券
			-- 此处返回给服务端修改礼券
			-- UPDATE `ssaccountsdb`.`AccountsInfo` SET `Present` = `Present` + nAwardItemRealCount WHERE `UserID` = inUserID;
		END IF;

		IF ISNULL(nTotalVoucherCount)        THEN	SET nTotalVoucherCount 			:= 0; 	END IF;
		IF ISNULL(nTotalVoucherCountBefore)  THEN	SET nTotalVoucherCountBefore 	:= 0; 	END IF;
		IF nTotalVoucherCount < 0   		 THEN	SET nTotalVoucherCount 			:= 0; 	END IF;
		-- 插入日志(系统补助前)
		INSERT INTO `ssrecorddb`.`RecordVoucherDrawing` (`UserID`,`GameType`,`AwardType`,`WealthType`,`AwardItemType`,`AwardItemCount`,`VoucherCountInPoolBefore`,`VoucherCountInPoolAfter`,`RecordTime`)
		VALUES(inUserID, inGameType, inAwardType, inWealthType, nAwardItemType, nAwardItemRealCount, nTotalVoucherCountBefore, nTotalVoucherCount, NOW());
		-- 插入日志(系统补助后)
		IF nIsSystemSubsidyUsing = 1 THEN -- 系统补助日志
			SET nTotalVoucherCount := nTotalVoucherCount + nSystemSubsidy;
			INSERT INTO `ssrecorddb`.`RecordVoucherDrawing` (`UserID`,`GameType`,`AwardType`,`WealthType`,`AwardItemType`,`AwardItemCount`,`VoucherCountInPoolBefore`,`VoucherCountInPoolAfter`,`RecordTime`)
			VALUES(0, inGameType, 0, inWealthType, 0, nTotalVoucherCount, 0, nTotalVoucherCount, NOW());
		END IF;

	COMMIT;

	IF ISNULL(nTotalVoucherCount) THEN
		SELECT IFNULL(VoucherCount, 0) INTO nTotalVoucherCount  FROM `sstreasuredb`.`VoucherPoolInfo` WHERE `VoucherPoolType` = inGameType;
	END IF;
	IF ISNULL(nTotalVoucherCount) THEN
		SET nTotalVoucherCount := 0;
	END IF;

	SET retCode := 0;
	SET retMsg := "success";
	SELECT retCode, retMsg, 
		inUserID AS UserID,
		nTotalVoucherCount AS TotalVoucherCount,
		nAwardItemType AS AwardItemType,
		nAwardItemRealCount AS AwardItemRealCount,
		nIsSystemSubsidyUsing AS IsSystemSubsidyUsing,
		IFNULL(nSystemSubsidy, 0) AS SystemSubsidy,
		nMemberOrder AS MemberOrder,
		szNickName AS NickName;

END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for s_voucher_betting
-- ----------------------------
DROP PROCEDURE IF EXISTS `s_voucher_betting`;
DELIMITER ;;
CREATE  PROCEDURE `s_voucher_betting`(
IN inUserID int(11),IN inVoucherPoolType int(11),IN inBettingScore int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);
	DECLARE	lTotalVoucherCount BIGINT;	-- 礼券池中礼券总量
	DECLARE	iVoucherBettingOutput INT;	-- 每次投注产出礼券

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode := -1;
		SET retMsg := "数据库内部错误";
		SELECT retCode, retMsg;
	END;

	SET iVoucherBettingOutput := inBettingScore * 1;
	SELECT `VoucherCount` INTO lTotalVoucherCount FROM `sstreasuredb`.`VoucherPoolInfo` WHERE `VoucherPoolType` = inVoucherPoolType;

	START TRANSACTION;
		IF ISNULL(lTotalVoucherCount) THEN
			SET lTotalVoucherCount := iVoucherBettingOutput;
			INSERT INTO `sstreasuredb`.`VoucherPoolInfo` (VoucherPoolType, VoucherCount) VALUES (inVoucherPoolType, lTotalVoucherCount);
		ELSE
			SET lTotalVoucherCount := lTotalVoucherCount + iVoucherBettingOutput;
			UPDATE `sstreasuredb`.`VoucherPoolInfo` SET `VoucherCount` = `VoucherCount` + iVoucherBettingOutput WHERE `VoucherPoolType` = inVoucherPoolType;
		END IF;

		-- 记录投注次数
		INSERT INTO `ssrecorddb`.`RecordVoucherBetCount` (GameType,BetCount,BetDate,BetUserId) VALUES(inVoucherPoolType, 1, NOW(), inUserID);
	COMMIT;


	SET retCode := 0;
	SET retMsg := "success";
	SELECT retCode, retMsg, lTotalVoucherCount;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for s_write_loveliness_score
-- ----------------------------
DROP PROCEDURE IF EXISTS `s_write_loveliness_score`;
DELIMITER ;;
CREATE  PROCEDURE `s_write_loveliness_score`(
IN inUserID int(11),IN inLoveLiness int(11),IN inVariationScore bigint(20))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode = -1;
		SET retMsg = "数据库内部错误";
		SELECT retCode, retMsg;
	END;

	START TRANSACTION;
		UPDATE `sstreasuredb`.`GameScoreInfo` SET `Score`=`Score`+inVariationScore WHERE `UserID`=inUserID;

		UPDATE `ssaccountsdb`.`AccountsInfo` SET `LoveLiness`=`LoveLiness`+inLoveLiness WHERE `UserID`=inUserID;
	COMMIT;

	SET retCode := 0;
	SET retMsg := "success";
	SELECT retCode, retMsg;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for s_write_present_score
-- ----------------------------
DROP PROCEDURE IF EXISTS `s_write_present_score`;
DELIMITER ;;
CREATE  PROCEDURE `s_write_present_score`(
IN inUserID int(11),IN inVariationPresent int(11),IN inVariationScore bigint(20))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode = -1;
		SET retMsg = "数据库内部错误";
		SELECT retCode, retMsg;
	END;

	START TRANSACTION;
		#UPDATE `sstreasuredb`.`GameScoreInfo` SET `Score`=`Score`+inVariationScore WHERE `UserID`=inUserID;

		#UPDATE `ssaccountsdb`.`AccountsInfo` SET `Gift`=`Gift`+inVariationPresent WHERE `UserID`=inUserID;
		INSERT INTO `ssrecorddb`.`PresentChange` SET `UserID`=inUserID, tp=1, `presentUsed`=(-inVariationPresent), `scoreAdd`=inVariationScore, `Datetime`=now();
	COMMIT;
	COMMIT;

	SET retCode := 0;
	SET retMsg := "success";
	SELECT retCode, retMsg;
END
;;
DELIMITER ;
