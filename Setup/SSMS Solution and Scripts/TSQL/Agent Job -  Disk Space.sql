USE [msdb]
GO

/****** Object:  Job [!DBA Automation - Add Disk Space to DBADatabase]    Script Date: 30/07/2016 09:59:12 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 30/07/2016 09:59:12 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'!DBA Automation - Add Disk Space to DBADatabase', 
             @enabled=1, 
             @notify_level_eventlog=0, 
             @notify_level_email=0, 
             @notify_level_netsend=0, 
             @notify_level_page=0, 
             @delete_level=0, 
             @description=N'This job will run a powershell script to gather the disk space from the servers available from the DBA Database. It will log to a log file located \DBADatabase_DiskSpace_Job_', 
             @category_name=N'[Uncategorized (Local)]', 
             @owner_login_name=N'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run Powershell]    Script Date: 30/07/2016 09:59:12 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run Powershell', 
             @step_id=1, 
             @cmdexec_success_code=0, 
             @on_success_action=1, 
             @on_success_step_id=0, 
             @on_fail_action=2, 
             @on_fail_step_id=0, 
             @retry_attempts=0, 
             @retry_interval=0, 
             @os_run_priority=0, @subsystem=N'PowerShell', 
             @command=N'cd c:\scripts
& .\''!DBA Database Update DiskSpace  Results.ps1''', 
             @database_name=N'master', 
             @output_file_name=N'\Diskspaceoutput.txt', 
             @flags=0, 
             @proxy_name=N'SA'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'daily 5am', 
             @enabled=1, 
             @freq_type=4, 
             @freq_interval=1, 
             @freq_subday_type=1, 
             @freq_subday_interval=0, 
             @freq_relative_interval=0, 
             @freq_recurrence_factor=0, 
             @active_start_date=20151230, 
             @active_end_date=99991231, 
             @active_start_time=50000, 
             @active_end_time=235959, 
             @schedule_uid=N'24267739-6c9c-4557-bd45-34a95766ef39'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

