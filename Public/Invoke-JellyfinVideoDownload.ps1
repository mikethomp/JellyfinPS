<#
.SYNOPSIS
Downloads and reconstructs a Jellyfin video stream into a local MP4 file.

.DESCRIPTION
Invoke-JellyfinVideoDownload connects to a Jellyfin server, requests an HLS
(m3u8) transcoded stream for a specified media item, downloads all required
playlist segments, and merges them into a single MP4 file using ffmpeg.

.PARAMETER VideoId
The Jellyfin media item ID to download.

.PARAMETER OutputDirectory
The directory where temporary segment files and the final MP4 file
will be stored.

If the directory does not exist, it will be created automatically.

.PARAMETER JellyfinHost
The hostname or IP address of the Jellyfin server (do not include "https://").
For example: jellyfin.local or 192.168.1.10:8096

.PARAMETER ApiKey
The API key used to authenticate with the Jellyfin server. This key must have permission
to query user information.

.PARAMETER Bitrate
The maximum bitrate in bits per second for transcoding.

.PARAMETER SkipCertificateCheck
Skips certificate validation checks that include all validations such as expiration, revocation, trusted root authority, etc.

.EXAMPLE
Invoke-JellyfinVideoDownload `
    -VideoId "7f8fcbf8fef34f2ea0fd13c3d9b6e111" `
    -OutputDirectory "D:\Downloads" `
    -JellyfinHost "jellyfin.example.com" `
    -ApiKey "YOUR_API_KEY"

.NOTES
Requirements:
- ffmpeg must be installed and available in PATH

Temporary Files:
- Segment files are stored in the output directory during processing
- Temporary files are automatically removed after completion

Transcoding:
- Media is requested as an HLS stream using Jellyfin transcoding
- Final MP4 is rebuilt losslessly with ffmpeg stream copy mode

