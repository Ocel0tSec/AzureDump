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

# Install Chocolatey and Boxstarter if needed
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

#Install Python, go, and git, RoadRecon currently requires python3.8 to function
choco install -y git
choco install golang -y
choco install -y python --version=3.8.0
py -m pip install --upgrade pip

#Creates a floder on your desktop where it installs the tools and then installs them
cd "\Users\$([Environment]::UserName)\Desktop"
New-Item -Path "C:\Users\$([Environment]::UserName)\Desktop\AzureTools" -ItemType directory
cd AzureTools

# Installs Azure Modules 
Install-Module -Name Az -Repository PSGallery -Force
Install-Module -Name AADInternals -Force
Install-Module -Name PSWSMan -Force
Install-Module -Name ExchangePowerShell -Force
Install-Module -Name ExchangeOnlineManagement -Force
Install-Module -Name MSOnline -Force

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

#Installs Azure CLI
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

#Installs AzureHound
git clone https://github.com/BloodHoundAD/AzureHound.git
go build -ldflags="-s -w -X github.com/bloodhoundad/azurehound/constants.Version=$(git describe tags --exact-match 2> $null -or git rev-parse HEAD)"

#Invoke-WebRequest -Uri https://github.com/BloodHoundAD/AzureHound/releases/download/v1.2.3/azurehound-windows-amd64.zip -OutFile AzureHound.zip
#Expand-Archive .\AzureHound.zip
#Clean Up
#Remove-Item "C:\Users\$([Environment]::UserName)\Desktop\AzureTools\AzureHound.zip" -Recurse

#Installs RoadRecon
py -m pip install roadrecon
cd "\Users\$([Environment]::UserName)\Desktop\AzureTools"

#Installs PowerZure
git clone https://github.com/hausec/PowerZure.git

#Installs Crowdstrike Reporting Tool
git clone https://github.com/CrowdStrike/CRT.git

Read-Host -Prompt "Complete! Press enter to exit"
