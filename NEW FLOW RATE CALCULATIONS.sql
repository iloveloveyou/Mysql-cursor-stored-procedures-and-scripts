select CARD_ID1, LOG_RTC, VOLUME_RELEASED, 
timestampdiff(second,prevdatenew,LOG_RTC) AS DIFF,  
SEC_TO_TIME(timestampdiff(second,prevdatenew,LOG_RTC)) AS DIFF1, 
SEC_TO_TIME(VOLUME_RELEASED/(timestampdiff(second,prevdatenew,LOG_RTC))*60) AS Duration

from (
    select CARD_ID1, LOG_RTC,VOLUME_RELEASED, @prevDateNew as prevdatenew, 
      @prevDateNew := LOG_RTC
    from TRANS  where volume_released is not null 
) TRANS  
        JOIN
    UNIT U ON GROUP_ID = U.GROUP_ID
WHERE
    
         U.UNIT_NAME = 'BUSIRO 121'
        AND CAST(LOG_RTC AS DATE) BETWEEN '2015-04-17' AND '2015-04-18'
ORDER BY LOG_RTC ASC;



SELECT
    
     CAST(min(data.START_TIME) as TIME),
    
     calc_queue_idle(data.UNIT_ID, stt.BEGIN_TIME, stt.END_TIME) IDLE
FROM `stat_time_table` stt
JOIN (
	SELECT
	    T.UNIT_ID,
	    T.LOG_RTC,
	    T.START_TIME,
       T.LOG_RTC AS END_TIME
	FROM
	    trans T
	JOIN unit U ON T.UNIT_ID = U.ID
	WHERE
	    1=1
	    AND T.VOLUME_RELEASED IS NOT NULL
	    AND U.UNIT_NAME = 'Busiro 121'
) data ON data.LOG_RTC BETWEEN stt.BEGIN_TIME AND stt.END_TIME
WHERE stt.BEGIN_TIME >= '2015-04-08 00:00:00' AND stt.BEGIN_TIME  < '2015-04-15 00:00:00'
GROUP BY stt.BEGIN_TIME, data.UNIT_ID
ORDER BY stt.BEGIN_TIME ASC
