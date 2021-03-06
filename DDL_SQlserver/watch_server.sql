SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE view [dbo].[watch_server]
as
SELECT
  	  collection_time
      ,[server_name]
	  ,[session_id]
		,concat(
			datediff(ss,start_time,collection_time) / 86400,
			':',
			(datediff(ss,start_time,collection_time) / 3600) % 24,
			':',
			(datediff(ss,start_time,collection_time) / 60)  % 60,
			 ':',
			 datediff(ss,start_time,collection_time) % 60
		 ) as duration
      ,[database_name]
      ,[program_name]
      ,[login_name]
      ,st1.sql_text as sql_text
      ,[wait_type]
      ,[wait_time]
      ,[blocking_session_id]
      ,[reads]
      ,[writes]
      ,[physical_reads]
      ,[status]
      ,[open_tran_count]
      ,[host_name]
      ,[start_time]
      ,[login_time]
      ,[request_id]
      ,[cpu]
      ,[tempdb_allocations]
      ,[tempdb_current]
      ,[used_memory]
      ,st2.sql_text as sql_command
      ,[percent_complete]
	  ,plan_xml
  FROM [dbo].[active_query_raw] a
  left outer join sql_text st1 on st1.sql_hash = a.sql_text_hash
  left outer join sql_text st2 on st2.sql_hash = a.sql_command_hash
  left outer join sql_plan sp on sp.plan_hash = a.plan_hash













GO
