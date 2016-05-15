 <# 
.SYNOPSIS  
     Daily Script to automate install and update of required SQL Server Estate 

.DESCRIPTION 
    This script is to run as a job on the admin server (XXXX) and will inspect the DBADatabase on the server for any update flags and take the appropriate action

.PARAMETER 

.EXAMPLE 

.NOTES 
    AUTHOR: Rob Sewell sqldbawithabeard.com 
    DATE: 1/05/2015 - Initial
			20/07/2015 - Altered Update-InstancesWithScript function to include query - added new scripts AlterOlaIndex

   $File = gci \\\LogFiles\autoserverupdate*|Sort-Object Lastwritetime -desc|select -first 1
   Get-Content -Path  -Tail 1 –Wait
#> 

$CentralDBAServer = ''
$CentralDBADatabase = 'DBADatabase'
$DBAAdminDatabase = 'DBA-Admin'
$Date = Get-Date -Format ddMMyyyy_HHmmss
$LogFile = '\LogFiles\AutoScriptInstall__' + $Date + '.log' 

# To Load SQL Server Management Objects into PowerShell
   [System.Reflection.Assembly]::LoadWithPartialName(‘Microsoft.SqlServer.SMO’)  | out-null
  [System.Reflection.Assembly]::LoadWithPartialName(‘Microsoft.SqlServer.SMOExtended’)  | out-null

<# 
.SYNOPSIS 
Runs a T-SQL script. 
.DESCRIPTION 
Runs a T-SQL script. Invoke-Sqlcmd2 only returns message output, such as the output of PRINT statements when -verbose parameter is specified 
.INPUTS 
None 
    You cannot pipe objects to Invoke-Sqlcmd2 
.OUTPUTS 
   System.Data.DataTable 
.EXAMPLE 
Invoke-Sqlcmd2 -ServerInstance "MyComputer\MyInstance" -Query "SELECT login_time AS 'StartTime' FROM sysprocesses WHERE spid = 1" 
This example connects to a named instance of the Database Engine on a computer and runs a basic T-SQL query. 
StartTime 
----------- 
2010-08-12 21:21:03.593 
.EXAMPLE 
Invoke-Sqlcmd2 -ServerInstance "MyComputer\MyInstance" -InputFile "C:\MyFolder\tsqlscript.sql" | Out-File -filePath "C:\MyFolder\tsqlscript.rpt" 
This example reads a file containing T-SQL statements, runs the file, and writes the output to another file. 
.EXAMPLE 
Invoke-Sqlcmd2  -ServerInstance "MyComputer\MyInstance" -Query "PRINT 'hello world'" -Verbose 
This example uses the PowerShell -Verbose parameter to return the message output of the PRINT command. 
VERBOSE: hello world 
.NOTES 
Version History 
v1.0   - Chad Miller - Initial release 
v1.1   - Chad Miller - Fixed Issue with connection closing 
v1.2   - Chad Miller - Added inputfile, SQL auth support, connectiontimeout and output message handling. Updated help documentation 
v1.3   - Chad Miller - Added As parameter to control DataSet, DataTable or array of DataRow Output type 
#> 
function Invoke-Sqlcmd2 
{ 
    [CmdletBinding()] 
    param( 
    [Parameter(Position=0, Mandatory=$true)] [string]$ServerInstance, 
    [Parameter(Position=1, Mandatory=$false)] [string]$Database, 
    [Parameter(Position=2, Mandatory=$false)] [string]$Query, 
    [Parameter(Position=3, Mandatory=$false)] [string]$Username, 
    [Parameter(Position=4, Mandatory=$false)] [string]$Password, 
    [Parameter(Position=5, Mandatory=$false)] [Int32]$QueryTimeout=600, 
    [Parameter(Position=6, Mandatory=$false)] [Int32]$ConnectionTimeout=15, 
    [Parameter(Position=7, Mandatory=$false)] [string]$InputFile, 
    [Parameter(Position=8, Mandatory=$false)] [ValidateSet('DataSet', 'DataTable', 'DataRow')] [string]$As='DataRow' 
    ) 
 
    if ($InputFile) 
    { 
        $filePath = $(Resolve-Path $InputFile).path 
        $Query =  [System.IO.File]::ReadAllText("$filePath") 
    } 
 
    $conn=new-object System.Data.SqlClient.SQLConnection 
      
    if ($Username) 
    { $ConnectionString = 'Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}' -f $ServerInstance,$Database,$Username,$Password,$ConnectionTimeout } 
    else 
    { $ConnectionString = 'Server={0};Database={1};Integrated Security=True;Connect Timeout={2}' -f $ServerInstance,$Database,$ConnectionTimeout } 
 
    $conn.ConnectionString=$ConnectionString 
     
    #Following EventHandler is used for PRINT and RAISERROR T-SQL statements. Executed when -Verbose parameter specified by caller 
    if ($PSBoundParameters.Verbose) 
    { 
        $conn.FireInfoMessageEventOnUserErrors=$true 
        $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {Write-Verbose "$($_)"} 
        $conn.add_InfoMessage($handler) 
    } 
     
    $conn.Open() 
    $cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn) 
    $cmd.CommandTimeout=$QueryTimeout 
    $ds=New-Object system.Data.DataSet 
    $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd) 
    [void]$da.fill($ds) 
    $conn.Close() 
    switch ($As) 
    { 
        'DataSet'   { Write-Output ($ds) } 
        'DataTable' { Write-Output ($ds.Tables) } 
        'DataRow'   { Write-Output ($ds.Tables[0]) } 
    } 
 
} #Invoke-Sqlcmd2

