



--USE DBA

--GO

--/*

--	TABLE TO STORE THE HISTORICAL DEADLOCK GRAPHS

--*/

--CREATE TABLE dbo.DeadlockEvents

--(

--	AlertTime		DATETIME,

--	DeadlockGraph	XML

--)                               



/*

	PROCEDURE TO PROCESS THE DEADLOCK GRAPH AND SEND MAIL

*/                              

CREATE PROC [dbo].[DBA_Deadlock_graph]  @xml XML  

AS  

BEGIN  

SET NOCOUNT ON;  

  

DECLARE @body VARCHAR(MAX)  

CREATE TABLE #victim_list(process_id VARCHAR(100))  

CREATE TABLE #processdetails  

(  

 id					VARCHAR(100),  

 taskpriority		VARCHAR(100),  

 logused			VARCHAR(100),  

 waitresource		VARCHAR(100),  

 waittime			VARCHAR(100),  

 ownerId			VARCHAR(100),  

 transactionname	VARCHAR(100),  

 lasttranstarted	VARCHAR(100),  

 XDES				VARCHAR(100),  

 lockMode			VARCHAR(100),  

 schedulerid		VARCHAR(100),  

 kpid				VARCHAR(100),  

 status				VARCHAR(100),  

 spid				VARCHAR(100),  

 sbid				VARCHAR(100),  

 ecid				VARCHAR(100),  

 priority			VARCHAR(100),  

 trancount			VARCHAR(100),  

 lastbatchstarted	VARCHAR(100),  

 lastbatchcompleted VARCHAR(100),  

 clientapp			VARCHAR(100),  

 hostname			VARCHAR(100),  

 hostpid			VARCHAR(100),  

 loginname			VARCHAR(100),  

 isolationlevel		VARCHAR(100),  

 xactid				VARCHAR(100),  

 currentdb			VARCHAR(100),  

 lockTimeout		VARCHAR(100),  

 clientoption1		VARCHAR(100),  

 clientoption2		VARCHAR(100)  

)  

CREATE TABLE #frame_details  

(  

 id					VARCHAR(100),  

 procname			VARCHAR(100),  

 line				VARCHAR(100),  

 stmtstart			VARCHAR(100),  

 sqlhandle			VARCHAR(100)  

)  

CREATE TABLE #frame_values  

(  

 id					VARCHAR(100),  

 frame				VARCHAR(max)  

)  

CREATE TABLE #input_buffer  

(  

 id					VARCHAR(100),  

 inputbuf			VARCHAR(max)  

)  

CREATE TABLE #resource_details_keylock  

(  

 hobtid				VARCHAR(100),  

 dbid				VARCHAR(100),  

 objectname			VARCHAR(100),  

 indexname			VARCHAR(100),  

 lock_id			VARCHAR(100),  

 mode				VARCHAR(100),  

 associatedObjectId VARCHAR(100),  

 owner_id			VARCHAR(100),  

 owner_mode			VARCHAR(100),  

 waiter_id			VARCHAR(100),  

 waiter_mode		VARCHAR(100),  

 waiter_requestType VARCHAR(100)  

)  

  

CREATE TABLE #resource_details_objectlock  

(  

 lockpartition		VARCHAR(100),  

 objid				VARCHAR(100),  

 subresource		VARCHAR(100),  

 dbid				VARCHAR(100),  

 objectname			VARCHAR(100),  

 lock_id			VARCHAR(100),  

 mode				VARCHAR(100),  

 associatedObjectId VARCHAR(100),  

 owner_id			VARCHAR(100),  

 owner_mode			VARCHAR(100),  

 waiter_id			VARCHAR(100),  

 waiter_mode		VARCHAR(100),  

 waiter_requestType VARCHAR(100)  

)  

  

CREATE TABLE #resource_details_databaselock  

(  

 subresource		VARCHAR(100),  

 dbid				VARCHAR(100),  

 dbname				VARCHAR(100),  

 lock_id			VARCHAR(100),  

 mode				VARCHAR(100),  

 owner_id			VARCHAR(100),  

 owner_mode			VARCHAR(100),  

 waiter_id			VARCHAR(100),  

 waiter_mode		VARCHAR(100),  

 waiter_requestType VARCHAR(100)  

)  

  

CREATE TABLE #resource_details_exchangeEvent  

