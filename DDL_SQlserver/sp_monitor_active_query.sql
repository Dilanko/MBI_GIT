SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_monitor_active_query] (@target_server nvarchar(128), @run_mode char(10) = 'normal', @current_collection datetime2 = null)
AS
DECLARE @threshold_blocking int,
    @threshold_lr_sql   int,
    @threshold_lr_xact  INT,
	@rows_inserted INT = 0,
	@sql nvarchar(4000)

if (@run_mode = 'normal')
	exec sp_get_thresholds @target_server, @threshold_lr_sql output, @threshold_lr_xact output, @threshold_blocking output
else
	BEGIN
	set @threshold_blocking = 1
	set @threshold_lr_sql = 1
	set @threshold_lr_xact = 1
	END


BEGIN try

	if (@run_mode = 'normal')
		BEGIN
			-- load active_query table with fresh data  

			exec (@target_server + '.dba_config.dbo.sp_whoisactive_to_table')

  			set @sql = '
				insert into active_query_vw
				select
					collection_time, server_name, session_id, sql_text, sql_command, login_name, 
					substring(wait_info, (charindex('')'',wait_info))+1, len(wait_info)) as wait_type,
					substring(wait_info, 2,(charindex(''ms)'',wait_info))-2) / 1000 as wait_time,
					cpu, tempdb_allocations, tempdb_current, blocking_session_id, reads, writes, physical_reads, used_memory, status,
					open_tran_count, percent_complete, host_name, database_name, program_name, start_time, login_time, request_id
				from openquery(' + @target_server + 
					',''select CONVERT(NVARCHAR(128),serverproperty(''''instancename'''')) AS server_name, * from dba_config.dbo.whoisactive'')'
			exec (@sql)
		END
	
	if (@current_collection is null OR @run_mode = 'normal')
			SET @current_collection = (SELECT Max(collection_time)
				FROM   active_query_raw where server_name = @target_server)

    DECLARE @previous_collection DATETIME2 = (SELECT Max(collection_time)
       FROM   active_query_raw
       WHERE  server_name = @target_server and collection_time < @current_collection)

    -- cleanup various utility tables once per day.
    IF ( Datepart(day, @previous_collection) <>
         Datepart(day, @current_collection) )
		BEGIN
		  DELETE FROM active_query_vw
		  WHERE  server_name = @target_server and Datediff(dd, collection_time, CURRENT_TIMESTAMP) > 30

		  DELETE FROM active_query_stats
		  WHERE  server_name = @target_server and Datediff(dd, collection_time, CURRENT_TIMESTAMP) > 30

		  DELETE FROM cycle_log
		  WHERE  target_server = @target_server and Datediff(dd, run_timestamp, CURRENT_TIMESTAMP) > 1
		END

    -- insert keys into #active_query_alertable that identify the 3 possible situations involving active alert conditions.
	-- A table-valued function will be used to encapsulate threshold handling conditions.

    SELECT 'CONTINUING' AS alert_status, 3 as alert_sort,
           *
	INTO #active_query_alertable
    FROM   Active_query_alert(@target_server, @current_collection, @threshold_blocking,
           @threshold_lr_sql,
                  @threshold_lr_xact) cur
    WHERE  EXISTS (SELECT *
                   FROM   Active_query_alert(@target_server, @previous_collection,
                          @threshold_blocking,
                          @threshold_lr_sql,
                                  @threshold_lr_xact) prev
                   WHERE cur.session_id = prev.session_id)
    UNION ALL
    SELECT 'NEW' AS alert_status, 1,
           *
    FROM   Active_query_alert(@target_server, @current_collection, @threshold_blocking,
           @threshold_lr_sql,
                  @threshold_lr_xact) cur
    WHERE  NOT EXISTS (SELECT *
                       FROM   Active_query_alert(@target_server, @previous_collection,
                              @threshold_blocking,
                              @threshold_lr_sql,
                                      @threshold_lr_xact) prev
                       WHERE cur.session_id = prev.session_id)
    UNION ALL
    SELECT 'CLEARED' AS alert_status, 2,
           *
    FROM   Active_query_alert(@target_server, @previous_collection, @threshold_blocking,
           @threshold_lr_sql,
                  @threshold_lr_xact) prev
    WHERE  NOT EXISTS (SELECT *
                       FROM   Active_query_alert(@target_server, @current_collection,
                              @threshold_blocking,
                              @threshold_lr_sql,
                                      @threshold_lr_xact) cur
                       WHERE cur.session_id = prev.session_id)

	-- sum the alert_type column to identify those situations where a given session may
	-- have triggered more than one alert.  We will report back only a single row but 
	-- need to show all the possible alert conditions that may be involved.

	select collection_time, server_name, session_id, alert_status, alert_sort, sum(alert_type) as alert_types
	into #active_query_with_alerts
	from #active_query_alertable
	group by collection_time, server_name, session_id, alert_status, alert_sort

	if (@run_mode = 'normal')
	BEGIN

		declare @session_id smallint

		-- For any alertable SQL, collect relevant info from sys.dm_exec_query_stats

		set @SQL = 'insert into active_query_stats select ''' + convert(varchar,@current_collection) + ''', ''' + @target_server + ''', * from openquery(' +
					@target_server + 
					',''select
					session_id
					,q.query_hash
					,q.query_plan_hash
					,q.plan_generation_num
					,q.creation_time
					,q.last_execution_time
					,q.execution_count
					,q.total_physical_reads
					,q.min_physical_reads
					,q.max_physical_reads
					,q.total_logical_writes
					,q.min_logical_writes
					,q.max_logical_writes
					,q.total_logical_reads
					,q.min_logical_reads
					,q.max_logical_reads
					,q.total_elapsed_time
					,q.min_elapsed_time
					,q.max_elapsed_time
					,q.total_rows
					,q.min_rows
					,q.max_rows
				from sys.dm_exec_requests r
				join sys.dm_exec_query_stats q 
					on r.sql_handle = q.sql_handle and r.statement_start_offset = q.statement_start_offset and r.statement_end_offset = q.statement_end_offset and r.plan_handle = q.plan_handle
				'')	
					where session_id in (
						select session_id
						from #active_query_with_alerts
					)
				'
			exec (@SQL)

		-- For NEW Long Running SQL and/or Xact, capture XML query plan.
	
		declare active_new_plan_csr cursor
		for
		select session_id
		from #active_query_with_alerts
		where alert_types <> 4 -- exclude alerts involved with blocking only
			and alert_status = 'NEW'

		open active_new_plan_csr

		fetch from active_new_plan_csr
			into @session_id

		WHILE @@fetch_status = 0
		BEGIN

			set @SQL = 'insert into sql_plan_insert_vw select ''' + convert(varchar,@current_collection) + ''', ''' + @target_server + ''', session_id, convert(xml, query_plan) from openquery(' +
					@target_server + ',''select session_id, query_plan from sys.dm_exec_requests
				cross apply sys.dm_exec_text_query_plan(plan_handle, statement_start_offset, statement_end_offset)
				where session_id = ' + convert(varchar(10), @session_id) + ''')'
			exec (@SQL)

			FETCH NEXT FROM active_new_plan_csr
				into @session_id
		END

		close active_new_plan_csr
	
	END

	-- Perform the final join that includes all necessary columns along with a conversion
	-- of the numeric alert_types column into text.
	 SELECT ma.alert_status, ma.alert_sort,
		   CASE ma.alert_types
			 WHEN 1 THEN 'Long Running SQL'
			 WHEN 2 THEN 'Long Running Xact'
			 WHEN 3 THEN 'Long Running SQL/Xact'
			 WHEN 4 THEN 'Blocked'
			 WHEN 5 THEN 'Long Running SQL/Blocked'
			 WHEN 6 THEN 'Long Running Xact/Blocked'
			 WHEN 7 THEN 'Long Running SQL/Xact/Blocked'
			 ELSE 'Unknown'
		   END AS alert_types,
		   a.*
	INTO #core_data
	FROM   #active_query_with_alerts ma
		   JOIN active_query_vw a
			 ON a.session_id = ma.session_id
				AND a.collection_time = ma.collection_time
				AND a.server_name = ma.server_name
	UNION
	-- this part will be have data when blocking is identified.
	-- the "lead blocker" will be returned in the result set.
	SELECT 'BLOCKING INFO' as alert_status, 0, 
		'Lead Blocker' as alert_types,
		* 
	FROM   active_query_vw 
	WHERE  server_name = @target_server
			AND collection_time = @current_collection
			AND blocking_session_id IS NULL 
			AND session_id IN (SELECT DISTINCT av.blocking_session_id 
								FROM   #active_query_with_alerts aq 
										JOIN active_query_vw av 
										ON av.session_id = aq.session_id 
											AND av.collection_time = 
												aq.collection_time 
											AND aq.server_name = av.server_name 
								WHERE  aq.alert_types >= 4) 

	SELECT c.*, 
		creation_time, last_execution_time, execution_count, 
		min_elapsed_time/1000 as min_elapsed_time, total_elapsed_time/1000/execution_count as avg_elapsed_time, max_elapsed_time/1000 as max_elapsed_time,
		min_logical_reads, total_logical_reads/execution_count as avg_logical_reads, max_logical_reads,
		min_physical_reads, total_physical_reads/execution_count as avg_physical_reads, max_physical_reads,
		min_rows, total_rows/execution_count as avg_rows, max_rows
	FROM #core_data c
	LEFT OUTER JOIN active_query_stats a ON c.session_id = a.session_id and c.server_name = a.server_name and c.collection_time = a.collection_time and a.execution_count > 0
	ORDER  BY 2, c.session_id
	
END try

BEGIN catch
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT @ErrorMessage = Error_message(),
            @ErrorSeverity = Error_severity(),
            @ErrorState = Error_state();

    -- Use RAISERROR inside the CATCH block to propagate the error 
    -- to the calling routine.  Return error 
    -- information about the original error that caused 
    -- execution to jump to the CATCH block. 
    RAISERROR (@ErrorMessage,-- Message text. 
            @ErrorSeverity,-- Severity. 
            @ErrorState -- State. 
			);
END catch

GO
