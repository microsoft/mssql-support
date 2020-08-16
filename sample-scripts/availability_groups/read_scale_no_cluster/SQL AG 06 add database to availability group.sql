-- create database
CREATE DATABASE [db1];
GO
ALTER DATABASE [db1] SET RECOVERY FULL;
GO
BACKUP DATABASE [db1] 
   TO DISK = N'db1.bak';
GO

-- add the database to the availability group
ALTER AVAILABILITY GROUP [ag1] ADD DATABASE [db1];
GO

-- check the status of this database in the availability group
SELECT * FROM sys.databases WHERE name = 'db1';
GO
SELECT DB_NAME(database_id) AS 'database', synchronization_state_desc FROM sys.dm_hadr_database_replica_states;
GO
