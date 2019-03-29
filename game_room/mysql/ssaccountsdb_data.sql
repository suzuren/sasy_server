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
-- Records of systemstatusinfo
-- ----------------------------
INSERT INTO `systemstatusinfo` VALUES ('BankPrerequisite', '2000', '银行存取条件，存取金币数必须大于此数才可操作！', '存取条件', '键值：表示存取金币数必须大于此数才可存取');
INSERT INTO `systemstatusinfo` VALUES ('EnjoinLogon', '0', '由于系统维护，暂时停止游戏系统的登录服务', '登录服务', '键值：是否禁止登录，1-开启，其他-关闭');
INSERT INTO `systemstatusinfo` VALUES ('RegisterMachineLimit', '5', '小号注册限制', '注册服务', '键值：允许几个相同机器码的帐号领取免费金币，0不限制');
INSERT INTO `systemstatusinfo` VALUES ('RegisterScore', '20000', '新用户注册系统送金币的数目！', '注册服务', '键值：表示赠送的金币数量, 0-不赠送');
INSERT INTO `systemstatusinfo` VALUES ('RevenueRateSave', '20', '银行存款操作税收比率（千分比）！', '存款税率', '键值：表示银行存款操作税收比率值（千分比）！');
INSERT INTO `systemstatusinfo` VALUES ('RevenueRateSaveMember1', '10', 'vip1银行存款操作税收比率（千分比）！', '存款税率', '键值：表示银行存款操作税收比率值（千分比）！');
INSERT INTO `systemstatusinfo` VALUES ('RevenueRateSaveMember2', '5', 'vip2银行存款操作税收比率（千分比）！', '存款税率', '键值：表示银行存款操作税收比率值（千分比）！');
INSERT INTO `systemstatusinfo` VALUES ('RevenueRateSaveMember3', '2', 'vip3银行存款操作税收比率（千分比）！', '存款税率', '键值：表示银行存款操作税收比率值（千分比）！');
INSERT INTO `systemstatusinfo` VALUES ('RevenueRateSaveMember4', '0', 'vip4银行存款操作税收比率（千分比）！', '存款税率', '键值：表示银行存款操作税收比率值（千分比）！');
INSERT INTO `systemstatusinfo` VALUES ('RevenueRateSaveMember5', '0', 'vip5银行存款操作税收比率（千分比）！', '存款税率', '键值：表示银行存款操作税收比率值（千分比）！');
INSERT INTO `systemstatusinfo` VALUES ('RevenueRateTake', '0', '银行取款操作税收比率（千分比）！', '取款税率', '键值：表示银行取款操作税收比率值（千分比）！');