(  

 id					VARCHAR(100),  

 waitType			VARCHAR(100),  

 nodeId				VARCHAR(100),  

 owner_id			VARCHAR(100),  

 owner_mode			VARCHAR(100),  

 waiter_id			VARCHAR(100),  

 waiter_mode		VARCHAR(100),  

 waiter_requestType VARCHAR(100)  

)  

  

CREATE TABLE #resource_details_metadatalock  

(  

 subresource		VARCHAR(100),  

 classid			VARCHAR(100),  

 dbid				VARCHAR(100),  

 dbname				VARCHAR(100),  

 lock_id			VARCHAR(100),  

 mode				VARCHAR(100),  

 owner_id			VARCHAR(100),  

 owner_mode			VARCHAR(100),  

 waiter_id			VARCHAR(100),  

 waiter_mode		VARCHAR(100),  

 waiter_requestType VARCHAR(100)  

)  

  

CREATE TABLE #resource_details_pagelock  

(  

 fileid				VARCHAR(100),  

 pageid				VARCHAR(100),  

 dbid				VARCHAR(100),  

 dbname				VARCHAR(100),  

 objectname			VARCHAR(100),  

 lock_id			VARCHAR(100),  

 mode				VARCHAR(100),  

 associatedObjectId VARCHAR(100),  

 owner_id			VARCHAR(100), 

 owner_mode			VARCHAR(100),  

 waiter_id			VARCHAR(100),  

 waiter_mode		VARCHAR(100),  

 waiter_requestType VARCHAR(100)  

)  

  

create table #resource_details_ridlock  

(  

 pageid				VARCHAR(100),  

 dbid				VARCHAR(100),  

 dbname				VARCHAR(100),  

 objectname			VARCHAR(100),  

 lock_id			VARCHAR(100),  

 mode				VARCHAR(100),  

 associatedObjectId VARCHAR(100),  

 owner_id			VARCHAR(100),  

 owner_mode			VARCHAR(100),  

 waiter_id			VARCHAR(100),  

 waiter_mode		VARCHAR(100),  

 waiter_requestType VARCHAR(100)  

)  

  

INSERT INTO #victim_list  

		SELECT dl.n.value('@victim','VARCHAR(100)')  

		FROM @xml.nodes('TextData/deadlock-list/deadlock') dl(n)  

  

INSERT INTO #processdetails  

	 select dl.n.value('@id[1]','VARCHAR(100)') AS id,  

	 dl.n.value('@taskpriority[1]','VARCHAR(100)') AS taskpriority,  

	 dl.n.value('@logused[1]','VARCHAR(100)') AS logused,  

	 dl.n.value('@waitresource[1]','VARCHAR(100)') AS waitresource,  

	 dl.n.value('@waittime[1]','VARCHAR(100)') AS waittime,  

	 dl.n.value('@ownerId[1]','VARCHAR(100)') AS ownerId,  

	 dl.n.value('@transactionname[1]','VARCHAR(100)') AS transactionname,  

	 dl.n.value('@lasttranstarted[1]','VARCHAR(100)') AS lasttranstarted,  

	 dl.n.value('@XDES[1]','VARCHAR(100)') AS XDES,  

	 dl.n.value('@lockMode[1]','VARCHAR(100)') AS lockMode,  

	 dl.n.value('@schedulerid[1]','VARCHAR(100)') AS schedulerid,  

	 dl.n.value('@kpid[1]','VARCHAR(100)') AS kpid,  

	 dl.n.value('@status[1]','VARCHAR(100)') AS status,  

	 dl.n.value('@spid[1]','VARCHAR(100)') AS spid,  

	 dl.n.value('@sbid[1]','VARCHAR(100)') AS sbid,  

	 dl.n.value('@ecid[1]','VARCHAR(100)') AS ecid,  

	 dl.n.value('@priority[1]','VARCHAR(100)') AS priority,  

	 dl.n.value('@trancount[1]','VARCHAR(100)') AS trancount,  

	 dl.n.value('@lastbatchstarted[1]','VARCHAR(100)') AS lastbatchstarted,  

	 dl.n.value('@lastbatchcompleted[1]','VARCHAR(100)') AS lastbatchcompleted,  

	 dl.n.value('@clientapp[1]','VARCHAR(100)') AS clientapp,  

	 dl.n.value('@hostname[1]','VARCHAR(100)') AS hostname,  

	 dl.n.value('@hostpid[1]','VARCHAR(100)') AS hostpid,  

	 dl.n.value('@loginname[1]','VARCHAR(100)') AS loginname,  

	 dl.n.value('@isolationlevel[1]','VARCHAR(100)') AS isolationlevel,  

	 dl.n.value('@xactid[1]','VARCHAR(100)') AS xactid,  

	 dl.n.value('@currentdb[1]','VARCHAR(100)') AS currentdb,  

	 dl.n.value('@lockTimeout[1]','VARCHAR(100)') AS lockTimeout,  

	 dl.n.value('@clientoption1[1]','VARCHAR(100)') AS clientoption1,  

	 dl.n.value('@clientoption2[1]','VARCHAR(100)') AS clientoption2  

	 FROM @xml.nodes('//TextData/deadlock-list/deadlock/process-list/process') dl(n)  

  



