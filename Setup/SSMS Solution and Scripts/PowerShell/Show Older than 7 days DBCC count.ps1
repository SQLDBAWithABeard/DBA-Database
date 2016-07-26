## Script to display when Last DBCC Check older than 7 days
 
 $CentralDBAServer = ''
$CentralDatabaseName = 'DBADatabase'

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
$ServerNames = $AlltheServers| Select ServerName,InstanceName,Port
}
catch
{
Write-Error " Failed to gather Server and Instance names from the DBA Database"
}
$All = 0
$Never = 0
foreach ($ServerName in $ServerNames)
{
## $ServerName
 $InstanceName =  $ServerName|Select InstanceName -ExpandProperty InstanceName
 $Port = $ServerName| Select Port -ExpandProperty Port
$ServerName = $ServerName|Select ServerName -ExpandProperty ServerName 
 $Connection = $ServerName + '\' + $InstanceName + ',' + $Port

$srv = New-Object ('Microsoft.SqlServer.Management.SMO.Server') $Connection
if($srv.VersionMajor -gt 8)
{
foreach($db in $srv.Databases|Where-Object {$_.IsAccessible -eq $true})
{
$lastDBCC_CHECKDB=$db.ExecuteWithResults("DBCC DBINFO () WITH TABLERESULTS").Tables[0] | where {$_.Field.ToString() -eq "dbi_dbccLastKnownGood"} | Select $db.Name, Value -First 1
    $DaysOld = ((Get-Date) - [DateTime]$lastDBCC_CHECKDB.Value).Days
    if($DaysOld -gt 7)
    {
     write-host $ServerName "  " $db.Name " Last DBCC CHECKDB execution older than 7 days : " $lastDBCC_CHECKDB.Value
     $All ++
    }
    
     if ($lastDBCC_CHECKDB.Value -eq '1900-01-01 00:00:00.000'){$Never ++}
}
}
}

write-host "Number of Databases where Last DBCC CHECKDB execution older than 7 days : $All"
write-host "Number of Databases where NEVER DBCC CHECKDB execution  : $Never"
