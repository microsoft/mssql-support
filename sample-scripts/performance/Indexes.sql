declare @indexName nvarchar(255)
declare @rowCount int
declare @UsedMB numeric(36, 2)
declare @UnusedMB numeric(36, 2)
declare @TotalMB numeric(36, 2)

if OBJECT_ID('tempdb..#Indexes') is not null
begin
drop table #Indexes
end

create table #Indexes(
Id int primary key identity,
SchemaName nvarchar(255),
TableName nvarchar(255),
IndexName nvarchar(255),
IndexType nvarchar(255),
Avg_fragmentation float,
ActionNeed nvarchar(255),
[RowCount] int,
IndexMB numeric(36,3),
TableUsedMB numeric(36, 3),
TableUnusedMB numeric(36, 3),
TableTotalMB numeric(36, 3),
ReorganizeIndex nvarchar(1000),
ReorganizeTable nvarchar(1000),
RebuildIndex nvarchar(1000),
RebuildTable nvarchar(1000),

)

insert into #Indexes(
SchemaName,
TableName,
IndexName,
IndexType,
Avg_fragmentation ,
ActionNeed,
IndexMB,
ReorganizeIndex,
ReorganizeTable,
RebuildIndex ,
RebuildTable
)

select 
s.name [Schema],
t.name TableName, 
i.name IndexName,
frag.index_type_desc IndexType,
frag.avg_fragmentation_in_percent,

(case
	when frag.avg_fragmentation_in_percent < 5 then 'Nothing'
	when frag.avg_fragmentation_in_percent between 5 and 30 then 'Reorganize'
	when frag.avg_fragmentation_in_percent > 30 then 'Rebuild' end),
cast((frag.page_count * 8.0 / 1024 / 1024) as numeric(36,3)), 

CONCAT('ALTER INDEX [',i.name ,'] ON [', s.name, '].[' , t.name , '] REORGANIZE;') [ReorganizeIndex],
CONCAT('ALTER INDEX ALL ON [', s.name, '].[' , t.name ,'] REORGANIZE;') [ReorganizeAllTable],
CONCAT('ALTER INDEX [', i.name, '] ON [', s.name, '].[' , t.name, '] REBUILD ;') [RebuildIndex],
CONCAT('ALTER INDEX ALL ON [', s.name, '].[' ,  t.name ,'] REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON, ONLINE = ON);') [RebuildTable]

from sys.tables t 
join sys.schemas s on t.schema_id = s.schema_id
join sys.indexes i on t.object_id = i.object_id
join sys.dm_db_index_physical_stats(DB_ID(), null, null, null, null) as frag on frag.object_id = t.object_id and frag.index_id = i.index_id
where t.type = 'U' and frag.alloc_unit_type_desc = 'IN_ROW_DATA'
order by frag.avg_fragmentation_in_percent desc 

declare saitorhan_cls cursor for

SELECT
i.name IndexName,
p.rows AS RowCounts,
CAST(ROUND((SUM(a.used_pages) / 128.00), 2) AS NUMERIC(36, 3)), -- AS Used_MB,
CAST(ROUND((SUM(a.total_pages) - SUM(a.used_pages)) / 128.00, 3) AS NUMERIC(36, 2)),-- AS Unused_MB,
CAST(ROUND((SUM(a.total_pages) / 128.00), 2) AS NUMERIC(36, 3)) --AS Total_MB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
GROUP BY i.name, p.Rows

open saitorhan_cls
fetch next from saitorhan_cls into @indexName, @rowCount, @UsedMB, @UnusedMB, @TotalMB

while @@FETCH_STATUS = 0
begin

update #Indexes set [RowCount] = @rowCount, TableUsedMB = @UsedMB, TableUnusedMB = @UnusedMB, TableTotalMB = @TotalMB where IndexName = @indexName

fetch next from saitorhan_cls into @indexName, @rowCount, @UsedMB, @UnusedMB, @TotalMB
end
close saitorhan_cls
deallocate saitorhan_cls


select * from #Indexes

