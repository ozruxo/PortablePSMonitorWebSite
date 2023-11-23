<#
.SYNOPSIS
    Start the portable website.

.DESCRIPTION
    Start and run the portable website.

.PARAMETER RootDirectoryPath
    Specify the root directory if the deault for IIS is not desired.

.PARAMETER SourceFiles
    Specify the direcoty path of the downloaded files.

.PARAMETER ForceFolderCreation
    Force the creation of website directories.

.PARAMETER Devices
    Specify the devices you would like to monitor.

.PARAMETER Permission
    Specify if you have permissions to the remote systems. Permission will allow for getting more detailed information.

.PARAMETER Continuous
    Specifiy if you would like this module to update the files continuously.

.PARAMETER Minutes
    Specify the frequency of the udpates. Default is 5 minutes. Other set options are: 10,15,20,30,45,60.

.PARAMETER StopAfter
    Specify how many loops until complete.

.EXAMPLE
    Invoke-PPSMWOrchestration `
    -RootDirectoryPath "$env:USERPROFILE\Desktop\PPSMW"
    -SourceFiles "$env:USERPROFILE\Desktop\PortablePSMonitorWebSite" `
    -Devices (Get-Content "$env:USERPROFILE\Desktop\AllComputers.txt") `
    -Permission `
    -Continuous `
    -Minutes 5 `
    -StopAfter 100

.EXAMPLE
    Invoke-PPSMWOrchestration `
    -RootDirectoryPath "$env:USERPROFILE\Desktop\PPSMW"
    -SourceFiles "$env:USERPROFILE\Desktop\PortablePSMonitorWebSite" `
    -Devices (Get-Content "$env:USERPROFILE\Desktop\AllComputers.txt")

.NOTES
    Any improvements welcome.

.FUNCTIONALITY
    PPSMW build web site
#>