Error Handling:
- Segment downloads are retried up to 5 times
- Failed downloads trigger cleanup of partial files
#>
function Invoke-JellyfinVideoDownload {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$VideoId,
        [Parameter(Mandatory = $true)][string]$OutputDirectory,
        [Parameter(Mandatory = $true)][string]$JellyfinHost,
        [Parameter(Mandatory = $true)][string]$ApiKey,
        [Parameter()][int]$Bitrate = 1500000,
        [Parameter()][switch]$SkipCertificateCheck
    )

    # Convert the VideoId to a UUID
    $VideoUUID = ($VideoId -replace '(.{8})(.{4})(.{4})(.{4})(.{12})', '$1-$2-$3-$4-$5')

    # Normalize the OutputDirectory
    if (!(Test-Path $OutputDirectory)) {
        New-Item -Path $OutputDirectory -ItemType Directory | Out-Null
    }
    $OutputDirectoryObject = Get-Item $OutputDirectory

    # Calculate the Bitrates
    if ($Bitrate -lt 720000) {
        $AudioBitrate = 128000
    } else {
        $AudioBitrate = 192000
    }
    if ($AudioBitrate -ge $Bitrate) {
        throw "Bitrate too low!"
    } else {
        $VideoBitrate = $Bitrate - $AudioBitrate
    }

    # Get the m3u8 playlist
    $PlayList = Invoke-JellyfinApiRequest `
        -Path "videos/$($VideoUUID)/main.m3u8" `
        -JellyfinHost $JellyfinHost `
        -ApiKey $ApiKey `
        -SkipCertificateCheck:$SkipCertificateCheck `
        -Query @{
        MediaSourceId               = $VideoId
        VideoCodec                  = 'av1,hevc,h264,vp9'
        AudioCodec                  = 'aac'
        AudioStreamIndex            = '1'
        VideoBitrate                = "$($VideoBitrate)"
        AudioBitrate                = "$($AudioBitrate)"
        MaxFramerate                = '50'
        SegmentContainer            = 'mp4'
        MinSegments                 = '1'
        BreakOnNonKeyFrames         = 'True'
        TranscodingMaxAudioChannels = '2'
        RequireAvc                  = 'false'
        EnableAudioVbrEncoding      = 'true'
        'h264-level'                = '40'
        'h264-videobitdepth'        = '8'
        'h264-profile'              = 'high'
        'av1-profile'               = 'main'
        'av1-rangetype'             = 'SDR'
        'av1-level'                 = '19'
        'vp9-rangetype'             = 'SDR'
        'hevc-profile'              = 'main,main10'
        'hevc-rangetype'            = 'SDR'
        'hevc-level'                = '186'
        'hevc-deinterlace'          = 'true'
        'h264-rangetype'            = 'SDR'
        'h264-deinterlace'          = 'true'
        TranscodeReasons            = 'ContainerBitrateExceedsLimit'
    }
    
    $LocalPlaylist = "$($OutputDirectoryObject.FullName)/$($VideoId).m3u8"
    if (Test-Path $LocalPlaylist) {
        Remove-Item $LocalPlaylist -Force
    }
    
    # Create the local m3u8 file and collect all the URIs
    $Segments = @()
    foreach ($line in ($PlayList -split "`n")) {
        $FileName = $null
        if ($line -match '#EXT-X-MAP:URI="(.+)"') {
            # Media Initialization Section
            $XMap = $matches[1]
            $SegmentUri = "https://$($JellyfinHost)/videos/$($VideoUUID)/$($XMap)"
            Write-Verbose $SegmentUri
            $FileName = "$($OutputDirectoryObject.FullName)/$($VideoId)-$(([uri]$SegmentUri).AbsolutePath | Split-Path -Leaf)"
            Write-Verbose $FileName
            $Segments += [PSCustomObject]@{
                SegmentUri = $SegmentUri
                FileName = $FileName
            }
            "#EXT-X-MAP:URI=`"$($FileName)`"" | Out-File $LocalPlaylist -Append
        } elseif ($line -match "^hls1/main/\d+.mp4") {
            # Video Segment
            $SegmentUri = "https://$($JellyfinHost)/videos/$($VideoUUID)/$($line)"
            Write-Verbose $SegmentUri
            $FileName = "$($OutputDirectoryObject.FullName)/$($VideoId)-$(([uri]$SegmentUri).AbsolutePath | Split-Path -Leaf)"
            Write-Verbose $FileName
            $Segments += [PSCustomObject]@{
                SegmentUri = $SegmentUri
                FileName = $FileName
            }
            $FileName | Out-File $LocalPlaylist -Append
        } elseif ($line -match '^#') {
            # All other m3u8 notations
            $line | Out-File $LocalPlaylist -Append
        }
    }

    # Download the playlist segments
    if ($Segments) {
        try {
            $SegmentNumber = 1
            foreach ($Segment in $Segments) {
                Write-Progress -Activity "Downloading $($VideoId).mp4" `
                    -Status "Segment $($SegmentNumber) of $($Segments.Count)" `
                    -PercentComplete ([int](($SegmentNumber/$Segments.Count) * 100))

                if (!(Test-Path $Segment.FileName)) {
                    foreach ($try in (1..5)) {
                        $PreviousProgressPreference = $ProgressPreference
                        try {
                            $ProgressPreference = 'SilentlyContinue'
                            Invoke-WebRequest $Segment.SegmentUri -OutFile $Segment.FileName -SkipCertificateCheck:$SkipCertificateCheck
                            $ProgressPreference = $PreviousProgressPreference
                            break
                        } catch {
                            $ProgressPreference = $PreviousProgressPreference
                            if ($try -ge 5) {
                                throw $_.Exception.Message
                            } else {
                                Write-Warning $_.Exception.Message
                                Write-Warning "Sleeping..."
                                Start-Sleep -Seconds 10
                            }
                        }
                        $ProgressPreference = $PreviousProgressPreference
                    }
                }
                $SegmentNumber += 1
            }
            Write-Progress -Activity "Downloading $($VideoId).mp4" -Completed
        } catch {
            Write-Progress -Activity "Downloading $($VideoId).mp4" -Completed -ErrorAction SilentlyContinue
            if ($FileName -and (Test-Path $FileName)) {
                Remove-Item $FileName -Force
            }
            throw $_.Exception.Message
        }

        # Merge the segments
        $Output = "$($OutputDirectoryObject.FullName)/$($VideoId).mp4"
        ffmpeg -y -protocol_whitelist file,crypto,tcp,http,https,tls -i $LocalPlaylist -c copy $Output 
            
        $OutputObject = Get-Item $Output
    }

    # Cleanup
    if (Test-Path $LocalPlaylist) {
        Remove-Item $LocalPlaylist -Force
    }
    Get-ChildItem $OutputDirectory -Filter "$($VideoId)*" | Where-Object {
        $_.Name -ne $OutputObject.Name
    } | ForEach-Object { Remove-Item $_ -Force }

    if ($Segments) {
        return $OutputObject
    } else {
        throw "Could not find any segments to download"
    }

}
