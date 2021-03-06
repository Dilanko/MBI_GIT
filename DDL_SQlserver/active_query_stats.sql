SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[active_query_stats](
	[collection_time] [datetime2](0) NOT NULL,
	[server_name] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[session_id] [smallint] NOT NULL,
	[query_hash] [binary](8) NOT NULL,
	[query_plan_hash] [binary](8) NOT NULL,
	[plan_generation_num] [bigint] NOT NULL,
	[creation_time] [datetime2](0) NOT NULL,
	[last_execution_time] [datetime2](0) NOT NULL,
	[execution_count] [bigint] NOT NULL,
	[total_physical_reads] [bigint] NOT NULL,
	[min_physical_reads] [bigint] NOT NULL,
	[max_physical_reads] [bigint] NOT NULL,
	[total_logical_writes] [bigint] NOT NULL,
	[min_logical_writes] [bigint] NOT NULL,
	[max_logical_writes] [bigint] NOT NULL,
	[total_logical_reads] [bigint] NOT NULL,
	[min_logical_reads] [bigint] NOT NULL,
	[max_logical_reads] [bigint] NOT NULL,
	[total_elapsed_time] [bigint] NOT NULL,
	[min_elapsed_time] [bigint] NOT NULL,
	[max_elapsed_time] [bigint] NOT NULL,
	[total_rows] [bigint] NOT NULL,
	[min_rows] [bigint] NOT NULL,
	[max_rows] [bigint] NOT NULL,
 CONSTRAINT [active_query_stats_pk] PRIMARY KEY CLUSTERED 
(
	[collection_time] ASC,
	[server_name] ASC,
	[session_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
