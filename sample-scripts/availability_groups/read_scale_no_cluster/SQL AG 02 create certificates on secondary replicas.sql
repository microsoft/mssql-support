-- create the same certificate on all replicas that match the one present on the primary 
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'YourPassword';
GO
CREATE CERTIFICATE dbm_certificate
    FROM FILE = 'C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\DATA\dbm_certificate.cer'
    WITH PRIVATE KEY (
    FILE = 'C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\DATA\dbm_certificate.pvk',
    DECRYPTION BY PASSWORD = 'YourPassword'
            );
GO

