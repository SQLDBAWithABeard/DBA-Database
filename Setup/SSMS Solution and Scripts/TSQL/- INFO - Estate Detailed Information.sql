
/* Number of Servers */

SELECT COUNT(ServerName) as Servers
,Environment
,Location
 FROM dbo.InstanceList il
 GROUP BY Location, Environment

 /*Number of Servers, Number of Databases, Environment and Location */

 SELECT COUNT(DISTINCT il.ServerName) as 'number of servers'
,COUNT(d.Name) as 'number of databases'
,il.Environment
,il.Location
 FROM dbo.InstanceList il
 JOIN info.Databases d
 ON il.InstanceID = d.InstanceID
 GROUP BY Location,Environment


 /*Size, Number of Servers, Number of Databases, Environment and Location */

 SELECT COUNT(DISTINCT il.ServerName) AS 'number of servers'
,COUNT(d.Name) AS 'number of databases'
,CAST((SUM(d.SizeMB) / 1024) AS Decimal(7,2)) AS 'Size Gb'
 FROM dbo.InstanceList il
 JOIN info.Databases d
 ON il.InstanceID = d.InstanceID

 SELECT COUNT(DISTINCT il.ServerName) AS 'number of servers'
,COUNT(d.Name) AS 'number of databases'
,CAST((SUM(d.SizeMB) / 1024) AS Decimal(7,2)) AS 'Size Gb'
,il.Environment
,il.Location
 FROM dbo.InstanceList il
 JOIN info.Databases d
 ON il.InstanceID = d.InstanceID
 GROUP BY Location,Environment

 /*Number of Servers, by Version, Edition, SP */

 SELECT 
SI.SQLVersion
,COUNT(DISTINCT il.ServerName) AS 'number of servers'
FROM dbo.InstanceList il
JOIN info.SQLInfo SI
ON il.ServerName = SI.ServerName 
GROUP BY Environment,SI.SQLVersion
ORDER BY SQLVersion Desc

 SELECT 
SI.SQLVersion
,SI.Edition
-- ,SI.ServicePack
,COUNT(DISTINCT il.ServerName) AS 'number of servers'
FROM dbo.InstanceList il
JOIN info.SQLInfo SI
ON il.ServerName = SI.ServerName 
GROUP BY Environment,SI.SQLVersion,SI.Edition
--,SI.ServicePack
ORDER BY SQLVersion Desc

 /* Number of Agent Jobs */

 SELECT COUNT(DISTINCT il.ServerName) as 'number of servers'
,SUM(ajs.NumberOfJobs) as 'Total Agent Jobs'
,il.Environment
,il.Location
FROM dbo.InstanceList il
JOIN info.AgentJobServer AJS
ON il.InstanceID = AJS.InstanceID
WHERE DATEDIFF( d, AJS.NumberofJobs, GETDATE() ) >300
GROUP BY Location,Environment


 /* Number of databases without a full backup*/


 SELECT COUNT(DISTINCT il.ServerName) as 'number of servers'
,COUNT(d.Name) as 'number of databases'
,CAST((SUM(d.SizeMB) / 1024) AS Decimal(7,2)) as 'Size Gb'
,il.Environment
,il.Location
 FROM dbo.InstanceList il
 JOIN info.Databases d
 ON il.InstanceID = d.InstanceID
 WHERE d.LastBackupDate = '0001-01-01 00:00:00.0000000'
 GROUP BY Location,Environment


 /* Number of Full databases wihtout a transaction log backup */

 SELECT COUNT(DISTINCT il.ServerName) as 'number of servers'
,COUNT(d.Name) as 'number of databases'
,CAST((SUM(d.SizeMB) / 1024) AS Decimal(7,2)) as 'Size Gb'
,il.Environment
,il.Location
 FROM dbo.InstanceList il
 JOIN info.Databases d
 ON il.InstanceID = d.InstanceID
 WHERE d.LastLogBackupDate = '0001-01-01 00:00:00.0000000'
 and d.RecoveryModel = 'full'
 GROUP BY Location,Environment

/* Databases by Recovery Model */

SELECT 
il.Environment
,d.RecoveryModel
,COUNT(d.Name) as 'number of databases'
 FROM dbo.InstanceList il
 JOIN info.Databases d
 ON il.InstanceID = d.InstanceID
 GROUP BY Environment,d.RecoveryModel

/* OS Operating System*/

SELECT 
SOI.OperatingSystem
,COUNT(DISTINCT il.ServerName) as 'Number of Servers'
 FROM dbo.InstanceList il
 JOIN info.ServerOSInfo SOI
 on IL.ServerName = SOI.ServerName
 GROUP BY soi.OperatingSystem
 ORDER BY soi.OperatingSystem

/* */

/* */

/* */


/* */


/* */

/* *//* */
/* */
/* */
/* */
/* */

/* */

/* */




/* */
/* */
 /* */