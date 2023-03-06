#Connect to Azure Account
function LoginToAzure {
    Write-Host "Logging in to your account" -ForegroundColor Cyan

    # Disable Azure CLI warning message
    $env:AZURE_CORE_DISABLE_WARN_ON_INVALID_CONFIG = "true"

    # Login to Azure account
    $azOutput = az login --allow-no-subscriptions 2> $null

    # Extract relevant information
    $azOutputJson = $azOutput | ConvertFrom-Json
    $azUser = $azOutputJson[0].user.name
    $azState = $azOutputJson[0].state
    $azTenantId = $azOutputJson[0].tenantId
    $azAccountId = $azOutputJson[0].id

    # Print output
    $azUser = $null
    $azState = $null
    $azTenantId = $null
    $azAccountId = $null
    $azOutputJson | ForEach-Object {
        $azUser = $_.user.name
        $azState = $_.state
        $azTenantId = $_.tenantId
        $azAccountId = $_.id
    }

    Write-Host "`t[+] ID:`t`t`t$($azAccountId)" -ForegroundColor Green; `
    Write-Host "`t[+] Tenant ID:`t$($azTenantId)" -ForegroundColor Green; `
    Write-Host "`t[+] Username:`t$($azUser)" -ForegroundColor Green; `
    Write-Host "`t[+] State:`t`t$($azState)" -ForegroundColor Green;

}
LoginToAzure

#Enumerate Azure data with Azure CLI
function Get-AzData{

    Write-Host "Dumping Azure" -ForegroundColor Cyan
    Start-Sleep -Milliseconds 1000
    function Get-AppList {
        $appList = az ad app list --query "[].[displayName,appId]" --all -o tsv 2>&1
        if ($LASTEXITCODE -ne 0) {
            if ($appList -like "*SubscriptionNotFound*") {
                Write-Host "`t[-]No Subscriptions found" -ForegroundColor Red
            } else {
                Write-Error $appList
            }
        } else {
            Write-Host "`t[+] Applications Processed" -ForegroundColor Green
            $appList | Out-File -FilePath "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Apps.csv"
            Start-Sleep -Milliseconds 500
        }
    }
    Get-AppList

    # Get list of apps with password or key credentials
    function Get-ADApplicationsWithCredentials {
        $appList = az ad app list --query "[?keyCredentials || passwordCredentials].[displayName, appId, keyCredentials, passwordCredentials]" -o tsv 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error $appList
        } else {
            if (![string]::IsNullOrEmpty($appList)) {
                Write-Host "`t[!] Azure AD Applications with Credentials Processed" -ForegroundColor Orange
                $filePath = "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\ADApplicationsWithCredentials.csv"
                $appList | Out-File -FilePath $filePath
                Start-Sleep -Milliseconds 500
            } else {
                Write-Host "`t[-] No Azure AD Applications with Credentials Found" -ForegroundColor Red
            }
        }
    }
    Get-ADApplicationsWithCredentials
    
    # Get list of interesting URLs from applications
    az ad app list | findstr ".com" | Sort-Object | Get-Unique > "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Interesting_Urls.txt"
    az ad app list | findstr ".org" | Sort-Object | Get-Unique >> "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Interesting_Urls.txt"
    az ad app list | findstr ".net" | Sort-Object | Get-Unique >> "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Interesting_Urls.txt"
    az ad app list | findstr ".us" | Sort-Object | Get-Unique >> "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Interesting_Urls.txt"
    az ad app list | findstr ".io" | Sort-Object | Get-Unique >> "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Interesting_Urls.txt"
    az ad app list | findstr ".xyz" | Sort-Object | Get-Unique >> "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Interesting_Urls.txt"
    az ad app list | findstr "10." | Sort-Object | Get-Unique >> "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Interesting_Urls.txt"
    az ad app list | findstr "172." | Sort-Object | Get-Unique >> "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Interesting_Urls.txt"
    az ad app list | findstr "192." | Sort-Object | Get-Unique >> "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Interesting_Urls.txt"
    Write-Host "`t[+] Got Interesting URL's" -ForegroundColor Green
    Start-Sleep -Milliseconds 500

    # Get list of service principals
    function Get-SPList {
        $spList = az ad sp list --query "[].[displayName,appOwnerOrganizationId,appId,id]" --all -o tsv 2>&1
        if ($LASTEXITCODE -ne 0) {
            if ($spList -like "*SubscriptionNotFound*") {
                Write-Host "`t[-]No Subscriptions found" -ForegroundColor Red
            } else {
                Write-Error $spList
            }
        } else {
            Write-Host "`t[+] Service Principals Processed" -ForegroundColor Green
            $spList | Out-File -FilePath "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\ServicePrincipals.csv" 
        }
    }
    Get-SPList


    # Get list of groups
    az ad group list --query "[].[displayName,description,onPremisesNetBiosName,onPremisesDomainName,mail,id]" -o tsv > "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Groups.csv"
    Write-Host "`t[+] Groups Processed" -ForegroundColor Green
    Start-Sleep -Milliseconds 500
    
    # Get list of users
    #az ad user list --query "[].[displayName,mail,[0].businessPhones[0],mobilePhone,id,jobTitle,officeLocation,givenName,surname,userPrincipalName]" -o tsv > "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Users.csv"
    #Write-Host "`t[+] Users Processed" -ForegroundColor Green
    #Start-Sleep -Milliseconds 500

    #TEST for business phones

    az ad user list --query "[].{displayName: displayName, mail: mail, businessPhone: businessPhones[0] || 'N/A', mobilePhone: mobilePhone || 'N/A', id: objectId, jobTitle: jobTitle, officeLocation: officeLocation, givenName: givenName, surname: surname, userPrincipalName: userPrincipalName}" -o tsv > "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Users.csv"
    Write-Host "`t[+] Users Processed" -ForegroundColor Green
    Start-Sleep -Milliseconds 500
    
    # Get list of VMs
    function Get-VMs {
        $vmList = az vm list --query "[].[name,location,resourceGroup,osDisk.name,osType]" -o tsv 2>&1
        if ($LASTEXITCODE -ne 0) {
            if ($vmList -like "*SubscriptionNotFound*") {
                Write-Host "`t[-] No VM Subscriptions Found" -ForegroundColor Red
            } else {
                Write-Error $vmList
            }
        } else {
            Write-Host "`t[+] VMs Processed" -ForegroundColor Green
            $vmList | Out-File -FilePath VMs.csv
            Start-Sleep -Milliseconds 500
        }
    }
    Get-VMs

    # Get list of storage accounts
    function Get-StorageAccountList {
        $saList = az storage account list --query "[].[name,location,resourceGroup]" -o tsv 2>&1
        if ($LASTEXITCODE -ne 0) {
            if ($saList -like "*SubscriptionNotFound*") {
                Write-Host "`t[-] No Storage Account Subscriptions Found" -ForegroundColor Red
            } else {
                Write-Error $saList
            }
        } else {
            Write-Host "`t[+] VMs Processed" -ForegroundColor Green
            $saList | Out-File -FilePath StorageAccounts.csv
            Start-Sleep -Milliseconds 500
        }
    }
    Get-StorageAccountList
    
