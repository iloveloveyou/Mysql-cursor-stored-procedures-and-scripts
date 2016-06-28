USE sample;

-- call calc_queue_idle('2015-01-01 00:30:00', '2015-01-01 01:00:00');
-- > 13:47

DELIMITER $$
 DROP FUNCTION IF EXISTS calc_queue_idle$$
 CREATE FUNCTION calc_queue_idle(UNIT_ID INT, BEGIN_TIME_VAR DATETIME, END_TIME_VAR DATETIME)
 RETURNS TIME
 DETERMINISTIC
 READS SQL DATA
 BEGIN
 DECLARE queue_idle_time INT;
 DECLARE cursor_users_loop_done INT DEFAULT FALSE;
 DECLARE time_difference_seconds INT;

 DECLARE cur_user VARCHAR(50);
 DECLARE cur_user_start_time DATETIME;
 DECLARE cur_user_end_time DATETIME;
 
 DECLARE last_user VARCHAR(50);
 DECLARE last_user_end_time DATETIME;

 DECLARE cursor_users CURSOR FOR
 		SELECT
		    T.CARD_ID1 as USER,
 		    T.START_TIME,
          T.LOG_RTC AS END_TIME
		FROM trans T
		WHERE
			T.LOG_RTC >= BEGIN_TIME_VAR AND T.LOG_RTC < END_TIME_VAR
		   AND T.VOLUME_RELEASED IS NOT NULL
		   AND T.UNIT_ID = UNIT_ID
		ORDER BY T.LOG_RTC;

 DECLARE CONTINUE HANDLER FOR NOT FOUND SET cursor_users_loop_done = TRUE;

 SET queue_idle_time = 0;
 OPEN cursor_users;
 cursor_users_loop: LOOP
    
    FETCH cursor_users INTO cur_user, cur_user_start_time, cur_user_end_time;

    IF cursor_users_loop_done THEN
      LEAVE cursor_users_loop;
    END IF;
    
    IF last_user IS NOT NULL AND cur_user <> last_user THEN
        SET time_difference_seconds = TIMESTAMPDIFF(SECOND, last_user_end_time, cur_user_start_time);
        SET queue_idle_time = queue_idle_time + time_difference_seconds;
--        call dolog(concat("cycle queue_idle_time +", time_difference_seconds));
--        call dolog(concat("cycle queue_idle_time =", queue_idle_time));
    END IF;
    
    SET last_user = cur_user;
    SET last_user_end_time = cur_user_start_time;

    END LOOP;

CLOSE cursor_users;

RETURN SEC_TO_TIME(queue_idle_time);
 			   
END$$
DELIMITER ;