function Deploy-PPSMWSingle {

    [CmdletBinding()]
    param(
        [String]$RootDirectoryPath,
        [String]$NonVMFolderPath,
        [String]$vHostFolderPath,
        [String]$VMFolderPath,
        [String]$TemplateFolderName,
        [String]$IndividualDevicePagePath
    )

    #region INITIAL VARIABLES

        $PrintPage     = [System.Collections.ArrayList]::New()
        $Devices       = (Get-ChildItem -Path $NonVMFolderPath,$vHostFolderPath,$VMFolderPath).BaseName
        $HTMLPagePath  = "$IndividualDevicePagePath.html"
        $TemplateEnd   = "$RootDirectoryPath\$TemplateFolderName\singleEnd.html"
        $TemplateStart = "$RootDirectoryPath\$TemplateFolderName\singleStart.html"

    #endregion

    #region FUNCTIONS

        function Set-SingleHTML {
                
            param(
                [Array]$Devices
            )

            # variables
            $PieceTogether = [System.Collections.ArrayList]::New()
            $SortedObjects = $Devices | Sort-Object
            $collect = [System.Collections.ArrayList]::New()
            $i = 0

            foreach ($Device in $SortedObjects){
                
                if ($Device -match "^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])$"){
    
                    #Write-host "ip0"
                    $FirstPortion = $Device.split('.')[0..2] -join '.'
                }
                else{
                
                    #Write-host "n0"
                    $FirstPortion = $Device.Substring(0,1)
                }
            
                if ($i -eq 0){
            
                    $Compare = $FirstPortion
                    $i++
                }
            
                if($Compare -ne $FirstPortion){
            
                    #Write-host "0.1"
                    $PrintCache = $Collect | Select-Object -Unique
            
                    if (Compare-Object -ReferenceObject $CompareAgain -DifferenceObject $PrintCache -ErrorAction SilentlyContinue){
                    
                        # Reset variable
                        $PrintTwo = [System.Collections.ArrayList]::New()

                        $Print1 = @"
                    <div class="deviceObject">
                        <div class="deviceName" tabindex="1"> $($Compare.ToUpper()) </div>
                        <div>
"@

                        # Loop variable for printing Print2
                        foreach ($PC in $PrintCache){

                            $Print2 = @"
                            <div class="linkName"><a class="deviceLink" href ="individual/$PC.html">$PC</a></div>
"@
                            $PrintTwo.Add($Print2) | Out-Null
                        }

                        $Print3 = @"
                        </div>
                    </div>
"@

                        $PieceTogether.Add($Print1) | Out-Null
                        $PieceTogether.Add([String]$PrintTwo) | Out-Null
                        $PieceTogether.Add($Print3) | Out-Null
                        $Collect = [System.Collections.ArrayList]::New()
                    }
            
                    $CompareAgain = $PrintCache
                    $PrintCache = $null
                }
            
                foreach ($Device2 in $Devices){
                    
                    #write-host "1"
                    if ($Device2 -match "^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])$"){
                
                        #Write-host "1.1"
                        $SecondPortion = $Device2.split('.')[0..2] -join '.'
                    }
                    else{
                
                        #Write-Host "1.2"
                        $SecondPortion = $Device2.Substring(0,1)
                    }
            
                    if ($SecondPortion -eq $FirstPortion){
                    
                        #Write-host "1.3"
                        $Collect.Add($Device2) | Out-Null
                        $Compare = $SecondPortion
                    }
                }
            }

            # Print the last part of the loop
            $Print1 = @"
                    <div class="deviceObject">
                        <div class="deviceName" tabindex="1"> $($Compare.ToUpper()) </div>
                        <div>
"@

            $PrintCache = $collect | Select-Object -Unique
            # Reset Variable
            $PrintTwo = [System.Collections.ArrayList]::New()

            foreach ($PC in $PrintCache){

                $Print2 = @"
                            <div class="linkName"><a class="deviceLink" href ="individual/$PC.html">$PC</a></div>
"@
                $PrintTwo.Add($Print2) | Out-Null
            }
            
            $Print3 = @"
                        </div>
                    </div>
"@

            $PieceTogether.Add($Print1) | Out-Null
            $PieceTogether.Add([String]$PrintTwo) | Out-Null
            $PieceTogether.Add($Print3) | Out-Null

            return $PieceTogether
        }

    #endregion

    #region SCRIPT

        # Put together html
        Write-Verbose "Creating Single page"
        $PrintPage.Add((Get-Content -Path $TemplateStart )) | Out-Null
        $PrintPage.Add((Set-SingleHTML -Devices $Devices)) | Out-Null
        $PrintPage.Add((Get-Content -Path $TemplateEnd )) | Out-Null

        # Write to file
        Set-Content -Value $PrintPage -Path $HTMLPagePath

    #endregion
    
}