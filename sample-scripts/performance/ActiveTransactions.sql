
-- =============================================  
-- Author: Joseph Pilov
-- Create date: 03-2017
-- Description: Get info about active transactions on the system 
-- ============================================= 

--active trans
SELECT
  getdate() as now,
  DATEDIFF(SECOND, transaction_begin_time, GETDATE()) as tran_elapsed_time_seconds,
  *
FROM
  sys.dm_tran_active_transactions at
  JOIN sys.dm_tran_session_transactions st ON st.transaction_id = at.transaction_id
  INNER JOIN sys.sysprocesses sp ON st.session_id = sp.spid 
    CROSS APPLY sys.dm_exec_sql_text(sql_handle) txt
ORDER BY
  tran_elapsed_time_seconds DESC
  
  
  
--Active Row versioning transactions
SELECT
   GETDATE() AS runtime,
   a.*,
   b.kpid,
   b.blocked,
   b.lastwaittype,
   b.waitresource,
   db_name(b.dbid) as database_name,
   b.cpu,
   b.physical_io,
   b.memusage,
   b.login_time,
   b.last_batch,
   b.open_tran,
   b.status,
   b.hostname,
   b.program_name,
   b.cmd,
   b.loginame,
   request_id,
   c.* 
FROM
   sys.dm_tran_active_snapshot_database_transactions a 
   INNER JOIN sys.sysprocesses b 
      ON a.session_id = b.spid 
		CROSS APPLY sys.dm_exec_sql_text(sql_handle) c
