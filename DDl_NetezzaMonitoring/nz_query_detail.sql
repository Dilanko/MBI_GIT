SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[nz_query_detail](
	[session_id] [int] NULL,
	[tstart] [smalldatetime] NULL,
	[tend] [smalldatetime] NULL,
	[db] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[dt] [char](16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]

GO
