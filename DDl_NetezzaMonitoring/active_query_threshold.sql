SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[active_query_threshold](
	[sqltext] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[threshold] [smallint] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
