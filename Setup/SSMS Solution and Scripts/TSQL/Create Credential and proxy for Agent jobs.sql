/* Script to create the credential and proxy for the DBA Database Agent jobs to run on server XXXXXXX*/

USE [master]
GO
CREATE CREDENTIAL [SVC_DBADatabase] WITH IDENTITY = N'THEBEARD\SVC_DBADatabase', SECRET = N'Password01'
GO

USE [msdb]
GO
EXEC msdb.dbo.sp_add_proxy @proxy_name=N'SVC_DBADatabase',@credential_name=N'SVC_DBADatabase', 
		@enabled=1, 
		@description=N'Proxy for running DBADatabase Accounts should be sysadmin on servers'
GO
EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'SVC_DBADatabase', @subsystem_id=3
GO
EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'SVC_DBADatabase', @subsystem_id=12
GO
