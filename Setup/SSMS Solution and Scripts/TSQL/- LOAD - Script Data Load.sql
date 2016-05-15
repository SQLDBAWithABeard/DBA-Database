/*
Adding a new script to the DBA Database solution


Enter the corect values against the variables

The errors will tell you what you have done wrong

AUTHOR - Rob Sewell
DATE - 04/05/2015 - Initial
	- 10/08/2015 - Added some failsafes !!
	- 18/08/2015 - Added non contactabel and inactive to the query
	- 25/09/2015 - fixed typo NotContactable instead of NonContactable

*/


USE [DBADatabase]
GO

DECLARE @ScriptName nvarchar(50) = ''					--- Enter Name of Script
DECLARE @ScriptDescription nvarchar(256) = ''			--- Enter Description of Script 
DECLARE @ScriptLocation nvarchar(256) = ''				--- Enter full path to script
DECLARE @ScriptId int

DECLARE @Message nvarchar(150)


-- Ensure Script Name Does not exist
IF EXISTS
(
SELECT  [ScriptName]
  FROM [DBADatabase].[dbo].[ScriptList]
  Where [ScriptName] = @ScriptName )

BEGIN

SET @Message = @ScriptName + ' already exists in the DBA Database';
THROW 50000, @Message, 1
END

-- Ensure ScriptInstall Column Does Not Exist

DECLARE @ColumnName nvarchar(50)
SET @ColumnName = 'Has' + @ScriptName
DECLARE @Message nvarchar(100)

DECLARE @SQL nvarchar (400) = 'IF EXISTS(SELECT * FROM sys.columns 
            WHERE Name = N''' + @ColumnName + ''' AND Object_ID = Object_ID(N''Info.Scriptinstall''))
BEGIN
DECLARE @Message nvarchar(100)
   SET @Message = '' Column ' + @ColumnName + ' already exists in the Script Install Table'';
THROW 50000, @Message, 1
END'
EXEC (@SQL)


-- Insert Data

INSERT INTO [dbo].[ScriptList]
           ([ScriptName]
           ,[ScriptDecription]
           ,[ScriptLocation])
     VALUES
           (@ScriptName
           ,@ScriptDescription
           ,@ScriptLocation)

set @ScriptId = SCOPE_IDENTITY()

insert into dbo.InstanceScriptLookup (
	InstanceID,
	ScriptID,
	NeedsUpdate
)
	select		
		i.InstanceID,
		@ScriptId,
		0 -- Set this to 1 or 0 depending on whether you need to update ALL servers (1) or not (0)
	from dbo.InstanceList as i

GO

/* Add column to scriptinstall reporting table */

DECLARE @ColumnName nvarchar(50)
SET @ColumnName = 'Has' + @ScriptName
DECLARE @SQL nvarchar (70) = 'ALTER TABLE [Info].[Scriptinstall] ADD ' + @ColumnName + ' bit NULL'
PRINT @SQL
EXEC (@SQL)

