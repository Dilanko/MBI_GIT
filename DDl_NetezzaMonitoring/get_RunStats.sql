SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function get_RunStats (@sqlhash varbinary(20), @dbname varchar(100), @hostname varchar(100), @runVal integer)
returns varchar(100)
as
BEGIN
declare @cntVal integer, @minVal integer, @maxVal integer, @avgVal integer, @stdVal integer, @runStatus  varchar(20), @returnVal varchar(100);

select @cntVal = count(*), 
	@minVal = min(datediff(mi,submit_time,end_time)), 
	@maxVal = max(datediff(mi,submit_time,end_time)), 
	@avgVal = avg(datediff(mi,submit_time,end_time)), 
	@stdVal = stdev(datediff(mi,submit_time,end_time))
from query_history q
where sqlhash = @sqlhash
and dbname = @dbname
and hostname = @hostname;

if @runVal >= @maxVal set @runStatus = 'New Max'
else if @runVal > (@avgVal + (2 * @stdVal)) set @runStatus = 'High Range'
else set @runStatus = 'Normal';

set @returnVal = @runStatus + ': ' + 'cnt(' + cast(@cntVal as varchar(20)) + ') min(' + cast(@minVal as varchar(20)) + 
	') max( ' + cast(@maxVal as varchar(20)) + ') avg(' + cast(@avgVal as varchar(20)) + ') STD(' + cast(@stdVal as varchar(20)) + ')';

return(@returnVal);
END;


GO
