-- ============================================================================
-- - Application role access to server information - UseAppRoleToViewServerInfo.sql
--
--
--  This code is companion code that shows an example of application role access
--  to server information by using a certificate-signed procedure.
--
-- ============================================================================

USE master
GO

CREATE DATABASE approle_db ;
GO

CREATE LOGIN some_login WITH PASSWORD = 'SomePa$$word!' ;
GO

USE approle_db
GO

CREATE USER some_user FOR LOGIN some_login
GO

CREATE APPLICATION ROLE an_approle WITH PASSWORD = 'SomeAppRolePa$$word!' ;
GO

---------------------------------------------------------------------
-- This section shows how to use a certificate to authenticate
-- a signed stored procedure.
---------------------------------------------------------------------

CREATE LOGIN execute_as_login WITH PASSWORD = 'SomePa$$word!' ;
GO

USE master
GO

GRANT VIEW ANY DEFINITION TO execute_as_login ;
GRANT VIEW SERVER STATE   TO execute_as_login ;
GO

USE approle_db
GO

CREATE USER execute_as_user FOR LOGIN execute_as_login ;
GO

--
-- You must use EXECUTE AS 'execute_as_user' here because the application role
-- does not have a server identity. The application role cannot use
-- the certificate permissions on the server.  Therefore, you
-- need a new execution context to which you can grant
-- the needed VIEW* permissions.
--
CREATE PROC usp_access_server_system_tables
  WITH EXECUTE AS 'execute_as_user'
AS
  SELECT * FROM master.dbo.syslogins    ;
  SELECT * FROM master.dbo.sysprocesses ;
GO

GRANT EXECUTE ON usp_access_server_system_tables TO an_approle ;
GO

CREATE CERTIFICATE signing_cert ENCRYPTION BY PASSWORD = 'SomeCertPa$$word'
    WITH SUBJECT  = 'Signing Cert' ;
GO

BACKUP CERTIFICATE signing_cert TO FILE = 'signing_cert.cer' ;
GO

ADD SIGNATURE TO usp_access_server_system_tables
    BY CERTIFICATE signing_cert WITH PASSWORD = 'SomeCertPa$$word' ;
GO

---------------------------------------------------------------------
-- We must create a copy of the signing certificate in the target
-- database. In this case, the target database is the master database.
-- This copy of the signing certificate can vouch
-- for the execution contexts that enter this database from the
-- signed procedure.
---------------------------------------------------------------------
USE master
GO

CREATE CERTIFICATE signing_cert FROM FILE = 'signing_cert.cer' ;
GO

--
-- Because the VIEW* permissions in question are server-level permissions,
-- we need an AUTHENTICATE SERVER on a login-mapped certificate.
--
CREATE LOGIN signing_cert_login FROM CERTIFICATE signing_cert ;
GO

GRANT AUTHENTICATE SERVER TO signing_cert_login
GO


---------------------------------------------------------------------
-- Now you can open a new connection as "some_login" and
-- set the application role. Then, call the "usp_access_server_system_tables"
-- procedure, and obtain verification that you can access server-level information
-- when the application role-based application runs.  




--------------------------------------------------
-- Connect as some_login (open a new connection) 
--------------------------------------------------


USE approle_db
GO
EXEC sp_setapprole 'an_approle', 'SomeAppRolePa$$word!'
GO
EXEC usp_access_server_system_tables
GO



---------------------------------------------------------------------


---------------------------------------------------------------------
-- Go back to original connection to ...
-- Clean up after the procedure.

---------------------------------------------------------------------


USE master
GO
DROP DATABASE approle_db ;
GO

DROP LOGIN some_login;
GO

DROP LOGIN execute_as_login;
GO

DROP LOGIN signing_cert_login ;
GO

DROP CERTIFICATE signing_cert;
GO

--
-- Make sure to delete the certificate file. For example, delete
-- C:\Program Files\Microsoft SQL Server\MSSQL.<some_instance>\MSSQL\Data\signing_cert.cer
--

