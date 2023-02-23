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

<#
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
    #Apps that have passwords
    az ad sp list --all --query "[?passwordCredentials != null].displayName" -o tsv PasswordApps.csv
    #Apps that have key creds
    az ad sp list -all --query "[?keyCredentials != null].displayName" -o tsv CredApps.csv
    #Get Conditional Access Policies
    az rest --method GET --uri https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies | ConvertFrom-Json | Export-Excel -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\ConditionalAccessPolicies.xlsx" -WorksheetName "Conditional Access Policies" -AutoSize
        }
Get-AzData
#>

<#
function Get-AzData {
    # Get Apps and save to Apps.csv
    $apps = az ad app list --query "[].[displayName,appId]" -o tsv | ConvertFrom-Csv
    $apps | Export-Excel -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\AzData.xlsx" -WorksheetName "Apps" -AutoSize

    # Get Interesting URLs and save to a separate sheet
    $urls = az ad app list | findstr ".com", ".org", ".net", ".us", ".io", ".xyz", "10.", "172.", "192." | Sort-Object | Get-Unique
    $urls | Export-Excel -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\AzData.xlsx" -WorksheetName "Interesting URLs" -AutoSize

    # Get Service Principals and save to ServicePrincipals.csv
    $servicePrincipals = az ad sp list --query "[].[displayName,appOwnerOrganizationId,appId,id]" --all -o tsv | ConvertFrom-Csv
    $servicePrincipals | Export-Excel -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\AzData.xlsx" -WorksheetName "Service Principals" -AutoSize

    # Get Groups and save to Groups.csv
    $groups = az ad group list --query "[].[displayName,description,onPremisesNetBiosName,onPremisesDomainName,mail,id]" -o tsv | ConvertFrom-Csv
    $groups | Export-Excel -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\AzData.xlsx" -WorksheetName "Groups" -AutoSize

    # Get Users and save to Users.csv
    $users = az ad user list --query "[].[displayName,mail,businessPhones,mobilePhone,id,jobTitle,officeLocation,givenName,surname,userPrincipalName]" -o tsv | ConvertFrom-Csv
    $users | Export-Excel -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\AzData.xlsx" -WorksheetName "Users" -AutoSize

    # Get VMs and save to VMs.csv
    $vms = az vm list -o tsv | ConvertFrom-Csv
    $vms | Export-Excel -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\AzData.xlsx" -WorksheetName "VMs" -AutoSize

    # Get Storage Accounts and save to StorageAccts.csv
    $storageAccts = az storage account list -o tsv | ConvertFrom-Csv
    $storageAccts | Export-Excel -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\AzData.xlsx" -WorksheetName "Storage Accounts" -AutoSize

    # Get Key Vaults and save to KeyVaults.csv
    $keyVaults = az keyvault list -o tsv | ConvertFrom-Csv
    $keyVaults | Export-Excel -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\AzData.xlsx" -WorksheetName "Key Vaults" -AutoSize

    # Get Apps with passwords and save to PasswordApps.csv
    $passwordApps = az ad sp list --all --query "[?passwordCredentials != null].displayName" -o tsv | ConvertFrom-Csv
    $passwordApps | Export-Excel -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\AzData.xlsx" -WorksheetName "Apps with Passwords" -AutoSize

    # Get Apps with key creds and save to CredApps.csv
    $credApps = az ad sp list -all --query "[?keyCredentials != null].displayName" -o tsv | ConvertFrom-Csv
    $credApps | Export-Excel -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\AzData.xlsx" -WorksheetName "Apps with Credentials" -AutoSize

    #Get Conditional Access Policies
    $conditionalAccess = az rest --method GET --uri https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies | ConvertFrom-Json 
    $conditionalAccess | Export-Excel -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\AzData.xlsx" -WorksheetName "Conditional Access Policies" -AutoSize
}
Get-AzData
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

#Login via browser
az login 

#Get variables for the user ID and TennantIDs
$account = az account list | ConvertFrom-Json

$ID = $account.id
$tenantID = $account.tenantId

