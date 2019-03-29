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
-- Records of d_pay_info
-- ----------------------------
INSERT INTO `d_pay_info` VALUES ('1', '600', '12万金币');
INSERT INTO `d_pay_info` VALUES ('2', '1200', '12万金币');
INSERT INTO `d_pay_info` VALUES ('3', '5000', '60万金币');
INSERT INTO `d_pay_info` VALUES ('4', '9800', '130万金币');
INSERT INTO `d_pay_info` VALUES ('5', '29800', '350万金币');
INSERT INTO `d_pay_info` VALUES ('6', '48800', '600万金币');
INSERT INTO `d_pay_info` VALUES ('8', '2500', '50万金币');
INSERT INTO `d_pay_info` VALUES ('21', '3000', '月卡礼包(30元)');
INSERT INTO `d_pay_info` VALUES ('22', '1200', '商城充值(12元)');
INSERT INTO `d_pay_info` VALUES ('23', '5000', '商城充值(50元)');
INSERT INTO `d_pay_info` VALUES ('24', '9800', '商城充值(98元)');
INSERT INTO `d_pay_info` VALUES ('25', '29800', '商城充值(298元)');
INSERT INTO `d_pay_info` VALUES ('26', '48800', '商城充值(488元)');
INSERT INTO `d_pay_info` VALUES ('27', '1200', '商城充值(12元)');
INSERT INTO `d_pay_info` VALUES ('28', '5000', '商城充值(50元)');
INSERT INTO `d_pay_info` VALUES ('29', '9800', '商城充值(98元)');
INSERT INTO `d_pay_info` VALUES ('30', '29800', '商城充值(298元)');
INSERT INTO `d_pay_info` VALUES ('31', '48800', '商城充值(488元)');
INSERT INTO `d_pay_info` VALUES ('32', '600', '商城充值(6元)');
INSERT INTO `d_pay_info` VALUES ('34', '600', '首充礼包');
INSERT INTO `d_pay_info` VALUES ('35', '3000', '尊贵礼包');
INSERT INTO `d_pay_info` VALUES ('36', '1200', '12万金币+2万金币');
INSERT INTO `d_pay_info` VALUES ('37', '5000', '60万金币+4万金币');
INSERT INTO `d_pay_info` VALUES ('38', '9800', '130万金币+8万金币 ');
INSERT INTO `d_pay_info` VALUES ('39', '29800', '350万金币+20万金币 ');
INSERT INTO `d_pay_info` VALUES ('40', '48800', '600万金币+40万金币 ');
INSERT INTO `d_pay_info` VALUES ('41', '1200', '120钻石');
INSERT INTO `d_pay_info` VALUES ('42', '5000', '600钻石');
INSERT INTO `d_pay_info` VALUES ('43', '9800', '1300钻石');
INSERT INTO `d_pay_info` VALUES ('44', '29800', '3500钻石');
INSERT INTO `d_pay_info` VALUES ('45', '48800', '6000钻石');
INSERT INTO `d_pay_info` VALUES ('46', '10800', '商城充值(108元)');
INSERT INTO `d_pay_info` VALUES ('47', '100', '1元新手礼包尊享10倍礼遇');
INSERT INTO `d_pay_info` VALUES ('48', '100000', '商城充值(1000元)');
INSERT INTO `d_pay_info` VALUES ('49', '5000', '商城充值(50元)');
INSERT INTO `d_pay_info` VALUES ('50', '10000', '商城充值(100元)');
INSERT INTO `d_pay_info` VALUES ('51', '30000', '商城充值(300元)');
INSERT INTO `d_pay_info` VALUES ('52', '50000', '商城充值(500元)');
INSERT INTO `d_pay_info` VALUES ('53', '10000', '商城充值(100元)');
INSERT INTO `d_pay_info` VALUES ('54', '50000', '商城充值(500元)');
INSERT INTO `d_pay_info` VALUES ('55', '10000', '100元炮台升级礼包');
INSERT INTO `d_pay_info` VALUES ('56', '50000', '500元炮台进阶礼包');
INSERT INTO `d_pay_info` VALUES ('57', '50000', '500元特殊炮台寒冰礼包');
INSERT INTO `d_pay_info` VALUES ('58', '50000', '500元特殊炮台火焰礼包');
