
CREATE PROCEDURE [dbo].[CheckandTrackBlockingSessions]
AS
/*********************************************************
	original ?? - DBA team - job script
	mods - procedure; capture results in perm table
*********************************************************/
SET NOCOUNT ON
declare @firstquery nvarchar(max)
declare @secondquery nvarchar(max)
declare @tableHTML  NVARCHAR(MAX)
declare @PostedDate datetime

declare @BlockingSessions table (
	[spid] smallint NULL,
	[hostname] varchar(10) NULL,
	[database] varchar(10) NULL,
	[program_name] VARCHAR(25) NULL,
	[loginame] VARCHAR(20) NULL, 
	[login_time] VARCHAR(20) NULL,
	[last_batch] VARCHAR(20) NULL, 
	[cmd] VARCHAR(20) NULL,
	[Block] VARCHAR(20) NULL,
	[sql_handle] binary(20) NULL,
	[BlockingTSQL] nvarchar(max) NULL,
	[PostedDate] datetime NOT NULL 
)
declare @LocksDuringBlocking table (
	[isolation_level] varchar(40) NULL,
	[resource_type] nvarchar(60) NULL,
	[resource_database_id] int NULL,
	[resource_associated_entity_id] bigint NULL,
	[request_mode] nvarchar(60) NULL,
	[request_session_id] int NULL,
	[blocking_session_id] smallint NULL,
	[object name] sysname NULL,
	[object descr] nvarchar(60) NULL,
	[partition id] bigint NULL,
	[partition/page rows] bigint NULL,
	[index descr] nvarchar(60) NULL,
	[index/page container_id] bigint NULL,
	[PostedDate] datetime NOT NULL
)

set @firstquery = 
	N'SELECT s.spid, CAST(s.hostname AS VARCHAR(10)) as hostname, CAST(d.[name] AS VARCHAR(10)) as [database], 
		CAST(s.[program_name] AS VARCHAR(25)) as [program_name], CAST(s.loginame AS VARCHAR(20)) as loginame, 
		CAST(s.login_time AS VARCHAR(20)) as login_time , CAST(s.last_batch AS VARCHAR(20)) as last_batch , 
		CAST(s.cmd AS VARCHAR(20)) as cmd, ''Blocking'' as Block
		,s.[sql_handle]
		,@PostedDate as PostedDate
	FROM sys.sysprocesses s WITH(NOLOCK) JOIN sys.sysprocesses s1 WITH(NOLOCK) ON s.spid = s1.blocked
	JOIN sys.sysdatabases d WITH(NOLOCK) ON s.dbid = d.dbid 
	WHERE s.blocked = 0
	UNION ALL
	SELECT s2.spid, CAST(s2.hostname AS VARCHAR(10)) as hostname, CAST(d1.[name] AS VARCHAR(10)) as [database],
		CAST(s2.[program_name] AS VARCHAR(25)) as [program_name], CAST(s2.loginame AS VARCHAR(20)) as loginame, 
		CAST(s2.login_time AS VARCHAR(20)) as login_time , CAST(s2.last_batch AS VARCHAR(20)) as last_batch , 
		CAST(s2.cmd AS VARCHAR(20)) as cmd, ''Blocked by '' + CAST(s2.blocked AS VARCHAR(3)) as Block
		,s2.[sql_handle]
		,@PostedDate as PostedDate
	FROM sys.sysprocesses s2 WITH(NOLOCK) 
	JOIN sys.sysdatabases d1 WITH(NOLOCK) ON s2.dbid = d1.dbid 
	WHERE s2.blocked > 0
	'