<##############################################################################################
#
# NAME: Create-Database.ps1
# AUTHOR: Rob Sewell http://sqldbawithabeard.com
# DATE:08/09/2013
#
# COMMENTS: Load function for creating a database
#           Only Server and DB Name are mandatory the rest will be set to small defaults
#
# USAGE:  Create-Database -Server Fade2black -DBName Test35 -SysFileSize 10 -UserFileSize 15 -LogFileSize 20
# -UserFileGrowth 7 -UserFileMaxSize 150 -LogFileGrowth 8 -LogFileMaxSize 250 -DBRecModel FULL
# ————————————————————————
#>
Function Create-Database 
{
Param(
[Parameter(Mandatory=$true)]
[String]$Server ,
[Parameter(Mandatory=$true)]
[String]$DBName,
[Parameter(Mandatory=$false)]
[int]$SysFileSize = 256,
[Parameter(Mandatory=$false)]
[int]$UserFileSize = 256,
[Parameter(Mandatory=$false)]
[int]$LogFileSize = 256,
[Parameter(Mandatory=$false)]
[int]$UserFileGrowth = 256,
[Parameter(Mandatory=$false)]
[int]$UserFileMaxSize =5120,
[Parameter(Mandatory=$false)]
[int]$LogFileGrowth = 256,
[Parameter(Mandatory=$false)]
$LogFileMaxSize = 2560,
[Parameter(Mandatory=$false)]
[String]$DBRecModel = 'FULL'
)

try {
    # Set server object
    $srv = New-Object ('Microsoft.SqlServer.Management.SMO.Server') $server
    $DB = $srv.Databases[$DBName]
    
    # Define the variables
    # Set the file sizes (sizes are in KB, so multiply here to MB)
    $SysFileSize = [double]($SysFileSize * 1024.0)
    $UserFileSize = [double] ($UserFileSize * 1024.0)
    $LogFileSize = [double] ($LogFileSize * 1024.0)
    $UserFileGrowth = [double] ($UserFileGrowth * 1024.0)
    $UserFileMaxSize = [double] ($UserFileMaxSize * 1024.0)
    $LogFileGrowth = [double] ($LogFileGrowth * 1024.0)
    $LogFileMaxSize = [double] ($LogFileMaxSize * 1024.0)
   

    Write-Output "Creating database: $DBName"
 
    # Set the Default File Locations
    $DefaultDataLoc = $srv.Settings.DefaultFile
    $DefaultLogLoc = $srv.Settings.DefaultLog
 
    # If these are not set, then use the location of the master db mdf/ldf
    if ($DefaultDataLoc.Length -EQ 0) {$DefaultDataLoc = $srv.Information.MasterDBPath}
    if ($DefaultLogLoc.Length -EQ 0) {$DefaultLogLoc = $srv.Information.MasterDBLogPath}
 
    # new database object
    $DB = New-Object ('Microsoft.SqlServer.Management.SMO.Database') ($srv, $DBName)
 
    # new filegroup object
    $PrimaryFG = New-Object ('Microsoft.SqlServer.Management.SMO.FileGroup') ($DB, 'PRIMARY')
    # Add the filegroup object to the database object
    $DB.FileGroups.Add($PrimaryFG )
 
    # Best practice is to separate the system objects from the user objects.
    # So create a seperate User File Group
    $UserFG= New-Object ('Microsoft.SqlServer.Management.SMO.FileGroup') ($DB, 'UserFG')
    $DB.FileGroups.Add($UserFG)
 
    # Create the database files
    # First, create a data file on the primary filegroup.
    $SystemFileName = $DBName + '_System'
    $SysFile = New-Object ('Microsoft.SqlServer.Management.SMO.DataFile') ($PrimaryFG , $SystemFileName)
    $PrimaryFG.Files.Add($SysFile)
    $SysFile.FileName = $DefaultDataLoc + $SystemFileName + '.MDF'
    $SysFile.Size = $SysFileSize
    $SysFile.GrowthType = 'None'
    $SysFile.IsPrimaryFile = 'True'
 
    # Now create the data file for the user objects
    $UserFileName = $DBName + '_User'
    $UserFile = New-Object ('Microsoft.SqlServer.Management.SMO.Datafile') ($UserFG, $UserFileName)
    $UserFG.Files.Add($UserFile)
    $UserFile.FileName = $DefaultDataLoc + $UserFileName + '.NDF'
    $UserFile.Size = $UserFileSize
    $UserFile.GrowthType = 'KB'
    $UserFile.Growth = $UserFileGrowth
    $UserFile.MaxSize = $UserFileMaxSize
 
    # Create a log file for this database
    $LogFileName = $DBName + '_Log'
    $LogFile = New-Object ('Microsoft.SqlServer.Management.SMO.LogFile') ($DB, $LogFileName)
    $DB.LogFiles.Add($LogFile)
    $LogFile.FileName = $DefaultLogLoc + $LogFileName + '.LDF'
    $LogFile.Size = $LogFileSize
    $LogFile.GrowthType = 'KB'
    $LogFile.Growth = $LogFileGrowth
    $LogFile.MaxSize = $LogFileMaxSize
 
    #Set the Recovery Model
    $DB.RecoveryModel = $DBRecModel
    #Create the database
    $DB.Create()
 
    #Make the user filegroup the default
    $UserFG = $DB.FileGroups['UserFG']
    $UserFG.IsDefault = $true
    $UserFG.Alter()
    $DB.Alter()

    Write-Output " $DBName Created"
    Write-Output 'System File'
    $SysFile| Select-Object Name, FileName, Size, MaxSize,GrowthType| Format-List
    Write-Output 'User File'
    $UserFile| Select-Object Name, FileName, Size, MaxSize,GrowthType, Growth| Format-List
    Write-Output 'LogFile'
    $LogFile| Select-Object Name, FileName, Size, MaxSize,GrowthType, Growth| Format-List
    Write-Output 'Recovery Model'
    $DB.RecoveryModel

} Catch
{
   $error[0] | Format-List * -force
}
    }

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
$Message = ' This message came from the Automated Powershell script to standardise DBA scripts across Estate'
$Msg = $Additional + $ErrorMessage + ' ' + $Message
Write-Log -Path $LogFile -Message $ErrorMessage -Level Error
Write-EventLog -LogName Application -Source 'SQLAUTOSCRIPT' -EventId 1 -EntryType Error -Message $Msg
}

