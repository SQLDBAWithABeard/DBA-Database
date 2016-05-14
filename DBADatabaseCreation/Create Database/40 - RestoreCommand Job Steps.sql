-- Alter line 69 for the backup location

/*************************************************************************************************************
Script for creating automated restore scripts based on Ola Hallengren's Maintenance Solution. 
Source: https://ola.hallengren.com

Create RestoreCommand s proc in location of Maintenance Solution procedures 
and CommandLog table along with creating job steps.

At least one full backup for all databases should be logged to CommandLog table (i.e., executed through Maintenance Solution
created FULL backup job) for generated restore scripts to be valid. 
Restore scripts are generated based on CommandLog table, not msdb backup history.

Restore script is created using ouput file. Each backup job overwrites restore script file in separate step so that only
the most recent version is maintained for immediate DR. If possible, perform a tail log backup and add to end of restore script 
in order to avoid data loss (also remove any replace options for full backups).

Make sure sql agent has read / write to the directory that you want the restore script created.

Script will read backup file location from @Directory value used in respective DatabaseBackup job (NULL is supported). 
Set @LogToTable = 'Y' for all backup jobs! (This is the defaut).  

Created by Jared Zagelbaum, 4/13/2015, https://jaredzagelbaum.wordpress.com/
For intro / tutorial, see https://jaredzagelbaum.wordpress.com/2015/04/16/automated-restore-script-output-for-ola-hallengrens-maintenance-solution/
Follow me on Twitter!: @JaredZagelbaum

**************************************************************************************************************/

--Create restore command jobs
Declare @DatabaseName sysname = N'DBA-Admin'				-- Provide db location of maintenance solution and RestoreCommand




Declare @ErrorMessage nvarchar(max)
Declare @jobid UniqueIdentifier
Declare @BackupDir nvarchar(max)
Declare @RestoreScriptDirValue nvarchar(4000)
Declare @RestoreCommand nvarchar(max)

  DECLARE @Version numeric(18,10)

  DECLARE @TokenServer nvarchar(max)
  DECLARE @TokenJobID nvarchar(max)
  DECLARE @TokenStepID nvarchar(max)
  DECLARE @TokenDate nvarchar(max)
  DECLARE @TokenTime nvarchar(max)
  DECLARE @TokenLogDirectory nvarchar(max)

 SET @Version = CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - 1) + '.' + REPLACE(RIGHT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)), LEN(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)))),'.','') AS numeric(18,10))

 IF @Version >= 9.002047
  BEGIN
    SET @TokenServer = '$' + '(ESCAPE_SQUOTE(SRVR))'
    SET @TokenJobID = '$' + '(ESCAPE_SQUOTE(JOBID))'
    SET @TokenStepID = '$' + '(ESCAPE_SQUOTE(STEPID))'
    SET @TokenDate = '$' + '(ESCAPE_SQUOTE(STRTDT))'
    SET @TokenTime = '$' + '(ESCAPE_SQUOTE(STRTTM))'
  END
  ELSE
  BEGIN
    SET @TokenServer = '$' + '(SRVR)'
    SET @TokenJobID = '$' + '(JOBID)'
    SET @TokenStepID = '$' + '(STEPID)'
    SET @TokenDate = '$' + '(STRTDT)'
    SET @TokenTime = '$' + '(STRTTM)'
  END

  Declare @RestoreScriptDir nvarchar(max) = '\\BACKUPLOCATIONROOT\' + REPLACE(CAST(SERVERPROPERTY('servername') AS nvarchar),'\','$')   -- Choose restore script location: 'Backup_Dir', 'Error_Log', or custom defined dir, e.g., 'C:\' . Directory must be created first if custom!


 IF @RestoreScriptDir IS NULL OR @RestoreScriptDir = '' 
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @RestoreScriptDir is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
  END

IF @RestoreScriptDir NOT IN ('Error_Log', 'Backup_Dir')
BEGIN
	SET @RestoreScriptDirValue =  @RestoreScriptDir +  '\DatabaseRestore.txt'
END


Set @RestoreCommand = N'sqlcmd -E -S ' + @TokenServer + ' -d ' + @DatabaseName + ' -Q "EXECUTE [dbo].[RestoreCommand]" -b'


Declare jobidcursor CURSOR FAST_FORWARD FOR

SELECT 
JOB.job_id 
,
replace(
replace(
right(
substring(command, charindex('@Directory = ', command), CHARINDEX(',', command, charindex('@Directory', command)) - charindex('@Directory = ', command))
,len(
		substring(command, charindex('@Directory = ', command), CHARINDEX(',', command, charindex('@Directory', command)) - charindex('@Directory = ', command))
	) - 13
	) 
	,'N''',''
	)
	,'''',''
	)
	BackupDir

FROM Msdb.dbo.SysJobs JOB
 INNER JOIN Msdb.dbo.SysJobSteps STEP ON STEP.Job_Id = JOB.Job_Id
 WHERE step_name LIKE 'DatabaseBackup - %'

 OPEN jobidCursor
  FETCH NEXT FROM jobidCursor INTO @jobID, @BackupDir
  WHILE @@Fetch_Status = 0     
  BEGIN                

  IF @RestoreScriptDir = 'Backup_Dir' AND @BackupDir = 'NULL'
BEGIN
	EXECUTE [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer', N'BackupDirectory', @RestoreScriptDirValue OUTPUT
	SET @RestoreScriptDirValue = @RestoreScriptDirValue  + '\DatabaseRestore.txt' 
END

 IF @RestoreScriptDir = 'Backup_Dir' AND @BackupDir <> 'NULL'
 BEGIN
	SET @RestoreScriptDirValue =  @BackupDir  + 'DatabaseRestore.txt'
END

IF LEFT(@RestoreScriptDirValue, 2) = '\\'
BEGIN
SET @RestoreScriptDirValue = '\' + Replace(@RestoreScriptDirValue , '\\', '\')  --check for concat errors
END

IF LEFT(@RestoreScriptDirValue, 2) <> '\\'
BEGIN
SET @RestoreScriptDirValue = Replace(@RestoreScriptDirValue , '\\', '\')  --check for concat errors
END



		EXEC msdb.dbo.sp_update_jobstep 
		 @job_id=@jobID 
		,@step_id = 1 
		,@on_success_action=3
		,@on_fail_action=2       
		
		EXEC msdb.dbo.sp_add_jobstep
		 @job_id = @jobid
		,@step_name=N'Generate Restore Script'
		,@step_id=2
		,@cmdexec_success_code=0
		,@on_success_action=1
		,@on_fail_action=2
		,@retry_attempts=0 
		,@retry_interval=0 
		,@os_run_priority=0
		,@subsystem=N'CmdExec' 
		,@command=@RestoreCommand
		,@database_name=@DatabaseName
		,@output_file_name=@RestoreScriptDirValue
		,@flags=0
		 

		  FETCH Next FROM jobidCursor INTO @jobID    , @BackupDir
		   END 
		   CLOSE jobidCursor
		   DEALLOCATE jobidCursor