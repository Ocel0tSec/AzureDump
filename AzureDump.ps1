<#
    AzureDump

             To execute this script:
          1) Open PowerShell window as administrator
          2) Allow script execution by running command "Set-ExecutionPolicy Unrestricted"
          4) Execute the script by running ".\AzureDump.ps1"

You may be prompted to enter credentials several times
This script requires a browser and is not meant to be used on headless installations

          https://github.com/Ocel0tSec/AzureDump
#>

#Creates another folder where we will dump all of our files
$FolderName = "C:\Users\$([Environment]::UserName)\Desktop\AzFiles"
if (Test-Path $FolderName) { 
    Write-Host "You've done this before"
}
else
{
    #PowerShell Create directory if not exists
    New-Item $FolderName -ItemType Directory
    Write-Host "Folder Created successfully"
}
cd "C:\Users\$([Environment]::UserName)\Desktop\AzFiles"

az login 
#Prompt for Azure Active Directory Credentials 
#function Get-Creds{
#    $azUserName = Read-Host -prompt "Enter your username (User@domain.com)" 
#    $azPassword = Read-Host -prompt "Enter password"
#        az login -u $azUserName -p $azPassword --allow-no-subscriptions
#        }
#Get-Creds

#Queries AzAD and creates spreadsheets with app,user,group,vm,service principal info
function Get-AzData{
    az ad app list --query "[].[displayName,appId]" -o tsv > Apps.csv
        Write-Host "Applications Processed (Press ENTER if this hangs for more than 1 minute)"
    az ad app list | findstr ".com" | Sort-Object | Get-Unique > Interesting_Urls.txt
    az ad app list | findstr ".org" | Sort-Object | Get-Unique >> Interesting_Urls.txt
    az ad app list | findstr ".net" | Sort-Object | Get-Unique >> Interesting_Urls.txt
    az ad app list | findstr ".us" | Sort-Object | Get-Unique >> Interesting_Urls.txt
    az ad app list | findstr ".io" | Sort-Object | Get-Unique >> Interesting_Urls.txt
    az ad app list | findstr ".xyz" | Sort-Object | Get-Unique >> Interesting_Urls.txt
    az ad app list | findstr "10." | Sort-Object | Get-Unique >> Interesting_Urls.txt
    az ad app list | findstr "172." | Sort-Object | Get-Unique >> Interesting_Urls.txt
    az ad app list | findstr "192." | Sort-Object | Get-Unique >> Interesting_Urls.txt
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
    az account list -o tsv > CurrentAccount.csv
        Write-Host "Azure AD enumeration complete, Attempting MFA Bypass"
        }
Get-AzData

#Get an access token and use it to bypass MFA requirements

function PowerShellLogin{
$body = @{
    "client_id" =     "1950a258-227b-4e31-a9cf-717495945fc2"
    "resource" =      "https://graph.microsoft.com"
}
$UserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36"
$Headers=@{}
$Headers["User-Agent"] = $UserAgent
$authResponse = Invoke-RestMethod `
    -UseBasicParsing `
    -Method Post `
    -Uri "https://login.microsoftonline.com/common/oauth2/devicecode?api-version=1.0" `
    -Headers $Headers `
    -Body $body
$authResponse
    Read-Host -Prompt "Sign in using the above URL and enter the code, enter Y when finished to continue"
}
PowerShellLogin

#Pause to authenticate
#Read-Host -Prompt "Sign in using the above URL and enter the code, enter Y when finished to continue"

function GetTokens {
$body=@{
    "client_id" =  "1950a258-227b-4e31-a9cf-717495945fc2"
    "grant_type" = "urn:ietf:params:oauth:grant-type:device_code"
    "code" =       $authResponse.device_code
}
$Tokens = Invoke-RestMethod `
    -UseBasicParsing `
    -Method Post `
    -Uri "https://login.microsoftonline.com/Common/oauth2/token?api-version=1.0" `
    -Headers $Headers `
    -Body $body
$Tokens
}
GetTokens

#Paus to save tokens
Read-Host "Save the refresh token and then enter Y when finished to continue"

#Get the tenant Id and run AzureHound
Function ListTenant{
    az account show
    $graphToken = az account get-access-token --resource-type ms-graph
    Write-Host $graphToken
            cd "C:\Users\$([Environment]::UserName)\Desktop\AzureTools\AzureHound"
    ./azurehound -j $graphToken --tenant $tenant list az-ad
}
ListTenant
Write-Host "Save the Tenant ID and the User ID"

Function CleanFiles{
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
        Write-Host "Cleaning up files..."
   }
}
CleanFiles

Read-Host -Prompt "Open another window and run AzureHound using the TenantID, UserID, and RefreshToken 
        Press Enter to "


#Run CRT (Give it a client code eventually)
cd "C:\Users\$([Environment]::UserName)\Desktop\AzureTools\CRT" 
.\Get-CRTReport.ps1 -JobName ClientName -WorkingDirectory "C:\Users\$([Environment]::UserName)\Desktop\AzFiles"


#Run RoadRecon
function Road-Recon{
$azUserName = Read-Host -prompt "Enter your username (User@domain.com)" 
$azPassword = Read-Host -prompt "Enter password"
            Write-Host "Running RoadRecon"
    roadrecon auth -u $azUserName -p $azPassword
            Write-Host "Gathering"
    roadrecon gather --mfa
            Write-Host "Dumping"
    roadrecon dump
            Write-Host "Checking Policies"
    roadrecon plugin policies
    roadrecon-gui
            Write-Host "RoadRecon Complete, check http://127.0.0.1:5000 for results"
}
Road-Recon

Read-Host -Prompt "Complete! Press enter to exit"
