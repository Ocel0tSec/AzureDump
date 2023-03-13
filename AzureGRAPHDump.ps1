function Export-ConditionalAccessPoliciesToExcel {
    # Run the az rest command and store the output as a string
    $output = az rest --method GET --uri https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies
    
    Write-Host $output

    # Convert the output string to a JSON object
    $json = ConvertFrom-Json $output

    # Extract the policy objects from the JSON object
    $policies = $json.value

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

    # Autofit the columns
    $range = $worksheet.UsedRange
    $range.EntireColumn.AutoFit()    

# Save the workbook
$workbook.SaveAs("Conditional Access Policies.xlsx")

# Close the workbook and Excel application
$workbook.Close($true)
$excel.Quit()

# Release the Excel COM object
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
}
Export-ConditionalAccessPoliciesToExcel