set @secondquery = 
	N'SELECT
		case 
		when e1.transaction_isolation_level = 1 then ''ReadUncomitted''
		when e1.transaction_isolation_level = 2 then ''ReadCommitted''
		when e1.transaction_isolation_level = 3 then ''Repeatable''
		when e1.transaction_isolation_level = 4 then ''Serializable''
		when e1.transaction_isolation_level = 5 then ''Snapshot''
		end as [isolation_level],
		t1.resource_type, 
		t1.resource_database_id, 
		t1.resource_associated_entity_id, 
		t1.request_mode, 
		t1.request_session_id, 
		t2.blocking_session_id, 
		o1.name ''object name'', 
		o1.type_desc ''object descr'', 
		p1.partition_id ''partition id'', 
		p1.rows ''partition/page rows'', 
		a1.type_desc ''index descr'', 
		a1.container_id ''index/page container_id''
		,@PostedDate as PostedDate
	FROM sys.dm_tran_locks as t1 
	INNER JOIN sys.dm_os_waiting_tasks as t2 ON t1.lock_owner_address = t2.resource_address 
	LEFT OUTER JOIN sys.objects o1 on o1.object_id = t1.resource_associated_entity_id 
	LEFT OUTER JOIN sys.partitions p1 on p1.hobt_id = t1.resource_associated_entity_id 
	LEFT OUTER JOIN sys.allocation_units a1 on a1.allocation_unit_id = t1.resource_associated_entity_id 
	LEFT OUTER JOIN sys.dm_exec_sessions e1 on t1.request_session_id = e1.session_id
	'

