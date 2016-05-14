/*
Creates an agent job to run the SP_WhoIsActive in a loop and export the resuilts to a table in the DBA-Admin Database
*/


USE [msdb]
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

 IF EXISTS (SELECT job_id  FROM msdb.dbo.sysjobs_view  WHERE name = N'Log SP_WhoisActive to Table')
EXEC msdb.dbo.sp_delete_job @job_name=N'Log SP_WhoisActive to Table', @delete_unused_schedule=1

/****** Object:  Job [SP_WhoisActive to Table]    Script Date: 05/05/2015 15:29:57 ******/

/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 05/05/2015 15:29:57 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

/* Check for correct Job Owner*/


DECLARE @JobOwner nvarchar(50)
IF EXISTS (Select name from master.sys.syslogins where name = 'MYDefaultJobOwner')
SET @JobOwner = 'MYDefaultJobOwner'
IF EXISTS (Select name from master.sys.syslogins where name = 'sa')
SET @JobOwner = 'sa'

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Log SP_WhoisActive to Table', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This job will run the SP_whoisActive stored procedure and every 5 seconds for a minute, log the results to a table in the DBA-Admin Database and display the results. Useful for Immediate Trouble Shooting. To view results DECLARE @destination_table NVARCHAR(2000), @dSQL NVARCHAR(4000) ;
SET @destination_table = ''WhoIsActive_'' + CONVERT(VARCHAR, GETDATE(), 112) ;
SET @dSQL = N''SELECT collection_time, * FROM dbo.'' +
 QUOTENAME(@destination_table) + N'' order by 1 desc'' ;
print @dSQL
EXEC sp_executesql @dSQ', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=@JobOwner, @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Create Table]    Script Date: 05/05/2015 15:29:57 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Create Table', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=4, 
		@on_success_step_id=2, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @destination_table VARCHAR(4000) ;
SET @destination_table = ''WhoIsActive_'' + CONVERT(VARCHAR, GETDATE(), 112) ;

IF NOT EXISTS (SELECT Name from sys.Tables Where Name = @destination_table )
BEGIN
DECLARE @schema VARCHAR(4000) ;
EXEC sp_WhoIsActive
@get_transaction_info = 1,
@get_plans = 1,
@find_block_leaders = 1,
@RETURN_SCHEMA = 1,
@SCHEMA = @schema OUTPUT ;

SET @schema = REPLACE(@schema, ''<table_name>'', @destination_table) ;

PRINT @schema
EXEC(@schema) ;
END', 
		@database_name=N'DBA-Admin', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run Loop 10 times]    Script Date: 05/05/2015 15:29:57 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run Loop 10 times', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE
    @destination_table VARCHAR(4000) ,
    @msg NVARCHAR(1000) ;


SET @destination_table = ''WhoIsActive_'' + CONVERT(VARCHAR, GETDATE(), 112) ;

DECLARE @numberOfRuns INT ;
SET @numberOfRuns = 10 ;

WHILE @numberOfRuns > 0
    BEGIN;
        EXEC dbo.sp_WhoIsActive @get_transaction_info = 1, @get_plans = 1,
            @find_block_leaders = 1, @DESTINATION_TABLE = @destination_table ;

        SET @numberOfRuns = @numberOfRuns - 1 ;

        IF @numberOfRuns > 0
            BEGIN
                SET @msg = CONVERT(CHAR(19), GETDATE(), 121) + '': '' +
                 ''Logged info. Waiting...''
                RAISERROR(@msg,0,0) WITH nowait ;

                WAITFOR DELAY ''00:00:05''
            END
        ELSE
            BEGIN
                SET @msg = CONVERT(CHAR(19), GETDATE(), 121) + '': '' + ''Done.''
                RAISERROR(@msg,0,0) WITH nowait ;
            END

    END ;
GO

', 
		@database_name=N'DBA-Admin', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


