SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[errorlog_bookmark](
	[server_name] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[last_timestamp] [datetime2](0) NOT NULL,
	[local_time] [datetime2](0) NULL
) ON [PRIMARY]

GO
