
-- create the SQL login on the primary replica
USE [master]
GO
CREATE LOGIN [TestLogin] WITH PASSWORD=N'<YourPassword>', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

-- extract the password hash and sid for the login you created now
SELECT CAST( LOGINPROPERTY( name, 'PasswordHash' ) AS varbinary (256) ) as [Hash], [sid] FROM sys.server_principals WHERE name = 'TestLogin'
GO
-- replace the hash and sid in this create login statement
CREATE LOGIN [TestLogin] WITH PASSWORD = <YourPasswordHash> HASHED, SID = <YourSID>, DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
-- take this create login statement and execute it on all secondary replicas which are associated to this availability group

-- execute this on the primary replica to create user and map to the login
USE [db1]
GO
CREATE USER [TestLogin] FOR LOGIN [TestLogin]
GO
USE [db1]
GO
ALTER ROLE [db_datareader] ADD MEMBER [TestLogin]
GO
