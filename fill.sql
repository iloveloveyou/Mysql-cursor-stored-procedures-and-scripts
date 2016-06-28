USE sample;


DELIMITER $$
 DROP PROCEDURE IF EXISTS fill_trans_table$$
 CREATE PROCEDURE fill_trans_table(BEGIN_TIME_VAR DATETIME, END_TIME_VAR DATETIME)
 -- DETERMINISTIC
 -- WRITES SQL DATA
 BEGIN

 DECLARE cur_trans_id INT;
 DECLARE cur_unit_id INT;
 DECLARE cur_user VARCHAR(50);
 DECLARE cur_end_time DATETIME;
 DECLARE cur_volume_released DECIMAL(20,2);

 DECLARE last_user VARCHAR(50);
 DECLARE last_end_time DATETIME;
 DECLARE last_volume_released DECIMAL(20,2);
 DECLARE last_flow_rate_calc DECIMAL(9,5);

 DECLARE flow_rate_calc DECIMAL(9,5);
 DECLARE tapping_time_calc INT;
 DECLARE start_time_calc DATETIME;
 DECLARE idle_time_calc INT;
  DECLARE queue_length_calc INT;

 DECLARE calc_method INT;
 DECLARE const_flow_rate DECIMAL(9,5) DEFAULT 30 / 60; -- constant flow rate 30L/min = 0.5L/s

 DECLARE loop_done INT DEFAULT FALSE;
 DECLARE cursor_trans CURSOR FOR
        SELECT
            T.TRANS_ID,
            T.UNIT_ID,
            T.CARD_ID1 as USER,
          T.LOG_RTC as END_TIME,
          T.VOLUME_RELEASED
        FROM trans T
        WHERE
            T.LOG_RTC >= BEGIN_TIME_VAR AND T.LOG_RTC < END_TIME_VAR
           AND T.VOLUME_RELEASED IS NOT NULL
        ORDER BY T.UNIT_ID, T.LOG_RTC;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET loop_done = TRUE;

 -- call dolog(concat("IN BEGIN_TIME_VAR=", BEGIN_TIME_VAR, " END_TIME_VAR=", END_TIME_VAR));

 OPEN cursor_trans;
 cursor_trans_loop: LOOP

 FETCH cursor_trans INTO cur_trans_id, cur_unit_id, cur_user, cur_end_time, cur_volume_released;

 IF loop_done THEN
   LEAVE cursor_trans_loop;
 END IF;

 IF cur_volume_released >= 10  THEN

   IF last_user IS NOT NULL AND last_user = cur_user THEN

      SET calc_method = 2;

   ELSE IF  last_user IS NOT NULL AND last_user <> cur_user THEN

      SET calc_method = 3;

   ELSE

      SET calc_method = 1;
   END IF;
   END IF;

 ELSE IF cur_volume_released < 10  THEN

    IF last_user IS NULL THEN

      SET calc_method = 1;
   ELSE
      SET calc_method = 3;
   END IF;

 END IF;
 END IF;


 call dolog(concat("loop cur_trans_id=", cur_trans_id," cur_unit_id=", cur_unit_id, " cur_user=", cur_user," cur_end_time=", cur_end_time, " cur_volume_released=", cur_volume_released, " calc_method=", calc_method));

 IF calc_method = 1 THEN -- constant flow_rate
   SET flow_rate_calc = 30;
   SET tapping_time_calc = cur_volume_released / flow_rate_calc;
   SET start_time_calc = SUBTIME(cur_end_time, SEC_TO_TIME(tapping_time_calc));
   -- call dolog(concat("calc flow_rate_calc=", flow_rate_calc," tapping_time_calc=", tapping_time_calc, " start_time_calc=", start_time_calc));
   UPDATE trans
      SET FLOW_RATE = flow_rate_calc,
          TAPPING_TIME = SEC_TO_TIME(tapping_time_calc),
            START_TIME = start_time_calc
      WHERE TRANS_ID = cur_trans_id;

 ELSEIF calc_method = 2 THEN -- calc flow_rate based on volume_released
   -- tapping_time_calc = volume/time
    -- flow_rate_calc = diff(curr_endtime,prev_endtime)
   SET tapping_time_calc = TIMESTAMPDIFF(SECOND, last_end_time, cur_end_time);
   SET flow_rate_calc = cur_volume_released * 60/ tapping_time_calc ;
   SET start_time_calc = SUBTIME(cur_end_time, SEC_TO_TIME(tapping_time_calc));

   -- call dolog(concat("calc flow_rate_calc=", flow_rate_calc," tapping_time_calc=", tapping_time_calc, " start_time_calc=", start_time_calc));
   UPDATE trans
      SET FLOW_RATE = flow_rate_calc,
          TAPPING_TIME = SEC_TO_TIME(tapping_time_calc),
            START_TIME = start_time_calc
      WHERE TRANS_ID = cur_trans_id;

 ELSEIF calc_method = 3 THEN -- use last flow_rate
   SET flow_rate_calc = last_flow_rate_calc;
   SET tapping_time_calc = cur_volume_released * 60/ flow_rate_calc ;
   SET start_time_calc = SUBTIME(cur_end_time, SEC_TO_TIME(tapping_time_calc));
   -- call dolog(concat("calc flow_rate_calc=", flow_rate_calc," tapping_time_calc=", tapping_time_calc, " start_time_calc=", start_time_calc));
   UPDATE trans
      SET FLOW_RATE = flow_rate_calc,
          TAPPING_TIME = SEC_TO_TIME(tapping_time_calc),
            START_TIME = start_time_calc
      WHERE TRANS_ID = cur_trans_id;

 END IF;

 IF last_user IS NOT NULL AND last_user <> cur_user THEN -- if card is changed
 SET idle_time_calc = TIMESTAMPDIFF(SECOND, last_end_time, start_time_calc);
   -- call dolog(concat("idle cur_trans_id=", cur_trans_id, " last_end_time=", last_end_time," start_time_calc=", start_time_calc, " idle_time_calc=", idle_time_calc));
    ELSE
   SET idle_time_calc = null;


 END IF;

  IF MINUTE(idle_time_calc) < 2 AND MINUTE(idle_time_calc) > 0 THEN
    SET queue_length_calc = 1;
    ELSE
    SET queue_length_calc = NULL;
   END IF;



  UPDATE trans
   SET idle_time = SEC_TO_TIME(idle_time_calc),
   QUEUE_LENGTH = queue_length_calc

   WHERE TRANS_ID = cur_trans_id;




 SET last_user = cur_user;
 SET last_flow_rate_calc = flow_rate_calc;
 SET last_end_time = cur_end_time;

 END LOOP;

 CLOSE cursor_trans;

END$$
DELIMITER ;



DELIMITER $$
 DROP PROCEDURE IF EXISTS fill_full_trans_table$$
 CREATE PROCEDURE fill_full_trans_table()
 BEGIN
 DECLARE min_time DATETIME;
 DECLARE max_time DATETIME;

 SELECT MIN(LOG_RTC) INTO min_time FROM trans;
 SELECT MAX(LOG_RTC) INTO max_time FROM trans;

 call fill_trans_table(min_time, max_time);

END$$
DELIMITER ;
