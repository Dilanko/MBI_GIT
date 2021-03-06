SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 CREATE FUNCTION [dbo].[active_query_alert] (@target_server nvarchar(128),
											@collection_time    DATETIME,
                                           @threshold_blocking INT,
                                           @threshold_lr_sql   INT,
                                           @threshold_lr_xact  INT)
returns TABLE
AS
    RETURN
      (
      -- check SQL by comparing current runtimes against either
      -- (1) the custom threshold setup for this particular query or
      -- (2) the general sql execution threshold.

	  -- long-running SQL
      SELECT 1 as alert_type, session_id, collection_time, server_name
       FROM   active_query_vw a
       WHERE  server_name = @target_server and collection_time = @collection_time
			and start_time >= login_time -- condition should always be true but instances have been encountered where it is not (apparrent bug)
			and start_time >= (SELECT sqlserver_start_time FROM sys.dm_os_sys_info) -- another bug condition to avoid
			 and status <> 'dormant'
             AND ( EXISTS (SELECT *
                            FROM   active_query_threshold t
                            WHERE  upper(Replace(a.sql_text, '''', '')) LIKE  upper(t.sql_text)
                                   AND datediff(mi,start_time, collection_time) > t.threshold)
                     OR ( NOT EXISTS (SELECT *
                                      FROM   active_query_threshold t
                                      WHERE  upper(Replace(a.sql_text, '''', '')) LIKE  upper(t.sql_text))
                          AND datediff(mi,start_time, collection_time) > @threshold_lr_sql)
                  )
      UNION -- blocking
      SELECT 4,  session_id, collection_time, server_name
      FROM   active_query_vw a
      WHERE  server_name = @target_server and collection_time = @collection_time
             AND blocking_session_id > 0
             AND (wait_time / 60) >= @threshold_blocking
      UNION -- long-running transactions
      SELECT 2,  session_id, collection_time, server_name
      FROM   active_query_vw a
      WHERE  server_name = @target_server and collection_time = @collection_time
	  		and start_time >= login_time -- condition should never be true but instances have been encountered where it is not (apparrent bug)
			and start_time >= (SELECT sqlserver_start_time FROM sys.dm_os_sys_info) -- another bug condition to avoid
             AND open_tran_count > 0
              AND ( EXISTS (SELECT *
                            FROM   active_query_threshold t
                            WHERE  upper(Replace(a.sql_text, '''', '')) LIKE  upper(t.sql_text)
                            AND datediff(mi,start_time, collection_time) > t.threshold)
                     OR ( NOT EXISTS (SELECT *
                                      FROM   active_query_threshold t
                                      WHERE  upper(Replace(a.sql_command, '''', '')) LIKE  upper(t.sql_text))
                          AND datediff(mi,start_time, collection_time) > @threshold_lr_xact)
                  ))




















GO
