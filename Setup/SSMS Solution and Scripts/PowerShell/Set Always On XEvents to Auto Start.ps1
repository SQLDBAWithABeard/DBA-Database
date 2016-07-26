## Script to set Always on health extended events session to auto start

## https://msdn.microsoft.com/en-us/library/ff877887.aspx
## 
## also mention Mike Fall
## 
## http://www.mikefal.net/2015/06/09/tsql2sday-powershell-and-extended-events/

$XEName = 'AlwaysOn_health'
$DBADatabaseServer = ''

$Query = @"
SELECT 
IL.ServerName
FROM [dbo].[InstanceList] IL
WHERE NotContactable = 0
AND Inactive = 0
"@

Try
{
$Results = (Invoke-Sqlcmd -ServerInstance $DBADatabaseServer -Database DBADatabase -Query $query -ErrorAction Stop).ServerName
}
catch
{
Write-Error "Unable to Connect to the DBADatabase - Please Check"
}

foreach($Server in $Results)
{

try
{
$srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $Server
}
catch
{
Write-Warning " Failed to connect to $Server"
continue
}
if (!( $srv.version)){
Write-Output " Failed to Connect to $Server"
continue
}

if($srv.versionmajor -ge '11')
{
if ($srv.AvailabilityGroups.Name)
{
$AGNames = $srv.AvailabilityGroups.Name

if(Test-Path SQLSERVER:\XEvent\$Server)
{
$XEStore = get-childitem -path SQLSERVER:\XEvent\$Server -ErrorAction SilentlyContinue  | where {$_.DisplayName -ieq 'default'} 
 $AutoStart = $XEStore.Sessions[$XEName].AutoStart
Write-Output "$server for $AGNames --- $XEName -- $AutoStart"
if($AutoStart -eq $false)
{
$XEStore.Sessions[$XEName].AutoStart = $true
$XEStore.Sessions[$XEName].Alter()
}
}
else
{
Write-Output "Failed to connect to XEvent on $Server"

 }
}
else
{
## Write-Output "No AGs on $Server"
}
}
else
{
##  Write-Output "$server not 2012 or above"
}
} 
