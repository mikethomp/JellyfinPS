<#
.SYNOPSIS
Retrieves a Jellyfin media library by name.

.DESCRIPTION
Queries the Jellyfin API to retrieve available media libraries (media folders)
and returns the library that matches the specified name.

The function calls the Jellyfin /Library/MediaFolders endpoint and performs
client-side filtering to locate the requested library.

.PARAMETER LibraryName
The name of the Jellyfin media library to retrieve. This value must match
the library name as configured in Jellyfin.

.PARAMETER JellyfinHost
The hostname or IP address of the Jellyfin server (do not include "https://").
For example: jellyfin.local or 192.168.1.10:8096

.PARAMETER ApiKey
The API key used to authenticate with the Jellyfin server. This key must have permission
to query user information.

.PARAMETER SkipCertificateCheck
Skips certificate validation checks that include all validations such as expiration, revocation, trusted root authority, etc.

.EXAMPLE
Get-JellyfinLibrary -LibraryName "Movies" -JellyfinHost "jellyfin.local:8096" -ApiKey "abc123"

Retrieves the "Movies" media library from the Jellyfin server.
#>
function Get-JellyfinLibrary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$LibraryName,
        [Parameter(Mandatory = $true)][string]$JellyfinHost,
        [Parameter(Mandatory = $true)][string]$ApiKey,
        [Parameter()][switch]$SkipCertificateCheck
    )

    $Libraries = Invoke-JellyfinApiRequest `
        -Path "Library/MediaFolders" `
        -JellyfinHost $JellyfinHost `
        -ApiKey $ApiKey `
        -SkipCertificateCheck:$SkipCertificateCheck
    
    return ($Libraries.Items | Where-Object { $_.Name -eq $LibraryName })

}
