SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--sp_send_error_email_check 'CRDQUAL01', 'errorlog'

CREATE procedure [dbo].[sp_previous_run_cycle_status] (@target_server nvarchar(128), @alert_type nvarchar(50))
as
-- The only time an alert_status of not 'ok' should be returned is when the last two cycles are both not 'ok'.

	declare @last_run datetime2, @prior_to_last_run datetime2

	select @last_run = max(run_timestamp)
	from cycle_log
	where target_server = @target_server
	and alert_type = @alert_type

	select @prior_to_last_run = max(run_timestamp)
	from cycle_log
	where target_server = @target_server
	and alert_type = @alert_type
	and run_timestamp < @last_run

	if exists (select 1 from cycle_log 
			where target_server = @target_server
			and alert_type = @alert_type
			and run_timestamp = @last_run
			and alert_status <> 'ok')
		and exists (select 1 from cycle_log 
			where target_server = @target_server
			and alert_type = @alert_type
			and run_timestamp = @prior_to_last_run
			and alert_status <> 'ok' )
		select 'error' as status

	else
		select 'ok' as status
GO
