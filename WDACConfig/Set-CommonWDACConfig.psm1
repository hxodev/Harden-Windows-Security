#Requires -RunAsAdministrator
function Set-CommonWDACConfig {
    [CmdletBinding()]
    Param(
        [ValidatePattern('\.xml$')]
        [ValidateScript({               
                $_ | ForEach-Object {                   
                    $xmlTest = [xml](Get-Content $_)
                    $RedFlag1 = $xmlTest.SiPolicy.SupplementalPolicySigners.SupplementalPolicySigner.SignerId
                    $RedFlag2 = $xmlTest.SiPolicy.UpdatePolicySigners.UpdatePolicySigner.SignerId                    
                    if ($RedFlag1 -or $RedFlag2) {                          
                        return $True                       
                    }                    
                    else { throw 'The selected policy xml file is Unsigned, Please select a Signed policy.' }               
                }
            }, ErrorMessage = 'The selected policy xml file is Unsigned, Please select a Signed policy.')]
        [parameter(Mandatory = $false)][System.String]$SignedPolicyPath,

        [ValidatePattern('\.xml$')]
        [ValidateScript({
                $_ | ForEach-Object {                   
                    $xmlTest = [xml](Get-Content $_)
                    $RedFlag1 = $xmlTest.SiPolicy.SupplementalPolicySigners.SupplementalPolicySigner.SignerId
                    $RedFlag2 = $xmlTest.SiPolicy.UpdatePolicySigners.UpdatePolicySigner.SignerId                   
                    if (!$RedFlag1 -and !$RedFlag2) {                      
                        return $True
                    }                   
                    else { throw 'The selected policy xml file is Signed, Please select an Unsigned policy.' }                        
                }
            }, ErrorMessage = 'The selected policy xml file is Signed, Please select an Unsigned policy.')]
        [parameter(Mandatory = $false)][System.String]$UnsignedPolicyPath,

        [ValidatePattern('\.exe$')]
        [ValidateScript({ Test-Path $_ -PathType 'Leaf' }, ErrorMessage = 'The path you selected is not a file path.')]
        [parameter(Mandatory = $false)][System.String]$SignToolPath,
        
        [ValidateScript({
                $certs = foreach ($cert in (Get-ChildItem 'Cert:\CurrentUser\my')) {
            (($cert.Subject -split ',' | Select-Object -First 1) -replace 'CN=', '').Trim()
                } 
                $certs -contains $_
            }, ErrorMessage = "A certificate with the provided common name doesn't exist in the personal store of the user certificates." )]
        [parameter(Mandatory = $false)][System.String]$CertCN,

        [ValidatePattern('\.cer$')]
        [ValidateScript({ Test-Path $_ -PathType 'Leaf' }, ErrorMessage = 'The path you selected is not a file path.')]
        [parameter(Mandatory = $false)][System.String]$CertPath, 

        [parameter(Mandatory = $false)][switch]$DeleteUserConfig,

        [parameter(Mandatory = $false)][System.Guid]$StrictKernelPolicyGUID,
        [parameter(Mandatory = $false)][System.Guid]$StrictKernelNoFlightRootsPolicyGUID,
        
        [Parameter(Mandatory = $false)][Switch]$SkipVersionCheck
    )
    begin {
        # Importing resources such as functions by dot-sourcing so that they will run in the same scope and their variables will be usable
        . "$psscriptroot\Resources.ps1"
        
        # Stop operation as soon as there is an error anywhere, unless explicitly specified otherwise
        $ErrorActionPreference = 'Stop'        
        if (-NOT $SkipVersionCheck) { . Update-self }  

        # Create User configuration folder if it doesn't already exist
        if (-NOT (Test-Path -Path "$env:USERPROFILE\.WDACConfig\")) {
            New-Item -ItemType Directory -Path "$env:USERPROFILE\.WDACConfig\" -Force -ErrorAction Stop | Out-Null
            Write-Debug -Message "The .WDACConfig folder in current user's folder has been created because it didn't exist."
        }

        # Create User configuration file if it doesn't already exist
        if (-NOT (Test-Path -Path "$env:USERPROFILE\.WDACConfig\UserConfigurations.json")) { 
            New-Item -ItemType File -Path "$env:USERPROFILE\.WDACConfig\" -Name 'UserConfigurations.json' -Force -ErrorAction Stop | Out-Null
            Write-Debug -Message "The UserConfigurations.json file in \.WDACConfig\ folder has been created because it didn't exist."
        }

        if ($DeleteUserConfig) {        
            Remove-Item -Path "$env:USERPROFILE\.WDACConfig\" -Recurse -Force
            &$WritePink 'User Configurations for WDACConfig module have been deleted.'
            break
        }

        # Scan the file with Microsoft Defender for anything malicious before it's going to be used
        Start-MpScan -ScanType CustomScan -ScanPath "$env:USERPROFILE\.WDACConfig\UserConfigurations.json"
        
        if ($PSBoundParameters.Count -eq 0) {
            Write-Error 'No parameter was selected.'
            break
        }

        # Read the current user configurations
        $CurrentUserConfigurations = Get-Content -Path "$env:USERPROFILE\.WDACConfig\UserConfigurations.json"
        # If the file exists but is corrupted and has bad values, rewrite it
        try {
            $CurrentUserConfigurations = $CurrentUserConfigurations | ConvertFrom-Json
        }
        catch {
            Set-Content -Path "$env:USERPROFILE\.WDACConfig\UserConfigurations.json" -Value ''
        }

        # An object to hold the User configurations
        $UserConfigurationsObject = [PSCustomObject]@{
            SignedPolicyPath                    = ''
            UnsignedPolicyPath                  = ''
            SignToolCustomPath                  = ''
            CertificateCommonName               = ''
            CertificatePath                     = ''
            StrictKernelPolicyGUID              = ''
            StrictKernelNoFlightRootsPolicyGUID = ''
        }
    }
    process {

        if ($SignedPolicyPath) {
            $UserConfigurationsObject.SignedPolicyPath = $SignedPolicyPath
        }
        else {
            $UserConfigurationsObject.SignedPolicyPath = $CurrentUserConfigurations.SignedPolicyPath
        }

        if ($UnsignedPolicyPath) {
            $UserConfigurationsObject.UnsignedPolicyPath = $UnsignedPolicyPath
        }
        else {
            $UserConfigurationsObject.UnsignedPolicyPath = $CurrentUserConfigurations.UnsignedPolicyPath
        }

        if ($SignToolPath) {
            $UserConfigurationsObject.SignToolCustomPath = $SignToolPath
        }
        else {
            $UserConfigurationsObject.SignToolCustomPath = $CurrentUserConfigurations.SignToolCustomPath
        }

        if ($CertPath) {
            $UserConfigurationsObject.CertificatePath = $CertPath
        }
        else {
            $UserConfigurationsObject.CertificatePath = $CurrentUserConfigurations.CertificatePath
        }

        if ($CertCN) {
            $UserConfigurationsObject.CertificateCommonName = $CertCN
        }        
        else {
            $UserConfigurationsObject.CertificateCommonName = $CurrentUserConfigurations.CertificateCommonName
        }

        if ($StrictKernelPolicyGUID) {
            $UserConfigurationsObject.StrictKernelPolicyGUID = $StrictKernelPolicyGUID
        }
        else {
            $UserConfigurationsObject.StrictKernelPolicyGUID = $CurrentUserConfigurations.StrictKernelPolicyGUID
        }

        if ($StrictKernelNoFlightRootsPolicyGUID) {
            $UserConfigurationsObject.StrictKernelNoFlightRootsPolicyGUID = $StrictKernelNoFlightRootsPolicyGUID
        }
        else {
            $UserConfigurationsObject.StrictKernelNoFlightRootsPolicyGUID = $CurrentUserConfigurations.StrictKernelNoFlightRootsPolicyGUID
        }

    }
    end {
        # Update the User Configurations file
        $UserConfigurationsObject | ConvertTo-Json | Set-Content "$env:USERPROFILE\.WDACConfig\UserConfigurations.json"                
        &$WritePink "`nThis is your new WDAC User Configurations: "
        Get-Content -Path "$env:USERPROFILE\.WDACConfig\UserConfigurations.json" | ConvertFrom-Json | Format-List *
    }
}
<#
.SYNOPSIS
Add/Remove/Change common values for parameters used by WDACConfig module

.LINK
https://github.com/HotCakeX/Harden-Windows-Security/wiki/Set-CommonWDACConfig

.DESCRIPTION
Add/Remove/Change common values for parameters used by WDACConfig module so that you won't have to provide values for those repetitive parameters each time you need to use the WDACConfig module cmdlets.

.COMPONENT
Windows Defender Application Control, ConfigCI PowerShell module, WDACConfig module

.FUNCTIONALITY
Add/Remove/Change common values for parameters used by WDACConfig module so that you won't have to provide values for those repetitive parameters each time you need to use the WDACConfig module cmdlets.

.PARAMETER SignedPolicyPath
Path to a Signed WDAC xml policy

.PARAMETER UnsignedPolicyPath
Path to an Unsigned WDAC xml policy

.PARAMETER CertCN
Certificate common name

.PARAMETER SignToolPath
Path to the SignTool.exe

.PARAMETER CertPath
Path to a .cer certificate file

.PARAMETER StrictKernelPolicyGUID
GUID of the Strict Kernel mode policy

.PARAMETER StrictKernelNoFlightRootsPolicyGUID
GUID of the Strict Kernel no Flights root mode policy

.PARAMETER DeleteUserConfig
Deletes the .WDACConfig directory in User directory and all of the files in it

.PARAMETER SkipVersionCheck
Can be used with any parameter to bypass the online version check - only to be used in rare cases

#>

# Importing argument completer ScriptBlocks
. "$psscriptroot\ArgumentCompleters.ps1"
# Set PSReadline tab completion to complete menu for easier access to available parameters - Only for the current session
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Register-ArgumentCompleter -CommandName 'Set-CommonWDACConfig' -ParameterName 'CertCN' -ScriptBlock $ArgumentCompleterCertificateCN
Register-ArgumentCompleter -CommandName 'Set-CommonWDACConfig' -ParameterName 'CertPath' -ScriptBlock $ArgumentCompleterCerFilePathsPicker
Register-ArgumentCompleter -CommandName 'Set-CommonWDACConfig' -ParameterName 'SignToolPath' -ScriptBlock $ArgumentCompleterExeFilePathsPicker
Register-ArgumentCompleter -CommandName 'Set-CommonWDACConfig' -ParameterName 'SignedPolicyPath' -ScriptBlock $ArgumentCompleterPolicyPathsBasePoliciesOnly
Register-ArgumentCompleter -CommandName 'Set-CommonWDACConfig' -ParameterName 'UnsignedPolicyPath' -ScriptBlock $ArgumentCompleterPolicyPathsBasePoliciesOnly