# Get list of key vaults
function Get-keyVaultList {
    $kvList =  az keyvault list --query "[].[name,location,resourceGroup]"  -o tsv 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($kvList -like "*SubscriptionNotFound*") {
            Write-Host "`t[-] No Key Vaults Found" -ForegroundColor Red
        } else {
            Write-Error $kvList
        }
    } else {
        if (![string]::IsNullOrEmpty($kvList)) {
            Write-Host "`t[+] Key Vaults Processed" -ForegroundColor Green
            $filePath = "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\KetVaults.csv"
            $kvList | Out-File -FilePath $filePath
            Start-Sleep -Milliseconds 500
        } else {
            Write-Host "`t[-] No Key Vaults Found" -ForegroundColor Red
        }
    }
}
Get-keyVaultList

}
Get-AzData

#Create an Excel sheet and add data for each .csv
function Export-AppsToExcel {

    Write-Host "Generating Excel Sheets" -ForegroundColor Cyan
    # import the CSV data and set the column names
    $data = Import-Csv -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Apps.csv" -Header "DisplayName"
    
    # load the Excel COM object
    $excel = New-Object -ComObject Excel.Application

    # make Excel visible
    $excel.Visible = $true

    # add a new workbook
    $workbook = $excel.Workbooks.Add()

    # get the first worksheet
    $worksheet = $workbook.Worksheets.Item(1)

    # set the header names and format
    $worksheet.Cells.Item(1,1) = "Display Name"
    $worksheet.Cells.Item(1,1).Font.Bold = $true
    $worksheet.Cells.Item(1,1).Font.ColorIndex = 2 # white
    $worksheet.Cells.Item(1,2) = "App ID"
    $worksheet.Cells.Item(1,2).Font.Bold = $true
    $worksheet.Cells.Item(1,2).Font.ColorIndex = 2 # white

    # set the background color of the header row
    $headerRange = $worksheet.Range("A1:B1")
    $headerRange.Interior.ColorIndex = 30
    $headerRange.Font.Bold = $true

    # start at row 2 (after the header row)
    $row = 2

    # loop through the data and add each row to the worksheet
    foreach ($item in $data) {
        $displayName = $item.DisplayName
        $displayNameArray = $displayName -split "\t+"

        $worksheet.Cells.Item($row,1) = $displayNameArray[0]
        $worksheet.Cells.Item($row,2) = $displayNameArray[1]

        # increment the row counter
        $row++
    }

    # set the background color of the rows
    $range = $worksheet.Range("A2:B$row")
    $fill = $range.Interior
    $fill.Pattern = 1
    $fill.PatternColorIndex = -4105
    $fill.ThemeColor = 1
    $fill.TintAndShade = 0.599993896298105

    # set the background color of every row to a different color
    for ($i = 2; $i -le $row; $i++) {
    $rangeA = $worksheet.Range("A$i")
    $rangeB = $worksheet.Range("B$i")
    if (($i % 2) -eq 0) {
        $rangeA.Interior.ColorIndex = 15
        $rangeB.Interior.ColorIndex = 15
    }
    else {
        $rangeA.Interior.ColorIndex = 2
        $rangeB.Interior.ColorIndex = 2
    }
}

    # autofit the columns
    $range = $worksheet.Range("A:B")
    $range.EntireColumn.AutoFit() | Out-Null

    # save the workbook
    $workbook.SaveAs("C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Applications.xlsx", 51)

    # close the workbook and Excel
    $workbook.Close()
    $excel.Quit()

    # release the COM objects
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
}

# call the function to export the data to an Excel file
Export-AppsToExcel

