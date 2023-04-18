# AzureDump
Powershell Script to enumerate AzureAD and output good data

AzureDumpInstaller.ps1 will install the necessary AZ modules as well as the following tools: AADInternals by @DrAzureAD, PowerZure by @haus3c, AzureHound by the folks at bloodhound, python 3.7 (seemed to be the version required), and RoadRecon by Dirk-jan.

It is meant to be installed onto a fresh virtual machine for each tenant you are auditing. There are no logout functions so use this carefully. Tested on Windows 11. 

1. Run the installer (Might have to turn off defender) 
3. Choose what other tools you want to run (RoadRecon,CRT, etc.) by editing tthe config.json file
4. Ensure you put everything onto the Desktop and keep all names the same
5. Set the execution policy to bypass/unrestricted and unblock the file
6. Run ./AzureHound.ps1

This can be used by both red and blue teams. If you find a low priv account connected to azure it is possilbe to gather a ton of good data. It's really good if you find yourself on a low privledged account and want to gather email addresses and phone numbers for phishing/vhishing.  For blue teams it can be used as an auditing tool to check for misconfigurations and to lock down unecessary data. Examples of this are the MFA check, legacy protocols check, Global Admin list, and the Applications with credentials. I have also found some very interesting stuff in the application URL's so give that a once over and see whay you can find. 

![image](https://user-images.githubusercontent.com/78559938/232842614-0d34bd80-7c54-4439-a627-58d93d4ffb30.png)

Another cool feature I included was the token grabber from AzureHound. This  can be used in a varity of ways, so if the script does't work you can just copy those and try to login. It uses the device code login function. 

![image](https://user-images.githubusercontent.com/78559938/232844448-31824177-896a-4278-8923-8b8adb54756d.png)

I originally had included an option of how you wanted to login (user/pass, device code) but just settled on user prompts as MFA seems like it's going to be the norm. 

Things to do:
1. Clean up the output
2. Fix some functionality 
3. Get less login prompts
4. Add more tools and features
