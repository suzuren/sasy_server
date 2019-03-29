/*
Navicat MySQL Data Transfer

Source Server Version : 50621
Source Database       : sswebdb

Target Server Type    : MYSQL
Target Server Version : 50621
File Encoding         : 65001

*/

USE `sswebdb`;

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for b_address
-- ----------------------------
DROP TABLE IF EXISTS `b_address`;
CREATE TABLE `b_address` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `address` varchar(300) DEFAULT NULL,
  `username` varchar(255) DEFAULT NULL,
  `token` int(11) DEFAULT NULL,
  `post` int(11) DEFAULT NULL,
  `phone` bigint(11) DEFAULT NULL,
  `pid` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for b_exchange
-- ----------------------------
DROP TABLE IF EXISTS `b_exchange`;
CREATE TABLE `b_exchange` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `status` int(11) DEFAULT NULL,
  `pid` int(11) DEFAULT NULL,
  `score` int(11) DEFAULT NULL,
  `order_time` varchar(255) DEFAULT NULL,
  `gift_name` varchar(255) DEFAULT NULL,
  `pic_url` varchar(255) DEFAULT NULL,
  `gift_id` int(11) DEFAULT NULL,
  `username` varchar(255) DEFAULT NULL,
  `phone` bigint(11) DEFAULT NULL,
  `address` varchar(50) DEFAULT NULL,
  `marks` varchar(255) DEFAULT NULL,
  `post` int(11) DEFAULT NULL,
  `userId` int(11) DEFAULT NULL,
  `confirm_date` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for b_gift
