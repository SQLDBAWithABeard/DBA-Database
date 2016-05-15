<# 
.SYNOPSIS  
     This Script will check all of the instances in the InstanceList to see which scripts have been installed and log to the info.ScriptInstall table

.DESCRIPTION 
    This Script will check all of the instances in the InstanceList to see which scripts have been installed and log to the info.ScriptInstall table

.PARAMETER 

.EXAMPLE 

.NOTES 
    AUTHOR: Rob Sewell sqldbawithabeard.com 
    DATE: 22/05/2015 - Initial
                    18/08/2015 - Added Inactive nad Non-Contactable columns to server query
#> 


# Load SMO extension
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo') | Out-Null;
$Date = Get-Date -Format ddMMyyyy_HHmmss
$LogFile = '\LogFiles\DBADatabaseSQLScriptInstall_' + $Date + '.log'
$CentralDBAServer = ''
$CentralDatabaseName = 'DBADatabase'

<#
.Synopsis
   Write-Log writes a message to a specified log file with the current time stamp.
.DESCRIPTION
   The Write-Log function is designed to add logging capability to other scripts.
   In addition to writing output and/or verbose you can write to a log file for
   later debugging.

   By default the function will create the path and file if it does not 
   exist. 
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 4/3/2015 10:29:58 AM 

   Changelog:
    * Renamed LogPath parameter to Path to keep it standard - thanks to @JeffHicks
    * Revised the Force switch to work as it should - thanks to @JeffHicks

   To Do:
    * Add error handling if trying to create a log file in a inaccessible location.
    * Add ability to write $Message to $Verbose or $Error pipelines to eliminate
      duplicates.

.EXAMPLE
   Write-Log -Message "Log message" 
   Writes the message to c:\Logs\PowerShellLog.log
.EXAMPLE
   Write-Log -Message "Restarting Server" -Path c:\Logs\Scriptoutput.log
   Writes the content to the specified log file and creates the path and file specified. 
.EXAMPLE
   Write-Log -Message "Does not exist" -Path c:\Logs\Script.log -Level Error
   Writes the message to the specified log file as an error message, and writes the message to the error pipeline.
#>
function Write-Log
{
    [CmdletBinding()]
    #[Alias('wl')]
    [OutputType([int])]
    Param
    (
        # The string to be written to the log.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias('LogContent')]
        [string]$Message,

        # The path to the log file.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [Alias('LogPath')]
        [string]$Path='C:\Logs\PowerShellLog.log',

        [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    Position=3)]
        [ValidateSet('Error','Warn','Info')]
        [string]$Level='Info',

        [Parameter(Mandatory=$false)]
        [switch]$NoClobber
    )

    Begin
    {
    }
    Process
    {
        
        if ((Test-Path $Path) -AND $NoClobber) {
            Write-Warning "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
            Return
            }

        # If attempting to write to a log file in a folder/path that doesn't exist
        # to create the file include path.
        elseif (!(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $NewLogFile = New-Item $Path -Force -ItemType File
            }

        else {
            # Nothing to see here yet.
            }

        # Now do the logging and additional output based on $Level
        switch ($Level) {
            'Error' {
                Write-Error $Message
                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ERROR: $Message" | Out-File -FilePath $Path -Append
                }
            'Warn' {
                Write-Warning $Message
                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') WARNING: $Message" | Out-File -FilePath $Path -Append
                }
            'Info' {
                Write-Verbose $Message
                Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') INFO: $Message" | Out-File -FilePath $Path -Append
                }
            }
    }
    End
    {
    }
}

function Catch-Block
{
param ([string]$Additional)
$ErrorMessage = " On $Connection " + $Additional + $_.Exception.Message + $_.Exception.InnerException.InnerException.message
$Message = ' This message came from the Automated Powershell script updating the DBA Database with SQL Information'
$Msg = $Additional + $ErrorMessage + ' ' + $Message
Write-Log -Path $LogFile -Message $ErrorMessage -Level Error
Write-EventLog -LogName Application -Source 'SQLAUTOSCRIPT' -EventId 1 -EntryType Error -Message $Msg
}

# Create Log File

try{
New-Item -Path $LogFile -ItemType File
$Msg = 'New File Created'
Write-Log -Path $LogFile -Message $Msg
}
catch
{
$ErrorMessage = $_.Exception.Message
$FailedItem = $_.Exception.ItemName
$Message = ' This message came from the Automated Powershell script updating the DBA Database with SQL Information'

$Msg = $ErrorMessage + ' ' + $FailedItem + ' ' + $Message
Write-EventLog -LogName Application -Source 'SQLAUTOSCRIPT' -EventId 1 -EntryType Error -Message $Msg
}

