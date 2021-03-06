SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


  --declare @target_server nvarchar(128) = 'CRDPROD01'

  CREATE procedure [dbo].[sp_get_thresholds] (@target_server nvarchar(128),
  @lr_sql int output, @lr_xact int output, @blocking int output)
  as

  select @lr_sql = threshold_minutes
  from
  (
  select threshold_minutes
  from threshold
  where target_name = @target_server
  and threshold_type = 'lr_sql'
  UNION
  select threshold_minutes
  from threshold t1
  inner join target_server ts on ts.environment = t1.target_name and ts.server_name = @target_server
  where threshold_type = 'lr_sql'
  and not exists (select 1 from threshold t2
					where t2.threshold_type = t1.threshold_type
					and t2.target_name = @target_server)
  ) thresholds_unioned

  select @lr_xact = threshold_minutes
  from
  (
  select threshold_minutes
  from threshold
  where target_name = @target_server
  and threshold_type = 'lr_xact'
  UNION
  select threshold_minutes
  from threshold t1
  inner join target_server ts on ts.environment = t1.target_name and ts.server_name = @target_server
  where threshold_type = 'lr_xact'
  and not exists (select 1 from threshold t2
					where t2.threshold_type = t1.threshold_type
					and t2.target_name = @target_server)
  ) thresholds_unioned

  select @blocking = threshold_minutes
  from
  (
  select threshold_minutes
  from threshold
  where target_name = @target_server
  and threshold_type = 'blocking'
  UNION
  select threshold_minutes
  from threshold t1
  inner join target_server ts on ts.environment = t1.target_name and ts.server_name = @target_server
  where threshold_type = 'blocking'
  and not exists (select 1 from threshold t2
					where t2.threshold_type = t1.threshold_type
					and t2.target_name = @target_server)
  ) thresholds_unioned


GO
