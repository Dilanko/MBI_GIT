SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE FUNCTION dbo.Find_regular_expression (@source     VARCHAR(5000),
                                             @regexp     VARCHAR(1000),
                                             @ignorecase BIT = 0)
returns BIT
AS
  BEGIN
      DECLARE @hr INTEGER
      DECLARE @objRegExp INTEGER
      DECLARE @objMatches INTEGER
      DECLARE @objMatch INTEGER
      DECLARE @count INTEGER
      DECLARE @results BIT

      EXEC @hr = Sp_oacreate
        'VBScript.RegExp',
        @objRegExp output

      IF @hr <> 0
        BEGIN
            SET @results = 0

            RETURN @results
        END

      EXEC @hr = Sp_oasetproperty
        @objRegExp,
        'Pattern',
        @regexp

      IF @hr <> 0
        BEGIN
            SET @results = 0

            RETURN @results
        END

      EXEC @hr = Sp_oasetproperty
        @objRegExp,
        'Global',
        false

      IF @hr <> 0
        BEGIN
            SET @results = 0

            RETURN @results
        END

      EXEC @hr = Sp_oasetproperty
        @objRegExp,
        'IgnoreCase',
        @ignorecase

      IF @hr <> 0
        BEGIN
            SET @results = 0

            RETURN @results
        END

      EXEC @hr = Sp_oamethod
        @objRegExp,
        'Test',
        @results output,
        @source

      IF @hr <> 0
        BEGIN
            SET @results = 0

            RETURN @results
        END

      EXEC @hr = Sp_oadestroy
        @objRegExp

      IF @hr <> 0
        BEGIN
            SET @results = 0

            RETURN @results
        END

      RETURN @results
  END  
GO
