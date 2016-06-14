SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[RegExIndex](@Pattern [nvarchar](4000), @Input [nvarchar](max), @Options [int])
RETURNS [int] WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [RegexFunction].[SimpleTalk.Phil.Factor.RegularExpressionFunctions].[RegExIndex]
GO