<#
.Synopsis
 A function to add a ChangeLog information
.DESCRIPTION
 Load function for adding a change to the changelog table.
 Use Get-ChangeLog $Server to see details
 Inputs the username of the account running powershell into the database as the user
REQUIRES Invoke-SQLCMD2
http://sqldbawithabeard.com
.EXAMPLE
 Add-ChangeLog SERVERNAME "Altered AutoGrowth Settings for TempDB to None"
 
 Adds ServerName UserName and Altered AutoGrowth Settings for TempDB to None to the change log table
#>
Function Add-ChangeLog
{
[CmdletBinding()]
Param(
 [Parameter(Mandatory=$True)]
 [string]$Server,
 
 [Parameter(Mandatory=$True)]
 [string]$Change
)
 
$UserName = $env:USERDOMAIN + '\' + $env:USERNAME
 
$Query = "INSERT INTO [dbo].[ChangeLog]
([Date]
,[InstanceName]
,[ChangeDesc]
,[UserName])
     VALUES
 (GetDate()
 ,'$Server'
 ,'$Change'
,'$UserName')
"
Invoke-Sqlcmd2 -ServerInstance $Server -Database 'DBA-Admin' -Query $Query -Verbose
}

function Remove-UpdateFlag
{
param(
[string]$ServerName,
[string]$InstanceName,
[string]$ScriptName
)
                try
                    {
            $RemoveUpdateFlag = @"
            UPDATE [dbo].[InstanceScriptLookup]
   SET 
      [NeedsUpdate] = 0
 WHERE 
 InstanceID = (SELECT InstanceID from dbo.InstanceList Where [ServerName] = '$ServerName' AND [InstanceName] = '$InstanceName')
 AND
 ScriptID = (SELECT ScriptID from [dbo].[ScriptList] WHERE [ScriptName] = '$ScriptName')
GO
"@
                     Invoke-Sqlcmd -ServerInstance $CentralDBAServer -Database $CentralDBADatabase -Query $RemoveUpdateFlag
                     Write-Log -Path $LogFile -Message ' Update Flags Removed' -Level Info
                     }
                 catch
                     {
                     Catch-block 'Failed to remove Update Flags -- '
                     }
}

