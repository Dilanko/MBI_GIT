param(
	[parameter(mandatory=$true)]
	[string]$current_dir
)
if (-NOT (test-path $current_dir)) {
	throw  "current_dir parameter invalid: $current_dir"
}
cd $current_dir -passthru

if (test-path ./running.flg) {
	write-warning "script is still running.  Exiting ..."
	exit 1
} else {
	 new-item -path . -name running.flg -type "file"
}

import-module (join-path $current_dir mbips)
$config_file = join-path $current_dir "../config.xml"
if (test-path $config_file) {
	[xml]$ConfigFile = Get-Content $config_file
} else {
	throw "$config_file not found ... exiting"
}
$email_to = $ConfigFile.settings.email.to
$connectionstring =  $ConfigFile.settings.db.connection.SQLServer
$error_signal_file = "..\\scratch\\SS_error_email_signal_file.txt"

try {
    $target_servers_errorlog = Get-SQLData -connectionString $connectionString -query "exec sp_get_targets_errorlog" -isSQLServer
    $target_servers_active_queries = Get-SQLData -connectionString $connectionString -query "exec sp_get_targets_active_queries" -isSQLServer	
	Invoke-SQL -connectionString $connectionString -query "update cycle_clock set cycle_runtime = getdate()" -isSQLServer	
	
} catch {
	if (test-path $error_signal_file) {
		$last_error_email = (get-item $error_signal_file | select lastwritetime).LastWriteTime
	} else {
		set-content $error_signal_file ""
		$last_error_email = "12/1/2015"
	}

	if  ((new-timespan -start ($last_error_email) -end (get-date)).TotalMinutes -GT 59) {
		$messageParameters = @{                        
			Subject = "SQL Server [MBI Monitor, TRP] -> INITIALIZING ERROR"
			Body = "Problem with initial exec on SQL-1-BSC\BSCXE `n" + $_                   
			From = "tier2@mbisolutions.net"                                            
			To = $email_to
			SmtpServer = "gateway-1.corpdr.drp"                        
		}
		Send-MailMessage @messageParameters #-BodyAsHtml  
		set-content $error_signal_file ""
	}
    throw "problem with initial interaction with sql-1-bsc"
}

foreach ($target_server in $target_servers_active_queries)
{
	monitor_active_queries -target_server $target_server.server_name -run_mode 'normal' # -email_to_override 'kmccool@mbisolutions.net'
	Invoke-SQL -connectionString $connectionString -query ("update target_server set last_active_query_cycle = getdate() where server_name = '{0}'" -f $target_server.server_name) -isSQLServer	
}

foreach ($target_server in $target_servers_errorlog)
{
	monitor_errorlog $target_server.server_name
	Invoke-SQL -connectionString $connectionString -query ("update target_server set last_errorlog_cycle = getdate() where server_name = '{0}'" -f $target_server.server_name) -isSQLServer	
}

collect_metrics 'CRDPROD01'
collect_metrics 'INVPROD02'
collect_metrics 'INVPROD03'

remove-item ./running.flg

