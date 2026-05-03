<#
.SYNOPSIS
Searches for media items in a Jellyfin server.

.DESCRIPTION
Queries the Jellyfin API to search for media items matching the provided search term.
Results can be filtered by media type (Movies, Shows, Playlists) using switches.

If no type switches are specified, the function searches across all supported types.

The function calls the Jellyfin /Items endpoint with recursive search enabled and
returns matching items for the specified user.

.PARAMETER SearchTerm
The text string to search for. This is matched against item names and metadata
within the Jellyfin library.

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

.PARAMETER Movies
When specified, limits the search to movie items.

.PARAMETER Shows
When specified, limits the search to TV series.

.PARAMETER Playlists
When specified, limits the search to playlists.

.PARAMETER SkipCertificateCheck
Skips certificate validation checks that include all validations such as expiration, revocation, trusted root authority, etc.

.EXAMPLE
Search-Jellyfin -SearchTerm "Matrix" -UserId "user123" -JellyfinHost "jellyfin.local:8096" -ApiKey "abc123"

Searches all supported media types for items matching "Matrix".

.EXAMPLE
Search-Jellyfin -SearchTerm "Office" -Movies -UserId "user123" -JellyfinHost "jellyfin.local:8096" -ApiKey "abc123"

Searches only movies for items matching "Office".

.EXAMPLE
Search-Jellyfin -SearchTerm "Favorites" -Playlists -UserId "user123" -JellyfinHost "192.168.1.50:8096" -ApiKey "abc123" -Limit 50

Searches playlists with a reduced result limit.
#>
function Search-Jellyfin {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$SearchTerm,
        [Parameter(Mandatory = $true)][string]$UserId,
        [Parameter(Mandatory = $true)][string]$JellyfinHost,
        [Parameter(Mandatory = $true)][string]$ApiKey,
        [Parameter(Mandatory = $false)][int]$Limit = 100,
        [Parameter()][switch]$Movies,
        [Parameter()][switch]$Shows,
        [Parameter()][switch]$Playlists,
        [Parameter()][switch]$SkipCertificateCheck
    )

    # If no switches are supplied, search everything
    if (!$Movies -and (!$Shows) -and (!$Playlists)) {
        $Movies = $true
        $Shows = $true
        $Playlists = $true
    }

    # Translate the switches into the Jellyfin types
    $ItemTypes = @()
    if ($Movies) {
        $ItemTypes += "Movie"
    }
    if ($Shows) {
        $ItemTypes += "Series"
    }
    if ($Playlists) {
        $ItemTypes += "Playlist"
    }
    
    $SearchResults = Invoke-JellyfinApiRequest `
        -Path "Items" `
        -JellyfinHost $JellyfinHost `
        -ApiKey $ApiKey `
        -SkipCertificateCheck:$SkipCertificateCheck `
        -Query @{
            userId           = $UserId
            limit            = $Limit
            recursive        = 'true'
            searchTerm       = $SearchTerm
            includeItemTypes = $ItemTypes -join ','
        }
        
    return $SearchResults.items

}
