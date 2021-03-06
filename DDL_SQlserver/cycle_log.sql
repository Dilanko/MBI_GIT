SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[cycle_log](
	[run_timestamp] [datetime2](0) NOT NULL,
	[target_server] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[alert_type] [varchar](100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[alert_status] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[log_text] [varchar](1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [cycle_log_pk] PRIMARY KEY CLUSTERED 
(
	[run_timestamp] DESC,
	[target_server] ASC,
	[alert_type] ASC,
	[alert_status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