function Update-InstancesWithScript
{
param
(
$ScriptName
)

# Get Instances which need updating or installing
$Query = @"
SELECT
IL.ServerName
,IL.InstanceName
,IL.Port
,SL.ScriptName
,SL.ScriptLocation
,ISL.NeedsUpdate

FROM
[dbo].[InstanceScriptLookup] as ISL
JOIN
dbo.InstanceList as IL
ON
ISL.[InstanceID] = IL.InstanceID
JOIN
[dbo].[ScriptList] as SL
ON
SL.ScriptID = ISL.ScriptID
WHERE ISL.NeedsUpdate = 1
AND
SL.ScriptName = '$ScriptName'
AND 
IL.Inactive = 0
AND
IL.NotContactable = 0

"@

    try
    {
   # Write-Log -Path $LogFile -Message $Query -Level Info ## For logging purposes when testing
    $InstancesToUpdate = Invoke-Sqlcmd2 -ServerInstance $CentralDBAServer -Database $CentralDBADatabase -Query $Query
    Write-Log -Path $LogFile -Message ' Instances gathered' -Level Info
    }
    catch
    {
    $Add = " Failed to gather Instances from  $CentralDBAServer "
    Catch-block $Add
    }

    # Iterate through the required instances and run script
    if ($InstancesToUpdate -eq $NULL)
    {
 Write-Log -Path $LogFile -Message ' No Instances to Update' -Level Info
    }

    else{
    foreach ($Instance in $InstancesToUpdate)
        {
        $ServerName = $Instance.ServerName
        $InstanceName = $Instance.InstanceName
        $ScriptLocation = $Instance.ScriptLocation
        $ScriptName = $Instance.ScriptName
        $Connection = $ServerName + '\' + $InstanceName + ',' + $Instance.Port
        $srv = New-Object Microsoft.SQLServer.Management.SMO.Server $Connection

       # [string]$InstallScript = Get-Content  $ScriptLocation

        # Check if the DBAAdmin database is created and if not create it
        try
            {
            $db = $srv.Databases[$DBAAdminDatabase]
            $Check = $DB.State
            if(!$Check)
                {
                Create-Database -Server $Connection -DBName $DBAAdminDatabase
                Write-Log -Path $LogFile -Message " DBA-Admin Database created on $Connection"
                }
            else
                {
                # Write-Log -Path $LogFile -Message " DBA-Admin Database already exists on $Connection"
                }
            }
        catch
            {
            Catch-Block 'Failed to Create DBA-Admin Database -- '
            }
            # Check if the ChangeLog table is created and if not create it
        try
            {
            $srv = New-Object Microsoft.SQLServer.Management.SMO.Server $Connection
            $db = $Srv.Databases[$DBAAdminDatabase]
            $tb = $db.Tables['ChangeLog']
            $Check = $tb.State
            if(!$Check )
                {
                $tb = New-Object Microsoft.SQLServer.Management.Smo.Table($db,'ChangeLog')
                $col1 = New-object Microsoft.SqlServer.Management.Smo.Column($tb,'ChangeLogID', [Microsoft.SQLServer.Management.Smo.Datatype]::Int)
                $col1.Identity = $True
                $col1.IdentityIncrement = 1
                $col1.IdentitySeed = 1
                $col1.Nullable = $false
                $col2 = New-object Microsoft.SqlServer.Management.Smo.Column($tb,'Date', [Microsoft.SQLServer.Management.Smo.Datatype]::DateTime)
                $col3 = New-object Microsoft.SqlServer.Management.Smo.Column($tb,'InstanceName', [Microsoft.SQLServer.Management.Smo.Datatype]::NVarchar(50))
                $col4 = New-object Microsoft.SqlServer.Management.Smo.Column($tb,'ChangeDesc', [Microsoft.SQLServer.Management.Smo.Datatype]::NVarchar(500))
                $col5 = New-object Microsoft.SqlServer.Management.Smo.Column($tb,'UserName', [Microsoft.SQLServer.Management.Smo.Datatype]::NVarchar(50))
                $tb.Columns.Add($col1)
                $tb.Columns.Add($col2)
                $tb.Columns.Add($col3)
                $tb.Columns.Add($col4)
                $tb.Columns.Add($col5)
                $idxpk = new-object Microsoft.SQLServer.Management.Smo.Index ($tb, 'PK_ChangeLogID')
                $idxpk.IndexKeyType = 'DriPrimaryKey'
                $idxpk.IsClustered = $true
                $idxpkcol = new-object Microsoft.SQLServer.Management.Smo.IndexedColumn ($idxpk, 'ChangeLogID')
                $idxpk.IndexedColumns.Add($idxpkcol)
                $tb.Indexes.Add($idxpk)
                $tb.Create()

                Write-Log -Path $LogFile -Message " ChangeLog Table created on $Connection"
                Add-ChangeLog -Server $Connection -Change 'ChangeLog Table Created'
                }
            else
                {
                $DBName = $db.Name
                # Write-Log -Path $LogFile -Message " ChangeLog Table already exists on $Connection in $DbName "
                }
            }
        catch
            {
            Catch-Block 'Failed to Create ChangeLog Table  -- '
            }

            # Run Install Script
            try
            {
           # Invoke-Sqlcmd2 -ServerInstance $Connection -Database $DBAAdminDatabase -Query $InstallScript
            Invoke-Sqlcmd -ServerInstance $Connection -Database $DBAAdminDatabase -InputFile $ScriptLocation -DisableVariables -ErrorAction Stop
            Add-ChangeLog -Server $Connection -Change "Installed or updated $ScriptName "
            Write-Log -Path $LogFile -Message "Installed or updated $ScriptName on $Connection"
            
                try
                    {
            Remove-UpdateFlag -ServerName $ServerName -InstanceName $InstanceName -ScriptName $ScriptName
                     }
                 catch
                     {
                     Catch-block 'Failed to Remove Update Flags  --'
                     }
                }
            catch
            {
            Catch-Block "Failed To Install or update $ScriptName -- "
            }
    }
    }
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
$Message = ' This message came from the Automated Powershell script to standardise DBA scripts across Estate'

$Msg = $ErrorMessage + ' ' + $FailedItem + ' ' + $Message
Write-EventLog -LogName Application -Source 'SQLAUTOSCRIPT' -EventId 1 -EntryType Error -Message $Msg
}

