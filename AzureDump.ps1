# Read config.json content
$configJsonPath = "C:\Users\$([Environment]::UserName)\Desktop\AzureDump-main\config.json"
$configJson = Get-Content -Path $configJsonPath -Raw | ConvertFrom-Json

# Iterate over the scripts and execute if marked "yes"
foreach ($script in $configJson.scripts) {
    if ($script.run -eq "yes") {
        Write-Host "Executing $($script.name)..." -ForegroundColor Cyan
        . $($script.path)
    }
}
