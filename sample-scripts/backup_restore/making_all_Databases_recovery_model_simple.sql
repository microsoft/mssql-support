USE MASTER
DECLARE
@isql VARCHAR(2000),
@dbname VARCHAR(64)

DECLARE c1 CURSOR FOR SELECT NAME FROM MASTER..SYSDATABASES WHERE [name] NOT IN ('master','model','msdb','tempdb','ReportServer','ReportServerTempDB')
OPEN c1
FETCH NEXT FROM c1 INTO @dbname
WHILE @@fetch_status <> -1
    BEGIN
	
    SELECT @isql = 'ALTER DATABASE @dbname SET RECOVERY SIMPLE'
    SELECT @isql = replace(@isql,'@dbname',@dbname)
    PRINT @isql
    EXEC(@isql)

    SELECT @isql='USE @dbname; DBCC SHRINKFILE (N''@dbname_log'' , 0, TRUNCATEONLY)'
    SELECT @isql = replace(@isql,'@dbname',@dbname)
    PRINT  @isql
    EXEC(@isql)

    FETCH NEXT FROM c1 INTO @dbname
    END
CLOSE c1
DEALLOCATE c1