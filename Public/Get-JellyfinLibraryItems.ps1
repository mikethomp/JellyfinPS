<#
.SYNOPSIS
Retrieves items from a Jellyfin media library.

.DESCRIPTION
Queries the Jellyfin API to retrieve items within a specified media library for a given user.
Results are returned in a paginated format and can be controlled using the Limit and StartIndex
parameters.

The function calls the Jellyfin /Users/{UserId}/Items endpoint and returns the items that are
direct children of the specified library (non-recursive).

.PARAMETER LibraryId
The unique identifier of the Jellyfin media library (parent folder) to query. See Get-JellyfinLibrary.

.PARAMETER UserId
The Jellyfin user ID. See Get-JellyfinUser.

.PARAMETER JellyfinHost
The hostname or IP address of the Jellyfin server (do not include "https://").
For example: jellyfin.local or 192.168.1.10:8096

.PARAMETER ApiKey
The API key used to authenticate with the Jellyfin server. This key must have permission
to query user information.

.PARAMETER Limit
(Optional) The maximum number of records to return. Default 100.

.PARAMETER StartIndex
(Optional) The starting index for pagination. Default is 0.
Use this parameter to retrieve subsequent pages of results.

.PARAMETER SkipCertificateCheck
Skips certificate validation checks that include all validations such as expiration, revocation, trusted root authority, etc.

.EXAMPLE
Get-JellyfinLibraryItems -LibraryId "abcd1234" -UserId "user123" -JellyfinHost "jellyfin.local:8096" -ApiKey "abc123"

Retrieves the first 100 items from the specified library.

.EXAMPLE
Get-JellyfinLibraryItems -LibraryId "abcd1234" -UserId "user123" -JellyfinHost "192.168.1.50:8096" -ApiKey "abc123" -Limit 50 -StartIndex 100

Retrieves the next 50 items starting at index 100 (pagination).
#>
function Get-JellyfinLibraryItems {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$LibraryId,
        [Parameter(Mandatory = $true)][string]$UserId,
        [Parameter(Mandatory = $true)][string]$JellyfinHost,
        [Parameter(Mandatory = $true)][string]$ApiKey,
        [Parameter(Mandatory = $false)][int]$Limit = 100,
        [Parameter(Mandatory = $false)][int]$StartIndex = 0,
        [Parameter()][switch]$SkipCertificateCheck
    )

    $LibraryItems = Invoke-JellyfinApiRequest `
        -Path "Users/$($UserId)/Items" `
        -JellyfinHost $JellyfinHost `
        -ApiKey $ApiKey `
        -SkipCertificateCheck:$SkipCertificateCheck `
        -Query @{
            Recursive  = 'false'
            StartIndex = $StartIndex
            limit      = $Limit
            ParentId   = $LibraryId
        }

    return $LibraryItems.Items

}
