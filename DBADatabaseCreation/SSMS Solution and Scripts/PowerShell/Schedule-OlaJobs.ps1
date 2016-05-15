   <# 
.SYNOPSIS  
     Script to set some default schedules for the default jobs created by Ola Hallengrens Maintenance Solution

.DESCRIPTION 
    This script will set some default job schedules for Ola Hallengrens Maintenance Solution default Jobs
    following the guidance on his website

    Follow these guidelines from Ola's website https://ola.hallengren.com 

		The "One Day a week here should be a different day of the week

				User databases:
				•Full backup one day per week                                  * If using differentials otherwise daily
				•Differential backup all other days of the week                * If required - otherwise don't schedule
				•Transaction log backup every hour
				•Integrity check one day per week
				•Index maintenance one day per week

				System databases:
				•Full backup every day
				•Integrity check one day per week

				I recommend that you run a full backup after the index maintenance. The following differential backups will then be small. I also recommend that you perform the full backup after the integrity check. Then you know that the integrity of the backup is okay.


		The one day of a week here can be the same day of the week

				Cleanup:
				•sp_delete_backuphistory one day per week
				•sp_purge_jobhistory one day per week
				•CommandLog cleanup one day per week
				•Output file cleanup one day per week

.PARAMETER 
    Server
        This is the connection string required to connect to the SQL Instance ServerName for a default instance, Servername\InstanceName or ServerName\InstanceName,Port
.EXAMPLE 
    Schedule-OlaJobs ServerName\InstanceName


.NOTES 
    Obviously requires Ola Hallengrens Maintnance Solution script to have been run first and only schedules the default jobs

    AUTHOR: Rob Sewell sqldbawithabeard.com 
    DATE: 1/05/2015 - Initial
	19/05/2015 - Added some if else and changed the -eq to like * for the job names
