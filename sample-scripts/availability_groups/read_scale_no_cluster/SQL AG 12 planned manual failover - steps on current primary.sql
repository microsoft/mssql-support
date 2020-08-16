-- Make the current primary replica SYNCHRONOUS_COMMIT
ALTER AVAILABILITY GROUP [ag1] 
     MODIFY REPLICA ON N'ag-node001' 
     WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);
GO

-- Make the target secondary replica SYNCHRONOUS_COMMIT
ALTER AVAILABILITY GROUP [ag1] 
     MODIFY REPLICA ON N'ag-node001' 
     WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);
GO

-- check synchronization status
SELECT ag.name, 
   drs.database_id, 
   drs.group_id, 
   drs.replica_id, 
   drs.synchronization_state_desc, 
   ag.sequence_number
FROM sys.dm_hadr_database_replica_states drs, sys.availability_groups ag
WHERE drs.group_id = ag.group_id
GO

-- set availability group attributes needed for failover
ALTER AVAILABILITY GROUP [ag1] 
     SET (REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 1);
GO

-- take the availability group offline in current primary replica
ALTER AVAILABILITY GROUP [ag1] OFFLINE
GO

-- now perform the failover operations on the target secondary

-- set the old primary to secondary replica
ALTER AVAILABILITY GROUP [ag1] 
     SET (ROLE = SECONDARY);
GO

-- resume data movement
ALTER DATABASE [db1]
     SET HADR RESUME
GO

-- last two steps need to be done on all secondary replicas after the failover operation to resume data movement
