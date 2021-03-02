-- =============================================  
-- Author: Joseph Pilov
-- Create date: 03-2017
-- Description: Retrieve space usage by database
-- ============================================= 

SELECT sum(size/128) size_mb, db_name(database_id) dbname 
FROM sys.master_files
GROUP BY database_id
ORDER BY size_mb DESC