function Add-CredentialsColumnsToApplicationsFile {
    # Define path to CSV file
    $csvFilePath = "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\ADApplicationsWithCredentials.csv"

    # Check if CSV file exists
    if (-not (Test-Path $csvFilePath)) {
        return
    }

    # Load Excel COM object
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false

    # Open Applications.xlsx workbook
    $workbook = $excel.Workbooks.Open("C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Applications.xlsx")
    $worksheet = $workbook.Worksheets.Item(1)

    # Add column headers
    $worksheet.Cells.Item(1, 5) = "Has Key Credentials"
    $worksheet.Cells.Item(1, 6) = "Has Password Credentials"

    # Get list of applications with credentials from ADApplicationsWithCredentials.csv
    $appList = Import-Csv $csvFilePath -Delimiter "`t"

    # Loop through each row in the worksheet and check if the application has credentials
    $row = 2
    while ($worksheet.Cells.Item($row, 1).Value2) {
        $appId = $worksheet.Cells.Item($row, 2).Value2

        $app = $appList | Where-Object { $_.appId -eq $appId }
        if ($app) {
            $hasKey = if ($app.keyCredentials) { "Yes" } else { "No" }
            $hasPassword = if ($app.passwordCredentials) { "Yes" } else { "No" }

            $worksheet.Cells.Item($row, 5) = $hasKey
            $worksheet.Cells.Item($row, 6) = $hasPassword
        }

        $row++
    }

    # Save and close workbook
    $workbook.Save()
    $workbook.Close()

    # Quit Excel
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
}
Add-CredentialsColumnsToApplicationsFile



function Export-ServicePrincipalsToExcel {

    # import the CSV data and set the column names
    $data = Import-Csv -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\ServicePrincipals.csv" -Header "DisplayName", "AppOwnerOrganizationId", "AppId", "Id"
    
    # load the Excel COM object
    $excel = New-Object -ComObject Excel.Application

    # make Excel visible
    $excel.Visible = $true

    # add a new workbook
    $workbook = $excel.Workbooks.Add()

    # add a new worksheet and set its name to "Service Principals"
    $worksheet = $workbook.Worksheets.Add()
    $worksheet.Name = "Service Principals"

    # set the header names
    $worksheet.Cells.Item(1,1) = "Display Name"
    $worksheet.Cells.Item(1,1).Font.Bold = $true
    $worksheet.Cells.Item(1,1).Font.ColorIndex = 2 # white
    $worksheet.Cells.Item(1,2) = "App Owner Organization Id"
    $worksheet.Cells.Item(1,2).Font.Bold = $true
    $worksheet.Cells.Item(1,2).Font.ColorIndex = 2 # white
    $worksheet.Cells.Item(1,3) = "App Id"
    $worksheet.Cells.Item(1,3).Font.Bold = $true
    $worksheet.Cells.Item(1,3).Font.ColorIndex = 2 # white
    $worksheet.Cells.Item(1,4) = "Id"
    $worksheet.Cells.Item(1,4).Font.Bold = $true
    $worksheet.Cells.Item(1,4).Font.ColorIndex = 2 # white

    # set the header row to be bold
    $headerRange = $worksheet.Range("A1:D1")
    $headerRange.Interior.ColorIndex = 30
    $headerRange.Font.Bold = $true

    # set the background color of the header row
    $headerRange.Interior.ColorIndex = 30

    # start at row 2 (after the header row)
    $row = 2

    # loop through the data and add each row to the worksheet
    foreach ($item in $data) {
        $displayName = $item.DisplayName
        $displayNameArray = $displayName -split "\t+"

        $worksheet.Cells.Item($row,1) = $displayNameArray[0]
        $worksheet.Cells.Item($row,2) = $displayNameArray[1]
        $worksheet.Cells.Item($row,3) = $displayNameArray[2]
        $worksheet.Cells.Item($row,4) = $displayNameArray[3]
        
        # increment the row counter
        $row++
    }

        # set the background color of the rows
        $range = $worksheet.Range("A2:B$row")
        $fill = $range.Interior
        $fill.Pattern = 1
        $fill.PatternColorIndex = -4105
        $fill.ThemeColor = 1
        $fill.TintAndShade = 0.599993896298105
    
        # set the background color of every row to a different color
        for ($i = 2; $i -le $row; $i++) {
        $rangeA = $worksheet.Range("A$i")
        $rangeB = $worksheet.Range("B$i")
        $rangeC = $worksheet.Range("C$i")
        $rangeD = $worksheet.Range("D$i")
        if (($i % 2) -eq 0) {
            $rangeA.Interior.ColorIndex = 15
            $rangeB.Interior.ColorIndex = 15
            $rangeC.Interior.ColorIndex = 15
            $rangeD.Interior.ColorIndex = 15
        }
        else {
            $rangeA.Interior.ColorIndex = 2
            $rangeB.Interior.ColorIndex = 2
            $rangeC.Interior.ColorIndex = 2
            $rangeD.Interior.ColorIndex = 2
        }
    }

    # autofit the columns
    $range = $worksheet.Range("A:D")
    $range.EntireColumn.AutoFit() | Out-Null

    # save the workbook
    $workbook.SaveAs("C:\Users\$([Environment]::UserName)\Desktop\AzFiles\ServicePrincipals.xlsx", 51)

    # close the workbook and Excel
    $workbook.Close()
    $excel.Quit()

    # release the COM objects
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
}

# call the function to export the data to an Excel file
Export-ServicePrincipalsToExcel

