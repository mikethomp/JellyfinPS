<#
.SYNOPSIS
Retrieves metadata for a Jellyfin media item via the API.

.DESCRIPTION
Fetches detailed metadata for a specific Jellyfin item using the Jellyfin REST API.

.PARAMETER ItemId
The unique identifier of the Jellyfin item to retrieve metadata for.

.PARAMETER UserId
The Jellyfin user ID. See Get-JellyfinUser.

.PARAMETER JellyfinHost
The hostname or IP address of the Jellyfin server (do not include "https://").
For example: jellyfin.local or 192.168.1.10:8096

.PARAMETER ApiKey
The API key used to authenticate with the Jellyfin server.

.EXAMPLE
$metadata = Get-JellyfinMetadata -ItemId "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -UserId "user123-uuid-here"
-JellyfinHost "localhost:8096" `
-ApiKey "your-api-key-here"

.NOTES
Requires an API key with read access to the library.

#>
function Get-JellyfinMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ItemId,
        [Parameter(Mandatory = $true)][string]$UserId,
        [Parameter(Mandatory = $true)][string]$JellyfinHost,
        [Parameter(Mandatory = $true)][string]$ApiKey
    )

    $Metadata = Invoke-JellyfinApiRequest `
        -Path "Users/$($UserId)/Items/$($ItemId)" `
        -JellyfinHost $JellyfinHost `
        -ApiKey $ApiKey `
        -SkipCertificateCheck:$SkipCertificateCheck
    
    return $Metadata

}