 /*
 This script will set the backup jobs for the OLA maintenance plan solution to use 
 the Data Centre 2 Dev Share Change this  - Line 6 & Line 85
 */
 
 DECLARE @DataCentre nvarchar(50) = 'Data Centre 2' -- Enter description for Agent jobs
 DECLARE @BackupDirectory nvarchar(max)
  DECLARE @CleanupTime int
  DECLARE @OutputFileDirectory nvarchar(max)
  DECLARE @LogToTable nvarchar(max)
  DECLARE @DatabaseName nvarchar(max)
  DECLARE @Version numeric(18,10)

  DECLARE @TokenServer nvarchar(max)
  DECLARE @TokenJobID nvarchar(max)
  DECLARE @TokenStepID nvarchar(max)
  DECLARE @TokenDate nvarchar(max)
  DECLARE @TokenTime nvarchar(max)
  DECLARE @TokenLogDirectory nvarchar(max)

  DECLARE @JobDescription nvarchar(max)
  DECLARE @JobCategory nvarchar(max)
  DECLARE @JobOwner nvarchar(max)

  DECLARE @JobName01 nvarchar(max)
  DECLARE @JobName02 nvarchar(max)
  DECLARE @JobName03 nvarchar(max)
  DECLARE @JobName04 nvarchar(max)
  DECLARE @JobName05 nvarchar(max)
  DECLARE @JobName06 nvarchar(max)
  DECLARE @JobName07 nvarchar(max)
  DECLARE @JobName08 nvarchar(max)
  DECLARE @JobName09 nvarchar(max)
  DECLARE @JobName10 nvarchar(max)
  DECLARE @JobName11 nvarchar(max)

  DECLARE @JobCommand01 nvarchar(max)
  DECLARE @JobCommand02 nvarchar(max)
  DECLARE @JobCommand03 nvarchar(max)
  DECLARE @JobCommand04 nvarchar(max)
  DECLARE @JobCommand05 nvarchar(max)
  DECLARE @JobCommand06 nvarchar(max)
  DECLARE @JobCommand07 nvarchar(max)
  DECLARE @JobCommand08 nvarchar(max)
  DECLARE @JobCommand09 nvarchar(max)
  DECLARE @JobCommand10 nvarchar(max)
  DECLARE @JobCommand11 nvarchar(max)

  DECLARE @OutputFile01 nvarchar(max)
  DECLARE @OutputFile02 nvarchar(max)
  DECLARE @OutputFile03 nvarchar(max)
  DECLARE @OutputFile04 nvarchar(max)
  DECLARE @OutputFile05 nvarchar(max)
  DECLARE @OutputFile06 nvarchar(max)
  DECLARE @OutputFile07 nvarchar(max)
  DECLARE @OutputFile08 nvarchar(max)
  DECLARE @OutputFile09 nvarchar(max)
  DECLARE @OutputFile10 nvarchar(max)
  DECLARE @OutputFile11 nvarchar(max)

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

  IF @Version >= 12
  BEGIN
    SET @TokenLogDirectory = '$' + '(ESCAPE_SQUOTE(SQLLOGDIR))'
  END

  SELECT @BackupDirectory = '\\' /* THIS is the backup directory*/

  SELECT @CleanupTime = 220

  IF  @OutputFileDirectory IS NULL AND SERVERPROPERTY('EngineEdition') <> 4 AND @Version < 12
