# Remove-WDACConfig available parameters

## Notes

* **Mandatory** parameters indicate you always need to provide values for them.

* **Automatic** parameters indicate that if you used [Set-CommonWDACConfig](https://github.com/HotCakeX/Harden-Windows-Security/wiki/Set-CommonWDACConfig) cmdlet to set default values for them, the module will automatically use them. This saves time and prevents repetitive tasks. However, if no value exists in User Configurations for an Automatic parameter and you didn't explicitly provide a value for that parameter either, then you will see an error asking you to provide value for it. Explicitly providing a value for an Automatic parameter in the command line overrides its default value in User Configurations, meaning the module will ignore the value of the same parameter in the User Configurations file.

* **Optional** parameters indicate that they are not required and without using them the module will automatically run with the optimal settings.

* Many cmdlets and parameters of the module support the PowerShell's built-in `-Debug` switch and when that switch is used, they display extra details and debugging messages on the console, showing you what's happening under the hood.

<br>

## Remove-WDACConfig -SignedBase

![image](https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/Wiki%20APNGs/Remove-WDACConfig%20-RemoveSignedPolicies.apng)

```powershell
Remove-WDACConfig [-SignedBase] -PolicyPaths <String[]> -CertCN <String> [-SignToolPath <String>]
```

<br>

Uses [the official procedure](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/deployment/disable-wdac-policies) to Re-Deploy the Signed base WDAC policies with ***Enabled:Unsigned System Integrity Policy*** rule option.

### 1 mandatory parameter

* `-PolicyPaths <String[]`: Path to xml file(s) of the currently deployed policy that you want to remove, can be multiple. Supports tab completion by showing only `.xml` files.

### 2 Automatic parameters

* `-SignToolPath <String>`: [You can use it in 2 different ways](#the-logic-behind--signtoolpath-string-optional-parameter)

* `-CertCN <String>`: Common name of the certificate used to sign the deployed WDAC policies - Supports argument completion so you don't have to manually enter the Certificate's CN, just make sure the certificate is installed in the personal store of the user certificates, then press TAB to auto complete the name. You can however enter it manually if you want to.

<br>

<img src="https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/Gifs/1pxRainbowLine.gif" width= "300000" alt="horizontal super thin rainbow RGB line">

<br>

## Remove-WDACConfig -UnsignedOrSupplemental

![image](https://github.com/HotCakeX/Harden-Windows-Security/raw/main/images/Wiki%20APNGs/Remove-WDACConfig%20-UnsignedOrSupplemental.apng)

```powershell
Remove-WDACConfig [-UnsignedOrSupplemental] [-PolicyIDs <String[]>] [-PolicyNames <String[]>]
```

<br>

Removes Unsigned deployed WDAC policies as well as [Signed deployed Supplemental WDAC policies](https://github.com/HotCakeX/Harden-Windows-Security/wiki/WDAC-Notes#removing-supplemental-policies)

### 2 parameters

* `-PolicyIDs <String[]>`
* `-PolicyNames <String[]>`

You can choose either of them or both of them, at the same time, but you do need to use one of them at least.

They use argument completion with ValidateSet, meaning you can't specify wrong PolicyIDs or PolicyNames, just press TAB key and it will autofill the arguments for you based on the deployed policies. If you want to select multiple items, after each one, enter a comma `,` and then press TAB again to choose another Name/ID.

For example, you can specify 2 policies by IDs and 3 policies by names, and it will automatically remove all of them.

**Hint:** First use [-ListActivePolicies](https://github.com/HotCakeX/Harden-Windows-Security/wiki/Confirm-WDACConfig#confirm-wdacconfig--listactivepolicies) parameter to list the deployed policies on the screen.

**Hint 2:** When using `-PolicyNames <String[]>` parameter, if multiple policies with the exact same name are deployed, when you press TAB, you will only see 1 of them, if you select it, all of the policies with that name will be removed. If that's not desired, consider using `-PolicyIDs <String[]>` parameter instead.

**Hint 3:** The argument completers on this parameter are very smart. E.g., if there are 10 policies deployed on the system and you use argument Tab completion to select 5 of them by IDs, when you try to select the other 5 by their names, the name of the policies that you already selected by IDs don't show up anymore. This greatly reduces user error and simplifies the workflow for end user.

<br>

### The logic behind `-SignToolPath <String>` optional parameter

1. If [Windows SDK](https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/) Signing Tools for Desktop Apps components is installed in the default location `C:\Program Files (x86)\Windows Kits`, then `-SignToolPath <String>` parameter isn't necessary.

2. If Windows SDK Signing Tools for Desktop Apps components is not installed in the default location or you want to manually browse for the `signtool.exe`, then make sure you use the `-SignToolPath <String>` parameter.
