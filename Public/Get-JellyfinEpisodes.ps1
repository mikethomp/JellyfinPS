<#
.SYNOPSIS
Retrieves episodes for a specific Jellyfin show season.

.DESCRIPTION
Queries the Jellyfin API to retrieve all episodes for a given show and season.
Optionally, results can be scoped to a specific user, to include playback-related
fields such as watched status or resume position.

The function calls the Jellyfin /Shows/{Id}/Episodes endpoint and returns the episode items
including media source information.

.PARAMETER ShowId
The unique identifier of the Jellyfin show.

.PARAMETER SeasonId
The unique identifier of the season within the specified show. See Get-JellyfinSeasons.

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

.PARAMETER Limit
(Optional) The maximum number of records to return. Default 100.

.PARAMETER SkipCertificateCheck
Skips certificate validation checks that include all validations such as expiration, revocation, trusted root authority, etc.

.EXAMPLE
Get-JellyfinEpisodes -ShowId "12345" -SeasonId "67890" -JellyfinHost "jellyfin.local:8096" -ApiKey "abc123"

Retrieves all episodes for the specified show and season.

.EXAMPLE
Get-JellyfinEpisodes -ShowId "12345" -SeasonId "67890" -UserId "user123" -JellyfinHost "192.168.1.50:8096" -ApiKey "abc123"

Retrieves episodes including user-specific playback information for the given user.
#>
function Get-JellyfinEpisodes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ShowId,
        [Parameter(Mandatory = $true)][string]$SeasonId,
        [Parameter(Mandatory = $true)][string]$JellyfinHost,
        [Parameter(Mandatory = $true)][string]$ApiKey,
        [Parameter(Mandatory = $false)][string]$UserId,
        [Parameter(Mandatory = $false)][int]$Limit = 100,
        [Parameter()][switch]$SkipCertificateCheck
    )

    if ($UserId) {
        $Episodes = Invoke-JellyfinApiRequest `
            -Path "Shows/$($ShowId)/Episodes" `
            -JellyfinHost $JellyfinHost `
            -ApiKey $ApiKey `
            -SkipCertificateCheck:$SkipCertificateCheck `
            -Query @{
                userId   = $UserId
                seasonId = $SeasonId
                Fields   = 'MediaSources'
                limit    = $Limit
            }
    } else {
        $Episodes = Invoke-JellyfinApiRequest `
            -Path "Shows/$($ShowId)/Episodes" `
            -JellyfinHost $JellyfinHost `
            -ApiKey $ApiKey `
            -SkipCertificateCheck:$SkipCertificateCheck `
            -Query @{
                seasonId = $SeasonId
                Fields   = 'MediaSources'
                limit    = $Limit
            }
    }

    return $Episodes.Items
}
