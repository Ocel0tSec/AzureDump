# AzureDump
Powershell Script to enumerate AzureAD and output good data

AzureDumpInstaller.ps1 will install the necessary AZ modules as well as the following tools: AADInternals by @DrAzureAD, PowerZure by @haus3c, AzureHound by the folks at bloodhound, python 3.7 (seemed to be the version required), and RoadRecon by Dirk-jan.

After installing the tools you will just need to run AureDump.ps1
This requires a user account and password and will:

1. Use Azure CLI to query for usernames, groups, applications, service principals, vm's, storage accounts, key vaults
2. Generate am Access Token
3. Run PowerZure 
4. Run AADInternals (Currently removed need to get this working)
5. Run AzureHound
6. Run RoadRecon
7. Get MFA status of all users

The output will default to a folder on your current users desktop.
Use http://127.0.0.1:5000 to check RoadRecon results
