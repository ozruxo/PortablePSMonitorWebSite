function Deploy-PPSMWvHostPage {

    [CmdletBinding()]
    param(
        [String]$PathToFiles,
        [String]$vHostDevicePagePath, `
        [String]$RootDirectoryPath,
        [String]$TemplateFolderName,
        [String]$VMFolderPath
    )

    #region INITIAL VARIABLES

        $HTMLPagePath  = "$vHostDevicePagePath.html"
        $PrintPage     = [System.Collections.ArrayList]::New()
        $TemplateStart = "$RootDirectoryPath\$TemplateFolderName\individStart.html"
        $TemplateEnd   = "$RootDirectoryPath\$TemplateFolderName\individEnd.html"

    #endregion

    #region FUNCTIONS

        function Set-vHostHTML {

            param(
                [String]$PathToFiles,
                [String]$PathToVMs
            )

            # Variables
            $AllVMs           = [System.Collections.ArrayList]::New()
            $AllvHosts        = [System.Collections.ArrayList]::New()
            $PieceTogether    = [System.Collections.ArrayList]::New()
            $AllvHostFiles    = Get-ChildItem -Path $PathTofiles
            $OnlineImage      = 'azure-vms-icon-2048x1891.png'
            $OfflineImage     = 'x.png'

            # Create website refernce data
            foreach($vHost in $AllvHostFiles){

                # Get deatils from device
                $DeviceProperties = Get-Content -Path $vHost.FullName | ConvertFrom-Json
                $vHostName        = (($vHost.FullName -split "\\")[-1]).split('.')[0]

                if ([int]$DeviceProperties.OSDiskPerc -ge 15){

                    $vDiskStatus = 'gooddisk'
                }
                else {

                    $vDiskStatus = 'baddisk'
                }

                $vHostCustomObject = [PSCustomObject]@{
                    Name       = $vHostName
                    Status     = 'online'
                    color      = 'green'
                    DiskPerc   = $DeviceProperties.OSDiskPerc
                    RAMGB      = $DeviceProperties.RAMGB
                    Data       = $DeviceProperties.DataDiskInfo
                    Access     = 'access'
                    DiskStatus = $vDiskStatus
                }
                $AllvHosts.Add($vHostCustomObject) | Out-Null

                # Get List of IPs and try to find VM's that match
                $vHostIps = $DeviceProperties.VMIPs

                foreach ($IP in $vHostIps){

                    $VMs = Get-ChildItem -Path $VMFolderPath
                    foreach ($VM in $VMs){

                        $VMContent = Get-Content -Path $VM.FullName | ConvertFrom-Json

                        if ($VMContent.NetworkInfo.IPAddress -match $IP){

                            if ([int]$VMContent.OSDiskPerc -ge 15){

                                $DiskStatus = 'gooddisk'
                            }
                            else {

                                $DiskStatus = 'baddisk'
                            }

                            # Array for VMs
                            $VMCustomObject = [PSCustomObject]@{
                                Name       = (($VM.FullName -split "\\")[-1]).split('.')[0]
                                Status     = 'online'
                                DiskPerc   = $VMContent.OSDiskPerc
                                Usercount  = $VMContent.UserCount
                                Access     = 'access'
                                DiskStatus = $DiskStatus
                                vHost      = $vHostName
                            }
                            $AllVMs.Add($VMCustomObject) | Out-Null
                        }
                        else {

                            # If Additional IP's don't match
                            $VMCustomObject = [PSCustomObject]@{
                                Name       = $IP
                                Status     = 'offline'
                                DiskPerc   = 'N/A'
                                Usercount  = 'N/A'
                                Access     = 'noaccess'
                                DiskStatus = 'baddisk'
                                vHost      = $vHostName
                            }
                            $AllVMs.Add($VMCustomObject) | Out-Null
                        }
                    }
                }
            }

            # Foreach vHost
            foreach ($AvH in $AllvHosts){

                # vHost start
                $vHostStart = @"
        <div class="main">
            <div class="mainHost">
                <H1> Virtual Host </H1>
                <div class="host">
                    <div class="hobject">
                        <div class="hstatusbar">
                            <div class="hstatusindicator $($AvH.Status)"></div>
                            <div class="hstatusindicator $($AvH.Access)"></div>
                            <div class="hstatusindicator $($AvH.DiskStatus)"></div>
                        </div>
                        <div class="HName">$($AvH.Name)</div>
                        <img class="image" tabindex="1" src="../style/images/server_$($AvH.Color).svg">
                        <div class="Hinfo">
                            <div>OS Disk available: $($AvH.DiskPerc)%</div>
                            <div>RAM available : $($AvH.RAMGB)GB</div>
"@
                $PieceTogether.Add($vHostStart)

                # foreach vHost data disks
                foreach ($vDD in $AvH.Data){
                    $vHostDataDisk = @"
                            <div>Disk $($vDD.DiskLetter): available: $($vDD.DiskPerc)%</div>
"@
                    $PieceTogether.Add($vHostDataDisk) | Out-Null
                }

                $PrintMidSection01 = @"
                        </div>
                    </div>
                </div>
            </div>
            <div class="mainVM">
                <H1>VM's</H1>
                <div class="container">
"@
                $PieceTogether.Add($PrintMidSection01) | Out-Null

                # foreach vm
                foreach ($VM in $AllVMs){

                    if ($VM.Status -eq 'online'){
                        
                        $Image = $OnlineImage
                    }
                    else{
                        
                        $Image = $OfflineImage
                    }
                    if ($VM.vHost -eq $AvH.Name){

                        $vHostVM = @"
                    <div class="vmobject">
                        <div class="statusbar">
                            <div class="statusindicator $($VM.Status)"></div>
                            <div class="statusindicator $($VM.Access)"></div>
                            <div class="statusindicator $($VM.DiskStatus)"></div>
                        </div>
                        <div class="VName">$($VM.Name)</div>
                        <img class="vimage" tabindex="1" src="../style/images/$Image">
                        <div class="info">
                            <div>OS Disk available: $($VM.DiskPerc)%</div>
                            <div>Users on VM : $($VM.UserCount)</div>
                        </div>
                    </div>
"@
                    }

                    $PieceTogether.Add($vHostVM) | Out-Null
                }

                $PrintMidSection02 = @"
                </div>
            </div>
            <div class="mainReview">
                <h1>Review</h1>
                <div class="Rcontainer">
"@
                $PieceTogether.Add($PrintMidSection02) | Out-Null

                # foreach review item
                $vHostReview = @"
                    $VMReview
"@
                $PieceTogether.Add($vHostReview) | Out-Null

                $PrintMidSection03 = @"
                </div>
            </div>
        </div>
"@
                $PieceTogether.Add($PrintMidSection03) | Out-Null
            }

            return $PieceTogether
        }

    #region SCRIPT

        # Put together HTML
        Write-Verbose "Creating vHost page"
        $PrintPage.Add((Get-Content -Path $TemplateStart)) | Out-Null
        $PrintPage.Add((Set-vHostHTML -PathToFile $PathToFiles -PathToVMs $VMFolderPath)) | Out-Null
        $PrintPage.Add((Get-Content -Path $TemplateEnd)) | Out-Null

        # Write to file
        Set-Content -Value $PrintPage -Path $HTMLPagePath

    #endregion

}