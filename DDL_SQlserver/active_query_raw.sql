SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[active_query_raw](
	[collection_time] [datetime2](0) NOT NULL,
	[server_name] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[session_id] [smallint] NOT NULL,
	[sql_text_hash] [varbinary](20) NULL,
	[sql_command_hash] [varbinary](20) NULL,
	[login_name] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[wait_type] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[wait_time] [int] NULL,
	[cpu] [int] NULL,
	[tempdb_allocations] [bigint] NULL,
	[tempdb_current] [bigint] NULL,
	[blocking_session_id] [smallint] NULL,
	[reads] [bigint] NULL,
	[writes] [bigint] NULL,
	[physical_reads] [bigint] NULL,
	[used_memory] [bigint] NOT NULL,
	[status] [varchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[open_tran_count] [smallint] NULL,
	[percent_complete] [real] NULL,
	[host_name] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[database_name] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[program_name] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[start_time] [datetime2](0) NOT NULL,
	[login_time] [datetime2](0) NULL,
	[request_id] [int] NULL,
	[plan_hash] [varbinary](20) NULL,
 CONSTRAINT [whoisactive_raw_pk] PRIMARY KEY CLUSTERED 
(
	[collection_time] ASC,
	[server_name] ASC,
	[session_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create trigger [dbo].[Trig_DEL_active_query_raw]
on [dbo].[active_query_raw]
FOR DELETE
AS
	delete from sql_plan
	where exists 
		(select * from deleted d where sql_plan.plan_hash = d.plan_hash
			and not exists (
				select * from active_query_raw a where a.plan_hash = d.plan_hash))

GO
