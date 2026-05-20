<#
.SYNOPSIS
Updates metadata for a Jellyfin media item via the API.

.DESCRIPTION
Sends a POST request to the Jellyfin server to update metadata fields for a specific item.
The Metadata object is converted to JSON and sent to the Jellyfin REST API endpoint.

.PARAMETER ItemId
The unique identifier of the Jellyfin item to update.

.PARAMETER Metadata
A PSCustomObject containing the metadata fields and values to update (e.g., Name, Overview, Tags).

.PARAMETER JellyfinHost
The hostname or IP address of the Jellyfin server (do not include "https://").
For example: jellyfin.local or 192.168.1.10:8096

.PARAMETER ApiKey
The API key used to authenticate with the Jellyfin server.

.EXAMPLE
$metadata = Get-JellyfinMetadata -ItemId "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -UserId "user123-uuid-here" `
    -JellyfinHost "localhost:8096" -ApiKey "your-api-key-here"
$metadata.Name = "New Name"
Set-JellyfinMetadata -ItemId "a1b2c3d4-e5f6-7890-abcd-ef1234567890" -Metadata $metadata `
    -JellyfinHost "localhost:8096" -ApiKey "your-api-key-here"

.NOTES
Requires an API key with metadata editing permissions. The function returns $null on success.

#>
function Set-JellyfinMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ItemId,
        [Parameter(Mandatory = $true)][PSCustomObject]$Metadata,
        [Parameter(Mandatory = $true)][string]$JellyfinHost,
        [Parameter(Mandatory = $true)][string]$ApiKey
    )

    Invoke-WebRequest `
        -UseBasicParsing `
        -Uri "$($JellyfinHost)/Items/$($ItemId)?api_key=$($ApiKey)" `
        -Method POST -ContentType "application/json" `
        -Body ($Metadata | ConvertTo-Json -Depth 100) | Out-Null
    
    return $null
}