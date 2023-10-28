<#
.SYNOPSIS
    Create files with device details.

.DESCRIPTION
    Create files that correlate to the devices you would like to monitor. This files will contain data pertaining to each device and will be used to populate the website.

.PARAMETER DeviceFilePath
    Specify the path of the files that stores the information on what computers to monitor. File type should be JSON.

.PARAMETER Access
    Specify whether access is available or not with $true or $false.

.PARAMETER Continuous
    Specify if you want the files to be updated on a cadence.

.PARAMETER Frequency
    Specify the cadence for how often to check the remote systems.

.EXAMPLE
    Get-RemoteDataToFile -DeviceFilePath $RootDirecotry\$DevicesFile -Access $true

.NOTES
    Any improvements welcome.
#>

function Get-RemoteDataToFile {

    param(
        [String]$Access=$false,
        [String]$DeviceFilePath,
        [Switch]$Continuous,
        [Int]$Frequency
    )

    #region FUNCTIONS

        function Confirm-Connection {
            
            param(
                [String]$Device
            )

            $PingResult   = ping $Device -n 1
            $PingReceived = $PingResult[5].Split(',')[1]

            if ($PingReceived -match ' Received = 1'){
                
                $Connection = $true
            }
            else {
                
                $Connection = $false
            }
            return $Connection
        }

        function Get-AllInfo {

            function Get-RAMInfo {
        
                $RAMAvail = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
                $RAMinGB = "$([math]::Round($RAMAvail/1024,2))GB"
                return $RAMinGB
            }
    
            function Get-OSDiskInfo {
            
                $Drives = Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}
                foreach ($Dri in $Drives){
                
                    if ($Dri.DeviceID -eq 'C:'){
                
                        $FreeSpace = [math]::Round($Dri.FreeSpace / 1GB)
                        $TotalSize = [math]::Round($Dri.Size / 1GB)
                        $Maths = $FreeSpace/$TotalSize
                        $OSDiskPercentAvailable = [math]::Round($Maths*100)
                    }
                }
    
                return $OsDiskPercentAvailable
            }

            function Get-DataDiskInfo {
        
                $DataDiskReturn = [System.Collections.ArrayList]::New()

                $Drives = Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}
                foreach ($Dri in $Drives){
                
                    if ($Dri.DeviceID -ne 'C:'){
                
                        $FreeSpace = [math]::Round($Dri.FreeSpace / 1GB)
                        $TotalSize = [math]::Round($Dri.Size / 1GB)
                        $Maths = $FreeSpace/$TotalSize
                        $OSDiskPercentAvailable = [math]::Round($Maths*100)
                        $DataDiskReturn.Add("$($Dri.DeviceID);$OSDiskPercentAvailable") | Out-Null
                    }   
                }
    
                return $DataDiskReturn
            }
        
            function Get-UserCount {
    
                $sessions = cmd /c "query session"
                $i = 0
                foreach ($Line in $sessions){
    
                    if($Line -match 'SESSIONNAME'){
            
                        continue
                    }
    
                    elseif($Line -match 'Services'){
            
                        continue
                    }
                    elseif($Line -match 'Console'){
            
                        continue
                    }
                    elseif($Line -match '65536'){
            
                        continue
                
                    }
                    elseif($Line -match '65537'){
            
                        continue
                    }
                    else{
            
                        $i++
                    }
                }
    
                return $i
            }

            function Get-HardwareInfo {
            
                $ComputerSystem = Get-CimInstance -ClassName CIM_ComputerSystem | Select-Object Manufacturer, Model, SystemFamily
                $SerialNumber   = Get-CimInstance -ClassName CIM_Chassis | Select-Object SerialNumber
                $BIOSVersion    = (Get-CimInstance -ClassName CIM_BIOSElement).SMBIOSBIOSVersion
            }

            function Get-ProcessorInfo {
            
                # Variable
                $CPUInfo = [System.Collections.ArrayList]::new()

                $ComputerProcessor = Get-CimInstance -ClassName Cim_Processor | Select-Object DeviceID, Name, AddressWidth, NumberOfCores, NumberOfLogicalProcessors
                foreach ($CP in $ComputerProcessor){
                
                    $CustomObject = [PSCustomObject]@{
                    
                        DeviceId             = $CP.DeviceId
                        Name                 = $CP.Name
                        NumberOfCores        = $CP.NumberOfCores
                        NumberOfLogicalCores = $CP.NumberOfLogicalProcessors
                    }
                    $CPUInfo.Add($CustomObject)
                    return $CPUInfo
                }
            }

            function Get-OSInfo {
            
                $OSInfo = Get-CimInstance -ClassName CIM_OperatingSystem | Select-Object Caption, InstallDate, LastBootUpTime, LocalDateTime, BuildNumber
                return $OSInfo
            }

            function Get-NetworkInfo {

                $Network = Get-CimInstance Win32_NetworkAdapterConfiguration | Select-Object Description, DHCPEnabled, IPAddress, DefaultIPGateway, MACAddress
                foreach ($Net in $Network){
                
                    if ($Net.DefaultIPGateway){
                    
                        foreach ($IP in $Net.IPAddress){
                        
                            if ($IP -match "^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])$"){
                            
                                $SaveIP = $IP
                            }
                        }

                        $NetInfo = [PSCustomObjects]@{
                        
                            Description = $Network.Description
                            DHCPEnabled = $Network.DHCPEnabled
                            IPAddress   = $SaveIP
                            MACAddress  = $Network.MACAddress
                        }
                    }
                }
                return $NetInfo
            }

            # Maybe add Get-QuickVMInfo for vhost
        }

    #endregion

    #region SCRIPT

        $ImportDevices = Get-Content $DeviceFilePath
        $Devices = ConvertFrom-Json $ImportDevices

        foreach ($Device in $Devices){

            # Check via IP 
            if ($Device.IP -ne 'false'){

                # Variable
                $DeviceString = $Device.IP

                if ($Access -eq $true){
            
                    $Available = Confirm-Connection -Device $DeviceString
                }

                If ($Access -eq $false){

                    $Available = Confirm-Connection -Device $DeviceString
            
                }
            }

            # Check via Name
            if ($Device.Name -ne 'false'){

                # Variable
                $DeviceString = $Device.Name

                if ($Access -eq $true){
            
                    $Available = Confirm-Connection -Device $DeviceString
                }

                If ($Access -eq $false){

                    $Available = Confirm-Connection -Device $DeviceString
            
                }
            }
        }

    #endregion

    # Start jobs to gather all data

    # Print all data to referenceData folder

}