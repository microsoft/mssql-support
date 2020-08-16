
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
-- make sure the replica to be promoted is in synchronized status

-- perform failover
ALTER AVAILABILITY GROUP ag1 FORCE_FAILOVER_ALLOW_DATA_LOSS
GO

-- on the old primary set its status to secondary

-- reset availability group attributes to the ones before failover
ALTER AVAILABILITY GROUP [ag1] 
     SET (REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 0);
GO

ALTER AVAILABILITY GROUP [ag1] 
     MODIFY REPLICA ON N'ag-node001' 
     WITH (AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT);
GO
ALTER AVAILABILITY GROUP [ag1] 
     MODIFY REPLICA ON N'ag-node000' 
     WITH (AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT);
GO

-- make sure to recreate the listener for the new primary to enable read-only routing