#================================================
#   [PreOS] Update Module
#================================================
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host  -ForegroundColor Green "Setting Display Resolution to 1400x"
    Set-DisRes 1400
}
else{
    Write-Host  -ForegroundColor Green "Setting Display Resolution to 1920x"
    Set-DisRes 1920
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
    "OSImageIndex":  9,
    "OSName":  "Windows 11 23H2 x64",
    "OSReleaseID":  "23H2",
    "OSVersion":  "Windows 11",
    "OSActivationValues":  [
                                "Retail",
                                "Volume"
                            ],
    "OSEditionValues":  [
                            "Pro",
                            "Enterprise"
                        ],
    "OSLanguageValues":  [
                                "de-de",
                                "fr-fr",
                                "it-it",
                                "en-us"
                            ],
    "OSNameValues":  [
                            "Windows 11 23H2 x64",
                            "Windows 11 24H2 x64",
                            "Windows 10 22H2 x64"
                        ],
    "OSReleaseIDValues":  [
                                "23H2",
                                "24H2"
                            ],
    "OSVersionValues":  [
                            "Windows 11",
                            "Windows 10"
                        ],
    "ClearDiskConfirm":  false,
    "restartComputer":  false,
    "updateDiskDrivers":  true,
    "updateFirmware":  true,
    "updateNetworkDrivers":  true,
    "SkipAutopilot":  true,
    "SkitAutopilotOOBE":  true,
    "SkipOOBEDeploy":  true,
    "HPIAALL": false,
    "HPIADrivers": true,
    "HPIAFirmware": false,
    "HPIASoftware": true,
    "HPTPMUpdate": false,
    "HPBIOSUpdate": true

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