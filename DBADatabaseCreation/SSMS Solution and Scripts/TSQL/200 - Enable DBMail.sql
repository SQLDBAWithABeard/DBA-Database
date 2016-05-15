/* Script to create the DB Mail profile, send a test email and enable for the agent and the failsafe operator  */

/* You will need to set the correct values for domains, emails, SMTP Servers */
-- Ensure Mail is enabled

--show options
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

--enable
sp_configure 'Database Mail XPs', 1;
GO
RECONFIGURE
GO

--hide options
sp_configure 'show advanced options', 0;
GO
RECONFIGURE;
GO


-- Create the Account
declare @server nvarchar(50)
declare @email nvarchar(75)
set @server = REPLACE(@@servername,'\','-')
set @email = @server + '@YOURDOMAIN'

IF NOT EXISTS
(SELECT name 
  FROM [msdb].[dbo].[sysmail_account] where name = 'SQLMailAccount')
  BEGIN
EXECUTE msdb.dbo.sysmail_add_account_sp
    @account_name = 'SQLMailAccount',
    @description = 'Mail account for Database Mail',
    @email_address = @email,
    @display_name = @@servername,
	@mailserver_name = 'SMTP Server' 
	END

-- Create the Mail Profile
IF NOT EXISTS
(SELECT Name
  FROM [msdb].[dbo].[sysmail_profile] WHERE Name = 'SQLMailProfile')
  BEGIN
EXECUTE msdb.dbo.sysmail_add_profile_sp
       @profile_name = 'SQLMailProfile',
       @description = 'Profile used for database mail'
END

-- Add the Database Mail Account
IF NOT EXISTS
(SELECT [sequence_number]
FROM [msdb].[dbo].[sysmail_profileaccount] as pa
JOIN
[msdb].[dbo].[sysmail_profile] as p
ON
pa.profile_id = p.profile_id
JOIN
[msdb].[dbo].[sysmail_account] as a
ON
pa.account_id = a.account_id
where
A.name = 'SQLMailAccount'
and
P.name = 'SQLMailProfile')
begin
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = 'SQLMailProfile',
    @account_name = 'SQLMailAccount',
    @sequence_number = 1
	END

-- Grant Access to the profile name

IF NOT EXISTS
(SELECT [principal_sid]
  FROM [msdb].[dbo].[sysmail_principalprofile] AS  pp
  JOIN
  [msdb].[dbo].[sysmail_profile] as p
  ON
  pp.profile_id = p.profile_id
  WHERE
  P.name = 'SQLMailProfile')
  BEGIN
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
    @profile_name = 'SQLMailProfile',
    @principal_name = 'public',
    @is_default = 1 ;
	END
-- Test Execution of mail

declare @body1 varchar(100)
set @body1 = 'Server :'+@@servername+ ' Is now set up for database mail '
EXEC msdb.dbo.sp_send_dbmail @recipients=N'DBA.Team@YOURDOMAIN',
    @subject = 'I Work on this server ',
    @body = @body1,
    @body_format = 'HTML' ;

-- Enable the Mailbox
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1
GO
EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'UseDatabaseMail', N'REG_DWORD', 1
GO
EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'DatabaseMailProfile', N'REG_SZ', N'SQLMailProfile'
GO




-- Set Agent Mail properties

USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1, 
		@databasemail_profile=N'SQLMailProfile', 
		@use_databasemail=1
GO

USE [msdb]
GO
EXEC master.dbo.sp_MSsetalertinfo @failsafeoperator=N'DBA_Notify', 
		@notificationmethod=1
GO

