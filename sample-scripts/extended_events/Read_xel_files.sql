-- read the extended event data from the file and store it into a table
select * into tbl_fn_xe_read_file 
from sys.fn_xe_file_target_read_file('file_name.xel', null, null, null);
go

-- review the structure of the table and understand the columns
select top 100 * from tbl_fn_xe_read_file
go

-- get a list of all events captured in the XE file
select distinct [object_name], count(*) from tbl_fn_xe_read_file
group by [object_name]
go

-- now extract the events of interest into a seperate table so we can process them and apply transformations quickly
select timestamp_utc, convert(XML, event_data) as event_data into tbl_HadrMsgTypePrimaryProgressMsg
from tbl_fn_xe_read_file
where [object_name] = 'hadr_transport_dump_message'
go

-- review a few records to understand the fields present in the XML document (event, data, actions)
select top 100 * from tbl_HadrMsgTypePrimaryProgressMsg
go

-- start shredding the rows and extract the event, data and actions
SELECT event_data.value('(event/@name)[1]', 'varchar(50)') AS event_name
, event_data.value('(event/@timestamp)[1]', 'varchar(50)') AS [TIMESTAMP]
,event_data.value('(event/data[@name="operation"]/text)[1]','nvarchar(1024)') AS [c_operation]
,event_data.value('(event/data[@name="operation_reason"]/text)[1]','nvarchar(1024)') AS [c_operation_reason]
,event_data.value('(event/data[@name="sequence_number"]/value)[1]','int') AS [c_sequence_number]
,event_data.value('(event/data[@name="acknowledgment_number"]/value)[1]','int') AS [c_acknowledgment_number]
,event_data.value('(event/data[@name="message_type"]/text)[1]','nvarchar(1024)') AS [c_message_type]
,event_data.value('(event/data[@name="message_log_id"]/value)[1]','nvarchar(1024)') AS c_message_log_id
,event_data.value('(event/data[@name="availability_group_id"]/value)[1]','nvarchar(1024)') AS c_availability_group_id
,event_data.value('(event/data[@name="local_availability_replica_id"]/value)[1]','nvarchar(1024)') AS c_local_availability_replica_id
,event_data.value('(event/data[@name="target_availability_replica_id"]/value)[1]','nvarchar(1024)') AS c_target_availability_replica_id
,event_data.value('(event/data[@name="connection_session_id"]/value)[1]','nvarchar(1024)') AS c_connection_session_id
,event_data.value('(event/data[@name="database_replica_id"]/value)[1]','nvarchar(1024)') AS c_database_replica_id
,event_data.value('(event/action[@name="session_id"]/value)[1]','int') AS a_session_id
,event_data.value('(event/action[@name="system_thread_id"]/value)[1]','int') AS a_system_thread_id
INTO tbl_HadrMsgTypePrimaryProgressMsg_shred
FROM tbl_HadrMsgTypePrimaryProgressMsg AS evts
GO

-- get aggregate information about the type of events
select [c_message_type], [c_operation], [c_operation_reason], count(*) as Event_Count
from tbl_HadrMsgTypePrimaryProgressMsg_shred where c_message_type = 'HadrMsgTypePrimaryProgressMsg'
group by [c_message_type], [c_operation], [c_operation_reason]
order by [c_message_type], [c_operation], [c_operation_reason]
go

-- review a sample of the rows
select top 100 *
from tbl_HadrMsgTypePrimaryProgressMsg_shred
where [c_message_type] = 'HadrMsgTypePrimaryProgressMsg'
go
