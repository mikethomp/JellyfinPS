<#
.SYNOPSIS
Retrieves seasons for a specified Jellyfin show.

.DESCRIPTION
Queries the Jellyfin API to retrieve all seasons associated with a given show.
Optionally, results can be scoped to a specific user, to include playback-related
fields such as watched status or resume position.

The function calls the Jellyfin /Shows/{Id}/Seasons endpoint and returns the season items.

.PARAMETER ShowId
The unique identifier of the Jellyfin show.

.PARAMETER JellyfinHost
The hostname or IP address of the Jellyfin server (do not include "https://").
For example: jellyfin.local or 192.168.1.10:8096

.PARAMETER ApiKey
The API key used to authenticate with the Jellyfin server. This key must have permission
to query user information.

.PARAMETER UserId
(Optional) The Jellyfin user ID. See Get-JellyfinUser.
When provided, user-specific data such as playback progress and watched status
will be included in the response.

.PARAMETER SkipCertificateCheck
Skips certificate validation checks that include all validations such as expiration, revocation, trusted root authority, etc.

.EXAMPLE
Get-JellyfinSeasons -ShowId "12345" -JellyfinHost "jellyfin.local:8096" -ApiKey "abc123"

Retrieves all seasons for the specified show.

.EXAMPLE
Get-JellyfinSeasons -ShowId "12345" -UserId "user123" -JellyfinHost "192.168.1.50:8096" -ApiKey "abc123"

Retrieves seasons including user-specific metadata such as watched status.
#>
function Get-JellyfinSeasons {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ShowId,
        [Parameter(Mandatory = $true)][string]$JellyfinHost,
        [Parameter(Mandatory = $true)][string]$ApiKey,
        [Parameter(Mandatory = $false)][string]$UserId,
        [Parameter()][switch]$SkipCertificateCheck
    )

    if ($UserId) {
        $Seasons = Invoke-JellyfinApiRequest `
            -Path "Shows/$($ShowId)/Seasons" `
            -JellyfinHost $JellyfinHost `
            -ApiKey $ApiKey `
            -SkipCertificateCheck:$SkipCertificateCheck `
                -Query @{
                userId = $UserId
            }
    }
    else {
        $Seasons = Invoke-JellyfinApiRequest `
            -Path "Shows/$($ShowId)/Seasons" `
            -JellyfinHost $JellyfinHost `
            -ApiKey $ApiKey `
            -SkipCertificateCheck:$SkipCertificateCheck
    }

    return $Seasons.Items

}
