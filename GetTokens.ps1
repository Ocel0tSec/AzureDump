<#
Logs in to Microsoft using the Device code method
It will save the refresh token and access token as variables if it works
#>

function Get-MicrosoftTokens {
    param(
        [string]$ClientId = "1950a258-227b-4e31-a9cf-717495945fc2",
        [string]$UserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36",
        [int]$PollingInterval = 10,
        [int]$PollingTimeout = 300
    )

    # Get device code
    $body = @{
        "client_id" =     $ClientId
        "resource" =      "https://graph.microsoft.com"
    }
    $headers = @{
        "User-Agent" = $UserAgent
    }
    $authResponse = Invoke-RestMethod `
        -UseBasicParsing `
        -Method Post `
        -Uri "https://login.microsoftonline.com/common/oauth2/devicecode?api-version=1.0" `
        -Headers $headers `
        -Body $body

    Write-Host "Enter this code in your browser" -ForegroundColor Cyan
    Write-Host "`t[+] Code: " $authResponse.user_code -ForegroundColor Green
    Start-Process $authResponse.verification_url

    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($PollingTimeout)
    $accessToken = $null
    $refreshToken = $null

    do {
        # Suppress error messages from the polling request
        $Tokens = $null
        try {
            $body=@{
                "client_id" =  $ClientId
                "grant_type" = "urn:ietf:params:oauth:grant-type:device_code"
                "code" =       $authResponse.device_code
            }
            $Tokens = Invoke-RestMethod `
                -UseBasicParsing `
                -Method Post `
                -Uri "https://login.microsoftonline.com/Common/oauth2/token?api-version=1.0" `
                -Headers $headers `
                -Body $body -ErrorAction SilentlyContinue
        } catch {
            # Suppress error messages from the polling request
        }

        if ($Tokens -ne $null) {
            $accessToken = $Tokens.access_token
            $refreshToken = $Tokens.refresh_token
        } else {
            Start-Sleep -Seconds $PollingInterval
        }
    } until (($accessToken -ne $null) -or (Get-Date) -gt $endTime)

    if ($accessToken -ne $null) {
        $secret = ConvertTo-SecureString $refreshToken -AsPlainText -Force
        Set-Secret -Name "MyRefreshToken" -Secret $secret
        $env:ACCESSTOKEN = $accessToken
        $env:REFRESHTOKEN = $refreshToken
        Write-Host "Got some tokens" -ForegroundColor Cyan
        Write-Host "`t[+] Access token: $accessToken"
        Write-Host "`t[+] Refresh token: $refreshToken"
    } else {
        Write-Warning "`t[-] Polling timed out before user signed in" -ForegroundColor Red
    }
}

Get-MicrosoftTokens
