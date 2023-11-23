<#
.SYNOPSIS
    Create folders.

.DESCRIPTION
    Create folders needed for the PowerShell website.

.PARAMETER RootDirectoryPath
    Specify the directory path for the root of the website.

.PARAMETER Force
    Specify this parameter to create the directories and copy files regardless if already existing.

.PARAMETER SourceFiles
    Specify the directory to which the source files exist. This will be from the module set. You will want the template and css files if you want it to look a little pretty.

.PARAMETER IndividualWebFolderPath
    Specify the directory path for the individual JSON files.

.PARAMETER NoAccessFolderPath
    Specify the directory path for the no access folder.

.PARAMETER NonVMFolderPath
    Specify the directory path fo the non vm device JSON files.

.PARAMETER PingFolderPath
    Specify the directory path for the ping only JSON files.

.PARAMETER vHostFolderPath
    Specify the directory path for the virtual host JSON files.

.PARAMETER VMFolderPath
    Specify the directory path for the virtual machine JSON files.

.PARAMETER RefMediaFolderPath
    Specify the directory path for the CSS and other media to be copied over to website from source files.

.PARAMETER RefTemplateFolderPath
    Specify the folder path for the template directory.

.PARAMETER ErrorFolderPath
    Specify the folder path for 404 page.

.EXAMPLE
    Set-PPSMWFolders - SourceFiles '$env:USERPROFILE\Desktop\PortablePSMonitorWebSite'

.EXAMPLE
    Set-PPSMWFolders -DirectoryPath $RootDirectoryPath -SourceFiles '$env:USERPROFILE\Desktop\PortablePSMonitorWebSite'

.NOTES
    Any improvements welcome.

.FUNCTIONALITY
    PPSMW build web site
#>

function Set-PPSMWFolders {
    
    [CmdletBinding()]
    param(
        [Parameter(mandatory=$true)]
        [String]$RootDirectoryPath,
        [Switch]$Force,
        [Parameter(mandatory=$true)]
        [String]$SourceFiles,
        [Parameter(mandatory=$true)]
        [String]$IndividualWebFolderPath,
        [Parameter(mandatory=$true)]
        [String]$NoAccessFolderPath,
        [Parameter(mandatory=$true)]
        [String]$NonVMFolderPath,
        [Parameter(mandatory=$true)]
        [String]$PingFolderPath,
        [Parameter(mandatory=$true)]
        [String]$vHostFolderPath,
        [Parameter(mandatory=$true)]
        [String]$VMFolderPath,
        [Parameter(mandatory=$true)]
        [String]$RefMediaFolderPath,
        [Parameter(mandatory=$true)]
        [String]$RefTemplateFolderPath,
        [Parameter(mandatory=$true)]
        [String]$ErrorFolderPath
    )

    #region SCRIPT

        if (-not(Test-Path $RootDirectoryPath) -or $Force){
    
            # Create root directory path
            Write-Verbose "Creating directory path: $RootDirectoryPath"
            New-Item -Path $RootDirectoryPath -ItemType Directory | Out-Null

            # Create sub directories
            New-Item -Path $IndividualWebFolderPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
            New-Item -Path $NoAccessFolderPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
            New-Item -Path $vHostFolderPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
            New-Item -Path $NonVMFolderPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
            New-Item -Path $ErrorFolderPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
            New-Item -Path $PingFolderPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
            New-Item -Path $VMFolderPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

            # Copy files
            Copy-Item -Path "$SourceFiles\$RefMediaFolderPath" -Destination "$RootDirectoryPath" -Recurse -Force -ErrorAction SilentlyContinue
            Copy-Item -Path "$SourceFiles\$RefTemplateFolderPath" -Destination "$RootDirectoryPath" -Recurse -Force -ErrorAction SilentlyContinue

            # Move file
            Move-Item -Path "$RootDirectoryPath\template\404.html" -Destination "$ErrorFolderPath" -ErrorAction SilentlyContinue
        }

    #endregion
}