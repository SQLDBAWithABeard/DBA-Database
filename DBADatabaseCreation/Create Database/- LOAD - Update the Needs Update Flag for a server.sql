/*

Script to set update flag to 1 to auto install script for a particular script server and instance

Choose the correct Script IDs below

Get the script name by running 

SELECT [ScriptID],[ScriptName] FROM [DBADatabase].[dbo].[ScriptList]

Ola
Ola Restore Command Proc
Restore Command Job Steps
sp_blitz
SP_AskBrent
sp_BlitzCache
sp_BlitzIndex
sp_BlitzTrace
sp_whoisactive
whoisactiveagentjob
ScheduleOlaJobs
Match-SQLLoginsJob
CreateSPBlitzTableJob
SPAskBrentToTableAgentJob
Create
Create
Create
Create
AGFailoverAlerts
EnableDBMail
Add_Basic_Trace_XE 
AlterOlaIndex
DBAAdminSPs
OLAGDrive
*/

Use [DBADatabase]
Go

DECLARE @NAMESERVER nvarchar(50)
DECLARE @NAMEINSTANCE nvarchar(50)


SET @NAMESERVER = ''    -- ENTER THE SERVER NAME HERE
SET  @NAMEINSTANCE = 'MSSQLSERVER'          -- ENTER THE INSTANCE NAME HERE


UPDATE [dbo].[InstanceScriptLookup] 
SET NeedsUpdate = 1  /* Set the correct value here*/
WHERE 
[dbo].[InstanceScriptLookup].ISLID IN

(SELECT
ISL.ISLID
FROM [dbo].[InstanceScriptLookup] AS ISL
Join
[dbo].[InstanceList] AS IL
ON
ISL.InstanceID = IL.InstanceID
JOIN
[dbo].[ScriptList] AS SL
ON
ISL.ScriptID = SL.ScriptID
WHERE

IL.ServerName = @NAMESERVER
AND
 IL.InstanceName = @NAMEINSTANCE
AND
SL.ScriptID in
(
--- Choose the Scripts to be set to enabled

1	,--   Ola
 2	,--   Ola Restore Command Proc
 3	,--   Restore Command Job Steps
 4	,--   sp_blitz
 5	,--   SP_AskBrent
 6	,--   sp_BlitzCache
 7	,--   sp_BlitzIndex
 8	,--   sp_BlitzTrace
 9	,--   sp_whoisactive
 10	,--   whoisactiveagentjob
11	,--   ScheduleOlaJobs
-- ---- 06/2015 This job is not working at present DO NOT INSTALL--- 12	,--   Match-SQLLoginsJob
13	,--   CreateSPBlitzTableJob
14	,--   SPAskBrentToTableAgentJob
15	,--   CreateOL
---  16	-- ,--   Create          ONLY ONE OF THESE unless using G drive - in which case choose 24
-- 17	-- ,--   Create
-- 18	--   Create
-- 19   -- , ---- AGFailoverAlerts  -- ONLY if AG
20  ,--- EnableDBMail
21 ,--- Add_Basic_Trace_XE   -- ONLY for Servers 2012 and above
22 , -- AlterOlaIndex
 23 --,  -- DBAAdminSPs
--,24   -- OLAGDrive
)
)