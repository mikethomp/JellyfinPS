function Invoke-JellyfinApiRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$JellyfinHost,
        [Parameter(Mandatory = $true)][string]$ApiKey,
        [Parameter()][hashtable]$Query,
        [Parameter()][switch]$SkipCertificateCheck
    )

    # Normalize host (ensure https:// is present)
    if ($JellyfinHost -notmatch '^https?://') {
        $BaseUri = "https://$JellyfinHost"
    } else {
        $BaseUri = $JellyfinHost.TrimEnd('/')
    }
    
    # Build query string
    $queryParams = @{}
    if ($Query) {
        $queryParams += $Query
    }

    # Always include API key
    $queryParams['api_key'] = $ApiKey

    $queryString = ($queryParams.GetEnumerator() | ForEach-Object {
        "$($_.Key)=$([System.Web.HttpUtility]::UrlEncode($_.Value))"
    }) -join '&'

    $uri = "$BaseUri/$($Path.TrimStart('/'))"
    if ($queryString) {
        $uri = "$($uri)?$($queryString)"
    }

    Write-Verbose $uri

    try {
        $response = Invoke-RestMethod -Uri $uri -SkipCertificateCheck:$SkipCertificateCheck
        return $response
    }
    catch {
        throw "Jellyfin API request failed: $($_.Exception.Message)"
    }
}