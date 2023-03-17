# AzureDump
Powershell Script to enumerate AzureAD and output good data

AzureDumpInstaller.ps1 will install the necessary AZ modules as well as the following tools: AADInternals by @DrAzureAD, PowerZure by @haus3c, AzureHound by the folks at bloodhound, python 3.7 (seemed to be the version required), and RoadRecon by Dirk-jan.

It is meant to be installed onto a fresh virtual machine for each tenant you are auditing. There are no logout functions so use this carefully. Tested on Windows 11. 

1. Run the installer 
2. Run AzureDump
3. Choose what other tools you want to run (RoadRecon,CRT, etc.)
4. Run AzureGRAPHDump

This can be used by both red and blue teams. If you find a low priv account connected to azure it is possilbe to gather a ton of good data. It's most likely going to set off alerts. For blue teams it can be used as an auditing tool to check for misconfigurations and to lock down unecessary data.
