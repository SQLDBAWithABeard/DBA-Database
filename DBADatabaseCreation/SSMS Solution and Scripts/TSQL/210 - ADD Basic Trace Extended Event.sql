/* This script will create an Extended event session called basic_trace 

AUTHOR Rob Sewell
		10/06/2015 - Created
		Need to add target file location line 35
*/

-- Check


IF EXISTS (select  name from sys.server_event_sessions where name = 'Basic_Trace')
	BEGIN
	 DROP EVENT SESSION [Basic_Trace] ON SERVER;
	END

CREATE EVENT SESSION [Basic_Trace] ON SERVER 
ADD EVENT sqlserver.error_reported(
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.query_hash,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text)
    WHERE ([package0].[greater_than_uint64]([sqlserver].[database_id],(4)) AND [package0].[equal_boolean]([sqlserver].[is_system],(0)))),
ADD EVENT sqlserver.module_end(SET collect_statement=(1)
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.query_hash,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text)
    WHERE ([package0].[greater_than_uint64]([sqlserver].[database_id],(4)) AND [package0].[equal_boolean]([sqlserver].[is_system],(0)))),
ADD EVENT sqlserver.rpc_completed(
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.query_hash,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text)
    WHERE ([package0].[greater_than_uint64]([sqlserver].[database_id],(4)) AND [package0].[equal_boolean]([sqlserver].[is_system],(0)))),
ADD EVENT sqlserver.sp_statement_completed(SET collect_object_name=(1)
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text)
    WHERE ([package0].[greater_than_uint64]([sqlserver].[database_id],(4)) AND [package0].[equal_boolean]([sqlserver].[is_system],(0)))),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.query_hash,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text)
    WHERE ([package0].[greater_than_uint64]([sqlserver].[database_id],(4)) AND [package0].[equal_boolean]([sqlserver].[is_system],(0)))),
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.nt_username,sqlserver.query_hash,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text)
    WHERE ([package0].[greater_than_uint64]([sqlserver].[database_id],(4)) AND [package0].[equal_boolean]([sqlserver].[is_system],(0)))) 
ADD TARGET package0.event_file(SET filename=N'ENTER FILE NAME PATH HERE.xel')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)
GO


