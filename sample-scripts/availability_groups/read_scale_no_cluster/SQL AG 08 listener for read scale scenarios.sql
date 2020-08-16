USE [master]
GO

-- remove listener that exists previously
ALTER AVAILABILITY GROUP [ag1]
REMOVE LISTENER N'ag-node000';
GO

-- create listener that maps to the listener of the primary replica IP to use for read-routing
ALTER AVAILABILITY GROUP [ag1]
ADD LISTENER N'ag-node000' (
WITH IP
((N'10.0.0.4', N'255.255.240.0')
)
, PORT=2433);
GO
