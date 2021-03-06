SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[calendar](
	[dt] [char](16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[dh] [char](13) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[date_only] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[yy] [int] NULL,
	[mm] [int] NULL,
	[dd] [int] NULL,
	[hh] [int] NULL,
	[mi] [int] NULL
) ON [PRIMARY]

GO
