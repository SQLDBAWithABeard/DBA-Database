 <# 
.SYNOPSIS  
     This Script will check all databases for the last read and write times and store in a table

.DESCRIPTION 
     This Script will check all of the instances in the InstanceList check all databases for the 
     last read and write times and store in the LastUsed table
.PARAMETER 

.EXAMPLE 

.NOTES 
    AUTHOR: Rob Sewell sqldbawithabeard.com 
    DATE: 30/09/2015 - Initial
                    

    Does NOT work with SQL 2000 boxes
#> 

$CentralDBAServer = ''
$CentralDatabaseName = 'DBADatabase'
$Date = Get-Date -Format ddMMyyyy_HHmmss
$LogFile = '\LogFiles\DBADatabaseLastUsedUpdate_' + $Date + '.log'

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
$Query = @"
 SELECT [ServerName]
      ,[InstanceName]
      ,[Port]
  FROM [DBADatabase].[dbo].[InstanceList]
  Where Inactive = 0 
  AND NotContactable = 0
"@

# Create Log File

try{
New-Item -Path $LogFile -ItemType File
$Msg = ' New File Created'
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
try{
$AlltheServers= Invoke-Sqlcmd -ServerInstance $CentralDBAServer -Database $CentralDatabaseName -Query $query -ErrorAction Stop
$ServerNames = $AlltheServers| Select-Object ServerName,InstanceName,Port
Write-Log -Path $LogFile -Message ' Instances gathered from DBA Database'
}
catch
{
Catch-Block ' Failed to gather Server and Instance names from the DBA Database'
}

foreach ($ServerName in $ServerNames)
{
## $ServerName
 $InstanceName =  $ServerName|Select-Object InstanceName -ExpandProperty InstanceName
 $Port = $ServerName| Select-Object Port -ExpandProperty Port
$ServerName = $ServerName|Select-Object ServerName -ExpandProperty ServerName 
 $Connection = $ServerName + '\' + $InstanceName + ',' + $Port
# Set SQL Query - Remember to add any system databases or databases to ignore into the NOT IN
$query = @"
WITH agg AS
(
  SELECT
       max(last_user_seek) last_user_seek,
       max(last_user_scan) last_user_scan,
       max(last_user_lookup) last_user_lookup,
       max(last_user_update) last_user_update,
       sd.name dbname
   FROM
       sys.dm_db_index_usage_stats, master..sysdatabases sd
   WHERE
      sd.name not in('master','tempdb','model','msdb','distribution','MSSQL1_distribution')
   AND
     database_id = sd.dbid  group by sd.name
)
SELECT
   dbname,
   last_read = MAX(last_read),
   last_write = MAX(last_write)
FROM
(
   SELECT dbname, last_user_seek, NULL FROM agg
   UNION ALL
  SELECT dbname, last_user_scan, NULL FROM agg
   UNION ALL
   SELECT dbname, last_user_lookup, NULL FROM agg
   UNION ALL
   SELECT dbname, NULL, last_user_update FROM agg
) AS x (dbname, last_read, last_write)
GROUP BY
   dbname
ORDER BY 1;
"@
# Get the time SQL was restarted
try{
$svr = New-Object 'Microsoft.SQLServer.Management.Smo.Server' $Connection
if($svr.VersionMajor -eq 8)
{continue} ##ignore SQL 2000 boxes
$db = $svr.Databases['TempDB']
$SQLRestarted = $db.CreateDate
Write-Log -Path $LogFile -Message " Gathered TempDB create date from $Connection"
}
catch
{
Catch-Block " Failed to gather TempDB create date from $Connection"
}
try{
#Run Query against SQL Server
$Results = Invoke-Sqlcmd -ServerInstance $Connection -Query $query -Database master -ErrorAction Stop
Write-Log -Path $LogFile -Message " Gathered Last Used data create date from $Connection"
}
catch
{
Catch-Block " Failed to gather Last Used data from $Connection"
continue
}
foreach($Result in $Results)
{
$DBNull = [System.DBNull]::Value  #' just in case we need to look at Nulls
$Name = $Result.dbname
$LastRead = $Result.last_read
$LastWrite = $Result.last_write
try
{
$Query = @"
INSERT INTO [Info].[LastUsed]
           ([DatabaseID]
           ,[DateChecked]
           ,[LastRead]
           ,[LastWrite]
		   ,[SQLRestarted])
     VALUES
           ((SELECT DatabaseID from [info].[Databases] 
		   WHERE InstanceID = (SELECT InstanceID from [dbo].[InstanceList] 
								WHERE ServerName = '$ServerName' 
								AND InstanceName = '$InstanceName')
			AND Name = '$Name')
           ,GetDate()
           ,'$LastRead'
           ,'$LastWrite'
		   ,'$SQLRestarted')
"@
Invoke-Sqlcmd -ServerInstance $CentralDBAServer -Database $CentralDatabaseName -Query $query -ErrorAction Stop
## Write-Log -Path $LogFile -Message " Loaded DBADatabase with details from $Connection for $Name"  ## For Debugging uncomment this line
}
catch
{
Catch-Block " Failed to insert data into DBADatabase for $Connection - Query = $query"
continue
}
}


}

$query = @"
 UPDATE [DBADatabase].[Info].[LastUsed]
 SET LastRead = NULL
 WHERE LastRead = '1900-01-01 00:00:00.000'

 UPDATE [DBADatabase].[Info].[LastUsed]
 SET LastWrite= NULL
 WHERE LastWrite= '1900-01-01 00:00:00.000'
"@
try{
Invoke-Sqlcmd -ServerInstance $CentralDBAServer -Database $CentralDatabaseName -Query $query -ErrorAction Stop
Write-Log -Path $LogFile -Message ' Updated the Nulls'
}
catch
{
Catch-Block " Failed to update the NULLS $query"
}

Write-Log -Path $LogFile -Message ' Script Finished'