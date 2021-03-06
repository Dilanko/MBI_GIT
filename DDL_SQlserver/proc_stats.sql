SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[proc_stats](
	[object_name] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[db_name] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[last_execution_time] [datetime2](7) NOT NULL,
	[plan_handle] [varbinary](64) NOT NULL,
	[server_name] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[collection_time] [datetime2](7) NOT NULL,
	[sql_handle] [varbinary](64) NOT NULL,
	[type] [char](2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[cached_time] [datetime] NULL,
	[execution_count] [bigint] NOT NULL,
	[last_worker_time] [bigint] NOT NULL,
	[last_physical_reads] [bigint] NOT NULL,
	[last_logical_writes] [bigint] NOT NULL,
	[last_logical_reads] [bigint] NOT NULL,
	[last_elapsed_time] [bigint] NOT NULL,
 CONSTRAINT [proc_stats_pk] PRIMARY KEY CLUSTERED 
(
	[object_name] ASC,
	[db_name] ASC,
	[last_execution_time] ASC,
	[plan_handle] ASC,
	[server_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
