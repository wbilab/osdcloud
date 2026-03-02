Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$LogDir = "C:\OSDCloud"
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
$LogFile = Join-Path $LogDir "WindowsUpdateLog_$(Get-Date -Format yyyyMMdd_HHmmss).txt"
New-Item -ItemType File -Path $LogFile -Force | Out-Null

function Add-LogLine($text) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    $line = "[$timestamp] $text"
    $listbox.Items.Add($line)
    $line | Out-File -FilePath $LogFile -Append -Encoding UTF8
    $listbox.TopIndex = $listbox.Items.Count - 1
    $form.Refresh()
}

$Global:CancelUpdates = $false

$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows & Driver Update Installer"
$form.Width = 800
$form.Height = 600

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
$CancelButton.Add_Click({
    $Global:CancelUpdates = $true
    Add-LogLine "--> CANCEL REQUESTED! Stopping after current update finishes..."
    $CancelButton.Enabled = $false
    $CancelButton.Text = "Canceling..."
})
$form.Controls.Add($CancelButton)

$form.TopMost = $true
$form.Show()

Start-Sleep -Seconds 2
Add-LogLine "Initializing update engine..."

Try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
    Install-Module -Name PSWindowsUpdate -Force -AllowClobber -ErrorAction Stop
    Add-LogLine "PSWindowsUpdate module installed."
} Catch {
    Add-LogLine "Failed to install PSWindowsUpdate: $_"
    return
}

Try {
    Import-Module PSWindowsUpdate
    Add-WUServiceManager -MicrosoftUpdate -Confirm:$false | Out-Null
    Add-LogLine "Microsoft Update enabled (includes drivers)."
} Catch {
    Add-LogLine "Failed to enable Microsoft Update: $_"
    return
}

Try {
    Add-LogLine "Scanning for updates... (Window may freeze for several minutes!)"
    $form.Refresh()
    [System.Windows.Forms.Application]::DoEvents() 
    
    $updates = Get-WindowsUpdate -MicrosoftUpdate -ErrorAction Stop
    $count = $updates.Count

    if ($count -eq 0) {
        Add-LogLine "No updates available."
    } else {
        Add-LogLine "Found $count update(s). Starting installation..."
        
        foreach ($update in $updates) {
            [System.Windows.Forms.Application]::DoEvents() 
            
            if ($Global:CancelUpdates) {
                Add-LogLine "Update process aborted by user."
                break
            }

            Add-LogLine "Installing: $($update.Title)"
            if ($update.KBArticleID) {
                Install-WindowsUpdate -KBArticleID $update.KBArticleID -AcceptAll -IgnoreReboot -Confirm:$false | Out-Null
            } else {
                Install-WindowsUpdate -Title $update.Title -AcceptAll -IgnoreReboot -Confirm:$false | Out-Null
            }
            Add-LogLine "Done: $($update.Title)"
        }

        Add-LogLine "Update process finished."
    }

} Catch {
    Add-LogLine "Unexpected error during update process: $_"
}

Add-LogLine "Window will close in 15 seconds..."

for ($i = 15; $i -ge 1; $i--) {
    $form.Text = "Closing in $i seconds..."
    [System.Windows.Forms.Application]::DoEvents() 
    Start-Sleep -Seconds 1
}

$form.Close()