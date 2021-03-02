-- =============================================  
-- Author: Joseph Pilov
-- Create date: 03-2017
-- Description: Retrieve space usage by object and Index
-- ============================================= 

SELECT 
 t.NAME AS TableName,
 i.name AS indexName,
 SUM(p.rows) AS RowCounts,
 SUM(a.total_pages) AS TotalPages, 
 SUM(a.used_pages) AS UsedPages, 
 SUM(a.data_pages) AS DataPages,
 (SUM(a.total_pages) * 8) / 1024 AS TotalSpaceMB, 
 (SUM(a.used_pages) * 8) / 1024 AS UsedSpaceMB, 
 (SUM(a.data_pages) * 8) / 1024 AS DataSpaceMB
FROM 
 sys.tables t
INNER JOIN  
 sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
 sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
 sys.allocation_units a ON p.partition_id = a.container_id
WHERE 
 i.index_id > 0
GROUP BY 
 t.NAME, i.object_id, i.index_id, i.name 
ORDER BY 
 OBJECT_NAME(i.object_id) 

