SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[target_server](
	[server_name] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[client_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[dbms_type] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[environment] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[status] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[errorlog_polling_cycle] [smallint] NOT NULL,
	[active_query_polling_cycle] [smallint] NOT NULL,
	[last_errorlog_cycle] [datetime] NULL,
	[last_active_query_cycle] [datetime] NULL
) ON [PRIMARY]

GO
