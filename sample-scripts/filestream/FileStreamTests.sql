-- enable file stream access configuration
EXEC sp_configure 'filestream_access_level' , 2
GO
RECONFIGURE WITH OVERRIDE
GO

-- create database with filestream filegroup
-- change the file locations as appropriate
CREATE DATABASE myDb1
ON
PRIMARY (NAME = myDb1_data, FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\myDb1_data.mdf'),
FILEGROUP FileStreamGroup1 CONTAINS FILESTREAM (NAME = myDb1FSFG1, FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\filestream\myDb1_FSFG1')
LOG ON (NAME = myDb1_Log, FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\myDb1_log.ldf')
GO

USE myDb1
GO
-- create table that will use filestream containers
CREATE TABLE tbl_test1 ([Id] [uniqueidentifier] ROWGUIDCOL NOT NULL UNIQUE, [SerialNumber] int, [Chart] varbinary(MAX) FILESTREAM NULL)
GO

-- store data
INSERT INTO tbl_test1 VALUES (newid(), 1 , CAST('this is filestream info' as varbinary(MAX)))
GO
SELECT * FROM tbl_test1
GO
