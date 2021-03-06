SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NZ_SYSUTIL_HISTORY](
	[ENTRY] [smalldatetime] NOT NULL,
	[HOST_CPU] [decimal](3, 2) NULL,
	[HOST_DISK] [decimal](3, 2) NULL,
	[HOST_FABRIC] [decimal](3, 2) NULL,
	[HOST_MEMORY] [decimal](3, 2) NULL,
	[SPU_CPU] [decimal](3, 2) NULL,
	[SPU_DISK] [decimal](3, 2) NULL,
	[SPU_FABRIC] [decimal](3, 2) NULL,
	[SPU_MEMORY] [decimal](3, 2) NULL,
	[MAX_SPU_CPU] [decimal](3, 2) NULL,
	[MAX_SPU_DISK] [decimal](3, 2) NULL,
	[MAX_SPU_FABRIC] [decimal](3, 2) NULL,
	[MAX_SPU_MEMORY] [decimal](3, 2) NULL,
	[SPU_TEMP_DISK] [decimal](3, 2) NULL,
	[MAX_SPU_TEMP_DISK] [decimal](3, 2) NULL,
 CONSTRAINT [pk_nz_sysutil_history] PRIMARY KEY CLUSTERED 
(
	[ENTRY] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