function Invoke-PPSMWOrchestration {

    [CmdletBinding()]
    param(
        [Parameter(mandatory=$true)]
        [String]$RootDirectoryPath,
        [Parameter(mandatory=$true)]
        [String]$SourceFiles,
        [Switch]$ForceFolderCreation,
        [Parameter(mandatory=$true)]
        [String[]]$Devices,
        [Switch]$Permission,
        [Switch]$Continuous,
        [ValidateSet(5,10,15,20,30,45,60)]
        [Int]$Minutes=5,
        [Int]$StopAfter
    )

    #region INITIAL VARIABLES

        # Easy variables to change variables
        $IndividualDevicePageFolder = 'individual'
        $IndividualDevicePageName   = 'single'
        $vHostDevicePageName        = 'allvhosts'
        $DataFilesDir               = 'referenceData'
        $NoAccessFolder             = 'noAccess'
        $PingFolder                 = 'ping'
        $NonVMFolder                = 'nonVM'
        $vHostFolder                = 'vHost'
        $VMFolder                   = 'vm'
        $AllDevicesFileName         = 'Devices.json'
        $IndexFileName              = 'index'
        $ErrorFolderName            = 'error'

        # Less easy variables to change
        $MediaFolderName            = 'style'
        $TemplateFolderName         = 'template'
        $IndividualWebFolderPath    = "$RootDirectoryPath\pages\$IndividualDevicePageFolder"
        $IndividualDevicePagePath   = "$RootDirectoryPath\pages\$IndividualDevicePageName"
        $vHostDevicePagePath        = "$rootDirectoryPath\pages\$vHostDevicePageName"
        $ErrorFolderPath            = "$rootDirectoryPath\pages\$ErrorFolderName"
        $ReferenceDataPath          = "$RootDirectoryPath\$DataFilesDir"
        $NoAccessFolderPath         = "$ReferenceDataPath\$NoAccessFolder"
        $NonVMFolderPath            = "$ReferenceDataPath\$NonVMFolder"
        $PingFolderPath             = "$ReferenceDataPath\$PingFolder"
        $vHostFolderPath            = "$ReferenceDataPath\$vHostFolder"
        $VMFolderPath               = "$ReferenceDataPath\$VMFolder"
        
        # For copying files
        $RefMediaFolderPath         = "Resources\$MediaFolderName"
        $RefTemplateFolderPath      = "Resources\$TemplateFolderName"

        # Set counter
        if ($StopAfter){
        
            $Stop = 0
        }
        else {
        
            $Stop      = 0
            $StopAfter = 1
        }

    #endregion

    #region SCRIPT

        # Create folder structure, copy css and template files
        if ($ForceFolderCreation){
    
            Write-Output "Force creating directories"
            Set-PPSMWFolders `
            -RootDirectoryPath $RootDirectoryPath `
            -SourceFiles $SourceFiles `
            -IndividualWebFolderPath $IndividualWebFolderPath `
            -NoAccessFolderPath $NoAccessFolderPath `
            -NonVMFolderPath $NonVMFolderPath `
            -PingFolderPath $PingFolderPath `
            -vHostFolderPath $vHostFolderPath `
            -VMFolderPath $VMFolderPath `
            -RefMediaFolderPath $RefMediaFolderPath `
            -RefTemplateFolderPath $RefTemplateFolderPath `
            -ErrorFolderPath $ErrorFolderPath `
            -Force
        }
        else{
    
            if (-not (Test-Path $ReferenceDataPath)){
                
                Write-Output "Creating directories"
                Set-PPSMWFolders `
                -RootDirectoryPath $RootDirectoryPath `
                -SourceFiles $SourceFiles `
                -IndividualWebFolderPath $IndividualWebFolderPath `
                -NoAccessFolderPath $NoAccessFolderPath `
                -NonVMFolderPath $NonVMFolderPath `
                -PingFolderPath $PingFolderPath `
                -vHostFolderPath $vHostFolderPath `
                -VMFolderPath $VMFolderPath `
                -RefMediaFolderPath $RefMediaFolderPath `
                -ErrorFolderPath $ErrorFolderPath `
                -RefTemplateFolderPath $RefTemplateFolderPath `
            }
            else{

                $FreashStart = Get-ChildItem $ReferenceDataPath -Depth 1 | Where-Object {$PSItem.Name -match '.json'}
                Remove-Item $FreashStart.FullName -Force -Recurse
            }
        }

        # Set reference file for all devices to check
        Write-Output "Writing reference file for all devices"
        Set-PPSMWSystemsBy `
        -Devices $Devices `
        -ReferenceDataPath $ReferenceDataPath `
        -AllDevicesFileName $AllDevicesFileName

        # If permissions, get all data
        if ($Permission){
        
            Write-Verbose "Parameter permissions selected"
            if ($Continuous){

                Write-Verbose "Parameter continuous selected"
                do{

                    Write-Output "Getting remote data...This might take a while"
                    Get-PPSMWRemoteDataToFile `
                    -Access `
                    -ReferenceDataPath $ReferenceDataPath `
                    -AllDeviceFileName $AllDevicesFileName `
                    -PingFolderPath $PingFolderPath `
                    -NoAccessFolderPath $NoAccessFolderPath `
                    -RootDirectoryPath $RootDirectoryPath
                    
                    # Return devices that could not be accessed from the noAccess folder
                    if ((Get-ChildItem -Path $NoAccessFolderPath).Count -gt 0){

                        $NoAccessFiles = Get-ChildItem -Path $NoAccessFolderPath
                        foreach ($NAFile in $NoAccessFiles){

                            Write-Host -ForegroundColor Red "Cannot access: $(($NAFile.Name -split '.',-6))"
                        }
                    }
                    
                    # Only contiue if files exist
                    if (((Get-ChildItem $NonVMFolderPath).Count + (Get-ChildItem $vHostFolderPath).Count + (Get-ChildItem $VMFolderPath).Count) -gt 0){

                        Write-Host "Writing from reference data"
                        Build-PPSMWSitePages `
                        -Access `
                        -RootDirectoryPath $RootDirectoryPath `
                        -ReferenceDataPath $ReferenceDataPath `
                        -PingFolderPath $PingFolderPath `
                        -NonVMFolderPath $NonVMFolderPath `
                        -vHostFolderPath $vHostFolderPath `
                        -vHostDevicePagePath $vHostDevicePagePath `
                        -VMFolderPath $VMFolderPath `
                        -TemplateFolderName $TemplateFolderName `
                        -IndexFileName $IndexFileName `
                        -IndividualWebFolderPath $IndividualWebFolderPath `
                        -IndividualDevicePagePath $IndividualDevicePagePath
                    }
                    else{

                        Write-Warning "No reference data generated"
                        break
                    }
                    $Stop++
                    Start-Sleep -Seconds ($Minutes*60)
                    
                    # Print count to file
                    $Count = [PSCustomObject] @{
                        
                        LoopIteration = $Stop
                    }
                    Write-Verbose "Print to count file"
                    Set-Content -Value ($Count | ConvertTo-Json) -Path "$RootDirectoryPath\Count.json"

                }until($Stop -eq $StopAfter)
            }
            else{
            
                Write-Output "Getting remote data...This might take a while"
                Get-PPSMWRemoteDataToFile `
                    -Access `
                    -ReferenceDataPath $ReferenceDataPath `
                    -AllDeviceFileName $AllDevicesFileName `
                    -PingFolderPath $PingFolderPath `
                    -NoAccessFolderPath $NoAccessFolderPath `
                    -RootDirectoryPath $RootDirectoryPath
                
                # Return devices that could not be accessed from the noAccess folder
                if ((Get-ChildItem -Path $NoAccessFolderPath).Count -gt 0){

                    $NoAccessFiles = Get-ChildItem -Path $NoAccessFolderPath
                    foreach ($NAFile in $NoAccessFiles){

                        Write-Host -ForegroundColor Red "Cannot access: $(($NAFile.Name -split '.',-6))"
                    }
                }
                
                # Only contiue if files exist
                if (((Get-ChildItem $NonVMFolderPath).Count + (Get-ChildItem $vHostFolderPath).Count + (Get-ChildItem $VMFolderPath).Count) -gt 0){

                    Write-Host "Writing from reference data"
                    Build-PPSMWSitePages `
                    -Access `
                    -RootDirectoryPath $RootDirectoryPath `
                    -ReferenceDataPath $ReferenceDataPath `
                    -PingFolderPath $PingFolderPath `
                    -NonVMFolderPath $NonVMFolderPath `
                    -vHostFolderPath $vHostFolderPath `
                    -vHostDevicePagePath $vHostDevicePagePath `
                    -VMFolderPath $VMFolderPath `
                    -TemplateFolderName $TemplateFolderName `
                    -IndexFileName $IndexFileName `
                    -IndividualWebFolderPath $IndividualWebFolderPath `
                    -IndividualDevicePagePath $IndividualDevicePagePath
                }
                else{

                    Write-Warning "No reference data generated"
                    break
                }
            }
        }
        # if no permissions
        else{
        
            if ($Continuous){
            
                do{

                    Write-Output "Getting remote data...This might take a while"
                    Get-PPSMWRemoteDataToFile `
                    -ReferenceDataPath $ReferenceDataPath `
                    -AllDeviceFileName $AllDevicesFileName `
                    -PingFolderPath $PingFolderPath `
                    -NoAccessFolderPath $NoAccessFolderPath `
                    -RootDirectoryPath $RootDirectoryPath
                    
                    # Return devices that could not be accessed from the noAccess folder
                    if ((Get-ChildItem -Path $NoAccessFolderPath).Count -gt 0){

                        $NoAccessFiles = Get-ChildItem -Path $NoAccessFolderPath
                        foreach ($NAFile in $NoAccessFiles){
    
                            Write-Host -ForegroundColor Red "Cannot access: $(($NAFile.Name -split '.',-6))"
                        }
                    }

                    # Only contiue if files exist
                    if ((Get-ChildItem $PingFolderPath).Count -gt 0){

                        Write-Host "Writing from reference data"
                        Build-PPSMWSitePages `
                        -RootDirectoryPath $RootDirectoryPath `
                        -ReferenceDataPath $ReferenceDataPath `
                        -PingFolderPath $PingFolderPath `
                        -NonVMFolderPath $NonVMFolderPath `
                        -vHostFolderPath $vHostFolderPath `
                        -VMFolderPath $VMFolderPath `
                        -TemplateFolderName $TemplateFolderName `
                        -IndexFileName $IndexFileName
                    }
                    else{
    
                        Write-Warning "No reference data generated"
                        break
                    }

                    $Stop++
                    Start-Sleep -Seconds ($Minutes*60)

                    # Print count to file
                    $Count = [PSCustomObject] @{
                        
                        LoopIteration = $Stop
                    }
                    Set-Content -Value ($Count | ConvertTo-Json) -Path "$RootDirectoryPath\Count.json"

                }until($Stop -eq $StopAfter)
            }
            else {
            
                Write-Output "Getting remote data...This might take a while"
                Get-PPSMWRemoteDataToFile `
                -ReferenceDataPath $ReferenceDataPath `
                -AllDeviceFileName $AllDevicesFileName `
                -PingFolderPath $PingFolderPath `
                -NoAccessFolderPath $NoAccessFolderPath `
                -RootDirectoryPath $RootDirectoryPath
                
                # Return devices that could not be accessed from the noAccess folder
                if ((Get-ChildItem -Path $NoAccessFolderPath).Count -gt 0){

                    $NoAccessFiles = Get-ChildItem -Path $NoAccessFolderPath
                    foreach ($NAFile in $NoAccessFiles){

                        Write-Host -ForegroundColor Red "Cannot access: $(($NAFile.Name -split '.',-6))"
                    }
                }

                # Only contiue if files exist
                if ((Get-ChildItem $PingFolderPath).Count -gt 0){

                    Write-Host "Writing from reference data"
                    Build-PPSMWSitePages `
                    -RootDirectoryPath $RootDirectoryPath `
                    -ReferenceDataPath $ReferenceDataPath `
                    -PingFolderPath $PingFolderPath `
                    -NonVMFolderPath $NonVMFolderPath `
                    -vHostFolderPath $vHostFolderPath `
                    -VMFolderPath $VMFolderPath `
                    -TemplateFolderName $TemplateFolderName `
                    -IndexFileName $IndexFileName
                }
                else{

                    Write-Warning "No reference data generated"
                    break
                }
            }
        }

    #endregion
}