#Create an Excel sheet Groups
function Export-GroupsToExcel {

    # import the CSV data and set the column names
    $data = Import-Csv -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Groups.csv" -Header "DisplayName","Description","OnPremisesNetBiosName","onPremisesDomainName","mail","id"
    
    # load the Excel COM object
    $excel = New-Object -ComObject Excel.Application

    # make Excel visible
    $excel.Visible = $true

    # add a new workbook
    $workbook = $excel.Workbooks.Add()

    # add a new worksheet and set its name to "Groups"
    $worksheet = $workbook.Worksheets.Add()
    $worksheet.Name = "Groups"

    # set the header names and format
    $worksheet.Cells.Item(1,1) = "Display Name"
    $worksheet.Cells.Item(1,1).Font.Bold = $true
    $worksheet.Cells.Item(1,1).Font.ColorIndex = 2 # white
    $worksheet.Cells.Item(1,2) = "Description"
    $worksheet.Cells.Item(1,2).Font.Bold = $true
    $worksheet.Cells.Item(1,2).Font.ColorIndex = 2 # white
    $worksheet.Cells.Item(1,3) = "On Premises NetBios Name"
    $worksheet.Cells.Item(1,3).Font.Bold = $true
    $worksheet.Cells.Item(1,3).Font.ColorIndex = 2 # white
    $worksheet.Cells.Item(1,4) = "On Premises DomainName"
    $worksheet.Cells.Item(1,4).Font.Bold = $true
    $worksheet.Cells.Item(1,4).Font.ColorIndex = 2 # white
    $worksheet.Cells.Item(1,5) = "Email Address"
    $worksheet.Cells.Item(1,5).Font.Bold = $true
    $worksheet.Cells.Item(1,5).Font.ColorIndex = 2 # white
    $worksheet.Cells.Item(1,6) = "Id"
    $worksheet.Cells.Item(1,6).Font.Bold = $true
    $worksheet.Cells.Item(1,6).Font.ColorIndex = 2 # white

    # set the background color of the header row
    $headerRange = $worksheet.Range("A1:F1")
    $headerRange.Interior.ColorIndex = 30
    $headerRange.Font.Bold = $true

    # start at row 2 (after the header row)
    $row = 2

    # loop through the data and add each row to the worksheet
    foreach ($item in $data) {
        $displayName = $item.DisplayName
        $displayNameArray = $displayName -split "\t+"

        $worksheet.Cells.Item($row,1) = $displayNameArray[0]
        $worksheet.Cells.Item($row,2) = $displayNameArray[1]
        $worksheet.Cells.Item($row,3) = $displayNameArray[2]
        $worksheet.Cells.Item($row,4) = $displayNameArray[3]
        $worksheet.Cells.Item($row,5) = $displayNameArray[4]
        $worksheet.Cells.Item($row,6) = $displayNameArray[5]

        # increment the row counter
        $row++
    }

        # set the background color of the rows
        $range = $worksheet.Range("A2:B$row")
        $fill = $range.Interior
        $fill.Pattern = 1
        $fill.PatternColorIndex = -4105
        $fill.ThemeColor = 1
        $fill.TintAndShade = 0.599993896298105
    
        # set the background color of every row to a different color
        for ($i = 2; $i -le $row; $i++) {
        $rangeA = $worksheet.Range("A$i")
        $rangeB = $worksheet.Range("B$i")
        $rangeC = $worksheet.Range("C$i")
        $rangeD = $worksheet.Range("D$i")
        $rangeE = $worksheet.Range("E$i")
        $rangeF = $worksheet.Range("F$i")

        if (($i % 2) -eq 0) {
            $rangeA.Interior.ColorIndex = 15
            $rangeB.Interior.ColorIndex = 15
            $rangeC.Interior.ColorIndex = 15
            $rangeD.Interior.ColorIndex = 15
            $rangeE.Interior.ColorIndex = 15
            $rangeF.Interior.ColorIndex = 15
        }
        else {
            $rangeA.Interior.ColorIndex = 2
            $rangeB.Interior.ColorIndex = 2
            $rangeC.Interior.ColorIndex = 2
            $rangeD.Interior.ColorIndex = 2
            $rangeE.Interior.ColorIndex = 2
            $rangeF.Interior.ColorIndex = 2
        }
    }
    # autofit the columns
    $range = $worksheet.Range("A:F")
    $range.EntireColumn.AutoFit() | Out-Null

    # save the workbook
    $workbook.SaveAs("C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Groups.xlsx", 51)

    # close the workbook and Excel
    $workbook.Close()
    $excel.Quit()

    # release the COM objects
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
}
Export-GroupsToExcel

