USE [msdb]
GO

/****** Object:  Job [!DBA Automation - Check for and Label Inactive Databases]    Script Date: 13/07/2016 13:35:49 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 13/07/2016 13:35:49 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'!DBA Automation - Check for and Label Inactive Databases', 
              @enabled=1, 
              @notify_level_eventlog=0, 
              @notify_level_email=0, 
              @notify_level_netsend=0, 
              @notify_level_page=0, 
              @delete_level=0, 
              @description=N'Sets the inactive field of database in [Databases] to 1 (true) when DBA Automation scripts have been unable to contact/update from it for 3 days.', 
              @category_name=N'[Uncategorized (Local)]', 
              @owner_login_name=N'SA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run TSQL to update [databases].[inactive]]    Script Date: 13/07/2016 13:35:49 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run TSQL to update [databases].[inactive]', 
              @step_id=1, 
              @cmdexec_success_code=0, 
              @on_success_action=1, 
              @on_success_step_id=0, 
              @on_fail_action=2, 
              @on_fail_step_id=0, 
              @retry_attempts=0, 
              @retry_interval=0, 
              @os_run_priority=0, @subsystem=N'TSQL', 
              @command=N'UPDATE [Info].[Databases]

SET [Inactive] = 1

WHERE [DatabaseID] in (SELECT [DatabaseID]
                                  FROM [DBADatabase].[Info].[Databases]
                                  JOIN [dbo].InstanceList
                                  ON [DBADatabase].[Info].[Databases].[InstanceID] = [dbo].[InstanceList].[InstanceID]
                                  WHERE [DateChecked] < dateadd(DAY,-3,getdate())
                                  AND [InstanceList].[Inactive] = 0
                                  AND [InstanceList].[Inactive] = 0
                                  )', 
              @database_name=N'DBADatabase', 
              @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily at 7:12', 
              @enabled=1, 
              @freq_type=4, 
              @freq_interval=1, 
              @freq_subday_type=1, 
              @freq_subday_interval=0, 
              @freq_relative_interval=0, 
              @freq_recurrence_factor=0, 
              @active_start_date=20160406, 
              @active_end_date=99991231, 
              @active_start_time=71200, 
              @active_end_time=235959, 
              @schedule_uid=N'da11347a-f7cc-4c56-896c-fcaca3bab02a'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


