-- create the endpoint on all replicas after the certificates are created
CREATE ENDPOINT [Hadr_endpoint]
    AS TCP (LISTENER_PORT = 5022)
    FOR DATABASE_MIRRORING (
	    ROLE = ALL,
	    AUTHENTICATION = CERTIFICATE dbm_certificate,
		ENCRYPTION = REQUIRED ALGORITHM AES
		);
GO
ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED;
GO

-- make sure the port specified for the endpoint is opened for the replicas to communicate