#Create an Excel sheet for Users
function Export-UsersToExcel {

    # import the CSV data and set the column names
    $data = Import-Csv -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Users.csv" -Header "DisplayName","mail","BusinessPhone","MobilePhone","Id","JobTitle","OfficeLocation","GivenName","Surname","UserPrincipalName"
    
    # load the Excel COM object
    $excel = New-Object -ComObject Excel.Application

    # make Excel visible
    $excel.Visible = $true

    # add a new workbook
    $workbook = $excel.Workbooks.Add()

    # get the first worksheet
    $worksheet = $workbook.Worksheets.Item(1)

    # set the header names and format
    $worksheet.Cells.Item(1,1) = "Display Name"
    $worksheet.Cells.Item(1,1).Font.Bold = $true
    $worksheet.Cells.Item(1,1).Font.ColorIndex = 2 # white
    $worksheet.Cells.Item(1,2) = "Emai Address"
    $worksheet.Cells.Item(1,2).Font.Bold = $true
    $worksheet.Cells.Item(1,2).Font.ColorIndex = 2 # white
    $worksheet.Cells.Item(1,3) = "Business Phones"
    $worksheet.Cells.Item(1,3).Font.Bold = $true
    $worksheet.Cells.Item(1,3).Font.ColorIndex = 2 # white
    $worksheet.Cells.Item(1,4) = "Mobile Phone"
    $worksheet.Cells.Item(1,4).Font.Bold = $true
    $worksheet.Cells.Item(1,4).Font.ColorIndex = 2 # white
    $worksheet.Cells.Item(1,5) = "Id"
    $worksheet.Cells.Item(1,5).Font.Bold = $true
    $worksheet.Cells.Item(1,5).Font.ColorIndex = 2 # white
    $worksheet.Cells.Item(1,6) = "Job Title"
    $worksheet.Cells.Item(1,6).Font.Bold = $true
    $worksheet.Cells.Item(1,6).Font.ColorIndex = 2 # white
    $worksheet.Cells.Item(1,7) = "Office Location"
    $worksheet.Cells.Item(1,7).Font.Bold = $true
    $worksheet.Cells.Item(1,7).Font.ColorIndex = 2 # white
    $worksheet.Cells.Item(1,8) = "Given Name"
    $worksheet.Cells.Item(1,8).Font.Bold = $true
    $worksheet.Cells.Item(1,8).Font.ColorIndex = 2 # white
    $worksheet.Cells.Item(1,9) = "Surname"
    $worksheet.Cells.Item(1,9).Font.Bold = $true
    $worksheet.Cells.Item(1,9).Font.ColorIndex = 2 # white
    $worksheet.Cells.Item(1,10) = "User Principal Name"
    $worksheet.Cells.Item(1,10).Font.Bold = $true
    $worksheet.Cells.Item(1,10).Font.ColorIndex = 2 # white

    # set the background color of the header row
    $headerRange = $worksheet.Range("A1:J1")
    $headerRange.Interior.ColorIndex = 30
    $headerRange.Font.Bold = $true

    # start at row 2 (after the header row)
    $row = 2

    # loop through the data and add each row to the worksheet
    foreach ($item in $data) {
        $displayName = $item.DisplayName
        $displayNameArray = $displayName -split "\t+"

        $worksheet.Cells.Item($row,1) = $displayNameArray[0]
        $worksheet.Cells.Item($row,2) = $displayNameArray[1]
        $worksheet.Cells.Item($row,3) = $displayNameArray[2]
        $worksheet.Cells.Item($row,4) = $displayNameArray[3]
        $worksheet.Cells.Item($row,5) = $displayNameArray[4]
        $worksheet.Cells.Item($row,6) = $displayNameArray[5]
        $worksheet.Cells.Item($row,7) = $displayNameArray[6]
        $worksheet.Cells.Item($row,8) = $displayNameArray[7]
        $worksheet.Cells.Item($row,9) = $displayNameArray[8]
        $worksheet.Cells.Item($row,10) = $displayNameArray[9]
        # increment the row counter
        $row++
    }

        # set the background color of the rows
        $range = $worksheet.Range("A2:B$row")
        $fill = $range.Interior
        $fill.Pattern = 1
        $fill.PatternColorIndex = -4105
        $fill.ThemeColor = 1
        $fill.TintAndShade = 0.599993896298105
    
        # set the background color of every row to a different color
        for ($i = 2; $i -le $row; $i++) {
        $rangeA = $worksheet.Range("A$i")
        $rangeB = $worksheet.Range("B$i")
        $rangeC = $worksheet.Range("C$i")
        $rangeD = $worksheet.Range("D$i")
        $rangeE = $worksheet.Range("E$i")
        $rangeF = $worksheet.Range("F$i")
        $rangeG = $worksheet.Range("G$i")
        $rangeH = $worksheet.Range("H$i")
        $rangeI = $worksheet.Range("I$i")
        $rangeJ = $worksheet.Range("J$i")

        if (($i % 2) -eq 0) {
            $rangeA.Interior.ColorIndex = 15
            $rangeB.Interior.ColorIndex = 15
            $rangeC.Interior.ColorIndex = 15
            $rangeD.Interior.ColorIndex = 15
            $rangeE.Interior.ColorIndex = 15
            $rangeF.Interior.ColorIndex = 15
            $rangeG.Interior.ColorIndex = 15
            $rangeH.Interior.ColorIndex = 15
            $rangeI.Interior.ColorIndex = 15
            $rangeJ.Interior.ColorIndex = 15
        }
        else {
            $rangeA.Interior.ColorIndex = 2
            $rangeB.Interior.ColorIndex = 2
            $rangeC.Interior.ColorIndex = 2
            $rangeD.Interior.ColorIndex = 2
            $rangeE.Interior.ColorIndex = 2
            $rangeF.Interior.ColorIndex = 2
            $rangeG.Interior.ColorIndex = 2
            $rangeH.Interior.ColorIndex = 2
            $rangeI.Interior.ColorIndex = 2
            $rangeJ.Interior.ColorIndex = 2
        }
    }
    # autofit the columns
    $range = $worksheet.Range("A:J")
    $range.EntireColumn.AutoFit() | Out-Null

    # save the workbook
    $workbook.SaveAs("C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Users.xlsx", 51)

    # close the workbook and Excel
    $workbook.Close()
    $excel.Quit()

    # release the COM objects
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
}
Export-UsersToExcel

