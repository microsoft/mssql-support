-- join the secondary replica to the availability group
ALTER AVAILABILITY GROUP [ag1] JOIN WITH (CLUSTER_TYPE = NONE);
GO		 
ALTER AVAILABILITY GROUP [ag1] GRANT CREATE ANY DATABASE;
GO

-- check the status of the database in the availability group
SELECT * FROM sys.databases WHERE name = 'db1';
GO
SELECT DB_NAME(database_id) AS 'database', synchronization_state_desc FROM sys.dm_hadr_database_replica_states;
GO
