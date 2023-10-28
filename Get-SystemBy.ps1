<#
.SYNOPSIS
    Create file.

.DESCRIPTION
    Create file with IP's and/or device names needed for the PowerShell website.

.PARAMETER DirectoryPath
    Specify the path of the directory or leave as default. Default will be the directory structure created by IIS, plus the following sub-directories dash\ReferenceData.

.PARAMETER Devices
    Specify device names where DNS works or IP address.

.EXAMPLE
    Set-SystemsBy -Devices '10.10.10.1','Spartans'

.EXAMPLE
    Set-SystemsBy -DirectoryPath $env:USERPROFILE -Devices 'LittleMouse','192.168.1.1'

.NOTES
    Any improvements welcome.
#>

function Get-SystemsBy {

    [CmdletBinding()]
    param(
        [String]$DirectoryPath='C:\inetpub\wwwroot\dash\ReferenceData',
        [String[]]$Devices
    )

    #region INITIAL VARIABLES
    
        $FileName = 'Devices.json'
    
    #endregion

    #region FUNCTIONS

        function Set-DeviceFile {

            param(
                [String[]]$InputData
            )

            # Set Variables
            $PrintToFile = [System.Collections.ArrayList]::new()

            foreach ($DataInput in $InputData){

                if ($DataInput -match "^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])$"){
                
                    Write-Verbose "Adding IP: $DataInput to custom object"
                    $CustomObject = [PSCustomObject]@{
                        
                        IP   = $DataInput
                        Name = 'false'
                    }
                }
                else {
                    
                    Write-Verbose "Adding Name: $DataInput to custom object"
                    $CustomObject = [PSCustomObject]@{
                        
                        IP   = 'false'
                        Name = $DataInput
                    }
                }
                
                if ([String]::IsNullOrWhiteSpace($InputData)){
                
                    Write-Warning "No Data. Ending Script."
                    exit
                }
                
                $PrintToFile.Add($CustomObject) | Out-Null
            }
            
            Write-Verbose "Creating array for objects"
            $Write = $PrintToFile | ConvertTo-Json
            
            Write-Verbose "Printing the following to file:"
            Write-Verbose `n$Write
            $Write | Set-Content -Path "$DirectoryPath\$FileName"
        }

    #endregion

    #region SCRIPT

        if ($Devices){

            Write-Verbose "Setting file by provided devices"    
            Set-DeviceFile -InputData $Devices
        }
        else {
        
            Write-Warning "No devices specified"
        }

    #endregion

}