INSERT INTO #frame_details  

	 SELECT dl.n.value('../../@id[1]','VARCHAR(100)') AS id,  

	 dl.n.value('@procname[1]','VARCHAR(100)') AS procname,  

	 dl.n.value('@line[1]','VARCHAR(100)') AS line,  

	 dl.n.value('@stmtstart[1]','VARCHAR(100)') AS stmtstart,  

	 dl.n.value('@sqlhandle[1]','VARCHAR(100)') AS sqlhandle  

	 FROM @xml.nodes('//TextData/deadlock-list/deadlock/process-list/process/executionStack/frame') dl(n)  

  

INSERT INTO #frame_values  

	SELECT dl.n.value('../@id[1]','VARCHAR(100)') AS id,  

	dl.n.value('frame[1]','VARCHAR(100)') AS frame   

	FROM @xml.nodes('//TextData/deadlock-list/deadlock/process-list/process/executionStack') dl(n)  

  

INSERT INTO #input_buffer  

	SELECT dl.n.value('@id[1]','VARCHAR(100)') AS id,  

	dl.n.value('inputbuf[1]','VARCHAR(100)') AS inputbuf   

	FROM @xml.nodes('//TextData/deadlock-list/deadlock/process-list/process') dl(n)  

  

INSERT INTO #resource_details_keylock  

	 SELECT dl.n.value('@hobtid[1]','VARCHAR(100)') AS hobtid,  

	 dl.n.value('@dbid[1]','VARCHAR(100)') AS dbid,  

	 dl.n.value('@objectname[1]','VARCHAR(100)') AS objectname,  

	 dl.n.value('@indexname[1]','VARCHAR(100)') AS indexname,  

	 dl.n.value('@id[1]','VARCHAR(100)') AS lock_id,  

	 dl.n.value('@mode[1]','VARCHAR(100)') AS mode,  

	 dl.n.value('@associatedObjectId[1]','VARCHAR(100)') AS associatedObjectId,  

	 dl.n.value('(owner-list/owner)[1]/@id','VARCHAR(100)') AS owner_id,  

	 dl.n.value('(owner-list/owner)[1]/@mode','VARCHAR(100)') AS owner_mode,  

	 dl.n.value('(waiter-list/waiter)[1]/@id','VARCHAR(100)') AS waiter_id,  

	 dl.n.value('(waiter-list/waiter)[1]/@mode','VARCHAR(100)') AS waiter_mode,  

	 dl.n.value('(waiter-list/waiter)[1]/@requestType','VARCHAR(100)') AS waiter_requestType  

	 FROM @xml.nodes('//TextData/deadlock-list/deadlock/resource-list/keylock') dl(n)  

  

INSERT INTO #resource_details_objectlock  

	SELECT dl.n.value('@lockpartition[1]','VARCHAR(100)') AS lockpartition,  

     dl.n.value('@objid[1]','VARCHAR(100)') AS objid,  

     dl.n.value('@subresource[1]','VARCHAR(100)') AS subresource,  

	 dl.n.value('@dbid[1]','VARCHAR(100)') AS dbid,  

	 dl.n.value('@objectname[1]','VARCHAR(100)') AS objectname,  

	 dl.n.value('@id[1]','VARCHAR(100)') AS lock_id,  

	 dl.n.value('@mode[1]','VARCHAR(100)') AS mode,  

	 dl.n.value('@associatedObjectId[1]','VARCHAR(100)') AS associatedObjectId,  

	 dl.n.value('(owner-list/owner)[1]/@id','VARCHAR(100)') AS owner_id,  

	 dl.n.value('(owner-list/owner)[1]/@mode','VARCHAR(100)') AS owner_mode,  

	 dl.n.value('(waiter-list/waiter)[1]/@id','VARCHAR(100)') AS waiter_id,  

	 dl.n.value('(waiter-list/waiter)[1]/@mode','VARCHAR(100)') AS waiter_mode,  

	 dl.n.value('(waiter-list/waiter)[1]/@requestType','VARCHAR(100)') AS waiter_requestType  

	FROM @xml.nodes('//TextData/deadlock-list/deadlock/resource-list/objectlock') dl(n)  

	  

