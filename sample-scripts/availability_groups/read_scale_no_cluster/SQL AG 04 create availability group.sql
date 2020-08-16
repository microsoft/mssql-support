-- create the availability group with the replicas specified
CREATE AVAILABILITY GROUP [ag1]
     WITH (CLUSTER_TYPE = NONE)
     FOR REPLICA ON
         N'ag-node000' 
 	      	WITH (
  	       ENDPOINT_URL = N'tcp://ag-node000:5022',
  	       AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,
  	       FAILOVER_MODE = MANUAL,
  	       SEEDING_MODE = AUTOMATIC,
           SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL)
  	       ),
         N'ag-node001' 
  	    WITH ( 
  	       ENDPOINT_URL = N'tcp://ag-node001:5022', 
  	       AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,
  	       FAILOVER_MODE = MANUAL,
  	       SEEDING_MODE = AUTOMATIC,
           SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL)
		   ),
         N'ag-node002' 
  	    WITH ( 
  	       ENDPOINT_URL = N'tcp://ag-node002:5022', 
  	       AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,
  	       FAILOVER_MODE = MANUAL,
  	       SEEDING_MODE = AUTOMATIC,
           SECONDARY_ROLE (ALLOW_CONNECTIONS = ALL)
  	       );
GO
ALTER AVAILABILITY GROUP [ag1] GRANT CREATE ANY DATABASE;
GO

-- if you want to add more replicas later
ALTER AVAILABILITY GROUP [ag1] ADD REPLICA ON 'ag-node003'
  	    WITH ( 
  	       ENDPOINT_URL = N'tcp://ag-node003:5022', 
  	       AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,
  	       FAILOVER_MODE = MANUAL,
  	       SEEDING_MODE = AUTOMATIC
  	       );
GO
