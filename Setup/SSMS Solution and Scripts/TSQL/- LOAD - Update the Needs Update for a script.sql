/* Use this script to find all instances with a particular script installed and set them to be updated again

Or to update with a new script 

Or to cancel updates

NOTE - This updates ALL Servers - Is that really what you want? Maybe specify further filters using one of the other load scripts

AUTHOR - Rob Sewell
DATE - 04/05/2015 - Initial

*/

Use [DBADatabase]
GO

DECLARE @NeedsUpdate bit = 1				-- 1 to update 0 to cancel
DECLARE @ScriptName nvarchar(50) = ''		-- Enter the Script Name
DECLARE @Message nvarchar(100)
-- Ensure Script exists

IF NOT EXISTS
(
SELECT  [ScriptName]
  FROM [DBADatabase].[dbo].[ScriptList]
  Where [ScriptName] = @ScriptName )

BEGIN
SET @Message = @ScriptName + ' script does not exist in the DBA Database';
THROW 50000, @Message, 1
END

-- Ensure Column in ScriptInstall Table exists

-- Ensure ScriptInstall Column Does Not Exist

DECLARE @ColumnName nvarchar(50)
SET @ColumnName = 'Has' + @ScriptName
DECLARE @Message nvarchar(100)

DECLARE @SQL nvarchar (400) = 'IF NOT EXISTS(SELECT * FROM sys.columns 
            WHERE Name = N''' + @ColumnName + ''' AND Object_ID = Object_ID(N''Info.Scriptinstall''))
BEGIN
DECLARE @Message nvarchar(100)
   SET @Message = '' Column ' + @ColumnName + ' Does not exist in the Script Install Table'';
THROW 50000, @Message, 1
END'
EXEC (@SQL)


UPDATE [dbo].[InstanceScriptLookup] 
SET NeedsUpdate = 1  
WHERE 
[dbo].[InstanceScriptLookup].ISLID IN
(SELECT 
InstanceID		
FROM [DBADatabase].[Info].[Scriptinstall] 
Where 
@ScriptName = 1  
)