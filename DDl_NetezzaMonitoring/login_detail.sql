SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[login_detail](
	[servername] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[USERNAME] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EMAIL] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[USEAUTH] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
CREATE UNIQUE CLUSTERED INDEX [login_detail2_pk] ON [dbo].[login_detail]
(
	[servername] ASC,
	[USERNAME] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
