[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Type DWord -Value '1'
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Type DWord -Value '1'

Add-Type -AssemblyName System.Windows.Forms
$systemDrive = $env:SystemDrive
$workingDirectory = Join-Path $systemDrive "OSDCloud\Scripts"

$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Check-AutopilotPrerequisites.log"
Start-Transcript -Path (Join-Path "$workingDirectory\" $Global:Transcript) -ErrorAction Ignore

Write-Host "Execute Autopilot Prerequitites Check" -ForegroundColor Green

Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
Install-Script -Name Check-AutopilotPrerequisites -Force
Check-AutopilotPrerequisites

Stop-Transcript


# Pfad zur Logdatei
$logDateiPfad = (Join-Path "$workingDirectory\" $Global:Transcript)
# Lese die Logdatei
$logInhalt = Get-Content -Path $logDateiPfad

# Durchsuche den Inhalt der Log Datei von Autopilot Pre Check und extrahiere den Wert
$KeyboardlayoutZeile = $logInhalt | Where-Object { $_ -match "Keyboardlayout" }
$tpmpresentZeile = $logInhalt | Where-Object { $_ -match "Tpm present" }
$tpmreadyZeile = $logInhalt | Where-Object { $_ -match "Tpm ready" }
$tpmenabledZeile = $logInhalt | Where-Object { $_ -match "Tpm enabled" }
$biosserialnummerZeile = $logInhalt | Where-Object { $_ -match "Bios Serialnumber" }
$approfileZeile = $logInhalt | Where-Object { $_ -match "Cached AP Profile" }

# Teile die Zeile anhand des Doppelpunkts (:) auf, um den Werte aus dem Autopilot PreCheck zu extrahieren und definiere Variabeln
$KeyboardlayoutTeile = $KeyboardlayoutZeile -split ":"
$Keyboardlayout = $KeyboardlayoutTeile[1].Trim()

$tpmpresentTeile = $tpmpresentZeile -split ":"
$tpmpresent = $tpmpresentTeile[1].Trim()

$tpmreadyTeile = $tpmreadyZeile -split ":"
$tpmready = $tpmreadyTeile[1].Trim()

$tpmenabledTeile = $tpmenabledZeile -split ":"
$tpmenabled= $tpmenabledTeile[1].Trim()

$biosserialnummerTeile = $biosserialnummerZeile -split ":"
$biosserialnummer = $biosserialnummerTeile[1].Trim()

$approfileTeile = $approfileZeile -split ":"
$approfile = $approfileTeile[1].Trim()


$rawImageUrl = "https://raw.githubusercontent.com/wbilab/osdcloud/main/Vi_Logo.png"
Invoke-WebRequest $rawImageUrl -OutFile $workingDirectory"\Vi_Logo.png"
$logo = Join-Path $workingDirectory "Vi_Logo.png"

Save-Script -Name Get-WindowsAutoPilotInfo -Path $workingDirectory -Force

# Erstelle das Hauptfenster
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "VISI AutoPilot Registrierung"
$Form.Size = New-Object System.Drawing.Size(500, 450)
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $false
$Form.StartPosition = "CenterScreen"


# Erstelle den Titel mit groesserer Schriftart
$LabelTitle = New-Object System.Windows.Forms.Label
$LabelTitle.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Bitte wählen Sie die gewünschte Funktion:"))
$LabelTitle.Location = New-Object System.Drawing.Point(10, 70)
$LabelTitle.AutoSize = $true
$LabelTitle.Font = New-Object System.Drawing.Font("Arial", 11)

# Erstelle den Platz für das Logo
$LogoPictureBox = New-Object System.Windows.Forms.PictureBox
$LogoPictureBox.Image = [System.Drawing.Image]::FromFile($logo)
$LogoPictureBox.SizeMode = "AutoSize"
$LogoPictureBox.Location = New-Object System.Drawing.Point(10, 20)

# Erstelle den ersten Button (quadratisch und groesser)
$Button1 = New-Object System.Windows.Forms.Button
$Button1.Text = "AutoPilot`nRegistrierung`n`nTag: InCloud"
$Button1.Size = New-Object System.Drawing.Size(100, 100)
$Button1.Location = New-Object System.Drawing.Point(10, 120)
$Button1.Add_Click({

$Form.WindowState = "Minimized" # Minimiere das GUI-Fenster
cd $workingDirectory
.\Get-WindowsAutoPilotInfo.ps1 -GroupTag InCloud -Online -Assign
$Form.Close() # Schliesse das Programm
})

# Erstelle den zweiten Button (quadratisch und groesser)
$Button2 = New-Object System.Windows.Forms.Button
$Button2.Text = "AutoPilot`nRegistrierung`n`nTag: Hybrid"
$Button2.Size = New-Object System.Drawing.Size(100, 100)
$Button2.Location = New-Object System.Drawing.Point(120, 120)
$Button2.Add_Click({

$Form.WindowState = "Minimized" # Minimiere das GUI-Fenster
cd $workingDirectory
.\Get-WindowsAutoPilotInfo.ps1 -GroupTag Hybrid -Online -Assign
$Form.Close() # Schliesse das Programm
})


# Erstelle die Bezeichnung für das Eingabefeld "Anderes"
$LabelAnderes = New-Object System.Windows.Forms.Label
$LabelAnderes.Text = "AutoPilot`nRegistrierung"
$LabelAnderes.Size = New-Object System.Drawing.Size(100, 30)
$LabelAnderes.Location = New-Object System.Drawing.Point(230, 125)

# Erstelle die Bezeichnung für das Eingabefeld "Tag"
$LabelTag = New-Object System.Windows.Forms.Label
$LabelTag.Size = New-Object System.Drawing.Size(30, 20)
$LabelTag.Text = "Tag:"
$LabelTag.Location = New-Object System.Drawing.Point(230, 170)

# Erstelle ein Eingabefeld
$InputBox = New-Object System.Windows.Forms.TextBox
$InputBox.Location = New-Object System.Drawing.Point(260, 165)
$InputBox.Size = New-Object System.Drawing.Size(70, 50)

# Erstelle die "OK"-Taste
$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Text = "OK"
$OKButton.Size = New-Object System.Drawing.Size(100, 30)
$OKButton.Location = New-Object System.Drawing.Point(230, 190)
$OKButton.Add_Click({
$inputValue = $InputBox.Text
$Form.WindowState = "Minimized" # Minimiere das GUI-Fenster
cd $workingDirectory
.\Get-WindowsAutoPilotInfo.ps1 -GroupTag $inputValue -Online -Assign
$Form.Close() # Schliesse das Programm
})

# Erstelle den driten Button (quadratisch und groesser)
$Button3 = New-Object System.Windows.Forms.Button
$Button3.Text = "AutoPilot Registrierung`nschliessen"
$Button3.Size = New-Object System.Drawing.Size(100, 100)
$Button3.Location = New-Object System.Drawing.Point(350, 120)
$Button3.Add_Click({
$Form.Close() # Schliesse das Programm
 })

$precheckText = "Autopilot PreCheck Results:`n`nKeyboardlayout: $Keyboardlayout`nTpm present: $tpmpresent`nTpm ready: $tpmready`nTpm enabled: $tpmenabled`nSerienumber: $biosserialnummer`nAutoPilot Registration: $approfile"

# Erstellen Sie ein Label mit Rahmen und dem Text mit 5 Zeilen
$precheck = New-Object Windows.Forms.Label
$precheck.Text = $precheckText
$precheck.Width = 380
$precheck.Height = 120
$precheck.Location = New-Object Drawing.Point(10, 250)
$precheck.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

# Erstellen Sie ein Label für den Countdown-Text
$LabelClose = New-Object System.Windows.Forms.Label
$LabelClose.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Das Gerät ist bereits im AutoPilot registriert.`nDas Fenster wird in 15 Sekunden automatisch geschlossen!"))
$LabelClose.AutoSize = $true
$LabelClose.ForeColor = [System.Drawing.Color]::Green
$LabelClose.Location = New-Object System.Drawing.Point(10, 380)


# Funktion zum Aktivieren/Deaktivieren der Schaltflächen
if ($approfile -eq "Assigned") {
    $Button1.Enabled = $false
    $Button2.Enabled = $false
    $OKButton.Enabled = $false
    $InputBox.Enabled = $false
    $Button3.Enabled = $true

    # Starten Sie den Countdown
    $CountdownDuration = 15  # Countdown-Dauer in Sekunden
    $CountdownTimer = [System.Diagnostics.Stopwatch]::StartNew()

    # Funktion zum Aktualisieren des Countdown-Textes
    function UpdateCountdownText() {
    $RemainingTime = $CountdownDuration - [math]::Round($CountdownTimer.Elapsed.TotalSeconds)
    if ($RemainingTime -gt 0) {
        
    } else {
        $Form.Close()
    }
    }

    # Timer erstellen, um den Countdown-Text zu aktualisieren
    $CountdownUpdateTimer = New-Object System.Windows.Forms.Timer
    $CountdownUpdateTimer.Interval = 1000  # 1 Sekunde
    $CountdownUpdateTimer.Add_Tick({ UpdateCountdownText })
    $CountdownUpdateTimer.Start()
    
    $Form.Controls.Add($LabelClose)

} else {
    $Button1.Enabled = $true
    $Button2.Enabled = $true
    $OKButton.Enabled = $true
    $InputBox.Enabled = $true
    $Button3.Enabled = $true
}

# Füge die Steuerelemente dem Hauptfenster hinzu
$Form.Controls.Add($LabelTitle)
$Form.Controls.Add($LogoPictureBox)
$Form.Controls.Add($LabelAnderes)
$Form.Controls.Add($LabelTag)
$Form.Controls.Add($InputBox)
$Form.Controls.Add($precheck)
$form.Controls.AddRange(@($Button1, $Button2, $Button3,$OKButton))

# Zeige das GUI-Fenster an
$Form.ShowDialog()

