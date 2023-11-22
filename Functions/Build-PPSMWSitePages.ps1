function Build-PPSMWSitePages {

    [CmdletBinding()]
    param(
        [Switch]$Access,
        [String]$RootDirectoryPath,
        [String]$ReferenceDataPath,
        [String]$PingFolderPath,
        [String]$NonVMFolderPath,
        [String]$vHostFolderPath,
        [String]$vHostDevicePagePath,
        [String]$VMFolderPath,
        [String]$TemplateFolderName,
        [String]$IndexFileName,
        [String]$IndividualWebFolderPath,
        [String]$IndividualDevicePagePath
    )

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
        do{
            
            Write-Verbose "Removing completed jobs"
            # Set variable
            $Jobs = Get-Job

            foreach ($Job in $Jobs){
            
                # Remove successful job
                if ($Job.State -eq 'Completed'){
                
                    Write-Verbose "Job Completed. Removing"
                    Receive-Job -InstanceId $Job.InstanceId
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
            Start-Sleep -Seconds 1
        }until($Jobs.count -eq 0)

    #endregion

}