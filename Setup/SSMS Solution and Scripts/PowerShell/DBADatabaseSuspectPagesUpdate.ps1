 <# 
.SYNOPSIS  
     This Script will check all of the instances in the InstanceList and add any suspect pages details

.DESCRIPTION 
     This Script will check all of the instances in the InstanceList, check the suspect page table in msdb and add any results to the DBA Database
.PARAMETER 

.EXAMPLE 

.NOTES 
    AUTHOR: Rob Sewell sqldbawithabeard.com 
    DATE: 27/06/2015
#> 

$Date = Get-Date -Format ddMMyyyy_HHmmss
$LogFile = '\LogFile\DBADatabaseSuspectPagesUpdate_' + $Date + '.log'
$CentralDBAServer = ''
$CentralDatabaseName = 'DBADatabase'
# Load SMO extension
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo') | Out-Null;


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

$Query = " SELECT [ServerName] ,[InstanceName] ,[Port] FROM [DBADatabase].[dbo].[InstanceList] Where Inactive = 0  AND NotContactable = 0 "

try{
$AlltheServers= Invoke-Sqlcmd -ServerInstance $CentralDBAServer -Database $CentralDatabaseName -Query $query
$ServerNames = $AlltheServers| Select ServerName,InstanceName,Port
Write-Log -Path $LogFile -Message "Collected ServerNames from DBA Database"
}
catch
{
Catch-Block " Failed to gather Server and Instance names from the DBA Database"
}

$query = @"
Select 
DB_NAME(database_id) as DBName, 
File_Name(file_id) as FileName, 
page_id, 
CASE event_type 
WHEN 1 THEN '823 or 824 or Torn Page'
WHEN 2 THEN 'Bad Checksum'
WHEN 3 THEN 'Torn Page'
WHEN 4 THEN 'Restored'
WHEN 5 THEN 'Repaired (DBCC)'
WHEN 7 THEN 'Deallocated (DBCC)'
END as EventType, 
error_count, 
last_update_date  
from dbo.suspect_pages
"@
foreach ($ServerName in $ServerNames)
{
 $InstanceName =  $ServerName|Select InstanceName -ExpandProperty InstanceName
 $Port = $ServerName| Select Port -ExpandProperty Port
$ServerName = $ServerName|Select ServerName -ExpandProperty ServerName 
 $Connection = $ServerName + '\' + $InstanceName + ',' + $Port
Write-Log  "Gathering Information from $Connection"
 try
 {
 $srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $Connection
 }
catch
{
Catch-Block " Failed to connect to $Connection"
continue
}
 if (!( $srv.version)){
 Catch-Block " Failed to Connect to $Connection"
 continue
 }
 if ($srv.VersionMajor -ge 9)
 {
$table = $srv.Databases['msdb'].tables['suspect_pages']
if($table.RowCount -gt 0)
{
$Result = Invoke-Sqlcmd -ServerInstance $ServerName -Database msdb -Query $Query
Write-Log -Path $LogFile -Message "WARNING : - $servername has this result :- $Result" -Level Warn

$DatabaseName     = $Result.DatabaseName 
$ServerName       = $Result.ServerName
$FileName         = $Result.FileName 
$Page_id          = $Result.Page_id  
$EventType        = $Result.EventType 
$Error_count      = $Result.Error_count
$last_update_date = $Result.last_update_date

$query = @"
EXEC   [dbo].[usp_InsertSuspectPages]
		@ServerName = N'" + $ServerName + "',
		@DatabaseName = N'" + $DatabaseName + "',
		@FileName = N'" + $FileName + "',
		@Page_id = " + $Page_id + ",
		@EventType = N'" + $EventType + "',
		@Error_count = " + $Error_count + ",
		@last_update_date = N'" + $last_update_date + "'
"@
try
{
Invoke-Sqlcmd -ServerInstance $CentralDBAServer -Database $CentralDatabaseName -Query $Query
}
catch
{
Catch-Block "FAILED: To add details to suspect page table : - $Query"
}
}
else
{
Write-Log -Path $LogFile -Message "$servername has 0 rows in suspect pages table"
}
 }
 else
 {
Write-Log -Path $LogFile -Message "$ServerName version lower than SQL 2005 no query run"
 }
 }