INSERT INTO #resource_details_databaselock  

	 SELECT dl.n.value('@subresource[1]','VARCHAR(100)') AS subresource,  

	 dl.n.value('@dbid[1]','VARCHAR(100)') AS dbid,  

	 db_name(dl.n.value('@dbid[1]','VARCHAR(100)')) AS dbname,  

	 dl.n.value('@id[1]','VARCHAR(100)') AS lock_id,  

	 dl.n.value('@mode[1]','VARCHAR(100)') AS mode,  

	 dl.n.value('(owner-list/owner)[1]/@id','VARCHAR(100)') AS owner_id,  

	 dl.n.value('(owner-list/owner)[1]/@mode','VARCHAR(100)') AS owner_mode,  

	 dl.n.value('(waiter-list/waiter)[1]/@id','VARCHAR(100)') AS waiter_id,  

	 dl.n.value('(waiter-list/waiter)[1]/@mode','VARCHAR(100)') AS waiter_mode,  

	 dl.n.value('(waiter-list/waiter)[1]/@requestType','VARCHAR(100)') AS waiter_requestType  

	FROM @xml.nodes('//TextData/deadlock-list/deadlock/resource-list/databaselock') dl(n)  

	  

INSERT INTO #resource_details_exchangeEvent  

	 SELECT dl.n.value('@id[1]','VARCHAR(100)') AS lock_id,  

	 dl.n.value('@waitType[1]','VARCHAR(100)') AS waitType,  

	 dl.n.value('@nodeId[1]','VARCHAR(100)') AS nodeId,  

	 dl.n.value('(owner-list/owner)[1]/@id','VARCHAR(100)') AS owner_id,  

	 dl.n.value('(owner-list/owner)[1]/@mode','VARCHAR(100)') AS owner_mode,  

	 dl.n.value('(waiter-list/waiter)[1]/@id','VARCHAR(100)') AS waiter_id,  

	 dl.n.value('(waiter-list/waiter)[1]/@mode','VARCHAR(100)') AS waiter_mode,  

	 dl.n.value('(waiter-list/waiter)[1]/@requestType','VARCHAR(100)') AS waiter_requestType  

	 FROM @xml.nodes('//TextData/deadlock-list/deadlock/resource-list/exchangeEvent') dl(n)  

  

INSERT INTO #resource_details_metadatalock  

	SELECT dl.n.value('@subresource[1]','VARCHAR(100)') AS subresource,  

    dl.n.value('@classid[1]','VARCHAR(100)') AS classid,  

	dl.n.value('@dbid[1]','VARCHAR(100)') AS dbid,  

	db_name(dl.n.value('@dbid[1]','VARCHAR(100)')) AS dbname,  

	dl.n.value('@id[1]','VARCHAR(100)') AS lock_id,  

	dl.n.value('@mode[1]','VARCHAR(100)') AS mode,  

	dl.n.value('(owner-list/owner)[1]/@id','VARCHAR(100)') AS owner_id,  

	dl.n.value('(owner-list/owner)[1]/@mode','VARCHAR(100)') AS owner_mode,  

	dl.n.value('(waiter-list/waiter)[1]/@id','VARCHAR(100)') AS waiter_id,  

	dl.n.value('(waiter-list/waiter)[1]/@mode','VARCHAR(100)') AS waiter_mode,  

	dl.n.value('(waiter-list/waiter)[1]/@requestType','VARCHAR(100)') AS waiter_requestType  

	FROM @xml.nodes('//TextData/deadlock-list/deadlock/resource-list/metadatalock') dl(n)  

  

