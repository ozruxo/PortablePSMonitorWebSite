<#
.SYNOPSIS
    Build the index (home) HTML page.

.DESCRIPTION
    Build the index (home) HTML page.

.PARAMETER RootDirectoryPath
    Specify the root directory for the website.

.PARAMETER PingOnly
    Specify the devices will only be monitored with ping.

.PARAMETER PingFolderPath
    Specify the ping directory path.

.PARAMETER NonVMFolderPath
    Specify the directory path for the non virtual machine devices.

.PARAMETER vHostFolderPath
    Specify the directory path for the virtual host devices.

.PARAMETER VMFolderPath
    Specify the directory path for the virtual machine devices.

.PARAMETER TemplateFolderName
    Specify the template folder name.

.PARAMETER IndexFileName
    Specify the index (home) HTML page name. If this changes you will have to update the HTML.

.PARAMETER NoAccessFolderPath
    Specify the directory path for device that can not be reached.

.EXAMPLE
    Deploy-PPSMWIndex `
    -RootDirectoryPath $RootDirectoryPath `
    -NonVMFolderPath $NonVMFolderPath `
    -vHostFolderPath $vHostFolderPath `
    -VMFolderPAth $VMFolderPath `
    -TemplateFolderPath $TemplateFolderPath `
    -IndexFileName $IndexFileName `
    -NoAccessFolderPath $NoAccessFolderPath    

.EXAMPLE
    Deploy-PPSMWIndex `
    -RootDirectoryPath $RootDirectoryPath `
    -PingOnly `
    -PingFolderPath $PingFolderPath `
    -TemplateFolderPath $TemplateFolderPath `
    -IndexFileName $IndexFileName `
    -NoAccessFolderPath $NoAccessFolderPath

.NOTES
    Any improvements welcome.

.FUNCTIONALITY
    PPSMW build web site
#>

function Deploy-PPSMWIndex {

    param(
        [Parameter(mandatory=$true)]
        [String]$RootDirectoryPath,
        [Switch]$PingOnly,
        [String]$PingFolderPath,
        [String]$NonVMFolderPath,
        [String]$vHostFolderPath,
        [String]$VMFolderPath,
        [Parameter(mandatory=$true)]
        [String]$TemplateFolderName,
        [Parameter(mandatory=$true)]
        [String]$IndexFileName,
        [Parameter(mandatory=$true)]
        [String]$NoAccessFolderPath
    )

    #region INITIAL VARIABLES
    
        $PrintPage         = [System.Collections.ArrayList]::New()
        $HTMLPagePath      = "$RootDirectoryPath\$IndexFileName.html"
        $TemplateEnd       = "$RootDirectoryPath\$TemplateFolderName\indexEnd.html"
        $TemplateStart     = "$rootDirectoryPath\$TemplateFolderName\indexStart.html"
        $TemplateStartPing = "$RootDirectoryPath\$TemplateFolderName\indexStartP.html"
        $Devices           = @()

    #endregion

    #region FUNCTIONS

        function Set-IndexHTML {

            param(
                [Array]$Device,
                [Switch]$Permission
            )

            $DeviceName = $Device.Name
            
            if ($Device.Status -eq 'Online'){

                $RNum        = Get-Random (4..6)
                $DeviceColor = "Green$RNum"
                $Message     = "Pingable IP"
            }
            elseif($Device.Status -eq 'NotAccessible'){
            
                $DeviceColor = 'Red'
                $Message     = 'Not Accessible'
            }
            else {
                
                $DeviceColor = 'Red'
                $Message     = 'Not Pingable'
            }

            if ($Permission){
                
                $Print = @"
        <div class="deviceObject device$DeviceColor">
            <div class="deviceName"><a class="deviceLink" href="pages/individual/$($DeviceName).html">$($DeviceName.ToLower())</a></div>
            <div class="hide">$Message</div>
        </div>
"@
            }
            else{

                $Print = @"
        <div class="deviceObject device$DeviceColor">
            <div class="deviceName">$DeviceName</div>
            <div class="hide">$Message</div>
        </div>
"@   
            }
            return $Print
        }

    #endregion

    #region SCRIPT

        if ($PingOnly){

            Write-Verbose "Writing ping only index page"
            $Devices = Get-ChildItem -Path $PingFolderPath,$NoAccessFolderPath
            
            $PrintPage.Add((Get-Content $TemplateStartPing)) | Out-Null

            foreach ($Device in $Devices){
            
                $PrintPage.Add((Set-IndexHTML -Device (Get-Content $Device.FullName | ConvertFrom-Json))) | Out-Null
            }

            $PrintPage.Add((Get-Content $TemplateEnd)) | Out-Null
            Set-Content -Value $PrintPage -Path $HTMLPagePath
        }
        else{

            Write-Verbose "Writing index page with permissions"
            $Devices = Get-ChildItem -Path $NonVMFolderPath,$vHostFolderPath,$VMFolderPath,$NoAccessFolderPath
            $PrintPage.Add((Get-Content $TemplateStart)) | Out-Null
            
            foreach ($Device in $Devices){
            
                $PrintPage.Add((Set-IndexHTML -Permission -Device (Get-Content $Device.FullName | ConvertFrom-Json))) | Out-Null
            }

            $PrintPage.Add((Get-Content $TemplateEnd)) | Out-Null
            Set-Content -Value $PrintPage -Path $HTMLPagePath
        }

    #endregion

}
