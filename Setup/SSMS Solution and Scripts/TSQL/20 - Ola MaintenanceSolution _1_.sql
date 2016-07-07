-- THIS IS A PLACE HOLDER - you need to download the solution yourself - respect the licenses
-- I recommend this alter the default log and diff job creation to set ChangeBackupType to Y to catch new databases

/*

USE [DBA-Admin] -- Specify the database in which the objects will be created.

SET @CreateJobs          = 'Y'          -- Specify whether jobs should be created.
SET @BackupDirectory     = N'' -- Specify the backup root directory.
SET @CleanupTime         = NULL         -- Time in hours, after which backup files are deleted. If no time is specified, then no backup files are deleted.
SET @OutputFileDirectory = NULL         -- Specify the output file directory. If no directory is specified, then the SQL Server error log directory is used.
SET @LogToTable          = 'Y'          -- Log commands to a table.


SQL Server Maintenance Solution - SQL Server 2005, SQL Server 2008, SQL Server 2008 R2, SQL Server 2012, and SQL Server 2014

Backup: https://ola.hallengren.com/sql-server-backup.html
Integrity Check: https://ola.hallengren.com/sql-server-integrity-check.html
Index and Statistics Maintenance: https://ola.hallengren.com/sql-server-index-and-statistics-maintenance.html

The solution is free: https://ola.hallengren.com/license.html

You can contact me by e-mail at ola@hallengren.com.

Last updated 25 January, 2015.

Ola Hallengren
https://ola.hallengren.com

30/04/2015 - Rob Sewell - Altered default log and diff job creation to set ChangeBackupType to Y to catch new databases
*/

USE [DBA-Admin] -- Specify the database in which the objects will be created.

SET NOCOUNT ON

DECLARE @CreateJobs nvarchar(max)
DECLARE @BackupDirectory nvarchar(max)
DECLARE @CleanupTime int
DECLARE @OutputFileDirectory nvarchar(max)
DECLARE @LogToTable nvarchar(max)
DECLARE @Version numeric(18,10)
DECLARE @Error int

SET @CreateJobs          = 'Y'          -- Specify whether jobs should be created.
SET @BackupDirectory     = N'' -- Specify the backup root directory.
SET @CleanupTime         = NULL         -- Time in hours, after which backup files are deleted. If no time is specified, then no backup files are deleted.
SET @OutputFileDirectory = NULL         -- Specify the output file directory. If no directory is specified, then the SQL Server error log directory is used.
SET @LogToTable          = 'Y'          -- Log commands to a table.

SET @Error = 0
