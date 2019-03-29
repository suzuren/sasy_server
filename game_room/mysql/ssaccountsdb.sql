/*
Navicat MySQL Data Transfer

Source Server Version : 50621
Source Database       : ssaccountsdb

Target Server Type    : MYSQL
Target Server Version : 50621
File Encoding         : 65001

*/

USE `ssaccountsdb`;

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for accountbinding
-- ----------------------------
DROP TABLE IF EXISTS `accountbinding`;
CREATE TABLE `accountbinding` (
  `UserID` int(10) NOT NULL,
  `PlatformID` int(10) DEFAULT NULL,
  `GameStatus` int(10) DEFAULT NULL,
  `BindingDate` datetime DEFAULT NULL,
  PRIMARY KEY (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for accountsface
-- ----------------------------
DROP TABLE IF EXISTS `accountsface`;
CREATE TABLE `accountsface` (
  `UserID` int(10) unsigned NOT NULL,
  `PlatformFace` char(32) DEFAULT NULL,
  PRIMARY KEY (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for accountsinfo
-- ----------------------------
DROP TABLE IF EXISTS `accountsinfo`;
CREATE TABLE `accountsinfo` (
  `UserID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `GameID` int(10) unsigned NOT NULL DEFAULT '0',
  `PlatformID` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '统一平台ID',
  `NickName` char(32) DEFAULT NULL,
  `Gender` tinyint(4) NOT NULL DEFAULT '0' COMMENT '用户性别',
  `FaceID` smallint(3) NOT NULL DEFAULT '1' COMMENT '头像标识',
  `Present` int(11) NOT NULL DEFAULT '0' COMMENT '赠送礼物',
  `UserMedal` int(11) NOT NULL DEFAULT '0' COMMENT '用户奖牌',
  `Experience` int(11) NOT NULL DEFAULT '0' COMMENT '经验数值',
  `LoveLiness` int(11) NOT NULL DEFAULT '0' COMMENT '用户魅力',
  `Gift` int(11) NOT NULL DEFAULT '0' COMMENT '礼券',
  `Contribution` int(11) NOT NULL DEFAULT '0' COMMENT '贡献值',
  `UserRight` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '用户权限',
  `MasterRight` int(11) NOT NULL DEFAULT '0' COMMENT '管理权限',
  `ServiceRight` int(11) NOT NULL DEFAULT '0' COMMENT '服务权限',
  `MasterOrder` tinyint(4) NOT NULL DEFAULT '0' COMMENT '管理等级',
  `MemberOrder` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '会员等级',
  `MemberOverDate` datetime DEFAULT NULL COMMENT '过期日期',
  `MemberSwitchDate` datetime DEFAULT NULL COMMENT '切换时间',
  `Status` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '用户状态（0x01=Nullity，0x02=StunDown，0x04=IsAndroid，0x08=MoorMachine, 0x10=小号）',
  `NullityOverDate` datetime DEFAULT NULL COMMENT '禁止时间',
  `GameLogonTimes` int(11) NOT NULL DEFAULT '0' COMMENT '登录次数',
  `PlayTimeCount` int(11) NOT NULL DEFAULT '0' COMMENT '游戏时间',
  `OnLineTimeCount` int(11) NOT NULL DEFAULT '0' COMMENT '在线时间',
  `LastLogonIP` char(15) DEFAULT NULL COMMENT '登录地址',
  `LastLogonDate` datetime DEFAULT NULL COMMENT '登录时间',
  `LastLogonMachine` char(32) DEFAULT NULL COMMENT '登录机器',
  `RegisterIP` char(15) DEFAULT NULL COMMENT '注册地址',
  `RegisterDate` datetime DEFAULT NULL COMMENT '注册时间',
  `RegisterMachine` char(32) DEFAULT NULL COMMENT '注册机器',
  PRIMARY KEY (`UserID`),
  KEY `idx1` (`GameID`),
  KEY `idx2` (`NickName`),
  KEY `idx3` (`PlatformID`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for accountsmember
-- ----------------------------
DROP TABLE IF EXISTS `accountsmember`;
CREATE TABLE `accountsmember` (
  `UserID` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '用户标识',
  `MemberOrder` tinyint(4) NOT NULL DEFAULT '0' COMMENT '会员标识',
  `UserRight` int(11) NOT NULL DEFAULT '0' COMMENT '用户权限',
  `MemberOverDate` datetime NOT NULL COMMENT '会员期限',
  PRIMARY KEY (`UserID`,`MemberOrder`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for accountssignature
-- ----------------------------
DROP TABLE IF EXISTS `accountssignature`;
CREATE TABLE `accountssignature` (
  `UserID` int(10) unsigned NOT NULL,
  `Signature` varchar(255) NOT NULL DEFAULT '',
  `HideFlag` tinyint(4) DEFAULT '0' COMMENT '1屏蔽，0不屏蔽',
  PRIMARY KEY (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for androidconfig
-- ----------------------------
DROP TABLE IF EXISTS `androidconfig`;
CREATE TABLE `androidconfig` (
  `ServerID` int(10) unsigned NOT NULL COMMENT '服务器ID',
  `StartTime` int(10) unsigned NOT NULL COMMENT '开始小时',
  `EndTime` int(10) unsigned NOT NULL COMMENT '结束小时',
  `AndroidNum` int(10) unsigned NOT NULL COMMENT '机器人数目',
  `AllowAndroid` tinyint(3) unsigned NOT NULL COMMENT '是否有效',
  `MinPlayDraw` int(10) unsigned NOT NULL COMMENT '最小游戏局数',
  `MaxPlayDraw` int(10) unsigned NOT NULL COMMENT '最大游戏局数',
  `MinTakeScore` bigint(20) unsigned NOT NULL COMMENT '机器人最小携带金币',
  `MaxTakeScore` bigint(20) unsigned NOT NULL COMMENT '机器人最大携带金币',
  `MinReposeTime` int(10) unsigned NOT NULL COMMENT '最小服务时间',
  `MaxReposeTime` int(10) unsigned NOT NULL COMMENT '最大服务时间',
  PRIMARY KEY (`ServerID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for androidmanager
-- ----------------------------
DROP TABLE IF EXISTS `androidmanager`;
CREATE TABLE `androidmanager` (
  `UserID` int(10) unsigned NOT NULL COMMENT '用户标识',
  `ServerID` int(10) unsigned NOT NULL COMMENT '房间标识',
  `MinPlayDraw` int(10) unsigned NOT NULL COMMENT '最少局数',
  `MaxPlayDraw` int(10) unsigned NOT NULL COMMENT '最大局数',
  `MinTakeScore` bigint(20) unsigned NOT NULL COMMENT '最少分数',
  `MaxTakeScore` bigint(20) unsigned NOT NULL COMMENT '最高分数',
  `MinReposeTime` int(10) unsigned NOT NULL COMMENT '最少休息',
  `MaxReposeTime` int(10) unsigned NOT NULL COMMENT '最大休息',
  `ServiceTime` int(10) unsigned NOT NULL,
  `ServiceGender` int(10) unsigned NOT NULL COMMENT '服务类型',
  `CreateDate` datetime NOT NULL,
  `TableId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`UserID`),
  KEY `idx1` (`ServerID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for androidnickname
-- ----------------------------
DROP TABLE IF EXISTS `androidnickname`;
CREATE TABLE `androidnickname` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `NickName` char(32) NOT NULL DEFAULT '',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `idx1` (`NickName`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for confineaddress
-- ----------------------------
DROP TABLE IF EXISTS `confineaddress`;
CREATE TABLE `confineaddress` (
  `AddrString` char(15) NOT NULL COMMENT '地址字符',
  `EnjoinMask` bit(8) NOT NULL DEFAULT b'0' COMMENT '0x1=禁止登录，0x2=禁止注册',
  `EnjoinOverDate` datetime NOT NULL COMMENT '过期时间',
  `CollectDate` datetime NOT NULL COMMENT '收集日期',
  `CollectNote` varchar(255) NOT NULL COMMENT '输入备注',
  PRIMARY KEY (`AddrString`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for confinemachine
-- ----------------------------
DROP TABLE IF EXISTS `confinemachine`;
CREATE TABLE `confinemachine` (
  `MachineSerial` char(32) NOT NULL COMMENT '机器序列',
  `EnjoinMask` bit(8) NOT NULL DEFAULT b'0' COMMENT '0x1=禁止登录，0x2=禁止注册',
  `EnjoinOverDate` datetime NOT NULL COMMENT '过期时间',
  `CollectDate` datetime NOT NULL COMMENT '收集日期',
  `CollectNote` varchar(255) NOT NULL COMMENT '输入备注',
  PRIMARY KEY (`MachineSerial`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for gameidentifier
-- ----------------------------
DROP TABLE IF EXISTS `gameidentifier`;
CREATE TABLE `gameidentifier` (
  `UserID` int(10) unsigned NOT NULL,
  `GameID` int(10) unsigned NOT NULL,
  PRIMARY KEY (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for logonsystemmessage
-- ----------------------------
DROP TABLE IF EXISTS `logonsystemmessage`;
CREATE TABLE `logonsystemmessage` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '索引标识',
  `Type` tinyint(3) unsigned NOT NULL DEFAULT '0' COMMENT '消息类型，客户端用0x00=禁用 x01=Android, 0x02=IOS (0x03=Android | IOS)',
  `ServerRange` varchar(255) NOT NULL DEFAULT '0' COMMENT '房间范围(0:所有房间)',
  `MessageTitle` char(250) NOT NULL COMMENT '邮件标题',
  `MessageString` varchar(2048) NOT NULL DEFAULT '' COMMENT '消息内容',
  `StartTime` datetime NOT NULL COMMENT '开始时间',
  `EndTime` datetime NOT NULL COMMENT '结束时间',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for logonusersmessage
-- ----------------------------
DROP TABLE IF EXISTS `logonusersmessage`;
CREATE TABLE `logonusersmessage` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `UserID` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '用户ID',
  `MessageTitle` char(250) NOT NULL COMMENT '标题',
  `MessageString` varchar(2048) NOT NULL DEFAULT '' COMMENT '消息内容',
  `StartTime` datetime NOT NULL COMMENT '开始时间',
  `GoodsInfo` char(250) DEFAULT '' COMMENT 'itemId:itemCount|itemId:itemCount|',
  `FromId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`),
  KEY `idx1` (`UserID`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for regisertmachinecount
-- ----------------------------
DROP TABLE IF EXISTS `regisertmachinecount`;
CREATE TABLE `regisertmachinecount` (
  `RegisterMachine` char(32) NOT NULL COMMENT '注册机器',
  `Count` smallint(6) NOT NULL DEFAULT '0' COMMENT '次数',
  PRIMARY KEY (`RegisterMachine`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for systemstatusinfo
-- ----------------------------
DROP TABLE IF EXISTS `systemstatusinfo`;
CREATE TABLE `systemstatusinfo` (
  `StatusName` varchar(64) NOT NULL,
  `StatusValue` int(11) DEFAULT NULL,
  `StatusString` varchar(255) NOT NULL,
  `StatusTip` varchar(32) NOT NULL,
  `StatusDescription` varchar(255) NOT NULL,
  PRIMARY KEY (`StatusName`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for systemstreaminfo
-- ----------------------------
DROP TABLE IF EXISTS `systemstreaminfo`;
CREATE TABLE `systemstreaminfo` (
  `CollectDate` date NOT NULL,
  `GameLogonSuccess` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '登录成功',
  `GameRegisterSuccess` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '注册成功',
  PRIMARY KEY (`CollectDate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Procedure structure for sp_cerate_android_name
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_cerate_android_name`;
DELIMITER ;;
CREATE  PROCEDURE `sp_cerate_android_name`(
IN inCreateNum int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE varNickName CHAR(32);
	DECLARE varIsNickExist TINYINT;
	DECLARE varConflictNum TINYINT DEFAULT 0;
	DECLARE varGameID INT;
	DECLARE i INT DEFAULT 0;

	DECLARE fname CHAR(255);
  DECLARE name1 CHAR(255);
  DECLARE name2 CHAR(255);
	DECLARE name3 CHAR(255);
	
	SELECT MAX(`ID`) INTO varGameID FROM `AndroidNickName`;
	IF ISNULL(varGameID) THEN
		SET varGameID := 1;
	ELSE
		SET varGameID := varGameID + 1;
	END IF;
	
	nickNameLoop: LOOP
		SET fname = "游客";
		SET name1 := SUBSTRING('djalgjd13d1f3a1gedgghretr1g6f1g668y4r613131316h1r1h3131g6h4110hf64ry4r96463f1gf67494613164616979161997hf149497h1f97r44ht9rtyu19716494hrt97yu61hr9795r4',ROUND(1+150*RAND()),12); 
    #SET name2 := SUBSTRING('abcdefghijklmnopqrstuvwxyz',ROUND(1+26*RAND()),5); 
    #SET name3 := SUBSTRING('0123456789',ROUND(1+10*RAND()),5); 

		SET varNickName := CONCAT(fname,name1);
		
		IF i > inCreateNum THEN
			LEAVE nickNameLoop;
		END IF;

		IF varConflictNum>=10 THEN
			LEAVE nickNameLoop;
		END IF;


		SELECT COUNT(`NickName`) INTO varIsNickExist FROM `AndroidNickName` WHERE `NickName`=varNickName;
		IF varIsNickExist=1 THEN
			SET varConflictNum := varConflictNum + 1;
		ELSE
			INSERT INTO androidnickname VALUES(varGameID,varNickName);
			SET i := i + 1;
			SET varGameID := varGameID + 1;
		END IF;
	END LOOP;

END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_change_nickname
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_change_nickname`;
DELIMITER ;;
CREATE  PROCEDURE `sp_change_nickname`(
IN inUserID int(11),IN inNickname char(32),IN inIsScoreCharged tinyint(4))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	DECLARE varNickName VARCHAR(255);
	DECLARE varNickCount INT;
	DECLARE varScore BIGINT;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode = -1;
		SET retMsg = "数据库内部错误";
		SELECT retCode, retMsg;
	END;

	-- 查询用户
	SELECT `NickName` INTO varNickName FROM `AccountsInfo` WHERE `UserID`=inUserID;
	IF ISNULL(varNickName) THEN
		SET retCode := 1;
		SET retMsg = "您的帐号不存在";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	IF inNickname=varNickName THEN
		SET retCode := 2;
		SET retMsg = "昵称相同，不需要修改";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	#IF inIsScoreCharged=0 THEN
		#IF LEFT(varNickName, 2)="游客" THEN
			#SET inIsScoreCharged := 1;
		#END IF;
	#END IF;

	SELECT COUNT(`NickName`) INTO varNickCount FROM `AccountsInfo` WHERE `NickName`=inNickname;
	IF varNickCount > 0 THEN
		SET retCode := 3;
		SET retMsg = "此昵称已被其他玩家使用了";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	START TRANSACTION;
		UPDATE `AccountsInfo` SET `NickName`=inNickname WHERE `UserID`=inUserID;
		IF inIsScoreCharged=0 THEN
		
			#UPDATE `ssfishdb`.`t_bag` SET `ItemCount`=`ItemCount`-100000 WHERE `UserId`=inUserID and ItemId = 1001;
			SELECT `ItemCount` INTO varScore FROM `ssfishdb`.`t_bag` WHERE `UserId`=inUserID and ItemId = 1001;
			IF ISNULL(varScore) THEN
				SET varScore := -1;
			END IF;

			IF varScore < 100000 THEN
				ROLLBACK;

				SET retCode := 4;
				SET retMsg = "您的金币少于10万，不能修改";
				SELECT retCode, retMsg;
				LEAVE THIS_PROCEDURE;
			END IF;
		END IF;
	COMMIT;

	SET retCode := 0;
	SET retMsg := "SUCCESS";
	SELECT retCode, retMsg, varScore AS "Score";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_gameserver_login
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_gameserver_login`;
DELIMITER ;;
CREATE  PROCEDURE `sp_gameserver_login`(IN inUserID int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	-- 基本信息
	DECLARE varUserID INT;
	DECLARE varGameID INT;
	DECLARE varPlatformID INT;
	DECLARE varGender TINYINT;
	DECLARE varFaceID SMALLINT;
	DECLARE varNickName CHAR(32);
	DECLARE varPlatformFace CHAR(32);
	DECLARE varSignature VARCHAR(255);
	DECLARE varHideFlag SMALLINT;

	-- 用户状态
	DECLARE varStatus TINYINT UNSIGNED;

	-- 积分信息
	DECLARE varUserMedal INT;
	DECLARE varGift INT;
	DECLARE varPresent INT;
	DECLARE	varExperience INT;
	DECLARE	varLoveLiness INT;
	DECLARE varContribution INT;

	DECLARE varScore BIGINT;
	DECLARE varInsure BIGINT;
	DECLARE varWinCount INT;
	DECLARE varLostCount INT;
	DECLARE varFleeCount INT;
	DECLARE varDrawCount INT;

	-- 会员信息
	DECLARE varUserRight INT;
	DECLARE varMasterRight INT;
	DECLARE varMemberOrder TINYINT;
	DECLARE varMasterOrder TINYINT;

	CALL sp_inner_is_login_closed(retCode, retMsg);
	IF retCode=1 THEN
		SET retCode := 1;
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	-- 查询用户
	SELECT `UserID`, `GameID`, `PlatformID`, `NickName`, `FaceID`, `Gender`, `UserMedal`, `Experience`, `Gift`, `Present`, `LoveLiness`, `UserRight`, `MasterRight`, `MemberOrder`, `MasterOrder`, `Status`, `Contribution` INTO varUserID, varGameID, varPlatformID, varNickName, varFaceID, varGender, varUserMedal, varExperience, varGift, varPresent, varLoveLiness, varUserRight, varMasterRight, varMemberOrder, varMasterOrder, varStatus, varContribution FROM `AccountsInfo` WHERE `UserID`=inUserID;

	IF ISNULL(varUserID) THEN
		SET retCode := 4;
		SET retMsg = "您的帐号不存在";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	CALL sp_inner_is_nullity(varStatus, retCode);
	IF retCode=1 THEN
		SET retCode := 5;
		SET retMsg = "您的帐号处于冻结状态，请与客服联系";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	CALL sp_inner_is_stundown(varStatus, retCode);
	IF retCode=1 THEN
		SET retCode := 6;
		SET retMsg = "您的帐号使用了安全关闭功能，必须重新开通后才能继续使用";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	SELECT `Score`, `InsureScore`, `WinCount`, `LostCount`, `FleeCount`, `DrawCount` INTO varScore, varInsure, varWinCount, varLostCount, varFleeCount, varDrawCount FROM `sstreasuredb`.`GameScoreInfo` WHERE `UserID`=inUserID;

	SELECT `Signature`,`HideFlag` INTO varSignature,varHideFlag FROM `ssaccountsdb`.`AccountsSignature` WHERE `UserID`=inUserID;

	SELECT `PlatformFace` INTO varPlatformFace FROM `ssaccountsdb`.`AccountsFace` WHERE `UserID`=inUserID;

	SET retCode := 0;
	SET retMsg := "SUCCESS";

	SELECT retCode, retMsg, varPlatformID AS "PlatformID", varUserID AS "UserID", varGameID AS "GameID", varGender AS "Gender", varFaceID AS "FaceID", varPlatformFace AS "PlatformFace", varNickName AS "NickName", varSignature AS "Signature",varHideFlag AS "HideFlag", varUserRight AS "UserRight", varMasterRight AS "MasterRight", varMemberOrder AS "MemberOrder", varMasterOrder AS "MasterOrder", varScore AS "Score", varInsure AS "Insure", varUserMedal AS "UserMedal", varGift AS "Gift", varPresent AS "Present", varExperience AS "Experience", varLoveLiness AS "LoveLiness", varStatus AS "Status", varContribution AS "Contribution", varWinCount AS "WinCount", varLostCount AS "LostCount", varFleeCount AS "FleeCount", varDrawCount AS "DrawCount";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_gameserver_logout
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_gameserver_logout`;
DELIMITER ;;
CREATE  PROCEDURE `sp_gameserver_logout`(
IN inOutID int(11),IN inUserID int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	DECLARE varEnterDate DATE;
	DECLARE varEnterTime DATETIME;
	DECLARE varOnLineTimeCount INT;
	DECLARE varKindID INT;

	DECLARE varLeaveScore BIGINT;
	DECLARE varLeaveInsure BIGINT;
	DECLARE varLeaveMedal INT;
	DECLARE varLeaveExp INT;
	DECLARE varLeaveLove INT;
	DECLARE varLeaveGift INT;
	DECLARE varLeaveGem INT;
	DECLARE varLeavePresent INT;

	DECLARE varEnterScore BIGINT;
	DECLARE varEntreInsure BIGINT;
	DECLARE varEnterMedal INT;
	DECLARE varEnterExp INT;
	DECLARE varEnterLove INT;
	DECLARE varEnterGift INT;
	DECLARE varEnterPresent INT;

	DECLARE varDeltScore BIGINT;
	DECLARE varDeltInsure BIGINT;
	DECLARE varDeltMedal INT;
	DECLARE varDeltExp INT;
	DECLARE varDeltLove INT;
	DECLARE varDeltGift INT;
	DECLARE varDeltPresent INT;

	DECLARE varLeaveWinCount INT;
	DECLARE varLeaveLostCount INT;
	DECLARE varLeaveDrawCount INT;
	DECLARE varLeaveFleeCount INT;

	DECLARE varMasterOrder TINYINT;
	DECLARE varMemberOrder TINYINT;
	DECLARE varUserRight INT;
	DECLARE varMasterRight INT;
	DECLARE varContribution INT;
	DECLARE varStatus INT;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode = -1;
		SET retMsg = "数据库内部错误";
		SELECT retCode, retMsg;
	END;

	SELECT `EnterTime`, `KindID`, `EnterScore`, `EntreInsure`, `EnterMedal`, `EnterExp`, `EnterLove`, `EnterGift`, `EnterPresent` INTO varEnterTime, varKindID, varEnterScore, varEntreInsure, varEnterMedal, varEnterExp, varEnterLove, varEnterGift, varEnterPresent FROM `ssrecorddb`.`UserInOut` WHERE `ID`=inOutID AND `UserID`=inUserID;
	IF ISNULL(varEnterTime) THEN
		SET retCode := 2;
		SET retMsg = "找不到进出记录";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;
	SET varEnterDate := DATE(varEnterTime);
	SET varOnLineTimeCount := TIMESTAMPDIFF(SECOND, varEnterTime, NOW());

	#SELECT `Score`,`Gift`,`Gem` INTO varLeaveScore,varLeaveGift,varLeaveGem from (select UserId, SUM(Gift) as Gift,SUM(Score) as Score,SUM(Gem) as Gem FROM (select UserId, ifnull(case ItemId WHEN 1003 then ItemCount end, 0) AS Gift,ifnull(CASE ItemId when 1001 then ItemCount END, 0) as Score,ifnull(CASE ItemId when 1002 then ItemCount END, 0) as Gem from `ssfishdb`.`t_bag` where ItemId in(1001,1002,1003) ) a GROUP BY UserId) as a  WHERE a.UserId = inUserID;
	SELECT a.Score,a.Gift,a.Gem INTO varLeaveScore,varLeaveGift,varLeaveGem FROM( SELECT (CASE when ItemId=1001 then ItemCount else 0 end) as score,sum(CASE when ItemId=1003 then ItemCount else 0 end) as gift,sum(CASE when ItemId=1002 then ItemCount else 0 end) as gem FROM ssfishdb.t_bag WHERE ItemId in (1001,1002,1003) and UserId = inUserID) a;
	SELECT `InsureScore`, `WinCount`, `LostCount`, `DrawCount`, `FleeCount` INTO  varLeaveInsure, varLeaveWinCount, varLeaveLostCount, varLeaveDrawCount, varLeaveFleeCount FROM `sstreasuredb`.`GameScoreInfo` WHERE `UserID`=inUserID;
	SELECT `UserMedal`, `Experience`, `LoveLiness`, `Present`, `MasterOrder`, `MemberOrder`, `UserRight`, `MasterRight`, `Contribution`, `Status` INTO varLeaveMedal, varLeaveExp, varLeaveLove, varLeavePresent, varMasterOrder, varMemberOrder, varUserRight, varMasterRight, varContribution, varStatus FROM `ssaccountsdb`.`AccountsInfo` WHERE `UserID`=inUserID;

	SET varDeltScore := varLeaveScore-varEnterScore;
	SET varDeltInsure := varLeaveInsure-varEntreInsure;
	SET varDeltMedal := varLeaveMedal-varEnterMedal;
	SET varDeltExp := varLeaveExp-varEnterExp;
	SET varDeltLove := varLeaveLove-varEnterLove;
	SET varDeltGift := varLeaveGift-varEnterGift;
	SET varDeltPresent := varLeavePresent-varEnterPresent;

	-- GSP_GR_LeaveGameServerEx里面泡分设置没有添加
	START TRANSACTION;
		UPDATE `ssaccountsdb`.`AccountsInfo` SET `OnLineTimeCount`=`OnLineTimeCount`+varOnLineTimeCount WHERE `UserID`=inUserID;

		UPDATE `ssrecorddb`.`UserInOut` SET `LeaveTime`=NOW(), `LeaveScore`=varLeaveScore, `LeaveInsure`=varLeaveInsure, `LeaveMedal`=varLeaveMedal, `LeaveExp`=varLeaveExp, `LeaveLove`=varLeaveLove, `LeaveGift`=varLeaveGift, `LeavePresent`=varLeavePresent, `LeaveWinCount`=varLeaveWinCount, `LeaveLostCount`=varLeaveLostCount, `LeaveDrawCount`=varLeaveDrawCount, `LeaveFleeCount`=varLeaveFleeCount,`LeaveGem`=varLeaveGem WHERE `ID`=inOutID;

		-- 还需要插入`UserVariateDay`
		INSERT INTO `ssrecorddb`.`UserVariateDay` (`UserID`, `KindID`, `RecordDate`, `Score`, `Insure`, `Medal`, `Experience`, `Loveliness`, `Gift`, `Present`) VALUES (inUserID, varKindID, varEnterDate, varDeltScore, varDeltInsure, varDeltMedal, varDeltExp, varDeltLove, varDeltGift, varDeltPresent) ON DUPLICATE KEY UPDATE `Score`=`Score`+varDeltScore, `Insure`=`Insure`+varDeltInsure, `Medal`=`Medal`+varDeltMedal, `Experience`=`Experience`+varDeltExp, `Loveliness`=`Loveliness`+varDeltLove, `Gift`=`Gift`+varDeltGift, `Present`=`Present`+varDeltPresent;
	COMMIT;

	SET retCode := 0;
	SET retMsg := "SUCCESS";
	SELECT retCode, retMsg, varLeaveScore AS "Score", varLeaveInsure AS "Insure", varLeaveMedal AS "UserMedal", varLeaveExp AS "Experience", varLeaveLove AS "LoveLiness", varLeaveGift AS "Gift", varLeavePresent AS "Present", varMasterOrder AS "MasterOrder", varMemberOrder AS "MemberOrder", varUserRight AS "UserRight", varMasterRight AS "MasterRight", varContribution AS "Contribution", varStatus AS "Status";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_inner_create_android
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_inner_create_android`;
DELIMITER ;;
CREATE  PROCEDURE `sp_inner_create_android`(
)
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE varNickName CHAR(32);
	DECLARE varIsNickExist TINYINT;
	DECLARE varConflictNum TINYINT DEFAULT 0;
	DECLARE varCursor1 CURSOR FOR SELECT `NickName` FROM `AndroidNickName` ORDER BY `ID` ASC;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET varConflictNum := 127;

	OPEN varCursor1;
	nickNameLoop: LOOP
		FETCH varCursor1 INTO varNickName;
		IF varConflictNum>=100 THEN
			LEAVE nickNameLoop;
		END IF;


		SELECT COUNT(`NickName`) INTO varIsNickExist FROM `AccountsInfo` WHERE `NickName`=varNickName;
		IF varIsNickExist=1 THEN
			SET varConflictNum := varConflictNum + 1;
		ELSE
			CALL sp_inner_login_do_register(0, varNickName, "127.0.0.1", "", 1);
		END IF;
	END LOOP;
	CLOSE varCursor1;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_inner_gameid_generate
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_inner_gameid_generate`;
DELIMITER ;;
CREATE  PROCEDURE `sp_inner_gameid_generate`(
IN inCount int(11))
    SQL SECURITY INVOKER
BEGIN
	DECLARE varGameID INT;
	DECLARE varUserID INT;
	DECLARE i INT DEFAULT 0;
	
	SELECT MAX(`GameID`) INTO varGameID FROM `GameIdentifier`;
	IF ISNULL(varGameID) THEN
		SET varGameID := 1;
	ELSE
		SET varGameID := varGameID + 1;
	END IF;

	SELECT MAX(`UserID`) INTO varUserID FROM `GameIdentifier`;
	IF ISNULL(varUserID) THEN
		SET varUserID := 1;
	ELSE
		SET varUserID := varUserID + 1;
	END IF;

	WHILE i < inCount DO
		INSERT INTO GameIdentifier (`GameID`, `UserID`) VALUES (varGameID, varUserID);
		SET varUserID := varUserID + 1;
		SET varGameID := varGameID + 1;
		SET i := i + 1;
	END WHILE;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_inner_is_ip_banned
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_inner_is_ip_banned`;
DELIMITER ;;
CREATE  PROCEDURE `sp_inner_is_ip_banned`(
IN inIPAddress char(15),IN inAction tinyint(3) unsigned,OUT outRetCode tinyint(4))
    SQL SECURITY INVOKER
BEGIN
	DECLARE varRecordCnt INT;

	SELECT COUNT(`AddrString`) INTO varRecordCnt FROM `ConfineAddress` WHERE `AddrString`=inIPAddress AND `EnjoinMask`&inAction=inAction AND `EnjoinOverDate`>NOW();
	IF varRecordCnt > 0 THEN
		SET outRetCode := 1;
	ELSE
		SET outRetCode := 0;
	END IF;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_inner_is_login_closed
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_inner_is_login_closed`;
DELIMITER ;;
CREATE  PROCEDURE `sp_inner_is_login_closed`(
OUT outRetCode int(11),OUT outRetStr varchar(255))
    SQL SECURITY INVOKER
BEGIN
	DECLARE varIsEnjoinLogon INT;
	DECLARE varStatusString VARCHAR(255);

	SELECT `StatusValue`, `StatusString` INTO varIsEnjoinLogon, varStatusString FROM `SystemStatusInfo` WHERE StatusName="EnjoinLogon";
	IF varIsEnjoinLogon=1 THEN
		SET outRetCode := 1;
		SET outRetStr := varStatusString;
	ELSE
		SET outRetCode := 0;
	END IF;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_inner_is_machine_banned
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_inner_is_machine_banned`;
DELIMITER ;;
CREATE  PROCEDURE `sp_inner_is_machine_banned`(
IN inMachine char(32),IN inAction tinyint(3) unsigned,OUT outRetCode tinyint(4))
    SQL SECURITY INVOKER
BEGIN
	DECLARE varRecordCnt INT;

	SELECT COUNT(`MachineSerial`) INTO varRecordCnt FROM `ConfineMachine` WHERE `MachineSerial`=inMachine AND `EnjoinMask`&inAction=inAction AND `EnjoinOverDate`>NOW();
	IF varRecordCnt > 0 THEN
		SET outRetCode := 1;
	ELSE
		SET outRetCode := 0;
	END IF;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_inner_is_nullity
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_inner_is_nullity`;
DELIMITER ;;
CREATE  PROCEDURE `sp_inner_is_nullity`(
IN inStatus tinyint(3) unsigned,OUT outRetCode tinyint(4))
    SQL SECURITY INVOKER
BEGIN
	IF (inStatus & 0x01) > 0 THEN
		SET outRetCode := 1;
	ELSE
		SET outRetCode := 0;
	END IF;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_inner_is_stundown
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_inner_is_stundown`;
DELIMITER ;;
CREATE  PROCEDURE `sp_inner_is_stundown`(
IN inStatus tinyint(3) unsigned,OUT outRetCode tinyint(4))
    SQL SECURITY INVOKER
BEGIN
	IF (inStatus & 0x02) > 0 THEN
		SET outRetCode := 1;
	ELSE
		SET outRetCode := 0;
	END IF;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_inner_login_do_register
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_inner_login_do_register`;
DELIMITER ;;
CREATE  PROCEDURE `sp_inner_login_do_register`(
IN inPlatformID int(11),IN inPlatformNick char(32),IN inIPAddr char(15),IN inMachineSerial char(32),IN inIsAndroid tinyint(4))
    SQL SECURITY INVOKER
BEGIN
	DECLARE varIsNickNameExist TINYINT;
	DECLARE varUserID INT;
	DECLARE varGameID INT;
	DECLARE varNickName CHAR(32);


	DECLARE varRegisterScore INT;
	DECLARE varRegisterMachineLimit INT;
	DECLARE varRegisterMachineCount INT;
	DECLARE varIsLimited TINYINT;
	DECLARE varFaceID INT;

	SET varFaceID := FLOOR(1+RAND()*100%37);

	if CHAR_LENGTH(inPlatformNick) < 4 THEN
		SET varNickName := CONCAT("游客", SUBSTR(UUID(),1,8));
	else
		SELECT COUNT(`NickName`) INTO varIsNickNameExist FROM `AccountsInfo` WHERE `NickName`=inPlatformNick;
		IF varIsNickNameExist>0 THEN
			SET varNickName := CONCAT("游客", SUBSTR(UUID(),1,8));
		ELSE
			SET varNickName := inPlatformNick;
		END IF;
	end if;

	INSERT INTO `AccountsInfo` (`PlatformID`, `NickName`, `Gender`, `FaceID`, `GameLogonTimes`, `LastLogonIP`, `LastLogonDate`, `LastLogonMachine`, `RegisterIP`, `RegisterDate`, `RegisterMachine`) VALUES (inPlatformID, varNickName, 0, varFaceID, 1, inIPAddr, NOW(), inMachineSerial, inIPAddr, NOW(), inMachineSerial);
	SET varUserID := LAST_INSERT_ID();

	UPDATE `AccountsInfo` SET `GameID`=varUserID+300000 WHERE `UserID`=varUserID;


	IF inIsAndroid=0 THEN
		-- 统计日志
		INSERT INTO `SystemStreamInfo` (`CollectDate`, `GameRegisterSuccess`) VALUES (CURRENT_DATE(), 1) ON DUPLICATE KEY UPDATE `GameRegisterSuccess`=`GameRegisterSuccess`+1;

		UPDATE `RegisertMachineCount` SET `Count`=`Count`+1 WHERE `RegisterMachine`=inMachineSerial;
		IF ROW_COUNT() = 0 THEN
			INSERT INTO `RegisertMachineCount` (`RegisterMachine`, `Count`) VALUES (inMachineSerial, 1);
		END IF;

		SELECT `Count` INTO varRegisterMachineCount FROM `RegisertMachineCount` WHERE `RegisterMachine`=inMachineSerial;
		SELECT `StatusValue` INTO varRegisterMachineLimit FROM `SystemStatusInfo` WHERE `StatusName`="RegisterMachineLimit";
		IF varRegisterMachineLimit<>0 AND varRegisterMachineCount > varRegisterMachineLimit THEN
			SET varIsLimited := 1;
		ELSE
			SET varIsLimited := 0;
		END IF;

		-- 注册赠送金币
		SELECT `StatusValue` INTO varRegisterScore FROM `SystemStatusInfo` WHERE `StatusName`="RegisterScore";
		IF varRegisterScore>0 THEN
			IF varIsLimited=1 THEN
				SET varRegisterScore := 0;
			END IF;
		ELSE
			SET varRegisterScore := 0;
		END IF;

		IF varRegisterScore > 0 THEN
			UPDATE `ssrecorddb`.`RegisterScore` SET `Score`=`Score`+varRegisterScore, `Count`=`Count`+1 WHERE `RegisterMachine`=inMachineSerial;
			IF ROW_COUNT() = 0 THEN
				INSERT INTO `ssrecorddb`.`RegisterScore` (`RegisterMachine`, `Score`, `Count`, `CollectDate`) VALUES (inMachineSerial, varRegisterScore, 1, NOW());
			END IF;
		END IF;

		IF varIsLimited=1 THEN
			UPDATE `AccountsInfo` SET `Status`=`Status`|0x10 WHERE `UserID`=varUserID;
		END IF;
	ELSE
		SET varRegisterScore := 0;
		UPDATE `AccountsInfo` SET `Status`=`Status`|0x04 WHERE `UserID`=varUserID;
	END IF;

	INSERT INTO `ssfishdb`.`t_bag` (`UserId`,`ItemId`,`ItemCount`,`EndTime`) VALUES(varUserID,1001,20000,0);

	INSERT INTO `sstreasuredb`.`GameScoreInfo` (`UserID`, `Score`) VALUES (varUserID, varRegisterScore);

END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_inner_member_update
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_inner_member_update`;
DELIMITER ;;
CREATE  PROCEDURE `sp_inner_member_update`(
IN inUserID int(11),OUT outMemberOrder tinyint(4),OUT outMemberOverDate datetime,OUT outMemberSwitchDate datetime)
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	-- 删除会员
	DELETE FROM `AccountsMember` WHERE `UserID`=inUserID AND `MemberOverDate`<=NOW();

	-- 搜索会员
	SELECT MAX(`MemberOverDate`), MAX(`MemberOrder`), MIN(`MemberOverDate`) INTO outMemberOverDate, outMemberOrder, outMemberSwitchDate FROM `AccountsMember` WHERE `UserID`=inUserID;

	-- 数据调整
	IF ISNULL(outMemberOrder) THEN
		SET outMemberOrder := 0;
	END IF;

	IF ISNULL(outMemberOverDate) THEN
		SET outMemberOverDate := "1981-10-10 00:00:00";
	END IF;

	IF ISNULL(outMemberSwitchDate) THEN
		SET outMemberSwitchDate := "1981-10-10 00:00:00";
	END IF;

	-- 更新数据
	IF outMemberOrder = 0 THEN
		UPDATE `AccountsInfo` SET `MemberOrder`=outMemberOrder, `MemberOverDate`=outMemberOverDate, `MemberSwitchDate`=outMemberSwitchDate, `UserRight`=`UserRight`&0xFFFFFDFF WHERE `UserID`=inUserID;
	ELSE
		UPDATE `AccountsInfo` SET `MemberOrder`=outMemberOrder, `MemberOverDate`=outMemberOverDate, `MemberSwitchDate`=outMemberSwitchDate, `UserRight`=`UserRight`|0x00000200 WHERE `UserID`=inUserID;
	END IF;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_is_android_config_ok
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_is_android_config_ok`;
DELIMITER ;;
CREATE  PROCEDURE `sp_is_android_config_ok`(
IN inServerID int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	#Routine body goes here...
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	DECLARE varAllowAndroid TINYINT;
	DECLARE varAndroidNum INT;
	
	SELECT `AndroidNum`, `AllowAndroid` INTO varAndroidNum, varAllowAndroid FROM `AndroidConfig` WHERE `ServerID`=inServerID;
	IF ISNULL(varAndroidNum) THEN
		SET retCode := 1;
		SET retMsg := "没有配置AndroidConfig";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	IF varAllowAndroid<>1 OR varAndroidNum<=0 THEN
		SET retCode := 2;
		SET retMsg := "AndroidConfig配置不允许机器人";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	SET retCode := 0;
	SET retMsg := "机器人配置正确";
	SELECT retCode, retMsg;

END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_is_nickname_used
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_is_nickname_used`;
DELIMITER ;;
CREATE  PROCEDURE `sp_is_nickname_used`(
IN inNickname char(32))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE varNickCount INT;

	SELECT COUNT(`NickName`) INTO varNickCount FROM `AccountsInfo` WHERE `NickName`=inNickname;
	IF varNickCount > 0 THEN
		SET varNickCount := 1;
	END IF;

	SELECT varNickCount AS "ret";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_load_android
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_load_android`;
DELIMITER ;;
CREATE  PROCEDURE `sp_load_android`(
IN inServerID int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE varStartTime INT;
	DECLARE varEndTime INT;
	DECLARE varAndroidNum INT;
	DECLARE varAllowAndroid TINYINT UNSIGNED;
	DECLARE varMinPlayDraw INT;
	DECLARE varMaxPlayDraw INT;
	DECLARE varMinTakeScore BIGINT;
	DECLARE varMaxTakeScore BIGINT;
	DECLARE varMinReposeTime INT;
	DECLARE varMaxReposeTime INT;

	DECLARE varServiceTime INT;

	DECLARE varTotalAndroidCnt INT;
	DECLARE varSelectOffset INT UNSIGNED;
	DECLARE varAndroidUserID INT;
	DECLARE varTableCount INT;
	DECLARE tempAndroidNum INT;


	SELECT `StartTime`, `EndTime`, `AndroidNum`, `AllowAndroid`, `MinPlayDraw`, `MaxPlayDraw`, `MinTakeScore`, `MaxTakeScore`, `MinReposeTime`, `MaxReposeTime` INTO varStartTime, varEndTime, varAndroidNum, varAllowAndroid, varMinPlayDraw, varMaxPlayDraw, varMinTakeScore, varMaxTakeScore, varMinReposeTime, varMaxReposeTime FROM `AndroidConfig` WHERE `ServerID`=inServerID;
	SELECT `TableCount` INTO varTableCount FROM ssplatformdb.gameroominfo WHERE `ServerID`=inServerID;
	SET tempAndroidNum := varAndroidNum;
	
	DELETE FROM `AndroidManager` WHERE `ServerID`=inServerID;

	IF varAllowAndroid=1 THEN
		SET varServiceTime := POW(2, varEndTime) - POW(2, varStartTime);

		SELECT COUNT(`Status`) INTO varTotalAndroidCnt FROM `AccountsInfo` WHERE `Status`&0x04<>0;
		
		selectLoop: LOOP
			SET varSelectOffset := FLOOR(RAND() * varTotalAndroidCnt);

			SELECT `UserID` INTO varAndroidUserID FROM `AccountsInfo` WHERE `Status`&0x04<>0 LIMIT varSelectOffset, 1;
			IF NOT ISNULL(varAndroidUserID) AND NOT EXISTS(SELECT `UserID` FROM `AndroidManager` WHERE `UserID`=varAndroidUserID) THEN
				INSERT INTO `AndroidManager` (`UserID`, `ServerID`, `MinPlayDraw`, `MaxPlayDraw`, `MinTakeScore`, `MaxTakeScore`, `MinReposeTime`, `MaxReposeTime`, `ServiceTime`, `ServiceGender`, `CreateDate`,`TableId`) VALUES (varAndroidUserID, inServerID, varMinPlayDraw, varMaxPlayDraw, varMinTakeScore, varMaxTakeScore, varMinReposeTime, varMaxReposeTime, varServiceTime, 7, LOCALTIME(),varTableCount);
				SET varAndroidNum := varAndroidNum - 1;
			END IF;

			IF varAndroidNum<=0 THEN
				SET varAndroidNum := tempAndroidNum;
				SET varTableCount := varTableCount - 1;
				IF varTableCount <= 0 THEN
					LEAVE selectLoop;
				END IF;
			END IF;
		END LOOP;
	END IF;

	SELECT * FROM `AndroidManager` WHERE `ServerID`=inServerID;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_load_user_logon_message
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_load_user_logon_message`;
DELIMITER ;;
CREATE  PROCEDURE `sp_load_user_logon_message`(
IN inUserID int(11))
    SQL SECURITY INVOKER
BEGIN
	DECLARE varCurrentTS DATETIME;
	SET varCurrentTS := NOW();

	SELECT `ID` AS "id", UNIX_TIMESTAMP(`StartTime`) AS "startTime", `MessageString` AS "msg" FROM `LogonUsersMessage` WHERE `UserID`=inUserID AND `StartTime`<varCurrentTS ORDER BY `ID` ASC;
	DELETE FROM `LogonUsersMessage` WHERE `UserID`=inUserID AND `StartTime`<varCurrentTS;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_loginserver_login
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_loginserver_login`;
DELIMITER ;;
CREATE  PROCEDURE `sp_loginserver_login`(IN inPlatformID int(11),IN inPlatformNick char(32),IN inIPAddr char(15),IN inMachineSerial char(32))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	-- 基本信息
	DECLARE varUserID INT;
	DECLARE varGameID INT;
	DECLARE varGender TINYINT;
	DECLARE varFaceID SMALLINT;
	DECLARE varPlatformFace CHAR(32);
	DECLARE varNickName CHAR(32);
	DECLARE varSignature VARCHAR(255);
	DECLARE varHideFlag SMALLINT;
	
	-- 积分信息
	DECLARE varUserMedal INT;
	DECLARE varGift INT;
	DECLARE varPresent INT;
	DECLARE	varExperience INT;
	DECLARE	varLoveLiness INT;

	DECLARE varScore BIGINT;
	DECLARE varInsure BIGINT;
	DECLARE varWinCount INT;
	DECLARE varLostCount INT;
	DECLARE varFleeCount INT;
	DECLARE varDrawCount INT;

	-- 会员信息
	DECLARE varUserRight INT;
	DECLARE varMasterRight INT;
	DECLARE varMasterOrder TINYINT;
	DECLARE varMemberOrder TINYINT;
	DECLARE varMemberOverDate DATETIME;
	DECLARE varMemberSwitchDate DATETIME;
	
	DECLARE varStatus TINYINT UNSIGNED;
	DECLARE varContribution INT;

	-- 辅助变量
	DECLARE varIsFirstRegister INT DEFAULT 0;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode = -1;
		SET retMsg = "数据库内部错误";
		SELECT retCode, retMsg;
	END;

	CALL sp_inner_is_login_closed(retCode, retMsg);
	IF retCode=1 THEN
		SET retCode := 1;
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	CALL sp_inner_is_ip_banned(inIPAddr, 0x01, retCode);
	IF retCode=1 THEN
		SET retCode := 2;
		SET retMsg = "系统禁止了您IP的登录功能，请联系客服";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	CALL sp_inner_is_machine_banned(inMachineSerial, 0x01, retCode);
	IF retCode=1 THEN
		SET retCode := 3;
		SET retMsg = "系统禁止了您机器的登录功能，请联系客服";
		SELECT retCode, retMsg;
		LEAVE THIS_PROCEDURE;
	END IF;

	-- 查询用户
	SELECT `UserID`, `GameID`, `NickName`, `FaceID`, `Gender`, `UserMedal`, `Experience`, `Gift`, `Present`, `LoveLiness`, `UserRight`, `MasterRight`, `MasterOrder`, `MemberOrder`, `MemberOverDate`, `MemberSwitchDate`, `Status`, `Contribution` INTO varUserID, varGameID, varNickName, varFaceID, varGender, varUserMedal, varExperience, varGift, varPresent, varLoveLiness, varUserRight, varMasterRight, varMasterOrder, varMemberOrder, varMemberOverDate, varMemberSwitchDate, varStatus, varContribution FROM `AccountsInfo` WHERE `PlatformID`=inPlatformID;

	START TRANSACTION;
		IF ISNULL(varUserID) THEN
			CALL sp_inner_login_do_register(inPlatformID, inPlatformNick, inIPAddr, inMachineSerial, 0);
			SET varIsFirstRegister := 1;

			SELECT `UserID`, `GameID`, `NickName`, `FaceID`, `Gender`, `UserMedal`, `Experience`, `Gift`, `Present`, `LoveLiness`, `UserRight`, `MasterRight`, `MasterOrder`, `MemberOrder`, `MemberOverDate`, `MemberSwitchDate`, `Status`, `Contribution` INTO varUserID, varGameID, varNickName, varFaceID, varGender, varUserMedal, varExperience, varGift, varPresent, varLoveLiness, varUserRight, varMasterRight, varMasterOrder, varMemberOrder, varMemberOverDate, varMemberSwitchDate, varStatus, varContribution FROM `AccountsInfo` WHERE `PlatformID`=inPlatformID;
		ELSE
			UPDATE `AccountsInfo` SET `LastLogonIP`=inIPAddr, `LastLogonDate`=NOW(), `LastLogonMachine`=inMachineSerial WHERE `UserID`=varUserID;

			IF varMemberOrder<>0 AND varMemberSwitchDate<NOW() THEN
				CALL sp_inner_member_update(varUserID, varMemberOrder, varMemberOverDate, varMemberSwitchDate);
			END IF;
		END IF;
	COMMIT;

	IF varIsFirstRegister=0 THEN
		CALL sp_inner_is_nullity(varStatus, retCode);
		IF retCode=1 THEN
			SET retCode := 4;
			SET retMsg = "您的帐号处于冻结状态，请与客服联系";
			SELECT retCode, retMsg;
			LEAVE THIS_PROCEDURE;
		END IF;

		CALL sp_inner_is_stundown(varStatus, retCode);
		IF retCode=1 THEN
			SET retCode := 5;
			SET retMsg = "您的帐号使用了安全关闭功能，必须重新开通后才能继续使用";
			SELECT retCode, retMsg;
			LEAVE THIS_PROCEDURE;
		END IF;
	END IF;

	SELECT `Score`, `InsureScore`, `WinCount`, `LostCount`, `FleeCount`, `DrawCount` INTO varScore, varInsure, varWinCount, varLostCount, varFleeCount, varDrawCount FROM `sstreasuredb`.`GameScoreInfo` WHERE `UserID`=varUserID;

	SELECT `Signature`,`HideFlag` INTO varSignature,varHideFlag FROM  `ssaccountsdb`.`AccountsSignature` WHERE `UserID`=varUserID;

	SELECT `PlatformFace` INTO varPlatformFace FROM `ssaccountsdb`.`AccountsFace` WHERE `UserID`=varUserID;

	SET retCode := 0;
	SET retMsg := "success";
	-- 输出变量
	SELECT retCode, retMsg, varUserID AS "UserID", inPlatformID AS "PlatformID", varGameID AS "GameID", varNickName AS "NickName", varSignature AS "Signature",varHideFlag AS "HideFlag", varFaceID AS "FaceID", varPlatformFace AS "PlatformFace", varGender AS "Gender", varUserMedal AS "UserMedal", varExperience AS "Experience", varPresent AS "Present", varScore AS "Score", varInsure AS "Insure", varLoveLiness AS "LoveLiness", varMemberOrder AS "MemberOrder", UNIX_TIMESTAMP(varMemberOverDate) AS "MemberOverDate", varGift AS "Gift", varUserRight AS "UserRight", varMasterRight AS "MasterRight", varMasterOrder AS "MasterOrder", varContribution AS "Contribution", varStatus AS "Status", varWinCount AS "WinCount", varLostCount AS "LostCount", varFleeCount AS "FleeCount", varDrawCount AS "DrawCount", varIsFirstRegister AS "IsFirstRegister";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_reload_one_android
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_reload_one_android`;
DELIMITER ;;
CREATE  PROCEDURE `sp_reload_one_android`(
IN inServerID int(11),IN inUserID int(11),IN inTableId int(11))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE varStartTime INT;
	DECLARE varEndTime INT;
	DECLARE varAndroidNum INT;
	DECLARE varAllowAndroid TINYINT UNSIGNED;
	DECLARE varMinPlayDraw INT;
	DECLARE varMaxPlayDraw INT;
	DECLARE varMinTakeScore BIGINT;
	DECLARE varMaxTakeScore BIGINT;
	DECLARE varMinReposeTime INT;
	DECLARE varMaxReposeTime INT;

	DECLARE varServiceTime INT;

	DECLARE varTotalAndroidCnt INT;
	DECLARE varSelectOffset INT UNSIGNED;
	DECLARE varAndroidUserID INT;


	SELECT `StartTime`, `EndTime`, `AndroidNum`, `AllowAndroid`, `MinPlayDraw`, `MaxPlayDraw`, `MinTakeScore`, `MaxTakeScore`, `MinReposeTime`, `MaxReposeTime` INTO varStartTime, varEndTime, varAndroidNum, varAllowAndroid, varMinPlayDraw, varMaxPlayDraw, varMinTakeScore, varMaxTakeScore, varMinReposeTime, varMaxReposeTime FROM `AndroidConfig` WHERE `ServerID`=inServerID;
	SET varAndroidNum := 1; 

	DELETE FROM `AndroidManager` WHERE `ServerID`=inServerID and `UserID`=inUserId;

	IF varAllowAndroid=1 THEN
		SET varServiceTime := POW(2, varEndTime) - POW(2, varStartTime);

		SELECT COUNT(`Status`) INTO varTotalAndroidCnt FROM `AccountsInfo` WHERE `Status`&0x04<>0;
		
		selectLoop: LOOP
			SET varSelectOffset := FLOOR(RAND() * varTotalAndroidCnt);

			SELECT `UserID` INTO varAndroidUserID FROM `AccountsInfo` WHERE `Status`&0x04<>0 LIMIT varSelectOffset, 1;
			IF NOT ISNULL(varAndroidUserID) AND NOT EXISTS(SELECT `UserID` FROM `AndroidManager` WHERE `UserID`=varAndroidUserID) THEN
				INSERT INTO `AndroidManager` (`UserID`, `ServerID`, `MinPlayDraw`, `MaxPlayDraw`, `MinTakeScore`, `MaxTakeScore`, `MinReposeTime`, `MaxReposeTime`, `ServiceTime`, `ServiceGender`, `CreateDate`,`TableId`) VALUES (varAndroidUserID, inServerID, varMinPlayDraw, varMaxPlayDraw, varMinTakeScore, varMaxTakeScore, varMinReposeTime, varMaxReposeTime, varServiceTime, 7, LOCALTIME(),inTableId);
				SET varAndroidNum := varAndroidNum - 1;
			END IF;

			IF varAndroidNum<=0 THEN
				LEAVE selectLoop;
			END IF;
		END LOOP;
	END IF;

	SELECT * FROM `AndroidManager` WHERE `ServerID`=inServerID and `UserID`=varAndroidUserID;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for sp_set_platform_face
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_set_platform_face`;
DELIMITER ;;
CREATE  PROCEDURE `sp_set_platform_face`(
IN inUserID int(11),IN inPlatformFace char(32))
    SQL SECURITY INVOKER
THIS_PROCEDURE:BEGIN
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	IF STRCMP("", inPlatformFace)<>0 THEN
		INSERT INTO `ssaccountsdb`.`AccountsFace` (`UserID`, `PlatformFace`) VALUES (inUserID, inPlatformFace) ON DUPLICATE KEY UPDATE `PlatformFace`=inPlatformFace;
	ELSE
		DELETE FROM `ssaccountsdb`.`AccountsFace` WHERE `UserID`=inUserID;
	END IF;

	SET retCode := 0;
	SET retMsg := "success";
	SELECT retCode, retMsg;
END
;;
DELIMITER ;
