<#
.SYNOPSIS
    Build the required HTML pages.

.DESCRIPTION
    Build the required HTML pages for the site pertaining to the devices being monitored.

.PARAMETER Access
    Specify you have network domain access to client devices.

.PARAMETER RootDirectoryPath
    Specify the root directory path for the website.

.PARAMETER ReferenceDataPath
    Specify the directory path within the website folders, where ther JSON files will be located to reference, for building the webpages.

.PARAMETER PingFolderPath
    Specify the directory path for devices that are only being monitored via Ping.

.PARAMETER NonVMFolderPath
    Specify the directory path for all non VM devices.

.PARAMETER vHostFolderPath
    Specify the folder path for all devices running Hyper-V.

.PARAMETER vHostDevicePagePath
    Specify the path to where the web page for the virtual hosts will be.

.PARAMETER VMFolderPath
    Specify the folder path for all virtual machine devies.

.PARAMETER TemplateFolderName
    Specify the name of the Template folder.

.PARAMETER IndexFileName
    Specify the name of the index file (home page). If changed, the HTML will need to be updated.

.PARAMETER IndividualWebFolderPath
    Specify the directory path for the individual web pages per device.

.PARAMETER IndividualDevicePagePath
    Specify the path for the 'single' web page. Changing this would required updates to the HTML.

.EXAMPLE
    Build-PPSMWSitePages `
    -RootDirectoryPath $env:USERPROFILE\Desktop\web `
    -ReferenceDataPath $ReferenceDataPath `
    -PingFolderPath $PingFolderPath `
    -TemplateFolderName `
    -IndexFileName $IndexFileName

.EXAMPLE
    Build-PPSMWSitePages `
    -Access
    -RootDirectoryPath $env:USERPROFILE\Desktop\web `
    -ReferenceDataPath $ReferenceDataPath `
    -PingFolderPath $PingFolderPath `
    -NonVMFoldPath $NonVMFolderPath `
    -vHostFolderPAth $vHostFolderPath `
    -vHostDevicePagePath $vHostDevicePathPAth `
    -VMFolderPath $VMFolderPath `
    -TemplateFolderName `
    -IndexFileName $IndexFileName `
    -IndividualWebFolderPath $IndividualWebFolderPath `
    -IndividualDevicePagePath $IndividualDeviceFolderPath

.NOTES
    Any improvements welcome.
    If the individual web pages for the devices are not creating. Make sure the module set is imported or check your environment variable paths. The following script creates those pages: Deploy-PPSMWIndividualPage.ps1

.FUNCTIONALITY
    PPSMW build web site
#>

