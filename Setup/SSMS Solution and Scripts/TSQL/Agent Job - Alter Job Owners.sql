USE [msdb]
GO

/****** Object:  Job [!DBA Automation - Change Job Owners]    Script Date: 30/07/2016 09:59:22 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 30/07/2016 09:59:22 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'!DBA Automation - Change Job Owners', 
             @enabled=1, 
             @notify_level_eventlog=0, 
             @notify_level_email=0, 
             @notify_level_netsend=0, 
             @notify_level_page=0, 
             @delete_level=0, 
             @description=N'This Script changes the Owners of SQL Agent Jobs to SERVERNAMESA and emails a DBA to notify of incorrect Job Owners ', 
             @category_name=N'[Uncategorized (Local)]', 
             @owner_login_name=N'SA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run the Script]    Script Date: 30/07/2016 09:59:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run the Script', 
             @step_id=1, 
             @cmdexec_success_code=0, 
             @on_success_action=1, 
             @on_success_step_id=0, 
             @on_fail_action=2, 
             @on_fail_step_id=0, 
             @retry_attempts=0, 
             @retry_interval=0, 
             @os_run_priority=0, @subsystem=N'CmdExec', 
             @command=N'powershell & PATH TO\ChangeJobOwners.ps1', 
             @flags=0, 
             @proxy_name=N'CMD'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'6am', 
             @enabled=1, 
             @freq_type=4, 
             @freq_interval=1, 
             @freq_subday_type=1, 
             @freq_subday_interval=0, 
             @freq_relative_interval=0, 
             @freq_recurrence_factor=0, 
             @active_start_date=20150612, 
             @active_end_date=99991231, 
             @active_start_time=60000, 
             @active_end_time=235959, 
             @schedule_uid=N'dd436eed-b12f-40c2-b6ce-e5b5aaf00e95'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

