SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[nz_query_history](
	[QH_SESSIONID] [int] NULL,
	[QH_PLANID] [int] NULL,
	[QH_CLIENTID] [int] NULL,
	[QH_CLIIPADDR] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[QH_DATABASE] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[QH_USER] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[QH_SQL] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[QH_TSUBMIT] [datetime2](7) NULL,
	[QH_TSTART] [datetime2](7) NULL,
	[QH_TEND] [datetime2](7) NULL,
	[QH_PRIORITY] [int] NULL,
	[QH_PRITXT] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[QH_ESTCOST] [bigint] NULL,
	[QH_ESTDISK] [bigint] NULL,
	[QH_ESTMEM] [bigint] NULL,
	[QH_SNIPPETS] [int] NULL,
	[QH_SNPTSDONE] [int] NULL,
	[QH_RESROWS] [bigint] NULL,
	[QH_RESBYTES] [bigint] NULL,
	[qh_sql_hash] [varbinary](20) NULL,
	[duration_minutes] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
