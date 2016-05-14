/*This creates an agent job which will run the SP_AskBrent stored procedure in expermode and retunr the results to 4 tables in the DBA-Admin database as well as to screen. This is useful for trouble shooting purposes as it can be run at a certain time if we have an issue or immediately. It will retunr the biggest issues found  including Wait Stats, CPU Utilisation,  File usage, all relevant perfmon stats*/

USE [msdb]
GO


 IF EXISTS (SELECT job_id  FROM msdb.dbo.sysjobs_view  WHERE name = N'Log SP_AskBrent To Table')
EXEC msdb.dbo.sp_delete_job @job_name=N'Log SP_AskBrent To Table', @delete_unused_schedule=1

/* Check for correct Job Owner*/


DECLARE @JobOwner nvarchar(50)
IF EXISTS (Select name from master.sys.syslogins where name = 'robert.flaxley')
SET @JobOwner = 'robert.flaxley'
IF EXISTS (Select name from master.sys.syslogins where name = 'sa')
SET @JobOwner = 'sa'

DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'Log SP_AskBrent To Table', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'This job will run the SP_AskBrent stored procedure in expermode and retunr the results to 4 tables in the DBA-Admin database as well as to screen. This is useful for trouble shooting purposes as it can be run at a certain time if we have an issue or immediately. It will retunr the biggest issues found  including Wait Stats, CPU Utilisation,  File usage, all relevant perfmon stats', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=@JobOwner , @job_id = @jobId OUTPUT
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'Log SP_AskBrent To Table', @server_name = N'(local)'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'Log SP_AskBrent To Table', @step_name=N'Run SP', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @destination_table VARCHAR(4000) ;
SET @destination_table = ''SP_AskBrentResults_''+ replace(convert(varchar, getdate(),101),''/'','''') + ''_'' + replace(convert(varchar, getdate(),108),'':'','''')  ;
DECLARE @FileStatsdestination_table VARCHAR(4000) ;
SET @FileStatsdestination_table = ''SP_AskBrentResults_FileStats''+ replace(convert(varchar, getdate(),101),''/'','''') + ''_'' + replace(convert(varchar, getdate(),108),'':'','''')  ;	
DECLARE @PerfMonStatsdestination_table VARCHAR(4000) ;
SET @PerfMonStatsdestination_table = ''SP_AskBrentResults_PerfMonStats''+ replace(convert(varchar, getdate(),101),''/'','''') + ''_'' + replace(convert(varchar, getdate(),108),'':'','''')  ;
DECLARE @WaitStatsdestination_table VARCHAR(4000) ;
SET @WaitStatsdestination_table = ''SP_AskBrentResults_WaitStats_''+ replace(convert(varchar, getdate(),101),''/'','''') + ''_'' + replace(convert(varchar, getdate(),108),'':'','''')  ;

exec sp_AskBrent @ExpertMode = 1
,@Seconds = 30
,@OutputDatabaseName = ''DBA-Admin''
,@OutputSchemaName = ''dbo'' 
,@OutputTableName = @destination_table
,@OutputTableNameFileStats = @FileStatsdestination_table
,@OutputTableNamePerfmonStats = @PerfMonStatsdestination_table
,@OutputTableNameWaitStats = @WaitStatsdestination_table', 
		@database_name=N'DBA-Admin', 
		@flags=0
GO

/* Check for correct Job Owner*/


DECLARE @JobOwner nvarchar(50)
IF EXISTS (Select name from master.sys.syslogins where name = 'robert.flaxley')
SET @JobOwner = 'robert.flaxley'
IF EXISTS (Select name from master.sys.syslogins where name = 'sa')
SET @JobOwner = 'sa'


EXEC msdb.dbo.sp_update_job @job_name=N'Log SP_AskBrent To Table', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'This job will run the SP_AskBrent stored procedure in expermode and retunr the results to 4 tables in the DBA-Admin database as well as to screen. This is useful for trouble shooting purposes as it can be run at a certain time if we have an issue or immediately. It will retunr the biggest issues found  including Wait Stats, CPU Utilisation,  File usage, all relevant perfmon stats', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=@JobOwner , 
		@notify_email_operator_name=N'', 
		@notify_netsend_operator_name=N'', 
		@notify_page_operator_name=N''


GO
