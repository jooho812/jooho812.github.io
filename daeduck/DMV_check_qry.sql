
--1. 저장프로시져별 실행수 뽑기 

select db_name(st.dbid) DBName
,object_schema_name(st.objectid,dbid) SchemaName
,object_name(st.objectid,dbid) StoredProcedure
,sum(qs.execution_count) Execution_count
from sys.dm_exec_cached_plans cp
join sys.dm_exec_query_stats qs on cp.plan_handle=qs.plan_handle
cross apply sys.dm_exec_sql_text(cp.plan_handle)st
where DB_Name(st.dbid) is not null and cp.objtype = 'proc'
group by DB_Name(st.dbid),object_schema_name(objectid,st.dbid),object_name(objectid,st.dbid)
order by sum(qs.execution_count) desc


--2. CPU소모량이 많은 저장프로시져 뽑기

select db_name(st.dbid) DBName
,object_schema_name(st.objectid,dbid) SchemaName
,object_name(st.objectid,dbid) StoredProcedure
,sum(qs.execution_count) Execution_count
,sum(qs.total_worker_time) total_cpu_time
,sum(qs.total_worker_time) / (sum(qs.execution_count) * 1.0) avg_cpu_time
from sys.dm_exec_cached_plans cp join sys.dm_exec_query_stats qs on cp.plan_handle=qs.plan_handle
cross apply sys.dm_exec_sql_text(cp.plan_handle) st
where db_name(st.dbid) is not null and cp.objtype='proc'
group by db_name(st.dbid), object_schema_name(objectid,st.dbid), object_name(objectid,st.dbid)
order by sum(qs.total_worker_time) desc


--3. IO량이 많은 저장프로시져 뽑기

select db_name(st.dbid) DBName
,object_schema_name(objectid,st.dbid) SchemaName
,object_name(objectid,st.dbid) StoredProcedure
,sum(execution_count) execution_count
,sum(qs.total_physical_reads+qs.total_logical_reads+qs.total_logical_writes) total_IO
,sum(qs.total_physical_reads+qs.total_logical_reads+qs.total_logical_writes) / sum
(execution_count) avg_total_IO
,sum(qs.total_physical_reads) total_physical_reads
,sum(qs.total_physical_reads) / (sum(execution_count) * 1.0) avg_physical_read
,sum(qs.total_logical_reads) total_logical_reads
,sum(qs.total_logical_reads) / (sum(execution_count) * 1.0) avg_logical_read
,sum(qs.total_logical_writes) total_logical_writes
,sum(qs.total_logical_writes) / (sum(execution_count) * 1.0) avg_logical_writes
from sys.dm_exec_query_stats qs cross apply sys.dm_exec_sql_text(qs.plan_handle) st
join sys.dm_exec_cached_plans cp on qs.plan_handle = cp.plan_handle
where db_name(st.dbid) is not null and cp.objtype = 'proc'
group by db_name(st.dbid),object_schema_name(objectid,st.dbid), object_name(objectid,st.dbid)
order by sum(qs.total_physical_reads+qs.total_logical_reads+qs.total_logical_writes) desc


--4. 처리시간이 긴 저장프로시져 뽑기

select db_name(st.dbid) DBName
,object_schema_name(objectid,st.dbid) SchemaName
,object_name(objectid,st.dbid) StoredProcedure
,sum(execution_count) execution_count
,sum(qs.total_elapsed_time) total_elapsed_time
,sum(qs.total_elapsed_time) / sum(execution_count) avg_elapsed_time
from sys.dm_exec_query_stats qs cross apply sys.dm_exec_sql_text(qs.plan_handle)st
join sys.dm_exec_cached_plans cp on qs.plan_handle = cp.plan_handle
where db_name(st.dbid) is not null and cp.objtype = 'proc'
group by db_name(st.dbid),object_schema_name(objectid,st.dbid),object_name(objectid,st.dbid)
order by sum(qs.total_elapsed_time) desc
