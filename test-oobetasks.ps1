Write-Host -ForegroundColor DarkGray "Disable Bitlocker Win11 24H2"
REG ADD HKLM\SYSTEM\CurrentControlSet\Control\BitLocker /v PreventDeviceEncryption /t REG_DWORD /d 1 /f

$logonpfad = "$env:SystemDrive\WINDOWS\System32\GroupPolicy\User\Scripts\Logon"

$ScriptPathSendKeys = $(Join-Path -Path $logonpfad -ChildPath "1-SendKeys.ps1")
$ScriptPathOOBE = $(Join-Path -Path $logonpfad -ChildPath "2-OOBE.ps1")

if (-not (Test-Path -Path (Split-Path -Path $logonpfad))) {
    New-Item -Path $logonpfad -ItemType Directory -Force | Out-Null
    New-Item -Path "$env:SystemDrive\WINDOWS\System32\GroupPolicy\User\Scripts\Logoff" -ItemType Directory -Force | Out-Null
    New-Item -Path "$env:SystemDrive\WINDOWS\System32\GroupPolicy\Machine" -ItemType Directory -Force | Out-Null    
}

$SendKeysScript = @"
`$nircmdUrl = 'https://www.nirsoft.net/utils/nircmd-x64.zip'
`$downloadPath = 'C:\OSDCloud\nircmd.zip'
`$extractPath = 'C:\OSDCloud\nircmd'
`$extractPathexe = 'C:\OSDCloud\nircmd\nircmd.exe'

if (-not (Test-Path 'C:\OSDCloud')) { New-Item -Path 'C:\OSDCloud' -ItemType Directory -Force | Out-Null }
Invoke-WebRequest -Uri `$nircmdUrl -OutFile `$downloadPath
Expand-Archive -Path `$downloadPath -DestinationPath `$extractPath -Force
Start-Sleep -Seconds 3

`$maxRetries = 5
`$success = `$false

for (`$i = 1; `$i -le `$maxRetries; `$i++) {
    Write-Host "[`$i/`$maxRetries] Shift+F10 senden..."
    Start-Process -FilePath `$extractPathexe -ArgumentList 'sendkeypress shift+f10' -Wait
    Start-Sleep -Seconds 3

    if (Get-Process -Name "cmd" -ErrorAction SilentlyContinue) {
        Write-Host "cmd.exe erkannt Shift+F10 war erfolgreich."
        `$success = `$true
        break
    } else {
        Write-Warning "cmd.exe nicht erkannt. Nächster Versuch..."
    }
}

if (-not `$success) {
    Write-Error "Shift+F10 konnte nicht erfolgreich ausgeführt werden."
} else {
    Start-Process -FilePath `$extractPathexe -ArgumentList 'sendkeypress Alt+Tab' -Wait
}
"@

Out-File -FilePath $ScriptPathSendKeys -InputObject $SendKeysScript -Encoding ascii

$psscriptsini = @"
`
[Logon]
0CmdLine=1-SendKeys.ps1 
0Parameters=
1CmdLine=2-OOBE.ps1
1Parameters=
"@

Out-File -FilePath "C:\WINDOWS\System32\GroupPolicy\User\Scripts\psscripts.ini" -InputObject $psscriptsini -Encoding ascii -Force

$gpt = @"
`[General]
gPCUserExtensionNames=[{42B5FAAE-6536-11D2-AE5A-0000F87571E3}{40B66650-4972-11D1-A7CA-0000F87571E3}]
Version=65536
"@

Out-File -FilePath "C:\WINDOWS\System32\GroupPolicy\gpt.ini" -InputObject $gpt -Encoding ascii -Force

Set-ItemProperty -Path "C:\WINDOWS\System32\GroupPolicy" -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)
Set-ItemProperty -Path "C:\WINDOWS\System32\GroupPolicy\User\Scripts\psscripts.ini" -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)

$OOBEScript =@"
if (-not (Test-Path 'C:\OSDCloud')) { New-Item -Path 'C:\OSDCloud' -ItemType Directory -Force | Out-Null }
`$Global:Transcript = "`$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OOBEScripts.log"
Start-Transcript -Path "C:\OSDCloud\`$Global:Transcript" -ErrorAction Ignore | Out-Null

Write-Host -ForegroundColor DarkGray "Installing OSD PS Module"
Start-Process PowerShell -ArgumentList "-NoL -C Install-Module OSD -Force -Verbose" -Wait

if ([System.Environment]::OSVersion.Version -ge (New-Object Version "10.0.22000.0")) {
    write-Host -ForegroundColor DarkGray "Start Built-In Apps Cleanup"
    Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/Windows11CleanupBuiltinApps.ps1" -Wait
}

Write-Host -ForegroundColor DarkGray "Executing Keyboard Language Skript"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/Set-KeyboardLanguage.ps1" -Wait

Write-Host -ForegroundColor DarkGray "Executing VISI Autopilot Registration"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/test-VISI_OSDCloud_AutoPilot.ps1" -Wait

`$FlagPath = "C:\OSDCloud\AutopilotDone.flag"
Write-Host -ForegroundColor DarkGray "Waiting for Autopilot process to finalize..."
while (-not (Test-Path -Path `$FlagPath)) {
    Start-Sleep -Seconds 5
}

`$AutoPilotResult = Get-Content -Path `$FlagPath
Remove-Item -Path `$FlagPath -Force -ErrorAction SilentlyContinue

if (`$AutoPilotResult -eq "Aborted") {
    Write-Warning "Autopilot-Registrierung wurde vom Benutzer übersprungen/abgebrochen."
} else {
    Write-Host -ForegroundColor Green "Autopilot-Registrierung abgeschlossen."
}

# --- Englisches Pop-up mit 60-Sekunden-Timer (Im Vordergrund) ---
`$wshell = New-Object -ComObject WScript.Shell
# 4 = Yes/No, 32 = Question Icon, 4096 = System Modal (Zwingt das Fenster in den Vordergrund)
`$answer = `$wshell.Popup("Do you want to install Windows and Driver Updates now?`n`nAuto-starting in 60 seconds.", 60, "Install Updates?", 4 + 32 + 4096)

if (`$answer -eq 7) {
    Write-Host -ForegroundColor Yellow "Updates skipped by user."
} else {
    Write-Host -ForegroundColor DarkGray "Executing Windows & Driver Update Installer"
    Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/test-AutoInstall-WindowsUpdates.ps1" -Wait
}

Write-Host -ForegroundColor DarkGray "Executing Cleanup Script"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/CleanUp.ps1" -Wait

Write-Host -ForegroundColor DarkGray "Restarting Computer"
Start-Process PowerShell -ArgumentList "-NoL -C Restart-Computer -Force" -Wait

Stop-Transcript -Verbose | Out-File
"@

Out-File -FilePath $ScriptPathOOBE -InputObject $OOBEScript -Encoding ascii