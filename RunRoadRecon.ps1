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
