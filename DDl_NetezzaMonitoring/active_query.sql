SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[active_query](
	[COLLECTION_TIME] [datetime2](7) NOT NULL,
	[SUBMIT_TIME] [datetime2](7) NULL,
	[SESSION_ID] [int] NOT NULL,
	[USERNAME] [nvarchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DBNAME] [nvarchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RESOURCE_GROUP] [nvarchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PLANID] [int] NULL,
	[SQLTEXT] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SQL_LENGTH] [int] NULL,
	[ESTCOST] [bigint] NULL,
	[ESTDISK] [bigint] NULL,
	[ESTMEM] [bigint] NULL,
	[RESROWS] [bigint] NULL,
	[RESBYTES] [bigint] NULL,
	[HOSTNAME] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[servername] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
CREATE CLUSTERED INDEX [pk_active_query] ON [dbo].[active_query]
(
	[COLLECTION_TIME] ASC,
	[SESSION_ID] ASC,
	[servername] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
