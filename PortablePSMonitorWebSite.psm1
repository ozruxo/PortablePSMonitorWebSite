$ModulePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\PortablePSMonitorWebSite"
#$ModulePath = "C:\Program Files\WindowsPowerShell\Modules\PortablePSMonitorWebSite"

$FunctionModules = Get-ChildItem -Path "$ModulePath\Functions\*.ps1"

Foreach($Import in $FunctionModules){

    try{
     
        Write-Verbose "Importing module $($Import.FullName)"
        . $import.FullName
    }
    catch{
        
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}