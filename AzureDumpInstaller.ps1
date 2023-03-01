<#
    Much of this was taken from 
    https://github.com/mandiant/flare-vm

    Installation Script For tools needed to run AzureDump

             To execute this script:
          1) Open PowerShell window as administrator
          2) Allow script execution by running command "Set-ExecutionPolicy Unrestricted"
          3) Unblock the install script by running "Unblock-File .\install.ps1"
          4) Execute the script by running ".\install.ps1"

          https://github.com/Ocel0tSec/AzureDump
#>

if (-not $noChecks.IsPresent) {
    # Ensure script is ran as administrator
    Write-Host "[+] Checking if script is running as administrator..."
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-Not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "`t[!] Please run this script as administrator" -ForegroundColor Red
        Read-Host "Press any key to exit..."
        exit 1
    } else {
        Write-Host "`t[+] Running as administrator" -ForegroundColor Green
        Start-Sleep -Milliseconds 500
    }
}
    # Ensure execution policy is unrestricted
    Write-Host "[+] Checking if execution policy is unrestricted..."
    if ((Get-ExecutionPolicy).ToString() -ne "Unrestricted") {
        Write-Host "`t[!] Please run this script after updating your execution policy to unrestricted" -ForegroundColor Red
        Write-Host "`t[-] Hint: Set-ExecutionPolicy Unrestricted" -ForegroundColor Yellow
        Read-Host "Press any key to exit..."
        exit 1
    } else {
        Write-Host "`t[+] Execution policy is unrestricted" -ForegroundColor Green
        Start-Sleep -Milliseconds 500
    }

# Check Chocolatey and Boxstarter versions
$boxstarterVersionGood = $false
$chocolateyVersionGood = $false
if(${Env:ChocolateyInstall} -and (Test-Path "${Env:ChocolateyInstall}\bin\choco.exe")) {
    $version = choco --version
    $chocolateyVersionGood = [System.Version]$version -ge [System.Version]"0.10.13"
    choco info -l -r "boxstarter" | ForEach-Object { $name, $version = $_ -split '\|' }
    $boxstarterVersionGood = [System.Version]$version -ge [System.Version]"3.0.0"
}

# Install Chocolatey and Boxstarter 
if (-not ($chocolateyVersionGood -and $boxstarterVersionGood)) {
    Write-Host "[+] Installing Boxstarter..." -ForegroundColor Cyan
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://boxstarter.org/bootstrapper.ps1'))
    Get-Boxstarter -Force

    # Fix verbosity issues with Boxstarter v3
    # See: https://github.com/chocolatey/boxstarter/issues/501
    $fileToFix = "${Env:ProgramData}\boxstarter\boxstarter.chocolatey\Chocolatey.ps1"
    $offendingString = 'if ($val -is [string] -or $val -is [boolean]) {'
    if ((Get-Content $fileToFix -raw) -contains $offendingString) {
        $fixString = 'if ($val -is [string] -or $val -is [boolean] -or $val -is [system.management.automation.actionpreference]) {'
        ((Get-Content $fileToFix -raw) -replace [regex]::escape($offendingString),$fixString) | Set-Content $fileToFix
    }
    $fileToFix = "${Env:ProgramData}\boxstarter\boxstarter.chocolatey\invoke-chocolatey.ps1"
    $offendingString = 'Verbose           = $VerbosePreference'
    if ((Get-Content $fileToFix -raw) -contains $offendingString) {
        $fixString = 'Verbose           = ($global:VerbosePreference -eq "Continue")'
        ((Get-Content $fileToFix -raw) -replace [regex]::escape($offendingString),$fixString) | Set-Content $fileToFix
    }
    Start-Sleep -Milliseconds 500
}
Import-Module "${Env:ProgramData}\boxstarter\boxstarter.chocolatey\boxstarter.chocolatey.psd1" -Force

# Make `refreshenv` available right away, by defining the $env:ChocolateyInstall
# variable and importing the Chocolatey profile module.
# Note: Using `. $PROFILE` instead *may* work, but isn't guaranteed to.
$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."   
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"

# refreshenv is now an alias for Update-SessionEnvironment
# (rather than invoking refreshenv.cmd, the *batch file* for use with cmd.exe)
# This should make git.exe accessible via the refreshed $env:PATH, so that it
# can be called by name only.
refreshenv

#Install Python, go, and git, RoadRecon currently requires python3.8 to function
choco install -y git
choco install golang -y
choco install -y python --version=3.8.0
py -m pip install --upgrade pip

#Creates a floder on your desktop where it installs the tools and then installs them
cd "\Users\$([Environment]::UserName)\Desktop"
New-Item -Path "C:\Users\$([Environment]::UserName)\Desktop\AzureTools" -ItemType directory
cd AzureTools

#Install NuGet
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Installs Azure Modules 
Write-Host "`Installing Modules" -ForegroundColor Cyan
Install-Module -Name Az -Repository PSGallery -Force
Install-Module -Name AADInternals -Force
Install-Module -Name PSWSMan -Force
Install-Module -Name ExchangePowerShell -Force
Install-Module -Name ExchangeOnlineManagement -Force
Install-Module -Name MSOnline -Force
Install-Module -Name PowerShellGet -Force
Install-Module -Name ImportExcel -Force
Start-Sleep -Milliseconds 500
Write-Host "`t[+] Modules Installed" -ForegroundColor Green

#Installs Azure CLI
Write-Host "`Installing Azure CLI" -ForegroundColor Cyan
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
Start-Sleep -Milliseconds 500
Write-Host "`t[+] Azure CLI installed" -ForegroundColor Green

#Refresh enviornment variables 
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")


#Installs AzureHound
Write-Host "`Installing AzureHound" -ForegroundColor Cyan
git clone https://github.com/BloodHoundAD/AzureHound.git
cd AzureHound
go build -ldflags="-s -w -X github.com/bloodhoundad/azurehound/constants.Version=$(git describe tags --exact-match 2> $null -or git rev-parse HEAD)"
Start-Sleep -Milliseconds 500
Write-Host "`t[+] AzureHound Installed" -ForegroundColor Green

#Installs RoadRecon
Write-Host "`Installing RoadRecon" -ForegroundColor Cyan
py -m pip install roadrecon
cd "\Users\$([Environment]::UserName)\Desktop\AzureTools"
Start-Sleep -Milliseconds 500
Write-Host "`t[+] RoadRecon Installed" -ForegroundColor Green

#Installs PowerZure
Write-Host "`Installing PowerZure" -ForegroundColor Cyan
git clone https://github.com/hausec/PowerZure.git
Start-Sleep -Milliseconds 500
Write-Host "`t[+] PowerZure Installed" -ForegroundColor Green

#Installs Crowdstrike Reporting Tool
Write-Host "`Installing CrowdStrike Reporting Tool" -ForegroundColor Cyan
git clone https://github.com/CrowdStrike/CRT.git
Start-Sleep -Milliseconds 500
Write-Host "`t[+] CRT Installed" -ForegroundColor Green

Read-Host -Prompt "Complete! Press enter to exit"
