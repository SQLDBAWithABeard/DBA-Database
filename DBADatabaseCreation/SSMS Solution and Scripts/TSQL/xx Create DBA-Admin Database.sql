***********************************
-- create Database
--***********************************
USE [master];
GO

/****** Object:  Database [DBA-Admin]    Script Date: 19/05/2015 13:48:06 ******/

IF NOT EXISTS (Select Name from sys.databases where name = 'DBA-Admin')
CREATE DATABASE [DBA-Admin]

ON  PRIMARY 
( NAME = N'DBA-Admin_System', FILENAME = N'E:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\DATA\DBA-Admin_System.MDF' , SIZE = 131072KB , MAXSIZE = UNLIMITED, FILEGROWTH = 0), 
 FILEGROUP [UserFG]  DEFAULT 
( NAME = N'DBA-Admin_User', FILENAME = N'E:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\DATA\DBA-Admin_User.NDF' , SIZE = 131072KB , MAXSIZE = 5120MB , FILEGROWTH = 131072KB )
LOG ON 
( NAME = N'DBA-Admin_Log', FILENAME = N'E:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\DATA\DBA-Admin_Log.LDF' , SIZE = 131072KB , MAXSIZE = 5120MB , FILEGROWTH = 131072KB );
GO






--***********************************
-- create Table
--***********************************

USE [DBA-Admin];
GO


SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT Name from sys.tables where name = 'Changelog')
CREATE TABLE [dbo].[ChangeLog](
       [ChangeLogID] [int] IDENTITY(1,1) NOT NULL,
       [Date] [datetime] NULL,
       [InstanceName] [nvarchar](50) NULL,
       [ChangeDesc] [nvarchar](500) NULL,
      [UserName] [nvarchar](50) NULL
	   ,
CONSTRAINT [PK_ChangeLogID] PRIMARY KEY CLUSTERED 
(
       [ChangeLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


--***********************************
-- add a line to the change log
--***********************************
USE [DBA-Admin];
GO

IF NOT EXISTS (SELECT * FROM DBO.ChangeLog Where [ChangeDesc] = 'Created new database DBA-Admin')
BEGIN
insert into [dbo].[ChangeLog]
([date], Instancename, changedesc, username)
values 
(
	getdate(),
	convert (nvarchar(50), SERVERPROPERTY ('ServerName')) , 
	'Created new database DBA-Admin',
	system_user
)
END
-- check
select * from [dbo].[ChangeLog]