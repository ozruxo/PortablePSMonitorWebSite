function Deploy-PPSMWIndex {

    param(
        [String]$RootDirectoryPath,
        [Switch]$PingOnly,
        [String]$PingFolderPath,
        [String]$NonVMFolderPath,
        [String]$vHostFolderPath,
        [String]$VMFolderPath,
        [String]$TemplateFolderName,
        [String]$IndexFileName
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
            $Devices = Get-ChildItem -Path $PingFolderPath
            $PrintPage.Add((Get-Content $TemplateStartPing)) | Out-Null

            foreach ($Device in $Devices){
            
                $PrintPage.Add((Set-IndexHTML -Device (Get-Content $Device.FullName | ConvertFrom-Json))) | Out-Null
            }

            $PrintPage.Add((Get-Content $TemplateEnd)) | Out-Null
            Set-Content -Value $PrintPage -Path $HTMLPagePath
        }
        else{

            Write-Verbose "Writing index page with permissions"
            $Devices = Get-ChildItem -Path $NonVMFolderPath,$vHostFolderPath,$VMFolderPath
            $PrintPage.Add((Get-Content $TemplateStart)) | Out-Null
            
            foreach ($Device in $Devices){
            
                $PrintPage.Add((Set-IndexHTML -Permission -Device (Get-Content $Device.FullName | ConvertFrom-Json))) | Out-Null
            }

            $PrintPage.Add((Get-Content $TemplateEnd)) | Out-Null
            Set-Content -Value $PrintPage -Path $HTMLPagePath
        }

    #endregion

}