Write-Log -Path $LogFile -Message ' Script Started'

# Get Instances which need Ola's Maintenance Plan updating or installing

try{
Write-Log -Path $LogFile -Message ' Starting Ola Script' -Level Info
Update-InstancesWithScript -ScriptName 'Ola'
Write-Log -Path $LogFile -Message 'Ola Maintenance Plan Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install  -- Ola Maintenance Plan'}

try{
Write-Log -Path $LogFile -Message ' Starting Ola Restore Command Proc Script' -Level Info
Update-InstancesWithScript -ScriptName 'Ola Restore Command Proc'
Write-Log -Path $LogFile -Message ' Ola Restore Command Proc Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install Ola Restore Command Proc -- '}

try{
Write-Log -Path $LogFile -Message ' Starting Ola Restore Command Job Steps Script' -Level Info
Update-InstancesWithScript -ScriptName 'Restore Command Job Steps'
Write-Log -Path $LogFile -Message  'Ola Restore Command Job Steps Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install Ola Restore Command Job Steps -- '}

try{
Write-Log -Path $LogFile -Message ' Starting SP_Blitz Script' -Level Info
Update-InstancesWithScript -ScriptName 'SP_blitz'
Write-Log -Path $LogFile -Message  'SP_Blitz Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install SP_Blitz -- '}

