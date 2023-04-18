#Run CRT (Give it a client code eventually)
cd "C:\Users\$([Environment]::UserName)\Desktop\AzureTools\CRT" 
.\Get-CRTReport.ps1 -JobName ClientName -WorkingDirectory "C:\Users\$([Environment]::UserName)\Desktop\AzFiles"
cd "C:\Users\$([Environment]::UserName)\Desktop\AzureDump-main"
