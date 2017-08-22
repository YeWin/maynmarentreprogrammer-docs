
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

-- テーブルの構造 `m_user`
DROP TABLE IF EXISTS `m_user`;
CREATE TABLE `m_user` (
  `user_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ユーザID',
  `admin_flg` int(1) NOT NULL DEFAULT '0' COMMENT '管理者フラグ',
  `mail` varchar(255) NOT NULL COMMENT 'メールアドレス',
  `password` varchar(255) DEFAULT NULL COMMENT 'パスワード',
  `name` varchar(128) DEFAULT NULL COMMENT '名前',
  `image_url` varchar(512) DEFAULT NULL COMMENT '画像URL',
  `zipcode` varchar(32) DEFAULT NULL COMMENT '郵便番号',
  `address` varchar(512) DEFAULT NULL COMMENT '住所',
  `tel` varchar(20) DEFAULT NULL COMMENT '電話番号',
  `birthday` datetime DEFAULT NULL COMMENT '生年月日',
  `sex` int(1) DEFAULT NULL COMMENT '性別',
  `occupation` bigint(20) DEFAULT NULL COMMENT '職業',
  `memo` varchar(255) DEFAULT NULL COMMENT '備考',
  `delete_flg` int(1) NOT NULL DEFAULT '0' COMMENT '削除フラグ',
  `create_user` bigint(20) NOT NULL COMMENT '作成者ID',
  `create_datetime` datetime NOT NULL COMMENT '作成日時',
  `update_user` bigint(20) NOT NULL COMMENT '更新者ID',
  `update_datetime` datetime NOT NULL COMMENT '更新日時',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `mail` (`mail`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8;
-- --------------------------------------------------------

-- テーブルの構造 `m_group`
DROP TABLE IF EXISTS `m_group`;
CREATE TABLE `m_group` (
  `group_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'グループID',
  `group_name` varchar(64) NOT NULL COMMENT 'グループ名',
  `sender_mail` varchar(255) DEFAULT NULL COMMENT '送信元メールアドレス',
  `delete_flg` int(1) NOT NULL DEFAULT '0' COMMENT '削除フラグ',
  `create_user` bigint(20) NOT NULL COMMENT '作成者ID',
  `create_datetime` datetime NOT NULL COMMENT '作成日時',
  `update_user` bigint(20) NOT NULL COMMENT '更新者ID',
  `update_datetime` datetime NOT NULL COMMENT '更新日時',
  PRIMARY KEY (`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
-- --------------------------------------------------------

-- テーブルの構造 `t_group_member`
DROP TABLE IF EXISTS `t_group_member`;
CREATE TABLE `t_group_member` (
  `group_member_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'グループメンバID',
  `group_id` bigint(20) NOT NULL COMMENT 'グループID',
  `user_id` bigint(20) NOT NULL COMMENT 'ユーザID',
  `delete_flg` int(1) NOT NULL DEFAULT '0' COMMENT '削除フラグ',
  `create_datetime` datetime NOT NULL COMMENT '作成日時',
  `create_user` bigint(20) NOT NULL COMMENT '作成者ID',
  `update_datetime` datetime NOT NULL COMMENT '更新者ID',
  `update_user` bigint(20) NOT NULL COMMENT '更新日時',
  PRIMARY KEY (`group_member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
-- --------------------------------------------------------

-- テーブルの構造 `t_login_history`
DROP TABLE IF EXISTS `t_login_history`;
CREATE TABLE `t_login_history` (
  `login_history_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'ログイン履歴ID',
  `user_id` bigint(20) NOT NULL COMMENT 'ユーザID',
  `login_datetime` datetime NOT NULL COMMENT 'ログイン時刻',
  `delete_flg` int(1) NOT NULL DEFAULT '0' COMMENT '削除フラグ',
  `create_user` bigint(20) NOT NULL COMMENT '作成者ID',
  `create_datetime` datetime NOT NULL COMMENT '作成日時',
  `update_user` bigint(20) NOT NULL COMMENT '更新者ID',
  `update_datetime` datetime NOT NULL COMMENT '更新日時',
  PRIMARY KEY (`login_history_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

-- テーブルの構造 `t_mail_info`
DROP TABLE IF EXISTS `t_mail_info`;
CREATE TABLE `t_mail_info` (
  `mail_info_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'メール配信ID',
  `group_id` bigint(20) NOT NULL COMMENT 'グループID',
  `start_datetime` datetime DEFAULT NULL COMMENT '配信開始日時',
  `end_datetime` datetime DEFAULT NULL COMMENT '配信完了日時',
  `status` int(1) NOT NULL DEFAULT '0' COMMENT '配信ステータス',
  `delete_flg` int(1) NOT NULL DEFAULT '0' COMMENT '削除フラグ',
  `create_user` bigint(20) NOT NULL COMMENT '作成者ID',
  `create_datetime` datetime NOT NULL COMMENT '作成日時',
  `update_user` bigint(20) NOT NULL COMMENT '更新者ID',
  `update_datetime` datetime NOT NULL COMMENT '更新日時',
  PRIMARY KEY (`mail_info_id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;


-- --------------------------------------------------------

-- テーブルの構造 `t_safety`
DROP TABLE IF EXISTS `t_safety`;
CREATE TABLE `t_safety` (
  `safety_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '安否ID',
  `mail_info_id` bigint(20) NOT NULL COMMENT 'メール配信ID',
  `user_id` bigint(20) NOT NULL COMMENT 'ユーザID',
  `mail` varchar(255) NOT NULL COMMENT 'メールアドレス',
  `send_mail_datetime` datetime NOT NULL COMMENT 'メール送信日時',
  `group_id` bigint(20) NOT NULL DEFAULT '0' COMMENT 'グループID',
  `safety` int(1) NOT NULL DEFAULT '0' COMMENT '安否',
  `place` int(1) NOT NULL DEFAULT '0' COMMENT '居場所',
  `comment` varchar(512) DEFAULT NULL COMMENT '連絡事項',
  `status` int(1) NOT NULL DEFAULT '0' COMMENT '配信ステータス',
  `delete_flg` int(1) NOT NULL DEFAULT '0' COMMENT '削除フラグ',
  `create_user` bigint(20) NOT NULL COMMENT '作成者ID',
  `create_datetime` datetime NOT NULL COMMENT '作成日時',
  `update_user` bigint(20) NOT NULL COMMENT '更新者ID',
  `update_datetime` datetime NOT NULL COMMENT '更新日時',
  PRIMARY KEY (`safety_id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8;

alter table `m_user` comment 'ユーザ情報';
alter table `m_group` comment 'グループ情報';
alter table `t_group_member` comment 'グループメンバ情報';
alter table `t_login_history` comment 'ログイン履歴';
alter table `t_mail_info` comment 'メール配信情報';
alter table `t_safety` comment '安否情報';
alter table `m_user` comment 'ユーザ情報';