#Create an Excel sheet and add data for each .csv
function Export-VMsToExcel {

    #Set Filepath
    $vmFilePath = "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\VMs.csv"

    #Create if file exists 
    if (Test-Path $vmFilePath) {
            
        # import the CSV data and set the column names
        $data = Import-Csv -Path -Path $vmFilePath -Header "name","location","resourceGroup","osDisk.name","osType"
        
        # load the Excel COM object
        $excel = New-Object -ComObject Excel.Application

        # make Excel visible
        $excel.Visible = $true

        # add a new workbook
        $workbook = $excel.Workbooks.Add()

        # get the first worksheet
        $worksheet = $workbook.Worksheets.Item(1)

        # set the header names and format
        $worksheet.Cells.Item(1,1) = "Name"
        $worksheet.Cells.Item(1,1).Font.Bold = $true
        $worksheet.Cells.Item(1,1).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,2) = "Location"
        $worksheet.Cells.Item(1,2).Font.Bold = $true
        $worksheet.Cells.Item(1,2).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,3) = "Resource Group"
        $worksheet.Cells.Item(1,3).Font.Bold = $true
        $worksheet.Cells.Item(1,3).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,4) = "Operating System Disk Name"
        $worksheet.Cells.Item(1,4).Font.Bold = $true
        $worksheet.Cells.Item(1,4).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,5) = "Operating System Type"
        $worksheet.Cells.Item(1,5).Font.Bold = $true
        $worksheet.Cells.Item(1,5).Font.ColorIndex = 2 # white


        # set the background color of the header row
        $headerRange = $worksheet.Range("A1:E1")
        $headerRange.Interior.ColorIndex = 30

        # start at row 2 (after the header row)
        $row = 2

        # loop through the data and add each row to the worksheet
        foreach ($item in $data) {
            $displayName = $item.DisplayName
            $displayNameArray = $displayName -split "\t+"

            $worksheet.Cells.Item($row,1) = $displayNameArray[0]
            $worksheet.Cells.Item($row,2) = $displayNameArray[1]
            $worksheet.Cells.Item($row,3) = $displayNameArray[2]
            $worksheet.Cells.Item($row,4) = $displayNameArray[3]
            $worksheet.Cells.Item($row,5) = $displayNameArray[4]

            # increment the row counter
            $row++
        }

        # set the background color of the rows
        $range = $worksheet.Range("A2:B$row")
        $fill = $range.Interior
        $fill.Pattern = 1
        $fill.PatternColorIndex = -4105
        $fill.ThemeColor = 1
        $fill.TintAndShade = 0.599993896298105

        # set the background color of every row to a different color
        for ($i = 2; $i -le $row; $i++) {
        $rangeA = $worksheet.Range("A$i")
        $rangeB = $worksheet.Range("B$i")
        if (($i % 2) -eq 0) {
            $rangeA.Interior.ColorIndex = 15
            $rangeB.Interior.ColorIndex = 15
            $rangeC.Interior.ColorIndex = 15
            $rangeD.Interior.ColorIndex = 15
            $rangeE.Interior.ColorIndex = 15
        }
        else {
            $rangeA.Interior.ColorIndex = 2
            $rangeB.Interior.ColorIndex = 2
            $rangeC.Interior.ColorIndex = 2
            $rangeD.Interior.ColorIndex = 2
            $rangeE.Interior.ColorIndex = 2
        }
    }

        # autofit the columns
        $range = $worksheet.Range("A:E")
        $range.EntireColumn.AutoFit() | Out-Null

        # save the workbook
        $workbook.SaveAs("C:\Users\$([Environment]::UserName)\Desktop\AzFiles\VMs.xlsx", 51)

        # close the workbook and Excel
        $workbook.Close()
        $excel.Quit()

        # release the COM objects
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    }

    else {
    }
}
# call the function to export the data to an Excel file
Export-VMsToExcel

