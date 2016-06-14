SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[RegExSplit](@Pattern [nvarchar](4000), @Input [nvarchar](max), @Options [int])
RETURNS  TABLE (
	[Match] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [RegexFunction].[SimpleTalk.Phil.Factor.RegularExpressionFunctions].[RegExSplit]
GO
