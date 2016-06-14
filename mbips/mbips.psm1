function create_ddl
{
	[CmdletBinding()]
	param([string]$target_db = $(throw "Target server required.")) 

	$ServerName='SQL-1-BSC'# the server it is on
	$DirectoryToSaveTo=join-path $PSScriptRoot "..\DDL\$target_db" # the directory where you want to store them

	# Load SMO assembly
	$v = [System.Reflection.Assembly]::LoadWithPartialName( 'Microsoft.SqlServer.SMO')
	[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SmoEnum') | out-null
	set-psdebug -strict # catch a few extra bugs
	$ErrorActionPreference = "stop"
	$My='Microsoft.SqlServer.Management.Smo'
	$srv = new-object ("$My.Server") $ServerName # attach to the server
	if ($srv.ServerType-eq $null) # if it managed to find a server
	   {
	   throw "Sorry, but I couldn't find Server '$ServerName' "
	}
	$scripter = new-object ("$My.Scripter") $srv # create the scripter
	$scripter.Options.ToFileOnly = $true
	$scripter.Options.Triggers = $true
	$scripter.Options.Indexes = $true

	# first we get the bitmap of all the object types we want
	$target_objects = [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::StoredProcedure `
		-bor [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::Table `
		-bor [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::UserDefinedFunction `
		-bor [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::View

	# get everything except the servicebroker object, the information schema and system views
	$d=$srv.databases[$target_db].EnumObjects([long]0x1FFFFFFF -band $target_objects) | `
		Where-Object {$_.Schema -ne 'sys'-and $_.Schema -ne "information_schema" -and $_.DatabaseObjectTypes -ne 'ServiceBroker'}

	# and write out each scriptable object as a file in the directory you specify
	$d| FOREACH-OBJECT { # for every object we have in the datatable.
	   $SavePath="$($DirectoryToSaveTo)\$($_.DatabaseObjectTypes)"
	   # create the directory if necessary (SMO doesn't).
	   if (!( Test-Path -path $SavePath )) # create it if not existing
			{Try { New-Item $SavePath -type directory | out-null }
			Catch [system.exception]{
				Write-Error "error while creating '$SavePath' $_"
				return
			 }
		}
		# tell the scripter object where to write it
		$scripter.Options.Filename = "$SavePath\$($_.name -replace '[\\\/\:\.]','-').sql";
		# Create a single element URN array
		$UrnCollection = new-object ('Microsoft.SqlServer.Management.Smo.urnCollection')
		$URNCollection.add($_.urn)
		# and write out the object to the specified file
		$scripter.script($URNCollection)
	}
}


function collect_metrics
{
	[CmdletBinding()]
	param([string]$target_server = $(throw "Target server required.")) 
	
	$config_file = join-path $PSScriptRoot "..\..\config.xml"
	if (test-path $config_file) {
		[xml]$ConfigFile = Get-Content $config_file
	} else {
		throw "$config_file not found ... exiting"
	}
	$email_to_default = $ConfigFile.settings.email.to
	$connectionstring =  $ConfigFile.settings.db.connection.SQLServer

	try {
		$email_to = (Get-SQLData -connectionString $connectionString -query "exec sp_get_alert_recipient $target_server" -isSQLServer).email_name
		Get-SQLData -connectionString $connectionString -query "exec sp_collect_metrics $target_server" -isSQLServer
        
        $previous_run_status = Get-SQLData -connectionString $connectionString -query "exec sp_previous_run_cycle_status $target_server, 'metrics'" -isSQLServer
        if ($previous_run_status | where status -ne 'ok') {
            #this cycle is good, previous cycle was bad, so send cycle failure all-clear email
    		$messageParameters = @{                        
				Subject = "$($target_server): Metrics Collection [MBI Monitor, TRP] -> ERROR ALL CLEAR"
				Body = "Previous monitor error condition has cleared."             
				From = "tier2@mbisolutions.net"                                            
				To = $email_to
				SmtpServer = "gateway-1.corpdr.drp"                        
			}                        
			Send-MailMessage @messageParameters #-BodyAsHtml  
        }
       	
	} catch {
        $error_message = $_ -replace "'", "''"
		$current_date = Get-SQLData -connectionString $connectionString -query "select getdate()" -isSQLServer
   		Invoke-SQL -connectionString $connectionString -query ("insert into cycle_log values ('{0}', '{1}', 'metrics', 'error', '{2}')" -f $current_date.column1.ToString(), $target_server, $error_message) -isSQLServer		
		$send_error_alert = Get-SQLData -connectionString $connectionString -query ("select dbo.fn_send_error_email('metrics','{0}','{1}')" -f $target_server, $current_date.column1.ToString()) -isSQLServer		
	    write ("send_error_alert {0}" -f $send_error_alert.column1)
		
		if ($send_error_alert.column1 -eq 'Y') {

			$messageParameters = @{                        
				Subject = "$($target_server): Metrics Collection [MBI Monitor, TRP] -> ERROR"
				Body = $error_message             
				From = "tier2@mbisolutions.net"                                            
				To = if ($email_to -eq $null) { $email_to_default } else { $email_to }
				SmtpServer = "gateway-1.corpdr.drp"                        
			}                        
			Send-MailMessage @messageParameters #-BodyAsHtml  
			Invoke-SQL -connectionString $connectionString -query ("insert into cycle_log values ('{0}', '{1}', 'metrics', 'error email', 'sent')" -f $current_date.column1.ToString(), $target_server) -isSQLServer	
			#throw
		}
		return
	}
 
	$status = "N/A"
    Invoke-SQL -connectionString $connectionString -query ("insert into cycle_log values (getdate(), '{0}', 'metrics', 'ok', '{1}')" -f $target_server, $status) -isSQLServer	
}


function monitor_errorlog
{
	[CmdletBinding()]
	param([string]$target_server = $(throw "Target server required.")) 

	$config_file = join-path $PSScriptRoot "..\..\config.xml"
	if (test-path $config_file) {
		[xml]$ConfigFile = Get-Content $config_file
	} else {
		throw "$config_file not found ... exiting"
	}
	$email_to_default = $ConfigFile.settings.email.to
	$connectionstring =  $ConfigFile.settings.db.connection.SQLServer
	
	try {
		$email_to = (Get-SQLData -connectionString $connectionString -query "exec sp_get_alert_recipient $target_server" -isSQLServer).email_name
		$alertable_entries = Get-SQLData -connectionString $connectionString -query "exec sp_monitor_errorlog $target_server" -isSQLServer
        
        $previous_run_status = Get-SQLData -connectionString $connectionString -query "exec sp_previous_run_cycle_status $target_server, 'errorlog'" -isSQLServer
        if ($previous_run_status | where status -ne 'ok') {
            #this cycle is good, previous cycle was bad, so send cycle failure all-clear email
    		$messageParameters = @{                        
				Subject = "$($target_server): Errorlog Alert [MBI Monitor, TRP] -> ERROR ALL CLEAR"
				Body = "Previous monitor error condition has cleared."             
				From = "tier2@mbisolutions.net"                                            
				To = $email_to
				SmtpServer = "gateway-1.corpdr.drp"                        
			}                        
			Send-MailMessage @messageParameters #-BodyAsHtml  
        }
       	
	} catch {
        $error_message = $_ -replace "'", "''"
		$current_date = Get-SQLData -connectionString $connectionString -query "select getdate()" -isSQLServer
   		Invoke-SQL -connectionString $connectionString -query ("insert into cycle_log values ('{0}', '{1}', 'errorlog', 'error', '{2}')" -f $current_date.column1.ToString(), $target_server, $error_message) -isSQLServer		
		$send_error_alert = Get-SQLData -connectionString $connectionString -query ("select dbo.fn_send_error_email('errorlog','{0}','{1}')" -f $target_server, $current_date.column1.ToString()) -isSQLServer		
	    write ("send_error_alert {0}" -f $send_error_alert.column1)
		
		if ($send_error_alert.column1 -eq 'Y') {

			$messageParameters = @{                        
				Subject = "$($target_server): Errorlog Alert [MBI Monitor, TRP] -> ERROR"
				Body = $error_message             
				From = "tier2@mbisolutions.net"                                            
				To = if ($email_to -eq $null) { $email_to_default } else { $email_to }
				SmtpServer = "gateway-1.corpdr.drp"                        
			}                        
			Send-MailMessage @messageParameters #-BodyAsHtml  
			Invoke-SQL -connectionString $connectionString -query ("insert into cycle_log values ('{0}', '{1}', 'errorlog', 'error email', 'sent')" -f $current_date.column1.ToString(), $target_server) -isSQLServer	
			#throw
		}
		return
	}
 
	if ($alertable_entries) {
		$messageParameters = @{                        
			Subject = "$($target_server): Errorlog Alert [MBI Monitor, TRP]"
			Body = $alertable_entries | ConvertTo-Html LogDate, ProcessInfo, Text | Out-String        
			From = "tier2@mbisolutions.net"                        
			To = $email_to
			SmtpServer = "gateway-1.corpdr.drp"                        
		}                        
		Send-MailMessage @messageParameters -BodyAsHtml 
	} else {
		write "no errorlog alerts identified for $target_server"
	}
	
	if ($alertable_entries -eq $null) {
		$active_count = 0
	} else {
		$active_count = @($alertable_entries).length
	}
	$status = "$active_count alerts identified"
    Invoke-SQL -connectionString $connectionString -query ("insert into cycle_log values (getdate(), '{0}', 'errorlog', 'ok', '{1}')" -f $target_server, $status) -isSQLServer	
}

function monitor_active_queries
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$True, Position=0)]
		[string]$target_server,
		
		[Parameter(Mandatory=$True, Position=1)]
		[ValidateSet("normal","test")]
		[string]$run_mode,
		
		[Parameter(Mandatory=$False, Position=2)]
		[string]$email_to_override	
	)

	$config_file = join-path $PSScriptRoot "..\..\config.xml"
	if (test-path $config_file) {
		[xml]$ConfigFile = Get-Content $config_file
	} else {
		throw "$config_file not found ... exiting"
	}
	$email_to_default = $ConfigFile.settings.email.to
	$connectionstring =  $ConfigFile.settings.db.connection.SQLServer
	$max_sql_size = 500
	 
	try {
		if ($email_to_override) {
			$email_to = $email_to_override
		} 
		else {
			$email_to = (Get-SQLData -connectionString $connectionString -query "exec sp_get_alert_recipient $target_server" -isSQLServer).email_name
		}
		
		$active_query = Get-SQLData -connectionString $connectionString -query "exec sp_monitor_active_query $target_server, $run_mode" -isSQLServer
        #$active_query = Get-SQLData -connectionString $connectionString -query "exec sp_monitor_active_query_test 'INVQUAL02', '2016-02-13 09:10:42'" -isSQLServer
		
        $previous_run_status = Get-SQLData -connectionString $connectionString -query "exec sp_previous_run_cycle_status $target_server, 'sql'" -isSQLServer
        if ($previous_run_status | where status -ne 'ok') {
            #this cycle is good, previous cycle was bad, so send cycle failure all-clear email
    		$messageParameters = @{                        
				Subject = "$($target_server): SQL Alert [MBI Monitor, TRP] -> ERROR ALL CLEAR"
				Body = "Previous monitor error condition has cleared."             
				From = "tier2@mbisolutions.net"                                            
				To = $email_to
				SmtpServer = "gateway-1.corpdr.drp"                        
			}                        
			Send-MailMessage @messageParameters #-BodyAsHtml  
        }

 	} catch {
        $error_message = $_ -replace "'", "''"
		$current_date = Get-SQLData -connectionString $connectionString -query "select getdate()" -isSQLServer
   		Invoke-SQL -connectionString $connectionString -query ("insert into cycle_log values ('{0}', '{1}', 'sql', 'error', '{2}')" -f $current_date.column1.ToString(), $target_server, $error_message) -isSQLServer			
		$send_error_alert = Get-SQLData -connectionString $connectionString -query ("select dbo.fn_send_error_email('sql','{0}','{1}')" -f $target_server, $current_date.column1.ToString()) -isSQLServer	
		write ("send_error_alert {0}" -f $send_error_alert.column1)
		
		if ($send_error_alert.column1 -eq 'Y') {
 
			$messageParameters = @{                        
				Subject = "$($target_server): SQL Alert [MBI Monitor, TRP] -> ERROR"
				Body = $error_message             
				From = "tier2@mbisolutions.net"                                            
				To = if ($email_to -eq $null) {$email_to_default} else { $email_to }
				SmtpServer = "gateway-1.corpdr.drp"                        
			}                        
			Send-MailMessage @messageParameters #-BodyAsHtml  
			Invoke-SQL -connectionString $connectionString -query ("insert into cycle_log values ('{0}', '{1}', 'sql', 'error email', 'sent')" -f $current_date.column1.ToString(), $target_server) -isSQLServer	

			#throw
		}
		return
	}

	$send_mail_flag = $active_query | where {($_.alert_status -eq 'NEW') -or ($_.alert_status -eq 'CLEARED')} | select alert_status -first 1

	if ($send_mail_flag) {
	
		[Reflection.Assembly]::LoadFile("C:\mbimon\lib\gudusoft.gsqlparser.dll");
		$DBVendor = [gudusoft.gsqlparser.TDbVendor]::DBVMssql
		$sqlparser = new-object gudusoft.gsqlparser.TGSqlParser($DBVendor)
		
		$active_query | foreach-object {
			$sqlparser.SqlText.Text = $_.sql_text
			$sqlparser.PrettyPrint()
			$_.sql_text = $sqlparser.FormattedSqlText.Text
			$sqlparser.SqlText.Text = $_.sql_command
			$sqlparser.PrettyPrint()
			$_.sql_command = $sqlparser.FormattedSqlText.Text
		}

		# Perform special handling for sql if determined necessary.
		$attachments = @()
		$active_query | foreach-object {
			if ($_.sql_text -eq $_.sql_command) 
				{$_.sql_command = " < same as sql_text >"} 
			elseif (($_.sql_command).Length -gt $max_sql_size) {
				$filename = "C:\temp\" + $target_server + "_" + $_.session_id + "_sql_command.txt"
				$sqlparser.SqlText.Text = $_.sql_command
				$sqlparser.PrettyPrint()
				# Only create file attachment for NEW alerts.
				if ($_.alert_status -eq 'NEW') {
					set-content $filename $sqlparser.FormattedSqlText.Text
					$attachments += $filename
				}
				#$_.sql_command = ($_.sql_command).substring(0,$max_sql_size) + " . . ."	
				$_.sql_command = ($sqlparser.FormattedSqlText.Text).substring(0,$max_sql_size) + " . . ."	
			}
			if (($_.sql_text).Length -gt $max_sql_size) {
				$filename = "c:\temp\" + $target_server + "_" + $_.session_id + "_sql_text.txt"
				$sqlparser.SqlText.Text = $_.sql_text
				$sqlparser.PrettyPrint()
				# Only create file attachment for NEW alerts.
				if ($_.alert_status -eq 'NEW') {
					set-content $filename $sqlparser.FormattedSqlText.Text
					$attachments += $filename
				}
				#$_.sql_text = ($_.sql_text).substring(0,$max_sql_size)	+ " . . ."	
				$_.sql_text = ($sqlparser.FormattedSqlText.Text).substring(0,$max_sql_size)	+ " . . ."	
			}
		}			

		$head = '
			<style>
			table, th, td {
				border: 1px solid black;
			}
			th {
				background-color: green
				color: white;
			}
			</style>
		'
		$email_alerts = $active_query | 
		select @{name="alert";Expression={"{0} ({1}) at {2}" -f $_.alert_status, $_.alert_types, $_.collection_time}},
		@{Name="elapsed";Expression={"{0:dd}d {0:hh}h {0:mm}m" -f (New-Timespan $_.start_time $_.collection_time)}},    
		database_name,
		@{name="who";Expression={"login {0} (session id {1}), program {2}, host {3}, login_time {4}" -f $_.login_name, $_.session_id, $_.program_name, $_.host_name, $_.login_time}},
		@{name="status";Expression={"{0}, waits={1}({2}), Blocker={3}, started {4})" -f $_.status, $_.wait_type, $_.wait_time, $_.blocking_session_id, $_.start_time}},
		@{Name="resources used";Expression={"LReads={0:N0} PReads={1:N0} writes={2:N0}" -f $_.reads, $_.physical_reads, $_.writes}},	
		@{Name="run history (min|avg|max)";Expression={"{0:N0} execs, TimeMS={1:N0}|{2:N0}|{3:N0} LReads={4:N0}|{5:N0}|{6:N0} PReads={7:N0}|{8:N0}|{9:N0} Rows={10:N0}|{11:N0}|{12:N0} created={13}" `
			-f $_.execution_count, $_.min_elapsed_time, $_.avg_elapsed_time, $_.max_elapsed_time, $_.min_logical_reads, $_.avg_logical_reads, $_.max_logical_reads, `
			$_.min_physical_reads, $_.avg_physical_reads, $_.max_physical_reads, $_.min_rows, $_.avg_rows, $_.max_rows, $_.creation_time}},	   
		sql_text,
		sql_command |
		#fl | Out-String 
		ConvertTo-Html -Head $head | Out-String
		
		$threshold_info = Get-SQLData -connectionString $connectionString -query "exec sp_show_thresholds $target_server" -isSQLServer | 
			select threshold_class, threshold_type, threshold_minutes, comment |
			#ft | out-string
			ConvertTo-Html | Out-String
				
		$messageParameters = @{                        
			Subject = "$($target_server): SQL Alert [MBI Monitor, TRP]"
			Body = ($email_alerts + "`r`n`r`n" + $threshold_info)
			From = "tier2@mbisolutions.net"                        
			To = $email_to
			SmtpServer = "gateway-1.corpdr.drp"                        
		} 
		
		try {
			if ($attachments) {
				$attachments | Send-MailMessage @messageParameters -BodyAsHtml 
				$attachments | foreach-object {
					remove-item $_
				}
			} else
			{
				Send-MailMessage @messageParameters -BodyAsHtml 
			}
		} catch {
			$error_message = $_ -replace "'", "''"
			$current_date = Get-SQLData -connectionString $connectionString -query "select getdate()" -isSQLServer
			Invoke-SQL -connectionString $connectionString -query ("insert into cycle_log values ('{0}', '{1}', 'sendmail', 'error', '{2}')" -f $current_date.column1.ToString(), $target_server, $error_message) -isSQLServer	
		}
	} else {
		write "no sql alerts identified for $target_server"
	}
	
	if ($active_query -eq $null) {
		$active_count = 0
	} else {
		$active_count = @($active_query).length
	}
	$status = "$active_count alerts identified"
    Invoke-SQL -connectionString $connectionString -query ("insert into cycle_log values (getdate(), '{0}', 'sql', 'ok', '{1}')" -f $target_server, $status) -isSQLServer	
}