BEGIN
  IF @Version >= 11
  BEGIN
    SELECT @OutputFileDirectory = [path]
    FROM sys.dm_os_server_diagnostics_log_configurations
  END
  ELSE
  BEGIN
    SELECT @OutputFileDirectory = LEFT(CAST(SERVERPROPERTY('ErrorLogFileName') AS nvarchar(max)),LEN(CAST(SERVERPROPERTY('ErrorLogFileName') AS nvarchar(max))) - CHARINDEX('\',REVERSE(CAST(SERVERPROPERTY('ErrorLogFileName') AS nvarchar(max)))))
  END
END

  IF RIGHT(@OutputFileDirectory,1) = '\' AND SERVERPROPERTY('EngineEdition') <> 4
BEGIN
  SET @OutputFileDirectory = LEFT(@OutputFileDirectory, LEN(@OutputFileDirectory) - 1)
END



  SELECT @LogToTable = 'Y'

  SELECT @DatabaseName = 'DBA-Admin'

  SET @JobDescription = 'Source: https://ola.hallengren.com'
  SET @JobCategory = 'Database Maintenance'
  SET @JobOwner = SUSER_SNAME(0x01)

    SET @JobName01 = 'DatabaseBackup - SYSTEM_DATABASES - FULL - DEV ' + @DataCentre 
  IF EXISTS (SELECT job_id  FROM msdb.dbo.sysjobs_view  WHERE name = N'DatabaseBackup - SYSTEM_DATABASES - FULL')
EXEC msdb.dbo.sp_delete_job @job_name=N'DatabaseBackup - SYSTEM_DATABASES - FULL', @delete_unused_schedule=1

  IF EXISTS (SELECT job_id  FROM msdb.dbo.sysjobs_view  WHERE name = @JobName01 )
EXEC msdb.dbo.sp_delete_job @job_name=@JobName01 , @delete_unused_schedule=1

  SET @JobCommand01 = 'sqlcmd -E -S ' + @TokenServer + ' -d ' + @DatabaseName + ' -Q "EXECUTE [dbo].[DatabaseBackup] @Databases = ''SYSTEM_DATABASES'', @Directory = ' + ISNULL('N''' + REPLACE(@BackupDirectory,'''','''''') + '''','NULL') + ', @BackupType = ''FULL'', @Verify = ''Y'', @CleanupTime = ' + ISNULL(CAST(@CleanupTime AS nvarchar),'NULL') + ', @CheckSum = ''Y''' + ', @Compress= ''Y''' + CASE WHEN @LogToTable = 'Y' THEN ', @LogToTable = ''Y''' ELSE '' END + '" -b'
  SET @OutputFile01 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + 'DatabaseBackup_' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile01) > 200 SET @OutputFile01 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile01) > 200 SET @OutputFile01 = NULL

  SET @JobName02 = 'DatabaseBackup - USER_DATABASES - DIFF - DEV ' + @DataCentre 

    IF EXISTS (SELECT job_id  FROM msdb.dbo.sysjobs_view  WHERE name = N'DatabaseBackup - USER_DATABASES - DIFF')
EXEC msdb.dbo.sp_delete_job @job_name=N'DatabaseBackup - USER_DATABASES - DIFF', @delete_unused_schedule=1

  IF EXISTS (SELECT job_id  FROM msdb.dbo.sysjobs_view  WHERE name = @JobName02 )
EXEC msdb.dbo.sp_delete_job @job_name=@JobName02 , @delete_unused_schedule=1

  SET @JobCommand02 = 'sqlcmd -E -S ' + @TokenServer + ' -d ' + @DatabaseName + ' -Q "EXECUTE [dbo].[DatabaseBackup] @Databases = ''USER_DATABASES'', @ChangeBackupType = ''Y'', @Directory = ' + ISNULL('N''' + REPLACE(@BackupDirectory,'''','''''') + '''','NULL') + ', @BackupType = ''DIFF'', @Verify = ''Y'', @CleanupTime = ' + ISNULL(CAST(@CleanupTime AS nvarchar),'NULL') + ', @CheckSum = ''Y''' + ', @Compress= ''Y''' + CASE WHEN @LogToTable = 'Y' THEN ', @LogToTable = ''Y''' ELSE '' END + '" -b'
  SET @OutputFile02 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + 'DatabaseBackup_' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile02) > 200 SET @OutputFile02 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile02) > 200 SET @OutputFile02 = NULL

  SET @JobName03 = 'DatabaseBackup - USER_DATABASES - FULL - DEV ' + @DataCentre 

      IF EXISTS (SELECT job_id  FROM msdb.dbo.sysjobs_view  WHERE name = N'DatabaseBackup - USER_DATABASES - FULL')
EXEC msdb.dbo.sp_delete_job @job_name=N'DatabaseBackup - USER_DATABASES - FULL', @delete_unused_schedule=1

  IF EXISTS (SELECT job_id  FROM msdb.dbo.sysjobs_view  WHERE name = @JobName03 )
EXEC msdb.dbo.sp_delete_job @job_name=@JobName03 , @delete_unused_schedule=1

  SET @JobCommand03 = 'sqlcmd -E -S ' + @TokenServer + ' -d ' + @DatabaseName + ' -Q "EXECUTE [dbo].[DatabaseBackup] @Databases = ''USER_DATABASES'', @Directory = ' + ISNULL('N''' + REPLACE(@BackupDirectory,'''','''''') + '''','NULL') + ', @BackupType = ''FULL'', @Verify = ''Y'', @CleanupTime = ' + ISNULL(CAST(@CleanupTime AS nvarchar),'NULL') + ', @CheckSum = ''Y''' + ', @Compress= ''Y''' + CASE WHEN @LogToTable = 'Y' THEN ', @LogToTable = ''Y''' ELSE '' END + '" -b'
  SET @OutputFile03 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + 'DatabaseBackup_' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile03) > 200 SET @OutputFile03 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile03) > 200 SET @OutputFile03 = NULL

 SET @JobName04 = 'DatabaseBackup - USER_DATABASES - LOG - DEV ' + @DataCentre 

IF EXISTS (SELECT job_id  FROM msdb.dbo.sysjobs_view  WHERE name = N'DatabaseBackup - USER_DATABASES - LOG')
EXEC msdb.dbo.sp_delete_job @job_name=N'DatabaseBackup - USER_DATABASES - LOG', @delete_unused_schedule=1

IF EXISTS (SELECT job_id  FROM msdb.dbo.sysjobs_view  WHERE name = @JobName04 )
EXEC msdb.dbo.sp_delete_job @job_name=@JobName04 , @delete_unused_schedule=1

  SET @JobCommand04 = 'sqlcmd -E -S ' + @TokenServer + ' -d ' + @DatabaseName + ' -Q "EXECUTE [dbo].[DatabaseBackup] @Databases = ''USER_DATABASES'', @ChangeBackupType = ''Y'', @Directory = ' + ISNULL('N''' + REPLACE(@BackupDirectory,'''','''''') + '''','NULL') + ', @BackupType = ''LOG'', @Verify = ''Y'', @CleanupTime = ' + ISNULL(CAST(@CleanupTime AS nvarchar),'NULL') + ', @CheckSum = ''Y''' + ', @Compress= ''Y''' +  CASE WHEN @LogToTable = 'Y' THEN ', @LogToTable = ''Y''' ELSE '' END + '" -b'
  SET @OutputFile04 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + 'DatabaseBackup_' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile04) > 200 SET @OutputFile04 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile04) > 200 SET @OutputFile04 = NULL

  SET @JobName05 = 'DatabaseIntegrityCheck - SYSTEM_DATABASES'
  SET @JobCommand05 = 'sqlcmd -E -S ' + @TokenServer + ' -d ' + @DatabaseName + ' -Q "EXECUTE [dbo].[DatabaseIntegrityCheck] @Databases = ''SYSTEM_DATABASES''' + CASE WHEN @LogToTable = 'Y' THEN ', @LogToTable = ''Y''' ELSE '' END + '" -b'
  SET @OutputFile05 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + 'DatabaseIntegrityCheck_' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile05) > 200 SET @OutputFile05 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile05) > 200 SET @OutputFile05 = NULL


  SET @JobName06 = 'DatabaseIntegrityCheck - USER_DATABASES'
  SET @JobCommand06 = 'sqlcmd -E -S ' + @TokenServer + ' -d ' + @DatabaseName + ' -Q "EXECUTE [dbo].[DatabaseIntegrityCheck] @Databases = ''USER_DATABASES''' + CASE WHEN @LogToTable = 'Y' THEN ', @LogToTable = ''Y''' ELSE '' END + '" -b'
  SET @OutputFile06 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + 'DatabaseIntegrityCheck_' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile06) > 200 SET @OutputFile06 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile06) > 200 SET @OutputFile06 = NULL

  SET @JobName07 = 'IndexOptimize - USER_DATABASES'
  SET @JobCommand07 = 'sqlcmd -E -S ' + @TokenServer + ' -d ' + @DatabaseName + ' -Q "EXECUTE [dbo].[IndexOptimize] @Databases = ''USER_DATABASES'' , @UpdateStatistics = ''ALL'', @OnlyModifiedStatistics = ''Y''' + CASE WHEN @LogToTable = 'Y' THEN ', @LogToTable = ''Y''' ELSE '' END + '" -b'
  SET @OutputFile07 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + 'IndexOptimize_' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile07) > 200 SET @OutputFile07 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile07) > 200 SET @OutputFile07 = NULL

  SET @JobName08 = 'sp_delete_backuphistory'
  SET @JobCommand08 = 'sqlcmd -E -S ' + @TokenServer + ' -d ' + 'msdb' + ' -Q "DECLARE @CleanupDate datetime SET @CleanupDate = DATEADD(dd,-30,GETDATE()) EXECUTE dbo.sp_delete_backuphistory @oldest_date = @CleanupDate" -b'
  SET @OutputFile08 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + 'sp_delete_backuphistory_' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile08) > 200 SET @OutputFile08 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile08) > 200 SET @OutputFile08 = NULL

  SET @JobName09 = 'sp_purge_jobhistory'
  SET @JobCommand09 = 'sqlcmd -E -S ' + @TokenServer + ' -d ' + 'msdb' + ' -Q "DECLARE @CleanupDate datetime SET @CleanupDate = DATEADD(dd,-30,GETDATE()) EXECUTE dbo.sp_purge_jobhistory @oldest_date = @CleanupDate" -b'
  SET @OutputFile09 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + 'sp_purge_jobhistory_' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile09) > 200 SET @OutputFile09 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile09) > 200 SET @OutputFile09 = NULL

  SET @JobName10 = 'Output File Cleanup'
  SET @JobCommand10 = 'cmd /q /c "For /F "tokens=1 delims=" %v In (''ForFiles /P "' + COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '" /m *_*_*_*.txt /d -30 2^>^&1'') do if EXIST "' + COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '"\%v echo del "' + COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '"\%v& del "' + COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '"\%v"'
  SET @OutputFile10 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + 'OutputFileCleanup_' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile10) > 200 SET @OutputFile10 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile10) > 200 SET @OutputFile10 = NULL

  SET @JobName11 = 'CommandLog Cleanup'
  SET @JobCommand11 = 'sqlcmd -E -S ' + @TokenServer + ' -d ' + @DatabaseName + ' -Q "DELETE FROM [dbo].[CommandLog] WHERE StartTime < DATEADD(dd,-30,GETDATE())" -b'
  SET @OutputFile11 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + 'CommandLogCleanup_' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile11) > 200 SET @OutputFile11 = COALESCE(@OutputFileDirectory,@TokenLogDirectory) + '\' + @TokenJobID + '_' + @TokenStepID + '_' + @TokenDate + '_' + @TokenTime + '.txt'
  IF LEN(@OutputFile11) > 200 SET @OutputFile11 = NULL

  IF NOT EXISTS (SELECT name  FROM msdb.dbo.sysjobs WHERE [name] = @JobName01)
  BEGIN
    EXECUTE msdb.dbo.sp_add_job @job_name = @JobName01, @description = @JobDescription, @category_name = @JobCategory, @owner_login_name = @JobOwner
    EXECUTE msdb.dbo.sp_add_jobstep @job_name = @JobName01, @step_name = @JobName01, @subsystem = 'CMDEXEC', @command = @JobCommand01, @output_file_name = @OutputFile01
    EXECUTE msdb.dbo.sp_add_jobserver @job_name = @JobName01
  END

  IF NOT EXISTS (SELECT name  FROM msdb.dbo.sysjobs WHERE [name] = @JobName02)
  BEGIN
    EXECUTE msdb.dbo.sp_add_job @job_name = @JobName02, @description = @JobDescription, @category_name = @JobCategory, @owner_login_name = @JobOwner
    EXECUTE msdb.dbo.sp_add_jobstep @job_name = @JobName02, @step_name = @JobName02, @subsystem = 'CMDEXEC', @command = @JobCommand02, @output_file_name = @OutputFile02
    EXECUTE msdb.dbo.sp_add_jobserver @job_name = @JobName02
  END

  IF NOT EXISTS (SELECT name  FROM msdb.dbo.sysjobs WHERE [name] = @JobName03)
  BEGIN
    EXECUTE msdb.dbo.sp_add_job @job_name = @JobName03, @description = @JobDescription, @category_name = @JobCategory, @owner_login_name = @JobOwner
    EXECUTE msdb.dbo.sp_add_jobstep @job_name = @JobName03, @step_name = @JobName03, @subsystem = 'CMDEXEC', @command = @JobCommand03, @output_file_name = @OutputFile03
    EXECUTE msdb.dbo.sp_add_jobserver @job_name = @JobName03
  END

  IF NOT EXISTS (SELECT name  FROM msdb.dbo.sysjobs WHERE [name] = @JobName04)
  BEGIN
    EXECUTE msdb.dbo.sp_add_job @job_name = @JobName04, @description = @JobDescription, @category_name = @JobCategory, @owner_login_name = @JobOwner
    EXECUTE msdb.dbo.sp_add_jobstep @job_name = @JobName04, @step_name = @JobName04, @subsystem = 'CMDEXEC', @command = @JobCommand04, @output_file_name = @OutputFile04
    EXECUTE msdb.dbo.sp_add_jobserver @job_name = @JobName04
  END

  IF NOT EXISTS (SELECT name  FROM msdb.dbo.sysjobs WHERE [name] = @JobName05)
  BEGIN
    EXECUTE msdb.dbo.sp_add_job @job_name = @JobName05, @description = @JobDescription, @category_name = @JobCategory, @owner_login_name = @JobOwner
    EXECUTE msdb.dbo.sp_add_jobstep @job_name = @JobName05, @step_name = @JobName05, @subsystem = 'CMDEXEC', @command = @JobCommand05, @output_file_name = @OutputFile05
    EXECUTE msdb.dbo.sp_add_jobserver @job_name = @JobName05
  END

  IF NOT EXISTS (SELECT name  FROM msdb.dbo.sysjobs WHERE [name] = @JobName06)
  BEGIN
    EXECUTE msdb.dbo.sp_add_job @job_name = @JobName06, @description = @JobDescription, @category_name = @JobCategory, @owner_login_name = @JobOwner
    EXECUTE msdb.dbo.sp_add_jobstep @job_name = @JobName06, @step_name = @JobName06, @subsystem = 'CMDEXEC', @command = @JobCommand06, @output_file_name = @OutputFile06
    EXECUTE msdb.dbo.sp_add_jobserver @job_name = @JobName06
  END

  IF NOT EXISTS (SELECT name  FROM msdb.dbo.sysjobs WHERE [name] = @JobName07)
  BEGIN
    EXECUTE msdb.dbo.sp_add_job @job_name = @JobName07, @description = @JobDescription, @category_name = @JobCategory, @owner_login_name = @JobOwner
    EXECUTE msdb.dbo.sp_add_jobstep @job_name = @JobName07, @step_name = @JobName07, @subsystem = 'CMDEXEC', @command = @JobCommand07, @output_file_name = @OutputFile07
    EXECUTE msdb.dbo.sp_add_jobserver @job_name = @JobName07
  END

  IF NOT EXISTS (SELECT name  FROM msdb.dbo.sysjobs WHERE [name] = @JobName08)
  BEGIN
    EXECUTE msdb.dbo.sp_add_job @job_name = @JobName08, @description = @JobDescription, @category_name = @JobCategory, @owner_login_name = @JobOwner
    EXECUTE msdb.dbo.sp_add_jobstep @job_name = @JobName08, @step_name = @JobName08, @subsystem = 'CMDEXEC', @command = @JobCommand08, @output_file_name = @OutputFile08
    EXECUTE msdb.dbo.sp_add_jobserver @job_name = @JobName08
  END

  IF NOT EXISTS (SELECT name  FROM msdb.dbo.sysjobs WHERE [name] = @JobName09)
  BEGIN
    EXECUTE msdb.dbo.sp_add_job @job_name = @JobName09, @description = @JobDescription, @category_name = @JobCategory, @owner_login_name = @JobOwner
    EXECUTE msdb.dbo.sp_add_jobstep @job_name = @JobName09, @step_name = @JobName09, @subsystem = 'CMDEXEC', @command = @JobCommand09, @output_file_name = @OutputFile09
    EXECUTE msdb.dbo.sp_add_jobserver @job_name = @JobName09
  END

  IF NOT EXISTS (SELECT name  FROM msdb.dbo.sysjobs WHERE [name] = @JobName10)
  BEGIN
    EXECUTE msdb.dbo.sp_add_job @job_name = @JobName10, @description = @JobDescription, @category_name = @JobCategory, @owner_login_name = @JobOwner
    EXECUTE msdb.dbo.sp_add_jobstep @job_name = @JobName10, @step_name = @JobName10, @subsystem = 'CMDEXEC', @command = @JobCommand10, @output_file_name = @OutputFile10
    EXECUTE msdb.dbo.sp_add_jobserver @job_name = @JobName10
  END

  IF NOT EXISTS (SELECT name  FROM msdb.dbo.sysjobs WHERE [name] = @JobName11)
  BEGIN
    EXECUTE msdb.dbo.sp_add_job @job_name = @JobName11, @description = @JobDescription, @category_name = @JobCategory, @owner_login_name = @JobOwner
    EXECUTE msdb.dbo.sp_add_jobstep @job_name = @JobName11, @step_name = @JobName11, @subsystem = 'CMDEXEC', @command = @JobCommand11, @output_file_name = @OutputFile11
    EXECUTE msdb.dbo.sp_add_jobserver @job_name = @JobName11
  END

  

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

Declare @ErrorMessage nvarchar(max)
Declare @jobid UniqueIdentifier
Declare @BackupDir nvarchar(max)
Declare @RestoreScriptDirValue nvarchar(4000)
Declare @RestoreCommand nvarchar(max)


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

  Declare @RestoreScriptDir nvarchar(max) 
  
  SET @RestoreScriptDir = @BackupDirectory  + '\' + REPLACE(CAST(SERVERPROPERTY('servername') AS nvarchar),'\','$')   -- Choose restore script location: 'Backup_Dir', 'Error_Log', or custom defined dir, e.g., 'C:\' . Directory must be created first if custom!


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