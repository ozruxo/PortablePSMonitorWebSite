function Build-PPSMWSitePages {

    [CmdletBinding()]
    param(
        [String]$Access,
        [String]$RootDirectoryPath
    )

    #region INITAL VARIABLES

        $DataFilesDir = 'referenceData'
        $PingFolder   = 'ping'
        $NonVMFolder  = 'nonVM'
        $vHostFolder  = 'vHost'
        $VMFolder     = 'vm'

    #endregion

    #region SCRIPT
    
        if ($Access){

            $FilesFromNonVMDir = Get-ChildItem "$RootDirectoryPath\$DataFilesDir\$NonVMFolder"
            $FilesFromvHostDir = Get-ChildItem "$RootDirectoryPath\$DataFilesDir\$vHostFolder"
            $FilesFromvmDir    = Get-ChildItem "$RootDirectoryPath\$DataFilesDir\$VMFolder"

            if (($FilesFromNonVMDir.Count + $FilesFromvHostDir.Count + $FilesFromvmDir.Count) -gt 0 ){
            
                # If files exists (as job)
                    # Deploy index page. Has all systems
                    # Deploy single page. Has all system
                    # Deploy vhost page if applicable
                    # Deploy individual pages for more detailed pages
                # End all jobs when complete

            }
        }
        else{

            $FilesFromPingDir = Get-ChildItem -Path "$RootDirectoryPath\$DataFilesDir\$PingFolder"
            
            if ($FilesFromPingDir.Count -gt 0){

                # If Files exists
                    # Deploy index page
                # End all jobs when complete
            }
        }

    #endregion
        
    "`0"
    Write-Host "You did it!"
}