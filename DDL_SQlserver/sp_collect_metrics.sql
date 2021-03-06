SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_collect_metrics] (@target_server nvarchar(128))
AS
DECLARE @sql nvarchar(4000), 
		@max_execution_time varchar(30),
		@previous_collection datetime2,
		@before_previous_collection datetime2


BEGIN try

	SELECT @max_execution_time = CONVERT(VARCHAR(30), 
								Dateadd(ss, 1, Isnull(Max(last_execution_time), '1/1/2000') 
								  ), 20) ,
		   @previous_collection = Isnull(max(collection_time), '1/1/2000')
	FROM   proc_stats 
	WHERE  server_name = @target_server 

	set @sql = '
	insert into proc_stats
	select *
	from openquery(' + @target_server + ',''
	SELECT 
		   Object_name(object_id, database_id)                    AS object, 
		   Db_name(database_id)                                   AS db, 
		   last_execution_time, 
		   plan_handle, 
		   ''''' + @target_server + ''''' as server,
		   Getdate()                                              AS collection_time, 
		   sql_handle, 
		   type, 
		   cached_time, 
		   execution_count, 
		   last_worker_time, 
		   last_physical_reads, 
		   last_logical_writes, 
		   last_logical_reads, 
		   last_elapsed_time
	FROM   sys.dm_exec_procedure_stats 
	WHERE  last_execution_time > ''''' + @max_execution_time + '''''
		   AND Db_name(database_id) IS NOT NULL 
		   '')'

	exec (@sql)

	set @before_previous_collection = 
	(SELECT isnull(Max(collection_time), '1/1/2000')
	FROM   proc_stats
	WHERE  server_name = @target_server and collection_time < @previous_collection)

    -- cleanup various utility tables once per day.
    IF ( Datepart(day, @previous_collection) <>
         Datepart(day, @before_previous_collection) )
		BEGIN
		  DELETE FROM proc_stats
		  WHERE  server_name = @target_server and Datediff(dd, collection_time, CURRENT_TIMESTAMP) > 30
		END
	
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
