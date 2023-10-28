<#
.SYNOPSIS
    Create folders.

.DESCRIPTION
    Create folders needed for the PowerShell website.

.PARAMETER DirectoryPath
    Specify the path of the directory or leave as default. Default will be the directory structure created by IIS.

.PARAMETER Force
    Specify this parameter to create the directories and copy files regardless if already existing.

.EXAMPLE
    Set-Folders

.EXAMPLE
    Set-Folders -DirectoryPath '/var/www/html/dash'

.NOTES
    Any improvements welcome.
#>

function Set-Folders {
    
    [CmdletBinding()]
    param(
        [String]$RootDirectoryPath='C:\inetpub\wwwroot\dash',
        [Switch]$Force
    )

    #region SCRIPT

        if (-not (Test-Path $RootDirectoryPath -or $Force)){
    
            # Create root directory path
            Write-Verbose "Creating directory path: $RootDirectoryPath"
            New-Item -Path $RootDirectoryPath -ItemType Directory | Out-Null

            # Create sub directories
            New-Item -Path "RootDirectoryPath\pages\single" -ItemType Directory
            New-Item -Path "RootDirectoryPath\pages\virtualhosts" -ItemType Directory
            New-Item -Path "RootDirectoryPath\referenceData\single" -ItemType Directory
            New-Item -Path "RootDirectoryPath\referenceData\vm" -ItemType Directory
            New-Item -Path "RootDirectoryPath\referenceData\vhost" -ItemType Directory
            New-Item -Path "RootDirectoryPath\style" -ItemType Directory
            New-Item -Path "RootDirectoryPath\style\font" -ItemType Directory
            New-Item -Path "RootDirectoryPath\style\images" -ItemType Directory
            New-Item -Path "RootDirectoryPath\template" -ItemType Directory

            # Copy files
                # Copy CSS from the modules folder
                # Copy templates from the modules folder
        }

    #endregion
}