try{
Write-Log -Path $LogFile -Message ' Starting SP_AskBrent Script' -Level Info
Update-InstancesWithScript -ScriptName 'SP_AskBrent'
Write-Log -Path $LogFile -Message 'SP_AskBrent Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install SP_AskBrent -- '}

try{
Write-Log -Path $LogFile -Message ' Starting SP_BlitzCache Script' -Level Info
Update-InstancesWithScript -ScriptName 'sp_BlitzCache'
Write-Log -Path $LogFile -Message  'SP_BlitzCache Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install SP_BlitzCache -- '}

try{
Write-Log -Path $LogFile -Message ' Starting SP_BlitzIndex Script' -Level Info
Update-InstancesWithScript -ScriptName 'sp_BlitzIndex'
Write-Log -Path $LogFile -Message 'SP_BlitzIndex Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install SP_BlitzIndex -- '}

try{
Write-Log -Path $LogFile -Message ' Starting SP_BlitzTrace Script' -Level Info
Update-InstancesWithScript -ScriptName 'sp_BlitzTrace'
Write-Log -Path $LogFile -Message  'SP_BlitzTrace Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install SP_BlitzTrace -- '}

try{
Write-Log -Path $LogFile -Message ' Starting SP_WhoIsActive Script' -Level Info
Update-InstancesWithScript -ScriptName 'sp_whoisactive'
Write-Log -Path $LogFile -Message  'SP_WhoIsActive Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install SP_WhoIsActive -- '}

try{
Write-Log -Path $LogFile -Message ' Starting WhoIsActive Agent Job Script' -Level Info
Update-InstancesWithScript -ScriptName 'whoisactiveagentjob'
Write-Log -Path $LogFile -Message  'WhoIsActive Agent Job Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install WhoIsActive Agent Job -- '}



<#
  $MatchLoginsAgentJob = @"
SELECT
IL.ServerName
,IL.InstanceName
,IL.Port
,SL.ScriptName
,SL.ScriptLocation
,ISL.NeedsUpdate

FROM
[dbo].[InstanceScriptLookup] as ISL
JOIN
dbo.InstanceList as IL
ON
ISL.[InstanceID] = IL.InstanceID
JOIN
[dbo].[ScriptList] as SL
ON
SL.ScriptID = ISL.ScriptID
WHERE ISL.NeedsUpdate = 1
AND
SL.ScriptName = 'Match-SQLLoginsJob'
AND
IL.Inactive = 0

"@

