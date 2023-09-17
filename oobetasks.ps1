$logonpfad = "$env:SystemDrive\WINDOWS\System32\GroupPolicy\User\Scripts\Logon"

$ScriptPathOOBE = $(Join-Path -Path $logonpfad -ChildPath "OOBE.ps1")
$ScriptPathSendKeys = $(Join-Path -Path $logonpfad -ChildPath "SendKeys.ps1")

# Überprüfe, ob der Ordner existiert. Wenn nicht, erstelle ihn.
if (-not (Test-Path -Path (Split-Path -Path $logonpfad))) {
    New-Item -Path $logonpfad -ItemType Directory -Force | Out-Null
    New-Item -Path "$env:SystemDrive\WINDOWS\System32\GroupPolicy\User\Scripts\Logoff" -ItemType Directory -Force | Out-Null
    New-Item -Path "$env:SystemDrive\WINDOWS\System32\GroupPolicy\Machine" -ItemType Directory -Force | Out-Null    
}

$OOBEScript =@"
`$Global:Transcript = "`$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OOBEScripts.log"
Start-Transcript -Path (Join-Path "`$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" `$Global:Transcript) -ErrorAction Ignore | Out-Null

Write-Host -ForegroundColor DarkGray "Installing OSD PS Module"
Start-Process PowerShell -ArgumentList "-NoL -C Install-Module OSD -Force -Verbose" -Wait

Write-Host -ForegroundColor DarkGray "Executing Keyboard Language Skript"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/Set-KeyboardLanguage.ps1" -Wait

Write-Host -ForegroundColor DarkGray "Executing VISI Autopilot Registration"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/VISI_OSDCloud_AutoPilot.ps1" -Wait

#Write-Host -ForegroundColor DarkGray "Executing OOBEDeploy Script fomr OSDCloud Module"
#Start-Process PowerShell -ArgumentList "-NoL -C Start-OOBEDeploy" -Wait

if ([System.Environment]::OSVersion.Version -ge (New-Object Version "10.0.22000.0")) {
write-Host -ForegroundColor DarkGray "Start Built-In Apps Cleanup"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/Windows11CleanupBuiltinApps.ps1" -Wait
}
Write-Host -ForegroundColor DarkGray "Executing Cleanup Script"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/CleanUp.ps1" -Wait

Write-Host -ForegroundColor DarkGray "Restarting Computer"
Start-Process PowerShell -ArgumentList "-NoL -C Restart-Computer -Force" -Wait

Stop-Transcript -Verbose | Out-File
"@

Out-File -FilePath $ScriptPathOOBE -InputObject $OOBEScript -Encoding ascii

$SendKeysScript = @"
`$Global:Transcript = "`$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-SendKeys.log"
Start-Transcript -Path (Join-Path "`$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" `$Global:Transcript) -ErrorAction Ignore | Out-Null

Write-Host -ForegroundColor DarkGray "Stop Debug-Mode (SHIFT + F10) with WscriptShell.SendKeys"
`$WscriptShell = New-Object -com Wscript.Shell

# ALT + TAB
Write-Host -ForegroundColor DarkGray "SendKeys: ALT + TAB"
`$WscriptShell.SendKeys("%({TAB})")

Start-Sleep -Seconds 1

# Shift + F10
Write-Host -ForegroundColor DarkGray "SendKeys: SHIFT + F10"
`$WscriptShell.SendKeys("+({F10})")

Stop-Transcript -Verbose | Out-File
"@

Out-File -FilePath $ScriptPathSendKeys -InputObject $SendKeysScript -Encoding ascii

$psscriptsini = @"
`
[Logon]
0CmdLine=SendKeys.ps1
0Parameters=
1CmdLine=OOBE.ps1
1Parameters=
"@

Out-File -FilePath "C:\WINDOWS\System32\GroupPolicy\User\Scripts\psscripts.ini" -InputObject $psscriptsini -Encoding ascii -Force

$gpt = @"
`[General]
"@

Out-File -FilePath "C:\WINDOWS\System32\GroupPolicy\gpt.ini" -InputObject $gpt -Encoding ascii -Force

Set-ItemProperty -Path "C:\WINDOWS\System32\GroupPolicy" -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)
Set-ItemProperty -Path "C:\WINDOWS\System32\GroupPolicy\User\Scripts\psscripts.ini" -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)
