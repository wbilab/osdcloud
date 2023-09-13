#================================================
#   [PreOS] Update Module
#================================================
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host  -ForegroundColor Green "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module PowerShellGet -Force -SkipPublisherCheck
Install-Module OSD -Force -SkipPublisherCheck
Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force    

#=======================================================================
#   [OS] Params and Start-OSDCloud
#=======================================================================
Write-Host -ForegroundColor Green "Create X:\OSDCloud\Automate\Start-OSDCloudGUI.json"
$OSDCloudGUIParam = @'
{
    "BrandName":  "",
    "OSActivation":  "Retail",
    "OSEdition":  "Pro",
    "OSLanguage":  "de-de",
    "OSImageIndex":  8,
    "OSName":  "Windows 11 22H2 x64",
    "OSReleaseID":  "22H2",
    "OSVersion":  "Windows 11",
    "OSActivationValues":  [
                                "Retail",
                                "Volume"
                            ],
    "OSEditionValues":  [
                            "Enterprise",
                            "Pro"
                        ],
    "OSLanguageValues":  [
                                "de-de",
                                "fr-fr"
                            ],
    "OSNameValues":  [
                            "Windows 11 22H2 x64",
                            "Windows 10 22H2 x64"
                        ],
    "OSReleaseIDValues":  [
                                "22H2"
                            ],
    "OSVersionValues":  [
                            "Windows 11",
                            "Windows 10"
                        ],
    "ClearDiskConfirm":  false,
    "restartComputer":  true,
    "updateDiskDrivers":  true,
    "updateFirmware":  true,
    "updateNetworkDrivers":  true,
    "SkipAutopilot":  false,
    "SkitAutopilotOOBE":  false,
    "SkipOOBEDeploy":  false
}
'@
If (!(Test-Path "X:\OSDCloud\Automate")) {
    New-Item "X:\OSDCloud\Automate" -ItemType Directory -Force | Out-Null
}
$OSDCloudGUIParam | Out-File -FilePath "X:\OSDCloud\Automate\Start-OSDCloudGUI.json" -Encoding ascii -Force

Start-OSDCloudGUI

#================================================
#  [PostOS] SetupComplete CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
$SetupCompleteCMD = @'
powershell.exe -Command Set-ExecutionPolicy RemoteSigned -Force
powershell.exe -Command "& {IEX (IRM https://raw.githubusercontent.com/wbilab/osdcloud/main/oobetasks.ps1)}"
'@
$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force

#=======================================================================
#   Restart-Computer
#=======================================================================
Write-Host  -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot