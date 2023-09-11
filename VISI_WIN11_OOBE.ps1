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
$Params = @{
    OSVersion = "Windows 11"
    OSBuild = "22H2"
    OSEdition = "Pro"
    OSLanguage = "en-us"
    OSLicense = "Retail"
    ZTI = $true
    Firmware = $false
}
Start-OSDCloud @Params

#================================================
#  [PostOS] AutopilotOOBE Configuration Staging
#================================================
Write-Host -ForegroundColor Green "Define Computername:"
$Serial = Get-WmiObject Win32_bios | Select-Object -ExpandProperty SerialNumber
$TargetComputername = $Serial.Substring(4,3)

$AssignedComputerName = "AkosCloud-$TargetComputername"
Write-Host -ForegroundColor Red $AssignedComputerName
Write-Host ""

Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json"
$AutopilotOOBEJson = @"
{
    "AssignedComputerName" : "",
    "AddToGroup":  "AADGroupX",
    "Assign":  {
                   "IsPresent":  true
               },
    "GroupTag": [
                   "InCloud",
                   "Hybrid",
                   "Thinclient",
                   "CH",
                   "DE",
                   "AT",
                   ""
               ],
    "Hidden":  [
                   "AssignedComputerName",
                   "AddToGroup",
                   "AssignedUser",
                   "PostAction",
                   "Run",
                   "Docs",
                   "Assign"
               ],
    "PostAction":  "Quit",
    "Run":  "NetworkingWireless",
    "Docs":  "https://google.com/",
    "Title":  "Autopilot Manual Register"
}
"@

If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$AutopilotOOBEJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json" -Encoding ascii -Force

#================================================
#  [PostOS] SetupComplete CMD Command Line
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
$SetupCompleteCMD = @'
powershell.exe -Command Set-ExecutionPolicy RemoteSigned -Force
powershell.exe -Command "& {IEX (IRM oobetasks.osdcloud.ch)}"
'@
$SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force

#=======================================================================
#   Restart-Computer
#=======================================================================
Write-Host  -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot