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

#Sets the execution policy
Set-ExecutionPolicy -Scope CurrentUser Bypass -Force

#Creates another folder where we will dump all of our files
$FolderName = "C:\Users\$([Environment]::UserName)\Desktop\AzFiles"
if (Test-Path $FolderName) {
   
    Write-Host "You've done this before"
    # Perform Delete file from folder operation
}
else
{
  
    #PowerShell Create directory if not exists
    New-Item $FolderName -ItemType Directory
    Write-Host "Folder Created successfully"

}
cd "C:\Users\$([Environment]::UserName)\Desktop\AzFiles"

#Prompt for Azure Active Directory Credentials 

function Get-Creds{
    $azUserName = Read-Host -prompt "Enter your username (User@domain.com)" 
    $azPassword = Read-Host -prompt "Enter password"
        az login -u $azUserName -p $azPassword --allow-no-subscriptions
        }
Get-Creds

#Queries AzAD and creates spreadsheets with app,user,group,vm,service principal info

function Get-AzData{
    az ad app list --query "[].[displayName,appId]" -o tsv > Apps.csv
        Write-Host "Applications Processed"
    az ad app list | findstr ".com" | Sort-Object | Get-Unique > Interesting_com_Urls.txt
    az ad app list | findstr ".org" | Sort-Object | Get-Unique > Interesting_org_Urls.txt
    az ad app list | findstr ".net" | Sort-Object | Get-Unique > Interesting_net_Urls.txt
    az ad app list | findstr ".us" | Sort-Object | Get-Unique > Interesting_us_Urls.txt
    az ad app list | findstr ".io" | Sort-Object | Get-Unique > Interesting_io_Urls.txt
    az ad app list | findstr ".xyz" | Sort-Object | Get-Unique > Interesting_xyz_Urls.txt
    az ad app list | findstr "10." | Sort-Object | Get-Unique > Interesting_10_Urls.txt
    az ad app list | findstr "172." | Sort-Object | Get-Unique > Interesting_172_Urls.txt
    az ad app list | findstr "192." | Sort-Object | Get-Unique > Interesting_192_Urls.txt
        Write-Host "Got Interesting URL's"
    az ad sp list --query "[].[displayName,appOwnerOrganizationId,appId,id]" --all -o tsv > ServicePrincipals.csv
        Write-Host "Service Principals Processed"
    az ad group list --query "[].[displayName,description,onPremisesNetBiosName,onPremisesDomainName,mail,id]" -o tsv > Groups.csv
        Write-Host "Groups Processed"
    az ad user list --query "[].[displayName,mail,businessPhones,mobilePhone,id,jobTitle,officeLocation,givenName,surname,userPrincipalName]" -o tsv > Users.csv
        Write-Host "Users Processed"
        Write-Host "Checking for VM subscription"
    az vm list -o tsv > VMs.csv
        Write-Host "Checking for Storage Account subscription"
    az storage account list -o tsv > StorageAccts.csv
        Write-Host "Checking Key Vaults"
    az keyvault list -o tsv > KeyVaults.csv
    az account list -o tsv > CurrnetAccount.csv
        Write-Host "Azure AD enumeration complete, Attempting MFA Bypass"
        }
Get-AzData

#Get an access token and use it to bypass MFA requirements
function Connect-Account{ 
$token = az account get-access-token --query accessToken --output tsv
    Write-Host $token
$azId = Read-Host -prompt "Enter the id from above (ex: e9c493d3-a879-42d6-beb5-012ec9095552)"
    Write-Host $azId
        Connect-AzAccount -AccessToken $token -AccountId $azId
}
Connect-Account 

#Run Powerzure for basic enumeration checks also tries to grab another token
Write-Host "Running PowerZure"
cd "C:\Users\$([Environment]::UserName)\Desktop\AzureTools\PowerZure"
Import-Module ./PowerZure.psd1
Get-AzureTarget | Out-File "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\TargetInfo.json"

#This opens a window and breaks it if MFA is enabled 
#Get-AADIntAccessTokenForAADGraph -SaveToCache
Write-Host "PowerZure Complete"

#Get the tenant Id and run AzureHound
Function Azure-Hound{
        Write-Host "Enumerating Tenant and running AzureHound"
    $tenant = az account tenant list --query '[].[tenantId]' -o tsv
    Write-Host $tenant
    $graphToken = az account get-access-token --resource-type ms-graph
    Write-Host $graphToken
            cd "C:\Users\$([Environment]::UserName)\Desktop\AzureTools\AzureHound"
    ./azurehound -j $graphToken --tenant $tenant list az-ad
        Write-Host "AzureHound Complete"
        Write-Host "Cleaning up files..."

#Cleans up empty files
}

gci "C:\Users\$([Environment]::UserName)\Desktop\AzFiles" -Recurse | foreach
   if($_.Length -eq 0){
      Write-Output "Removing Empty File $($_.FullName)"
      $_.FullName | Remove-Item -Force
   }
   if( $_.psiscontainer -eq $true){
      if((gci $_.FullName) -eq $null){
         Write-Output "Removing Empty folder $($_.FullName)"
         $_.FullName | Remove-Item -Force
      }
}

#Run RoadRecon
function Road-Recon{
$azUserName = Read-Host -prompt "Enter your username (User@domain.com)" 
$azPassword = Read-Host -prompt "Enter password"
            Write-Host "Running RoadRecon"
    roadrecon auth -u $azUserName -p $azPassword
            Write-Host "Gathering"
    roadrecon gather
            Write-Host "Dumping"
    roadrecon dump
            Write-Host "Checking Policies"
    roadrecon plugin policies
    roadrecon-gui
            Write-Host "RoadRecon Complete, check http://127.0.0.1:5000 for results"
}
Road-Recon

#Get MFA Status of all users
Write-Host "Checking all users for MFA"
Function MFA-Check{
$azUserName = Read-Host -prompt "Enter your username (User@domain.com)" 
$azPassword = Read-Host -prompt "Enter password"
$cred = New-Object -TypeName PSCredential -argumentlist $azUserName, $azPassword
Connect-MsolService -Credential $cred
$Report = @()
$AzUsers = Get-MsolUser -All
ForEach ($AzUser in $AzUsers) {
$DefaultMFAMethod = ($AzUser.StrongAuthenticationMethods | ? { $_.IsDefault -eq "True" }).MethodType
$MFAState = $AzUser.StrongAuthenticationRequirements.State
if ($MFAState -eq $null) {$MFAState = "Disabled"}
$objReport = [PSCustomObject]@{
User = $AzUser.UserPrincipalName
MFAState = $MFAState
MFAPhone = $AzUser.StrongAuthenticationUserDetails.PhoneNumber
MFAMethod = $DefaultMFAMethod
}
$Report += $objReport
}
$Report
#Export to csv
$Report| Export-CSV -NoTypeInformation -Encoding UTF8 "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\AzureUsersMFAstatus.csv"
}
MFA-Check


Read-Host -Prompt "Complete! Press enter to exit"
