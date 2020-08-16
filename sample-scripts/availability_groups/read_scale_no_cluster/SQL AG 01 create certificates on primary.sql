-- create certificate that will be used for endpoint authentication
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'YourPassword';
GO
CREATE CERTIFICATE dbm_certificate WITH SUBJECT = 'dbm';
GO
BACKUP CERTIFICATE dbm_certificate
   TO FILE = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\dbm_certificate.cer'
   WITH PRIVATE KEY (
           FILE = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\dbm_certificate.pvk',
           ENCRYPTION BY PASSWORD = 'YourPassword'
       );
GO

-- copy the .cer and .pck file to all replicas that need to communicate and authenticate with this replica endpoint