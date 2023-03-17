#A script which uses the GRAPH API to extract useful and interseting data from Azure Active Directory
#It will then take that information and format it into an excel book
#Make sure it's not done in the x86 powershell

function AzureGraphDump{

    #login to AzureAD
    Connect-AzureAD

function Get-ConditionalAccessPolicies {
    # Run the az rest command and store the output as a string
    $output = az rest --method GET --uri https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies | Out-String

    # Convert the output string to a JSON object
    $json = ConvertFrom-Json $output

    # Extract the policy objects from the JSON object
    $policies = $json.value

    # Return the policies
    return $policies

    # Display success message
    Write-Host "Successfully retrieved $($policies.count) conditional access policies."
    
}
Get-ConditionalAccessPolicies

function Export-PoliciesToCSV {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [array]$Policies
    )

    $Policies | Select-Object -Property createdDateTime,displayName,grantControls,id,modifiedDateTime,@{Name="ApplicationEnforcedRestrictions";Expression={$_.sessionControls.applicationEnforcedRestrictions}},@{Name="CloudAppSecurity";Expression={$_.sessionControls.cloudAppSecurity}},@{Name="DisableResilienceDefaults";Expression={$_.sessionControls.disableResilienceDefaults}},@{Name="PersistentBrowser";Expression={$_.sessionControls.persistentBrowser}},@{Name="SignInFrequency";Expression={$_.sessionControls.signInFrequency}} | Export-Csv -Path $Path -NoTypeInformation
}
$policies = Get-ConditionalAccessPolicies
Export-PoliciesToCSV -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Policies.csv" -Policies $policies


# Get all global admins in the organization and convert to a csv
function Get-GlobalAdmins{
    $globalAdmins = Get-AzureADDirectoryRoleMember -ObjectId (Get-AzureADDirectoryRole | Where-Object {$_.displayName -eq 'Global Administrator'}).ObjectId | Get-AzureADUser
    
    # Select properties to export
    $properties = 'DisplayName', 'Mail', @{Name='OtherMails';Expression={$_.OtherMails -join ';'}}, @{Name='ProxyAddresses';Expression={$_.ProxyAddresses -join ';'}}, 'TelephoneNumber', 'UserPrincipalName', 'ObjectId', 'AccountEnabled'
    
    # Export global admins to CSV file
    $globalAdmins | Select-Object $properties | Export-Csv -Path "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\global_admins.csv" -NoTypeInformation
    }
    Get-GlobalAdmins
    
    



function Export-ConditionalAccessPoliciesToExcel {
    
    $caFilePath = "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\Policies.csv"

    if (Test-Path $caFilePath){

        $data = Import-Csv -Path $caFilePath -Header "createdDateTime","displayName","grantControls","id","modifiedDateTime"

        # Load the Excel COM object
        $excel = New-Object -ComObject Excel.Application

        # Make Excel visible
        $excel.Visible = $true

        # Add a new workbook
        $workbook = $excel.Workbooks.Add()

        # Get the first worksheet
        $worksheet = $workbook.Worksheets.Item(1)

        # Set the header names and format
        $worksheet.Cells.Item(1,1) = "Created Date Time"
        $worksheet.Cells.Item(1,1).Font.Bold = $true
        $worksheet.Cells.Item(1,1).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,2) = "Display Name"
        $worksheet.Cells.Item(1,2).Font.Bold = $true
        $worksheet.Cells.Item(1,2).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,3) = "Grant Controls"
        $worksheet.Cells.Item(1,3).Font.Bold = $true
        $worksheet.Cells.Item(1,3).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,4) = "ID"
        $worksheet.Cells.Item(1,4).Font.Bold = $true
        $worksheet.Cells.Item(1,4).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,5) = "Modified Date Time"
        $worksheet.Cells.Item(1,5).Font.Bold = $true
        $worksheet.Cells.Item(1,5).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,6) = "Application Enforced Restrictions"
        $worksheet.Cells.Item(1,6).Font.Bold = $true
        $worksheet.Cells.Item(1,6).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,7) = "Cloud App Security"
        $worksheet.Cells.Item(1,7).Font.Bold = $true
        $worksheet.Cells.Item(1,7).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,8) = "Disable Resilience Defaults"
        $worksheet.Cells.Item(1,8).Font.Bold = $true
        $worksheet.Cells.Item(1,8).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,9) = "Persistent Browser"
        $worksheet.Cells.Item(1,9).Font.Bold = $true
        $worksheet.Cells.Item(1,9).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,10) = "Sign In Frequency"
        $worksheet.Cells.Item(1,10).Font.Bold = $true
        $worksheet.Cells.Item(1,10).Font.ColorIndex = 2 # white

        # set the background color of the header row
        $headerRange = $worksheet.Range("A1:J1")
        $headerRange.Interior.ColorIndex = 30

        # Set the data starting row
        $row = 2

        # Loop through each policy and populate the Excel worksheet
        foreach ($policy in $policies) {
            # Populate the Created Date Time column
            $worksheet.Cells.Item($row,1) = $policy.createdDateTime

            # Populate the Display Name column
            $worksheet.Cells.Item($row,2) = $policy.displayName

            # Populate the Grant Controls column
            $worksheet.Cells.Item($row,3) = $policy.grantControls

            # Populate the ID column
            $worksheet.Cells.Item($row,4) = $policy.id

            # Populate the Modified Date Time column
            $worksheet.Cells.Item($row,5) = $policy.modifiedDateTime

            # Populate the Application Enforced Restrictions column
            $worksheet.Cells.Item($row,6) = $policy.sessionControls.applicationEnforcedRestrictions

            # Populate the Cloud App Security column
            $worksheet.Cells.Item($row,7) = $policy.sessionControls.cloudAppSecurity

            # Populate the Disable Resilience Defaults column
            $worksheet.Cells.Item($row,8) = $policy.sessionControls.disableResilienceDefaults

            # Populate the Persistent Browser column
            $worksheet.Cells.Item($row,9) = $policy.sessionControls.persistentBrowser

            # Populate the Sign In Frequency column
            $worksheet.Cells.Item($row,10) = $policy.sessionControls.signInFrequency

            # Move to the next row
            $row += 1
        }

        # set the background color of the rows
        $range = $worksheet.Range("A2:J$row")
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

    # Save the workbook
    $workbook.SaveAs("C:\Users\$([Environment]::UserName)\Desktop\AzFiles\caPolicies.xlsx")

    # Close the workbook and Excel application
    $workbook.Close($true)
    $excel.Quit()

     # release the COM objects
     [System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet) | Out-Null
     [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
     [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    }

    else {
    }

}
Export-ConditionalAccessPoliciesToExcel

