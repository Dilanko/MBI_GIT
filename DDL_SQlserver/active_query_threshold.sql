SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[active_query_threshold](
	[sql_text] [varchar](100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[threshold] [int] NOT NULL,
	[comment] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