try{
Write-Log -Path $LogFile -Message " Starting Match-SQLLoginsJob Agent Job Script" -Level Info
$InstancesToUpdate = Invoke-Sqlcmd -ServerInstance $CentralDBAServer -Database $CentralDBADatabase -Query $MatchLoginsAgentJob
foreach ($Server in $InstancesToUpdate.ServerName)
{
cd c:
$Dest = 'FileSystem::\\' + $Server + '\E$\Scripts'
if(!(Test-Path $Dest))
{New-Item $Dest -ItemType Directory}
Copy-Item 'FileSystem::\\ld5v-file-i01\Departments\Technology\DBA\PROJECTS\SSMS\Instance Setup\instance Setup\PSV2Match-SQLLogins.ps1' $Dest
}
Update-InstancesWithScript -Query $MatchLoginsAgentJob
Write-Log -Path $LogFile -Message  "Match-SQLLoginsJob Agent Job Installed or updated"

 }
 Catch
 {Catch-Block "Failed to install Match-SQLLoginsJob Agent Job  -- "}
 #>
 # CreateSPBlitzTableJob

try{
Write-Log -Path $LogFile -Message ' Starting Create SPBlitz to Table Job Script' -Level Info
Update-InstancesWithScript -ScriptName 'CreateSPBlitzTableJob'
Write-Log -Path $LogFile -Message  ' Starting Create SPBlitz to Table Job Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install Create SPBlitz to Table Job  -- '}

 # Create SPAskBrentToTableAgentJob

try{
Write-Log -Path $LogFile -Message ' Starting Create SPAskBrent To Table Agent Job Script' -Level Info
Update-InstancesWithScript -ScriptName 'SPAskBrentToTableAgentJob'
Write-Log -Path $LogFile -Message  ' Create SPAskBrent To Table Agent Job Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install Create SPBlitz to Table Job  -- '}

 Write-Log -Path $LogFile -Message  ' Script Finished'

  # Create OLA Prdo Job

try{
Write-Log -Path $LogFile -Message ' Starting Create OLA NPT PROD Job Script' -Level Info
Update-InstancesWithScript -ScriptName 'CreateOLANPTPRODJob'
Write-Log -Path $LogFile -Message  ' Create OLA NPT PROD Job Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install Create OLA NPT PROD Job -- '}

  # Create OLA Dev Job

try{
Write-Log -Path $LogFile -Message ' Starting Create OLA NPT DEV Job Script' -Level Info
Update-InstancesWithScript -ScriptName 'CreateOLANPTDEVJob'
Write-Log -Path $LogFile -Message  ' Create OLA NPT DEV Job Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install Create OLA NPT DEV Job  -- '}
 
 # Create OLA PROD Job

try{
Write-Log -Path $LogFile -Message ' Starting Create OLA SLO PROD Job Script' -Level Info
Update-InstancesWithScript -ScriptName 'CreateOLASLOPRODJob'
Write-Log -Path $LogFile -Message  ' Create OLA SLO PROD Job Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install Create OLA SLO PROD Job  -- '}

 # Create OLA SLO DEV Job

try{
Write-Log -Path $LogFile -Message ' Starting Create OLA SLO DEV Job Script' -Level Info
Update-InstancesWithScript -ScriptName 'CreateOLASLODEVJob'
Write-Log -Path $LogFile -Message  ' Create OLA SLO DEV Job Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install Create OLA SLO DEV Job  -- '}

   

 # Create AGFailoverAlerts

try{
Write-Log -Path $LogFile -Message ' Starting Create AG Failover Alerts' -Level Info
Update-InstancesWithScript -ScriptName 'AGFailoverAlerts'
Write-Log -Path $LogFile -Message  ' AG Failover Alerts Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install AG Failover Alerts  -- '}

 # EnableDBMail
 
try{
Write-Log -Path $LogFile -Message ' Starting Enable DBMail' -Level Info
Update-InstancesWithScript -ScriptName 'EnableDBMail'
Write-Log -Path $LogFile -Message  ' Enable DBMail Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install Enable DBMail  -- '}

# Add_Basic_Trace_XE
 
try{
Write-Log -Path $LogFile -Message ' Starting Add_Basic_Trace_XE' -Level Info
Update-InstancesWithScript -ScriptName 'Add_Basic_Trace_XE'
Write-Log -Path $LogFile -Message  ' Add_Basic_Trace_XE Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install Add_Basic_Trace_XE  -- '}

   # 'DBAAdminSPs'
 
