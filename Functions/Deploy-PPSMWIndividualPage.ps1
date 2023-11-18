function Deploy-PPSMWIndividaulPage {

    [CmdletBinding()]
    param(
        [String]$PathToFile,
        [String]$IndividualWebFolderPath,
        [String]$RootDirectoryPath,
        [String]$TemplateFolderName
    )

    #region INITIAL VARIABLES

        $PrintPage     = [System.Collections.ArrayList]::New()
        $DeviceName    = ($PathToFile.Split('\')[-1]).split('.')[0]
        $HTMLPagePath  = "$IndividualWebFolderPath\$DeviceName.html"
        $TemplateEnd   = "$RootDirectoryPath\$TemplateFolderName\individEnd.html"
        $TemplateStart = "$RootDirectoryPath\$TemplateFolderName\individStart.html"

    #endregion

    #region FUNCTIONS

        function Get-Spacing {

            param(
                [int]$MaxLength,
                [int]$MinLength,
                [int]$Specified
            )

            if ($Specified){

                $TotalSpaces = '&nbsp' *$Specified
            }
            else{

                # Calculate the number of spaces needed for formatting
                $Multiplyby = ($MaxLength - $MinLength)
                if ($Multiplyby -lt 0){

                    $Multiplyby = ($MinLength - $MaxLength)
                    $TotalSpaces = '&nbsp' *$Multiplyby
                }
                else{
                
                    $TotalSpaces = '&nbsp' *$Multiplyby
                }
            }

            return $TotalSpaces
        }

        function Set-IndividHTML{

            param(
                [String]$PathToFile
            )

            # variables
            $PieceTogether    = [System.Collections.ArrayList]::New()
            $DeviceProperties = Get-Content -Path $PathToFile | ConvertFrom-Json

            #region Hostname, RAM percentage and OS Disk percentage
            $Print01 = @"
        <div class="termPH"> Hostname </div>
        <div class="termPH"> -------- </div>
        <div> $($DeviceName) </div>
        <div>&nbsp</div>
        <div class="termPH"> RAM Used </div>
        <div class="termPH"> -------- </div>
        <div> $($DeviceProperties.RAMGB)% </div>
        <div>&nbsp</div>
        <div class="termPH"> OS Disk Used </div>
        <div class="termPH"> ------------ </div>
        <div> $($DeviceProperties.OSDiskPerc)% </div>
        <div>&nbsp</div>
"@
            #endregion

            #region Data disk(s)
            $PrintDD01 = [System.Collections.ArrayList]::New()
            foreach ($DD in $DeviceProperties.DataDiskInfo){
            
                $PrintInternalDD01 = @"
<div class="termPH"> DataDisk: $($DD.DiskLetter) </div>
"@
                $PrintDD01.Add($PrintInternalDD01) | Out-Null
            }
            $PrintDD02 = [System.Collections.ArrayList]::New()
            foreach ($DD in $DeviceProperties.DataDiskInfo){
            
                $PrintInternalDD02 = @"
<div class="termPH"> ------------ </div>
"@
                $PrintDD02.Add($PrintInternalDD02) | Out-Null
            }
            $PrintDD03 = [System.Collections.ArrayList]::New()
            $Spaces = Get-Spacing -MaxLength 9 -MinLength ((($DD.DiskPerc).Length))
            foreach ($DD in $DeviceProperties.DataDiskInfo){
            
                $PrintInternalDD03 = @"
<div> $($DD.DiskPerc)% $Spaces </div>
"@
                $PrintDD03.Add($PrintInternalDD03) | Out-Null
            }

            $Print02 = @"
        <div class="inTermFlex">
$PrintDD01
        </div>
        <div class="inTermFlex">
$PrintDD02
        </div>
        <div class="inTermFlex">
$PrintDD03
        </div>
        <div>&nbsp</div>
"@
            #endregion

            #region Users
            $Print03 = @"
        <div class="termPH"> Users </div>
        <div class="termPH"> ----- </div>
        <div> $($DeviceProperties.UserCount) </div>
        <div>&nbsp</div>
"@
            #endregion

            #region Operating System information
            $Spaces = Get-Spacing -MaxLength (($DeviceProperties.OSInfo.Caption).Length - 1)  -MinLength 10
            #-----Version-----#
            $InnerOSPrint01 = @"
<div class="termPH"> OS Version $Spaces </div>
"@
            $InnerOSPrint05 = @"
<div class="termPH"> ---------- $Spaces </div>
"@
            $InnerOSPrint09 = @"
<div> $($DeviceProperties.OSInfo.Caption) </div>
"@
            #-----------------#
            #---BuildNumber---#
            $Spaces = Get-Spacing -MaxLength 10 -MinLength (($DeviceProperties.OSInfo.BuildNumber).Length -1)
            $InnerOSPrint02 = @"
            <div class="termPH"> Build Number </div>
"@
            $InnerOSPrint06 = @"
            <div class="termPH"> ------------ </div>
"@
            $InnerOSPrint10 = @"
            <div> $($DeviceProperties.OSInfo.BuildNumber) $Spaces </div>
"@
            #-----------------#
            #---InstallDate---#
            $Spaces = Get-Spacing -MaxLength (($DeviceProperties.OSInfo.InstallDate).Length - 1 ) -MinLength 12
            $InnerOSPrint03 = @"
            <div class="termPH"> Install Date $Spaces </div>
"@
            $InnerOSPrint07 = @"
            <div class="termPH"> ------------ $Spaces </div>
"@
            $InnerOSPrint11 = @"
            <div> $($DeviceProperties.OSInfo.InstallDate) </div>
"@
            #-----------------#
            #-----LastBoot----#
            $InnerOSPrint04 = @"
            <div class="termPH"> LastBootUpTime </div>
"@
            $InnerOSPrint08 = @"
            <div class="termPH"> -------------- </div>
"@
            $InnerOSPrint12 = @"
            <div> $($DeviceProperties.OSInfo.LastBootupTime) </div>
"@
            #-----------------#
            $Print04 = @"
        <div class="inTermFlex">
$InnerOSPrint01
$InnerOSPrint02
$InnerOSPrint03
$InnerOSPrint04
        </div>
        <div class="inTermFlex">
$InnerOSPrint05
$InnerOSPrint06
$InnerOSPrint07
$InnerOSPrint08
        </div>
        <div class="inTermFlex">
$InnerOSPrint09
$InnerOSPrint10
$InnerOSPrint11
$InnerOSPrint12
        </div>
        <div>&nbsp</div>
"@
        
            #endregion

            #region Hardware info
            #---Manufacture---#
            $Spaces = Get-Spacing -MaxLength 12 -MinLength (($DeviceProperties.Hardware.Manufacturer).Length + 1)
            $InnerHWPrint01 = @"
            <div class="termPH"> Manufacturer </div>
"@
            $InnerHWPrint06 = @"
            <div class="termPH"> ------------ </div>
"@
            $InnerHWPrint11 = @"
            <div> $($DeviceProperties.Hardware.Manufacturer) $Spaces </div>
"@
            #-----------------#
            #------Model------#
            $Spaces = Get-Spacing -MaxLength (($DeviceProperties.Hardware.Model).Length + 1) -MinLength 5
            $InnerHWPrint02 = @"
            <div class="termPH"> Model $Spaces </div>
"@
            $InnerHWPrint07 = @"
            <div class="termPH"> ----- $Spaces </div>
"@
            $InnerHWPrint12 = @"
            <div> $($DeviceProperties.Hardware.Model) </div>
"@
            #-----------------#
            #---SystemFamily--#
            if ([String]::IsNullOrWhiteSpace($DeviceProperties.Hardware.SystemFamily)) {
                $Spaces = Get-Spacing -Specified 14
                $InnerHWPrint03 = @"
            <div class="termPH"> SystemFamily </div>
"@
                $InnerHWPrint08 = @"
            <div class="termPH"> ------------ </div>
"@
                $InnerHWPrint13 = @"
            <div> $Spaces </div>
"@
            }
            else{
                $Spaces = Get-Spacing -MaxLength (($DeviceProperties.Hardware.SystemFamily).Length + 1) -MinLength 12
                $InnerHWPrint03 = @"
            <div class="termPH"> SystemFamily $Spaces </div>
"@
                $InnerHWPrint08 = @"
            <div class="termPH"> ------------ $Spaces </div>
"@
                $InnerHWPrint13 = @"
            <div> $($DeviceProperties.Hardware.SystemFamily) </div>
"@
            }
            #-----------------#
            #---SerialNumber--#
            $Spaces = Get-Spacing -MaxLength 13 -MinLength (($DeviceProperties.Hardware.SerialNumber).Length + 1)
            $InnerHWPrint04 = @"
            <div class="termPH"> Serial Number </div>
"@
            $InnerHWPrint09 = @"
            <div class="termPH"> ------------- </div>
"@
            $InnerHWPrint14 = @"
            <div> $($DeviceProperties.Hardware.SerialNumber) $Spaces </div>
"@
            #-----------------#
            #-------BIOS------#
            $InnerHWPrint05 = @"
            <div class="termPH"> BIOS Version</div>
"@
            $InnerHWPrint10 = @"
            <div class="termPH"> ------------ </div>
"@
            $InnerHWPrint15 = @"
            <div> $($DeviceProperties.Hardware.BIOSVersion) </div>
"@
            #-----------------#
            $Print05 = @"
        <div class="inTermFlex">
$InnerHWPrint01
$InnerHWPrint02
$InnerHWPrint03
$InnerHWPrint04
$InnerHWPrint05
        </div>
        <div class="inTermFlex">
$InnerHWPrint06
$InnerHWPrint07
$InnerHWPrint08
$InnerHWPrint09
$InnerHWPrint10
        </div>
        <div class="inTermFlex">
$InnerHWPrint11
$InnerHWPrint12
$InnerHWPrint13
$InnerHWPrint14
$InnerHWPrint15
        </div>
        <div>&nbsp</div>
"@
        
            #endregion

            #region Processor info
            #----Processor----#
            if (($DeviceProperties.Processor).Count -gt 1){$Spaces = '(x2)'}
            else{$Spaces = Get-Spacing -MaxLength 9 -MinLength (($DeviceProperties.Processor.DeviceID).Length + 1)}
            $InnerProcPrint01 = @"
            <div class="termPH"> Processor </div>
"@
            $InnerProcPrint05 = @"
            <div class="termPH"> --------- </div>
"@
            $InnerProcPrint09 = @"
            <div> $($DeviceProperties.Processor.DeviceID) $Spaces </div>
"@
            #-----------------#
            #-------Name------#
            $Spaces = Get-Spacing -MaxLength (($DeviceProperties.Processor.Name).Length - 1) -MinLength 4
            $InnerProcPrint02 = @"
            <div class="termPH"> Name $Spaces </div>
"@
            $InnerProcPrint06 = @"
            <div class="termPH"> ---- $Spaces </div>
"@
            $InnerProcPrint10 = @"
            <div> Intel(R) Core(TM) i7-10510U CPU @ 1.80GHz </div>
"@
            #-----------------#
            #------Cores------#
            $InnerProcPrint03 = @"
            <div class="termPH"> Cores </div>
"@
            $InnerProcPrint07 = @"
            <div class="termPH"> ----- </div>
"@
            $InnerProcPrint11 = @"
            <div> 2 &nbsp&nbsp&nbsp</div>
"@
            #-----------------#
            #-----Logical-----#
            $InnerProcPrint04 = @"
            <div class="termPH"> Logical Cores </div>
"@
            $InnerProcPrint08 = @"
        <div class="termPH"> ------------- </div>
"@
            $InnerProcPrint12 = @"
            <div> 4 </div>
"@
            #-----------------#
            $Print06 = @"
        <div class="inTermFlex">
$InnerProcPrint01
$InnerProcPrint02
$InnerProcPrint03
$InnerProcPrint04
        </div>
        <div class="inTermFlex">
$InnerProcPrint05
$InnerProcPrint06
$InnerProcPrint07
$InnerProcPrint08
        </div>
        <div class="inTermFlex">
$InnerProcPrint09
$InnerProcPrint10
$InnerProcPrint11
$InnerProcPrint12
        </div>
        <div>&nbsp</div>
"@
            #endregion

            #region Networking
            $Spaces = Get-Spacing -MaxLength (($DeviceProperties.NetworkInfo.Description).Length - 1) -MinLength 15
            #-----Adapter-----#
            $InnerNetPrint01 = @"
            <div class="termPH"> Network Adapter $Spaces </div>
"@
            $InnerNetPrint05 = @"
            <div class="termPH"> --------------- $Spaces </div>
"@
            $InnerNetPrint09 = @"
            <div> $($DeviceProperties.NetworkInfo.Description) </div>
"@
            #-----------------#
            #-------DHCP------#
            $InnerNetPrint02 = @"
            <div class="termPH"> DHCP </div>
"@
            $InnerNetPrint06 = @"
            <div class="termPH"> ---- </div>
"@
            $InnerNetPrint10 = @"
            <div> $($DeviceProperties.NetworkInfo.DHCPEnabled) </div>
"@
            #-----------------#
            #----IPAddress----#
            $Spaces = Get-Spacing -MaxLength (($DeviceProperties.NetworkInfo.IPAddress).Length - 1) -MinLength 9
            $InnerNetPrint03 = @"
            <div class="termPH"> IPAddress $Spaces </div>
"@
            $InnerNetPrint07 = @"
            <div class="termPH"> --------- $spaces </div>
"@
            $InnerNetPrint11 = @"
            <div> $($DeviceProperties.NetworkInfo.IPAddress) </div>
"@
            #-----------------#
            #-------MAC-------#
            $InnerNetPrint04 = @"
            <div class="termPH"> MAC </div>
"@
            $InnerNetPrint08 = @"
            <div class="termPH"> --- </div>
"@
            $InnerNetPrint12 = @"
            <div> $($DeviceProperties.NetworkInfo.MACAddress) </div>
"@
            #-----------------#
            $Print07 = @"
        <div class="inTermFlex">
$InnerNetPrint01
$InnerNetPrint02
$InnerNetPrint03
$InnerNetPrint04
        </div>
        <div class="inTermFlex">
$InnerNetPrint05
$InnerNetPrint06
$InnerNetPrint07
$innerNetPrint08
        </div>
        <div class="inTermFlex">
$InnerNetPrint09
$InnerNetPrint10
$InnerNetPrint11
$InnerNetPrint12
        </div>
"@
            #endregion

            $PieceTogether.Add($Print01) | Out-Null
            $PieceTogether.Add($Print02) | Out-Null
            $PieceTogether.Add($Print03) | Out-Null
            $PieceTogether.Add($Print04) | Out-Null
            $PieceTogether.Add($Print05) | Out-Null
            $PieceTogether.Add($Print06) | Out-Null
            $PieceTogether.Add($Print07) | Out-Null

            return $PieceTogether
        }

    #endregion

    #region SCRIPT
        
        # Put together HTML
        Write-Verbose "Creating Individual page for $DeviceName"
        $PrintPage.Add((Get-Content -Path $TemplateStart)) | Out-Null
        $PrintPage.Add((Set-IndividHTML -PathToFile $PathToFile)) | Out-Null
        $PrintPage.Add((Get-Content -Path $TemplateEnd)) | Out-Null

        # Write to file
        Set-Content -Value $PrintPage -Path $HTMLPagePath

    #endregion
    
}