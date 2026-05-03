# Import all public and private functions
Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" | ForEach-Object { . $_.FullName }
Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" | ForEach-Object { . $_.FullName }

# Export only public functions
Export-ModuleMember -Function (Get-ChildItem "$PSScriptRoot\Public\*.ps1" | ForEach-Object {
    $_.BaseName
})