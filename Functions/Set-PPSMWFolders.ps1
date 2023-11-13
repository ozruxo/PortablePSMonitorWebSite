<#
.SYNOPSIS
    Create folders.

.DESCRIPTION
    Create folders needed for the PowerShell website.

.PARAMETER DirectoryPath
    Specify the path of the directory or leave as default. Default will be the directory structure created by IIS.

.PARAMETER Force
    Specify this parameter to create the directories and copy files regardless if already existing.

.PARAMETER SourceFiles
    Specify the directory path of downloaded (module) files.

.EXAMPLE
    Set-PPSMWFolders - SourceFiles '$env:USERPROFILE\Desktop\PortablePSMonitorWebSite'

.EXAMPLE
    Set-PPSMWFolders -DirectoryPath $RootDirectoryPath -SourceFiles '$env:USERPROFILE\Desktop\PortablePSMonitorWebSite'

.NOTES
    Any improvements welcome.
#>

function Set-PPSMWFolders {
    
    [CmdletBinding()]
    param(
        [String]$RootDirectoryPath,
        [Switch]$Force,
        [String]$SourceFiles
    )

    #region SCRIPT

        if (-not(Test-Path $RootDirectoryPath) -or $Force){
    
            # Create root directory path
            Write-Verbose "Creating directory path: $RootDirectoryPath"
            New-Item -Path $RootDirectoryPath -ItemType Directory | Out-Null

            # Create sub directories
            New-Item -Path "$RootDirectoryPath\pages\single" -ItemType Directory
            New-Item -Path "$RootDirectoryPath\pages\virtualhosts" -ItemType Directory
            New-Item -Path "$RootDirectoryPath\referenceData\nonVM" -ItemType Directory
            New-Item -Path "$RootDirectoryPath\referenceData\vm" -ItemType Directory
            New-Item -Path "$RootDirectoryPath\referenceData\vHost" -ItemType Directory
            New-Item -Path "$RootDirectoryPath\referenceData\noAccess" -ItemType Directory
            New-Item -Path "$RootDirectoryPath\referenceData\ping" -ItemType Directory

            # Copy files
            Copy-Item -Path "$SourceFiles\Resources\Style" -Destination "$RootDirectoryPath" -Recurse -Force
            Copy-Item -Path "$SourceFiles\Resources\template" -Destination "$RootDirectoryPath" -Recurse -Force
        }

    #endregion
}