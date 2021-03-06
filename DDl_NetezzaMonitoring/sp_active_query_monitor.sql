SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_active_query_monitor] (@target_server varchar(100), @lr_sql_threshold TINYINT) 
AS 
    DECLARE @rows_inserted INT = 0 
	DECLARE @tgt_linked_server varchar(100)
	DECLARE @SQL varchar(max)
	DECLARE @tgt_host varchar(100)

  -- load active_query table with fresh data  
  if ( @target_server = 'ProdStriper' )
	set @tgt_linked_server = 'prodstriper_oledb'
  else if @target_server = 'DevStriper'
  	set @tgt_linked_server = 'devstriper_oledb'
  else
	BEGIN
	RAISERROR (N'Unknown target server specified: %s', 10, 1, @target_server);
	return -1
	END

  BEGIN try 
	set @sql = '
      INSERT INTO active_query 
      SELECT *, ''' + @target_server + '''
      FROM   Openquery(' + @tgt_linked_server + ', ''  
		  SELECT Now() AS collection_time, 
		   qs_tsubmit, 
		   session_id, 
		   session_username, 
		   dbname, 
		   resource_group, 
		   qs_planid, 
		   qs_sql, 
		   Char_length(qs_sql) AS sql_length, 
		   qs_estcost, 
		   qs_estdisk, 
		   qs_estmem, 
		   qs_resrows, 
		   qs_resbytes , 
		   ( 
				  SELECT val 
				  FROM   _t_environ 
				  WHERE  NAME = ''''HOSTNAME'''') AS hostname 
			FROM   _v_session_detail sd 
			JOIN   _v_qrystat qs 
			ON     sd.session_id = qs_sessionid  
		'')'
		exec (@sql)

      --at least one row must exist in active_query to represent the polling cycle.  Insert a stub row if no other rows have been inserted.  
      SELECT @rows_inserted = @@rowcount 

      IF ( @rows_inserted = 0 ) 
        BEGIN 
			set @sql = '
            INSERT INTO active_query
                        (collection_time, 
                         session_id, 
                         hostname,
						 servername) 
            SELECT * , ''' + @target_server + '''
            FROM   Openquery(' + @tgt_linked_server + ', ''
			 SELECT Now() AS collection_time,
			      0,
				  (select val from _t_environ where name = ''''HOSTNAME'''') as hostname
			  '')'
			exec (@sql)
		END 

    DECLARE @current_collection DATETIME2 = (SELECT Max(collection_time)  FROM   active_query WHERE servername = @target_server) 
    DECLARE @previous_collection DATETIME2 = (SELECT Max(collection_time) FROM   active_query 
												WHERE  collection_time < @current_collection
													AND servername = @target_server) 

    -- cleanup active_query once per day by removing rows older than one week.   
    IF ( Datepart(day, @previous_collection) <> 
         Datepart(day, @current_collection) ) 
      DELETE FROM active_query 
      WHERE  Datediff(wk, collection_time, CURRENT_TIMESTAMP) > 1 and servername = @target_server 

    -- return rows identifying the 3 possible situations involving active alert conditions. A table-valued function
	-- will be used to encapsulate threshold handling conditions.
    SELECT 'CONTINUING'                               AS alert_status, 
           Datediff(mi, submit_time, collection_time) duration_min, 
           username, 
		   (select email from login_detail ld where cur.username = ld.username and servername = @target_server) as email,
           Substring(sqltext, 1, 1000)                 AS sql, 
           dbname, 
           submit_time, 
           session_id, 
           planid, 
           estcost, 
           estdisk, 
           estmem, 
           resrows, 
           resbytes, 
           collection_time, 
           hostname 
    FROM   Active_query_alert(@current_collection, @lr_sql_threshold, @target_server) cur 
    WHERE  EXISTS (SELECT * 
                   FROM   Active_query_alert(@previous_collection, @lr_sql_threshold, @target_server) prev 
                   WHERE  cur.session_id = prev.session_id 
                          AND cur.hostname = prev.hostname) 
    UNION ALL 
    SELECT 'NEW', 
           Datediff(mi, submit_time, collection_time) duration_min, 
           username, 
		   (select email from login_detail ld where cur.username = ld.username and servername = @target_server) as email,
           Substring(sqltext, 1, 1000), 
           dbname, 
           submit_time, 
           session_id, 
           planid, 
           estcost, 
           estdisk, 
           estmem, 
           resrows, 
           resbytes, 
           collection_time, 
           hostname 
    FROM   Active_query_alert(@current_collection, @lr_sql_threshold, @target_server) cur 
    WHERE  NOT EXISTS (SELECT * 
                       FROM   Active_query_alert(@previous_collection, @lr_sql_threshold, @target_server) prev 
                       WHERE  cur.session_id = prev.session_id 
                              AND cur.hostname = prev.hostname) 
    UNION ALL 
    SELECT 'CLEARED', 
           Datediff(mi, submit_time, collection_time) duration_min, 
           username, 
		   (select email from login_detail ld where prev.username = ld.username and servername = @target_server) as email,
           Substring(sqltext, 1, 1000), 
           dbname, 
           submit_time, 
           session_id, 
           planid, 
           estcost, 
           estdisk, 
           estmem, 
           resrows, 
           resbytes, 
           collection_time, 
           hostname 
    FROM   Active_query_alert(@previous_collection, @lr_sql_threshold, @target_server) prev 
    WHERE  NOT EXISTS (SELECT * 
                       FROM   Active_query_alert(@current_collection, @lr_sql_threshold, @target_server) cur 
                       WHERE  cur.session_id = prev.session_id 
                              AND cur.hostname = prev.hostname) 
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
