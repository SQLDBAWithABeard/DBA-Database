/*

A set of alerts to notify the DBA Team of Availability Group Failovers and Issues with Data Movement

Requires that DBMail has been set up and that the DBA Team Operator has been created


*/

USE [msdb]
GO

IF NOT EXISTS 
	(SELECT NAME FROM sysoperators WHERE NAME = 'DBA_Notify')
	BEGIN

/****** Object:  Operator [DBA_Notify]    Script Date: 01/06/2015 08:43:21 ******/
EXEC msdb.dbo.sp_add_operator @name=N'DBA_Notify', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'DBA.Team@YOURDOMAIN', 
		@category_name=N'[Uncategorized]'
	END


	-- 1480 - AG Role Change (failover)

IF EXISTS
	(SELECT Name FROM msdb.dbo.sysalerts WHERE Name = N'AG Role Change')
BEGIN
EXEC msdb.dbo.sp_delete_alert @name=N'AG Role Change'
END

EXEC msdb.dbo.sp_add_alert @name=N'AG Role Change', 
		@message_id=1480, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=300,  
		@include_event_description_in=1, 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'AG Role Change', @operator_name=N'DBA_Notify', @notification_method = 1
GO

-- 35264 - AG Data Movement - Suspended
IF EXISTS
	(SELECT Name FROM msdb.dbo.sysalerts WHERE Name = N'AG Data Movement - Suspended')
BEGIN
EXEC msdb.dbo.sp_delete_alert @name=N'AG Data Movement - Suspended'
END


EXEC msdb.dbo.sp_add_alert

        @name = N'AG Data Movement - Suspended',

        @message_id = 35264,

    @severity = 0,

    @enabled = 1,

  @delay_between_responses=300, 

    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification 

        @alert_name = N'AG Data Movement - Suspended', 

         @operator_name=N'DBA_Notify', @notification_method = 1
GO

-- 35265 - AG Data Movement - Resumed

IF EXISTS
	(SELECT Name FROM msdb.dbo.sysalerts WHERE Name =N'AG Data Movement - Resumed')
BEGIN
EXEC msdb.dbo.sp_delete_alert @name=N'AG Data Movement - Resumed'
END


EXEC msdb.dbo.sp_add_alert

        @name = N'AG Data Movement - Resumed',

        @message_id = 35265,

    @severity = 0,

    @enabled = 1,

    @delay_between_responses=300, 

    @include_event_description_in = 1;
GO
EXEC msdb.dbo.sp_add_notification 

        @alert_name = N'AG Data Movement - Resumed', 

         @operator_name=N'DBA_Notify', @notification_method = 1
GO