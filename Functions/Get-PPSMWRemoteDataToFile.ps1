<#
.SYNOPSIS
    Create files with device details.

.DESCRIPTION
    Create files that correlate to the devices you would like to monitor. This files will contain data pertaining to each device and will be used to populate the website.

.PARAMETER Access
    Specify access is available with network domain credentials.

.PARAMETER ReferenceDataPath
    Specify directory path for list of all devices and for storing JSON files.

.PARAMETER AllDeviceFileName
    Specify the name of the files with all the devices listed.

.PARAMETER PingFolderPath
    Specify the directory path for the ping folder.

.PARAMETER NoAccessFolderPath
    Specify the directory path for systems that could not be accessed.

.PARAMETER RootDirectory
    Specify the path of the files that stores the information on what computers to monitor. The actual file will be written by this script.

.EXAMPLE
    Get-RemoteDataToFile `
    -Access `
    -ReferenceDataPath $ReferenceDataPath `
    -AllDeviceFilename $AllDeviceFileName `
    -PingFolderPath $PingFolderPath `
    -NoAccessFolderPath $NoAccessFolderPath `
    -RootDirectoryPath $RootDirectoryPath

.NOTES
    Any improvements welcome.

.FUNCTIONALITY
    PPSMW build web site
#>

function Get-PPSMWRemoteDataToFile {

    [CmdletBinding()]
    param(
        [Switch]$Access,
        [String]$ReferenceDataPath,
        [String]$AllDeviceFileName,
        [String]$PingFolderPath,
        [String]$NoAccessFolderPath,
        [String]$RootDirectoryPath
    )

    #region INITIAL VARIABLES

        $Progress = "(•_•)     ","(•_•)     ","(•_•)     ","(•_•)     ","(•_•)     ","(•_•)     ","(•_•)     ","(•_•)     ","( •_•)>⌐■-■","( •_•)>⌐■-■","(⌐■_■)     ","(⌐■_■)     ","(⌐■_■)     ","(⌐■_■)     "
        $i = 0

    #endregion

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

        $SendFunction = {function Get-AllInfo {

            #region FUNCTIONS

                function Get-RAMInfo {
        
                    $RAMAvail = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
                    $RAMinGB = "$([math]::Round($RAMAvail/1024,2))"
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
                            $DataDiskPercentAvailable = [math]::Round($Maths*100)
                            
                            $DD = [PSCustomObject]@{
                            
                                DiskLetter = $Dri.DeviceID
                                DiskPerc   = $DataDiskPercentAvailable
                            }

                            $DataDiskReturn.Add($DD) | Out-Null
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
                        # This is not accounting for remote session such as powershell
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

                    $HardwareInfo = [PSCustomObject]@{
                    
                        Manufacturer = $ComputerSystem.Manufacturer
                        Model        = $ComputerSystem.Model
                        SystemFamily = $ComputerSystem.SystemFamily
                        SerialNumber = ($SerialNumber).SerialNumber
                        BIOSVersion  = $BIOSVersion
                    }

                    return $HardwareInfo
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
                        $CPUInfo.Add($CustomObject) | Out-Null
                    }

                    return $CPUInfo
                }

                function Get-OSInfo {
            
                    $OperatingSystem = Get-CimInstance -ClassName CIM_OperatingSystem | Select-Object Caption, InstallDate, LastBootUpTime, LocalDateTime, BuildNumber
                    
                    $OSInfo = [PsCustomObject]@{
                    
                        Caption        = $OperatingSystem.Caption
                        InstallDate    = $OperatingSystem.InstallDate.ToString()
                        LastBootUpTime = $OperatingSystem.LastBootUpTime.ToString()
                        LocalDateTime  = $OperatingSystem.LocalDateTime.ToString()
                        BuildNumber    = $OperatingSystem.BuildNumber
                    }

                    return $OSInfo
                }

                function Get-NetworkInfo {

                    $Network = Get-CimInstance Win32_NetworkAdapterConfiguration | Select-Object Description, DHCPEnabled, IPAddress, DefaultIPGateway, MACAddress
                    $SaveIP = [System.Collections.ArrayList]::New()
                    foreach ($Net in $Network){
                
                        if ($Net.DefaultIPGateway){
                    
                            foreach ($IP in $Net.IPAddress){
                        
                                if ($IP -match "^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])$"){
                            
                                    $SaveIP.Add($IP) | Out-Null
                                }
                                $NetInfo = [PSCustomObject]@{
                        
                                    Description = $Net.Description
                                    DHCPEnabled = $Net.DHCPEnabled
                                    IPAddress   = $SaveIP
                                    MACAddress  = $Net.MACAddress
                                }
                            }
                        }
                    }

                    return $NetInfo
                }

                function Get-DeviceType {

                    $VHost = Get-Command Get-VM -ErrorAction SilentlyContinue

                    if ($Hardware.Model -eq 'Virtual Machine'){
                    
                        $DeviceType = 'vm'
                    }
                    elseif($VHost){
                    
                        $DeviceType = 'vHost'
                    }
                    else{
                    
                        $DeviceType = 'nonVM'
                    }

                    return $DeviceType
                }

                function Get-VMs {
                
                    $ListOfIPs = [System.Collections.ArrayList]::New()
                    $VMs = Get-VM
                    foreach ($VM in $VMs){
                    
                        if ($VM.NetworkAdapters.Status -eq 'Ok'){
                        
                            $VMIP = $VM.NetworkAdapters.IPAddresses[0]
                            $ListOfIPs.Add($VMIP) | Out-Null
                        }
                    }
                    return $ListOfIPs
                }

            #endregion

            #region SCRIPT

                # Get Data
                $RAM        = Get-RAMInfo       # Object in GB
                $OSDIsk     = Get-OSDiskInfo    # Object in percentage
                $DataDisk   = Get-DataDiskInfo  # Drive letter + percentage
                $UserCount  = Get-UserCount     # Object
                $Hardware   = Get-HardwareInfo  # Objects
                $Processor  = Get-ProcessorInfo # Objects
                $OS         = Get-OSInfo        # Objects
                $Network    = Get-NetworkInfo   # Arrays in Objects
                $DeviceType = Get-DeviceType    # String

                # Make custom object
                $PrintToFile = [PSCustomObject]@{
                
                    Name         = "$env:COMPUTERNAME"
                    DeviceType   = $DeviceType
                    PingOnly     = 'No'
                    Status       = 'Online'
                    RAMGB        = $RAM
                    OSDiskPerc   = $OSDIsk
                    DataDiskInfo = $DataDisk
                    UserCount    = $UserCount
                    Hardware     = $Hardware
                    Processor    = $Processor
                    OSInfo       = $OS
                    NetworkInfo  = $Network
                }

                if ($DeviceType -eq 'vHost'){
                
                    $PrintToFile | Add-Member -Name 'VMIPs' -MemberType NoteProperty -Value (Get-VMs)
                }

                # Convert everything to JSON
                $PrintToFile | ConvertTo-Json

            #endregion
        }}

    #endregion

    #region SCRIPT

        $ImportDevices = Get-Content "$ReferenceDataPath\$AllDeviceFileName"
        $Devices = $ImportDevices | ConvertFrom-Json

        foreach ($Device in $Devices){

            # Check via IP 
            if ($Device.IP -ne 'false'){

                $DeviceString = $Device.IP
            }
            if ($Device.Name -ne 'false'){

                $DeviceString = $Device.Name
            }

            if ($Access){
            
                $Available = Confirm-Connection -Device $DeviceString

                # Start Jobs
                If ($Available){
                
                    Start-Job -Name $DeviceString -ArgumentList $DeviceString -InitializationScript $SendFunction -ScriptBlock {
                    
                        # Variable
                        $DeviceString = $args[0]
                        
                        Invoke-Command -ComputerName $DeviceString -ScriptBlock ${function:Get-AllInfo}
                    } | Out-Null
                }
                else{
                    
                    $NoAccessNoPing = [PScustomObject]@{
                        
                        Name     = $DeviceString
                        Status   = "NotAccessible"
                        PingOnly = 'No'
                    }

                    Set-Content -Value ($NoAccessNoPing | ConvertTo-Json) -Path "$NoAccessFolderPath\$DeviceString.json"

                }

            }
            else{

                $Available = Confirm-Connection -Device $DeviceString

                # Create file for devices
                if ($Available -eq $true){
                    
                    $AccessPing = [PScustomObject]@{
                        
                        Name     = $DeviceString
                        Status   = "Online"
                        PingOnly = 'Yes'
                    }

                    Set-Content -Value ($AccessPing | ConvertTo-Json) -Path "$PingFolderPath\$DeviceString.json"
                }

                if ($Available -eq $false){
                    
                    $NoAccessNoPing = [PScustomObject]@{
                        
                        Name     = $DeviceString
                        Status   = "Offline"
                        PingOnly = 'Yes'
                    }

                    Set-Content -Value ($NoAccessNoPing | ConvertTo-Json) -Path "$NoAccessFolderPath\$DeviceString.json"
                }
            }
        }
        # Get Data from Jobs and sort files to the correct directory
        do{
            # Set variable
            $Jobs = Get-Job

            foreach ($Job in $Jobs){
            
                # Print all data to referenceData folder
                if ($Job.State -eq 'Completed' -and $Job.HasMoreData -eq $true){
                
                    Write-Verbose "Getting data from job"
                    $ReceivedJob = Receive-Job -InstanceId $Job.InstanceId -ErrorAction SilentlyContinue
                    if ([string]::IsNullOrWhiteSpace($ReceivedJob)){
                            
                        Write-Verbose "No access for $($Job.Name)"
                        $NoAccessValue = [PScustomObject]@{
                        
                            Name     = $Job.Name
                            Status   = "NotAccessible"
                            PingOnly = 'No'
                        }
                        Set-Content -Value ($NoAccessValue | ConvertTo-Json) -Path "$NoAccessFolderPath\$($Job.Name).json"
                    }
                    else{
                        
                        $ParseData = $ReceivedJob | ConvertFrom-Json 
                        Write-Verbose "Writing Data for $($Job.Name)"
                        Set-Content -Value $ReceivedJob -Path "$ReferenceDataPath\$($ParseData.DeviceType)\$($Job.Name).json"
                    }
                }
                # Remove successful job
                elseif ($Job.State -eq 'Completed' -and $Job.HasMoreData -eq $false){
                
                    Write-Verbose "Removed successful job"
                    Remove-Job -InstanceId $Job.InstanceId
                }
                # Remove failed job
                elseif ($Job.State -eq 'Failed' -and $Job.HasMoreData -eq 'False'){

                    Write-Verbose "$($Job.Name) failed with no data"
                    Remove-Job -InstanceID $Job.InstanceId
                }
                # Print verbose on unknown job status
                elseif($Job.State -ne 'Completed' -and $Job.State -ne 'Failed'){
                    
                    if ($Job.State -ne 'Running'){

                        Write-Verbose "Id: $($Job.Id) | Name: $($Job.Name) | State: $($Job.State) | HasMoreData: $($Job.HasMoreData)"
                    }
                }
            }

            if($PSVersionTable.PSVersion.Major -ge 7){
                
                Write-Host -NoNewline "`r$($Progress[$i])"
                if ($i -eq 13){$i = 0}else{$i++}
            }
            Start-Sleep -Milliseconds 500
        }until($Jobs.count -eq 0)

    #endregion

}
