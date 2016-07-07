/*
Script to show which servers will be updated with whcih scripts the next time the auto-install script runs
*/

Use [DBADatabase]
Go

SELECT
IL.ServerName
,IL.InstanceName
,IL.Port
,SL.ScriptName
,ISL.NeedsUpdate
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

 ISL.NeedsUpdate = 1
------------ ServerName = ''
