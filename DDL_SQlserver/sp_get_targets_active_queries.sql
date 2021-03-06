SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[sp_get_targets_active_queries]
as
select server_name
from target_server
where datediff(mi,isnull(last_active_query_cycle,'1/1/2015'),getdate()) > active_query_polling_cycle 
and status = 'active'



GO
