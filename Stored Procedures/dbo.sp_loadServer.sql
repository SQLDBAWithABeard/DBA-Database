SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[sp_loadServer] 
	-- Add the parameters for the stored procedure here
		 @Server nvarchar(50)
		,@InstanceName nvarchar(50) = 'MSSQLSERVER'
		,@Port int = 1433
     -- ,@AG bit = 0 -- no longer required field due to enhanced automation
		,@Environment nvarchar(25)
		,@Location nvarchar(30) = ''
		,@NotContactable bit = 0
AS
BEGIN
DECLARE @Message nvarchar(150)

declare @InstanceId int

-- Ensure Instance does not already exist
IF EXISTS
(
SELECT  [InstanceID]
  FROM [DBADatabase].[dbo].[InstanceList]
  Where [ServerName] = @Server
AND [InstanceName] = @InstanceName
													)
BEGIN
DECLARE @P nvarchar(10) = CAST(@Port as nvarchar(10))
SET @Message = @Server  + '\' + @InstanceName + ',' + @P + ' already exists in the DBA Database';
THROW 50000, @Message, 1
END

INSERT INTO [dbo].[InstanceList]
           ([ServerName]
           ,[InstanceName]
           ,[Port]
		   ,Inactive
		   ,Environment
		   ,Location
		   ,NotContactable)
     VALUES
           (@Server   
           ,@InstanceName         
           ,@Port            
		   ,0           
		   ,@Environment           
		   ,@Location    
		   ,@NotContactable ----------- Always 0 unless this servers in on a network that cannot be contacted in which case this is a 1            
		   ) 

set @InstanceId = SCOPE_IDENTITY()

insert into dbo.InstanceScriptLookup (
	InstanceID,
	ScriptID,
	NeedsUpdate
) 
	select 
		@InstanceId,
		s.ScriptID,
		0							-- This will update all scripts if set to 1 - DO NOT DO THIS
	from dbo.ScriptList as s

END
GO
