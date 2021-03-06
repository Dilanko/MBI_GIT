SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

  --declare @target_server nvarchar(128) = 'CRDPROD01'

CREATE procedure [dbo].[sp_show_thresholds] (@target_server nvarchar(128))
  as

  -- If the "threshold" table has an explicit entry for @target_server, display that.
  -- Otherwise, display thresholds for the related "environment".
  select target_name as threshold_class, threshold_type, threshold_minutes, 'COMMENT' as comment
  into #threshold
  from threshold
  where 1 = 2

  if exists (select 1 from threshold where target_name = @target_server)
	  insert into #threshold
	  select target_name, threshold_type, threshold_minutes, ''
	  from threshold
	  where target_name = @target_server
	  order by 2
  else
	  insert into #threshold
	  select target_name, th.threshold_type, th.threshold_minutes, ''
	  from threshold th
	  inner join target_server ts on ts.environment = th.target_name and ts.server_name = @target_server
	  order by 2

 -- Using the most recent active query entries, display any thresholds that match SQL text.
 select *
 from #threshold
 union
 select 'SQL', sql_text, threshold, comment
 from active_query_threshold t
 where exists (
	select 1
	from active_query_vw aq
	where aq.server_name = @target_server
	and aq.collection_time = (select max(collection_time) from active_query_vw where server_name = @target_server)
	and aq.sql_text like t.sql_text
 )



GO
