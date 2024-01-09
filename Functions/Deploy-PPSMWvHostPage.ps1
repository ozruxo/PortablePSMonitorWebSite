<#
.SYNOPSIS
    Create web page for virtual hosts.

.DESCRIPTION
    Create web page for virtual hosts.

.PARAMETER PathToFiles
    Specify directory path to virtual host JSON files.

.PARAMETER vHostDevicePagePath
    Specify the file path for the virtual host page.

.PARAMETER RootDirectoryPath
    Specify the root directory path for the website.

.PARAMETER TemplateFolderName
    Specify the name of the template folder.

.PARAMETER VMFolderPath
    Specify the directory path to the virtual machine JSON files.

.EXAMPLE
    Deploy-PPSMWvHostPage `
    -PathToFiles $PathToFiles `
    -vHostDevicePagePath $vHostDevicePagePath `
    -RootDirectoryPath $RootDirectoryPath `
    -TemplateFolderName $TemplateFolderName `
    -VMFolderPath $VMFolderPath

.NOTES
    Any improvements welcome.

.FUNCTIONALITY
    PPSMW build web site
#>

function Deploy-PPSMWvHostPage {

    [CmdletBinding()]
    param(
        [Parameter(mandatory=$true)]
        [String]$PathToFiles,
        [Parameter(mandatory=$true)]
        [String]$vHostDevicePagePath,
        [Parameter(mandatory=$true)]
        [String]$RootDirectoryPath,
        [Parameter(mandatory=$true)]
        [String]$TemplateFolderName,
        [Parameter(mandatory=$true)]
        [String]$VMFolderPath
    )

    #region INITIAL VARIABLES

        $HTMLPagePath  = "$vHostDevicePagePath.html"
        $PrintPage     = [System.Collections.ArrayList]::New()
        $TemplateStart = "$RootDirectoryPath\$TemplateFolderName\vHostStart.html"
        $TemplateEnd   = "$RootDirectoryPath\$TemplateFolderName\vHostEnd.html"

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
            $IPsMatch         = [System.Collections.ArrayList]::New()
            $IPsDontMatch     = [System.Collections.ArrayList]::New()
            $AllvHostFiles    = Get-ChildItem -Path $PathToFiles
            $VMs              = Get-ChildItem -Path $PathToVMs
            $OnlineImage      = 'azure-vms-icon-2048x1891.png'
            $OfflineImage     = 'x.png'

            # Create website refernce data
            foreach($vHost in $AllvHostFiles){

                # Reset variable
                $IPsMatch     = [System.Collections.ArrayList]::New()
                $IPsDontMatch = [System.Collections.ArrayList]::New()

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
                # This doesn't work well with VM's that have more than one IP
                $vHostIps = $DeviceProperties.VMIPs

                # Generate listings for Virtual machines
                foreach ($IP in $vHostIps){

                    if ($VMs){
                        
                        foreach ($VM in $VMs){

                            $VMContent = Get-Content -Path $VM.FullName | ConvertFrom-Json

                            if ($VMContent.NetworkInfo.IPAddress -match $IP){

                                $IPsMatch.Add($VMContent) | Out-Null
                            }
                            else{
                                
                                $IPsDontMatch.Add($IP) | Out-Null
                            }
                        }
                        # Clean up listing for virtual machines
                        $GetUnique = $IPsDontMatch | Select-Object -Unique
                        $DontMatchListing = [System.Collections.ArrayList]::New()
                        foreach($GU in $GetUnique){

                            $DontMatchListing.Add($GU) | Out-Null
                        }
                        :one foreach ($IPM in $IPsMatch){
                        
                            foreach($DontML in $DontMatchListing){

                                if ($IPM.NetworkInfo.IPAddress -eq $DontML){

                                    $DontMatchListing.Remove("$($IPM.NetworkInfo.IPAddress)") | Out-Null
                                    break :one
                                }
                            }
                        }
                    }
                    else{

                        if ($DontMatchListing){
                            
                            Remove-Variable -Name DontMatchListing
                        }
                        $DontMatchListing = $vHostIps
                    }
                }

                if ($DontMatchListing){

                    foreach ($DML in $DontMatchListing){
                        
                        # If Additional IP's don't match
                        $VMCustomObject = [PSCustomObject]@{
                            Name       = $DML
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

                # Create list of VMs to print
                foreach ($IPM in $IPsMatch){
    
                    if ([int]$IPM.OSDiskPerc -ge 15){
    
                        $DiskStatus = 'gooddisk'
                    }
                    else {
    
                        $DiskStatus = 'baddisk'
                    }
    
                    $VMCustomObject = [PSCustomObject]@{
                        Name       = $IPM.Name
                        Status     = 'online'
                        DiskPerc   = $IPM.OSDiskPerc
                        Usercount  = $IPM.UserCount
                        Access     = 'access'
                        DiskStatus = $DiskStatus
                        vHost      = $vHostName
                    }
                    $AllVMs.Add($VMCustomObject) | Out-Null
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
                        <div class="HName"><a class="hostLink" href="individual/$($AvH.Name).html">$($AvH.Name)</a></div>
                        <img class="image" tabindex="1" src="../style/images/server_$($AvH.Color).svg">
                        <div class="Hinfo">
                            <div>OS Disk available: $($AvH.DiskPerc)%</div>
                            <div>RAM available : $($AvH.RAMGB)GB</div>
"@
                $PieceTogether.Add($vHostStart) | Out-Null

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
                foreach ($AVM in $AllVMs){

                    if ($AVM.Status -eq 'online'){
                        
                        $Image = $OnlineImage
                    }
                    else{
                        
                        $Image = $OfflineImage
                    }
                    if ($AVM.vHost -eq $AvH.Name){

                        $vHostVM01 = @"
                    <div class="vmobject">
                        <div class="statusbar">
                            <div class="statusindicator $($AVM.Status)"></div>
                            <div class="statusindicator $($AVM.Access)"></div>
                            <div class="statusindicator $($AVM.DiskStatus)"></div>
                        </div>
"@
                        $PieceTogether.Add($vHostVM01) | Out-Null
                        if ($AVM.Status -eq 'offline'){
                        
                            $vHostVM02 = @"
                        <div class="VName"><a class="vmLink" href="error/404.html">$($AVM.Name)</a></div>
"@
                        }
                        else{

                            $vHostVM02 = @"
                        <div class="VName"><a class="vmLink" href="individual/$($AVM.Name).html">$($AVM.Name)</a></div>
"@
                        }
                        $PieceTogether.Add($vHostVM02) | Out-Null
                        $vHostVM03 = @"
                        <img class="vimage" tabindex="1" src="../style/images/$Image">
                        <div class="info">
                            <div>OS Disk available: $($AVM.DiskPerc)%</div>
                            <div>Users on VM : $($AVM.UserCount)</div>
                        </div>
                    </div>
"@
                        $PieceTogether.Add($vHostVM03) | Out-Null
                    }
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
