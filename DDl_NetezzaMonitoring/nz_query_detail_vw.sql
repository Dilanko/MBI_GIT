SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view nz_query_detail_vw
as
select dt, db, 
	case charindex('_',db)
					when 0 then db
					else substring(db,1,charindex('_',db)-1)
				 end as db_category
from nz_query_detail
GO
