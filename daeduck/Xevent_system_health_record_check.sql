

-- XEVENT LIST
    SELECT obj1.name        AS [XEvent-name]
         , col2.name        AS [XEvent-column]
         , obj1.description AS [Descr-name]
         , col2.description AS [Descr-column]
      FROM sys.dm_xe_objects        AS obj1
INNER JOIN sys.dm_xe_object_columns AS col2
        ON col2.object_name = obj1.name
  ORDER BY obj1.name
         , col2.name




-- system_health Xevent xel, xem 파일에서 wait_info 레코드 조회
SELECT
    xed.event_data.value('(@timestamp)[1]', 'datetime2') AS [timestamp],
    xed.event_data.value('(data[@name="wait_type"]/text)[1]', 'varchar(25)') AS wait_type, 
    xed.event_data.value('(data[@name="duration"]/value)[1]', 'int')/1000/60.0 AS wait_time_in_min, 
    xed.event_data.value('(action[@name="sql_text"]/value)[1]', 'varchar(max)') AS sql_text, 
    xed.event_data.value('(action[@name="session_id"]/value)[1]', 'varchar(25)') AS session_id, 
    xData.Event_Data,
    fx.object_name
FROM sys.fn_xe_file_target_read_file ('system_health*.xel','system_health*.xem',null,null) fx
CROSS APPLY (SELECT CAST(fx.event_data AS XML) AS Event_Data) AS xData
CROSS APPLY xData.Event_Data.nodes('//event') AS xed (event_data)
WHERE fx.object_name = 'wait_info';



-- system_health Xevent xel, xem 파일에서 deadlock 레코드 조회
-- Deadlock Report -> xml 클릭 후 xdl 확장자로 저장 후 열기
SELECT
    xed.event_data.value('(@timestamp)[1]', 'datetime2') AS [timestamp],
    xed.event_data.value('(data[@name="wait_type"]/text)[1]', 'varchar(25)') AS wait_type, 
    xed.event_data.value('(data[@name="duration"]/value)[1]', 'int')/1000/60.0 AS wait_time_in_min, 
    xed.event_data.value('(action[@name="sql_text"]/value)[1]', 'varchar(max)') AS sql_text, 
    xed.event_data.value('(action[@name="session_id"]/value)[1]', 'varchar(25)') AS session_id, 
    xData.Event_Data,
	xed.event_data.query('/event/data/value/child::*') DeadlockReport,
    fx.object_name
FROM sys.fn_xe_file_target_read_file ('system_health*.xel','system_health*.xem',null,null) fx
CROSS APPLY (SELECT CAST(fx.event_data AS XML) AS Event_Data) AS xData
CROSS APPLY xData.Event_Data.nodes('//event') AS xed (event_data)
WHERE fx.object_name = 'xml_deadlock_report';




-- system_health Xevent xel, xem 파일에서 worker thread 레코드 조회
with worker_thread_state
as
(
SELECT xed.event_data.value('(@timestamp)[1]', 'datetime') AS utctimestamp, 
       DATEADD(hh, +5.30, xed.event_data.value('(@timestamp)[1]', 'datetime')) AS [timestamp], 
       xed.event_data.value('(data[@name="component"]/text)[1]', 'varchar(100)') AS [component_name], 
       xed.event_data.value('(data[@name="state"]/text)[1]', 'varchar(100)') AS [component_state], 
       xed.event_data.value('(data[@name="data"]/value/queryProcessing/@maxWorkers)[1]', 'int') AS maxworkers, 
       xed.event_data.value('(data[@name="data"]/value/queryProcessing/@workersCreated)[1]', 'int') AS workerscreated, 
       xed.event_data.value('(data[@name="data"]/value/queryProcessing/@workersIdle)[1]', 'int') AS workersIdle, 
       xed.event_data.value('(data[@name="data"]/value/queryProcessing/@tasksCompletedWithinInterval)[1]', 'int') AS tasksCompletedWithinInterval, 
       xed.event_data.value('(data[@name="data"]/value/queryProcessing/@oldestPendingTaskWaitingTime)[1]', 'bigint') AS oldestPendingTaskWaitingTime, 
       xed.event_data.value('(data[@name="data"]/value/queryProcessing/@pendingTasks)[1]', 'int') AS pendingTasks,
    fx.object_name
FROM sys.fn_xe_file_target_read_file ('system_health*.xel','system_health*.xem',null,null) fx
CROSS APPLY (SELECT CAST(fx.event_data AS XML) AS Event_Data) AS xData
CROSS APPLY xData.Event_Data.nodes('//event') AS xed (event_data)
WHERE fx.object_name = 'sp_server_diagnostics_component_result'
)
select * 
from worker_thread_state
where component_name = 'QUERY_PROCESSING';

/**
Component_State : 작업자 스레드가 옳거나 철저하게 활용 될 것이라는 정보를 제공합니다.(warning 으로 되어있는지 확인)
MaxWorkers : 최대 작업자 스레드 값은 문서 시작 부분에 정의 된 프로세서 수에 따라 다릅니다. 제 예에서는 8 개의 프로세서가 있습니다. 따라서 최대 작업자 스레드 576 개를 제공합니다.
Workercreated : 이 숫자는 응용 프로그램에서 만든 작업자 스레드를 보여줍니다.
oldestPendingTaskWaitingTime : 보류중인 작업이 있고 작업자 스레드를 보유하고있는 경우 가장 오래된 보류 작업 수를 표시합니다. 이상적으로는 값이 0이어야합니다.
보류중인 작업 : 또한 보류중인 작업 수를 표시하며 정상적인 환경의 경우 해당 값도 0이어야합니다.
**/



 select OBJECT_NAME(s.object_id) AS object_name
      , COL_NAME(sc.object_id, sc.column_id) AS column_name
      , s.name AS statistics_name 
      , h.* from sys.stats s
 INNER JOIN sys.stats_columns AS sc  
    ON s.stats_id = sc.stats_id AND s.object_id = sc.object_id  
 cross apply sys.dm_db_stats_histogram(s.object_id,s.stats_id) h
 where s.object_id = object_id('DD_IOT_COMMUNICATION')
 order by s.object_id, s.name,sc.column_id


