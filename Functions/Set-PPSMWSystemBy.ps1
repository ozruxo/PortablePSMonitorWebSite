<#
.SYNOPSIS
    Create file.

.DESCRIPTION
    Create file with IP's and/or device names needed for the PowerShell website.

.PARAMETER ReferenceDataPath
    Specify the path of the directory.

.PARAMETER Devices
    Specify device names where DNS works or IP address.

.PARAMETER AllDevicesFileName
    Specify the name of the file name for the file with all the devices listed.

.EXAMPLE
    Set-PPSMWSystemsBy -ReferenceDataPath $ReferenceDataPath -Devices 'LittleMouse','192.168.1.1' -AllDevicesFileName "Devices.json"

.NOTES
    Any improvements welcome.

.FUNCTIONALITY
    PPSMW build web site
#>

function Set-PPSMWSystemsBy {

    [CmdletBinding()]
    param(
        [Parameter(mandatory=$true)]
        [String]$ReferenceDataPath,
        [Parameter(mandatory=$true)]
        [String[]]$Devices,
        [Parameter(mandatory=$true)]
        [String]$AllDevicesFileName
    )

    #region INITIAL VARIABLES

        $FullDirectoryPath = "$ReferenceDataPath\$AllDevicesFileName"
    
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
            
            Write-Verbose "Set Path: $FullDirectoryPath"
            Write-Verbose "Printing the following to file:"
            Write-Verbose `n$Write
            $Write | Set-Content -Path "$FullDirectoryPath"
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