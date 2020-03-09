
CREATE PROC [dbo].[OfflineDatabasesReport]
@profile_name_P NVARCHAR(500) ='SQLMail',@recipients_P NVARCHAR(500) ='abandaru@analyticsintell.com;vijaynalabolu@analyticsintell.com'
AS
BEGIN
SET NOCOUNT ON
DECLARE @p_subject NVARCHAR(500)
SET @p_subject = N'Offline Databases Report on ' + ( CAST((SELECT SERVERPROPERTY('ServerName')) AS NVARCHAR))

--Send the mail as table Formate
IF(SELECT COUNT(*) FROM sys.databases WHERE state_desc<>'Online')>0
BEGIN
DECLARE @table NVARCHAR(MAX) ;
SET @table =
N'<H2 style=” color: red; ” >Offline Databases Report</H2>' +
N' <span style=” font-size: 16px;” >Following databases are not accessible. Please take immediate action. </span>' +
N'<table border=”1″>' +
N'<tr><th>Database Name</th><th>Database Status</th></tr>' +
CAST ( ( SELECT td=name, '' ,td=state_desc FROM sys.databases WHERE state_desc<>'Online'
FOR XML PATH('tr'), TYPE
) AS NVARCHAR(MAX) ) +
N'</table>' ;
EXEC msdb.dbo.sp_send_dbmail
@profile_name=@profile_name_P, ---Change to your Profile Name
@recipients=@recipients_P, --Put the email address of those who want to receive the e-mail
@subject = @p_subject ,
@body = @table,
@body_format = 'HTML' ;
END
ELSE PRINT 'All Databases are Online'
END