#Create an Excel sheet and add data for each .csv
function Export-StorageAccountsToExcel {

    $saFilePath = "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\StorageAccounts.csv"

    # import the CSV data and set the column names
    if (Test-Path $saFilePath) {

        $data = Import-Csv -Path $saFilePath -Header "name","location","resourceGroup"
        
        # load the Excel COM object
        $excel = New-Object -ComObject Excel.Application

        # make Excel visible
        $excel.Visible = $true

        # add a new workbook
        $workbook = $excel.Workbooks.Add()

        # get the first worksheet
        $worksheet = $workbook.Worksheets.Item(1)

        # set the header names and format
        $worksheet.Cells.Item(1,1) = "Name"
        $worksheet.Cells.Item(1,1).Font.Bold = $true
        $worksheet.Cells.Item(1,1).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,2) = "Location"
        $worksheet.Cells.Item(1,2).Font.Bold = $true
        $worksheet.Cells.Item(1,2).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,3) = "Resource Group"
        $worksheet.Cells.Item(1,3).Font.Bold = $true
        $worksheet.Cells.Item(1,3).Font.ColorIndex = 2 # white

        # set the background color of the header row
        $headerRange = $worksheet.Range("A1:C1")
        $headerRange.Interior.ColorIndex = 30

        # start at row 2 (after the header row)
        $row = 2

        # loop through the data and add each row to the worksheet
        foreach ($item in $data) {
            $displayName = $item.DisplayName
            $displayNameArray = $displayName -split "\t+"

            $worksheet.Cells.Item($row,1) = $displayNameArray[0]
            $worksheet.Cells.Item($row,2) = $displayNameArray[1]
            $worksheet.Cells.Item($row,3) = $displayNameArray[2]

            # increment the row counter
            $row++
        }

        # set the background color of the rows
        $range = $worksheet.Range("A2:B$row")
        $fill = $range.Interior
        $fill.Pattern = 1
        $fill.PatternColorIndex = -4105
        $fill.ThemeColor = 1
        $fill.TintAndShade = 0.599993896298105

        # set the background color of every row to a different color
        for ($i = 2; $i -le $row; $i++) {
        $rangeA = $worksheet.Range("A$i")
        $rangeB = $worksheet.Range("B$i")
        if (($i % 2) -eq 0) {
            $rangeA.Interior.ColorIndex = 15
            $rangeB.Interior.ColorIndex = 15
            $rangeC.Interior.ColorIndex = 15

        }
        else {
            $rangeA.Interior.ColorIndex = 2
            $rangeB.Interior.ColorIndex = 2
            $rangeC.Interior.ColorIndex = 2
        }
    }

        # autofit the columns
        $range = $worksheet.Range("A:C")
        $range.EntireColumn.AutoFit() | Out-Null

        # save the workbook
        $workbook.SaveAs("C:\Users\$([Environment]::UserName)\Desktop\AzFiles\StorageAccounts.xlsx", 51)

        # close the workbook and Excel
        $workbook.Close()
        $excel.Quit()

        # release the COM objects
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    }

    else {
        }
}

# call the function to export the data to an Excel file
Export-StorageAccountsToExcel

#Create an Excel sheet and add data for each .csv
function Export-KeyVaultsToExcel {

    #Set Filepath
    $kvfilePath = "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\VMs.csv"

    if (Test-Path $kvfilePath) {

        # import the CSV data and set the column names
        $data = Import-Csv -Path $kvfilePath -Header "name","location","resourceGroup"
        
        # load the Excel COM object
        $excel = New-Object -ComObject Excel.Application

        # make Excel visible
        $excel.Visible = $true

        # add a new workbook
        $workbook = $excel.Workbooks.Add()

        # get the first worksheet
        $worksheet = $workbook.Worksheets.Item(1)

        # set the header names and format
        $worksheet.Cells.Item(1,1) = "Name"
        $worksheet.Cells.Item(1,1).Font.Bold = $true
        $worksheet.Cells.Item(1,1).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,2) = "Location"
        $worksheet.Cells.Item(1,2).Font.Bold = $true
        $worksheet.Cells.Item(1,2).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,3) = "Resource Group"
        $worksheet.Cells.Item(1,3).Font.Bold = $true
        $worksheet.Cells.Item(1,3).Font.ColorIndex = 2 # white

        # set the background color of the header row
        $headerRange = $worksheet.Range("A1:C1")
        $headerRange.Interior.ColorIndex = 30

        # start at row 2 (after the header row)
        $row = 2

        # loop through the data and add each row to the worksheet
        foreach ($item in $data) {
            $displayName = $item.DisplayName
            $displayNameArray = $displayName -split "\t+"

            $worksheet.Cells.Item($row,1) = $displayNameArray[0]
            $worksheet.Cells.Item($row,2) = $displayNameArray[1]
            $worksheet.Cells.Item($row,3) = $displayNameArray[2]

            # increment the row counter
            $row++
        }

        # set the background color of the rows
        $range = $worksheet.Range("A2:B$row")
        $fill = $range.Interior
        $fill.Pattern = 1
        $fill.PatternColorIndex = -4105
        $fill.ThemeColor = 1
        $fill.TintAndShade = 0.599993896298105

        # set the background color of every row to a different color
        for ($i = 2; $i -le $row; $i++) {
        $rangeA = $worksheet.Range("A$i")
        $rangeB = $worksheet.Range("B$i")
        if (($i % 2) -eq 0) {
            $rangeA.Interior.ColorIndex = 15
            $rangeB.Interior.ColorIndex = 15
            $rangeC.Interior.ColorIndex = 15

        }
        else {
            $rangeA.Interior.ColorIndex = 2
            $rangeB.Interior.ColorIndex = 2
            $rangeC.Interior.ColorIndex = 2
        }
    }

        # autofit the columns
        $range = $worksheet.Range("A:C")
        $range.EntireColumn.AutoFit() | Out-Null

        # save the workbook
        $workbook.SaveAs("C:\Users\$([Environment]::UserName)\Desktop\AzFiles\KeyVaults.xlsx", 51)

        # close the workbook and Excel
        $workbook.Close()
        $excel.Quit()

        # release the COM objects
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
        
    }
    else {
            }
    }
# call the function to export the data to an Excel file
Export-KeyVaultstoExcel
Write-Host "`t[+] Export Complete" -ForegroundColor Green
Write-Host "Merging Files" -ForegroundColor Cyan

