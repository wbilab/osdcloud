$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Cleanup-Script.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore

Write-Host "Execute OSD Cloud Cleanup Script" -ForegroundColor Green

# Copying the OOBEDeploy and AutopilotOOBE Logs
Get-ChildItem 'C:\Windows\Temp' -Filter *OOBE* | Copy-Item -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force

# Copying OSDCloud Logs
If (Test-Path -Path 'C:\OSDCloud\Logs') {
    Move-Item 'C:\OSDCloud\Logs\*.*' -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force
}
Move-Item 'C:\ProgramData\OSDeploy\*.*' -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force

If (Test-Path -Path 'C:\Temp') {
    Get-ChildItem 'C:\Temp' -Filter *OOBE* | Copy-Item -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force
    Get-ChildItem 'C:\Windows\Temp' -Filter *Events* | Copy-Item -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force
}

# Cleanup directories
If (Test-Path -Path 'C:\OSDCloud') { Remove-Item -Path 'C:\OSDCloud' -Recurse -Force }
If (Test-Path -Path 'C:\OSDCloud\nircmd.zip') { Remove-Item -Path 'C:\OSDCloud\nircmd.zip' -Recurse -Force }
If (Test-Path -Path 'C:\WINDOWS\System32\GroupPolicy\Machine') { Remove-Item 'C:\WINDOWS\System32\GroupPolicy\Machine' -Recurse -Force }
If (Test-Path -Path 'C:\WINDOWS\System32\GroupPolicy\User\Scripts\Logon') { Remove-Item 'C:\WINDOWS\System32\GroupPolicy\User\Scripts\Logon\1-SendKeys.ps1' -Recurse -Force }
If (Test-Path -Path 'C:\WINDOWS\System32\GroupPolicy\User\Scripts\Logon') { Remove-Item 'C:\WINDOWS\System32\GroupPolicy\User\Scripts\Logon\2-OOBE.ps1' -Recurse -Force }
If (Test-Path -Path 'C:\WINDOWS\System32\GroupPolicy\gpt.ini') { Remove-Item 'C:\WINDOWS\System32\GroupPolicy\gpt.ini' -Recurse -Force }
If (Test-Path -Path 'C:\WINDOWS\System32\GroupPolicy\User\Scripts\psscripts.ini') { Remove-Item 'C:\WINDOWS\System32\GroupPolicy\User\Scripts\psscripts.ini' -Recurse -Force }
If (Test-Path -Path 'C:\Drivers') { Remove-Item 'C:\Drivers' -Recurse -Force }
#If (Test-Path -Path 'C:\Temp') { Remove-Item 'C:\Temp' -Recurse -Force }
Get-ChildItem 'C:\Windows\Temp' -Filter *membeer*  | Remove-Item -Force

Stop-Transcript