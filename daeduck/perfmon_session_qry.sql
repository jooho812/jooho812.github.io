




-- 임시테이블 생성
create table #session_info 
(
   dbid int,
   objectid int,
   number int,
   encrypted int,
   text nvarchar(max)
);

-- perfmon kpid 조회
  select * 
  from sys.sysprocesses
  where kpid = 1696


-- 해당 spid 쿼리 조회
insert into #session_info
SELECT t.*
FROM sys.dm_exec_requests AS r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
WHERE session_id = (select spid from sys.sysprocesses where kpid = 1052) -- modify this value with your actual spid


select * 
from #session_info

dbcc inputbuffer(73)