-- ----------------------------
DROP TABLE IF EXISTS `b_gift`;
CREATE TABLE `b_gift` (
  `id` int(11) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `pic` varchar(255) DEFAULT NULL,
  `score` int(11) DEFAULT NULL,
  `type` int(11) DEFAULT NULL,
  `is_online` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for d_channel
-- ----------------------------
DROP TABLE IF EXISTS `d_channel`;
CREATE TABLE `d_channel` (
  `channelId` int(11) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`channelId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for d_pay_info
-- ----------------------------
DROP TABLE IF EXISTS `d_pay_info`;
CREATE TABLE `d_pay_info` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `price` int(11) NOT NULL DEFAULT '0',
  `nameStr` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=473 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for d_self_channel
-- ----------------------------
DROP TABLE IF EXISTS `d_self_channel`;
CREATE TABLE `d_self_channel` (
  `selfId` int(11) NOT NULL,
  `channelId` int(11) NOT NULL DEFAULT '0' COMMENT '渠道id',
  `appName` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`selfId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for platforminfo
-- ----------------------------
DROP TABLE IF EXISTS `platforminfo`;
CREATE TABLE `platforminfo` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '账号id',
  `account` varchar(255) NOT NULL,
  `pwd` varchar(255) NOT NULL,
  `rMachineId` varchar(255) NOT NULL,
  `rTime` datetime NOT NULL,
  `rSelfId` int(11) NOT NULL DEFAULT '0',
  `rDeviceId` varchar(255) NOT NULL DEFAULT '',
  `rAndroidId` varchar(255) NOT NULL DEFAULT '',
  `lMachineId` varchar(255) NOT NULL,
  `lTime` datetime NOT NULL,
  `lSelfId` int(11) NOT NULL DEFAULT '0',
  `lDeviceId` varchar(255) NOT NULL DEFAULT '',
  `lAndroidId` varchar(255) NOT NULL DEFAULT '',
  `phone` bigint(20) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx1` (`account`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for s_apple_pay
-- ----------------------------
DROP TABLE IF EXISTS `s_apple_pay`;
CREATE TABLE `s_apple_pay` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `transaction_id` varchar(255) NOT NULL COMMENT '票据',
  `isSandbox` int(11) NOT NULL DEFAULT '0',
  `bid` varchar(255) DEFAULT NULL COMMENT '客户端包名',
  `purchase_date` varchar(255) DEFAULT NULL,
  `product_id` varchar(255) DEFAULT NULL,
  `serverTp` int(11) NOT NULL DEFAULT '0',
  `pid` int(11) NOT NULL,
  `opTime` datetime NOT NULL,
  `selfId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx1` (`transaction_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for s_bbn_pay
-- ----------------------------
DROP TABLE IF EXISTS `s_bbn_pay`;
CREATE TABLE `s_bbn_pay` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '唯一自增id',
  `pid` int(11) NOT NULL DEFAULT '0' COMMENT '玩家平台id',
  `payId` int(11) NOT NULL DEFAULT '0' COMMENT '所买商品id',
  `price` int(11) NOT NULL DEFAULT '0' COMMENT '价格（分）',
  `orderBegin` varchar(32) NOT NULL,
  `serverTp` int(11) NOT NULL DEFAULT '0' COMMENT '0未处理，1已处理成功，2已处理失败',
  `opTime` datetime NOT NULL,
  `selfId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for s_bind_phone
-- ----------------------------
DROP TABLE IF EXISTS `s_bind_phone`;
CREATE TABLE `s_bind_phone` (
  `pid` int(11) NOT NULL,
  `session` varchar(255) DEFAULT NULL,
  `num` bigint(20) DEFAULT NULL,
  `num1` bigint(20) DEFAULT NULL,
  `pwd` varchar(255) DEFAULT NULL,
  `opTime` datetime DEFAULT NULL,
  PRIMARY KEY (`pid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for s_htc_pay
-- ----------------------------
DROP TABLE IF EXISTS `s_htc_pay`;
CREATE TABLE `s_htc_pay` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '唯一自增id',
  `pid` int(11) NOT NULL DEFAULT '0' COMMENT '玩家平台id',
  `payId` int(11) NOT NULL DEFAULT '0' COMMENT '所买商品id',
  `price` int(11) NOT NULL DEFAULT '0' COMMENT '价格（分）',
  `orderBegin` varchar(32) NOT NULL,
  `serverTp` int(11) NOT NULL DEFAULT '0' COMMENT '0未处理，1已处理成功，2已处理失败',
  `opTime` datetime NOT NULL,
  `selfId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for s_oppo_pay
-- ----------------------------
DROP TABLE IF EXISTS `s_oppo_pay`;
CREATE TABLE `s_oppo_pay` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '唯一自增id',
  `pid` int(11) NOT NULL DEFAULT '0' COMMENT '玩家平台id',
  `payId` int(11) NOT NULL DEFAULT '0' COMMENT '所买商品id',
  `price` int(11) NOT NULL DEFAULT '0' COMMENT '价格（分）',
  `orderBegin` varchar(32) NOT NULL,
  `serverTp` int(11) NOT NULL DEFAULT '0' COMMENT '0未处理，1已处理成功，2已处理失败',
  `opTime` datetime NOT NULL,
  `selfId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for s_pay
-- ----------------------------
DROP TABLE IF EXISTS `s_pay`;
CREATE TABLE `s_pay` (
  `orderId` varchar(32) NOT NULL,
  `pid` int(11) NOT NULL,
  `payId` int(11) NOT NULL,
  `cType` varchar(16) NOT NULL,
  `cFee` int(11) NOT NULL,
  `sTime` datetime NOT NULL,
  `channel` int(11) NOT NULL DEFAULT '0',
  `serverTp` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`orderId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for s_session_pid
-- ----------------------------
DROP TABLE IF EXISTS `s_session_pid`;
CREATE TABLE `s_session_pid` (
  `session` varchar(64) NOT NULL DEFAULT '',
  `pid` int(11) NOT NULL,
  PRIMARY KEY (`pid`),
  KEY `session` (`session`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for s_test
-- ----------------------------
DROP TABLE IF EXISTS `s_test`;
CREATE TABLE `s_test` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '唯一自增id',
  `str` varchar(511) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for s_third_info
-- ----------------------------
DROP TABLE IF EXISTS `s_third_info`;
CREATE TABLE `s_third_info` (
  `id` int(11) NOT NULL,
  `thirdStr` varchar(255) NOT NULL,
  `pid` int(11) NOT NULL,
  PRIMARY KEY (`id`,`thirdStr`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for s_uc_pay
-- ----------------------------
DROP TABLE IF EXISTS `s_uc_pay`;
CREATE TABLE `s_uc_pay` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '唯一自增id',
  `pid` int(11) NOT NULL DEFAULT '0' COMMENT '玩家平台id',
  `payId` int(11) NOT NULL DEFAULT '0' COMMENT '所买商品id',
  `price` int(11) NOT NULL DEFAULT '0' COMMENT '价格（分）',
  `orderBegin` varchar(32) NOT NULL,
  `serverTp` int(11) NOT NULL DEFAULT '0' COMMENT '0未处理，1已处理成功，2已处理失败',
  `opTime` datetime NOT NULL,
  `selfId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for s_vivio_pay
-- ----------------------------
DROP TABLE IF EXISTS `s_vivio_pay`;
CREATE TABLE `s_vivio_pay` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '唯一自增id',
  `pid` int(11) NOT NULL DEFAULT '0' COMMENT '玩家平台id',
  `payId` int(11) NOT NULL DEFAULT '0' COMMENT '所买商品id',
  `price` int(11) NOT NULL DEFAULT '0' COMMENT '价格（分）',
  `orderBegin` varchar(32) NOT NULL,
  `serverTp` int(11) NOT NULL DEFAULT '0' COMMENT '0未处理，1已处理成功，2已处理失败',
  `opTime` datetime NOT NULL,
  `selfId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for s_wifi_pay
-- ----------------------------
DROP TABLE IF EXISTS `s_wifi_pay`;
CREATE TABLE `s_wifi_pay` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '唯一自增id',
  `pid` int(11) NOT NULL DEFAULT '0' COMMENT '玩家平台id',
  `payId` int(11) NOT NULL DEFAULT '0' COMMENT '所买商品id',
  `price` int(11) NOT NULL DEFAULT '0' COMMENT '价格（分）',
  `orderBegin` varchar(32) NOT NULL,
  `serverTp` int(11) NOT NULL DEFAULT '0' COMMENT '0未处理，1已处理成功，2已处理失败',
  `opTime` datetime NOT NULL,
  `selfId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

-- ----------------------------
-- Table structure for s_wx_pay
-- ----------------------------
DROP TABLE IF EXISTS `s_wx_pay`;
CREATE TABLE `s_wx_pay` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '唯一自增id',
  `pid` int(11) NOT NULL DEFAULT '0' COMMENT '玩家平台id',
  `payId` int(11) NOT NULL DEFAULT '0' COMMENT '所买商品id',
  `price` int(11) NOT NULL DEFAULT '0' COMMENT '价格（分）',
  `orderBegin` varchar(32) NOT NULL,
  `serverTp` int(11) NOT NULL DEFAULT '0' COMMENT '0未处理，1已处理成功，2已处理失败',
  `opTime` datetime NOT NULL,
  `selfId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for s_yijie_pay
-- ----------------------------
DROP TABLE IF EXISTS `s_yijie_pay`;
CREATE TABLE `s_yijie_pay` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tcd` varchar(255) NOT NULL,
  `app` varchar(255) DEFAULT NULL,
  `cbi` varchar(255) DEFAULT NULL,
  `ct` datetime DEFAULT NULL,
  `fee` int(11) NOT NULL,
  `pt` datetime DEFAULT NULL,
  `sdk` varchar(255) DEFAULT NULL,
  `ssid` varchar(255) DEFAULT NULL,
  `st` int(11) DEFAULT NULL,
  `uid` varchar(255) DEFAULT NULL,
  `ver` varchar(255) DEFAULT NULL,
  `serverTp` int(11) NOT NULL DEFAULT '0' COMMENT '0未处理，1已处理成功，2已处理失败',
  `opTime` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx1` (`tcd`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for s_zfb_pay
-- ----------------------------
DROP TABLE IF EXISTS `s_zfb_pay`;
CREATE TABLE `s_zfb_pay` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '唯一自增id',
  `pid` int(11) NOT NULL DEFAULT '0' COMMENT '玩家平台id',
  `payId` int(11) NOT NULL DEFAULT '0' COMMENT '所买商品id',
  `price` int(11) NOT NULL DEFAULT '0' COMMENT '价格（分）',
  `orderBegin` varchar(32) NOT NULL,
  `serverTp` int(11) NOT NULL DEFAULT '0' COMMENT '0未处理，1已处理成功，2已处理失败',
  `opTime` datetime NOT NULL,
  `selfId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for s_zyf_pay
-- ----------------------------
DROP TABLE IF EXISTS `s_zyf_pay`;
CREATE TABLE `s_zyf_pay` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '唯一自增id',
  `pid` int(11) NOT NULL DEFAULT '0' COMMENT '玩家平台id',
  `payId` int(11) NOT NULL DEFAULT '0' COMMENT '所买商品id',
  `price` int(11) NOT NULL DEFAULT '0' COMMENT '价格（分）',
  `orderBegin` varchar(32) NOT NULL,
  `serverTp` int(11) NOT NULL DEFAULT '0' COMMENT '0未处理，1已处理成功，2已处理失败',
  `opTime` datetime NOT NULL,
  `selfId` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for yijieinfo
-- ----------------------------
DROP TABLE IF EXISTS `yijieinfo`;
CREATE TABLE `yijieinfo` (
  `appId` varchar(255) NOT NULL,
  `channelId` varchar(255) NOT NULL,
  `userId` varchar(255) NOT NULL,
  `platformId` int(11) NOT NULL,
  PRIMARY KEY (`appId`,`channelId`,`userId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Procedure structure for p_apple_pay
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_apple_pay`;
DELIMITER ;;
CREATE  PROCEDURE `p_apple_pay`(IN inTid CHAR(64), IN inSandbox INT, IN inBid CHAR(128), IN inPdate CHAR(32), IN inPid INT, IN inProductId CHAR(64), IN inSelfId INT)
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varId INT;
	DECLARE varIsSandbox INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";

	START TRANSACTION;
		select id,`isSandbox` into varId, varIsSandbox from `s_apple_pay` where transaction_id=inTid limit 1;
		if ISNULL(varIsSandbox) then -- 注册
			insert into `s_apple_pay` (transaction_id,isSandbox,bid,purchase_date,product_id,pid,opTime,selfId) values (inTid,inSandbox,inBid,inPdate,inProductId,inPid, NOW(), inSelfId);
			set varId := LAST_INSERT_ID();
		else
			set reCode = 1;
			set reMsg = "已经验单";
		end if;
	COMMIT;
	select reCode, reMsg, varId as "id";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_bbn_pay
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_bbn_pay`;
DELIMITER ;;
CREATE  PROCEDURE `p_bbn_pay`(IN inPid INT, IN inPayId INT, IN inOrderBegin CHAR(32), IN inSelfId INT)
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varId INT;
	DECLARE varNameStr VARCHAR(255);
	DECLARE varPrice INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";
	select price, nameStr into varPrice, varNameStr from d_pay_info where id=inPayId;
	if ISNULL(varPrice) THEN
		SET reCode = 1;
		SET reMsg = "找不到对应套餐";
		SELECT reCode, reMsg;
		LEAVE THIS_PROCEDURE;
	end if;
	START TRANSACTION;
		insert into `s_bbn_pay` (pid, payId, price, orderBegin, opTime, selfId) values (inPid, inPayId, varPrice, inOrderBegin, NOW(), inSelfId);
		set varId := LAST_INSERT_ID();
	COMMIT;
	select reCode, reMsg, varId as "id", varPrice as "price", varNameStr as "nameStr";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_bbn_pay_yq
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_bbn_pay_yq`;
DELIMITER ;;
CREATE  PROCEDURE `p_bbn_pay_yq`(IN inId INT, IN inPrice INT, IN inOrderBegin CHAR(32))
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varPid INT;
	DECLARE varPayId INT;
	DECLARE varServerTp INT;
	DECLARE varPrice INT;
	DECLARE varOrderBegin VARCHAR(255);
	DECLARE varSelfId INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";
	START TRANSACTION;
		select pid, payId, price, orderBegin, serverTp, selfId into varPid, varPayId, varPrice, varOrderBegin, varServerTp, varSelfId from s_bbn_pay where id=inId;
		if ISNULL(varPid) THEN
			SET reCode = 1;
			SET reMsg = "找不到订单";
			SELECT reCode, reMsg;
			LEAVE THIS_PROCEDURE;
		end if;
		if varPrice = inPrice and varOrderBegin = inOrderBegin and varServerTp = 0 THEN
			update s_bbn_pay set serverTp = 1 where id=inId;
		else
			SET reCode = 1;
			SET reMsg = "找不到订单";
			SELECT reCode, reMsg;
			LEAVE THIS_PROCEDURE;
		end if;
	COMMIT;
	select reCode, reMsg, varPid as "pid", varPayId as "payId", varSelfId as "selfId";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_bind_phone
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_bind_phone`;
DELIMITER ;;
CREATE  PROCEDURE `p_bind_phone`(IN inTp INT, IN inSession CHAR(64), IN inNum BIGINT, IN inNum1 INT, IN inPassword CHAR(64))
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varPid INT;
	DECLARE varOldPid INT;
	DECLARE varNum BIGINT;
	DECLARE varNum1 BIGINT;
	DECLARE varPwd VARCHAR(255);
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误1";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";

	START TRANSACTION;
		if inTp = 1 THEN -- 保存验证码
			select `pid` into varPid from `s_session_pid` where `session`=inSession limit 1;
			if ISNULL(varPid) then -- 注册
				set reCode = 1;
				set reMsg = "账号登录过期";
			else
				replace into `s_bind_phone` (pid,session,num,num1,pwd,opTime) values(varPid,inSession,inNum,inNum1,inPassword,NOW());
			end if;
		else -- 验证验证码
			select `pid`,`num`,`num1`, `pwd` into varPid, varNum, varNum1, varPwd from `s_bind_phone` where `session`=inSession limit 1;
			if ISNULL(varPid) then
				set reCode = 1;
				set reMsg = "验证码错误";
			else
				select id into varOldPid from `platforminfo` where phone = varNum limit 1;
				if not ISNULL(varOldPid) then
					set reCode = 1;
					set reMsg = "该手机号已绑定";
				else
					update `platforminfo` set pwd=varPwd and phone=varNum where id=varPid;
				end if;
				delete from `s_bind_phone` where pid = varPid;
			end if;
		end if;
	COMMIT;
	select reCode, reMsg;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_htc_pay
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_htc_pay`;
DELIMITER ;;
CREATE  PROCEDURE `p_htc_pay`(IN inPid INT, IN inPayId INT, IN inOrderBegin CHAR(32), IN inSelfId INT)
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varId INT;
	DECLARE varNameStr VARCHAR(255);
	DECLARE varPrice INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";
	select price, nameStr into varPrice, varNameStr from d_pay_info where id=inPayId;
	if ISNULL(varPrice) THEN
		SET reCode = 1;
		SET reMsg = "找不到对应套餐";
		SELECT reCode, reMsg;
		LEAVE THIS_PROCEDURE;
	end if;
	START TRANSACTION;
		insert into `s_htc_pay` (pid, payId, price, orderBegin, opTime, selfId) values (inPid, inPayId, varPrice, inOrderBegin, NOW(), inSelfId);
		set varId := LAST_INSERT_ID();
	COMMIT;
	select reCode, reMsg, varId as "id", varPrice as "price", varNameStr as "nameStr";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_htc_pay_yq
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_htc_pay_yq`;
DELIMITER ;;
CREATE  PROCEDURE `p_htc_pay_yq`(IN inId INT, IN inPrice INT, IN inOrderBegin CHAR(32))
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varPid INT;
	DECLARE varPayId INT;
	DECLARE varServerTp INT;
	DECLARE varPrice INT;
	DECLARE varOrderBegin VARCHAR(255);
	DECLARE varSelfId INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";
	START TRANSACTION;
		select pid, payId, price, orderBegin, serverTp, selfId into varPid, varPayId, varPrice, varOrderBegin, varServerTp, varSelfId from s_htc_pay where id=inId;
		if ISNULL(varPid) THEN
			SET reCode = 1;
			SET reMsg = "找不到订单";
			SELECT reCode, reMsg;
			LEAVE THIS_PROCEDURE;
		end if;
		if varPrice = inPrice and varOrderBegin = inOrderBegin and varServerTp = 0 THEN
			update s_htc_pay set serverTp = 1 where id=inId;
		else
			SET reCode = 1;
			SET reMsg = "找不到订单";
			SELECT reCode, reMsg;
			LEAVE THIS_PROCEDURE;
		end if;
	COMMIT;
	select reCode, reMsg, varPid as "pid", varPayId as "payId", varSelfId as "selfId";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_login
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_login`;
DELIMITER ;;
CREATE  PROCEDURE `p_login`(IN inAccount CHAR(32), IN inPassword CHAR(32), IN inMachineId CHAR(32), IN inTp INT, IN inSelfId INT, IN inDeviceId CHAR(64), IN inAndroidId CHAR(64))
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varId INT;
	DECLARE varPwd CHAR(32);
	DECLARE varPhone BIGINT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误1";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";

	START TRANSACTION;
		if inTp = 3 THEN
			select `id`,`pwd`,`phone` into varId, varPwd, varPhone from `platforminfo` where `phone`=inAccount limit 1;
			if ISNULL(varId) or varPwd <> inPassword  then -- 注册
				set reCode = 1;
				set reMsg = "该手机号未绑定账号或密码错误";
			end if;
		else
			select `id`,`pwd`,`phone` into varId, varPwd, varPhone from `platforminfo` where `account`=inAccount limit 1;
			if ISNULL(varId) then -- 注册
				insert into platforminfo (account,pwd,rMachineId,rTime,rSelfId,rDeviceId,rAndroidId,lMachineId,lTime,lSelfId,lDeviceId,lAndroidId) values(inAccount, inPassword, inMachineId, NOW(), inSelfId, inDeviceId, inAndroidId, inMachineId, NOW(), inSelfId, inDeviceId, inAndroidId);
				SET varId := LAST_INSERT_ID();
			elseif inTp = 2 and varPwd <> inPassword THEN
				set reCode = 1;
				set reMsg = "账号或密码错误";
			else
				update `platforminfo` set lMachineId=inMachineId,lTime=NOW(),lSelfId=inSelfId,lDeviceId=inDeviceId,lAndroidId=inAndroidId where id=varId;
			end if;
		end if;
	COMMIT;
	select reCode, reMsg, varId as 'pid', varPhone as 'phone';
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_oppo_pay
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_oppo_pay`;
DELIMITER ;;
CREATE  PROCEDURE `p_oppo_pay`(IN inPid INT, IN inPayId INT, IN inOrderBegin CHAR(32), IN inSelfId INT)
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varId INT;
	DECLARE varNameStr VARCHAR(255);
	DECLARE varPrice INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";
	select price, nameStr into varPrice, varNameStr from d_pay_info where id=inPayId;
	if ISNULL(varPrice) THEN
		SET reCode = 1;
		SET reMsg = "找不到对应套餐";
		SELECT reCode, reMsg;
		LEAVE THIS_PROCEDURE;
	end if;
	START TRANSACTION;
		insert into `s_oppo_pay` (pid, payId, price, orderBegin, opTime, selfId) values (inPid, inPayId, varPrice, inOrderBegin, NOW(), inSelfId);
		set varId := LAST_INSERT_ID();
	COMMIT;
	select reCode, reMsg, varId as "id", varPrice as "price", varNameStr as "nameStr";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_oppo_pay_yq
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_oppo_pay_yq`;
DELIMITER ;;
CREATE  PROCEDURE `p_oppo_pay_yq`(IN inId INT, IN inPrice INT, IN inOrderBegin CHAR(32))
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varPid INT;
	DECLARE varPayId INT;
	DECLARE varServerTp INT;
	DECLARE varPrice INT;
	DECLARE varOrderBegin VARCHAR(255);
	DECLARE varSelfId INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";
	START TRANSACTION;
		select pid, payId, price, orderBegin, serverTp, selfId into varPid, varPayId, varPrice, varOrderBegin, varServerTp, varSelfId from s_oppo_pay where id=inId;
		if ISNULL(varPid) THEN
			SET reCode = 1;
			SET reMsg = "找不到订单";
			SELECT reCode, reMsg;
			LEAVE THIS_PROCEDURE;
		end if;
		if varPrice = inPrice and varOrderBegin = inOrderBegin and varServerTp = 0 THEN
			update s_oppo_pay set serverTp = 1 where id=inId;
		else
			SET reCode = 1;
			SET reMsg = "找不到订单";
			SELECT reCode, reMsg;
			LEAVE THIS_PROCEDURE;
		end if;
	COMMIT;
	select reCode, reMsg, varPid as "pid", varPayId as "payId", varSelfId as "selfId";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_third_login
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_third_login`;
DELIMITER ;;
CREATE  PROCEDURE `p_third_login`(IN inId INT,IN inThirdStr CHAR(64),IN inMachineSerial CHAR(32), IN inSelfId INT)
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	-- 基本信息
	DECLARE varPlatformId INT;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode = -1;
		SET retMsg = "数据库内部错误";
		SELECT retCode, retMsg;
	END;

	-- 查询用户

	START TRANSACTION;
		SELECT `pid` INTO varPlatformId FROM `s_third_info` WHERE `id`=inId and `thirdStr`=inThirdStr;
		IF ISNULL(varPlatformId) THEN
			INSERT INTO `platforminfo` (`account`,`pwd`,`rMachineId`,`rTime`,`rSelfId`,`lMachineId`,`lTime`,`lSelfId`) VALUES ("", "", inMachineSerial, NOW(), inSelfId, inMachineSerial, NOW(), inSelfId);
			SET varPlatformId := LAST_INSERT_ID();
			INSERT INTO `s_third_info` (`id`,`thirdStr`,`pid`) VALUES (inId, inThirdStr, varPlatformId);
		else
			update `platforminfo` set lMachineId=inMachineSerial,lTime=NOW(),lSelfId=inSelfId where id=varPlatformId;
		END IF;
	COMMIT;

	SET retCode := 0;
	SET retMsg := "success";
	-- 输出变量
	SELECT retCode, retMsg, varPlatformId AS "pid";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_uc_pay
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_uc_pay`;
DELIMITER ;;
CREATE  PROCEDURE `p_uc_pay`(IN inPid INT, IN inPayId INT, IN inOrderBegin CHAR(32), IN inSelfId INT)
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varId INT;
	DECLARE varNameStr VARCHAR(255);
	DECLARE varPrice INT;
	DECLARE varThirdStr VARCHAR(255);
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";
	select price, nameStr into varPrice, varNameStr from d_pay_info where id=inPayId;
	if ISNULL(varPrice) THEN
		SET reCode = 1;
		SET reMsg = "找不到对应套餐";
		SELECT reCode, reMsg;
		LEAVE THIS_PROCEDURE;
	end if;
	select thirdStr into varThirdStr from s_third_info where pid=inPid;
	if ISNULL(varThirdStr) THEN
		SET reCode = 1;
		SET reMsg = "找不到对应用户";
		SELECT reCode, reMsg;
		LEAVE THIS_PROCEDURE;
	end if;
	START TRANSACTION;
		insert into `s_uc_pay` (pid, payId, price, orderBegin, opTime, selfId) values (inPid, inPayId, varPrice, inOrderBegin, NOW(), inSelfId);
		set varId := LAST_INSERT_ID();
	COMMIT;
	select reCode, reMsg, varId as "id", varPrice as "price", varNameStr as "nameStr", varThirdStr as "thirdStr";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_uc_pay_yq
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_uc_pay_yq`;
DELIMITER ;;
CREATE  PROCEDURE `p_uc_pay_yq`(IN inId INT, IN inPrice INT, IN inOrderBegin CHAR(32))
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varPid INT;
	DECLARE varPayId INT;
	DECLARE varServerTp INT;
	DECLARE varPrice INT;
	DECLARE varOrderBegin VARCHAR(255);
	DECLARE varSelfId INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";
	START TRANSACTION;
		select pid, payId, price, orderBegin, serverTp, selfId into varPid, varPayId, varPrice, varOrderBegin, varServerTp, varSelfId from s_uc_pay where id=inId;
		if ISNULL(varPid) THEN
			SET reCode = 1;
			SET reMsg = "找不到订单";
			SELECT reCode, reMsg;
			LEAVE THIS_PROCEDURE;
		end if;
		if varPrice = inPrice and varOrderBegin = inOrderBegin and varServerTp = 0 THEN
			update s_uc_pay set serverTp = 1 where id=inId;
		else
			SET reCode = 1;
			SET reMsg = "找不到订单";
			SELECT reCode, reMsg;
			LEAVE THIS_PROCEDURE;
		end if;
	COMMIT;
	select reCode, reMsg, varPid as "pid", varPayId as "payId", varSelfId as "selfId";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_vivo_pay
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_vivo_pay`;
DELIMITER ;;
CREATE  PROCEDURE `p_vivo_pay`(IN inPid INT, IN inPayId INT, IN inOrderBegin CHAR(32), IN inSelfId INT)
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varId INT;
	DECLARE varNameStr VARCHAR(255);
	DECLARE varPrice INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";
	select price, nameStr into varPrice, varNameStr from d_pay_info where id=inPayId;
	if ISNULL(varPrice) THEN
		SET reCode = 1;
		SET reMsg = "找不到对应套餐";
		SELECT reCode, reMsg;
		LEAVE THIS_PROCEDURE;
	end if;
	START TRANSACTION;
		insert into `s_vivio_pay` (pid, payId, price, orderBegin, opTime, selfId) values (inPid, inPayId, varPrice, inOrderBegin, NOW(), inSelfId);
		set varId := LAST_INSERT_ID();
	COMMIT;
	select reCode, reMsg, varId as "id", varPrice as "price", varNameStr as "nameStr";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_vivo_pay_yq
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_vivo_pay_yq`;
DELIMITER ;;
CREATE  PROCEDURE `p_vivo_pay_yq`(IN inId INT, IN inPrice INT, IN inOrderBegin CHAR(32))
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varPid INT;
	DECLARE varPayId INT;
	DECLARE varServerTp INT;
	DECLARE varPrice INT;
	DECLARE varOrderBegin VARCHAR(255);
	DECLARE varSelfId INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";
	START TRANSACTION;
		select pid, payId, price, orderBegin, serverTp, selfId into varPid, varPayId, varPrice, varOrderBegin, varServerTp, varSelfId from s_vivio_pay where id=inId;
		if ISNULL(varPid) THEN
			SET reCode = 1;
			SET reMsg = "找不到订单";
			SELECT reCode, reMsg;
			LEAVE THIS_PROCEDURE;
		end if;
		if varPrice = inPrice and varOrderBegin = inOrderBegin and varServerTp = 0 THEN
			update s_vivio_pay set serverTp = 1 where id=inId;
		else
			SET reCode = 1;
			SET reMsg = "找不到订单";
			SELECT reCode, reMsg;
			LEAVE THIS_PROCEDURE;
		end if;
	COMMIT;
	select reCode, reMsg, varPid as "pid", varPayId as "payId", varSelfId as "selfId";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_wifi_pay
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_wifi_pay`;
DELIMITER ;;
CREATE  PROCEDURE `p_wifi_pay`(IN inPid INT, IN inPayId INT, IN inOrderBegin CHAR(32), IN inSelfId INT)
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varId INT;
	DECLARE varNameStr VARCHAR(255);
	DECLARE varPrice INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";
	select price, nameStr into varPrice, varNameStr from d_pay_info where id=inPayId;
	if ISNULL(varPrice) THEN
		SET reCode = 1;
		SET reMsg = "找不到对应套餐";
		SELECT reCode, reMsg;
		LEAVE THIS_PROCEDURE;
	end if;
	START TRANSACTION;
		insert into `s_wifi_pay` (pid, payId, price, orderBegin, opTime, selfId) values (inPid, inPayId, varPrice, inOrderBegin, NOW(), inSelfId);
		set varId := LAST_INSERT_ID();
	COMMIT;
	select reCode, reMsg, varId as "id", varPrice as "price", varNameStr as "nameStr";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_wifi_pay_yq
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_wifi_pay_yq`;
DELIMITER ;;
CREATE  PROCEDURE `p_wifi_pay_yq`(IN inId INT, IN inPrice INT, IN inOrderBegin CHAR(32))
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varPid INT;
	DECLARE varPayId INT;
	DECLARE varServerTp INT;
	DECLARE varPrice INT;
	DECLARE varOrderBegin VARCHAR(255);
	DECLARE varSelfId INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";
	START TRANSACTION;
		select pid, payId, price, orderBegin, serverTp, selfId into varPid, varPayId, varPrice, varOrderBegin, varServerTp, varSelfId from s_wifi_pay where id=inId;
		if ISNULL(varPid) THEN
			SET reCode = 1;
			SET reMsg = "找不到订单";
			SELECT reCode, reMsg;
			LEAVE THIS_PROCEDURE;
		end if;
		if varPrice = inPrice and varOrderBegin = inOrderBegin and varServerTp = 0 THEN
			update s_wifi_pay set serverTp = 1 where id=inId;
		else
			SET reCode = 1;
			SET reMsg = "找不到订单";
			SELECT reCode, reMsg;
			LEAVE THIS_PROCEDURE;
		end if;
	COMMIT;
	select reCode, reMsg, varPid as "pid", varPayId as "payId", varSelfId as "selfId";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_wx_pay
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_wx_pay`;
DELIMITER ;;
CREATE  PROCEDURE `p_wx_pay`(IN inPid INT, IN inPayId INT, IN inOrderBegin CHAR(32), IN inSelfId INT)
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varId INT;
	DECLARE varNameStr VARCHAR(255);
	DECLARE varPrice INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";
	select price, nameStr into varPrice, varNameStr from d_pay_info where id=inPayId;
	if ISNULL(varPrice) THEN
		SET reCode = 1;
		SET reMsg = "找不到对应套餐";
		SELECT reCode, reMsg;
		LEAVE THIS_PROCEDURE;
	end if;
	START TRANSACTION;
		insert into `s_wx_pay` (pid, payId, price, orderBegin, opTime, selfId) values (inPid, inPayId, varPrice, inOrderBegin, NOW(), inSelfId);
		set varId := LAST_INSERT_ID();
	COMMIT;
	select reCode, reMsg, varId as "id", varPrice as "price", varNameStr as "nameStr";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_wx_pay_yq
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_wx_pay_yq`;
DELIMITER ;;
CREATE  PROCEDURE `p_wx_pay_yq`(IN inId INT, IN inPrice INT, IN inOrderBegin CHAR(32))
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varPid INT;
	DECLARE varPayId INT;
	DECLARE varServerTp INT;
	DECLARE varPrice INT;
	DECLARE varOrderBegin VARCHAR(255);
	DECLARE varSelfId INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";
	START TRANSACTION;
		select pid, payId, price, orderBegin, serverTp, selfId into varPid, varPayId, varPrice, varOrderBegin, varServerTp, varSelfId from s_wx_pay where id=inId;
		if ISNULL(varPid) THEN
			SET reCode = 1;
			SET reMsg = "找不到订单";
			SELECT reCode, reMsg;
			LEAVE THIS_PROCEDURE;
		end if;
		if varPrice = inPrice and varOrderBegin = inOrderBegin and varServerTp = 0 THEN
			update s_wx_pay set serverTp = 1 where id=inId;
		else
			SET reCode = 1;
			SET reMsg = "找不到订单";
			SELECT reCode, reMsg;
			LEAVE THIS_PROCEDURE;
		end if;
	COMMIT;
	select reCode, reMsg, varPid as "pid", varPayId as "payId", varSelfId as "selfId";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_yijie_login
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_yijie_login`;
DELIMITER ;;
CREATE  PROCEDURE `p_yijie_login`(IN inAppId CHAR(32),IN inChannelId CHAR(32),IN inUserId CHAR(32),IN inMachineSerial CHAR(32), IN inSelfId INT)
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE retCode INT;
	DECLARE retMsg VARCHAR(255);

	-- 基本信息
	DECLARE varPlatformId INT;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET retCode = -1;
		SET retMsg = "数据库内部错误";
		SELECT retCode, retMsg;
	END;

	-- 查询用户

	START TRANSACTION;
		SELECT `platformId` INTO varPlatformId FROM `yijieinfo` WHERE `appId`=inAppId and `channelId`=inChannelId and `userId`=inUserId;
		IF ISNULL(varPlatformId) THEN
			INSERT INTO `platforminfo` (`account`,`pwd`,`rMachineId`,`rTime`,`rSelfId`,`lMachineId`,`lTime`,`lSelfId`) VALUES ("", "", inMachineSerial, NOW(), inSelfId, inMachineSerial, NOW(), inSelfId);
			SET varPlatformId := LAST_INSERT_ID();
			INSERT INTO `yijieinfo` (`appId`,`channelId`,`userId`,`platformId`) VALUES (inAppId, inChannelId, inUserId, varPlatformId);
		else
			update `platforminfo` set lMachineId=inMachineSerial,lTime=NOW(),lSelfId=inSelfId where id=varPlatformId;
		END IF;
	COMMIT;

	SET retCode := 0;
	SET retMsg := "success";
	-- 输出变量
	SELECT retCode, retMsg, varPlatformId AS "pid";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_yijie_pay
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_yijie_pay`;
DELIMITER ;;
CREATE  PROCEDURE `p_yijie_pay`(IN inTcd CHAR(64), IN inApp CHAR(64), IN inCbi CHAR(64), IN inCt CHAR(32), IN inFee INT, IN inPt CHAR(32), IN inSdk CHAR(32), IN inSsid CHAR(32), IN inSt INT, IN inUid INT, IN inVer CHAR(32))
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varServerTp INT;
	DECLARE varId INT;
	DECLARE varCbi VARCHAR(255);
	DECLARE varFee INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";

	START TRANSACTION;
		select id,serverTp,cbi,fee into varId,varServerTp,varCbi,varFee from `s_yijie_pay` where tcd=inTcd limit 1;
		if ISNULL(varId) then -- 注册
			if inSt = 1 then
				insert into `s_yijie_pay` (tcd,app,cbi,ct,fee,pt,sdk,ssid,st,uid,ver,opTime) values (inTcd,inApp,inCbi,inCt,inFee,inPt,inSdk,inSsid,inSt,inUid,inVer,NOW());
				set varId := LAST_INSERT_ID();
				set varServerTp = 0;
				set varCbi := inCbi;
				set varFee := inFee;
			ELSE
				set reCode = 1;
				set reMsg = "st错误";
			end if;
		end if;
	COMMIT;
	select reCode, reMsg, varId as "id", varServerTp as "serverTp", varCbi as "cbi", varFee as "fee";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_zfb_pay
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_zfb_pay`;
DELIMITER ;;
CREATE  PROCEDURE `p_zfb_pay`(IN inPid INT, IN inPayId INT, IN inOrderBegin CHAR(32), IN inSelfId INT)
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varId INT;
	DECLARE varNameStr VARCHAR(255);
	DECLARE varPrice INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";
	select price, nameStr into varPrice, varNameStr from d_pay_info where id=inPayId;
	if ISNULL(varPrice) THEN
		SET reCode = 1;
		SET reMsg = "找不到对应套餐";
		SELECT reCode, reMsg;
		LEAVE THIS_PROCEDURE;
	end if;
	START TRANSACTION;
		insert into `s_zfb_pay` (pid, payId, price, orderBegin, opTime, selfId) values (inPid, inPayId, varPrice, inOrderBegin, NOW(), inSelfId);
		set varId := LAST_INSERT_ID();
	COMMIT;
	select reCode, reMsg, varId as "id", varPrice as "price", varNameStr as "nameStr";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_zfb_pay_yq
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_zfb_pay_yq`;
DELIMITER ;;
CREATE  PROCEDURE `p_zfb_pay_yq`(IN inId INT, IN inPrice INT, IN inOrderBegin CHAR(32))
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varPid INT;
	DECLARE varPayId INT;
	DECLARE varServerTp INT;
	DECLARE varPrice INT;
	DECLARE varOrderBegin VARCHAR(255);
	DECLARE varSelfId INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";
	START TRANSACTION;
		select pid, payId, price, orderBegin, serverTp, selfId into varPid, varPayId, varPrice, varOrderBegin, varServerTp, varSelfId from s_zfb_pay where id=inId;
		if ISNULL(varPid) THEN
			SET reCode = 1;
			SET reMsg = "找不到订单";
			SELECT reCode, reMsg;
			LEAVE THIS_PROCEDURE;
		end if;
		if varPrice = inPrice and varOrderBegin = inOrderBegin and varServerTp = 0 THEN
			update s_zfb_pay set serverTp = 1 where id=inId;
		else
			SET reCode = 1;
			SET reMsg = "找不到订单";
			SELECT reCode, reMsg;
			LEAVE THIS_PROCEDURE;
		end if;
	COMMIT;
	select reCode, reMsg, varPid as "pid", varPayId as "payId", varSelfId as "selfId";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_zyf_pay
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_zyf_pay`;
DELIMITER ;;
CREATE  PROCEDURE `p_zyf_pay`(IN inPid INT, IN inPayId INT, IN inOrderBegin CHAR(32), IN inSelfId INT)
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varId INT;
	DECLARE varNameStr VARCHAR(255);
	DECLARE varPrice INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";
	select price, nameStr into varPrice, varNameStr from d_pay_info where id=inPayId;
	if ISNULL(varPrice) THEN
		SET reCode = 1;
		SET reMsg = "找不到对应套餐";
		SELECT reCode, reMsg;
		LEAVE THIS_PROCEDURE;
	end if;
	START TRANSACTION;
		insert into `s_zyf_pay` (pid, payId, price, orderBegin, opTime, selfId) values (inPid, inPayId, varPrice, inOrderBegin, NOW(), inSelfId);
		set varId := LAST_INSERT_ID();
	COMMIT;
	select reCode, reMsg, varId as "id", varPrice as "price", varNameStr as "nameStr";
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for p_zyf_pay_yq
-- ----------------------------
DROP PROCEDURE IF EXISTS `p_zyf_pay_yq`;
DELIMITER ;;
CREATE  PROCEDURE `p_zyf_pay_yq`(IN inId INT, IN inPrice INT, IN inOrderBegin CHAR(32))
THIS_PROCEDURE:BEGIN
	-- 存储过程返回
	DECLARE reCode INT;
	DECLARE reMsg VARCHAR(255);

	-- 基本信息
	DECLARE varPid INT;
	DECLARE varPayId INT;
	DECLARE varServerTp INT;
	DECLARE varPrice INT;
	DECLARE varOrderBegin VARCHAR(255);
	DECLARE varSelfId INT;
	

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		ROLLBACK;
		
		SET reCode = -1;
		SET reMsg = "数据库内部错误";
		SELECT reCode, reMsg;
	END;

	set reCode = 0;
	set reMsg = "";
	START TRANSACTION;
		select pid, payId, price, orderBegin, serverTp, selfId into varPid, varPayId, varPrice, varOrderBegin, varServerTp, varSelfId from s_zyf_pay where id=inId;
		if ISNULL(varPid) THEN
			SET reCode = 1;
			SET reMsg = "找不到订单";
			SELECT reCode, reMsg;
			LEAVE THIS_PROCEDURE;
		end if;
		if varPrice = inPrice and varOrderBegin = inOrderBegin and varServerTp = 0 THEN
			update s_zyf_pay set serverTp = 1 where id=inId;
		else
			SET reCode = 1;
			SET reMsg = "找不到订单";
			SELECT reCode, reMsg;
			LEAVE THIS_PROCEDURE;
		end if;
	COMMIT;
	select reCode, reMsg, varPid as "pid", varPayId as "payId", varSelfId as "selfId";
END
;;
DELIMITER ;