Write-Log -Path $LogFile -Message ' Script Started'

 $Query = @"
 SELECT [ServerName]
      ,[InstanceName]
      ,[Port]
  FROM [DBADatabase].[dbo].[InstanceList]
  Where Inactive = 0 
  AND NotContactable = 0
"@

try{
$AlltheServers= Invoke-Sqlcmd -ServerInstance $CentralDBAServer -Database $CentralDatabaseName -Query $query
$ServerNames = $AlltheServers| Select-Object ServerName,InstanceName,Port
}
catch
{
Catch-Block ' Failed to gather Server and Instance names from the DBA Database'
}

foreach ($ServerName in $ServerNames)
{
$ServerName
$InstanceName =  $ServerName|Select-Object InstanceName -ExpandProperty InstanceName
$Port = $ServerName| Select-Object Port -ExpandProperty Port
$ServerName = $ServerName|Select-Object ServerName -ExpandProperty ServerName 
$Connection = $ServerName + '\' + $InstanceName + ',' + $Port

 try{
 $srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $Connection
 }
 catch
 {
 Catch-Block " Failed to Connect to $Connection"
 continue
 }
 if (!( $srv.version)){
 Catch-Block " Failed to Connect to $Connection"
 continue
 }

 $db = $srv.Databases['DBA-Admin']
 $Check = $db.Status
 $HasDBAdminDB = $false
 if($Check)
 {
 $HasDBAdminDB = $True
 }

###  Ola
 $Check = $db.StoredProcedures['CommandExecute']
 $OlaSP = $false
 if($Check)
 {
  $OlaSP = $true
 }

###  Ola Restore Command Proc
 $Check = $db.StoredProcedures['RestoreCommand']
 $HasOlaRestore = $false
 if($Check)
 {
 $HasOlaRestore = $true
 }
###  Restore Command Job Steps
$Jobs = $srv.JobServer.Jobs
$OlaJob = $Jobs|Where-Object{$_.name -like 'DatabaseBackup - SYSTEM_DATABASES - FULL*'}
$Check = $OlaJob.JobSteps|Where-Object{$_.name -eq 'Generate Restore Script'}
$RestoreScript = $false
if($Check)
 {
 $RestoreScript = $true
 }
 ###  sp_blitz
 $mastedb = $srv.Databases['master']
 $Check = $mastedb.StoredProcedures|Where-Object{$_.Name -eq 'SP_blitz'}
$HasSP_Blitz = $false
if($Check)
 {
 $HasSP_Blitz  = $true
 }

###  SP_AskBrent

 $mastedb = $srv.Databases['master']
 $Check = $mastedb.StoredProcedures|Where-Object{$_.Name -eq 'SP_AskBrent'}
$HasSP_AskBrent = $false
if($Check)
 {
$HasSP_AskBrent  = $true
 }
###  sp_BlitzCache

 $mastedb = $srv.Databases['master']
 $Check = $mastedb.StoredProcedures|Where-Object{$_.Name -eq 'SP_AskBrent'}
$HasSP_BlitzCache = $false
if($Check)
 {
$HasSP_BlitzCache  = $true
 }
###  sp_BlitzIndex

 $mastedb = $srv.Databases['master']
 $Check = $mastedb.StoredProcedures|Where-Object{$_.Name -eq 'sp_BlitzIndex'}
$Hassp_BlitzIndex = $false
if($Check)
 {
$Hassp_BlitzIndex  = $true
 }
###  sp_BlitzTrace

 $mastedb = $srv.Databases['master']
 $Check = $mastedb.StoredProcedures|Where-Object{$_.Name -eq 'sp_BlitzTrace'}
$Hassp_BlitzTrace = $false
if($Check)
 {
$Hassp_BlitzTrace  = $true
 }
###  sp_whoisactive

 $mastedb = $srv.Databases['master']
 $Check = $mastedb.StoredProcedures|Where-Object{$_.Name -eq 'sp_whoisactive'}
$Hassp_whoisactive = $false
if($Check)
 {
$Hassp_whoisactive = $true
 }
###  whoisactiveagentjob

$Check = $Jobs|Where-Object{$_.name -eq 'SP_WhoisActive to Table' }

$whoisactiveagentjob = $false
if($Check)
 {
 $whoisactiveagentjob = $true
 }

###  ScheduleOlaJobs

$HasOlaJobSchedule = $OlaJOb.HasSchedule

###  Match-SQLLoginsJob

$Check = $JObs|Where-Object {$_.Name -eq 'Match Server Logins'}

$HasMatchSQLLoginsJob = $false
if($Check)
 {
 $HasMatchSQLLoginsJob = $true
 }

###  CreateSPBlitzTableJob
$Check = $JObs|Where-Object {$_.Name -eq 'Log SP_Blitz to table'}

$HasSPBlitzTableJob = $false
if($Check)
 {
 $HasSPBlitzTableJob = $true
 }

###  SPAskBrentToTableAgentJob

$Check = $JObs|Where-Object {$_.Name -eq 'Log SP_AskBrent To Table'}

$HasAskBrentToTableAgentJob= $false
if($Check)
 {
 $HasAskBrentToTableAgentJob = $true
 }

###  CreateOLANPTPRODJob

$Check = $Jobs|Where-Object{$_.name -like 'DatabaseBackup - SYSTEM_DATABASES - FULL - PROD - Newport'}

$HasOLANPTPRODJob = $false
if($Check)
 {
 $HasOLANPTPRODJob = $true
 }

###  CreateOLANPTDEVJob

$Check = $Jobs|Where-Object{$_.name -like 'DatabaseBackup - SYSTEM_DATABASES - FULL - DEV - Newport'}

$HasOLANPTDEVJob = $false
if($Check)
 {
$HasOLANPTDEVJob= $true
 }

###  CreateOLASLOPRODJob

$Check = $Jobs|Where-Object{$_.name -like 'DatabaseBackup - SYSTEM_DATABASES - FULL - PROD - Slough'}

$HasOLASLORODJob = $false
if($Check)
 {
$HasOLASLORODJob= $true
 }

###  CreateOLASLODEVJob

$Check = $Jobs|Where-Object{$_.name -like 'DatabaseBackup - SYSTEM_DATABASES - FULL - DEV - Slough'}

$HasOLASLODEVJob = $false
if($Check)
 {
$HasOLASLODEVJob = $true
 }

 ### AGFailoverAlerts

 $Check = $srv.JobServer.Alerts|Where-Object {$_.Name -eq 'AG Data Movement - Resumed' -or $_.Name -eq 'AG Data Movement - Suspended' -or $_.Name -eq 'AG Role Change'}

 $AGFailoverAlerts = $false
if($Check.Count -eq 3)
 {
$AGFailoverAlerts = $true
 }

  ### EnableDBMail

 $Check = $srv.Mail|Where-Object{$_.Profiles.Name -eq 'SQLMailProfile' -and $_.Accounts.Name -eq 'SQLMailAccount' -and $_.Accounts.Mailservers.Name -eq 'mail.teleperformance.co.uk'}

 $EnableDBMail = $false
if($Check)
 {
$EnableDBMail = $true
 }


  ### Add_Basic_Trace_XE

$Check = Invoke-Sqlcmd -ServerInstance $Connection -Database master -Query "SELECT name from sys.server_event_sessions where name = 'Basic_Trace'"

 $Add_Basic_Trace_XE = $false
if($Check)
 {
$Add_Basic_Trace_XE = $true
 }



 # Check if Entry already exists
 try{
 $query = @"
 SELECT  SI.[InstanceID]
    FROM [DBADatabase].[Info].[Scriptinstall] as SI
  JOIN
[DBADatabase].[dbo].[InstanceList] as IL
ON
IL.[InstanceID] = SI.InstanceID
   WHERE IL.ServerName = '$ServerName' 
 AND IL.[InstanceName] = '$InstanceName'
"@
# $Query
$Exists = Invoke-Sqlcmd -ServerInstance $CentralDBAServer -Database $CentralDatabaseName -Query $Query
}
catch
{Catch-Block " Failed to gather Instance Name for Exists check $ServerName $InstanceName "
Break}

if($Exists)
{
 $Query = @"
 USE [DBADatabase]
GO

UPDATE  [Info].[Scriptinstall]

          SET 
           [HasDBAdminDB] =  '$HasDBAdminDB' 
           ,[OlaSP] = '$OlaSP' 
           ,[HasOlaRestore] = '$HasOlaRestore' 
           ,[RestoreScript] = '$RestoreScript' 
           ,[HasSP_Blitz] = '$HasSP_Blitz' 
           ,[HasSP_AskBrent] = '$HasSP_AskBrent' 
           ,[HasSP_BlitzCache] = '$HasSP_BlitzCache' 
           ,[Hassp_BlitzIndex] = '$Hassp_BlitzIndex' 
           ,[Hassp_BlitzTrace] = '$Hassp_BlitzTrace' 
           ,[Hassp_whoisactive] = '$Hassp_whoisactive' 
           ,[whoisactiveagentjob] = '$whoisactiveagentjob' 
           ,[HasOlaJobSchedule] = '$HasOlaJobSchedule' 
           ,[HasMatchSQLLoginsJob] = '$HasMatchSQLLoginsJob' 
           ,[HasSPBlitzTableJob] = '$HasSPBlitzTableJob' 
           ,[HasAskBrentToTableAgentJob] = '$HasAskBrentToTableAgentJob'
           ,[HasOLANPTPRODJob] = '$HasOLANPTPRODJob' 
           ,[HasOLANPTDEVJob] = '$HasOLANPTDEVJob'
           ,[HasOLASLORODJob] = '$HasOLASLORODJob' 
           ,[HasOLASLODEVJob] = '$HasOLASLODEVJob' 
           ,[AGFailoverAlerts] = '$AGFailoverAlerts' 
           ,[EnableDBMail] =  '$EnableDBMail'
           ,[Add_Basic_Trace_XE] = '$Add_Basic_Trace_XE'
           WHERE [InstanceID] = (SELECT InstanceID from dbo.InstanceList WHERE ServerName = '$ServerName' AND InstanceName = '$InstanceName')
            
"@
}
else
{
 $Query = @"
 USE [DBADatabase]
GO

INSERT INTO [Info].[Scriptinstall]
           ([InstanceID]
           ,[HasDBAdminDB]
           ,[OlaSP]
           ,[HasOlaRestore]
           ,[RestoreScript]
           ,[HasSP_Blitz]
           ,[HasSP_AskBrent]
           ,[HasSP_BlitzCache]
           ,[Hassp_BlitzIndex]
           ,[Hassp_BlitzTrace]
           ,[Hassp_whoisactive]
           ,[whoisactiveagentjob]
           ,[HasOlaJobSchedule]
           ,[HasMatchSQLLoginsJob]
           ,[HasSPBlitzTableJob]
           ,[HasAskBrentToTableAgentJob]
           ,[HasOLANPTPRODJob]
           ,[HasOLANPTDEVJob]
           ,[HasOLASLORODJob]
           ,[HasOLASLODEVJob]
           ,[AGFailoverAlerts]
           ,[EnableDBMail] 
           ,[Add_Basic_Trace_XE])
     VALUES
           ((SELECT InstanceID from dbo.InstanceList WHERE ServerName = '$ServerName' AND InstanceName = '$InstanceName')
           ,'$HasDBAdminDB' 
           ,'$OlaSP' 
           ,'$HasOlaRestore' 
           ,'$RestoreScript' 
           ,'$HasSP_Blitz' 
           ,'$HasSP_AskBrent' 
           ,'$HasSP_BlitzCache' 
           ,'$Hassp_BlitzIndex' 
           ,'$Hassp_BlitzTrace' 
           ,'$Hassp_whoisactive' 
           ,'$whoisactiveagentjob' 
           ,'$HasOlaJobSchedule' 
           ,'$HasMatchSQLLoginsJob' 
           ,'$HasSPBlitzTableJob' 
           ,'$HasAskBrentToTableAgentJob' 
           ,'$HasOLANPTPRODJob' 
           ,'$HasOLANPTDEVJob' 
           ,'$HasOLASLORODJob' 
           ,'$HasOLASLODEVJob' 
           ,'$AGFailoverAlerts'
           ,'$EnableDBMail' 
           ,'$Add_Basic_Trace_XE'
		   )
"@
}
try{
## $Query
Invoke-Sqlcmd -ServerInstance $CentralDBAServer -Database $CentralDatabaseName -Query $query -ErrorAction Stop
}
catch
{
Catch-Block " Failed to insert information for $Connection"
}
$Msg = " Info added for $Connection"
Write-Log -Path $LogFile -Message $Msg
 }

 Write-Log -Path $LogFile -Message 'Script Finished'