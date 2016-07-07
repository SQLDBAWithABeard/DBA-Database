
<# 
.NOTES 
    Name: email agent job results.ps1 
    Author: Rob Sewell http://sqldbawithabeard.com
    Requires: 
    Version History: 
                    Version 1.0 20/06/2013
                    Added New Header 23 August 2014
                    Version 2.0 29/06/2015 - Shiny New script connecting to the DBA Database
                    21/07/2015 - Added Inactive Column to the gather instances query
                    Version 2.1 - 19/08/2015 Added not contactable to the server list query - removed database insertion
    
.SYNOPSIS 
    Sends HTML email for all agent job results in a server list 

.DESCRIPTION 
    Connects to a server list and iterates though reading the agent job results and emails to the DBA Team - This is run as an agent job on LD5v-SQL11n-I06
#> 

# Load SMO extension
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo') | Out-Null;
$date = ( get-date ).ToString('dd/MM/yyyy')

# Server List Details
$DBADatabaseAG = ''
$DBADatabase = 'DBADatabase'
$JobsFileName = '\emailagentjobs.htm'

#Email Settings
$From = "AgentJobs@'YOURDOMAIN"
$To = "DBA.Team@'YOURDOMAIN"
### $To = "Rob.Sewell@'YOURDOMAIN"  ## For testing
$Subject = "SQL Agent Job Report - $Date" 
$SMTP = "mail.'YOURDOMAIN" 

# Get List of sql servers to check
$servers = Invoke-Sqlcmd -server $DBADatabaseAG -database $DBADatabase -Query 'Select [ServerName] ,[InstanceName] ,[Port]  FROM [DBADatabase].[dbo].[InstanceList] Where Inactive = 0  AND NotContactable = 0'

# First lets create a file to hold the html for the email

New-Item -ItemType file $JobsFileName -Force

# Function to write the HTML Header to the file
Function Write-HtmlHeader
{
param($fileName)

try
{
$date = ( get-date ).ToString('dd/MM/yyyy')
Add-Content $fileName '<html>'
Add-Content $fileName '<head>'
Add-Content $fileName "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>"
Add-Content $fileName '<title>SQL Agent Job Report</title>'
add-content $fileName '<STYLE TYPE="text/css">'
add-content $fileName '<!--'
add-content $fileName 'td {'
add-content $fileName 'font-family: Tahoma;'
add-content $fileName 'font-size: 11px;'
add-content $fileName 'border-top: 1px solid #999999;'
add-content $fileName 'border-right: 1px solid #999999;'
add-content $fileName 'border-bottom: 1px solid #999999;'
add-content $fileName 'border-left: 1px solid #999999;'
add-content $fileName 'padding-top: 0px;'
add-content $fileName 'padding-right: 0px;'
add-content $fileName 'padding-bottom: 0px;'
add-content $fileName 'padding-left: 0px;'
add-content $fileName '}'
add-content $fileName 'body {'
add-content $fileName 'margin-left: 5px;'
add-content $fileName 'margin-top: 5px;'
add-content $fileName 'margin-right: 0px;'
add-content $fileName 'margin-bottom: 10px;'
add-content $fileName ''
add-content $fileName 'table {'
add-content $fileName 'border: thin solid #000000;'
add-content $fileName '}'
add-content $fileName '-->'
add-content $fileName '</style>'
Add-Content $fileName '</head>'
Add-Content $fileName '<body>'
Add-Content $fileName "<div style = 'width:100%'>"
add-content $fileName "<table width='100%'>"
add-content $fileName "<tr bgcolor='#CCCCCC'>"
add-content $fileName "<td colspan='8' height='25' align='center'>"
add-content $fileName "<font face='tahoma' color='#003399' size='4'><strong>SQL Agent Job Report - $date</strong></font>"
add-content $fileName '</td>'
add-content $fileName '</tr>'
add-content $fileName "<tr bgcolor='#CCCCCC'>"
Add-Content $fileName "<td width='25%' align='center' bgcolor='#40FF00'>Successful Enabled Job</td>"
Add-Content $fileName "<td width='25%' align='center' bgcolor='#A4A4A4'>Disabled Job</td>"
Add-Content $fileName "<td width='25%' align='center' bgcolor='#FF0000'>Failed Job Result</td>"
Add-Content $fileName "<td width='25%' align='center' bgcolor='#FE9A2E'>Unknown Job Result</td>"
add-content $fileName '</tr>'
}
catch
{}

}

# Function to write the Table Header to the file
Function Write-JobTableHeader
{
param($fileName)

Add-Content $fileName "<tr bgcolor=#CCCCCC><td width='10%' align='center'>Server</td><td width='10%' align='center'>Category</td>"
Add-Content $fileName "<td width='20%' align='center'>Job Name</td><td width='25%' align='center'>Description</td><td width='5%' align='center'>Enabled</td>"
Add-Content $fileName "<td width='10%' align='center'>Current Run Status</td>"
Add-Content $fileName "<td width='10%' align='center'>Last Run Time</td><td width='10%' align='center'>Last Run Outcome</td></tr>"
}