INSERT INTO #resource_details_pagelock  

	 SELECT dl.n.value('@fileid[1]','VARCHAR(100)') AS fileid,  

     dl.n.value('@pageid[1]','VARCHAR(100)') AS pageid,  

	 dl.n.value('@dbid[1]','VARCHAR(100)') AS dbid,  

	 db_name(dl.n.value('@dbid[1]','VARCHAR(100)')) AS dbname,  

	 dl.n.value('@objectname[1]','VARCHAR(100)') AS objectname,  

	 dl.n.value('@id[1]','VARCHAR(100)') AS lock_id,  

	 dl.n.value('@mode[1]','VARCHAR(100)') AS mode,  

	 dl.n.value('@associatedObjectId[1]','VARCHAR(100)') AS associatedObjectId,  

	 dl.n.value('(owner-list/owner)[1]/@id','VARCHAR(100)') AS owner_id,  

	 dl.n.value('(owner-list/owner)[1]/@mode','VARCHAR(100)') AS owner_mode,  

	 dl.n.value('(waiter-list/waiter)[1]/@id','VARCHAR(100)') AS waiter_id,  

	 dl.n.value('(waiter-list/waiter)[1]/@mode','VARCHAR(100)') AS waiter_mode,  

	 dl.n.value('(waiter-list/waiter)[1]/@requestType','VARCHAR(100)') AS waiter_requestType  

	 FROM @xml.nodes('//TextData/deadlock-list/deadlock/resource-list/pagelock') dl(n)  

	  

INSERT INTO #resource_details_ridlock  

	 SELECT dl.n.value('@pageid[1]','VARCHAR(100)') AS pageid,  

	 dl.n.value('@dbid[1]','VARCHAR(100)') AS dbid,  

	 db_name(dl.n.value('@dbid[1]','VARCHAR(100)')) AS dbname,  

	 dl.n.value('@objectname[1]','VARCHAR(100)') AS objectname,  

	 dl.n.value('@id[1]','VARCHAR(100)') AS lock_id,  

	 dl.n.value('@mode[1]','VARCHAR(100)') AS mode,  

	 dl.n.value('@associatedObjectId[1]','VARCHAR(100)') AS associatedObjectId,  

	 dl.n.value('(owner-list/owner)[1]/@id','VARCHAR(100)') AS owner_id,  

	 dl.n.value('(owner-list/owner)[1]/@mode','VARCHAR(100)') AS owner_mode,  

	 dl.n.value('(waiter-list/waiter)[1]/@id','VARCHAR(100)') AS waiter_id,  

	 dl.n.value('(waiter-list/waiter)[1]/@mode','VARCHAR(100)') AS waiter_mode,  

	 dl.n.value('(waiter-list/waiter)[1]/@requestType','VARCHAR(100)') AS waiter_requestType  

	FROM @xml.nodes('//TextData/deadlock-list/deadlock/resource-list/ridlock') dl(n)  

  

SELECT @body='<table border="1"><tr><th>Process id(Victim)</th></tr>'  

SELECT @body=@body+'<tr><td>'+isnull(process_id,'')+'</td></tr>' from #victim_list  

SELECT @body=@body+'</table><br/><br/>'  

  

SELECT @body=@body+'Process Details:<br><table border="1">  

      <tr>  

       <th>Process id</th>  

       <th>DB_Name</th>  

       <th>procname</th>  

       <th>waittime</th>  

       <th>lockMode</th>  

       <th>trancount</th>  

       <th>clientapp</th>  

       <th>hostname</th>  

       <th>loginname</th>  

       <th>frame</th>  

       <th>inputbuf</th>  

      </tr>'  

  

SELECT DISTINCT isnull(pd.id,'') as [id],  

 isnull(db_name(pd.currentdb),'') as [currentdb],  

 isnull(fd.procname,'') as [procname],  

 isnull(pd.waittime,'') as [waittime],  

 isnull(pd.lockMode,'') as [lockMode],  

 isnull(pd.trancount,'') as [trancount],  

 isnull(pd.clientapp,'') as [clientapp],  

 isnull(pd.hostname,'') as [hostname],  

 isnull(pd.loginname,'') as [loginname],  

 isnull(fv.frame,'') as [frame],  

 isnull(ib.inputbuf,'') as [inputbuf]  

into #p_details_temp  

from #processdetails pd  

left join #frame_details fd on pd.id=fd.id  

left join #frame_values fv on fd.id=fv.id  

left join #input_buffer ib on fv.id=ib.id  

  

SELECT @body=@body+  

  '<tr><td>'+id+'</td>'+  

  '<td>'+currentdb+'</td>'+  

  '<td>'+procname+'</td>'+  

  '<td>'+waittime+'</td>'+  

  '<td>'+lockMode+'</td>'+  

  '<td>'+trancount+'</td>'+  

  '<td>'+clientapp+'</td>'+  

  '<td>'+hostname+'</td>'+  

  '<td>'+loginname+'</td>'+  

  '<td>'+frame+'</td>'+  

  '<td>'+inputbuf+'</td></tr>'  

FROM #p_details_temp  

SELECT @body=@body+'</table><br/><br/>'  

  

