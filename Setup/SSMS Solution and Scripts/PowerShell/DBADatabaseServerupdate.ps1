 <# 
.SYNOPSIS  
     This Script will check all of the instances in the InstanceList and gather the Windows Info and save to the Info.ServerInfo table

.DESCRIPTION 
     This Script will check all of the instances in the InstanceList and gather the Windows Info and save to the Info.ServerInfo table

.PARAMETER 

.EXAMPLE 

.NOTES 
    AUTHOR: Rob Sewell sqldbawithabeard.com 
    DATE: 22/05/2015 - Initial
            21/07/2015 - Added Inactive column to gather instances query
            18/08/2015 -= Added non-contactable to the instances query
#> 

Import-Module sqlps -DisableNameChecking

$CentralDBAServer = ''
$CentralDatabaseName = 'DBADatabase'
$AlltheServers = Invoke-Sqlcmd -ServerInstance $CentralDBAServer -Database $CentralDatabaseName -Query 'SELECT DISTINCT [ServerName] FROM [DBADatabase].[dbo].[InstanceList] Where Inactive = 0    AND NotContactable = 0'
$ServerNames = $AlltheServers| Select-Object ServerName -ExpandProperty ServerName
$Date = Get-Date -Format ddMMyyyy_HHmmss
$LogFile = '\LogFiles\DBADatabaseServerUpdate_' + $Date + '.log'

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
$ErrorMessage = " On $Connection or $ServerName " + $Additional + $_.Exception.Message + $_.Exception.InnerException.InnerException.message
$Message = ' This message came from the Automated Powershell script updating the DBA Database with Server Information'
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
$Message = ' This message came from the Automated Powershell script updating the DBA Database with Server Information'

$Msg = $ErrorMessage + ' ' + $FailedItem + ' ' + $Message
Write-EventLog -LogName Application -Source 'SQLAUTOSCRIPT' -EventId 1 -EntryType Error -Message $Msg
}


Write-Log -Path $LogFile -Message ' Script Started'
Write-Log -Path $LogFile -Message "Gathering Info for $ServerNames"
foreach($ServerName in $ServerNames)
{
$DNSHostName = 'NOT GATHERED'
$Domain = 'NOT GATHERED'
$OperatingSystem = 'NOT GATHERED'
$NoProcessors = 'NOT GATHERED'
$IP = 'NOT GATHERED'
$RAM = 'NOT GATHERED'

try{
$Info = get-wmiobject win32_computersystem -ComputerName $ServerName -ErrorAction Stop|
Select-Object DNSHostName,Domain,
@{Name='RAM';Expression={'{0:n0}' -f($_.TotalPhysicalMemory/1gb)}},
NumberOfLogicalProcessors
}
catch{
Catch-Block " Failed to Gather WMI Computer System information from $ServerName"
}

try
{
$OS =  Get-WmiObject Win32_OperatingSystem  -ComputerName $ServerName| Select-Object @{name='Name';Expression={($_.caption)}} 
}
catch{
Catch-Block " Failed to Gather WMI OS information from $ServerName"
}

Try
{
if($ServerName -eq $env:COMPUTERNAME)
{$IP = (Get-WmiObject -ComputerName $ServerName -class win32_NetworkAdapterConfiguration -Filter 'ipenabled = "true"' -ErrorAction Stop).ipaddress[0] }
else {$IP = [System.Net.Dns]::GetHostAddresses($ServerName).IPAddressToString }
Write-Log -Path $LogFile -Message "WMI Info gathered for $ServerName "
}
catch{
Catch-Block " Failed to Gather WMI Network information from $ServerName"
}
$DNSHostName = $info.DNSHostName
$Domain = $Info.Domain
$OperatingSystem = $OS.Name
$NoProcessors = $Info.NumberOfLogicalProcessors
$RAM = $Info.RAM

try{
$Exists = Invoke-Sqlcmd -ServerInstance $CentralDBAServer -Database $CentralDatabaseName -Query "SELECT [ServerName] FROM [DBADatabase].[Info].[ServerOSInfo] WHERE ServerName = '$ServerName'"
}
catch{
Catch-Block ' Failed to get Servers from DBA Database '
break
}
if ($Exists)
{
$Query = @"
UPDATE [Info].[ServerOSInfo]
   SET [DateChecked] = GetDate()
      ,[ServerName] = '$ServerName'
      ,[DNSHostName] = '$DNSHostName'
      ,[Domain] = '$Domain'
      ,[OperatingSystem] = '$OperatingSystem'
      ,[NoProcessors] = '$NOProcessors'
      ,[IPAddress] = '$IP'
      ,[RAM] = '$RAM'
WHERE ServerName = '$ServerName'
"@
}
else
{
$Query = @"
INSERT INTO [Info].[ServerOSInfo]
           ([DateChecked]
           ,[ServerName]
           ,[DNSHostName]
           ,[Domain]
           ,[OperatingSystem]
           ,[NoProcessors]
           ,[IPAddress]
           ,[RAM])
     VALUES
   ( GetDate()
      ,'$ServerName'
      ,'$DNSHostName'
      ,'$Domain'
      ,'$OperatingSystem'
      ,'$NoProcessors'
      ,'$IP'
      ,'$RAM')
"@
}
Try{
Invoke-Sqlcmd -ServerInstance $CentralDBAServer -Database $CentralDatabaseName -Query $Query
Write-Log -Path $LogFile -Message "Details update for $ServerName"
}
catch
{ Catch-Block ' Failed to write to DBA Database'
Write-Log -Path $LogFile -Message "$Query"}

}

Write-Log -Path $LogFile -Message 'Script Finished'