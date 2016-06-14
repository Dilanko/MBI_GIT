SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[RegExReplaceX](@Pattern [nvarchar](4000), @Input [nvarchar](max), @Repacement [nvarchar](max), @Options [int])
RETURNS [nvarchar](max) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [RegexFunction].[SimpleTalk.Phil.Factor.RegularExpressionFunctions].[RegExReplacex]
GO
