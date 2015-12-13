CREATE DATABASE  IF NOT EXISTS `dicionario-aberto` /*!40100 DEFAULT CHARACTER SET latin1 */;
USE `dicionario-aberto`;
-- MySQL dump 10.13  Distrib 5.6.19, for osx10.7 (i386)
--
-- Host: 127.0.0.1    Database: dicionario-aberto
-- ------------------------------------------------------
-- Server version	5.5.44

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `browse_idx`
--

DROP TABLE IF EXISTS `browse_idx`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `browse_idx` (
  `idx` int(11) NOT NULL AUTO_INCREMENT,
  `word` varchar(50) COLLATE utf8_bin NOT NULL,
  PRIMARY KEY (`idx`),
  KEY `on_word` (`word`)
) ENGINE=InnoDB AUTO_INCREMENT=125278 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `favourite`
--

DROP TABLE IF EXISTS `favourite`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `favourite` (
  `username` varchar(20) NOT NULL,
  `timestamp` datetime NOT NULL,
  `word_id` int(11) NOT NULL,
  PRIMARY KEY (`username`,`word_id`),
  KEY `fk_favourites_users1_idx` (`username`),
  KEY `fk_favourite_word1_idx` (`word_id`),
  CONSTRAINT `fk_favourites_users1` FOREIGN KEY (`username`) REFERENCES `user` (`username`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_favourite_word1` FOREIGN KEY (`word_id`) REFERENCES `word` (`word_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `metadata`
--

DROP TABLE IF EXISTS `metadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `metadata` (
  `key` varchar(50) NOT NULL,
  `value` varchar(100) NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `new`
--

DROP TABLE IF EXISTS `new`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `new` (
  `idnew` int(11) NOT NULL AUTO_INCREMENT,
  `user` varchar(20) NOT NULL,
  `date` datetime NOT NULL,
  `title` varchar(45) NOT NULL,
  `text` varchar(1000) NOT NULL,
  PRIMARY KEY (`idnew`),
  KEY `fk_new_user1_idx` (`user`),
  CONSTRAINT `fk_new_user1` FOREIGN KEY (`user`) REFERENCES `user` (`username`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=114 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `preview_cache`
--

DROP TABLE IF EXISTS `preview_cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `preview_cache` (
  `word_id` int(11) NOT NULL,
  `preview` varchar(500) COLLATE utf8_bin NOT NULL,
  `timestamp` datetime NOT NULL,
  PRIMARY KEY (`word_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `relation`
--

DROP TABLE IF EXISTS `relation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `relation` (
  `relation_id` varchar(10) COLLATE utf8_bin NOT NULL,
  `description` varchar(400) COLLATE utf8_bin NOT NULL,
  PRIMARY KEY (`relation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reported_user`
--

DROP TABLE IF EXISTS `reported_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `reported_user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `reported_user` varchar(20) NOT NULL,
  `reporter_user` varchar(20) NOT NULL,
  `timestamp` datetime NOT NULL,
  `reason` varchar(1500) NOT NULL,
  `admin_comment` varchar(1500) DEFAULT NULL,
  `admin_user` varchar(20) DEFAULT NULL,
  `closed` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_reported_user_user1_idx` (`reported_user`),
  KEY `fk_reported_user_user2_idx` (`reporter_user`),
  KEY `fk_reported_user_user3_idx` (`admin_user`),
  CONSTRAINT `fk_reported_user_user1` FOREIGN KEY (`reported_user`) REFERENCES `user` (`username`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_reported_user_user2` FOREIGN KEY (`reporter_user`) REFERENCES `user` (`username`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_reported_user_user3` FOREIGN KEY (`admin_user`) REFERENCES `user` (`username`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rev_idx_rel`
--

DROP TABLE IF EXISTS `rev_idx_rel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rev_idx_rel` (
  `rev_idx_word_id` int(11) NOT NULL,
  `word_id` int(11) NOT NULL,
  PRIMARY KEY (`rev_idx_word_id`,`word_id`),
  KEY `fk_rev_idx_rel_word1_idx` (`word_id`),
  CONSTRAINT `fk_rev_idx_rel_rev_idx_word1` FOREIGN KEY (`rev_idx_word_id`) REFERENCES `rev_idx_word` (`rev_idx_word_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_rev_idx_rel_word1` FOREIGN KEY (`word_id`) REFERENCES `word` (`word_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rev_idx_word`
--

DROP TABLE IF EXISTS `rev_idx_word`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rev_idx_word` (
  `rev_idx_word_id` int(11) NOT NULL AUTO_INCREMENT,
  `rev_idx_word` varchar(50) COLLATE utf8_bin NOT NULL,
  PRIMARY KEY (`rev_idx_word_id`),
  KEY `wordIdx` (`rev_idx_word`)
) ENGINE=InnoDB AUTO_INCREMENT=181643 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `revision`
--

DROP TABLE IF EXISTS `revision`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `revision` (
  `revision_id` int(11) NOT NULL,
  `word_id` int(11) NOT NULL,
  `creator` varchar(20) CHARACTER SET utf8 NOT NULL,
  `timestamp` datetime NOT NULL,
  `xml` text CHARACTER SET utf8 NOT NULL,
  `deleted` tinyint(1) NOT NULL DEFAULT '0',
  `moderator` varchar(20) CHARACTER SET utf8 DEFAULT NULL,
  `deletor` varchar(20) CHARACTER SET utf8 DEFAULT NULL,
  PRIMARY KEY (`revision_id`,`word_id`),
  KEY `fk_entries_words1_idx` (`word_id`),
  KEY `fk_entry_user1_idx` (`creator`),
  KEY `fk_entries_users_idx` (`deletor`),
  KEY `fk_entries_users1_idx` (`moderator`),
  CONSTRAINT `fk_entries_users` FOREIGN KEY (`deletor`) REFERENCES `user` (`username`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_entries_users1` FOREIGN KEY (`moderator`) REFERENCES `user` (`username`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_entries_words1` FOREIGN KEY (`word_id`) REFERENCES `word` (`word_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_entry_user1` FOREIGN KEY (`creator`) REFERENCES `user` (`username`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `role`
--

DROP TABLE IF EXISTS `role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `role` (
  `role_id` int(11) NOT NULL AUTO_INCREMENT,
  `role_name` varchar(10) NOT NULL,
  `create_word` tinyint(1) NOT NULL DEFAULT '0',
  `delete_word` tinyint(1) NOT NULL DEFAULT '0',
  `moderate_revision` tinyint(1) NOT NULL DEFAULT '0',
  `create_revision` tinyint(1) NOT NULL DEFAULT '0',
  `delete_revision` tinyint(1) NOT NULL DEFAULT '0',
  `manage_users` tinyint(1) NOT NULL DEFAULT '0',
  `report_users` tinyint(1) NOT NULL DEFAULT '0',
  `manage_news` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`role_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `search`
--

DROP TABLE IF EXISTS `search`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `search` (
  `time` datetime NOT NULL,
  `users_username` varchar(20) CHARACTER SET utf8 NOT NULL,
  `query` varchar(50) CHARACTER SET utf8 NOT NULL,
  PRIMARY KEY (`time`,`users_username`),
  KEY `fk_searches_users_idx` (`users_username`),
  CONSTRAINT `fk_searches_users` FOREIGN KEY (`users_username`) REFERENCES `user` (`username`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user` (
  `username` varchar(20) CHARACTER SET utf8 NOT NULL,
  `password` varchar(40) CHARACTER SET utf8 NOT NULL,
  `email` varchar(100) CHARACTER SET utf8 NOT NULL,
  `name` varchar(500) CHARACTER SET utf8 DEFAULT NULL,
  `name_public` tinyint(1) NOT NULL DEFAULT '0',
  `created` datetime NOT NULL,
  `role_id` int(11) NOT NULL,
  `banned` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`username`),
  KEY `fk_user_role1_idx` (`role_id`),
  CONSTRAINT `fk_user_role1` FOREIGN KEY (`role_id`) REFERENCES `role` (`role_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_restore`
--

DROP TABLE IF EXISTS `user_restore`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_restore` (
  `md5` varchar(32) COLLATE utf8_bin NOT NULL,
  `user` varchar(20) COLLATE utf8_bin NOT NULL,
  `requested` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `new` tinyint(1) NOT NULL DEFAULT '0',
  `email` varchar(100) COLLATE utf8_bin NOT NULL,
  `name` varchar(500) COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`md5`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `word`
--

DROP TABLE IF EXISTS `word`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `word` (
  `word_id` int(11) NOT NULL AUTO_INCREMENT,
  `word` varchar(50) COLLATE utf8_bin NOT NULL,
  `sense` int(11) NOT NULL DEFAULT '0',
  `last_revision` int(11) NOT NULL DEFAULT '1',
  `deleted` tinyint(1) NOT NULL DEFAULT '0',
  `creator` varchar(20) CHARACTER SET utf8 NOT NULL,
  `deletor` varchar(20) CHARACTER SET utf8 DEFAULT NULL,
  `normalized` varchar(50) CHARACTER SET utf8 NOT NULL,
  `derived_from` int(11) DEFAULT NULL,
  PRIMARY KEY (`word_id`),
  KEY `word_index` (`word`),
  KEY `normalidx` (`normalized`),
  KEY `fk_word_user1_idx` (`deletor`),
  KEY `fk_word_user2_idx` (`creator`),
  KEY `fk_word_word1_idx` (`derived_from`),
  CONSTRAINT `fk_word_user1` FOREIGN KEY (`deletor`) REFERENCES `user` (`username`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_word_user2` FOREIGN KEY (`creator`) REFERENCES `user` (`username`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_word_word1` FOREIGN KEY (`derived_from`) REFERENCES `word` (`word_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=128527 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `word_word_rel`
--

DROP TABLE IF EXISTS `word_word_rel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `word_word_rel` (
  `relation_id` varchar(10) COLLATE utf8_bin NOT NULL,
  `from_wid` int(11) NOT NULL,
  `to_wid` int(11) NOT NULL,
  PRIMARY KEY (`relation_id`,`from_wid`,`to_wid`),
  KEY `fk_word_word_rel_relation1_idx` (`relation_id`),
  KEY `fk_word_word_rel_word1_idx` (`from_wid`),
  KEY `fk_word_word_rel_word2_idx` (`to_wid`),
  CONSTRAINT `fk_word_word_rel_relation1` FOREIGN KEY (`relation_id`) REFERENCES `relation` (`relation_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_word_word_rel_word1` FOREIGN KEY (`from_wid`) REFERENCES `word` (`word_id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_word_word_rel_word2` FOREIGN KEY (`to_wid`) REFERENCES `word` (`word_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-12-13 17:04:21
