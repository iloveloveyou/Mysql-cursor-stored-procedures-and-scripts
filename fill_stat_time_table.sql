USE sample;

-- call fill_stat_time_table('2015-01-01', '2016-12-31');
-- > Query OK, 1 row affected (1 min 40.88 sec)
-- select count(*) from `stat_time_table`;
-- > 35040

DELIMITER $$
 DROP PROCEDURE IF EXISTS `fill_stat_time_table`$$
 CREATE PROCEDURE `fill_stat_time_table`(in BEGIN_TIME_VAR DATETIME, in END_TIME_VAR DATETIME)
 DETERMINISTIC
 MODIFIES SQL DATA
 BEGIN
 DECLARE CUR_TIME_VAR DATETIME;
 DECLARE NEXT_TIME_VAR DATETIME;
 
 DROP TABLE IF EXISTS `stat_time_table`;
 CREATE /*TEMPORARY*/ TABLE `stat_time_table` (
     `BEGIN_TIME` DATETIME NOT NULL COMMENT 'Period Begin Time',
     `END_TIME` DATETIME NOT NULL COMMENT 'Period End Time',
     PRIMARY KEY (`BEGIN_TIME`)
 );
 
 SET CUR_TIME_VAR = BEGIN_TIME_VAR;
 
 /*
 call dolog(concat(ifnull(CUR_TIME_VAR,'null'),
			 	  concat(" ", 
				    concat(ifnull(BEGIN_TIME_VAR, 'null'),
				      concat(" ", ifnull(END_TIME_VAR, 'null'))
				    )
				  )
			   ));
 */

 WHILE CUR_TIME_VAR < END_TIME_VAR DO
    SET NEXT_TIME_VAR = DATE_ADD(CUR_TIME_VAR, INTERVAL 30 MINUTE);
    INSERT INTO `stat_time_table` (`BEGIN_TIME`, `END_TIME`) VALUES(CUR_TIME_VAR, NEXT_TIME_VAR);
    SET CUR_TIME_VAR = NEXT_TIME_VAR;
 END WHILE;

 /*
 call dolog(concat(ifnull(CUR_TIME_VAR,'null'),
			 	  concat(" ", 
				    concat(ifnull(BEGIN_TIME_VAR, 'null'),
				      concat(" ", ifnull(END_TIME_VAR, 'null'))
				    )
				  )
			   ));
 */
			   
 END$$
DELIMITER ;

