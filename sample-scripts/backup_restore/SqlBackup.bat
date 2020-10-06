REM Example1: Full backups of all databases in the local named instance of SQLEXPRESS by using Windows Authentication 
sqlcmd -S .\EXPRESS –E -Q "EXEC sp_BackupDatabases @backupLocation='D:\SQLBackups\', @backupType='F'"  

REM Example2: Differential backups of all databases in the local named instance of SQLEXPRESS by using a SQLLogin and its password 
REM Note: The SQLLogin should have at least the Backup Operator role in SQL Server. 
REM sqlcmd -U <YourSQLLogin>SQLLogin -P password <StrongPassword> -S .\SQLEXPRESS -Q "EXEC sp_BackupDatabases  @backupLocation ='D:\SQLBackups', @BackupType=’D’" 

REM Example 3: Log backups of all databases in local named instance of SQLEXPRESS by using Windows Authentication 
REM sqlcmd -S .\SQLEXPRESS -E -Q "EXEC sp_BackupDatabases @backupLocation='D:\SQLBackups\',@backupType='L'" 

REM Example 4: Full backups of the database USERDB in the local named instance of SQLEXPRESS by using Windows Authentication 
REM sqlcmd -S .\SQLEXPRESS -E -Q "EXEC sp_BackupDatabases @backupLocation='D:\SQLBackups\', @databaseName=’USERDB’, @backupType='F'" 