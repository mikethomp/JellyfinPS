<#
.SYNOPSIS
Retrieves a Jellyfin user by username.

.DESCRIPTION
Queries the Jellyfin server API and returns user information that matches the specified username.
This function sends a request to the Jellyfin /Users endpoint and filters the results locally
to find the specified user.

.PARAMETER UserName
The name of the Jellyfin user to retrieve. This value must exactly match the user's name
as stored in Jellyfin.

.PARAMETER JellyfinHost
The hostname or IP address of the Jellyfin server (do not include "https://").
For example: jellyfin.local or 192.168.1.10:8096

.PARAMETER ApiKey
The API key used to authenticate with the Jellyfin server. This key must have permission
to query user information.

.PARAMETER SkipCertificateCheck
Skips certificate validation checks that include all validations such as expiration, revocation, trusted root authority, etc.

.EXAMPLE
Get-JellyfinUser -UserName "john" -JellyfinHost "jellyfin.local:8096" -ApiKey "abc123"

Returns the Jellyfin user object for the user named "john".
#>
function Get-JellyfinUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$UserName,
        [Parameter(Mandatory = $true)][string]$JellyfinHost,
        [Parameter(Mandatory = $true)][string]$ApiKey,
        [Parameter()][switch]$SkipCertificateCheck
        
    )

    $Users = Invoke-JellyfinApiRequest `
        -Path "Users" `
        -JellyfinHost $JellyfinHost `
        -ApiKey $ApiKey `
        -SkipCertificateCheck:$SkipCertificateCheck
    
    return ($Users | Where-Object { $_.Name -eq $UserName })

}
