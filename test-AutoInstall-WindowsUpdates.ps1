Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Logging setup
$LogDir = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD"
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
$LogFile = Join-Path $LogDir "WindowsUpdateLog_$(Get-Date -Format yyyyMMdd_HHmmss).txt"
New-Item -ItemType File -Path $LogFile -Force | Out-Null

# GUI Setup
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows & Driver Update Installer"
$form.Width = 800
$form.Height = 600
$form.TopMost = $true
$form.StartPosition = 'CenterScreen'

$listbox = New-Object System.Windows.Forms.ListBox
$listbox.Dock = 'Top'
$listbox.Height = 500
$listbox.Font = 'Consolas,10'
$form.Controls.Add($listbox)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Text = "Cancel Updates"
$CancelButton.Dock = 'Bottom'
$CancelButton.Height = 50
$CancelButton.BackColor = 'LightCoral'
$CancelButton.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($CancelButton)

$Global:LastLineRead = 0

# --- HINTERGRUND-PROZESS ---
# Dieser Block läuft entkoppelt vom Fenster im Hintergrund
$UpdateScript = {
    param($LogFilePath)
    
    function LogIt($text) { 
        "[$((Get-Date).ToString('HH:mm:ss'))] $text" | Out-File -FilePath $LogFilePath -Append -Encoding UTF8 
    }
    
    LogIt "Initializing update engine in background..."
    Try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
        Install-Module -Name PSWindowsUpdate -Force -AllowClobber -ErrorAction Stop | Out-Null
        LogIt "PSWindowsUpdate module installed."
        
        Import-Module PSWindowsUpdate
        Add-WUServiceManager -MicrosoftUpdate -Confirm:$false | Out-Null
        LogIt "Microsoft Update enabled. Scanning for updates..."
        
        $updates = Get-WindowsUpdate -MicrosoftUpdate -ErrorAction Stop
        
        if ($updates.Count -eq 0) {
            LogIt "No updates available."
        } else {
            LogIt "Found $($updates.Count) update(s). Starting installation..."
            foreach ($update in $updates) {
                LogIt "Installing: $($update.Title)"
                if ($update.KBArticleID) {
                    Install-WindowsUpdate -KBArticleID $update.KBArticleID -AcceptAll -IgnoreReboot -Confirm:$false | Out-Null
                } else {
                    Install-WindowsUpdate -Title $update.Title -AcceptAll -IgnoreReboot -Confirm:$false | Out-Null
                }
                LogIt "Done: $($update.Title)"
            }
            LogIt "Update process finished."
        }
    } Catch {
        LogIt "Error: $_"
    }
    LogIt "---END---"
}

# Starte den Hintergrund-Prozess
$Job = Start-Job -ScriptBlock $UpdateScript -ArgumentList $LogFile

# --- TIMER (Aktualisiert das GUI flüssig) ---
$Timer = New-Object System.Windows.Forms.Timer
$Timer.Interval = 1000 # 1 Sekunde
$Timer.Add_Tick({
    # Lese neue Zeilen aus der Log-Datei
    $content = Get-Content $LogFile -ErrorAction SilentlyContinue
    if ($content -and $content.Count -gt $Global:LastLineRead) {
        for ($i = $Global:LastLineRead; $i -lt $content.Count; $i++) {
            $listbox.Items.Add($content[$i])
            
            # Prüfen ob Hintergrundprozess fertig ist
            if ($content[$i] -match "---END---") {
                $Timer.Stop()
                $CancelButton.Text = "Close Window"
                $CancelButton.BackColor = 'LightGreen'
            }
        }
        $Global:LastLineRead = $content.Count
        $listbox.TopIndex = $listbox.Items.Count - 1
    }
    
    # Notfall-Check, falls der Job abstürzt
    if ($Job.State -ne 'Running' -and $Timer.Enabled) {
        $Timer.Stop()
        $CancelButton.Text = "Close Window"
        $CancelButton.BackColor = 'LightGreen'
    }
})

# --- BUTTON LOGIK ---
$CancelButton.Add_Click({
    if ($CancelButton.Text -eq "Close Window") {
        $form.Close()
    } else {
        # Bricht den Update-Prozess gewaltsam ab
        $Timer.Stop()
        Stop-Job $Job -ErrorAction SilentlyContinue
        Remove-Job $Job -ErrorAction SilentlyContinue
        
        $listbox.Items.Add("--> UPDATE PROCESS CANCELLED BY USER!")
        $listbox.TopIndex = $listbox.Items.Count - 1
        
        $CancelButton.Text = "Close Window"
        $CancelButton.BackColor = 'LightGreen'
    }
})

# Aufräumen, falls das Fenster über das 'X' geschlossen wird
$form.Add_FormClosing({
    Stop-Job $Job -ErrorAction SilentlyContinue
    Remove-Job $Job -ErrorAction SilentlyContinue
})

# Start GUI
$Timer.Start()
$form.ShowDialog() | Out-Null