try{
Write-Log -Path $LogFile -Message ' Starting DBAAdminSPs' -Level Info
Update-InstancesWithScript -ScriptName 'DBAAdminSPs'
Write-Log -Path $LogFile -Message  ' DBAAdminSPs Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install DBAAdminSPs  -- '}

 # AlterOlaIndex
 
try{
Write-Log -Path $LogFile -Message ' Starting AlterOlaIndex' -Level Info
Update-InstancesWithScript -ScriptName 'AlterOlaIndex'
Write-Log -Path $LogFile -Message  ' AlterOlaIndex Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install AlterOlaIndex  -- '}



   # 'OLAGDrive'
 
try{
Write-Log -Path $LogFile -Message ' Starting OLAGDrive' -Level Info
Update-InstancesWithScript -ScriptName 'OLAGDrive'
Write-Log -Path $LogFile -Message  ' OLAGDrive Installed or updated'

 }
 Catch
 {Catch-Block 'Failed to install DBAAdminSPs  -- '}

 $ScheduleOlaJobs = @"
SELECT
IL.ServerName
,IL.InstanceName
,IL.Port
,SL.ScriptName
,SL.ScriptLocation
,ISL.NeedsUpdate

FROM
[dbo].[InstanceScriptLookup] as ISL
JOIN
dbo.InstanceList as IL
ON
ISL.[InstanceID] = IL.InstanceID
JOIN
[dbo].[ScriptList] as SL
ON
SL.ScriptID = ISL.ScriptID
WHERE ISL.NeedsUpdate = 1
AND
SL.ScriptName = 'ScheduleOlaJobs'

"@

try{
Write-Log -Path $LogFile -Message ' Starting ScheduleOlaJobs Script' -Level Info
    try
        {
        $InstancesToUpdate = Invoke-Sqlcmd2 -ServerInstance $CentralDBAServer -Database $CentralDBADatabase -Query $ScheduleOlaJobs
        Write-Log -Path $LogFile -Message ' Instances gathered' -Level Info
        }
        catch
        {
        $Add = " Failed to gather Instances from  $CentralDBAServer "
        Catch-block $Add
        }
        # Iterate through the required instances and run script
        if ($InstancesToUpdate -eq $NULL)
        {
     Write-Log -Path $LogFile -Message ' No Instances to Update' -Level Info
        }
    else{
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
        $Schedule = new-object Microsoft.SqlServer.Management.Smo.Agent.JobSchedule ($job,'Weekly Sunday - Midnight ++ ')
        $Schedule.ActiveEndDate = Get-Date -Month 12 -Day 31 -Year 9999
        $Schedule.ActiveEndTimeOfDay = '23:59:59'
        $Schedule.FrequencyTypes = 'Weekly' 
        $Schedule.FrequencyRecurrenceFactor = 1 
        $Schedule.FrequencyInterval = 1  
        $Schedule.ActiveStartDate = get-date  
        $schedule.ActiveStartTimeOfDay = '00:16:00'
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
    
    foreach ($Instance in $InstancesToUpdate)
            {
            try
            {
            $ServerName = $Instance.ServerName
            $InstanceName = $Instance.InstanceName
            $ScriptLocation = $Instance.ScriptLocation
            $ScriptName = $Instance.ScriptName
            $Connection = $ServerName + '\' + $InstanceName + ',' + $Instance.Port
            Schedule-OlaJobs $Connection
            Add-ChangeLog -Server $Connection -Change 'ScheduleOlaJobs Installed or updated'
            Write-Log -Path $LogFile -Message  "ScheduleOlaJobs Installed or updated on $Connection"
            Remove-UpdateFlag -ServerName $ServerName -InstanceName $InstanceName -ScriptName $ScriptName
            }
            catch
            {
            Catch-Block 'Failed to install ScheduleOlaJobs -- '
            }
        }

    }
 }
 Catch
 {Catch-Block}

 

 Write-Log -Path $LogFile -Message  ' Script Finished'