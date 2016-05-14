/*Creates a job to Drop the SPBlitzResults Tables and then Creates a table in the DBA-Admin database and runs SP_Blitz and logs to the table*/

USE [msdb]
GO

 IF EXISTS (SELECT job_id  FROM msdb.dbo.sysjobs_view  WHERE name = N'Log SP_Blitz to table')
EXEC msdb.dbo.sp_delete_job @job_name=N'Log SP_Blitz to table', @delete_unused_schedule=1

/* Check for correct Job Owner*/


DECLARE @JobOwner nvarchar(50)
IF EXISTS (Select name from master.sys.syslogins where name = 'MyDefaultJobOwner')
SET @JobOwner = 'MyDefaultJobOwner'
IF EXISTS (Select name from master.sys.syslogins where name = 'sa')
SET @JobOwner = 'sa'

DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'Log SP_Blitz to table', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'Drops SPBlitzResults Tables and then Creates a table in the DBA-Admin database and runs SP_Blitz and logs to the table', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=@JobOwner , @job_id = @jobId OUTPUT
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'Log SP_Blitz to table', @server_name = N'(local)'
GO


USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Log SP_Blitz to table', @step_name=N'Run SP_Blitz', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @cmd varchar(4000)
declare cmds cursor for 
select ''drop table ['' + Name + '']''
 from sys.tables where name like ''SP_BlitzResults%''

open cmds
while 1=1
begin
    fetch cmds into @cmd
    if @@fetch_status != 0 break
    exec(@cmd)
end
close cmds;
deallocate cmds

DECLARE @destination_table VARCHAR(4000) ;
DECLARE @SCHEMA VARCHAR(4000);
SET @destination_table = ''SP_BlitzResults_'' + CONVERT(VARCHAR, GETDATE(), 112) ;

Exec sp_Blitz @OutputType = ''TABLE'', @OutputDatabaseName = ''DBA-Admin'', @OutputSchemaName = ''dbo'', @OutputTableName = @destination_table', 
		@database_name=N'DBA-Admin', 
		@flags=4
GO

/* Check for correct Job Owner*/


DECLARE @JobOwner nvarchar(50)
IF EXISTS (Select name from master.sys.syslogins where name = 'MyDefaultJobOwner')
SET @JobOwner = 'MyDefaultJobOwner'
IF EXISTS (Select name from master.sys.syslogins where name = 'sa')
SET @JobOwner = 'sa'


EXEC msdb.dbo.sp_update_job @job_name=N'Log SP_Blitz to table', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'Drops SPBlitzResults Tables and then Creates a table in the DBA-Admin database and runs SP_Blitz and logs to the table', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=@JobOwner , 
		@notify_email_operator_name=N'', 
		@notify_netsend_operator_name=N'', 
		@notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'Log SP_Blitz to table', @name=N'Weekly Monday AM --', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=2, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20150510, 
		@active_end_date=99991231, 
		@active_start_time=30000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id

GO
