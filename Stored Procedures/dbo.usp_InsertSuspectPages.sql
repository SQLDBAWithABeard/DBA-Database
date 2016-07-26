SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:          Rob Sewell
-- Create date: 26/07/2016
-- Description:     Inserts the suspect page information
-- =============================================
CREATE PROCEDURE [dbo].[usp_InsertSuspectPages]
       -- Add the parameters for the stored procedure here
       @ServerName nvarchar(128)
       ,@DatabaseName nvarchar(128) 
       ,@FileName varchar(2000) 
       ,@Page_id bigint 
       ,@EventType nvarchar(24) 
       ,@Error_count int 
       ,@last_update_date datetime 
AS
BEGIN
       -- SET NOCOUNT ON added to prevent extra result sets from
       -- interfering with SELECT statements.
       SET NOCOUNT ON;

    -- Insert statements for procedure here

INSERT INTO [Info].[SuspectPages]
           ([DatabaseID]
           ,[DateChecked]
           ,[FileName]
           ,[Page_id]
           ,[EventType]
           ,[Error_count]
           ,[last_update_date])
     VALUES
           ((SELECT DatabaseID FROM [Info].[Databases] D
                    JOIN dbo.InstanceList IL
                    ON IL.InstanceID = D.InstanceID
                    WHERE D.Name = @DatabaseName
                    AND IL.ServerName = @ServerName) 
           ,GETDATE()
           ,@FileName
           ,@Page_id
           ,@EventType
           ,@Error_count
           ,@last_update_date)

END

GO
