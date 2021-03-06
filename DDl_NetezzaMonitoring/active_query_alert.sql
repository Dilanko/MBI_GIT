SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[active_query_alert] (@collection_time  DATETIME, 
                                           @lr_sql_threshold TINYINT,
										   @tgt_server varchar(50)) 
returns TABLE 
AS 
    RETURN 
    ( 
		-- check for long SQL by comparing current runtimes against either 
		-- (1) the custom threshold setup for this particular query or 
		-- (2) the general sql execution threshold. 
		--		2.a if result rows less 1MM, use normal threshold
		--		2.b if results rows greater than/equal to 1MM, double the normal threshold
      SELECT * 
       FROM   active_query a 
       WHERE  collection_time = @collection_time and servername = @tgt_server
              AND ( EXISTS (SELECT * 
                            FROM   active_query_threshold t 
                            WHERE  Upper(Replace(a.sqltext, '''', '')) LIKE 
                                   Upper(t.sqltext) 
                                   AND Datediff(mi, submit_time, collection_time 
                                       ) > 
                                       t.threshold) 
                     OR
					( NOT EXISTS (SELECT * 
                                      FROM   active_query_threshold t 
                                      WHERE  Upper(Replace(a.sqltext, '''', '')) 
                                             LIKE 
                                             Upper(t.sqltext)) 
                     AND ( 	(Datediff(mi, submit_time, collection_time) > 
                              @lr_sql_threshold 
							AND resrows < 1000000)
						  OR 
						  (Datediff(mi, submit_time, collection_time) > 
                              (2 * @lr_sql_threshold )
							AND resrows >= 1000000)
						  )
					) 
						
                  )
	) 



GO
