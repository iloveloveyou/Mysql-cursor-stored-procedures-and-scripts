USE sample;

-- Table Unit
CREATE TABLE `unit` (
  `ID` int(20) DEFAULT NULL,
  `GROUP_ID` int(20) DEFAULT NULL,
  `CLUSTER_ID` int(20) DEFAULT NULL,
  `UNIT_REMOTE_ID` int(20) DEFAULT NULL,
  `UNIT_NAME` varchar(20) DEFAULT NULL,
  `UNIT_SERIAL` int(20) DEFAULT NULL,
  `WATER_PRICE` decimal(20,2) DEFAULT NULL,
  `PHONE_NUMBER` int(20) DEFAULT NULL,
  `IMEI` int(20) DEFAULT NULL,
  `TELCO_OPERATOR` varchar(20) DEFAULT NULL,
  `EVENT_EMAILS` varchar(20) DEFAULT NULL,
  `EVENT_PHONE` int(20) DEFAULT NULL,
  `LAST_CONNECTION` datetime DEFAULT NULL,
  `NOTES` varchar(100) DEFAULT NULL,
  `TIME_ZONE` datetime DEFAULT NULL,
  `CONNECTION_STATUS` varchar(20) DEFAULT NULL,
  `SIGNAL_STRENGTH` varchar(20) DEFAULT NULL,
  `SIGNAL_STRENGTH_CSQ` varchar(20) DEFAULT NULL,
  `LATITUDE` int(20) DEFAULT NULL,
  `LONGITUDE` int(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Table Trans
CREATE TABLE `trans` (
  `GROUP_ID` int(20) DEFAULT NULL,
  `UNIT_ID` int(20) DEFAULT NULL,
  `TRANSACTION_ID` int(20) DEFAULT NULL,
  `LOG_RTC` datetime DEFAULT NULL,
  `CARD_TYPE` int(20) DEFAULT NULL,
  `TRANSACTION_TYPE` int(20) DEFAULT NULL,
  `CREDITS_AFTER` decimal(20,0) DEFAULT NULL,
  `CREDITS_USED` decimal(20,2) DEFAULT NULL,
  `CREDITS_TOTAL_AFTER` decimal(20,2) DEFAULT NULL,
  `VOLUME_RELEASED` decimal(20,2) DEFAULT NULL,
  `VOLUME_TOTAL_AFTER` decimal(20,2) DEFAULT NULL,
  `CARD_ID1` int(20) DEFAULT NULL,
  `CARD_ID2` int(20) DEFAULT NULL,
  `NEW_WATER_PRICE` decimal(20,0) DEFAULT NULL,
  PRIMARY KEY (`TRANS_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=249385 DEFAULT CHARSET=latin1;

-- New Table for holding schedule servicing data

USE sample;
CREATE TABLE `ScheduleServicing` (
  `DATESUGGESTED` DATE,
  `DISPENSER` varchar(20) ,
  `DAYTIME` varchar(20) ,
  `DAY` varchar(20) ,
  `SERVICE` varchar(20),
  `DURATION` varchar(20)

)
;
-- New Table for holding cancelled schedule servicing data

USE sample;
CREATE TABLE `scheduleservicingcancelled` (
  `DateCancelled` date DEFAULT NULL,
  `DispenserCancelled` varchar(20) DEFAULT NULL,
  `DayTimeCancelled` varchar(20) DEFAULT NULL,
  `DayCancelled` varchar(20) DEFAULT NULL,
  `ServiceCancelled` varchar(20) DEFAULT NULL,
  `DurationCancelled` varchar(20) DEFAULT NULL,
  `Reason` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



-- Optimize tables
ALTER TABLE trans DROP COLUMN QUEUE_LENGTH ;
-- Add some extra columns "START_TIME", "FLOW_RATE", "TAPPING_TIME" to trans (less 1 minute to run)
ALTER TABLE trans ADD COLUMN TRANS_ID INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT;
ALTER TABLE trans ADD COLUMN FLOW_RATE DECIMAL(9,5);
ALTER TABLE trans ADD COLUMN TAPPING_TIME TIME;
ALTER TABLE trans ADD COLUMN START_TIME DATETIME;
ALTER TABLE trans ADD COLUMN IDLE_TIME TIME;
ALTER TABLE trans ADD COLUMN QUEUE_LENGTH INT;

-- Add some indexes
ALTER TABLE trans ADD INDEX idx_trans_unit_time (UNIT_ID, LOG_RTC);
ALTER TABLE trans ADD INDEX idx_trans_unit (UNIT_ID);
ALTER TABLE trans ADD INDEX idx_trans_group (GROUP_ID);
--


-- Calculate START_TIME in trans
-- ??? ALTER TABLE trans DISABLE KEYS;
CALL fill_full_trans_table();
--- ??? ALTER TABLE trans ENABLE KEYS;

ALTER TABLE trans ADD INDEX idx_trans_time (START_TIME);
