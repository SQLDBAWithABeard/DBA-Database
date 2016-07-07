/* This is just a place holder - You need to go to the website and download teh code yourself

Always respect peoples license */

USE master
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_WhoIsActive')
	EXEC ('CREATE PROC dbo.sp_WhoIsActive AS SELECT ''stub version, to be replaced''')
GO

/*********************************************************************************************
Who Is Active? v11.11 (2012-03-22)
(C) 2007-2012, Adam Machanic

Feedback: mailto:amachanic@gmail.com
Updates: http://sqlblog.com/blogs/adam_machanic/archive/tags/who+is+active/default.aspx
"Beta" Builds: http://sqlblog.com/files/folders/beta/tags/who+is+active/default.aspx

Donate! Support this project: http://tinyurl.com/WhoIsActiveDonate

License: 
	Who is Active? is free to download and use for personal, educational, and internal 
	corporate purposes, provided that this header is preserved. Redistribution or sale 
	of Who is Active?, in whole or in part, is prohibited without the author's express 
	written consent.
*********************************************************************************************/