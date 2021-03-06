SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE view [dbo].[active_query_vw] as

SELECT
		[collection_time]
      ,[server_name]
      ,[session_id]
      ,st1.sql_text as sql_text
      ,st2.sql_text as sql_command
      ,[login_name]
      ,[wait_type]
      ,[wait_time]
      ,[cpu]
      ,[tempdb_allocations]
      ,[tempdb_current]
      ,[blocking_session_id]
      ,[reads]
      ,[writes]
      ,[physical_reads]
      ,[used_memory]
      ,[status]
      ,[open_tran_count]
      ,[percent_complete]
      ,[host_name]
      ,[database_name]
      ,[program_name]
      ,[start_time]
      ,[login_time]
      ,[request_id]
  FROM [dbo].[active_query_raw] a
  left outer join sql_text st1 on st1.sql_hash = a.sql_text_hash
  left outer join sql_text st2 on st2.sql_hash = a.sql_command_hash












GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE trigger [dbo].[IO_Trig_DEL_active_query_vw] on [dbo].[active_query_vw]
INSTEAD OF DELETE
as 
BEGIN
	delete from active_query_raw 
	where exists (select * from deleted d where d.collection_time = active_query_raw.collection_time
		and d.session_id = active_query_raw.session_id and d.server_name = active_query_raw.server_name)

	delete from sql_text
	where exists 
		(select * from deleted d where sql_text.sql_hash = dbo.fn_hashbytesMAX(d.sql_command, 'md5')
			and not exists (
				select * from active_query_raw a where a.sql_command_hash = dbo.fn_hashbytesMAX(d.sql_command, 'md5')))

	delete from sql_text
	where exists 
		(select * from deleted d where sql_text.sql_hash = dbo.fn_hashbytesMAX(d.sql_text, 'md5')
			and not exists (
				select * from active_query_raw a where a.sql_text_hash = dbo.fn_hashbytesMAX(d.sql_text, 'md5')))
END



GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE trigger [dbo].[IO_Trig_INS_active_query_vw] on [dbo].[active_query_vw]
INSTEAD OF INSERT
as
BEGIN
	insert into active_query_raw (
		[collection_time]
      ,[server_name]
      ,[session_id]
      ,[sql_text_hash]
      ,[sql_command_hash]
      ,[login_name]
      ,[wait_type]
      ,[wait_time]
      ,[cpu]
      ,[tempdb_allocations]
      ,[tempdb_current]
      ,[blocking_session_id]
      ,[reads]
      ,[writes]
      ,[physical_reads]
      ,[used_memory]
      ,[status]
      ,[open_tran_count]
      ,[percent_complete]
      ,[host_name]
      ,[database_name]
      ,[program_name]
      ,[start_time]
      ,[login_time]
      ,[request_id]
  )

SELECT [collection_time]
      ,[server_name]
      ,[session_id]
      ,dbo.Fn_hashbytesmax(sql_text, 'md5')
      ,dbo.Fn_hashbytesmax(sql_command, 'md5')
      ,[login_name]
      ,[wait_type]
      ,[wait_time]
      ,[cpu]
      ,[tempdb_allocations]
      ,[tempdb_current]
      ,[blocking_session_id]
      ,[reads]
      ,[writes]
      ,[physical_reads]
      ,[used_memory]
      ,[status]
      ,[open_tran_count]
      ,[percent_complete]
      ,[host_name]
      ,[database_name]
      ,[program_name]
      ,[start_time]
      ,[login_time]
      ,[request_id]

	from inserted

  INSERT INTO sql_text
              (sql_hash,
               sql_text)
  SELECT distinct dbo.Fn_hashbytesmax(sql_command, 'md5'),
         sql_command
  FROM   inserted i
  WHERE (sql_command is not null and sql_command <> '')
  and ( NOT EXISTS (SELECT *
                     FROM   sql_text s
                     WHERE s.sql_hash = dbo.Fn_hashbytesmax(i.sql_command,'md5')) )

  INSERT INTO sql_text
              (sql_hash,
               sql_text)
  SELECT distinct dbo.Fn_hashbytesmax(sql_text, 'md5'),
         sql_text
  FROM   inserted i
  WHERE (sql_text is not null and sql_text <> '')
  and ( NOT EXISTS (SELECT *
                     FROM   sql_text s
                     WHERE s.sql_hash = dbo.Fn_hashbytesmax(i.sql_text,'md5')) )
END









GO
