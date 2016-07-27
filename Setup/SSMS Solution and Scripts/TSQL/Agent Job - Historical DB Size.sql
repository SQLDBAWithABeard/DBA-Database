USE [msdb]
GO

/****** Object:  Job [!DBA Automation - Add Database HistoricalDBSize]    Script Date: 14/07/2016 09:15:07 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [!DBA Database Jobs]    Script Date: 14/07/2016 09:15:07 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'!DBA Database Jobs' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'!DBA Database Jobs'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'!DBA Automation - Add Database HistoricalDBSize', 
              @enabled=1, 
              @notify_level_eventlog=0, 
              @notify_level_email=2, 
              @notify_level_netsend=0, 
              @notify_level_page=0, 
              @delete_level=0, 
              @description=N'No description available.', 
              @category_name=N'!DBA Database Jobs', 
              @owner_login_name=N'SA', 
              @notify_email_operator_name=N'The DBA Team', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Get Data and insert to HistoricalDBSize]    Script Date: 14/07/2016 09:15:07 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Get Data and insert to HistoricalDBSize', 
              @step_id=1, 
              @cmdexec_success_code=0, 
              @on_success_action=1, 
              @on_success_step_id=0, 
              @on_fail_action=2, 
              @on_fail_step_id=0, 
              @retry_attempts=0, 
              @retry_interval=0, 
              @os_run_priority=0, @subsystem=N'TSQL', 
              @command=N'USE [DBADatabase]
GO

INSERT INTO [Info].[HistoricalDBSize]
SELECT [DatabaseID]
      ,[DB].[InstanceID]
      ,[Name]
      ,[DateChecked]
      ,[SizeMB]
      ,[SpaceAvailableKB]
  FROM [DBADatabase].[Info].[Databases] DB JOIN [DBADatabase].[dbo].[InstanceList] IL ON IL.[InstanceID] = [DB].[InstanceID]
WHERE [Environment] = ''Production''
   AND [DB].[Inactive] = 0
   AND [Status] NOT LIKE ''Offline%''
GO', 
              @database_name=N'DBADatabase', 
              @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily at 7:00am', 
              @enabled=1, 
              @freq_type=4, 
              @freq_interval=1, 
              @freq_subday_type=1, 
              @freq_subday_interval=0, 
              @freq_relative_interval=0, 
              @freq_recurrence_factor=0, 
              @active_start_date=20160713, 
              @active_end_date=99991231, 
              @active_start_time=73000, 
              @active_end_time=235959, 
              @schedule_uid=N'eb508ede-293a-47d7-a6ae-3cbeb0548085'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