IF (SELECT top 1 blocked from sys.sysprocesses where blocked !=0) > 0
   BEGIN

   DECLARE @blockingSPID TABLE(blocked SMALLINT)
   INSERT INTO @blockingSPID SELECT blocked FROM sys.sysprocesses WHERE blocked !=0

   WAITFOR DELAY '00:02:30'

   IF EXISTS (SELECT DISTINCT blocked FROM sys.sysprocesses WHERE blocked IN (SELECT DISTINCT blocked FROM @blockingSPID))
      BEGIN
		SET @PostedDate = GETDATE();
		
		-- one time only run to capture blocking info
		INSERT INTO @BlockingSessions 
			([spid],[hostname],[database],[program_name],[loginame],[login_time],[last_batch],[cmd],[Block],[sql_handle],[PostedDate])
			EXECUTE sp_executesql @firstquery,N'@PostedDate datetime',@PostedDate = @PostedDate;
		INSERT INTO @LocksDuringBlocking
			([isolation_level],[resource_type],[resource_database_id],[resource_associated_entity_id],
			 [request_mode],[request_session_id],[blocking_session_id],[object name],[object descr],
			 [partition id],[partition/page rows],[index descr],[index/page container_id],[PostedDate])
			EXECUTE sp_executesql @secondquery,N'@PostedDate datetime',@PostedDate = @PostedDate;
		-- capture query for lead blockers
		UPDATE bsns
			SET bsns.[BlockingTSQL] = dmesqlt.[text]
		FROM @BlockingSessions bsns
		CROSS APPLY sys.dm_exec_sql_text(bsns.sql_handle) AS dmesqlt
		WHERE bsns.[Block] = 'Blocking'

		-- setup the email notication body; header first
		SET @tableHTML =
			  N'<html>'
			+ N'<head>' 
			+ N'<style>td {border: solid black;border-width: 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font: 11px arial}</style>'
			+ N'</head>' 
			+ N'<body>ALERT! There is blocking on the Prod instance. Please look at the server ASAP   (posted date ' +CONVERT(nvarchar(19),@PostedDate,100) + ')'
			+ N'<br>'
		-- second, if captured blocking sessions, include ... 
		IF EXISTS (SELECT NULL FROM @BlockingSessions)
			BEGIN
			SET @tableHTML = @tableHTML +
				N'<H5>Blocking Sessions  (note: perm table has lead blocker queries)</H5>' +  
				N'<table cellpadding=0 cellspacing=0 border=0>' +  
				N'<col width="500px" />' +
				N'<tr>' +
				N'<td bgcolor=#E6E6FA><b>spid</b></td>' +
				N'<td bgcolor=#E6E6FA><b>hostname</b></td>' +
				N'<td bgcolor=#E6E6FA><b>database</b></td>' +
				N'<td bgcolor=#E6E6FA><b>program_name</b></td>' +
				N'<td bgcolor=#E6E6FA><b>loginame</b></td>' +
				N'<td bgcolor=#E6E6FA><b>login_time</b></td>' +
				N'<td bgcolor=#E6E6FA><b>last_batch</b></td>' +
				N'<td bgcolor=#E6E6FA><b>cmd</b></td>' +
				N'<td bgcolor=#E6E6FA><b>Block</b></td>' +
				N'</tr>' +  
				CAST ( ( 
					SELECT
						td=COALESCE([spid],''),'',td=COALESCE([hostname],''),'',td=COALESCE([database],''),'',
						td=COALESCE([program_name],''),'',td=COALESCE([loginame],''),'',td=COALESCE([login_time],''),'',
						td=COALESCE([last_batch],''),'',td=COALESCE([cmd],''),'',td=COALESCE([Block],''),''
					FROM @BlockingSessions
					FOR XML PATH('tr'), TYPE   
				) AS NVARCHAR(MAX) ) +  
				N'</table>' +
				N'<br>' ;
			END
		-- third, if captured lock info, include ...
		IF EXISTS (SELECT NULL FROM @LocksDuringBlocking)
			BEGIN
			SET @tableHTML = @tableHTML +
				N'<H5>Locks during Blocking</H5>' +  
				N'<table cellpadding=0 cellspacing=0 border=0>' +  
				N'<col width="500px" />' +
				N'<tr>' +
				N'<td bgcolor=#E6E6FA><b>isolation_level</b></td>' +
				N'<td bgcolor=#E6E6FA><b>resource_type</b></td>' +
				N'<td bgcolor=#E6E6FA><b>resource_database_id</b></td>' +
				N'<td bgcolor=#E6E6FA><b>resource_associated_entity_id</b></td>' +
				N'<td bgcolor=#E6E6FA><b>request_mode</b></td>' +
				N'<td bgcolor=#E6E6FA><b>request_session_id</b></td>' +
				N'<td bgcolor=#E6E6FA><b>blocking_session_id</b></td>' +
				N'<td bgcolor=#E6E6FA><b>object name</b></td>' +
				N'<td bgcolor=#E6E6FA><b>object descr</b></td>' +
				N'<td bgcolor=#E6E6FA><b>partition id</b></td>' +
				N'<td bgcolor=#E6E6FA><b>partition/page rows</b></td>' +
				N'<td bgcolor=#E6E6FA><b>index descr</b></td>' +
				N'<td bgcolor=#E6E6FA><b>index/page container_id</b></td>' +
				N'</tr>' +  
				CAST ( ( 
					SELECT 
						td=COALESCE([isolation_level],''),'',td=COALESCE([resource_type],''),'',
						td=COALESCE([resource_database_id],''),'',td=COALESCE([resource_associated_entity_id],''),'',
						td=COALESCE([request_mode],''),'',td=COALESCE([request_session_id],''),'',
						td=COALESCE([blocking_session_id],''),'',td=COALESCE([object name],''),'',
						td=COALESCE([object descr],''),'',td=COALESCE([partition id],''),'',
						td=COALESCE([partition/page rows],''),'',td=COALESCE([index descr],''),'',
						td=COALESCE([index/page container_id],''),''
					FROM @LocksDuringBlocking
					FOR XML PATH('tr'), TYPE   
				) AS NVARCHAR(MAX) ) +  
				N'</table>' +
				N'<br>' ;
			END
		-- last, cap the end of email body
		SET @tableHTML = @tableHTML +
			N'</body>' +
			N'</html>'

		-- send email notification
		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'SQLMail',
			@recipients = 'abandaru@analyticsintell.com;vijaynalabolu@analyticsintell.com',
			@subject = 'CECL-DEV-SQL2 - !!ALERT!! - Blocking on DEV Server' ,
			@body = @tableHTML,  
			@body_format = 'HTML' ; 

		-- capture results
		INSERT INTO [dbo].[TrackBlockingSessions]
			([spid],[hostname],[database],[program_name],[loginame],[login_time],[last_batch],[cmd],[Block],[BlockingTSQL],[PostedDate])
			SELECT [spid],[hostname],[database],[program_name],[loginame],[login_time],[last_batch],[cmd],[Block],[BlockingTSQL],[PostedDate]
			FROM @BlockingSessions ;
		INSERT INTO [dbo].[TrackLocksDuringBlocking]
			([isolation_level],[resource_type],[resource_database_id],[resource_associated_entity_id],
			 [request_mode],[request_session_id],[blocking_session_id],[object name],[object descr],
			 [partition id],[partition/page rows],[index descr],[index/page container_id],[PostedDate])
			SELECT [isolation_level],[resource_type],[resource_database_id],[resource_associated_entity_id],
				 [request_mode],[request_session_id],[blocking_session_id],[object name],[object descr],
				 [partition id],[partition/page rows],[index descr],[index/page container_id],[PostedDate]
			FROM @LocksDuringBlocking ;

     END

   END

