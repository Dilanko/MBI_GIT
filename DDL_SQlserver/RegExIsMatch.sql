SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[RegExIsMatch](@Pattern [nvarchar](4000), @Input [nvarchar](max), @Options [int])
RETURNS [bit] WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [RegexFunction].[SimpleTalk.Phil.Factor.RegularExpressionFunctions].[RegExIsMatch]
GO