function Get-AzData {
    # Create a new Excel workbook
    $workbook = New-Object -ComObject Excel.Application
    $workbook.Visible = $true
    $workbook.DisplayAlerts = $false
    $workbook.SheetsInNewWorkbook = 7
    $workbook.Workbooks.Add()
    $worksheetIndex = 1

    # Get Apps and save to worksheet
    $apps = az ad app list --query "[].[displayName,appId]" -o tsv | ConvertFrom-Csv
    $worksheet = $workbook.Worksheets.Item($worksheetIndex)
    $worksheet.Name = "Apps"
    $worksheetIndex += 1
    $worksheet.Cells.Item(1,1).Value2 = "DisplayName"
    $worksheet.Cells.Item(1,2).Value2 = "AppId"
    $rowIndex = 2
    foreach ($app in $apps) {
        $worksheet.Cells.Item($rowIndex,1).Value2 = $app.DisplayName
        $worksheet.Cells.Item($rowIndex,2).Value2 = $app.AppId
        $rowIndex += 1
    }

    # Get Interesting URLs and save to a separate worksheet
    $urls = az ad app list | findstr ".com", ".org", ".net", ".us", ".io", ".xyz", "10.", "172.", "192." | Sort-Object | Get-Unique
    $worksheet = $workbook.Worksheets.Item($worksheetIndex)
    $worksheet.Name = "Interesting URLs"
    $worksheetIndex += 1
    $worksheet.Cells.Item(1,1).Value2 = "Interesting URLs"
    $rowIndex = 2
    foreach ($url in $urls) {
        $worksheet.Cells.Item($rowIndex,1).Value2 = $url
        $rowIndex += 1
    }

    # Get Service Principals and save to worksheet
    $servicePrincipals = az ad sp list --query "[].[displayName,appOwnerOrganizationId,appId,id]" --all -o tsv | ConvertFrom-Csv
    $worksheet = $workbook.Worksheets.Item($worksheetIndex)
    $worksheet.Name = "Service Principals"
    $worksheetIndex += 1
    $worksheet.Cells.Item(1,1).Value2 = "DisplayName"
    $worksheet.Cells.Item(1,2).Value2 = "AppOwnerOrganizationId"
    $worksheet.Cells.Item(1,3).Value2 = "AppId"
    $worksheet.Cells.Item(1,4).Value2 = "Id"
    $rowIndex = 2
    foreach ($servicePrincipal in $servicePrincipals) {
        $worksheet.Cells.Item($rowIndex,1).Value2 = $servicePrincipal.DisplayName
        $worksheet.Cells.Item($rowIndex,2).Value2 = $servicePrincipal.AppOwnerOrganizationId
        $worksheet.Cells.Item($rowIndex,3).Value2 = $servicePrincipal.AppId
        $worksheet.Cells.Item($rowIndex,4).Value2 = $servicePrincipal.Id
        $rowIndex += 1
    }

    # Get Groups and save to worksheet
    $groups = Get-AzADGroup -All:$true | Select-Object DisplayName,Id,Description,Mail,MailNickname,ObjectId,SecurityEnabled
    $worksheet = $workbook.Worksheets.Item($worksheetIndex)
    $worksheet.Name = "Groups"
    $worksheetIndex += 1
    $worksheet.Cells.Item(1,1).Value2 = "DisplayName"
    $worksheet.Cells.Item(1,2).Value2 = "Id"
    $worksheet.Cells.Item(1,3).Value2 = "Description"
    $worksheet.Cells.Item(1,4).Value2 = "Mail"
    $worksheet.Cells.Item(1,5).Value2 = "MailNickname"
    $worksheet.Cells.Item(1,6).Value2 = "ObjectId"
    $worksheet.Cells.Item(1,7).Value2 = "SecurityEnabled"
    $rowIndex = 2
    foreach ($group in $groups) {
        $worksheet.Cells.Item($rowIndex,1).Value2 = $group.DisplayName
        $worksheet.Cells.Item($rowIndex,2).Value2 = $group.Id
        $worksheet.Cells.Item($rowIndex,3).Value2 = $group.Description
        $worksheet.Cells.Item($rowIndex,4).Value2 = $group.Mail
        $worksheet.Cells.Item($rowIndex,5).Value2 = $group.MailNickname
        $worksheet.Cells.Item($rowIndex,6).Value2 = $group.ObjectId
        $worksheet.Cells.Item($rowIndex,7).Value2 = $group.SecurityEnabled
        $rowIndex += 1
    }

    # Get VMs and save to worksheet
    $resourceGroups = az group list --query "[].name" -o tsv
    $worksheet = $workbook.Worksheets.Item($worksheetIndex)
    $worksheet.Name = "VMs"
    $worksheetIndex += 1
    $worksheet.Cells.Item(1,1).Value2 = "Name"
    $worksheet.Cells.Item(1,2).Value2 = "ResourceGroup"
    $worksheet.Cells.Item(1,3).Value2 = "Location"
    $rowIndex = 2
    foreach ($resourceGroup in $resourceGroups) {
        $vms = az vm list --resource-group $resourceGroup --query "[].[name,resourceGroup,location]" -o tsv | ConvertFrom-Csv
        foreach ($vm in $vms) {
            $worksheet.Cells.Item($rowIndex,1).Value2 = $vm.Name
            $worksheet.Cells.Item($rowIndex,2).Value2 = $vm.ResourceGroup
            $worksheet.Cells.Item($rowIndex,3).Value2 = $vm.Location
            $rowIndex += 1
        }
    }

    # Get Users and save to worksheet
    $users = az ad user list --query "[].{DisplayName:displayName,Mail:mail,BusinessPhones:businessPhones,MobilePhone:mobilePhone,Id:id,JobTitle:jobTitle,OfficeLocation:officeLocation,GivenName:givenName,Surname:surname,UserPrincipalName:userPrincipalName}" -o tsv | ConvertFrom-Csv
    $worksheet = $workbook.Worksheets.Item($worksheetIndex)
    $worksheet.Name = "Users"
    $worksheetIndex += 1
    $worksheet.Cells.Item(1,1).Value2 = "DisplayName"
    $worksheet.Cells.Item(1,2).Value2 = "Mail"
    $worksheet.Cells.Item(1,3).Value2 = "BusinessPhones"
    $worksheet.Cells.Item(1,4).Value2 = "MobilePhone"
    $worksheet.Cells.Item(1,5).Value2 = "Id"
    $worksheet.Cells.Item(1,6).Value2 = "JobTitle"
    $worksheet.Cells.Item(1,7).Value2 = "OfficeLocation"
    $worksheet.Cells.Item(1,8).Value2 = "GivenName"
    $worksheet.Cells.Item(1,9).Value2 = "Surname"
    $worksheet.Cells.Item(1,10).Value2 = "UserPrincipalName"
    $rowIndex = 2
    foreach ($user in $users) {
        $worksheet.Cells.Item($rowIndex,1).Value2 = $user.DisplayName
        $worksheet.Cells.Item($rowIndex,2).Value2 = $user.Mail
        $worksheet.Cells.Item($rowIndex,3).Value2 = $user.BusinessPhones
        $worksheet.Cells.Item($rowIndex,4).Value2 = $user.MobilePhone
        $worksheet.Cells.Item($rowIndex,5).Value2 = $user.Id
        $worksheet.Cells.Item($rowIndex,6).Value2 = $user.JobTitle
        $worksheet.Cells.Item($rowIndex,7).Value2 = $user.OfficeLocation
        $worksheet.Cells.Item($rowIndex,8).Value2 = $user.GivenName
        $worksheet.Cells.Item($rowIndex,9).Value2 = $user.Surname
        $worksheet.Cells.Item($rowIndex,10).Value2 = $user.UserPrincipalName
        $rowIndex += 1
    }

    # Get Storage Accounts and save to worksheet
    $storageAccounts = Get-AzStorageAccount
    $worksheet = $workbook.Worksheets.Item($worksheetIndex)
    $worksheet.Name = "Storage Accounts"
    $worksheetIndex += 1
    $worksheet.Cells.Item(1,1).Value2 = "Name"
    $worksheet.Cells.Item(1,2).Value2 = "Resource Group"
    $worksheet.Cells.Item(1,3).Value2 = "Location"
    $worksheet.Cells.Item(1,4).Value2 = "Account Kind"
    $worksheet.Cells.Item(1,5).Value2 = "SKU Name"
    $rowIndex = 2
    foreach ($storageAccount in $storageAccounts) {
        $worksheet.Cells.Item($rowIndex,1).Value2 = $storageAccount.StorageAccountName
        $worksheet.Cells.Item($rowIndex,2).Value2 = $storageAccount.ResourceGroupName
        $worksheet.Cells.Item($rowIndex,3).Value2 = $storageAccount.Location
        $worksheet.Cells.Item($rowIndex,4).Value2 = $storageAccount.Kind
        $worksheet.Cells.Item($rowIndex,5).Value2 = $storageAccount.Sku.Name
        $rowIndex += 1

    }
    # Get Key Vaults and save to worksheet
    $keyVaults = Get-AzKeyVault | Select-Object Name, ResourceGroupName, Location
    $worksheet = $workbook.Worksheets.Item($worksheetIndex)
    $worksheet.Name = "Key Vaults"
    $worksheetIndex += 1
    $worksheet.Cells.Item(1,1).Value2 = "Name"
    $worksheet.Cells.Item(1,2).Value2 = "ResourceGroupName"
    $worksheet.Cells.Item(1,3).Value2 = "Location"
    $rowIndex = 2
    foreach ($keyVault in $keyVaults) {
        $worksheet.Cells.Item($rowIndex,1).Value2 = $keyVault.Name
        $worksheet.Cells.Item($rowIndex,2).Value2 = $keyVault.ResourceGroupName
        $worksheet.Cells.Item($rowIndex,3).Value2 = $keyVault.Location
        $rowIndex += 1
    }


    # Get Apps and save to worksheet
    $apps = az ad app list --query "[].[displayName,appId]" -o tsv | ConvertFrom-Csv
    $passwordApps = az ad sp list --all --query "[?passwordCredentials != null].displayName" -o tsv | ConvertFrom-Csv
    $credApps = az ad sp list -all --query "[?keyCredentials != null].displayName" -o tsv | ConvertFrom-Csv
    $worksheet = $workbook.Worksheets.Item($worksheetIndex)
    $worksheet.Name = "Apps"
    $worksheetIndex += 1
    $worksheet.Cells.Item(1,1).Value2 = "DisplayName"
    $worksheet.Cells.Item(1,2).Value2 = "AppId"
    $worksheet.Cells.Item(1,3).Value2 = "HasPassword"
    $worksheet.Cells.Item(1,4).Value2 = "HasCredentials"
    $rowIndex = 2
    foreach ($app in $apps) {
        $worksheet.Cells.Item($rowIndex,1).Value2 = $app.DisplayName
        $worksheet.Cells.Item($rowIndex,2).Value2 = $app.AppId
        if ($passwordApps -contains $app.DisplayName) {
            $worksheet.Cells.Item($rowIndex,3).Value2 = "Yes"
        }
        else {
            $worksheet.Cells.Item($rowIndex,3).Value2 = "No"
        }
        if ($credApps -contains $app.DisplayName) {
            $worksheet.Cells.Item($rowIndex,4).Value2 = "Yes"
        }
        else {
            $worksheet.Cells.Item($rowIndex,4).Value2 = "No"
        }
        $rowIndex += 1
    }

    # Get Conditional Access Policies and save to worksheet
    $conditionalAccess = az rest --method GET --uri https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies
    $worksheet = $workbook.Worksheets.Item($worksheetIndex)
    $worksheet.Name = "Conditional Access Policies"
    $worksheetIndex += 1
    $worksheet.Cells.Item(1,1).Value2 = "DisplayName"
    $worksheet.Cells.Item(1,2).Value2 = "Id"
    $worksheet.Cells.Item(1,3).Value2 = "State"
    $rowIndex = 2
    foreach ($policy in $conditionalAccess.value) {
        $worksheet.Cells.Item($rowIndex,1).Value2 = $policy.displayName
        $worksheet.Cells.Item($rowIndex,2).Value2 = $policy.id
        $worksheet.Cells.Item($rowIndex,3).Value2 = $policy.state
        $rowIndex += 1
    }

    # Save workbook
    $workbook.SaveAs("C:\Users\$([Environment]::UserName)\Desktop\AzFiles\AzData.xlsx")

    # Close workbook
    $workbook.Close()

    # Quit Excel
    $workbook.Quit()
}
Get-AzData

#Run RoadRecon
function RoadRecon{
        Write-Host "Running RoadRecon"
        roadrecon auth --device-code
                Write-Host "Gathering"
        roadrecon gather --mfa
                Write-Host "Dumping"
        roadrecon dump
                Write-Host "Checking Policies"
        roadrecon plugin policies
        roadrecon-gui
                Write-Host "RoadRecon Complete, check http://127.0.0.1:5000 for results"
    }
    RoadRecon

# Read the contents of the file into a variable
$auth = Get-Content -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\.roadtools_auth"

# Save the contents of the variable to a new file
Set-Content -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\.roadtools_auth.bak" -Value $auth

#Run CRT (Give it a client code eventually)
C:\Users\$([Environment]::UserName)\Desktop\AzureTools\CRT\.\Get-CRTReport.ps1 -JobName CRT_Report -WorkingDirectory

#Run AzureHound using session token from RoadRecon
C:\Users\$([Environment]::UserName)\Desktop\AzureTools\AzureHound\.azurehound.exe start -j $auth list -o azure_out.json

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
    

Read-Host -Prompt "Complete! Press enter to exit"
