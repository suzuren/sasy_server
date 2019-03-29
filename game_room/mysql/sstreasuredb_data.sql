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
-- Records of gameproperty
-- ----------------------------
INSERT INTO `gameproperty` VALUES ('1', '汽车', '1500', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('2', '臭蛋', '100', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('3', '鼓掌', '300', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('4', '香吻', '200', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('5', '啤酒', '500', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('6', '蛋糕', '800', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('7', '钻戒', '1000', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('8', '暴打', '500', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('9', '炸弹', '1000', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('10', '香烟', '500', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('11', '别墅', '2000', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('12', '砖头', '300', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('13', '鲜花', '300', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('14', '双倍积分卡', '10000', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('15', '四倍积分卡', '20000', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('16', '负分清零卡', '20000', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('17', '清逃跑率卡', '10000', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('18', '小喇叭', '10000', '90', '7', '7', '0', '0', '', '0');
INSERT INTO `gameproperty` VALUES ('19', '大喇叭', '50000', '90', '7', '7', '0', '0', '', '0');
INSERT INTO `gameproperty` VALUES ('20', '防踢卡', '10000', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('21', '护身符', '10000', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('22', '蓝钻会员卡', '100000', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('23', '蓝钻会员卡', '300000', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('24', '白钻会员卡', '600000', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('25', '红钻会员卡', '1200000', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('26', 'VIP房卡', '1000000', '90', '7', '7', '0', '0', '', '1');
INSERT INTO `gameproperty` VALUES ('100', '鸡蛋', '500', '90', '7', '7', '0', '-1', '', '1');
INSERT INTO `gameproperty` VALUES ('101', '香蕉皮', '500', '90', '7', '7', '0', '-1', '', '1');
INSERT INTO `gameproperty` VALUES ('102', '西红柿', '500', '90', '7', '7', '0', '-1', '', '1');
INSERT INTO `gameproperty` VALUES ('103', '飞刀', '5000', '90', '7', '7', '0', '-10', '', '1');
INSERT INTO `gameproperty` VALUES ('104', '炸弹', '50000', '90', '7', '7', '0', '-100', '', '1');
INSERT INTO `gameproperty` VALUES ('105', '帽子', '500', '90', '7', '7', '0', '1', '', '1');
INSERT INTO `gameproperty` VALUES ('106', '玫瑰', '500', '90', '7', '7', '0', '1', '', '1');
INSERT INTO `gameproperty` VALUES ('107', '红唇', '500', '90', '7', '7', '0', '1', '', '1');
INSERT INTO `gameproperty` VALUES ('108', '啤酒', '5000', '90', '7', '7', '0', '10', '', '1');
INSERT INTO `gameproperty` VALUES ('109', '香槟', '5000', '90', '7', '7', '0', '10', '', '1');
INSERT INTO `gameproperty` VALUES ('110', '名表', '5000', '90', '7', '7', '0', '10', '', '1');
INSERT INTO `gameproperty` VALUES ('200', '水晶鞋', '100', '100', '7', '7', '0', '10', '', '1');
INSERT INTO `gameproperty` VALUES ('201', '戒指', '200', '100', '7', '7', '0', '20', '', '1');
INSERT INTO `gameproperty` VALUES ('202', '钻戒', '200', '100', '7', '7', '0', '20', '', '1');
INSERT INTO `gameproperty` VALUES ('203', '摇钱树', '500', '100', '7', '7', '0', '50', '', '1');
INSERT INTO `gameproperty` VALUES ('204', '摩托', '1000', '100', '7', '7', '0', '100', '', '1');
INSERT INTO `gameproperty` VALUES ('205', '汽车', '50000', '100', '7', '7', '0', '100', '', '1');
INSERT INTO `gameproperty` VALUES ('206', '飞机', '5000', '100', '7', '7', '0', '500', '', '1');
INSERT INTO `gameproperty` VALUES ('207', '游轮', '10000', '100', '7', '7', '0', '1000', '', '1');
INSERT INTO `gameproperty` VALUES ('208', '玫瑰', '1000', '90', '7', '7', '0', '1', '', '0');
INSERT INTO `gameproperty` VALUES ('209', '金砖', '10000', '90', '7', '7', '0', '10', ' ', '0');
INSERT INTO `gameproperty` VALUES ('210', '跑车', '100000', '90', '7', '7', '0', '100', ' ', '0');
INSERT INTO `gameproperty` VALUES ('211', '别墅', '1000000', '90', '7', '7', '0', '1000', ' ', '0');

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
-- Records of payorderitem
-- ----------------------------
INSERT INTO `payorderitem` VALUES ('1', '6.00', '60000', '0', '1', '0', '0', '0', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '1', '1', '苹果审核12万金币');
INSERT INTO `payorderitem` VALUES ('2', '12.00', '120000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '1', '1', '苹果审核12万金币');
INSERT INTO `payorderitem` VALUES ('3', '50.00', '600000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '2', '2', '苹果审核60万金币');
INSERT INTO `payorderitem` VALUES ('4', '98.00', '1300000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '3', '2', '苹果审核130万金币');
INSERT INTO `payorderitem` VALUES ('5', '298.00', '3500000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '4', '2', '苹果审核350万金币');
INSERT INTO `payorderitem` VALUES ('6', '488.00', '6000000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '5', '2', '苹果审核600万金币');
INSERT INTO `payorderitem` VALUES ('8', '25.00', '250000', '0', '1', '1', '0', '1', '1', '2014-11-11 19:00:00', '2024-11-11 22:00:00', '2', '2', '苹果审核50万金币');
INSERT INTO `payorderitem` VALUES ('21', '30.00', '100000', '0', '1', '25', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '月卡礼包(30元)');
INSERT INTO `payorderitem` VALUES ('22', '12.00', '0', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(12元)');
INSERT INTO `payorderitem` VALUES ('23', '50.00', '0', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(50元)');
INSERT INTO `payorderitem` VALUES ('24', '98.00', '0', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(98元)');
INSERT INTO `payorderitem` VALUES ('25', '298.00', '0', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(298元)');
INSERT INTO `payorderitem` VALUES ('26', '488.00', '0', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(488元)');
INSERT INTO `payorderitem` VALUES ('27', '12.00', '120000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(12元)');
INSERT INTO `payorderitem` VALUES ('28', '50.00', '600000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(50元)');
INSERT INTO `payorderitem` VALUES ('29', '98.00', '1300000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(98元)');
INSERT INTO `payorderitem` VALUES ('30', '298.00', '3500000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(298元)');
INSERT INTO `payorderitem` VALUES ('31', '488.00', '6000000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(488元)');
INSERT INTO `payorderitem` VALUES ('32', '6.00', '60000', '0', '1', '0', '0', '0', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(6元)');
INSERT INTO `payorderitem` VALUES ('34', '6.00', '60000', '0', '1', '0', '0', '0', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '首充礼包');
INSERT INTO `payorderitem` VALUES ('35', '30.00', '100000', '0', '1', '25', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '尊贵礼包');
INSERT INTO `payorderitem` VALUES ('36', '12.00', '120000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '12万金币+2万金币');
INSERT INTO `payorderitem` VALUES ('37', '50.00', '600000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '60万金币+4万金币');
INSERT INTO `payorderitem` VALUES ('38', '98.00', '1300000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '130万金币+8万金币 ');
INSERT INTO `payorderitem` VALUES ('39', '298.00', '3500000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '350万金币+20万金币 ');
INSERT INTO `payorderitem` VALUES ('40', '488.00', '6000000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '600万金币+40万金币 ');
INSERT INTO `payorderitem` VALUES ('41', '12.00', '0', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '120钻石');
INSERT INTO `payorderitem` VALUES ('42', '50.00', '0', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '600钻石');
INSERT INTO `payorderitem` VALUES ('43', '98.00', '0', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '1300钻石');
INSERT INTO `payorderitem` VALUES ('44', '298.00', '0', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '3500钻石');
INSERT INTO `payorderitem` VALUES ('45', '488.00', '0', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '6000钻石');
INSERT INTO `payorderitem` VALUES ('46', '108.00', '1300000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(108元)');
INSERT INTO `payorderitem` VALUES ('47', '1.00', '10000', '0', '1', '0', '0', '0', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '1', '1', '1元新手礼包尊享10倍礼遇');
INSERT INTO `payorderitem` VALUES ('48', '1000.00', '10000000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(1000元)');
INSERT INTO `payorderitem` VALUES ('49', '50.00', '500000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(50元)');
INSERT INTO `payorderitem` VALUES ('50', '100.00', '1000000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(100元)');
INSERT INTO `payorderitem` VALUES ('51', '300.00', '3000000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(300元)');
INSERT INTO `payorderitem` VALUES ('52', '500.00', '5000000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(500元)');
INSERT INTO `payorderitem` VALUES ('53', '100.00', '2000000', '0', '1', '1', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(100元)');
INSERT INTO `payorderitem` VALUES ('54', '500.00', '10000000', '0', '1', '1', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '商城充值(500元)');
INSERT INTO `payorderitem` VALUES ('55', '100.00', '2200000', '0', '1', '0', '0', '0', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '1', '1', '100元炮台升级礼包');
INSERT INTO `payorderitem` VALUES ('56', '500.00', '11000000', '0', '1', '0', '0', '0', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '1', '1', '500元炮台进阶礼包');
INSERT INTO `payorderitem` VALUES ('57', '500.00', '10000000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '500元特殊炮台寒冰礼包');
INSERT INTO `payorderitem` VALUES ('58', '500.00', '10000000', '0', '-1', '0', '0', '1', '1', '2014-11-11 00:00:00', '2024-11-11 00:00:00', '0', '0', '500元特殊炮台火焰礼包');

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
-- Records of payorderitem_ex
-- ----------------------------
INSERT INTO `payorderitem_ex` VALUES ('1', '1002:50|1014:1|1004:10|1005:10|1001:60000');
INSERT INTO `payorderitem_ex` VALUES ('2', '1001:20000');
INSERT INTO `payorderitem_ex` VALUES ('3', '1001:40000');
INSERT INTO `payorderitem_ex` VALUES ('4', '1001:80000');
INSERT INTO `payorderitem_ex` VALUES ('5', '1001:200000');
INSERT INTO `payorderitem_ex` VALUES ('6', '1001:400000');
INSERT INTO `payorderitem_ex` VALUES ('8', '1002:50|1003:50|1001:250000');
INSERT INTO `payorderitem_ex` VALUES ('21', '1002:10|1004:5');
INSERT INTO `payorderitem_ex` VALUES ('22', '1002:120');
INSERT INTO `payorderitem_ex` VALUES ('23', '1002:600');
INSERT INTO `payorderitem_ex` VALUES ('24', '1002:1300');
INSERT INTO `payorderitem_ex` VALUES ('25', '1002:3500');
INSERT INTO `payorderitem_ex` VALUES ('26', '1002:6000');
INSERT INTO `payorderitem_ex` VALUES ('27', '1001:20000');
INSERT INTO `payorderitem_ex` VALUES ('28', '1001:40000');
INSERT INTO `payorderitem_ex` VALUES ('29', '1001:80000');
INSERT INTO `payorderitem_ex` VALUES ('30', '1001:200000');
INSERT INTO `payorderitem_ex` VALUES ('31', '1001:400000');
INSERT INTO `payorderitem_ex` VALUES ('32', '1002:50|1014:1|1004:10|1005:10|1001:60000');
INSERT INTO `payorderitem_ex` VALUES ('34', '1002:50|1014:1|1001:60000');
INSERT INTO `payorderitem_ex` VALUES ('35', '1002:10|1004:5');
INSERT INTO `payorderitem_ex` VALUES ('36', '1001:20000');
INSERT INTO `payorderitem_ex` VALUES ('37', '1001:40000');
INSERT INTO `payorderitem_ex` VALUES ('38', '1001:80000');
INSERT INTO `payorderitem_ex` VALUES ('39', '1001:200000');
INSERT INTO `payorderitem_ex` VALUES ('40', '1001:400000');
INSERT INTO `payorderitem_ex` VALUES ('41', '1002:120');
INSERT INTO `payorderitem_ex` VALUES ('42', '1002:600');
INSERT INTO `payorderitem_ex` VALUES ('43', '1002:1300');
INSERT INTO `payorderitem_ex` VALUES ('44', '1002:3500');
INSERT INTO `payorderitem_ex` VALUES ('45', '1002:6000');
INSERT INTO `payorderitem_ex` VALUES ('46', '1001:80000');
INSERT INTO `payorderitem_ex` VALUES ('47', '1002:50|1001:40000');
INSERT INTO `payorderitem_ex` VALUES ('48', '1001:7000000');
INSERT INTO `payorderitem_ex` VALUES ('49', '1001:150000');
INSERT INTO `payorderitem_ex` VALUES ('50', '1001:400000');
INSERT INTO `payorderitem_ex` VALUES ('51', '1001:1500000');
INSERT INTO `payorderitem_ex` VALUES ('52', '1001:3000000');
INSERT INTO `payorderitem_ex` VALUES ('53', '1002:100|1020:5');
INSERT INTO `payorderitem_ex` VALUES ('54', '1002:300|1021:5');
INSERT INTO `payorderitem_ex` VALUES ('55', '1002:300');
INSERT INTO `payorderitem_ex` VALUES ('56', '1002:700');
INSERT INTO `payorderitem_ex` VALUES ('57', '1027:1');
INSERT INTO `payorderitem_ex` VALUES ('58', '1028:1');

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
-- Records of t_fish_config
-- ----------------------------
INSERT INTO `t_fish_config` VALUES ('0', 'fish1', '0.4900000000', '0');
INSERT INTO `t_fish_config` VALUES ('1', 'fish2', '0.4900000000', '0');
INSERT INTO `t_fish_config` VALUES ('2', 'fish3', '0.3266666670', '0');
INSERT INTO `t_fish_config` VALUES ('3', 'fish4', '0.2450000000', '0');
INSERT INTO `t_fish_config` VALUES ('4', 'fish5', '0.1960000000', '0');
INSERT INTO `t_fish_config` VALUES ('5', 'fish6', '0.1633333330', '0');
INSERT INTO `t_fish_config` VALUES ('6', 'fish7', '0.1400000000', '0');
INSERT INTO `t_fish_config` VALUES ('7', 'fish8', '0.1225000000', '0');
INSERT INTO `t_fish_config` VALUES ('8', 'fish9', '0.1088888890', '0');
INSERT INTO `t_fish_config` VALUES ('9', 'fish10', '0.0980000000', '0');
INSERT INTO `t_fish_config` VALUES ('10', 'fish11', '0.0816666670', '0');
INSERT INTO `t_fish_config` VALUES ('11', 'fish12', '0.0653333330', '0');
INSERT INTO `t_fish_config` VALUES ('12', 'fish13', '0.0490000000', '0');
INSERT INTO `t_fish_config` VALUES ('13', 'fish14', '0.0392000000', '0');
INSERT INTO `t_fish_config` VALUES ('14', '蝙蝠鱼', '0.0326666670', '0');
INSERT INTO `t_fish_config` VALUES ('15', '银鲨', '0.0280000000', '0');
INSERT INTO `t_fish_config` VALUES ('16', '金鲨', '0.0098000000', '1');
INSERT INTO `t_fish_config` VALUES ('17', '美人鱼', '0.0122500000', '0');
INSERT INTO `t_fish_config` VALUES ('18', '金蝙蝠鱼', '0.0046666670', '1');
INSERT INTO `t_fish_config` VALUES ('19', '机械鱼', '0.0030625000', '1');
INSERT INTO `t_fish_config` VALUES ('20', '金猪', '0.0024378110', '1');
INSERT INTO `t_fish_config` VALUES ('21', '电鳗', '0.0066666700', '0');
INSERT INTO `t_fish_config` VALUES ('22', '全屏炸弹', '0.0010000000', '0');
INSERT INTO `t_fish_config` VALUES ('23', '定屏炸弹', '0.0495000000', '0');
INSERT INTO `t_fish_config` VALUES ('24', '小话费', '0.0000000000', '0');
INSERT INTO `t_fish_config` VALUES ('25', '大话费', '0.0000000000', '0');
INSERT INTO `t_fish_config` VALUES ('26', '小金龙', '0.0049000000', '1');
INSERT INTO `t_fish_config` VALUES ('27', '骨龙', '0.0019600000', '1');
INSERT INTO `t_fish_config` VALUES ('28', '机械虾', '0.0016333330', '1');
INSERT INTO `t_fish_config` VALUES ('29', '波塞冬', '0.0001000000', '0');
INSERT INTO `t_fish_config` VALUES ('30', '凤凰', '0.0016670000', '0');
INSERT INTO `t_fish_config` VALUES ('31', '南瓜鱼1', '0.0653333300', '0');
INSERT INTO `t_fish_config` VALUES ('32', '南瓜鱼2', '0.0049000000', '0');
INSERT INTO `t_fish_config` VALUES ('33', '波塞冬的宝藏', '0.0001000000', '0');
INSERT INTO `t_fish_config` VALUES ('99', '扑克10', '0.1000000000', '0');
INSERT INTO `t_fish_config` VALUES ('100', '扑克J', '0.1000000000', '0');
INSERT INTO `t_fish_config` VALUES ('101', '扑克Q', '0.1000000000', '0');
INSERT INTO `t_fish_config` VALUES ('102', '扑克K', '0.1000000000', '0');
INSERT INTO `t_fish_config` VALUES ('103', '扑克A', '0.1000000000', '0');

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
-- Records of t_frist_charge_reward
-- ----------------------------
INSERT INTO `t_frist_charge_reward` VALUES ('1', '1', '5', '1:1012:1:1:20|2:1013:1:21:40|3:1005:5:41:80|4:1001:50000:81:90|5:1001:80000:91:95|6:1006:1:96:99|7:1007:1:100:100|8:1008:1:101:101');
INSERT INTO `t_frist_charge_reward` VALUES ('2', '6', '49', '1:1012:1:1:10|2:1013:1:11:20|3:1005:5:21:40|4:1001:50000:41:80|5:1001:80000:81:92|6:1006:1:93:95|7:1007:1:96:98|8:1008:1:99:100');
INSERT INTO `t_frist_charge_reward` VALUES ('3', '50', '107', '1:1012:1:0:0|2:1013:1:0:0|3:1005:5:0:0|4:1001:50000:1:30|5:1001:80000:31:80|6:1006:1:81:100|7:1007:1:101:101|8:1008:1:101:101');
INSERT INTO `t_frist_charge_reward` VALUES ('4', '108', '297', '1:1012:1:0:0|2:1013:1:0:0|3:1005:5:0:0|4:1001:50000:0:0|5:1001:80000:1:30|6:1006:1:31:80|7:1007:1:81:95|8:1008:1:96:100');
INSERT INTO `t_frist_charge_reward` VALUES ('5', '298', '487', '1:1012:1:0:0|2:1013:1:0:0|3:1005:5:0:0|4:1001:50000:0:0|5:1001:80000:0:0|6:1006:1:1:40|7:1007:1:41:90|8:1008:1:91:100');
INSERT INTO `t_frist_charge_reward` VALUES ('6', '488', '488', '1:1012:1:0:0|2:1013:1:0:0|3:1005:5:0:0|4:1001:50000:0:0|5:1001:80000:0:0|6:1006:1:1:30|7:1007:1:31:80|8:1008:1:81:100');

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
-- Records of t_huo_dong_reward_config
-- ----------------------------
INSERT INTO `t_huo_dong_reward_config` VALUES ('1', '1', '1', '国庆集字', '0', '3', '-1', '1201:1|1202:1|1203:1|1204:1', '1206:1', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('1', '1', '2', '国庆集字', '0', '3', '-1', '1201:1|1202:1|1203:1|1204:1|1205:1', '1207:1', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('6', '4', '1', '国庆活动期间累计充值', '0', '-1', '-1', '1208:50', '1001:80000', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('6', '4', '2', '国庆活动期间累计充值', '0', '-1', '-1', '1208:98', '1001:150000', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('6', '4', '3', '国庆活动期间累计充值', '0', '-1', '-1', '1208:298', '1001:500000|1002:20', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('6', '4', '4', '国庆活动期间累计充值', '0', '-1', '-1', '1208:488', '1001:800000|1002:30', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('6', '4', '5', '国庆活动期间累计充值', '0', '-1', '-1', '1208:1888', '1001:3000000|1002:80', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('6', '4', '6', '国庆活动期间累计充值', '0', '-1', '-1', '1208:3888', '1001:6000000|1002:100', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('6', '4', '7', '国庆活动期间累计充值', '0', '-1', '-1', '1208:6888', '1001:10000000|1002:150', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('6', '4', '8', '国庆活动期间累计充值', '0', '-1', '-1', '1208:10888', '1001:16000000|1002:230', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('6', '4', '9', '国庆活动期间累计充值', '0', '-1', '-1', '1208:18888', '1001:28000000|1002:400', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('2', '2', '1', '单笔充值活动', '0', '-1', '-1', '1208:12', '1001:15000', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('2', '2', '2', '单笔充值活动', '0', '-1', '-1', '1208:50', '1001:55000', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('2', '2', '3', '单笔充值活动', '0', '-1', '-1', '1208:298', '1001:600000', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('2', '2', '4', '单笔充值活动', '0', '-1', '-1', '1208:488', '1001:1200000', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('3', '5', '1', '版本更新介绍', '0', '-1', '-1', '0', '0', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('4', '3', '1', '日累计充值活动', '0', '-1', '-1', '1208:60', '1001:72000', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('4', '3', '2', '日累计充值活动', '0', '-1', '-1', '1208:100', '1001:120000', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('4', '3', '3', '日累计充值活动', '0', '-1', '-1', '1208:300', '1001:368000', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('4', '3', '4', '日累计充值活动', '0', '-1', '-1', '1208:800', '1001:1000000', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('4', '3', '5', '日累计充值活动', '0', '-1', '-1', '1208:1300', '1001:1690000', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('4', '3', '6', '日累计充值活动', '0', '-1', '-1', '1208:2500', '1001:3750000', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('5', '1', '1', '万圣节集字', '0', '3', '-1', '1211:1|1212:1|1213:1|1214:1', '1216:1', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('5', '1', '2', '万圣节集字', '0', '3', '-1', '1211:1|1212:1|1213:1|1214:1|1215:1', '1217:1', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('7', '6', '1', '世界BOSS', '0', '-1', '-1', '0', '0', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('8', '7', '1', '首冲翻倍活动', '0', '-1', '-1', '0', '0', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('9', '8', '1', '捕鱼狂欢节', '0', '-1', '-1', '0', '0', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('10', '9', '1', '定时BOSS', '0', '-1', '-1', '0', '0', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('11', '1', '1', '圣诞集字', '0', '3', '-1', '1221:1|1222:1|1223:1|1224:1', '1226:1', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('11', '1', '2', '圣诞集字', '0', '3', '-1', '1221:1|1222:1|1223:1|1224:1|1225:1', '1227:1', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('12', '11', '1', 'BOSS来袭', '0', '-1', '-1', '0', '0', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('13', '12', '1', '登录有礼', '0', '1', '-1', '0', '0', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('13', '12', '2', '登录有礼', '0', '1', '-1', '0', '0', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('14', '13', '1', '充值乐翻天', '0', '1', '-1', '1208:50', '0', '1.1000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('14', '13', '2', '充值乐翻天', '0', '1', '-1', '1208:200', '0', '1.2000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('14', '13', '3', '充值乐翻天', '0', '1', '-1', '1208:400', '0', '1.3000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('14', '13', '4', '充值乐翻天', '0', '1', '-1', '1208:1000', '0', '1.4000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('14', '13', '5', '充值乐翻天', '0', '1', '-1', '1208:2000', '0', '1.5000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('15', '14', '1', '首充福利', '0', '1', '-1', '0', '1012:1', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('15', '14', '2', '首充福利', '0', '1', '-1', '0', '1013:1', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('15', '14', '3', '首充福利', '0', '1', '-1', '0', '1005:5', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('15', '14', '4', '首充福利', '0', '1', '-1', '0', '1001:50000', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('15', '14', '5', '首充福利', '0', '1', '-1', '0', '1001:80000', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('15', '14', '6', '首充福利', '0', '1', '-1', '0', '1006:1', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('15', '14', '7', '首充福利', '0', '1', '-1', '0', '1007:1', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('15', '14', '8', '首充福利', '0', '1', '-1', '0', '1008:1', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('16', '15', '1', '天降红包雨', '0', '-1', '-1', '0', '0', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('17', '1', '1', '情人节集字', '0', '3', '-1', '1228:1|1229:1|1230:1|1231:1', '1233:1', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('17', '1', '2', '情人节集字', '0', '3', '-1', '1228:1|1229:1|1230:1|1231:1|1232:1', '1234:1', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('18', '16', '1', '神秘炮台', '0', '-1', '-1', '0', '0', '0.0000000000');
INSERT INTO `t_huo_dong_reward_config` VALUES ('19', '17', '1', '超值礼包', '0', '-1', '-1', '0', '0', '0.0000000000');

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
-- Records of t_huo_dong_time_config
-- ----------------------------
INSERT INTO `t_huo_dong_time_config` VALUES ('1', '规则: 喜迎国庆，捕鱼狂欢，集字赢壕礼', '1', '2016-10-14 10:00:00', '2016-10-17 00:00:00', 'Gqj1', 'Gqj', 'Qby', '1');
INSERT INTO `t_huo_dong_time_config` VALUES ('2', '规则: 单笔充值特定金额，赢取相应丰厚大奖\n提示：可重复充值领取', '2', '2016-11-26 00:00:00', '2016-12-02 00:00:00', 'Dbcz', 'Cz', 'Qcz', '2');
INSERT INTO `t_huo_dong_time_config` VALUES ('3', '版本更新介绍', '3', '2016-10-14 10:00:00', '2016-10-17 00:00:00', 'Bz1', 'Bz', 'Qby', '3');
INSERT INTO `t_huo_dong_time_config` VALUES ('4', '日累计充值活动', '4', '2017-03-30 00:00:00', '2017-05-01 00:00:00', 'Rljcz', 'Cz', 'Qcz', '2');
INSERT INTO `t_huo_dong_time_config` VALUES ('5', '邪恶南瓜来袭，惊魂万圣节，集字迎好礼', '5', '2016-10-28 10:30:00', '2016-11-04 00:00:00', 'Wsj1', 'Wsj', 'Qby', '1');
INSERT INTO `t_huo_dong_time_config` VALUES ('6', '规则: 活动期间累计充值达到特定金额,赢取相应大奖', '6', '2017-01-16 16:30:00', '2017-01-20 00:00:00', 'Ljcz', 'Cz', 'Qcz', '2');
INSERT INTO `t_huo_dong_time_config` VALUES ('7', '世界BOSS', '7', '2016-10-14 10:00:00', '2017-10-17 00:00:00', 'Boss1', 'Boss', 'Qw', '3');
INSERT INTO `t_huo_dong_time_config` VALUES ('8', '规则：每天的第一次充值双倍回馈', '8', '2017-02-06 00:00:00', '2017-02-13 00:00:00', 'Mrsc1', 'Mrsc', 'Ycz', '3');
INSERT INTO `t_huo_dong_time_config` VALUES ('9', '捕鱼狂欢节，暴击双倍奖励', '9', '2016-11-04 14:00:00', '2016-11-13 00:00:00', 'Bjy1', 'Bjy', 'Qby', '3');
INSERT INTO `t_huo_dong_time_config` VALUES ('10', '定时BOSS', '10', '2016-10-14 10:00:00', '2017-10-17 00:00:00', 'Bsd1', 'Bsd', 'Qw', '3');
INSERT INTO `t_huo_dong_time_config` VALUES ('11', '欢度圣诞节，集字迎豪礼', '11', '2016-12-23 00:00:00', '2017-01-03 00:00:00', 'Sdj1', 'Sdj', 'Qby', '1');
INSERT INTO `t_huo_dong_time_config` VALUES ('12', '额外宝藏', '12', '2016-12-23 00:00:00', '2017-01-03 00:00:00', 'Yd1', 'Yd', 'Qby', '3');
INSERT INTO `t_huo_dong_time_config` VALUES ('13', '每天12：00-14：00，19：00-21：00，登录即可领好礼', '13', '2017-08-09 00:00:00', '2018-08-16 00:00:00', 'Dlyl1', 'Dlyl', 'Lq', '3');
INSERT INTO `t_huo_dong_time_config` VALUES ('14', '1. 累计充值到指定档可获得累计倍率的奖励,基础部分直接到帐,额外部分累计到红包内。（累计充值每日重置）\n2. 每日额外累计部分次日拆红包领取,忘记领取金币的用户系统将会通过邮件发送给用户。', '14', '2017-01-20 00:00:00', '2017-02-05 00:00:00', 'Lft', 'Cjd', 'Qcz', '3');
INSERT INTO `t_huo_dong_time_config` VALUES ('15', '每日首充的玩家可进行一次抽奖,首充金额越高抽中的物品越好哦！', '15', '2017-01-20 00:00:00', '2017-02-05 00:00:00', 'Scfl', 'Cjd', null, '3');
INSERT INTO `t_huo_dong_time_config` VALUES ('16', '活动期间,每15分钟左右会刷新一波红包鱼阵,捕中除了可以获得基础倍率金币奖励外,还有几率获得神秘道具和巨额金币奖励', '16', '2017-01-20 00:00:00', '2017-02-05 00:00:00', 'Tjhby', 'Cjd', 'Qby', '3');
INSERT INTO `t_huo_dong_time_config` VALUES ('17', '浪漫情人节，集字迎豪礼', '17', '2017-02-13 16:00:00', '2017-02-21 00:00:00', 'Qrj1', 'Qrj', null, '1');
INSERT INTO `t_huo_dong_time_config` VALUES ('18', '神秘炮台', '18', '2017-03-28 00:00:00', '2017-05-01 00:00:00', 'Smpt1', 'Smpt', 'Ckxq', '3');
INSERT INTO `t_huo_dong_time_config` VALUES ('19', '超值礼包', '19', '2017-03-28 00:00:00', '2017-05-01 00:00:00', 'Czlb1', 'Czlb', 'Ckxq', '3');

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
-- Records of t_item_compose
-- ----------------------------
INSERT INTO `t_item_compose` VALUES ('1009', '1012:1|1006:1|1002:5\n', '1');
INSERT INTO `t_item_compose` VALUES ('1010', '1012:1|1013:1|1007:1|1002:5', '1');
INSERT INTO `t_item_compose` VALUES ('1011', '1012:1|1013:1|1008:1|1002:10', '1');
INSERT INTO `t_item_compose` VALUES ('1022', '1020:1|1001:2000000|1002:20', '1');
INSERT INTO `t_item_compose` VALUES ('1023', '1021:1|1001:10000000|1002:100', '1');
INSERT INTO `t_item_compose` VALUES ('1030', '1029:10', '1');

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
-- Records of t_item_table_info
-- ----------------------------
INSERT INTO `t_item_table_info` VALUES ('1001', '金币', '金币', '1001', '1', '-1', '0', '0', '0', '0', '0', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1002', '钻石', '钻石', '1002', '1', '-1', '0', '0', '0', '0', '0', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1003', '话费兑换券', '可以兑换实物的话费兑换券', '1003', '1', '-1', '0', '0', '0', '0', '0', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1004', '锁定', '可以一段时间内锁定大鱼', '1004', '1', '999', '0', '0', '0', '0', '0', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1005', '狂暴', '可以一段时间内开启狂暴状态', '1005', '1', '999', '0', '0', '0', '0', '0', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1006', '银色钥匙', '可以合成价值20元的白银宝箱', '1006', '1', '-1', '0', '0', '0', '0', '1', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1007', '金色钥匙', '可以合成价值50元的黄金宝箱', '1007', '1', '-1', '0', '0', '0', '0', '1', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1008', '月牙钥匙', '可以合成价值100元的铂金宝箱', '1008', '1', '-1', '0', '0', '0', '0', '1', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1009', '银宝箱', '价值20元\n使用获得20W金币\n*装备可获得白银宝箱专属炮台*略微提高命中率', '1009', '1', '-1', '0', '0', '1', '1', '1', '1', '1014');
INSERT INTO `t_item_table_info` VALUES ('1010', '金宝箱', '价值50元\n使用获得50W金币\n*装备可获得黄金宝箱专属炮台略*微提高命中率', '1010', '1', '-1', '0', '0', '1', '1', '1', '2', '1015');
INSERT INTO `t_item_table_info` VALUES ('1011', '铂金宝箱', '价值100元\n使用获得100W金币*\n装备可获得铂金宝箱专属炮台*略微提高命中率', '1011', '1', '-1', '0', '0', '1', '1', '1', '3', '1016');
INSERT INTO `t_item_table_info` VALUES ('1012', '藏宝图上', '各区域奖金鱼都可以掉落 可以用来合成宝箱', '1012', '1', '-1', '0', '0', '0', '1', '1', '4', '0');
INSERT INTO `t_item_table_info` VALUES ('1013', '藏宝图下', '深海宝藏以上区域奖金鱼可以掉落 可以用来合成高级宝箱', '1013', '1', '-1', '0', '0', '0', '1', '1', '5', '0');
INSERT INTO `t_item_table_info` VALUES ('1014', '白银宝箱专属炮台', '限时使用3天 略微提高命中率', '1014', '1', '-1', '0', '0', '0', '0', '0', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1015', '黄金宝箱专属炮台', '限时使用3天 略微提高命中率', '1015', '1', '-1', '0', '0', '0', '0', '0', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1016', '铂金宝箱专属炮台', '限时使用3天 略微提高命中率', '1016', '1', '-1', '0', '0', '0', '0', '0', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1017', '遗失的袋子', '不小心的旅人遗失的袋子，装有未知金币。', '1017', '1', '-1', '0', '0', '0', '0', '0', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1018', '装满金币的宝箱', '藏在深海的某个角落。', '1018', '1', '-1', '0', '0', '0', '0', '0', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1019', '船长的宝藏', '船长毕生的财富。', '1019', '1', '-1', '0', '0', '0', '0', '0', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1020', '钻石合成卡', '可以合成钻石宝箱', '1020', '1', '-1', '0', '0', '0', '0', '1', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1021', '至尊合成卡', '可以合成至尊宝箱', '1021', '1', '-1', '0', '0', '0', '0', '1', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1022', '钻石宝箱', '打开可获得200W金币', '1022', '1', '-1', '0', '0', '1', '1', '1', '20', '0');
INSERT INTO `t_item_table_info` VALUES ('1023', '至尊宝箱', '打开可获得1000W金币', '1023', '1', '-1', '0', '0', '1', '1', '1', '21', '0');
INSERT INTO `t_item_table_info` VALUES ('1027', '冰晶凤羽', '子弹有一定几率冻结鱼类', '1027', '1', '-1', '0', '0', '0', '0', '0', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1028', '烈焰龙魂', '能够汲取被杀死鱼类的灵魂凝结为特殊晶体的神秘炮台', '1028', '1', '-1', '0', '0', '0', '0', '0', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1029', '火焰微粒', '里面仿佛囚禁着什么。可以用来合成火焰结晶', '1029', '1', '-1', '0', '0', '0', '0', '1', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1030', '火焰结晶', '珍贵的水晶，出售可以获得100W金币', '1030', '1', '-1', '0', '0', '0', '1', '0', '36', '0');
INSERT INTO `t_item_table_info` VALUES ('1031', '急速', '可以在一段时间内开启急速射击状态', '1031', '1', '999', '0', '0', '0', '0', '0', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1201', '欢', '出售可获得1000金币 25倍以下鱼类有几率掉落', '1201', '1', '-1', '0', '0', '0', '1', '0', '6', '0');
INSERT INTO `t_item_table_info` VALUES ('1202', '度', '出售可获得1000金币 25倍以下鱼类有几率掉落', '1202', '1', '-1', '0', '0', '0', '1', '0', '7', '0');
INSERT INTO `t_item_table_info` VALUES ('1203', '国', '出售可获得5000金币 击杀奖金鱼有几率掉落', '1203', '1', '-1', '0', '0', '0', '1', '0', '8', '0');
INSERT INTO `t_item_table_info` VALUES ('1204', '庆', '出售可获得10000金币 击杀BOSS金猪有几率掉落', '1204', '1', '-1', '0', '0', '0', '1', '0', '9', '0');
INSERT INTO `t_item_table_info` VALUES ('1205', '节', '出售可获得100000金币 击杀BOSS骨龙 机械虾有几率掉落', '1205', '1', '-1', '0', '0', '0', '1', '0', '10', '0');
INSERT INTO `t_item_table_info` VALUES ('1206', '国庆礼包', '打开可获得金币50000 锁定*5 狂暴*5', '1206', '1', '-1', '0', '0', '0', '1', '0', '11', '0');
INSERT INTO `t_item_table_info` VALUES ('1207', '国庆豪华礼包', '打开可随机获得3种宝箱中的一种', '1207', '1', '-1', '0', '0', '0', '1', '0', '12', '0');
INSERT INTO `t_item_table_info` VALUES ('1208', 'RMB', '代表人名币', '1208', '1', '-1', '0', '0', '0', '0', '0', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1211', '惊', '出售可获得1000金币，25倍以下鱼类有几率掉落', '1211', '1', '-1', '0', '0', '0', '1', '0', '13', '0');
INSERT INTO `t_item_table_info` VALUES ('1212', '魂', '出售可获得1000金币，25倍以下鱼类有几率掉落', '1212', '1', '-1', '0', '0', '0', '1', '0', '14', '0');
INSERT INTO `t_item_table_info` VALUES ('1213', '万', '出售可获得5000金币 击杀奖金鱼有几率掉落', '1213', '1', '-1', '0', '0', '0', '1', '0', '15', '0');
INSERT INTO `t_item_table_info` VALUES ('1214', '圣', '出售可获得10000金币，击杀BOSS有几率掉落', '1214', '1', '-1', '0', '0', '0', '1', '0', '16', '0');
INSERT INTO `t_item_table_info` VALUES ('1215', '节', '出售可获得100000金币 击杀深海宝藏区域BOSS有几率掉落', '1215', '1', '-1', '0', '0', '0', '1', '0', '17', '0');
INSERT INTO `t_item_table_info` VALUES ('1216', '万圣节礼包', '打开可获得金币50000 锁定*5 狂暴*5', '1216', '1', '-1', '0', '0', '0', '1', '0', '18', '0');
INSERT INTO `t_item_table_info` VALUES ('1217', '万圣节豪华礼包', '打开可随机获得3种宝箱中的一种', '1217', '1', '-1', '0', '0', '0', '1', '0', '19', '0');
INSERT INTO `t_item_table_info` VALUES ('1218', '神灯', '可以召唤神兽凤凰，击杀必掉宝箱', '1218', '1', '-1', '0', '0', '0', '0', '0', '0', '0');
INSERT INTO `t_item_table_info` VALUES ('1221', '欢', '出售可获得1000金币 25倍以下鱼类有几率掉落', '1221', '1', '-1', '0', '0', '0', '1', '0', '22', '0');
INSERT INTO `t_item_table_info` VALUES ('1222', '度', '出售可获得1000金币 25倍以下鱼类有几率掉落', '1222', '1', '-1', '0', '0', '0', '1', '0', '23', '0');
INSERT INTO `t_item_table_info` VALUES ('1223', '圣', '出售可获得5000金币 击杀奖金鱼有几率掉落', '1223', '1', '-1', '0', '0', '0', '1', '0', '24', '0');
INSERT INTO `t_item_table_info` VALUES ('1224', '诞', '出售可获得10000金币 击杀BOSS金猪有几率掉落', '1224', '1', '-1', '0', '0', '0', '1', '0', '25', '0');
INSERT INTO `t_item_table_info` VALUES ('1225', '节', '出售可获得100000金币 击杀BOSS骨龙 机械虾有几率掉落', '1225', '1', '-1', '0', '0', '0', '1', '0', '26', '0');
INSERT INTO `t_item_table_info` VALUES ('1226', '宝箱', '打开可获得金币50000 锁定*5 狂暴*5', '1226', '1', '-1', '0', '0', '0', '1', '0', '27', '0');
INSERT INTO `t_item_table_info` VALUES ('1227', '华丽宝箱', '打开可随机获得3种宝箱中的一种', '1227', '1', '-1', '0', '0', '0', '1', '0', '28', '0');
INSERT INTO `t_item_table_info` VALUES ('1228', '浪', '出售可获得1000金币 25倍以下鱼类有几率掉落', '1228', '1', '-1', '0', '0', '0', '1', '0', '29', '0');
INSERT INTO `t_item_table_info` VALUES ('1229', '漫', '出售可获得1000金币 25倍以下鱼类有几率掉落', '1229', '1', '-1', '0', '0', '0', '1', '0', '30', '0');
INSERT INTO `t_item_table_info` VALUES ('1230', '情', '出售可获得5000金币 击杀奖金鱼有几率掉落', '1230', '1', '-1', '0', '0', '0', '1', '0', '31', '0');
INSERT INTO `t_item_table_info` VALUES ('1231', '人', '出售可获得10000金币 击杀BOSS金猪有几率掉落', '1231', '1', '-1', '0', '0', '0', '1', '0', '32', '0');
INSERT INTO `t_item_table_info` VALUES ('1232', '节', '出售可获得100000金币 击杀BOSS骨龙 机械虾有几率掉落', '1232', '1', '-1', '0', '0', '0', '1', '0', '33', '0');
INSERT INTO `t_item_table_info` VALUES ('1233', '浪漫礼包', '打开可获得金币50000 锁定*5 狂暴*5', '1233', '1', '-1', '0', '0', '0', '1', '0', '34', '0');
INSERT INTO `t_item_table_info` VALUES ('1234', '情人节大礼', '打开可随机获得3种宝箱中的一种', '1234', '1', '-1', '0', '0', '0', '1', '0', '35', '0');

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
-- Records of t_rescue_coin
-- ----------------------------
INSERT INTO `t_rescue_coin` VALUES ('1', '30', '10000');
INSERT INTO `t_rescue_coin` VALUES ('2', '60', '10000');
INSERT INTO `t_rescue_coin` VALUES ('3', '180', '10000');
INSERT INTO `t_rescue_coin` VALUES ('4', '5', '5000');
INSERT INTO `t_rescue_coin` VALUES ('5', '5', '5000');
INSERT INTO `t_rescue_coin` VALUES ('6', '5', '5000');
INSERT INTO `t_rescue_coin` VALUES ('7', '5', '5000');
INSERT INTO `t_rescue_coin` VALUES ('8', '5', '5000');
INSERT INTO `t_rescue_coin` VALUES ('9', '5', '5000');
INSERT INTO `t_rescue_coin` VALUES ('10', '5', '5000');
INSERT INTO `t_rescue_coin` VALUES ('11', '5', '5000');
INSERT INTO `t_rescue_coin` VALUES ('12', '5', '5000');
INSERT INTO `t_rescue_coin` VALUES ('13', '5', '5000');
INSERT INTO `t_rescue_coin` VALUES ('14', '5', '5000');
INSERT INTO `t_rescue_coin` VALUES ('15', '5', '5000');
INSERT INTO `t_rescue_coin` VALUES ('16', '5', '5000');
INSERT INTO `t_rescue_coin` VALUES ('17', '5', '5000');
INSERT INTO `t_rescue_coin` VALUES ('18', '5', '5000');
INSERT INTO `t_rescue_coin` VALUES ('19', '5', '5000');
INSERT INTO `t_rescue_coin` VALUES ('20', '5', '5000');

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
-- Records of t_signin_award_info
-- ----------------------------
INSERT INTO `t_signin_award_info` VALUES ('1001', '1', '1', '1001', '2000');
INSERT INTO `t_signin_award_info` VALUES ('1002', '1', '2', '1001', '4000');
INSERT INTO `t_signin_award_info` VALUES ('1003', '1', '3', '1001', '5000');
INSERT INTO `t_signin_award_info` VALUES ('1004', '1', '4', '1001', '6000');
INSERT INTO `t_signin_award_info` VALUES ('1005', '1', '5', '1001', '7000');
INSERT INTO `t_signin_award_info` VALUES ('1006', '1', '6', '1001', '8000');
INSERT INTO `t_signin_award_info` VALUES ('1007', '1', '7', '1001', '10000');
INSERT INTO `t_signin_award_info` VALUES ('2001', '2', '5', '1001', '6000');
INSERT INTO `t_signin_award_info` VALUES ('2002', '2', '10', '1001', '10000');
INSERT INTO `t_signin_award_info` VALUES ('2003', '2', '15', '1001', '15000');
INSERT INTO `t_signin_award_info` VALUES ('2004', '2', '25', '1001', '20000');

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
-- Records of t_table_drop_gem
-- ----------------------------
INSERT INTO `t_table_drop_gem` VALUES ('1', '5000');
INSERT INTO `t_table_drop_gem` VALUES ('2', '5000');
INSERT INTO `t_table_drop_gem` VALUES ('3', '5000');
INSERT INTO `t_table_drop_gem` VALUES ('4', '5000');
INSERT INTO `t_table_drop_gem` VALUES ('5', '5000');
INSERT INTO `t_table_drop_gem` VALUES ('6', '6000');
INSERT INTO `t_table_drop_gem` VALUES ('7', '6000');
INSERT INTO `t_table_drop_gem` VALUES ('8', '6000');
INSERT INTO `t_table_drop_gem` VALUES ('9', '6000');
INSERT INTO `t_table_drop_gem` VALUES ('10', '6000');
INSERT INTO `t_table_drop_gem` VALUES ('11', '6000');
INSERT INTO `t_table_drop_gem` VALUES ('12', '6000');
INSERT INTO `t_table_drop_gem` VALUES ('13', '6000');
INSERT INTO `t_table_drop_gem` VALUES ('14', '6000');
INSERT INTO `t_table_drop_gem` VALUES ('15', '8000');
INSERT INTO `t_table_drop_gem` VALUES ('16', '8000');
INSERT INTO `t_table_drop_gem` VALUES ('17', '8000');
INSERT INTO `t_table_drop_gem` VALUES ('18', '8000');
INSERT INTO `t_table_drop_gem` VALUES ('19', '8000');
INSERT INTO `t_table_drop_gem` VALUES ('20', '8000');
INSERT INTO `t_table_drop_gem` VALUES ('21', '8000');
INSERT INTO `t_table_drop_gem` VALUES ('22', '8000');
INSERT INTO `t_table_drop_gem` VALUES ('23', '8000');
INSERT INTO `t_table_drop_gem` VALUES ('24', '8000');
INSERT INTO `t_table_drop_gem` VALUES ('25', '8000');
INSERT INTO `t_table_drop_gem` VALUES ('26', '8000');
INSERT INTO `t_table_drop_gem` VALUES ('27', '10000');
INSERT INTO `t_table_drop_gem` VALUES ('28', '10000');
INSERT INTO `t_table_drop_gem` VALUES ('29', '10000');
INSERT INTO `t_table_drop_gem` VALUES ('30', '10000');
INSERT INTO `t_table_drop_gem` VALUES ('31', '10000');
INSERT INTO `t_table_drop_gem` VALUES ('32', '10000');
INSERT INTO `t_table_drop_gem` VALUES ('33', '10000');
INSERT INTO `t_table_drop_gem` VALUES ('34', '10000');
INSERT INTO `t_table_drop_gem` VALUES ('35', '10000');
INSERT INTO `t_table_drop_gem` VALUES ('36', '10000');
INSERT INTO `t_table_drop_gem` VALUES ('37', '10000');
INSERT INTO `t_table_drop_gem` VALUES ('38', '10000');
INSERT INTO `t_table_drop_gem` VALUES ('39', '10000');
INSERT INTO `t_table_drop_gem` VALUES ('40', '10000');
INSERT INTO `t_table_drop_gem` VALUES ('41', '10000');
INSERT INTO `t_table_drop_gem` VALUES ('42', '20000');
INSERT INTO `t_table_drop_gem` VALUES ('43', '20000');
INSERT INTO `t_table_drop_gem` VALUES ('44', '20000');
INSERT INTO `t_table_drop_gem` VALUES ('45', '20000');
INSERT INTO `t_table_drop_gem` VALUES ('46', '20000');
INSERT INTO `t_table_drop_gem` VALUES ('47', '20000');
INSERT INTO `t_table_drop_gem` VALUES ('48', '20000');
INSERT INTO `t_table_drop_gem` VALUES ('49', '20000');
INSERT INTO `t_table_drop_gem` VALUES ('50', '20000');
INSERT INTO `t_table_drop_gem` VALUES ('51', '20000');
INSERT INTO `t_table_drop_gem` VALUES ('52', '20000');
INSERT INTO `t_table_drop_gem` VALUES ('53', '20000');
INSERT INTO `t_table_drop_gem` VALUES ('54', '20000');
INSERT INTO `t_table_drop_gem` VALUES ('55', '20000');
INSERT INTO `t_table_drop_gem` VALUES ('56', '20000');
INSERT INTO `t_table_drop_gem` VALUES ('57', '20000');
INSERT INTO `t_table_drop_gem` VALUES ('58', '20000');
INSERT INTO `t_table_drop_gem` VALUES ('59', '20000');
INSERT INTO `t_table_drop_gem` VALUES ('60', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('61', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('62', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('63', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('64', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('65', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('66', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('67', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('68', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('69', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('70', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('71', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('72', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('73', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('74', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('75', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('76', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('77', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('78', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('79', '50000');
INSERT INTO `t_table_drop_gem` VALUES ('80', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('81', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('82', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('83', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('84', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('85', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('86', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('87', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('88', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('89', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('90', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('91', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('92', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('93', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('94', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('95', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('96', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('97', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('98', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('99', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('100', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('101', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('102', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('103', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('104', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('105', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('106', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('107', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('108', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('109', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('110', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('111', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('112', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('113', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('114', '75000');
INSERT INTO `t_table_drop_gem` VALUES ('115', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('116', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('117', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('118', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('119', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('120', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('121', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('122', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('123', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('124', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('125', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('126', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('127', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('128', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('129', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('130', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('131', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('132', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('133', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('134', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('135', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('136', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('137', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('138', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('139', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('140', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('141', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('142', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('143', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('144', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('145', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('146', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('147', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('148', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('149', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('150', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('151', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('152', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('153', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('154', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('155', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('156', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('157', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('158', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('159', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('160', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('161', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('162', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('163', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('164', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('165', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('166', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('167', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('168', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('169', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('170', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('171', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('172', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('173', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('174', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('175', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('176', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('177', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('178', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('179', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('180', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('181', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('182', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('183', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('184', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('185', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('186', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('187', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('188', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('189', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('190', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('191', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('192', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('193', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('194', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('195', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('196', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('197', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('198', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('199', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('200', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('201', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('202', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('203', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('204', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('205', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('206', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('207', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('208', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('209', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('210', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('211', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('212', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('213', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('214', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('215', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('216', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('217', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('218', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('219', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('220', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('221', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('222', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('223', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('224', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('225', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('226', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('227', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('228', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('229', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('230', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('231', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('232', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('233', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('234', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('235', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('236', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('237', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('238', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('239', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('240', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('241', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('242', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('243', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('244', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('245', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('246', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('247', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('248', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('249', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('250', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('251', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('252', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('253', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('254', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('255', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('256', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('257', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('258', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('259', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('260', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('261', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('262', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('263', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('264', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('265', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('266', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('267', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('268', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('269', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('270', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('271', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('272', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('273', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('274', '83333');
INSERT INTO `t_table_drop_gem` VALUES ('275', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('276', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('277', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('278', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('279', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('280', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('281', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('282', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('283', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('284', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('285', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('286', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('287', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('288', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('289', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('290', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('291', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('292', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('293', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('294', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('295', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('296', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('297', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('298', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('299', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('300', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('301', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('302', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('303', '93750');
INSERT INTO `t_table_drop_gem` VALUES ('304', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('305', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('306', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('307', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('308', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('309', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('310', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('311', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('312', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('313', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('314', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('315', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('316', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('317', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('318', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('319', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('320', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('321', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('322', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('323', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('324', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('325', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('326', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('327', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('328', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('329', '200000');
INSERT INTO `t_table_drop_gem` VALUES ('330', '375000');
INSERT INTO `t_table_drop_gem` VALUES ('331', '375000');
INSERT INTO `t_table_drop_gem` VALUES ('332', '375000');
INSERT INTO `t_table_drop_gem` VALUES ('333', '375000');
INSERT INTO `t_table_drop_gem` VALUES ('334', '375000');
INSERT INTO `t_table_drop_gem` VALUES ('335', '375000');
INSERT INTO `t_table_drop_gem` VALUES ('336', '375000');
INSERT INTO `t_table_drop_gem` VALUES ('337', '375000');
INSERT INTO `t_table_drop_gem` VALUES ('338', '375000');
INSERT INTO `t_table_drop_gem` VALUES ('339', '375000');
INSERT INTO `t_table_drop_gem` VALUES ('340', '375000');
INSERT INTO `t_table_drop_gem` VALUES ('341', '375000');
INSERT INTO `t_table_drop_gem` VALUES ('342', '375000');
INSERT INTO `t_table_drop_gem` VALUES ('343', '375000');
INSERT INTO `t_table_drop_gem` VALUES ('344', '375000');
INSERT INTO `t_table_drop_gem` VALUES ('345', '375000');
INSERT INTO `t_table_drop_gem` VALUES ('346', '375000');
INSERT INTO `t_table_drop_gem` VALUES ('347', '500000');

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
-- Records of t_table_fly_bird_run_monster
-- ----------------------------
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('1', '1', '1号兔子', '1', '500', '6');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('2', '1', '2号兔子', '501', '1000', '6');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('3', '1', '3号兔子', '1001', '1667', '6');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('4', '2', '1号猴子', '1668', '2068', '8');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('5', '2', '2号猴子', '2069', '2469', '8');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('6', '2', '3号猴子', '2470', '2917', '8');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('7', '3', '通吃', '2918', '2937', '0');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('8', '4', '1号熊猫', '2939', '3339', '8');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('9', '4', '2号熊猫', '3340', '3740', '8');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('10', '4', '3号熊猫', '3741', '4187', '8');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('11', '5', '1号狮子', '4188', '4460', '12');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('12', '5', '2号狮子', '4461', '4731', '12');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('13', '5', '3号狮子', '4732', '5020', '12');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('14', '6', '鲨鱼', '5021', '5060', '24');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('15', '7', '1号老鹰', '5061', '5331', '12');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('16', '7', '2号老鹰', '5332', '5602', '12');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('17', '7', '3号老鹰', '5603', '5893', '12');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('18', '8', '1号孔雀', '5894', '6394', '8');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('19', '8', '2号孔雀', '6395', '6895', '8');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('20', '8', '3号孔雀', '6896', '7560', '8');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('21', '9', '通赔', '0', '0', '0');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('22', '10', '1号鸽子', '7561', '7961', '8');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('23', '10', '2号鸽子', '7962', '8362', '8');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('24', '10', '3号鸽子', '8363', '8810', '8');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('25', '11', '1号燕子', '8811', '9311', '6');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('26', '11', '2号燕子', '9312', '9712', '6');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('27', '11', '3号燕子', '9713', '10060', '6');
INSERT INTO `t_table_fly_bird_run_monster` VALUES ('28', '6', '金鲨', '0', '0', '100');

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
-- Records of t_table_give
-- ----------------------------
INSERT INTO `t_table_give` VALUES ('1', '银宝箱', '可以开出20W金币或者获得一个紫色水晶炮台', '3', '1001:200000:1:100');
INSERT INTO `t_table_give` VALUES ('2', '金宝箱', '可以开出50W金币或者获得一个紫色水晶炮台', '3', '1001:500000:1:100');
INSERT INTO `t_table_give` VALUES ('3', '铂金宝箱', '可以开出100W金币或者获得一个紫色水晶炮台', '3', '1001:1000000:1:100');
INSERT INTO `t_table_give` VALUES ('4', '藏宝图上', '出售可以获得1000金币', '3', '1001:1000:1:100');
INSERT INTO `t_table_give` VALUES ('5', '藏宝图下', '出售可以获得5000金币', '3', '1001:5000:1:100');
INSERT INTO `t_table_give` VALUES ('6', '欢', '出售可以获得1000金币', '3', '1001:1000:1:100');
INSERT INTO `t_table_give` VALUES ('7', '度', '出售可以获得1000金币', '3', '1001:1000:1:100');
INSERT INTO `t_table_give` VALUES ('8', '国', '出售可以获得5000金币', '3', '1001:5000:1:100');
INSERT INTO `t_table_give` VALUES ('9', '庆', '出售可以获得10000金币', '3', '1001:10000:1:100');
INSERT INTO `t_table_give` VALUES ('10', '节', '出售可以获得100000金币', '3', '1001:100000:1:100');
INSERT INTO `t_table_give` VALUES ('11', '国庆礼包', '可以开出5W金币，5个狂暴和5个锁定', '3', '1001:50000:1:100|1004:5:1:100|1005:5:1:100');
INSERT INTO `t_table_give` VALUES ('12', '国庆豪华礼包', '可以随机开出白银，黄金，铂金宝箱中的一个', '1', '1009:1:1:50|1010:1:51:80|1011:1:81:100');
INSERT INTO `t_table_give` VALUES ('13', '惊', '出售可以获得1000金币', '3', '1001:1000:1:100');
INSERT INTO `t_table_give` VALUES ('14', '魂', '出售可以获得1000金币', '3', '1001:1000:1:100');
INSERT INTO `t_table_give` VALUES ('15', '万', '出售可以获得5000金币', '3', '1001:5000:1:100');
INSERT INTO `t_table_give` VALUES ('16', '圣', '出售可以获得10000金币', '3', '1001:10000:1:100');
INSERT INTO `t_table_give` VALUES ('17', '节', '出售可以获得100000金币', '3', '1001:100000:1:100');
INSERT INTO `t_table_give` VALUES ('18', '万圣节礼包', '可以开出5W金币，5个狂暴和5个锁定', '3', '1001:50000:1:100|1004:5:1:100|1005:5:1:100');
INSERT INTO `t_table_give` VALUES ('19', '万圣节豪华礼包', '可以随机开出白银，黄金，铂金宝箱中的一个', '1', '1009:1:1:50|1010:1:51:80|1011:1:81:100');
INSERT INTO `t_table_give` VALUES ('20', '钻石宝箱', '使用获得200W金币', '3', '1001:2000000:1:100');
INSERT INTO `t_table_give` VALUES ('21', '至尊宝箱', '使用获得1000W金币', '3', '1001:10000000:1:100');
INSERT INTO `t_table_give` VALUES ('22', '欢', '出售可以获得1000金币', '3', '1001:1000:1:100');
INSERT INTO `t_table_give` VALUES ('23', '度', '出售可以获得1000金币', '3', '1001:1000:1:100');
INSERT INTO `t_table_give` VALUES ('24', '圣', '出售可以获得5000金币', '3', '1001:5000:1:100');
INSERT INTO `t_table_give` VALUES ('25', '诞', '出售可以获得10000金币', '3', '1001:10000:1:100');
INSERT INTO `t_table_give` VALUES ('26', '节', '出售可以获得100000金币', '3', '1001:100000:1:100');
INSERT INTO `t_table_give` VALUES ('27', '宝箱', '可以开出5W金币，5个狂暴和5个锁定', '3', '1001:50000:1:100|1004:5:1:100|1005:5:1:100');
INSERT INTO `t_table_give` VALUES ('28', '华丽宝箱', '可以随机开出白银，黄金，铂金宝箱中的一个', '1', '1009:1:1:50|1010:1:51:80|1011:1:81:100');
INSERT INTO `t_table_give` VALUES ('29', '浪', '出售可以获得1000金币', '3', '1001:1000:1:100');
INSERT INTO `t_table_give` VALUES ('30', '漫', '出售可以获得1000金币', '3', '1001:1000:1:100');
INSERT INTO `t_table_give` VALUES ('31', '情', '出售可以获得5000金币', '3', '1001:5000:1:100');
INSERT INTO `t_table_give` VALUES ('32', '人', '出售可以获得10000金币', '3', '1001:10000:1:100');
INSERT INTO `t_table_give` VALUES ('33', '节', '出售可以获得100000金币', '3', '1001:100000:1:100');
INSERT INTO `t_table_give` VALUES ('34', '浪漫礼包', '可以开出5W金币，5个狂暴和5个锁定', '3', '1001:50000:1:100|1004:5:1:100|1005:5:1:100');
INSERT INTO `t_table_give` VALUES ('35', '情人节大礼', '可以随机开出白银，黄金，铂金宝箱中的一个', '1', '1009:1:1:50|1010:1:51:80|1011:1:81:100');
INSERT INTO `t_table_give` VALUES ('36', '火焰结晶', '出售可以获得100W金币', '3', '1001:1000000:1:100');

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
-- Records of t_table_gun_uplevel
-- ----------------------------
INSERT INTO `t_table_gun_uplevel` VALUES ('1', '200', '5', '5000');
INSERT INTO `t_table_gun_uplevel` VALUES ('2', '300', '7', '10000');
INSERT INTO `t_table_gun_uplevel` VALUES ('3', '400', '10', '15000');
INSERT INTO `t_table_gun_uplevel` VALUES ('4', '500', '15', '15000');
INSERT INTO `t_table_gun_uplevel` VALUES ('5', '600', '30', '20000');
INSERT INTO `t_table_gun_uplevel` VALUES ('6', '700', '40', '20000');
INSERT INTO `t_table_gun_uplevel` VALUES ('7', '800', '50', '25000');
INSERT INTO `t_table_gun_uplevel` VALUES ('8', '900', '60', '25000');
INSERT INTO `t_table_gun_uplevel` VALUES ('9', '1000', '60', '30000');
INSERT INTO `t_table_gun_uplevel` VALUES ('10', '2000', '70', '30000');
INSERT INTO `t_table_gun_uplevel` VALUES ('11', '3000', '70', '40000');
INSERT INTO `t_table_gun_uplevel` VALUES ('12', '4000', '75', '40000');
INSERT INTO `t_table_gun_uplevel` VALUES ('13', '5000', '75', '50000');
INSERT INTO `t_table_gun_uplevel` VALUES ('14', '6000', '80', '50000');
INSERT INTO `t_table_gun_uplevel` VALUES ('15', '7000', '80', '50000');
INSERT INTO `t_table_gun_uplevel` VALUES ('16', '8000', '90', '50000');
INSERT INTO `t_table_gun_uplevel` VALUES ('17', '9000', '100', '80000');
INSERT INTO `t_table_gun_uplevel` VALUES ('18', '10000', '150', '80000');
INSERT INTO `t_table_gun_uplevel` VALUES ('19', '50000', '170', '100000');
INSERT INTO `t_table_gun_uplevel` VALUES ('20', '100000', '200', '100000');

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
-- Records of t_table_reward_gold_fish
-- ----------------------------
INSERT INTO `t_table_reward_gold_fish` VALUES ('1', '普通抽奖', '10000', '1:1001:12000:1:20|6:1003:10:98:100|2:1001:8000:21:75|7:1002:20:101:101|3:1001:25000:76:80|8:1002:30:101:101|4:1001:3000:81:95|5:1001:40000:96:97', '3', '3:2:1');
INSERT INTO `t_table_reward_gold_fish` VALUES ('2', '青铜抽奖', '100000', '1:1001:120000:1:20|6:1003:50:98:100|2:1001:80000:21:75|7:1002:100:101:101|3:1001:250000:76:80|8:1002:150:101:101|4:1001:30000:81:95|5:1001:400000:96:97', '3', '3:2:1');
INSERT INTO `t_table_reward_gold_fish` VALUES ('3', '白银抽奖', '200000', '1:1001:240000:1:20|5:1006:1:91:100|2:1001:160000:21:70|6:1002:100:101:101|3:1001:500000:71:75|7:1002:150:101:101|4:1001:60000:76:90|8:1002:200:101:101', '3', '1:5:3');
INSERT INTO `t_table_reward_gold_fish` VALUES ('4', '黄金抽奖', '400000', '1:1001:600000:1:20|5:1007:1:91:100|2:1001:320000:21:70|6:1002:150:101:101|3:1001:1000000:71:75|7:1002:200:101:101|4:1001:120000:76:90|8:1002:300:101:101', '3', '1:5:3');
INSERT INTO `t_table_reward_gold_fish` VALUES ('5', '铂金抽奖', '800000', '1:1001:1200000:1:20|5:1008:1:91:100|2:1001:640000:21:67|6:1003:400:68:70|3:1001:2000000:71:75|7:1002:300:101:101|4:1001:240000:76:90|8:1002:400:101:101', '3', '1:2:3');
INSERT INTO `t_table_reward_gold_fish` VALUES ('6', '钻石抽奖', '2000000', '1:1001:2400000:1:20|5:1008:2:91:100|2:1001:1600000:21:62|6:1003:800:63:65|3:1001:4000000:66:70|7:1002:1000:71:75|4:1001:1000000:76:90|8:1002:400:101:101', '3', '1:2:3');

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
-- Records of t_table_vip
-- ----------------------------
INSERT INTO `t_table_vip` VALUES ('0', '', '0.00', '0', '1.0000000000', '1.0000000000', '1.0000000000', '1.0000000000', '1.0000000000', '0');
INSERT INTO `t_table_vip` VALUES ('1', '', '30.00', '1', '1.0000000000', '1.0000000000', '1.0000000000', '1.0000000000', '1.0000000000', '0');
INSERT INTO `t_table_vip` VALUES ('2', '', '200.00', '1', '1.6000000000', '1.0000000000', '1.0000000000', '1.0000000000', '1.0000000000', '0');
INSERT INTO `t_table_vip` VALUES ('3', '', '500.00', '1', '1.6000000000', '1.1000000000', '1.0000000000', '1.0000000000', '1.0000000000', '9');
INSERT INTO `t_table_vip` VALUES ('4', '', '1000.00', '1', '1.6000000000', '1.1000000000', '1.2000000000', '1.0000000000', '1.0000000000', '9');
INSERT INTO `t_table_vip` VALUES ('5', '', '2000.00', '1', '1.6000000000', '1.2000000000', '1.2000000000', '1.0000000000', '1.0000000000', '18');
INSERT INTO `t_table_vip` VALUES ('6', '', '5000.00', '1', '1.6000000000', '1.2000000000', '1.2000000000', '1.0102040820', '1.0000000000', '18');
INSERT INTO `t_table_vip` VALUES ('7', '', '10000.00', '1', '1.6000000000', '1.2000000000', '1.2000000000', '1.0102040820', '1.0102040820', '18');

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
-- Records of t_task_table_info
-- ----------------------------
INSERT INTO `t_task_table_info` VALUES ('1001', '1', '0', '0', '1', '100', '100:1|101:1|102:1', '1001:15000');
INSERT INTO `t_task_table_info` VALUES ('1002', '1', '0', '0', '1', '100', '101:1|102:1|103:1', '1001:15000');
INSERT INTO `t_task_table_info` VALUES ('1003', '1', '0', '0', '1', '100', '102:1|103:1|104:1', '1001:15000');
INSERT INTO `t_task_table_info` VALUES ('2001', '2', '0', '0', '0', '100', '3:4|9:3|17:1', '1001:70000');
INSERT INTO `t_task_table_info` VALUES ('2002', '2', '0', '0', '0', '100', '4:5|11:3|16:1', '1001:50000');
INSERT INTO `t_task_table_info` VALUES ('2003', '2', '0', '0', '0', '100', '2:5|12:3|18:1', '1001:60000');
INSERT INTO `t_task_table_info` VALUES ('2004', '2', '0', '0', '0', '100', '1:5|10:3|19:1', '1001:80000');

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
-- Records of t_title_table_info
-- ----------------------------
INSERT INTO `t_title_table_info` VALUES ('1', '1', '1', '深海霸主');
INSERT INTO `t_title_table_info` VALUES ('2', '1', '2', '深海征服者');
INSERT INTO `t_title_table_info` VALUES ('3', '1', '3', '深海勇士');
INSERT INTO `t_title_table_info` VALUES ('4', '2', '1', '宝箱大亨');
INSERT INTO `t_title_table_info` VALUES ('5', '2', '2', '宝箱大师');
INSERT INTO `t_title_table_info` VALUES ('6', '2', '3', '宝箱猎人');

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
-- Records of vipawardinfo
-- ----------------------------
INSERT INTO `vipawardinfo` VALUES ('1', '绿钻', '10000');
INSERT INTO `vipawardinfo` VALUES ('2', '蓝钻', '20000');
INSERT INTO `vipawardinfo` VALUES ('3', '紫钻', '40000');
INSERT INTO `vipawardinfo` VALUES ('4', '黄钻', '100000');
INSERT INTO `vipawardinfo` VALUES ('5', '皇冠', '200000');
