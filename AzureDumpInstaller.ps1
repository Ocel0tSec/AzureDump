#Runs Script as Admin
function Use-RunAs{
	param([Switch]$Check)
	$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
	IF($Check) { return $IsAdmin }
	IF($MyInvocation.ScriptName -ne ""){
		IF(-not $IsAdmin){
			TRY{
				$arg = "-file `"$($MyInvocation.ScriptName)`""
				Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction 'stop'
			}CATCH{
				Write-Warning "Error - Failed RunAs Admin"
				Break
			}
			Exit
		}
	}ELSE{
		Write-Warning "Error - Not a PS1"
		Break
	}
}
Use-RunAs

#Sets the execution policy and installs Chocolatey and python 3.8 which is the version required for roadrecon to function correctly
Set-ExecutionPolicy -Scope CurrentUser Bypass -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install -y git
choco install -y python --version=3.8.0
py -m pip install --upgrade pip

#Creates a floder on your desktop where it installs the tools and then installs them
cd "\Users\$([Environment]::UserName)\Desktop"
New-Item -Path "C:\Users\$([Environment]::UserName)\Desktop\AzureTools" -ItemType directory
cd AzureTools
Install-Module -Name Az -Repository PSGallery -Force
Install-Module -Name AADInternals
Install-Module -Name PSWSMan
Install-Module -Name ExchangePowerShell
Install-Module -Name ExchangeOnlineManagement
Install-Module -Name pip
Install-Module -Name MSOnline
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
Invoke-WebRequest -Uri https://github.com/BloodHoundAD/AzureHound/releases/download/v1.2/azurehound-windows-amd64.zip -OutFile AzureHound.zip
Expand-Archive .\AzureHound.zip
Remove-Item "C:\Users\$([Environment]::UserName)\Desktop\AzureTools\AzureHound.zip" -Recurse
py -m pip install roadrecon
cd "\Users\$([Environment]::UserName)\Desktop\AzureTools"
git clone https://github.com/hausec/PowerZure.git
Read-Host -Prompt "Complete! Press enter to exit"
