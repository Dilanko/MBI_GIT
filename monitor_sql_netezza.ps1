param(
	[parameter(mandatory=$true)]
	[string]$current_dir
)
if (-NOT (test-path $current_dir)) {
	throw  "current_dir parameter invalid: $current_dir"
}
cd $current_dir -passthru

$config_file = join-path $pwd "..\config.xml"
if (test-path $config_file) {
	[xml]$ConfigFile = Get-Content $config_file
} else {
	throw "$config_file not found ... exiting"
}

$email_to = $ConfigFile.settings.email.to
$error_signal_file = "..\\scratch\\netezza_error_email_signal_file.txt"
import-module (join-path $pwd mbips)

foreach ($target_server in ('ProdStriper','DevStriper'))
{
	try {
		$connectionstring = $ConfigFile.settings.db.connection.Netezza
		$active_query = Get-SQLData -connectionString $connectionString -query "exec sp_active_query_monitor '$target_server', 120" -isSQLServer
	} catch {
		try {
			# if a problem exists with the first invocation of 'sp_active_query_monitor', try one more time before throwing an error
			# (we have found that network glitches causing failures often correct themselves by the second try to run the same sql).
			$active_query = Get-SQLData -connectionString $connectionString -query "exec sp_active_query_monitor '$target_server', 120" -isSQLServer
		}
		catch {
			if (test-path $error_signal_file) {
				$last_error_email = (get-item $error_signal_file | select lastwritetime).LastWriteTime
			} else {
				set-content $error_signal_file ""
				$last_error_email = "12/1/2015"
			}
			
			if  ((new-timespan -start ($last_error_email) -end (get-date)).TotalMinutes -GT 59) {
				$messageParameters = @{                        
					Subject = "$($target_server): Long Running SQL Alert [MBI Monitor, BSC Netezza] -> ERROR"
					Body = "Problem with initial exec on SQL-1-BSC\BSCXE (after two tries)`n" + $_                   
					From = "bsc-netezza-ops@mbisolutions.net"                        
					To = $email_to
					SmtpServer = "gateway-1.corpdr.drp"                        
				}                        
				Send-MailMessage @messageParameters #-BodyAsHtml  
				set-content $error_signal_file ""
			}
			throw "Problem with initial interaction with SQL-1_BSC (second try)"
		}
	}

	$send_mail_flag = $active_query | where {($_.alert_status -eq 'NEW') -or ($_.alert_status -eq 'CLEARED')} | select alert_status -first 1
#	$new_alerts = $active_query | where {($_.alert_status -eq 'NEW')}
#	$cleared_alerts = $active_query | where {($_.alert_status -eq 'CLEARED')}
#	$continuing_alerts = $active_query | where {($_.alert_status -eq 'CONTINUING')}
	 
	if ($send_mail_flag) {
		$messageParameters = @{                        
			Subject = "$($target_server): Long Running SQL ALERT [MBI Monitor, BSC Netezza]"
			Body = $active_query | 
				select alert_status, 
				@{Name="duration";Expression={"{0:c}" -f (New-Timespan $_.submit_time $_.collection_time)}},    
				duration_min, dbname, username, email, sql, submit_time, session_id, planid,
				 @{Name="est costSecs";Expression={"{0:N1}" -f ($_.estcost/1000)}},
				 @{Name="est diskMB";Expression={"{0:N1}" -f ($_.estdisk/1MB)}},
				 @{Name="est memMB";Expression={"{0:N1}" -f ($_.estmem/1MB)}},
				 @{Name="result rows";Expression={"{0:N0}" -f $_.resrows}},
				 @{Name="result Mbytes";Expression={"{0:N1}" -f ($_.resbytes/1MB)}},
				 collection_time, hostname | fl | Out-String
			From = "bsc-netezza-ops@mbisolutions.net"                        
			To = $email_to
			SmtpServer = "gateway-1.corpdr.drp"                        
		}                        
		Send-MailMessage @messageParameters #-BodyAsHtml  
	} else {
		write "nothing to email"
		$active_query
	}
}