function Get-SQLData
{
	[CmdletBinding()]
	param (
		[string]$connectionString,
		[string]$query,
		[switch]$isSQLServer
	)
	try
	{
		if ($isSQLServer)
		{
			Write-Verbose 'in SQL Server mode'
			$connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
		}
		else
		{
			Write-Verbose 'in OleDB mode'
			$connection = New-Object -TypeName System.Data.Odbc.OdbcConnection
		}
		$connection.ConnectionString = $connectionString
		$command = $connection.CreateCommand()
		$command.CommandText = $query
		if ($isSQLServer)
		{
			$adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
		}
		else
		{
			$adapter = New-Object System.Data.Odbc.OdbcDataAdapter $command
		}
		$dataset = New-Object -TypeName System.Data.DataSet
		[void]$adapter.Fill($dataset) # [void] required to suppress integer returned showing total row count
		$dataset.Tables[0]
	}
	catch
	{
		$err = $_.Exception
		write-error $err.Message
		#Write-Error "connection string: $connectionstring"
		Write-Error "sql: $query"
		<#		while ($err.InnerException)
		{
			$err = $err.InnerException
			write-error $err.Message
		}
#>		
		throw
	}
}
function Invoke-SQL
{
	[CmdletBinding()]
	param (
		[string]$connectionString,
		[string]$query,
		[switch]$isSQLServer
	)
	if ($isSQLServer)
	{
		Write-Verbose 'in SQL Server mode'
		$connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
	}
	else
	{
		Write-Verbose 'in OleDB mode'
		$connection = New-Object System.Data.Odbc.OdbcConnection
	}
	$connection.ConnectionString = $connectionString
	$command = $connection.CreateCommand()
	$command.CommandTimeout = 3600
	$command.CommandText = $query
	try
	{
		$connection.Open()
		$command.ExecuteNonQuery()
		$connection.close()
	}
	catch
	{
		$err = $_.Exception
		write-error $err.Message
		Write-Error "connection string: $connectionstring"
		Write-Error "sql: $query"
		throw
	}
}

function repeat-sql
{
	Param ([string]$sql,
		[string]$connectionString)
	
	while (1 -eq 1)
	{
		try
		{
			invoke-sql -query $sql -connectionString $connectionString -isSQLServer 
		}
		catch
		{
			throw
		}
	}#while
	$output = [PSCustomObject]@{
		SQL = $sql
		Error = $err.Message
	}
	Write-Output $output
} #repeat-sql