#> 

        function Schedule-OlaJobs
        {

        param([string]$Server)
        #Connect to server
        # To Load SQL Server Management Objects into PowerShell
    [System.Reflection.Assembly]::LoadWithPartialName(‘Microsoft.SqlServer.SMO’)  | out-null
    [System.Reflection.Assembly]::LoadWithPartialName(‘Microsoft.SqlServer.SMOExtended’)  | out-null
        $srv = New-Object Microsoft.SQLServer.Management.SMO.Server $Server
        $JobServer = $srv.JobServer
        $Jobs = $JobServer.Jobs

        # Set Schedule for Full System DBs to once a day just before midnight

        $Job = $Jobs|Where-Object {$_.Name -like 'DatabaseBackup - SYSTEM_DATABASES - FULL*'}
        if ($Job -eq $Null) 
        {Write-Output 'No Job with that name' 
        break}
        elseif ($Job.HasSchedule -eq $True)
        {
        Write-Output "Schedule already exists for $Job."
        }
        else{
        $Schedule = new-object Microsoft.SqlServer.Management.Smo.Agent.JobSchedule ($job, 'Daily - Midnight --')
        $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
        $Schedule.ActiveEndTimeOfDay = '23:59:59'
        $Schedule.FrequencyTypes = 'Daily'  
        $Schedule.FrequencySubDayTypes = 'Once'  
        $Schedule.FrequencyInterval = 1  
        $Schedule.ActiveStartDate = get-date  
        $schedule.ActiveStartTimeOfDay = '23:46:00'
        $Schedule.IsEnabled = $true
        $Schedule.Create()  
        }
        # Set Schedule for Full User DBs to once a week just after midnight on Sunday

        $Job = $Jobs|Where-Object {$_.Name -like 'DatabaseBackup - USER_DATABASES - FULL*'}
        if ($Job -eq $Null) 
        {Write-Output 'No Job with that name' 
        break}
                elseif ($Job.HasSchedule -eq $True)
        {
        Write-Output "Schedule already exists for $Job."
        }
        else{
        $Schedule = new-object Microsoft.SqlServer.Management.Smo.Agent.JobSchedule ($job,'Weekly Friday - Eveningt ++ ')
        $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
        $Schedule.ActiveEndTimeOfDay = '23:59:59'
        $Schedule.FrequencyTypes = 'Weekly' 
        $Schedule.FrequencyRecurrenceFactor = 1 
        $Schedule.FrequencyInterval = 32  
        $Schedule.ActiveStartDate = get-date  
        $schedule.ActiveStartTimeOfDay = '19:59:00'
        $Schedule.IsEnabled = $true
        $Schedule.Create()  
        }
        # Set Schedule for Diff User DBs to once a day just after midnight

        $Job = $Jobs|Where-Object {$_.Name -like 'DatabaseBackup - USER_DATABASES - DIFF*'}
        if ($Job -eq $Null) 
        {Write-Output 'No Job with that name' 
        break}
                elseif ($Job.HasSchedule -eq $True)
        {
        Write-Output "Schedule already exists for $Job."
        }
        else{
        $Schedule = new-object Microsoft.SqlServer.Management.Smo.Agent.JobSchedule ($job, 'Daily - Midnight ++ Not Sunday')
        $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
        $Schedule.ActiveEndTimeOfDay = '23:59:59'
        $Schedule.FrequencyTypes = 'Weekly'  
        $Schedule.FrequencyRecurrenceFactor = 1
        $Schedule.FrequencySubDayTypes = 'Once'  
        $Schedule.FrequencyInterval = 126 # Weekdays 62 + Saturdays 64  - https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.agent.jobschedule.frequencyinterval.aspx
        $Schedule.ActiveStartDate = get-date  
        $schedule.ActiveStartTimeOfDay = '00:16:00'
        $Schedule.IsEnabled = $true
        $Schedule.Create()  
        }
        # Set Schedule for Full System DBs to once a day just before midnight

        $Job = $Jobs|Where-Object {$_.Name -like 'DatabaseBackup - USER_DATABASES - LOG*'}
        if ($Job -eq $Null) 
        {Write-Output 'No Job with that name' 
        break}
                elseif ($Job.HasSchedule -eq $True)
        {
        Write-Output "Schedule already exists for $Job."
        }
        else{
        $Schedule = new-object Microsoft.SqlServer.Management.Smo.Agent.JobSchedule ($job, 'Hourly between 7 and 3')
        $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
        $Schedule.ActiveEndTimeOfDay = '02:59:59'
        $Schedule.FrequencyTypes = 'Daily'  
        $Schedule.FrequencySubDayTypes = 'Hour' 
        $Schedule.FrequencySubDayInterval = 1 
        $Schedule.FrequencyInterval = 1  
        $Schedule.ActiveStartDate = get-date  
        $schedule.ActiveStartTimeOfDay = '06:46:00'
        $Schedule.IsEnabled = $true
        $Schedule.Create()  
        }

        # Set Schedule for System DBCC to once a week just before midnight on Friday

        $Job = $Jobs|Where-Object {$_.Name -eq 'DatabaseIntegrityCheck - SYSTEM_DATABASES'}
        if ($Job -eq $Null) 
        {Write-Output 'No Job with that name' 
        break}
                elseif ($Job.HasSchedule -eq $True)
        {
        Write-Output "Schedule already exists for $Job."
        }
        else{
        $Schedule = new-object Microsoft.SqlServer.Management.Smo.Agent.JobSchedule ($job, 'Weekly Friday - Midnight --')
        $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
        $Schedule.ActiveEndTimeOfDay = '23:59:59'
        $Schedule.FrequencyTypes = 'Weekly' 
        $Schedule.FrequencyRecurrenceFactor = 1 
        $Schedule.FrequencyInterval = 64 
        $Schedule.ActiveStartDate = get-date  
        $schedule.ActiveStartTimeOfDay = '23:16:00'
        $Schedule.IsEnabled = $true
        $Schedule.Create()  
        }
        # Set Schedule for User DBCC to once a week on Saturday Evening

        $Job = $Jobs|Where-Object {$_.Name -eq 'DatabaseIntegrityCheck - USER_DATABASES'}
        if ($Job -eq $Null) 
        {Write-Output 'No Job with that name' 
        break}
                elseif ($Job.HasSchedule -eq $True)
        {
        Write-Output "Schedule already exists for $Job."
        }
        else{
        $Schedule = new-object Microsoft.SqlServer.Management.Smo.Agent.JobSchedule ($job, 'Weekly Saturday - Evening')
        $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
        $Schedule.ActiveEndTimeOfDay = '23:59:59'
        $Schedule.FrequencyTypes = 'Weekly' 
        $Schedule.FrequencyRecurrenceFactor = 1 
        $Schedule.FrequencyInterval = 64 
        $Schedule.ActiveStartDate = get-date  
        $schedule.ActiveStartTimeOfDay = '20:16:00'
        $Schedule.IsEnabled = $true
        $Schedule.Create()  
        }
        # Set Schedule for User IndexOptimize to once a week on Saturday Morning

        $Job = $Jobs|Where-Object {$_.Name -eq 'IndexOptimize - USER_DATABASES'}
        if ($Job -eq $Null) 
        {Write-Output 'No Job with that name' 
        break}
                elseif ($Job.HasSchedule -eq $True)
        {
        Write-Output "Schedule already exists for $Job."
        }
        else{
        $Schedule = new-object Microsoft.SqlServer.Management.Smo.Agent.JobSchedule ($job, 'Weekly Saturday - AM')
        $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
        $Schedule.ActiveEndTimeOfDay = '23:59:59'
        $Schedule.FrequencyTypes = 'Weekly' 
        $Schedule.FrequencyRecurrenceFactor = 1 
        $Schedule.FrequencyInterval = 64 
        $Schedule.ActiveStartDate = get-date  
        $schedule.ActiveStartTimeOfDay = '01:16:00'
        $Schedule.IsEnabled = $true
        $Schedule.Create()  
        }
        # Set Schedule for CommandLog Cleanup to once a week on Sunday Evening

        $Job = $Jobs|Where-Object {$_.Name -eq 'CommandLog Cleanup'}
        if ($Job -eq $Null) 
        {Write-Output 'No Job with that name' 
        break}
                elseif ($Job.HasSchedule -eq $True)
        {
        Write-Output "Schedule already exists for $Job."
        }
        else{
        $Schedule = new-object Microsoft.SqlServer.Management.Smo.Agent.JobSchedule ($job, 'Weekly Sunday - Evening ')
        $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
        $Schedule.ActiveEndTimeOfDay = '23:59:59'
        $Schedule.FrequencyTypes = 'Weekly' 
        $Schedule.FrequencyRecurrenceFactor = 1 
        $Schedule.FrequencyInterval = 1 
        $Schedule.ActiveStartDate = get-date  
        $schedule.ActiveStartTimeOfDay = '19:16:00'
        $Schedule.IsEnabled = $true
        $Schedule.Create()  
        }
        # Set Schedule for Output File Cleanup to once a week on Sunday Evening

        $Job = $Jobs|Where-Object {$_.Name -eq 'Output File Cleanup'}
        if ($Job -eq $Null) 
        {Write-Output 'No Job with that name' 
        break}
                elseif ($Job.HasSchedule -eq $True)
        {
        Write-Output "Schedule already exists for $Job."
        }
        else{
        $Schedule = new-object Microsoft.SqlServer.Management.Smo.Agent.JobSchedule ($job, 'Weekly Sunday - Evening ')
        $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
        $Schedule.ActiveEndTimeOfDay = '23:59:59'
        $Schedule.FrequencyTypes = 'Weekly' 
        $Schedule.FrequencyRecurrenceFactor = 1 
        $Schedule.FrequencyInterval = 1 
        $Schedule.ActiveStartDate = get-date  
        $schedule.ActiveStartTimeOfDay = '19:16:00'
        $Schedule.IsEnabled = $true
        $Schedule.Create()  
        }
        # Set Schedule for sp_delete_backuphistory to once a week on Sunday Evening

        $Job = $Jobs|Where-Object {$_.Name -eq 'sp_delete_backuphistory'}
        if ($Job -eq $Null) 
        {Write-Output 'No Job with that name' 
        break}
                elseif ($Job.HasSchedule -eq $True)
        {
        Write-Output "Schedule already exists for $Job."
        }
        else{
        $Schedule = new-object Microsoft.SqlServer.Management.Smo.Agent.JobSchedule ($job, 'Weekly Sunday - Evening ')
        $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
        $Schedule.ActiveEndTimeOfDay = '23:59:59'
        $Schedule.FrequencyTypes = 'Weekly' 
        $Schedule.FrequencyRecurrenceFactor = 1 
        $Schedule.FrequencyInterval = 1 
        $Schedule.ActiveStartDate = get-date  
        $schedule.ActiveStartTimeOfDay = '19:16:00'
        $Schedule.IsEnabled = $true
        $Schedule.Create()  
        }
        # Set Schedule for sp_purge_jobhistory to once a week on Sunday Evening

        $Job = $Jobs|Where-Object {$_.Name -eq 'sp_purge_jobhistory'}
        if ($Job -eq $Null) 
        {Write-Output 'No Job with that name' 
        break}
                elseif ($Job.HasSchedule -eq $True)
        {
        Write-Output "Schedule already exists for $Job."
        }
        else{
        $Schedule = new-object Microsoft.SqlServer.Management.Smo.Agent.JobSchedule ($job, 'Weekly Sunday - Evening ')
        $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
        $Schedule.ActiveEndTimeOfDay = '23:59:59'
        $Schedule.FrequencyTypes = 'Weekly' 
        $Schedule.FrequencyRecurrenceFactor = 1 
        $Schedule.FrequencyInterval = 1 
        $Schedule.ActiveStartDate = get-date  
        $schedule.ActiveStartTimeOfDay = '19:16:00'
        $Schedule.IsEnabled = $true
        $Schedule.Create()  
        }
        }