# Function to write the HTML Footerr to the file
Function Write-HtmlFooter
{
param($fileName)

Add-Content $fileName '</table></div></body></html>'
}

# Function to write the Job Info to the file
Function Write-JobInfo
{
param($fileName,$Connection)
$srv = New-Object 'Microsoft.SqlServer.Management.Smo.Server' $Connection;
 $JobCount = $srv.JobServer.jobs.Count
$successCount = 0
$failedCount = 0
$UnknownCount = 0
$JobsDisabled =0

      # For each jobs on the server
      foreach($job in $srv.JobServer.Jobs)
      {
            $jobName = $job.Name;
            $jobEnabled = $job.IsEnabled;
            $jobLastRunOutcome = $job.LastRunOutcome;
            $Category = $Job.Category;
            $RunStatus = $Job.CurrentRunStatus;
            $Time = $job.LastRunDate ;
            if ($Time -eq '01/01/0001 00:00:00')
            {
            $Time = ''
            }

             $Description = $Job.Description;
            # Counts for Failed jobs

            if($jobEnabled -eq $False)
            {
            $JobsDisabled += 1
             Add-Content $fileName "<tr bgcolor = '#A4A4A4' align='center'>"
             Add-Content $fileName "<td>$Connection</td><td>$Category</td><td>$jobName</td><td>$Description</td><td>$jobEnabled</td><td>$RunStatus</td><td>$Time</td><td>$jobLastRunOutcome</td></tr>"
            }
            elseif($jobLastRunOutcome -eq 'Failed')
            {
             $failedCount += 1;
             Add-Content $fileName "<tr bgcolor = '#FF0000' align='center' >"
             Add-Content $fileName "<td>$Connection</td><td>$Category</td><td>$jobName</td><td>$Description</td><td>$jobEnabled</td><td>$RunStatus</td><td>$Time</td><td>$jobLastRunOutcome</td></tr>"
            }
            elseif ($jobLastRunOutcome -eq 'Succeeded')
            {
             $successCount += 1;
             Add-Content $fileName "<tr bgcolor = '#40FF00' align='center' >"
             Add-Content $fileName "<td>$Connection</td><td>$Category</td><td>$jobName</td><td>$Description</td><td>$jobEnabled</td><td>$RunStatus</td><td>$Time</td><td>$jobLastRunOutcome</td></tr>"
            }
             elseif ($jobLastRunOutcome -eq 'Unknown')
            {
             $UnknownCount += 1;
             Add-Content $fileName "<tr bgcolor = '#FE9A2E' align='center' >"
             Add-Content $fileName "<td>$Connection</td><td>$Category</td><td>$jobName</td><td>$Description</td><td>$jobEnabled</td><td>$RunStatus</td><td>$Time</td><td>$jobLastRunOutcome</td></tr>"
            }


}


 Add-Content $JobsFileName "<tr bgcolor='#CCCCCC'><td width='100%' colSpan=8 align='center'><font face='tahoma' color='#003399' size='3'><strong>Instance $Connection - - Number of Jobs = $JobCount - - Successful = $successCount - - Failed = $failedCount - - Disabled = $JobsDisabled - - Unknown = $UnknownCount</strong></font></td></tr>"    
 Add-Content $JobsFileName "<tr bgcolor='#CCCCCC'><td width='100%' colSpan=8 ></td></tr>"    
 
}

# Function to send email!
Function Send-Email
{ param($from,$to,$subject,$smtphost,$htmlFileName)
$body = Get-Content $htmlFileName
$smtp= New-Object System.Net.Mail.SmtpClient $smtphost
$msg = New-Object System.Net.Mail.MailMessage $from, $to, $subject, $body
$msg.isBodyhtml = $true
$smtp.send($msg)

}

write-HTMLHeader $JobsFileName

foreach ($server in $Servers)
{
      $Name = $server.Servername
      $Instance = $Server.InstanceName
      $Port = $server.Port
      $Connection = $Name + '\' + $Instance + ',' + $Port
      Write-output $Connection
      
      # Create an SMO Server object
      $srv = New-Object 'Microsoft.SqlServer.Management.Smo.Server' $Connection;

 Add-Content $JobsFileName "<tr bgcolor='#CCCCCC'>"
 Add-Content $JobsFileName "<td width='100%' align='center' colSpan=8><font face='tahoma' color='#003399' size='4'><strong> $Connection Job Results Below</strong></font></td>"
 Add-Content $JobsFileName '</tr>'

 write-JobTableHeader $JobsFileName $Connection
Write-JobInfo $JobsFileName $Connection

}
write-HtmlFooter $JobsFileName
Send-Email -from $From -to $to -subject $Subject -smtphost $SMTP -htmlFileName $JobsFileName