function Build-PPSMWSitePages {

    [CmdletBinding()]
    param(
        [Switch]$Access,
        [Parameter(mandatory=$true)]
        [String]$RootDirectoryPath,
        [Parameter(mandatory=$true)]
        [String]$ReferenceDataPath,
        [Parameter(mandatory=$true)]
        [String]$PingFolderPath,
        [String]$NonVMFolderPath,
        [String]$vHostFolderPath,
        [String]$vHostDevicePagePath,
        [String]$VMFolderPath,
        [Parameter(mandatory=$true)]
        [String]$TemplateFolderName,
        [Parameter(mandatory=$true)]
        [String]$IndexFileName,
        [String]$IndividualWebFolderPath,
        [String]$IndividualDevicePagePath
    )

    #region INITIAL VARIABLES

        $Progress = "- ","\ ","| ","/ "
        $i = 0

    #endregion

    #region SCRIPT
    
        if ($Access){
            
            # Deploy index page. Has all systems
            Deploy-PPSMWIndex `
            -RootDirectoryPath $RootDirectoryPath `
            -NonVMFolderPath $NonVMFolderPath `
            -vHostFolderPath $vHostFolderPath `
            -VMFolderPath $VMFolderPath `
            -TemplateFolderName $TemplateFolderName `
            -IndexFileName $IndexFileName

            # Deploy single page. Has all system
            Deploy-PPSMWSingle `
            -RootDirectoryPath $RootDirectoryPath `
            -NonVMFolderPath $NonVMFolderPath `
            -vHostFolderPath $vHostFolderPath `
            -VMFolderPath $VMFolderPath `
            -TemplateFolderName $TemplateFolderName `
            -IndividualDevicePagePath $IndividualDevicePagePath

            # Deploy individual pages for more detailed pages
            Write-Verbose "Checking for non vm files to set individual page"
            $FilesFromNonVMDir = Get-ChildItem -Path $NonVMFolderPath
            if ($FilesFromNonVMDir.Count -gt 0){

                foreach ($NonVM in $FilesFromNonVMDir) {

                    Write-Verbose "Setting non vm individual page"
                    Start-Job -Name $NonVM.Name -ArgumentList $NonVM.FullName,$IndividualWebFolderPath,$RootDirectoryPath,$TemplateFolderName -ScriptBlock {
                
                        $PathToFile              = $args[0]
                        $IndividualWebFolderPath = $args[1]
                        $RootDirectoryPath       = $args[2]
                        $TemplateFolderName      = $args[3]

                        Deploy-PPSMWIndividualPage `
                        -PathToFile $PathToFile `
                        -IndividualWebFolderPath $IndividualWebFolderPath `
                        -RootDirectoryPath $RootDirectoryPath `
                        -TemplateFolderName $TemplateFolderName
                    } | Out-Null
                }
            }
            else{

                Write-Verbose "No non vm files for individual page"
            }

            # Deploy vhost page if applicable
            Write-Verbose "Checking for vhost files to set individual page"
            $FilesFromvHostDir = Get-ChildItem -Path $vHostFolderPath
            if ($FilesFromvHostDir.Count -gt 0){

                foreach ($vHost in $FilesFromvHostDir){

                    Write-Verbose "Setting vhost individual page"

                    Start-Job -Name $vHost.Name -ArgumentList $vHost.FullName,$IndividualWebFolderPath,$RootDirectoryPath,$TemplateFolderName -ScriptBlock {

                        $PathToFile              = $args[0]
                        $IndividualWebFolderPath = $args[1]
                        $RootDirectoryPath       = $args[2]
                        $TemplateFolderName      = $args[3]

                        Deploy-PPSMWIndividualPage `
                        -PathToFile $PathToFile `
                        -IndividualWebFolderPath $IndividualWebFolderPath `
                        -RootDirectoryPath $RootDirectoryPath `
                        -TemplateFolderName $TemplateFolderName
                    } | Out-Null
                }
                
                Write-Verbose "Setting vhost host page"
                Deploy-PPSMWvHostPage `
                -PathToFiles $vHostFolderPath `
                -vHostDevicePagePath $vHostDevicePagePath `
                -RootDirectoryPath $RootDirectoryPath `
                -TemplateFolderName $TemplateFolderName `
                -VMFolderPath $VMFolderPath
            }
            else {

                Write-Verbose "No vhost files for individual page"
            }

            # Deploy individual pages for more detailed pages
            Write-Verbose "Checking for vm files to set individual page"
            $FilesFromvmDir = Get-ChildItem -Path $VMFolderPath
            if ($FilesFromvmDir.Count -gt 0){

                foreach ($VM in $FilesFromvmDir){

                    Write-Verbose "Setting vm individaul page"
                    Start-Job -Name $VM.Name -ArgumentList $VM.FullName,$IndividualWebFolderPath,$RootDirectoryPath,$TemplateFolderName -ScriptBlock {

                        $PathToFile              = $args[0]
                        $IndividualWebFolderPath = $args[1]
                        $RootDirectoryPath       = $args[2]
                        $TemplateFolderName      = $args[3]

                        Deploy-PPSMWIndividualPage `
                        -PathToFile $PathToFile `
                        -IndividualWebFolderPath $IndividualWebFolderPath `
                        -RootDirectoryPath $RootDirectoryPath `
                        -TemplateFolderName $TemplateFolderName
                    } | Out-Null
                }
            }
        }
        else{

            Write-Verbose "Get device data from ping folder"
            $FilesFromPingDir = Get-ChildItem -Path $PingFolderPath
            
            if ($FilesFromPingDir.Count -gt 0){

                # Deploy index page
                Write-Verbose "Deploy index page"
                Deploy-PPSMWIndex `
                -RootDirectoryPath $RootDirectoryPath `
                -PingOnly `
                -PingFolderPath $PingFolderPath `
                -TemplateFolderName $TemplateFolderName `
                -IndexFileName $IndexFileName
            }
        }

        # End all jobs when complete
        Write-Output "Finishing up building web pages"
        do{
            
            Write-Verbose "Removing completed jobs"
            # Set variable
            $Jobs = Get-Job

            foreach ($Job in $Jobs){
            
                # Remove successful job
                if ($Job.State -eq 'Completed'){
                
                    Write-Verbose "Job Completed. Removing"
                    Remove-Job -InstanceId $Job.InstanceId
                }
                # Remove failed job
                elseif ($Job.State -eq 'Failed'){

                    Write-Verbose "$($Job.Name) failed"
                    Remove-Job -InstanceID $Job.InstanceId
                }
                # Print verbose on unknown job status
                elseif($Job.State -ne 'Completed' -and $Job.State -ne 'Failed'){
                
                    Write-Verbose "Id: $($Job.Id) | Name: $($Job.Name) | State: $($Job.State) | HasMoreData: $($Job.HasMoreData)"
                }
            }
            if($PSVersionTable.PSVersion.Major -ge 7){
                        
                Write-Host -NoNewline "`r$($Progress[$i])" ;if ($i -eq 3){$i = 0}else{$i++}
            }
            Start-Sleep -Milliseconds 500
        }until($Jobs.count -eq 0)

    #endregion

}