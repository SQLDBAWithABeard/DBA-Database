/*Show Information about Server*/

USE DBADatabase
GO

DECLARE @ServerName nvarchar(50) = 'SQL2014Ser12R2'

/* Instance List info */
SELECT IL.*	FROM dbo.InstanceList IL
WHERE IL.ServerName = @ServerName
/*OS Info*/
SELECT OS.*	FROM dbo.InstanceList IL
JOIN info.ServerOSInfo OS
ON IL.ServerName = OS.ServerName
WHERE IL.ServerName = @ServerName
/*SQL Info */
SELECT SQL.*	FROM dbo.InstanceList IL
JOIN info.SQLInfo SQL
ON IL.InstanceID = SQL.InstanceID
WHERE IL.ServerName = @ServerName
/*Database Info*/
SELECT DB.*	FROM dbo.InstanceList IL
JOIN info.Databases DB
ON IL.InstanceID = DB.InstanceID
WHERE IL.ServerName = @ServerName
/*installed Scripts*/
SELECT SI.*	FROM dbo.InstanceList IL
JOIN info.Scriptinstall SI
ON IL.InstanceID = SI.InstanceID
WHERE IL.ServerName = @ServerName
/*Agent Jobs Server Level*/
SELECT AJS.*	FROM dbo.InstanceList IL
JOIN info.AgentJobServer AJS
ON IL.InstanceID = AJS.InstanceID
WHERE IL.ServerName = @ServerName
/*Agent Jobs Detail Level*/
SELECT AJd.*	FROM dbo.InstanceList IL
JOIN info.AgentJobDetail AJD
ON IL.InstanceID = AJD.InstanceID
WHERE IL.ServerName = @ServerName