function Export-GlobalAdminsToExcel {
    
    $gaFilePath = "C:\Users\$([Environment]::UserName)\Desktop\AzFiles\global_admins.csv"

    if (Test-Path $gaFilePath){
        
        $data = Import-Csv -Path $gaFilePath -Header "DisplayName", "Mail", "OtherMails", "ProxyAddresses", "TelephoneNumber", "UserPrincipalName", "ObjectId", "AccountEnabled"

        # Load the Excel COM object
        $excel = New-Object -ComObject Excel.Application

        # Make Excel visible
        $excel.Visible = $true
        
        # Add a new workbook
        $workbook = $excel.Workbooks.Add()
        
        # Get the first worksheet
        $worksheet = $workbook.Worksheets.Item(1)

        # Set the header names and format
        $worksheet.Cells.Item(1,1) = "Display Name"
        $worksheet.Cells.Item(1,1).Font.Bold = $true
        $worksheet.Cells.Item(1,1).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,2) = "Mail"
        $worksheet.Cells.Item(1,2).Font.Bold = $true
        $worksheet.Cells.Item(1,2).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,3) = "Other Mails"
        $worksheet.Cells.Item(1,3).Font.Bold = $true
        $worksheet.Cells.Item(1,3).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,4) = "Proxy Addresses"
        $worksheet.Cells.Item(1,4).Font.Bold = $true
        $worksheet.Cells.Item(1,4).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,5) = "Telephone Number"
        $worksheet.Cells.Item(1,5).Font.Bold = $true
        $worksheet.Cells.Item(1,5).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,6) = "UserPrincipalName"
        $worksheet.Cells.Item(1,6).Font.Bold = $true
        $worksheet.Cells.Item(1,6).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,7) = "ObjectId"
        $worksheet.Cells.Item(1,7).Font.Bold = $true
        $worksheet.Cells.Item(1,7).Font.ColorIndex = 2 # white
        $worksheet.Cells.Item(1,8) = "Account Enabled"
        $worksheet.Cells.Item(1,8).Font.Bold = $true
        $worksheet.Cells.Item(1,8).Font.ColorIndex = 2 # white


        # set the background color of the header row
        $headerRange = $worksheet.Range("A1:H1")
        $headerRange.Interior.ColorIndex = 30

        # Set the data starting row
        $row = 2

        # Loop through each policy and populate the Excel worksheet
        foreach ($admin in $data) {
            $worksheet.Cells.Item($row,1) = $policy.DisplayName
            $worksheet.Cells.Item($row,2) = $policy.Mail
            $worksheet.Cells.Item($row,3) = $policy.OtherMails
            $worksheet.Cells.Item($row,4) = $policy.ProxyAddresses
            $worksheet.Cells.Item($row,5) = $policy.TelephoneNumber
            $worksheet.Cells.Item($row,6) = $policy.sessionControls.UserPrincipalName
            $worksheet.Cells.Item($row,7) = $policy.sessionControls.ObjectId
            $worksheet.Cells.Item($row,8) = $policy.sessionControls.AccountEnabled
            # Move to the next row
            $row += 1
        }

         # set the background color of the rows
         $range = $worksheet.Range("A2:H$row")
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
            if (($i % 2) -eq 0) {
                $rangeA.Interior.ColorIndex = 15
                $rangeB.Interior.ColorIndex = 15
                $rangeC.Interior.ColorIndex = 15
                $rangeD.Interior.ColorIndex = 15
                $rangeE.Interior.ColorIndex = 15
                $rangeF.Interior.ColorIndex = 15
                $rangeG.Interior.ColorIndex = 15
                $rangeH.Interior.ColorIndex = 15
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
            }
    }    

        # autofit the columns
        $range = $worksheet.Range("A:H")
        $range.EntireColumn.AutoFit() | Out-Null

        # Save the workbook
        $workbook.SaveAs("C:\Users\$([Environment]::UserName)\Desktop\AzFiles\GlobalAdmins.xlsx")

        # Close the workbook and Excel application
        $workbook.Close($true)
        $excel.Quit()

        # release the COM objects
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
        }

        else{

        }
    }
 
Export-GlobalAdminsToExcel

}
AzureGraphDump
