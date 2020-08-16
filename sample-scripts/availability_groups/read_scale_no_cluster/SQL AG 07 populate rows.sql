USE [db1]
GO
-- create a table
CREATE TABLE tbl1 ( col1 int , col2 char(4000) )
GO
-- populate rows
INSERT INTO tbl1 VALUES ( RAND()*100 ,'abc')
GO 10
-- check the values
SELECT * FROM tbl1
GO
-- clean the table
TRUNCATE TABLE tbl1
GO
