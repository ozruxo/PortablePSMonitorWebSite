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

.PARAMETER Permissions
    Specify if you have permissions to the remote systems. Permission will allow for getting more detailed information.

.PARAMETER Continuous
    Specifiy if you would like this module to update the files continuously.

.PARAMETER Minutes
    Specify the frequency of the udpates. Default is 5 minutes. Other set options are: 10,15,20,30,45,60.

.EXAMPLE
    Invoke-PPSMWOrchestration `

    -SourceFiles "$env:USERPROFILE\Desktop\PortablePSMonitorWebSite" `
    -Devices (Get-Content "$env:USERPROFILE\Desktop\AllComputers.txt") `
    -Permission `
    -Continuous `
    -Minutes 5 `
    -StopAfter 100

.NOTES
    Any improvements welcome.
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
    
            Set-PPSMWFolders -RootDirectoryPath $RootDirectoryPath -SourceFiles $SourceFiles -Force
        }
        else{
    
            Set-PPSMWFolders -RootDirectoryPath $RootDirectoryPath -SourceFiles $SourceFiles
        }

        # Set reference file for all devices to check
        Set-PPSMWSystemsBy -DirectoryPath $RootDirectoryPath -Devices $Devices

        # If permissions, get all data
        if ($Permission){
        
            if ($Continuous){

                do{

                    Get-PPSMWRemoteDataToFile -Access -RootDirectory $RootDirectoryPath
                    # Return devices that could not be accessed from the noAccess folder
                    # Only contiue if files exist
                    Build-PPSMWSitePages -Access -RootPath $RootDirectoryPath
                    $Stop++
                    Start-Sleep -Seconds ($Minutes*60)
                    
                    # Print count to file
                    $Count = [PSCustomObject] @{
                        
                        LoopIteration = $Stop
                    }
                    Set-Content -Value ($Count | ConvertTo-Json) -Path "$RootDirectoryPath\Count.json"

                }until($Stop -eq $StopAfter)
            }
            else{
            
                Get-PPSMWRemoteDataToFile -Access -RootDirectory $RootDirectoryPath
                # Return devices that could not be accessed from the noAccess folder
                # Only contiue if files exist
                Build-PPSMWSitePages -RootPath $RootDirectoryPath
            }
        }
        else{
        
            if ($Continuous){
            
                do{

                    Get-PPSMWRemoteDataToFile -RootDirectory $RootDirectoryPath
                    # Return devices that could not be accessed from the noAccess folder
                    # Only contiue if files exist
                    Build-PPSMWSitePages -RootPath $RootDirectoryPath
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
            
                Get-PPSMWRemoteDataToFile -RootDirectory $RootDirectoryPath
                # Return devices that could not be accessed from the noAccess folder
                # Only contiue if files exist
                Build-PPSMWSitePages -RootPath $RootDirectoryPath
            }
        }

    #endregion
}