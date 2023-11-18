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
            $FilesFromNonVMDir = Get-ChildItem -Path $NonVMFolderPath
            if ($FilesFromNonVMDir.Count -gt 0){

                foreach ($NonVM in $FilesFromNonVMDir) {

                    Start-Job -Name $NonVM.Name -ArgumentList $NonVM.FullName,$IndividualWebFolderPath,$RootDirectoryPath,$TemplateFolderName -ScriptBlock {
                
                        $PathToFile              = $args[0]
                        $IndividualWebFolderPath = $args[1]
                        $RootDirectoryPath       = $args[2]
                        $TemplateFolderName      = $args[3]

                        Deploy-PPSMWIndividaulPage `
                        -PathToFile $PathToFile `
                        -IndividualWebFolderPath $IndividualWebFolderPath `
                        -RootDirectoryPath $RootDirectoryPath `
                        -TemplateFolderName $TemplateFolderName
                    }
                }
            }

            # Deploy vhost page if applicable
            $FilesFromvHostDir = Get-ChildItem -Path $vHostFolderPath
            if ($FilesFromvHostDir.Count -gt 0){

                foreach ($vHost in $FilesFromvHostDir){

                    Start-Job -Name $vHost.Name -ArgumentList $vHost.FullName,$IndividualWebFolderPath,$RootDirectoryPath,$TemplateFolderName -ScriptBlock {

                        $PathToFile              = $args[0]
                        $IndividualWebFolderPath = $args[1]
                        $RootDirectoryPath       = $args[2]
                        $TemplateFolderName      = $args[3]

                        Deploy-PPSMWIndividaulPage `
                        -PathToFile $PathToFile `
                        -IndividualWebFolderPath $IndividualWebFolderPath `
                        -RootDirectoryPath $RootDirectoryPath `
                        -TemplateFolderName $TemplateFolderName
                    }
                }
                Deploy-PPSMWvHostPage `
                -PathToFiles $vHostFolderPath `
                -vHostDevicePagePath $vHostDevicePagePath `
                -RootDirectoryPath $RootDirectoryPath `
                -TemplateFolderName $TemplateFolderName `
                -VMFolderPath $VMFolderPath
            }

            # Deploy individual pages for more detailed pages
            $FilesFromvmDir = Get-ChildItem -Path $VMFolderPath
            if ($FilesFromvmDir.Count -gt 0){

                foreach ($VM in $FilesFromvmDir){

                    Start-Job -Name $VM.Name -ArgumentList $NonVM.FullName,$IndividualWebFolderPath,$RootDirectoryPath,$TemplateFolderName -ScriptBlock {

                        $PathToFile              = $args[0]
                        $IndividualWebFolderPath = $args[1]
                        $RootDirectoryPath       = $args[2]
                        $TemplateFolderName      = $args[3]

                        Deploy-PPSMWIndividaulPage `
                        -PathToFile $PathToFile `
                        -IndividualWebFolderPath $IndividualWebFolderPath `
                        -RootDirectoryPath $RootDirectoryPath `
                        -TemplateFolderName $TemplateFolderName
                    }
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