IF EXISTS (SELECT TOP 1 * FROM #resource_details_keylock) 

BEGIN  

	SELECT @body=@body+'Keylock:<br><table border="1"> <tr>'+   

	 '<th>hobtid,</th>'+  

	 '<th>dbid,</th>'+  

	 '<th>objectname,</th>'+  

	 '<th>indexname,</th>'+  

	 '<th>lock_id,</th>'+  

	 '<th>mode,</th>'+  

	 '<th>associatedObjectId,</th>'+  

	 '<th>owner_id,</th>'+  

	 '<th>owner_mode,</th>'+  

	 '<th>waiter_id,</th>'+  

	 '<th>waiter_mode,</th>'+  

	 '<th>waiter_requestType,</th>'+  

	 '</tr>'  

	select @body=@body+'<tr>'+   

	 '<td>'+isnull(hobtid,'')+'</td>'+  

	 '<td>'+isnull(dbid,'')+'</td>'+  

	 '<td>'+isnull(objectname,'')+'</td>'+  

	 '<td>'+isnull(indexname,'')+'</td>'+  

	 '<td>'+isnull(lock_id,'')+'</td>'+  

	 '<td>'+isnull(mode,'')+'</td>'+  

	 '<td>'+isnull(associatedObjectId,'')+'</td>'+  

	 '<td>'+isnull(owner_id,'')+'</td>'+  

	 '<td>'+isnull(owner_mode,'')+'</td>'+  

	 '<td>'+isnull(waiter_id,'')+'</td>'+  

	 '<td>'+isnull(waiter_mode,'')+'</td>'+  

	 '<td>'+isnull(waiter_requestType,'')+'</td>'+  

	 '</tr>'  

	 from #resource_details_keylock   

	select @body=@body+'</table><br/><br/>'   

END  

  

IF EXISTS (SELECT TOP 1 * FROM #resource_details_objectlock) 

BEGIN  

	SELECT @body=@body+'ObjectLock:<br><table border="1"> <tr>'+   

	 '<th>lockpartition,</th>'+  

	 '<th>objid,</th>'+  

	 '<th>subresource,</th>'+  

	 '<th>dbid,</th>'+  

	 '<th>objectname,</th>'+  

	 '<th>lock_id,</th>'+  

	 '<th>mode,</th>'+  

	 '<th>associatedObjectId,</th>'+  

	 '<th>owner_id,</th>'+  

	 '<th>owner_mode,</th>'+  

	 '<th>waiter_id,</th>'+  

	 '<th>waiter_mode,</th>'+  

	 '<th>waiter_requestType,</th>'+  

	 '</tr>'  

	SELECT @body=@body+'<tr>'+   

	 '<td>'+isnull(lockpartition,'')+'</td>'+  

	 '<td>'+isnull(objid,'')+'</td>'+  

	 '<td>'+isnull(subresource,'')+'</td>'+  

	 '<td>'+isnull(dbid,'')+'</td>'+  

	 '<td>'+isnull(objectname,'')+'</td>'+  

	 '<td>'+isnull(lock_id,'')+'</td>'+  

	 '<td>'+isnull(mode,'')+'</td>'+  

	 '<td>'+isnull(associatedObjectId,'')+'</td>'+  

	 '<td>'+isnull(owner_id,'')+'</td>'+  

	 '<td>'+isnull(owner_mode,'')+'</td>'+  

	 '<td>'+isnull(waiter_id,'')+'</td>'+  

	 '<td>'+isnull(waiter_mode,'')+'</td>'+  

	 '<td>'+isnull(waiter_requestType,'')+'</td>'+  

	 '</tr>'  

	FROM #resource_details_objectlock   

	SELECT @body=@body+'</table><br/><br/>'   

END  

  

IF EXISTS (SELECT TOP 1 * FROM #resource_details_databaselock) 

BEGIN  



	SELECT @body=@body+'DatabaseLock:<br><table border="1"> <tr>'+   

	 '<th>subresource,</th>'+  

	 '<th>dbid,</th>'+  

	 '<th>dbname,</th>'+  

	 '<th>lock_id,</th>'+  

	 '<th>mode,</th>'+  

	 '<th>owner_id,</th>'+  

	 '<th>owner_mode,</th>'+  

	 '<th>waiter_id,</th>'+  

	 '<th>waiter_mode,</th>'+  

	 '<th>waiter_requestType,</th>'+  

	 '</tr>'  

	SELECT @body=@body+'<tr>'+   

	 '<td>'+isnull(subresource,'')+'</td>'+  

	 '<td>'+isnull(dbid,'')+'</td>'+  

	 '<td>'+isnull(dbname,'')+'</td>'+  

	 '<td>'+isnull(lock_id,'')+'</td>'+  

	 '<td>'+isnull(mode,'')+'</td>'+  

	 '<td>'+isnull(owner_id,'')+'</td>'+  

	 '<td>'+isnull(owner_mode,'')+'</td>'+  

	 '<td>'+isnull(waiter_id,'')+'</td>'+  

	 '<td>'+isnull(waiter_mode,'')+'</td>'+  

	 '<td>'+isnull(waiter_requestType,'')+'</td>'+  

	 '</tr>'  

	from #resource_details_databaselock   

	select @body=@body+'</table><br/><br/>'   

END  

  

IF EXISTS (SELECT TOP 1 * FROM #resource_details_exchangeEvent) 

BEGIN  

	SELECT @body=@body+'ExchangeEvent:<br><table border="1"> <tr>'+   

	 '<th>lock_id,</th>'+  

	 '<th>waitType,</th>'+  

	 '<th>nodeId,</th>'+  

	 '<th>owner_id,</th>'+  

	 '<th>owner_mode,</th>'+  

	 '<th>waiter_id,</th>'+  

	 '<th>waiter_mode,</th>'+  

	 '<th>waiter_requestType,</th>'+  

	 '</tr>'  

	SELECT @body=@body+'<tr>'+   

	 '<td>'+isnull(id,'')+'</td>'+  

	 '<td>'+isnull(waitType,'')+'</td>'+  

	 '<td>'+isnull(nodeId,'')+'</td>'+  

	 '<td>'+isnull(owner_id,'')+'</td>'+  

	 '<td>'+isnull(owner_mode,'')+'</td>'+  

	 '<td>'+isnull(waiter_id,'')+'</td>'+  

	 '<td>'+isnull(waiter_mode,'')+'</td>'+  

	 '<td>'+isnull(waiter_requestType,'')+'</td>'+  

	 '</tr>'  

	FROM #resource_details_exchangeEvent   

	SELECT @body=@body+'</table><br/><br/>'   

END  

  

IF EXISTS (SELECT TOP 1 *  FROM #resource_details_metadatalock) 

BEGIN  

	SELECT @body=@body+'MetadataLock:<br><table border="1"> <tr>'+   

	'<th>subresource,</th>'+  

	'<th>classid,</th>'+  

	'<th>dbid,</th>'+  

	'<th>dbname,</th>'+  

	'<th>lock_id,</th>'+  

	'<th>mode,</th>'+  

	'<th>owner_id,</th>'+  

	'<th>owner_mode,</th>'+  

	'<th>waiter_id,</th>'+  

	'<th>waiter_mode,</th>'+  

	'<th>waiter_requestType,</th>'+  

	 '</tr>'  

	SELECT @body=@body+'<tr>'+   

	 '<td>'+isnull(subresource,'')+'</td>'+  

	 '<td>'+isnull(classid,'')+'</td>'+  

	 '<td>'+isnull(dbid,'')+'</td>'+  

	 '<td>'+isnull(dbname,'')+'</td>'+  

	 '<td>'+isnull(lock_id,'')+'</td>'+  

	 '<td>'+isnull(mode,'')+'</td>'+  

	 '<td>'+isnull(owner_id,'')+'</td>'+  

	 '<td>'+isnull(owner_mode,'')+'</td>'+  

	 '<td>'+isnull(waiter_id,'')+'</td>'+  

	 '<td>'+isnull(waiter_mode,'')+'</td>'+  

	 '<td>'+isnull(waiter_requestType,'')+'</td>'+  

	 '</tr>'  

	FROM #resource_details_metadatalock   

	SELECT @body=@body+'</table><br/><br/>'   

END  

  

IF EXISTS (SELECT TOP 1 * FROM #resource_details_pagelock) 

BEGIN  

	SELECT @body=@body+'PageLock:<br><table border="1"> <tr>'+   

	 '<th>fileid,</th>'+  

	 '<th>pageid,</th>'+  

	 '<th>dbid,</th>'+  

	 '<th>dbname,</th>'+  

	 '<th>objectname,</th>'+  

	 '<th>lock_id,</th>'+  

	 '<th>mode,</th>'+  

	 '<th>associatedObjectId,</th>'+  

	 '<th>owner_id,</th>'+  

	 '<th>owner_mode,</th>'+  

	 '<th>waiter_id,</th>'+  

	 '<th>waiter_mode,</th>'+  

	 '<th>waiter_requestType,</th>'+  

	 '</tr>'  

	SELECT @body=@body+'<tr>'+   

	 '<td>'+isnull(fileid,'')+'</td>'+  

	 '<td>'+isnull(pageid,'')+'</td>'+  

	 '<td>'+isnull(dbid,'')+'</td>'+  

	 '<td>'+isnull(dbname,'')+'</td>'+  

	 '<td>'+isnull(objectname,'')+'</td>'+  

	 '<td>'+isnull(lock_id,'')+'</td>'+  

	 '<td>'+isnull(mode,'')+'</td>'+  

	 '<td>'+isnull(associatedObjectId,'')+'</td>'+  

	 '<td>'+isnull(owner_id,'')+'</td>'+  

	 '<td>'+isnull(owner_mode,'')+'</td>'+  

	 '<td>'+isnull(waiter_id,'')+'</td>'+  

	 '<td>'+isnull(waiter_mode,'')+'</td>'+  

	 '<td>'+isnull(waiter_requestType,'')+'</td>'+  

	 '</tr>'  

	FROM #resource_details_pagelock   

	SELECT @body=@body+'</table><br/><br/>'  

END   

  

IF EXISTS (SELECT TOP 1 *  FROM #resource_details_ridlock) 

BEGIN  

	SELECT @body=@body+'RidLock:<br><table border="1"> <tr>'+   

	 '<th>pageid,</th>'+  

	 '<th>dbid,</th>'+  

	 '<th>dbname,</th>'+  

	 '<th>objectname,</th>'+  

	 '<th>lock_id,</th>'+  

	 '<th>mode,</th>'+  

	 '<th>associatedObjectId,</th>'+  

	 '<th>owner_id,</th>'+  

	 '<th>owner_mode,</th>'+  

	 '<th>waiter_id,</th>'+  

	 '<th>waiter_mode,</th>'+  

	 '<th>waiter_requestType,</th>'+  

	 '</tr>'  

	SELECT @body=@body+'<tr>'+   

	 '<td>'+isnull(pageid,'')+'</td>'+  

	 '<td>'+isnull(dbid,'')+'</td>'+  

	 '<td>'+isnull(dbname,'')+'</td>'+  

	 '<td>'+isnull(objectname,'')+'</td>'+  

	 '<td>'+isnull(lock_id,'')+'</td>'+  

	 '<td>'+isnull(mode,'')+'</td>'+  

	 '<td>'+isnull(associatedObjectId,'')+'</td>'+  

	 '<td>'+isnull(owner_id,'')+'</td>'+  

	 '<td>'+isnull(owner_mode,'')+'</td>'+  

	 '<td>'+isnull(waiter_id,'')+'</td>'+  

	 '<td>'+isnull(waiter_mode,'')+'</td>'+  

	 '<td>'+isnull(waiter_requestType,'')+'</td>'+  

	 '</tr>'  

	FROM #resource_details_ridlock   

	SELECT @body=@body+'</table><br/><br/>'  

END  

  

  

  

SELECT @body=@body+'<table border="1"><tr><th>Original XML</th></tr><tr><td>'+  

     replace( replace( convert(VARCHAR(MAX),@xml),  '<','&lt;' ),  '>','&gt;' )+  

    '</td></tr></table>'  

  

DECLARE @email_distribution_list VARCHAR(1024)  

SELECT @email_distribution_list = 'abandaru@analyticsintell.com;vijaynalabolu@analyticsintell.com'

  

EXEC msdb.dbo.sp_send_dbmail  

    @profile_name = 'sqlmail',  ---keep the profile name

    @recipients=@email_distribution_list,

    @body = @body,  

    @body_format='HTML',  

    @subject = 'Alert! DeadLock Occured On Server',  

    @importance = 'Normal' ;  

  

DROP TABLE #victim_list  

DROP TABLE #processdetails  

DROP TABLE #frame_details  

DROP TABLE #frame_values  

DROP TABLE #input_buffer  

DROP TABLE #resource_details_databaselock  

DROP TABLE #resource_details_exchangeEvent  

DROP TABLE #resource_details_keylock  

DROP TABLE #resource_details_metadatalock  

DROP TABLE #resource_details_objectlock  

DROP TABLE #resource_details_pagelock  

DROP TABLE #resource_details_ridlock  

DROP TABLE #p_details_temp  

  

  

END