function Merge-AzureData {
    # Define the directory path and output file name
    $directoryPath = "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\"
    $outputFileName = "AzureData.xlsx"
    $outputFilePath = Join-Path $directoryPath $outputFileName

    # Get a list of all XLSX files and the TXT file in the directory
    $xlsxFiles = Get-ChildItem -Path $directoryPath -Filter *.xlsx
    $txtFile = Get-ChildItem -Path $directoryPath -Filter *.txt

    # Load Excel COM object
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false

    # Create a new workbook
    $workbook = $excel.Workbooks.Add()

    # Loop through each XLSX file and copy its contents to a new worksheet in the workbook
    foreach ($xlsxFile in $xlsxFiles) {
        $worksheet = $workbook.Worksheets.Add()
        $worksheet.Name = $xlsxFile.BaseName

        $sourceWorkbook = $excel.Workbooks.Open($xlsxFile.FullName)
        $sourceWorksheet = $sourceWorkbook.Worksheets.Item(1)

        $sourceRange = $sourceWorksheet.UsedRange
        $sourceRowCount = $sourceRange.Rows.Count
        $sourceColumnCount = $sourceRange.Columns.Count

        $destinationRange = $worksheet.Range("A1")
        $destinationRange = $destinationRange.Resize($sourceRowCount, $sourceColumnCount)

        $sourceRange.Copy($destinationRange)

        $sourceWorkbook.Close()
    }

    # Add the contents of the TXT file to a new worksheet in the workbook
    $worksheet = $workbook.Worksheets.Add()
    $worksheet.Name = $txtFile.BaseName

    $txtContent = Get-Content $txtFile.FullName
    $currentRow = 1
    $txtContent | ForEach-Object {
        $worksheet.Cells.Item($currentRow, 1).Value2 = $_
        $currentRow++
    }

    # Autofit columns in all worksheets
    foreach ($worksheet in $workbook.Worksheets) {
        $worksheet.Columns.AutoFit() | Out-Null
    }

    # Save the merged data to a new XLSX file
    $workbook.SaveAs($outputFilePath, [Microsoft.Office.Interop.Excel.XlFileFormat]::xlOpenXMLWorkbook)
    $workbook.Close()

    # Quit Excel
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
}
$null = Merge-AzureData

Write-Host "`t[+] Merge Complete!" -ForegroundColor Green
Write-Host "Cleaning Up..." -ForegroundColor Cyan

#Clean Up Files
function Clean-AzureFiles {
    $directoryPath = "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\"
    $files = Get-ChildItem $directoryPath | Where-Object { $_.Name -ne "AzureData.xlsx" }
    foreach ($file in $files) {
        Remove-Item $file.FullName
    }
}
Clean-AzureFiles
Write-Host "`t[+] AzureData.xlsx should be located in C:\Users\$([Environment]::UserName)\Desktop\AzFiles\" -ForegroundColor Green


<#
#Use the GRAPH API to query good info from the tenant 
function Get-AzGraphData{
    
    # Get list of conditional access policies
    az rest --method GET --uri https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies | ConvertFrom-Json | Export-Excel -Path "ConditionalAccessPolicies.xlsx" -WorksheetName "Conditional Access Policies" -AutoSize
    Write-Host "t[+] Conditional Access Policies Processed" -ForegroundColor Green
    
}

# Prompt user to confirm whether to run RoadRecon
$confirmationMessage = "Do you want to run RoadRecon? (yes/no):"
Write-Host -NoNewLine $confirmationMessage -ForegroundColor Cyan
$confirmation = Read-Host
# Check user input
if ($confirmation -eq "yes") {
    # Run RoadRecon
    function Run-RoadRecon{
        Write-Host "Running RoadRecon"
        roadrecon auth --device-code
                Write-Host "Gathering"
        roadrecon gather --mfa
                Write-Host "Dumping"
        roadrecon dump
                Write-Host "Checking Policies"
        roadrecon plugin policies
    }
    Run-RoadRecon

    # Read device code auth and store into a variable
    $auth = Get-Content -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\.roadtools_auth"

    # Save the contents of the variable to a new file
    Set-Content -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\.roadtools_auth.bak" -Value $auth

    RunRoadRecon
} else {
    Write-Host "RoadRecon not run."
}

# Prompt user to confirm whether to run AzureHound
$confirmationMessage = "Do you want to run AzureHound? (yes/no):"
Write-Host -NoNewLine $confirmationMessage -ForegroundColor Cyan
$confirmation = Read-Host
# Check user input
if ($confirmation -eq "yes") {
C:\Users\$([Environment]::UserName)\Desktop\AzureTools\AzureHound\.azurehound.exe start -j $auth list -o azure_out.json
} else {
    Write-Host "AzureHound not run."
}

# Prompt user to confirm whether to run CRT
$confirmationMessage = "Do you want to run CrowdStrike Reporting Tool? (yes/no):"
Write-Host -NoNewLine $confirmationMessage -ForegroundColor Cyan
$confirmation = Read-Host
# Check user input
if ($confirmation -eq "yes") {
C:\Users\$([Environment]::UserName)\Desktop\AzureTools\CRT\.\Get-CRTReport.ps1 -JobName CRT_Report -WorkingDirectory
#Run CRT (Give it a client code eventually)
cd "C:\Users\$([Environment]::UserName)\Desktop\AzureTools\CRT" 
.\Get-CRTReport.ps1 -JobName ClientName -WorkingDirectory "C:\Users\$([Environment]::UserName)\Desktop\AzFiles"
} else {
    Write-Host "AzureHound not run."
}

#Start the RoadRecon GUI
roadrecon-gui
Write-Host "RoadRecon Complete, check http://127.0.0.1:5000 for results"
#>
