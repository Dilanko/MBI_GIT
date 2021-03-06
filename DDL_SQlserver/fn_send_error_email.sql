SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[fn_send_error_email] (@alert_type varchar(100), @target_server nvarchar(128), @current_run datetime2)
RETURNS char(1)
as

-- The context in which this function is called is the "catch" block of the errorlog/active_sql Powershell scripts.  The purpose of this
-- function is to control the frequency with which error email are sent.  The objective is to minimize error email "floods" while still 
-- providing reasonable fast notice of true error conditions.

BEGIN
	-- first check that the expected current cycle_log entry exists.  If not, this implies a serious failure that requires immediate handling.
	-- return a 'Y'.
	if not exists (select 1 from cycle_log where alert_type = @alert_type and target_server = @target_server and run_timestamp = @current_run)
		return 'Y'
	/*
	-- if the cycle_log had no entries prior to the current entry, this should be considered an alertable error condition.
	if not exists (select 1 from cycle_log where alert_type = @alert_type and target_server = @target_server and run_timestamp < @current_run)
		return 'Y'
	*/

	declare @last_run datetime2, @prior_to_last_run datetime2

	select @last_run = max(run_timestamp) from cycle_log where alert_type = @alert_type and target_server = @target_server and run_timestamp < @current_run
	select @prior_to_last_run = max(run_timestamp) from cycle_log where alert_type = @alert_type and target_server = @target_server and run_timestamp < @last_run

	-- This first condition simply confirms the expected "context" (noted above), where the current run encountered an error condition.
	if exists (
		select 1 from cycle_log where alert_type = @alert_type and target_server = @target_server and run_timestamp = @current_run and alert_status <> 'ok'
		)
		BEGIN
			-- Often, an error cycle will be encountered that immeidately corrects itself on the next cycle.  We wish to avoid sending alerts on this 
			-- "self-correcting" error cycle.  Therefore, the requirement for sending an error email immediately is that two error cycles have been 
			--  encountered after an "ok" cycle.
			if exists (
					select 1 from cycle_log where alert_type = @alert_type and target_server = @target_server and run_timestamp = @last_run and alert_status <> 'ok'
				)
				AND exists (
					select 1 from cycle_log where alert_type = @alert_type and target_server = @target_server and run_timestamp = @prior_to_last_run and alert_status = 'ok'
				)
			return 'Y'

			-- this condition is the true "throttle", which will avoid error email "floods" during a long period of error conditions.
			--  Before returning a send_error_email flag can even be considered, the hour of the current cycle must be at least 1 hour
			--  after that of the previous cycle.
			if (datediff(hh,@last_run,@current_run) > 0)
				-- there must not be any "ok" cycles within the last hour, i.e., there must be a continuous period of errors.
				if not exists (
					select 1 from cycle_log where alert_type = @alert_type and target_server = @target_server and run_timestamp > dateadd(hh,-1,@current_run) and alert_status = 'ok'
				)
				return 'Y'
		END

	return 'N'
END
GO
