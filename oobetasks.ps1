$logonpfad = "$env:SystemDrive\WINDOWS\System32\GroupPolicy\User\Scripts\Logon"

$ScriptPathSendKeys = $(Join-Path -Path $logonpfad -ChildPath "1-SendKeys.ps1")
$ScriptPathOOBE = $(Join-Path -Path $logonpfad -ChildPath "2-OOBE.ps1")

# Überprüfe, ob der Ordner existiert. Wenn nicht, erstelle ihn.
if (-not (Test-Path -Path (Split-Path -Path $logonpfad))) {
    New-Item -Path $logonpfad -ItemType Directory -Force | Out-Null
    New-Item -Path "$env:SystemDrive\WINDOWS\System32\GroupPolicy\User\Scripts\Logoff" -ItemType Directory -Force | Out-Null
    New-Item -Path "$env:SystemDrive\WINDOWS\System32\GroupPolicy\Machine" -ItemType Directory -Force | Out-Null    
}


$SendKeysScript = @"
# Definieren Sie den Download-URL fuer nircmd und den Zielpfad zum Speichern
`$nircmdUrl = 'https://www.nirsoft.net/utils/nircmd-x64.zip'
`$downloadPath = 'C:\OSDCloud\nircmd.zip'

# Zielverzeichnis fuer die extrahierten Dateien
`$extractPath = 'C:\OSDCloud\nircmd'
`$extractPathexe = 'C:\OSDCloud\nircmd\nircmd.exe'

# Laden Sie nircmd herunter
Invoke-WebRequest -Uri `$nircmdUrl -OutFile `$downloadPath

# Entpacken Sie das ZIP-Archiv
Expand-Archive -Path `$downloadPath -DestinationPath `$extractPath -Force

# Warten fuer 3 Sekunden
Start-Sleep -Seconds 3

# Simulieren von 'Shift+F10'
#Start-Process -FilePath `$extractPathexe -ArgumentList 'sendkeypress Shift+F10' -Wait

# Warten fuer 5 Sekunden
#Start-Sleep -Seconds 5

# Simulieren von 'ALT+TAB'
#Start-Process -FilePath `$extractPathexe -ArgumentList 'sendkeypress Alt+Tab' -Wait


# === Shift+F10 mit Wiederholung Pruefung ===
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
    # Optional: Fensterwechsel, wenn cmd.exe im Hintergrund ist
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
`$Global:Transcript = "`$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OOBEScripts.log"
Start-Transcript -Path (Join-Path "`$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" `$Global:Transcript) -ErrorAction Ignore | Out-Null

Write-Host -ForegroundColor DarkGray "Installing OSD PS Module"
Start-Process PowerShell -ArgumentList "-NoL -C Install-Module OSD -Force -Verbose" -Wait

if ([System.Environment]::OSVersion.Version -ge (New-Object Version "10.0.22000.0")) {
write-Host -ForegroundColor DarkGray "Start Built-In Apps Cleanup"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/Windows11CleanupBuiltinApps.ps1" -Wait
}

Write-Host -ForegroundColor DarkGray "Executing Windows & Driver Update Installer"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/AutoInstall-WindowsUpdates.ps1" -Wait

Write-Host -ForegroundColor DarkGray "Executing Keyboard Language Skript"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/Set-KeyboardLanguage.ps1" -Wait

Write-Host -ForegroundColor DarkGray "Executing VISI Autopilot Registration"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/VISI_OSDCloud_AutoPilot.ps1" -Wait

#Write-Host -ForegroundColor DarkGray "Executing OOBEDeploy Script fomr OSDCloud Module"
#Start-Process PowerShell -ArgumentList "-NoL -C Start-OOBEDeploy" -Wait

Write-Host -ForegroundColor DarkGray "Executing Cleanup Script"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/wbilab/osdcloud/main/CleanUp.ps1" -Wait

Write-Host -ForegroundColor DarkGray "Restarting Computer"
Start-Process PowerShell -ArgumentList "-NoL -C Restart-Computer -Force" -Wait

Stop-Transcript -Verbose | Out-File
"@

Out-File -FilePath $ScriptPathOOBE -InputObject $OOBEScript -Encoding ascii