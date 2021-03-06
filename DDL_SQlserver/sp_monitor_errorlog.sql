SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[sp_monitor_errorlog] (@target_server nvarchar(128))
as
declare @sql nvarchar(4000)
declare @start varchar(30) 
DECLARE @rows_inserted INT = 0

BEGIN TRY

	-- Obtain errorlog entries created since the last polling cycle.
	delete from errorlog_hold where server_name = @target_server
	-- add one second to previous errorlog bookmark datetime to ensure we are examining new errorlog entries.
	set @start = (select convert(varchar(30),dateadd(ss,1,last_timestamp), 109) from errorlog_bookmark where server_name = @target_server)
	set  @sql = 'insert into errorlog_hold select *, ''' + @target_server + ''' from openquery(' + @target_server + ',''set fmtonly off exec xp_readerrorlog 0, 1, null , null, ''''' + @start + ''''',''''9999-01-01'''''')'
	exec (@sql)

	SELECT @rows_inserted = @@rowcount

	-- Make accounting entries based on what was collected.
	IF ( @rows_inserted > 0 )
		update errorlog_bookmark
			set last_timestamp =
				(select max(LogDate) from errorlog_hold where server_name = @target_server),
			local_time = getdate()
			where server_name = @target_server
	ELSE
		BEGIN
			update errorlog_bookmark
				set local_time = getdate()
			where server_name = @target_server

			RETURN
		END

	-- For BACKUP failures, if a RESTORE is currently being done on the same database reporting failures, 
	-- ignore the errorlog alerts.
	if exists (
		SELECT 1 
		FROM   errorlog_hold err 
			   INNER JOIN active_query_vw actv 
					   ON actv.server_name = err.server_name 
						  AND dbo.Regexmatch('(?<=RESTORE DATABASE.)\w+', actv.sql_text, 1) = dbo.Regexmatch('(?<=^BACKUP failed.*)\w+(?=\.)', err.[Text], 1) 
		WHERE  err.server_name = @target_server 
			   AND err.text LIKE 'BACKUP failed%' 
			   AND actv.collection_time = (SELECT Max(collection_time) 
										   FROM   active_query_vw 
										   WHERE  server_name = @target_server) 
			   AND actv.sql_text LIKE 'RESTORE DATABASE%' 
		)
			RETURN

	-- for any errorlog line containing an alertable string, 
	-- return all the log entries for that LogDate/ProcessInfo combination.
	select data.*
	from errorlog_hold data
	join 
	(
		select distinct LogDate, ProcessInfo, server_name
		from errorlog_hold
		where
		server_name = @target_server
		and logdate > @start
		and 
		(
			((UPPER(Text) like '%SEVERITY: 1[6-9]%' or UPPER(Text) like '%SEVERITY: 2[0-4]%') and text not like '%Error: 17806%')
			or UPPER(Text) like '% STACK%'
			or UPPER(Text) like '%YIELDING%'
			or UPPER(Text) like '%FATAL%'
			or UPPER(Text) like '%UNABLE%'
			or UPPER(Text) like '%MEMORY PRESSURE%'
			or UPPER(Text) like '%SQL SERVER IS TERMINATING%'
			or UPPER(Text) like '%SQL SERVER IS STARTING%'
			or UPPER(Text) like '%TIME-OUT%'
		)
	) alerts
	on alerts.LogDate = data.LogDate and alerts.ProcessInfo = data.ProcessInfo and alerts.server_name = data.server_name
	where data.LogDate > @start
	order by 1

END try

BEGIN catch
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	DECLARE @ErrorNumber INT;

    SELECT @ErrorMessage = Error_message(),
            @ErrorSeverity = Error_severity(),
            @ErrorState = Error_state(),
			@ErrorNumber = Error_Number();

    -- Use RAISERROR inside the CATCH block to propagate the error 
    -- to the calling routine.  Return error 
    -- information about the original error that caused 
    -- execution to jump to the CATCH block. 

	-- ErrorNumber 7357 simply indicates that no errorlog entries were found.
	if (@ErrorNumber <> 7357)
		RAISERROR (@ErrorMessage,-- Message text. 
				@ErrorSeverity,-- Severity. 
				@ErrorState -- State. 
				);
END catch













GO
