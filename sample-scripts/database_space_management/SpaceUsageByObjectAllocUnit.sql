-- =============================================  
-- Author: Joseph Pilov
-- Create date: 03-2017
-- Description: Retrieve space usage by object and type of allocation unit
-- ============================================= 


SELECT
  t.object_id,
  OBJECT_NAME(t.object_id) ObjectName,
  sum(u.total_pages) * 8 Total_Reserved_kb,
  sum(u.used_pages) * 8 Used_Space_kb,
  u.type_desc,
  max(p.rows) RowsCount
FROM
  sys.allocation_units u
  join sys.partitions p on u.container_id = p.hobt_id
  join sys.tables t on p.object_id = t.object_id
GROUP BY
  t.object_id,
  OBJECT_NAME(t.object_id),
  u.type_desc
ORDER BY
  Used_Space_kb desc,
  ObjectName