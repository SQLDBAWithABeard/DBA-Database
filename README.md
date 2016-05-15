# DBA-Database-Creation-and-Population
This repo contains the scripts to create and populate the DBA Database to automatically gather information about your estate

- Install the DBA Database on your server
- Follow the [Add Server to Auto Scripts Doc](/Setup/Add%20Server%20to%20Auto%20Scripts.docx) to add servers 
- Copy the [PowerShell scripts](/Setup/SSMS%20Solution%20and%20Scripts/PowerShell) to a location that can be accessed by the server. You will need to alter each of them to add the Servername and log file location
- Create a credential and a proxy using [Create Credential and proxy for Agent jobs.sql](Setup/SSMS%20Solution%20and%20Scripts/TSQL/Create%20Credential%20and%20proxy%20for%20Agent%20jobs.sql) for an account with permissions on all of the servers that you need to monitor
- Create the agent jobs using the scripts provided - you will need to alter the Script location
- The auto-install script requires you to download and add those scripts where the license requires this (Brent Ozar, Adam Mechanic, Ola Hallengren, Jared Zagelbaum)
- The script location needs to be updated in the [DBADatabase].[dbo].[ScriptList] table
- You can add extra scripts for your own environment using [- LOAD - Script Data Load.sql](/Setup/SSMS%20Solution%20and%20Scripts/TSQL/-%20LOAD%20-%20Script%20Data%20Load.sql)adding a new code block to the [Auto Update PS job steps.ps1](Setup/SSMS%20Solution%20and%20Scripts/PowerShell/Auto%20Update%20PS%20job%20steps.ps1)
- You can set which servers get which scripts using the [- LOAD - Update the Needs Update Flag for a server.sql](Setup/SSMS%20Solution%20and%20Scripts/TSQL/-%20LOAD%20-%20Update%20the%20Needs%20Update%20Flag%20for%20a%20server.sql) or [- LOAD - Update the Needs Update for a script.sql](/Setup/SSMS%20Solution%20and%20Scripts/TSQL/-%20LOAD%20-%20Update%20the%20Needs%20Update%20for%20a%20script.sql) scripts although more granular targetting is recommended. The auto script job will then install them.
- All agent jobs should show success when run but you MUST check (or scrape automatically) the errors in the log files I do this via a job and a SSRS report
- The
