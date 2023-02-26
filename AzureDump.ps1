function LoginAndCreate{
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
    az login --allow-no-subscriptions
    
    #Get variables for the user ID and TennantIDs
    $account = az account list | ConvertFrom-Json
    
    $ID = $account.id
    $tenantID = $account.tenantId
    }
LoginAndCreate

function Get-AzData{
    # Get list of applications
    az ad app list --query "[].[displayName,appId]" -o tsv > "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Apps.csv"
    Write-Host "Applications Processed"
    
    # Get list of interesting URLs from applications
    az ad app list --query "[].identifierUris[]" -o tsv | Where-Object {$_ -match '\.(com|org|net|us|io|xyz|10\.|172\.|192\.)'} | Sort-Object | Get-Unique > Interesting_Urls.txt
    Write-Host "Got Interesting URL's"
    
    # Get list of service principals
    az ad sp list --query "[].[displayName,appOwnerOrganizationId,appId,id]" --all -o tsv > ServicePrincipals.csv
    Write-Host "Service Principals Processed"
    
    # Get list of groups
    az ad group list --query "[].[displayName,description,onPremisesNetBiosName,onPremisesDomainName,mail,id]" -o tsv > Groups.csv
    Write-Host "Groups Processed"
    
    # Get list of users
    az ad user list --query "[].[displayName,mail,businessPhones,mobilePhone,id,jobTitle,officeLocation,givenName,surname,userPrincipalName]" -o tsv > Users.csv
    Write-Host "Users Processed"
    
    # Get list of VMs
    az vm list --query "[].[name,location,resourceGroup,osDisk.name,osType]" -o tsv > VMs.csv
    Write-Host "VMs Processed"
    
    # Get list of storage accounts
    az storage account list --query "[].[name,location,resourceGroup]" -o tsv > StorageAccounts.csv
    Write-Host "Storage Accounts Processed"
    
    # Get list of key vaults
    az keyvault list --query "[].[name,location,resourceGroup]" -o tsv > KeyVaults.csv
    Write-Host "Key Vaults Processed"
    
    # Get list of apps with password credentials
    az ad sp list --query "[?passwordCredentials!=null].[displayName]" -o tsv > PasswordApps.csv
    Write-Host "Apps with Password Credentials Processed"
    
    # Get list of apps with key credentials
    az ad sp list --query "[?keyCredentials!=null].[displayName]" -o tsv > KeyCredentialApps.csv
    Write-Host "Apps with Key Credentials Processed"
    
    # Get list of conditional access policies
    az rest --method GET --uri https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies | ConvertFrom-Json | Export-Excel -Path "ConditionalAccessPolicies.xlsx" -WorksheetName "Conditional Access Policies" -AutoSize
    Write-Host "Conditional Access Policies Processed"
}
Get-AzData

function Export-AppsToExcel {

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
