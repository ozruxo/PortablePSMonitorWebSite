<#
.SYNOPSIS
    Create web page for individual devices.

.DESCRIPTION
    Create web page for individual devices.

.PARAMETER PathToFile
    Specify the path to the JSON for the individual device.

.PARAMETER IndividualWebFolderPath
    Specify the individual folder path.

.PARAMETER RootDirectoryPath
    Specify the root directory path for the website.

.PARAMETER TemplateFolderName
    Specify the name of the template folder.

.EXAMPLE
    Deploy-PPSMWIndividualPage `
    -PathToFile $PathToFile `
    -IndividualWebFolderPath $IndividualWebFolderPath `
    -RootDirectoryPath $RootDirectoryPath `
    -TemplateFolderName $TemplateFolderName

.NOTES
    Any improvements welcome.

.FUNCTIONALITY
    PPSMW build web site
#>

function Deploy-PPSMWIndividualPage {

    [CmdletBinding()]
    param(
        [Parameter(mandatory=$true)]
        [String]$PathToFile,
        [Parameter(mandatory=$true)]
        [String]$IndividualWebFolderPath,
        [Parameter(mandatory=$true)]
        [String]$RootDirectoryPath,
        [Parameter(mandatory=$true)]
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

                $TotalSpaces = '&nbsp' * $Specified
            }
            else{

                # Calculate the number of spaces needed for formatting
                $Multiplyby = ($MaxLength - $MinLength)
                if ($Multiplyby -lt 0){

                    $Multiplyby = ($MinLength - $MaxLength)
                    $TotalSpaces = '&nbsp' *$Multiplyby
                }
                else{
                
                    $TotalSpaces = '&nbsp' * $Multiplyby
                }
            }

            return $TotalSpaces
        }

        function Set-RAMDrawing {
        
            param(
                [Int]$Percent
            )
            if($Percent -gt 1){
            
                $LineNumber = [Math]::Ceiling([int]$Percent/10)
            }
            else{
            
                $LineNumber = [Math]::Ceiling([Int]$Percent)
            }
                        
            $DrawLine = "|" * $LineNumber
            if ($LineNumber -ne 10){
            
                $DrawDot  = "." * (10 - $LineNumber)
            }
            else{
            
                $DrawDot = $null
            }

            $DrawBar = $DrawLine + $DrawDot

            return $DrawBar
        }

        function Set-IndividHTML{

            param(
                [String]$PathToFile
            )

            # variables
            $PieceTogether    = [System.Collections.ArrayList]::New()
            $DeviceProperties = Get-Content -Path $PathToFile | ConvertFrom-Json

            #region Hostname, RAM percentage and OS Disk percentage
            
                if($DeviceProperties.DeviceType -eq 'vHost'  -or $DeviceProperties.DeviceType -eq 'nonVM'){
                
                    $RAMPrint = @"
            <div> RAM Avilable : $($DeviceProperties.RAMGB)GB </div>
"@
                }
                else{
                
                    $RAMBar = Set-RAMDrawing -Percent $DeviceProperties.RAMGB
                    $RAMPrint = @"
            <div> RAM Used : $RAMBar ($($DeviceProperties.RAMGB)%)</div>
"@
                }

                $Print01 = @"
            <div> Hostname : $($DeviceName) </div>
            <div> Users    : $($DeviceProperties.UserCount) </div>
            <div>&nbsp</div>
            $RAMPrint
            <div>&nbsp</div>
            <div class="termPH"> OSDiskAvailable </div>
            <div class="termPH"> --------------- </div>
            <div> $($DeviceProperties.OSDiskPerc)% </div>
            <div>&nbsp</div>
"@
            #endregion

            #region Data disk(s)
                
                $PrintDD01 = [System.Collections.ArrayList]::New()
                foreach ($DD in $DeviceProperties.DataDiskInfo){
            
                    $PrintInternalDD01 = @"
                <div class="termPH"> Data: $($DD.DiskLetter) </div>
"@
                    $PrintDD01.Add($PrintInternalDD01) | Out-Null
                }
                $PrintDD02 = [System.Collections.ArrayList]::New()
                foreach ($DD in $DeviceProperties.DataDiskInfo){
            
                    $PrintInternalDD02 = @"
                <div class="termPH"> -------- </div>
"@
                    $PrintDD02.Add($PrintInternalDD02) | Out-Null
                }
                $PrintDD03 = [System.Collections.ArrayList]::New()
                $Spaces = Get-Spacing -MaxLength 5 -MinLength ((($DD.DiskPerc).Length))
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

            #region Operating System information
            
                #-----Version-----#
                $Spaces = Get-Spacing -Specified 6
                $InnerOSPrint01 = @"
            <div> OSVersion $Spaces : $($DeviceProperties.OSInfo.Caption) </div>
"@
                #-----------------#
                #---BuildNumber---#
                $Spaces = Get-Spacing -Specified 4
                $InnerOSPrint02 = @"
            <div> BuildNumber $Spaces : $($DeviceProperties.OSInfo.BuildNumber) </div>
"@

                #-----------------#
                #---InstallDate---#
                $Spaces = Get-Spacing -Specified 4
                $InnerOSPrint03 = @"
            <div> InstallDate $Spaces : $($DeviceProperties.OSInfo.InstallDate) </div>
"@

                #-----------------#
                #-----LastBoot----#
                $Spaces = Get-Spacing -Specified 1
                $InnerOSPrint04 = @"
            <div> LastBootUpTime $Spaces : $($DeviceProperties.OSInfo.LastBootupTime) </div>
"@

                #-----------------#
            $Print03 = @"
$InnerOSPrint01
$InnerOSPrint02
$InnerOSPrint03
$InnerOSPrint04
            <div>&nbsp</div>
"@
        
            #endregion

            #region Hardware info
            
                #---Manufacture---#
                $Spaces = Get-Spacing -Specified 3
                $InnerHWPrint01 = @"
            <div> Manufacturer $Spaces : $($DeviceProperties.Hardware.Manufacturer) </div>
"@

                #-----------------#
                #------Model------#
                $Spaces = Get-Spacing -Specified 10
                $InnerHWPrint02 = @"
            <div> Model $Spaces : $($DeviceProperties.Hardware.Model) </div>
"@

                #-----------------#
                #---SystemFamily--#
                if ([String]::IsNullOrWhiteSpace($DeviceProperties.Hardware.SystemFamily)) {
                
                    $Spaces = Get-Spacing -Specified 3
                    $InnerHWPrint03 = @"
            <div> SystemFamily $Spaces : N/A </div>
"@
                }
                else{
                
                    $Spaces = Get-Spacing -Specified 3
                    $InnerHWPrint03 = @"
            <div> SystemFamily $Spaces : $($DeviceProperties.Hardware.SystemFamily) </div>
"@
                }

                #-----------------#
                #---SerialNumber--#
                $Spaces = Get-Spacing -Specified 3
                $InnerHWPrint04 = @"
            <div> SerialNumber $Spaces : $($DeviceProperties.Hardware.SerialNumber) </div>
"@

                #-----------------#
                #-------BIOS------#
                $Spaces = Get-Spacing -Specified 4
                $InnerHWPrint05 = @"
            <div> BIOSVersion $Spaces : $($DeviceProperties.Hardware.BIOSVersion) </div>
"@

                #-----------------#
                $Print04 = @"
$InnerHWPrint01
$InnerHWPrint02
$InnerHWPrint03
$InnerHWPrint04
$InnerHWPrint05
            <div>&nbsp</div>
"@
        
            #endregion

            #region Processor info
                
                #----Processor----#
                $Spaces = Get-Spacing -Specified 6
                if (($DeviceProperties.Processor).Count -gt 1){
                
                    $InnerProcPrint01 = @"
            <div> Processor $Spaces : $($DeviceProperties.Processor[0].DeviceID) (x2) </div>
"@
                }
                else{
                
                    $InnerProcPrint01 = @"
            <div> Processor $Spaces : $($DeviceProperties.Processor[0].DeviceID) </div>
"@                  
                }

                #-----------------#
                #-------Name------#
                $Spaces = Get-Spacing -Specified 11
                $InnerProcPrint02 = @"
            <div> Name $Spaces : $($DeviceProperties.Processor[0].Name) </div>
"@

                #-----------------#
                #------Cores------#
                $Spaces = Get-Spacing -Specified 10
                $InnerProcPrint03 = @"
            <div> Cores $Spaces : $($DeviceProperties.Processor[0].NumberOfCores) </div>
"@

                #-----------------#
                #-----Logical-----#
                $spaces = Get-Spacing -Specified 3
                $InnerProcPrint04 = @"
            <div> LogicalCores $Spaces : $($DeviceProperties.Processor[0].NumberOfLogicalCores) </div>
"@

                #-----------------#
                $Print05 = @"
$InnerProcPrint01
$InnerProcPrint02
$InnerProcPrint03
$InnerProcPrint04
            <div>&nbsp</div>
"@
            #endregion

            #region Networking

                #-----Adapter-----#
                $Spaces = Get-Spacing -Specified 1
                $InnerNetPrint01 = @"
            <div> NetworkAdapter $Spaces : $($DeviceProperties.NetworkInfo.Description)</div>
"@

                #-----------------#
                #-------DHCP------#
                $Spaces = Get-Spacing -Specified 11
                $InnerNetPrint02 = @"
            <div> DHCP $Spaces : $($DeviceProperties.NetworkInfo.DHCPEnabled) </div>
"@

                #-----------------#
                #----IPAddress----#
                $Spaces = Get-Spacing -Specified 6
                $InnerNetPrint03 = @"
            <div> IPAddress $Spaces : $($DeviceProperties.NetworkInfo.IPAddress) </div>
"@

                #-----------------#
                #-------MAC-------#
                $Spaces = Get-Spacing -Specified 12
                $InnerNetPrint04 = @"
            <div> MAC $Spaces : $($DeviceProperties.NetworkInfo.MACAddress) </div>
"@

                #-----------------#
                $Print06 = @"
$InnerNetPrint01
$InnerNetPrint02
$InnerNetPrint03
$InnerNetPrint04
"@
            #endregion

            $PieceTogether.Add($Print01) | Out-Null
            $PieceTogether.Add($Print02) | Out-Null
            $PieceTogether.Add($Print03) | Out-Null
            $PieceTogether.Add($Print04) | Out-Null
            $PieceTogether.Add($Print05) | Out-Null
            $PieceTogether.Add($Print06) | Out-Null

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
