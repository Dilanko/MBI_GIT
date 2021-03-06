SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[RegExOptionEnumeration](@IgnoreCase [bit], @MultiLine [bit], @ExplicitCapture [bit], @Compiled [bit], @SingleLine [bit], @IgnorePatternWhitespace [bit], @RightToLeft [bit], @ECMAScript [bit], @CultureInvariant [bit])
RETURNS [int] WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [RegexFunction].[SimpleTalk.Phil.Factor.RegularExpressionFunctions].[RegExOptionEnumeration]
GO
