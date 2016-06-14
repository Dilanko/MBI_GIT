param([string]$Database)
$ServerName='SQL-1-BSC'# the server it is on
$DirectoryToSaveTo=join-path $PSScriptRoot "DDL\$Database" # the directory where you want to store them

# Load SMO assembly
$v = [System.Reflection.Assembly]::LoadWithPartialName( 'Microsoft.SqlServer.SMO')
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SmoEnum') | out-null
set-psdebug -strict # catch a few extra bugs
$ErrorActionPreference = "stop"
$My='Microsoft.SqlServer.Management.Smo'
$srv = new-object ("$My.Server") $ServerName # attach to the server
if ($srv.ServerType-eq $null) # if it managed to find a server
   {
   Write-Error "Sorry, but I couldn't find Server '$ServerName' "
   return
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
$d=$srv.databases[$Database].EnumObjects([long]0x1FFFFFFF -band $target_objects) | `
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
