$configJsonPath = "config.json"
$configJson = Get-Content -Path $configJsonPath -Raw | ConvertFrom-Json

foreach ($script in $configJson.scripts) {
    if ($script.enabled) {
        Write-Host "Executing $($script.name) from $($script.file)"
        & ".\$($script.file)"
    }
}
