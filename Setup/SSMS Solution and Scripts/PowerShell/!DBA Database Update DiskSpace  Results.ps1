<# 
.NOTES 
    Name: Drive Space  to DBA Database.ps1 
    Author: Rob Sewell http://sqldbawithabeard.com
    Requires: 
    Version History: 
                    Version 0.1 
    
.SYNOPSIS 
    Adds data to the DBA database for Disk Space in a server list 

.DESCRIPTION 
    Connects to a server list and iterates though reading the disk space and adds data to the DBA Database - This is run as an agent job on HMDBS02
#> 

$Date = Get-Date -Format ddMMyyyy_HHmmss

$CentralDBAServer = ''
$CentralDatabaseName = 'DBADatabase'
$DBADatabase = 'DBADatabase'
$LogFile= "\LogFile\DBADatabase_DiskSpace_Job_" + $Date +  ".log"


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
    ##[Alias('wl')]
    [OutputType([int])]
    Param
    (
        ## The string to be written to the log.
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message,

        ## The path to the log file.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [Alias('LogPath')]
        [string]$Path="C:\Logs\PowerShellLog.log",

        [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    Position=3)]
        [ValidateSet("Error","Warn","Info")]
        [string]$Level="Info",

        [Parameter(Mandatory=$false)]
        [switch]$NoClobber
    )

    Begin
    {
    }
    Process
    {
        
        if ((Test-Path $Path) -AND $NoClobber) {
            Write-Warning 'Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name.'
            Return
            }

        ## If attempting to write to a log file in a folder/path that doesn't exist
        ## to create the file include path.
        elseif (!(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $NewLogFile = New-Item $Path -Force -ItemType File
            }

        else {
            ## Nothing to see here yet.
            }

        ## Now do the logging and additional output based on $Level
        switch ($Level) {
            'Error' {
                Write-Error $Message
                Write-Output "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") ERROR: $Message" | Out-File -FilePath $Path -Append
                }
            'Warn' {
                Write-Warning $Message
                Write-Output "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") WARNING: $Message" | Out-File -FilePath $Path -Append
                }
            'Info' {
                Write-Verbose $Message
                Write-Output "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") INFO: $Message" | Out-File -FilePath $Path -Append
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
$ErrorMessage = " On $Server " + $Additional + $_.Exception.Message + $_.Exception.InnerException.InnerException.message
$Message = " This message came from the Automated Powershell script updating the DBA Database with Agent Job Information"
$Msg = $Additional + $ErrorMessage + " " + $Message
Write-Log -Path $LogFile -Message $ErrorMessage -Level Error
## Write-EventLog -LogName Application -Source "SQLAUTOSCRIPT" -EventId 1 -EntryType Error -Message $Msg
}

## Create Log File

try
    {
    New-Item -Path $LogFile -ItemType File
    $Msg = "New File Created"
    Write-Log -Path $LogFile -Message $Msg
    }
catch
    {
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    $Message = " This message came from the Automated Powershell script updating the DBA Database with SQL Information"

    $Msg = $ErrorMessage + " " + $FailedItem + " " + $Message
    ## Write-EventLog -LogName Application -Source "SQLAUTOSCRIPT" -EventId 1 -EntryType Error -Message $Msg
    }

Write-Log -Path $LogFile -Message "Script Started"

 $Query = @"
 SELECT [ServerName]
  FROM [DBADatabase].[dbo].[InstanceList]
  Where Inactive = 0 
  AND NotContactable = 0
"@

try
    {
    $AlltheServers= Invoke-Sqlcmd -ServerInstance $CentralDBAServer -Database $CentralDatabaseName -Query $query
    $ServerNames = $AlltheServers| Select ServerName -ExpandProperty ServerName
    Write-Log -Path $LogFile -Message "Collected ServerNames from DBA Database"
    }
catch
    {
    Catch-Block " Failed to gather Server and Instance names from the DBA Database"
    }

foreach ($Server in $ServerNames)
    {
    $TotalGB = @{Name="Capacity";expression={[math]::round(($_.Capacity/ 1073741824),2)}}
    $FreeGB = @{Name="FreeSpace";expression={[math]::round(($_.FreeSpace / 1073741824),2)}}
    $FreePerc = @{Name="FreePerc";expression={[math]::round(((($_.FreeSpace / 1073741824)/($_.Capacity / 1073741824)) * 100),0)}}     
    try
        {    
        $OperatingSystem = Get-WmiObject Win32_OperatingSystem  -ComputerName $Server
        }
    catch
        {
        Catch-Block -Additional " Failed to check the Operating system for $Server "
        }
    if($OperatingSystem.version -gt 6)
        {
          try
            {
            $volumes = Get-WmiObject -computer $server win32_volume 
            $dks = $volumes  |Where-Object {$_.Label -ne 'System Reserved' -and $_.DriveType -ne 5}|Sort-Object Name | Select Name, Label, $TotalGB, $FreeGB, $FreePerc 
            Write-Log -Path $LogFile "Gathered Disk Information for $Server "
            }
          catch
            {
            Catch-Block -Additional "Failed to gather Disk Information for $Server"
            }
        }
    else
        {
        try
            {
            $TotalGB = @{Name="Capacity";expression={[math]::round(($_.Size/ 1073741824),2)}}
            $FreePerc = @{Name="FreePerc";expression={[math]::round(((($_.FreeSpace / 1073741824)/($_.Size / 1073741824)) * 100),0)}}
            $Label = @{Name = 'Label'; Expression = {$_.VolumeName}}
            $dks = Get-WmiObject win32_logicaldisk -ComputerName $server | Where-Object {$_.drivetype -eq 3}|Sort-Object Name |Select Name, $Label, $TotalGB, $FreeGB, $FreePerc 
            Write-Log -Path $LogFile "Gathered Disk Information for $Server "
            }
       catch
            {
            Catch-Block "Failed to Gather Disk Information for $Server "
            }
        }

        foreach($Disk in $dks)
            {
            if($disk.Name)
            {                    
            $DiskName = $disk.Name.Replace("'"," ")
            }
            else
            {
            $DiskName = $disk.Name
            }
            if($disk.label)
            {
            $Label = $disk.Label.Replace("'"," ")
            }
            else
            {
            $Label = $disk.Label
            }
            $Capacity = $disk.Capacity
            $FreeSpace = $disk.freespace
            $Percentage = $disk.freeperc

            $Query = @"
USE [DBADatabase]
GO

INSERT INTO [Info].[DiskSpace]
           ([Date]
           ,[ServerID]
           ,[DiskName]
           ,[Label]
           ,[Capacity]
           ,[FreeSpace]
           ,[Percentage])
     VALUES
           (GetDate()
           ,(SELECT InstanceID FROM dbo.InstanceList Where Servername = '$Server')
           ,'$DiskName'
           ,'$Label'
           ,'$Capacity'
           ,'$FreeSpace'
           ,'$Percentage')
GO

"@
         try
             {
             Invoke-Sqlcmd -ServerInstance $CentralDBAServer -Database $CentralDatabaseName -Query $query -ErrorAction Stop
             Write-Log -Path $LogFile -Message "Inserted data for $Server and $DiskName"
             }
        catch
            {
            Catch-Block "Failed to Insert data for $Server and $DiskName -- $Query"
            }
        }
}

Write-Log -Path $LogFile -Message "Script Finished"