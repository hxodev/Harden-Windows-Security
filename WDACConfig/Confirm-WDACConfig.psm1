#Requires -RunAsAdministrator
function Confirm-WDACConfig {
    [CmdletBinding(DefaultParameterSetName = 'List Active Policies')]
    Param(
        [Alias('L')]
        [Parameter(Mandatory = $false, ParameterSetName = 'List Active Policies')][Switch]$ListActivePolicies,
        [Alias('V')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Verify WDAC Status')][Switch]$VerifyWDACStatus,
        [Alias('S')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Check SmartAppControl Status')][Switch]$CheckSmartAppControlStatus,

        [Parameter(Mandatory = $false, ParameterSetName = 'List Active Policies')][Switch]$OnlyBasePolicies,
        [Parameter(Mandatory = $false, ParameterSetName = 'List Active Policies')][Switch]$OnlySupplementalPolicies,
        
        [Parameter(Mandatory = $false)][Switch]$SkipVersionCheck
    )

    begin {
        # Importing resources such as functions by dot-sourcing so that they will run in the same scope and their variables will be usable
        . "$psscriptroot\Resources.ps1"

        # Stop operation as soon as there is an error anywhere, unless explicitly specified otherwise
        $ErrorActionPreference = 'Stop'         
        if (-NOT $SkipVersionCheck) { . Update-self }        

        # Script block to show only non-system Base policies
        [scriptblock]$OnlyBasePoliciesBLOCK = {
            $BasePolicies = (CiTool -lp -json | ConvertFrom-Json).Policies | Where-Object { $_.IsSystemPolicy -ne 'True' } | Where-Object { $_.PolicyID -eq $_.BasePolicyID }           
            &$WriteLavender "`nThere are currently $(($BasePolicies.count)) Non-system Base policies deployed"
            $BasePolicies
        }
        # Script block to show only non-system Supplemental policies
        [scriptblock]$OnlySupplementalPoliciesBLOCK = {
            $SupplementalPolicies = (CiTool -lp -json | ConvertFrom-Json).Policies | Where-Object { $_.IsSystemPolicy -ne 'True' } | Where-Object { $_.PolicyID -ne $_.BasePolicyID }           
            &$WriteLavender "`nThere are currently $(($SupplementalPolicies.count)) Non-system Supplemental policies deployed`n"
            $SupplementalPolicies
        } 
        
        # If no parameters were passed run all of them
        if ($PSBoundParameters.Count -eq 0) {
            $ListActivePolicies = $true
            $VerifyWDACStatus = $true
            $CheckSmartAppControlStatus = $true
        }
    }

    process {
        if ($ListActivePolicies) {
            if ($OnlyBasePolicies) { &$OnlyBasePoliciesBLOCK }
            if ($OnlySupplementalPolicies) { &$OnlySupplementalPoliciesBLOCK }               
            if (!$OnlyBasePolicies -and !$OnlySupplementalPolicies) { &$OnlyBasePoliciesBLOCK; &$OnlySupplementalPoliciesBLOCK }
        }
        
        if ($VerifyWDACStatus) {
            Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard | Select-Object -Property *codeintegrity* | Format-List
            &$WriteLavender "2 -> Enforced`n1 -> Audit mode`n0 -> Disabled/Not running`n"
        }

        if ($CheckSmartAppControlStatus) {
            Get-MpComputerStatus | Select-Object -Property SmartAppControlExpiration, SmartAppControlState
            if ((Get-MpComputerStatus).SmartAppControlState -eq 'Eval') {
                &$WritePink "`nSmart App Control is in Evaluation mode."
            }
            elseif ((Get-MpComputerStatus).SmartAppControlState -eq 'On') {
                &$WritePink "`nSmart App Control is turned on."
            }
            elseif ((Get-MpComputerStatus).SmartAppControlState -eq 'Off') {
                &$WritePink "`nSmart App Control is turned off."
            }
        }            
    }
    
    <#
.SYNOPSIS
Show the status of WDAC on the system and lists the current deployed policies and shows details about each of them

.LINK
https://github.com/HotCakeX/Harden-Windows-Security/wiki/Confirm-WDACConfig

.DESCRIPTION
Using official Microsoft methods, Show the status of WDAC (Windows Defender Application Control) on the system, list the current deployed policies and show details about each of them.

.COMPONENT
Windows Defender Application Control, ConfigCI PowerShell module

.FUNCTIONALITY
Using official Microsoft methods, Show the status of WDAC (Windows Defender Application Control) on the system, list the current deployed policies and show details about each of them.

.PARAMETER ListActivePolicies
Lists the currently deployed policies and shows details about each of them

.PARAMETER VerifyWDACStatus
Shows the status of WDAC (Windows Defender Application Control) on the system

.PARAMETER CheckSmartAppControlStatus
Checks the status of Smart App Control and reports the results on the console

.PARAMETER SkipVersionCheck
Can be used with any parameter to bypass the online version check - only to be used in rare cases

#> 
}

# Set PSReadline tab completion to complete menu for easier access to available parameters - Only for the current session
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
