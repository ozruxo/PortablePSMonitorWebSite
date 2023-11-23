<#
.SYNOPSIS
    Create the 'single' web page.

.DESCRIPTION
    Create the 'single' web page. This page alphabetizes the list of deivces in interger or alphabetical headers.

.PARAMETER RootDirectoryPath
    Specify the root directory of the website.

.PARAMETER NonVMFolderPath
    Specify the directory path of the non virtual machine devices.

.PARAMETER vHostFolderPath
    Specify the directory path of the vitual host devices.

.PARAMETER VMFolderPath
    Specify the directory path of the virtual machine devices.

.PARAMETER TemplateFolderName
    Specify the name of the template folder.

.PARAMETER IndividualDevicePagePath
    Specify the path for the 'single' page. Changing this would required updates to the HTML.

.EXAMPLE
    Deploy-PPSMWSingle `
    -RootDirectoryPath $RootDirectoryPath `
    -NonVMFolderPath $NonVMFolderPath `
    -vHostFolderPath $VMFolderPAth `
    -TemplateFolderName $TemplateFolderName `
    -IndividualDevicePagePath $IndividualDevicePagePath

.NOTES
    Any improvements welcome.

.FUNCTIONALITY
    PPSMW build web site
#>

function Deploy-PPSMWSingle {

    [CmdletBinding()]
    param(
        [Parameter(mandatory=$true)]
        [String]$RootDirectoryPath,
        [Parameter(mandatory=$true)]
        [String]$NonVMFolderPath,
        [Parameter(mandatory=$true)]
        [String]$vHostFolderPath,
        [Parameter(mandatory=$true)]
        [String]$VMFolderPath,
        [Parameter(mandatory=$true)]
        [String]$TemplateFolderName,
        [Parameter(mandatory=$true)]
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
    
                    $FirstPortion = $Device.split('.')[0..2] -join '.'
                }
                else{
                
                    $FirstPortion = $Device.Substring(0,1)
                }
            
                if ($i -eq 0){
            
                    $Compare = $FirstPortion
                    $i++
                }
            
                if($Compare -ne $FirstPortion){
            
                    $PrintCache = $Collect | Select-Object -Unique

                    if ($null -eq $CompareAgain){

                        # I need the first CompareAgain to not match in order to print correctly
                        $CompareAgain = 'FirstObject'
                    }
                    
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
                        foreach ($PTwo in $PrintTwo){
                        
                            $PieceTogether.Add($PTwo) | Out-Null
                        }
                        $PieceTogether.Add($Print3) | Out-Null
                        $Collect = [System.Collections.ArrayList]::New()
                    }
            
                    $CompareAgain = $PrintCache
                    $PrintCache = $null
                }
            
                foreach ($Device2 in $Devices){
                    
                    if ($Device2 -match "^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])$"){
                
                        $SecondPortion = $Device2.split('.')[0..2] -join '.'
                    }
                    else{
                
                        $SecondPortion = $Device2.Substring(0,1)
                    }
            
                    if ($SecondPortion -eq $FirstPortion){
                    
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
            foreach ($PTwo in $PrintTwo){

                $PieceTogether.Add($PTwo) | Out-Null
            }
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