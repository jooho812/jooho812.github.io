

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




-- system_health Xevent xel, xem ���Ͽ��� wait_info ���ڵ� ��ȸ
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



-- system_health Xevent xel, xem ���Ͽ��� deadlock ���ڵ� ��ȸ
-- Deadlock Report -> xml Ŭ�� �� xdl Ȯ���ڷ� ���� �� ����
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




-- system_health Xevent xel, xem ���Ͽ��� worker thread ���ڵ� ��ȸ
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
Component_State : �۾��� �����尡 �ǰų� ö���ϰ� Ȱ�� �� ���̶�� ������ �����մϴ�.(warning ���� �Ǿ��ִ��� Ȯ��)
MaxWorkers : �ִ� �۾��� ������ ���� ���� ���� �κп� ���� �� ���μ��� ���� ���� �ٸ��ϴ�. �� �������� 8 ���� ���μ����� �ֽ��ϴ�. ���� �ִ� �۾��� ������ 576 ���� �����մϴ�.
Workercreated : �� ���ڴ� ���� ���α׷����� ���� �۾��� �����带 �����ݴϴ�.
oldestPendingTaskWaitingTime : �������� �۾��� �ְ� �۾��� �����带 �����ϰ��ִ� ��� ���� ������ ���� �۾� ���� ǥ���մϴ�. �̻������δ� ���� 0�̾���մϴ�.
�������� �۾� : ���� �������� �۾� ���� ǥ���ϸ� �������� ȯ���� ��� �ش� ���� 0�̾���մϴ�.
**/



