SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create function [dbo].[fn_hashbytesMAX]
    ( @string  nvarchar(max)
    , @Algo    varchar(10)
    )
    returns varbinary(20)
as
/************************************************************
*
*    Author:        Brandon Galderisi
*    Last modified: 15-SEP-2009 (by Denis)
*    Purpose:       uses the system function hashbytes as well
*                   as sys.fn_varbintohexstr to split an 
*                   nvarchar(max) string and hash in 8000 byte 
*                   chunks hashing each 8000 byte chunk,,
*                   getting the 40 byte output, streaming each 
*                   40 byte output into a string then hashing 
*                   that string.
*
*************************************************************/
begin
     declare    @concat       nvarchar(max)
               ,@NumHash      int
               ,@HASH         varbinary(20)
     set @NumHash = ceiling((datalength(@string)/2)/(4000.0))
    /* HashBytes only supports 8000 bytes so split the string if it is larger */
    if @NumHash>1
    begin
                                                        -- # * 4000 character strings
          ;with a as (select 1 as n union all select 1) -- 2 
               ,b as (select 1 as n from a ,a a1)       -- 4
               ,c as (select 1 as n from b ,b b1)       -- 16
               ,d as (select 1 as n from c ,c c1)       -- 256
               ,e as (select 1 as n from d ,d d1)       -- 65,536
               ,f as (select 1 as n from e ,e e1)       -- 4,294,967,296 = 17+ TRILLION characters
               ,factored as (select row_number() over (order by n) rn from f)
               ,factors as (select rn,(rn*4000)+1 factor from factored)

          select @concat = cast((
          select right(sys.fn_varbintohexstr
                         (
                         hashbytes(@Algo, substring(@string, factor - 4000, 4000))
                         )
                      , 40) + ''
          from Factors
          where rn <= @NumHash
          for xml path('')
          ) as nvarchar(max))


          set @HASH = dbo.fn_hashbytesMAX(@concat ,@Algo)
    end
     else
     begin
          set @HASH = convert(varbinary(20), hashbytes(@Algo, @string))
     end

return @HASH
end

GO
