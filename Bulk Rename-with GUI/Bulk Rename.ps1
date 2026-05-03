# ---------------- EXECUTION POLICY SAFETY ----------------
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# ---------------- AUTO ELEVATION ----------------
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Start-Process powershell `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Verb RunAs
    exit
}

# ---------------- LOAD ASSEMBLIES ----------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------------- PERMISSION FIX FUNCTION ----------------
function Grant-FullAccess {
    param ($Path)

    try {
        takeown /f "$Path" /a /d y | Out-Null
        icacls "$Path" /grant Administrators:F /c | Out-Null
    } catch {}
}

# ---------------- FORM ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Advanced File Renamer"
$form.Size = New-Object System.Drawing.Size(560,520)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Folder selection
$txtFolder = New-Object System.Windows.Forms.TextBox
$txtFolder.SetBounds(20,30,380,22)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse"
$btnBrowse.SetBounds(410,28,100,26)
$btnBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -eq "OK") {
        $txtFolder.Text = $dlg.SelectedPath
    }
})

# Operation
$grpOp = New-Object System.Windows.Forms.GroupBox
$grpOp.Text = "Operation"
$grpOp.SetBounds(20,70,500,80)

$rbRemove  = New-Object System.Windows.Forms.RadioButton
$rbAdd     = New-Object System.Windows.Forms.RadioButton
$rbReplace = New-Object System.Windows.Forms.RadioButton

$rbRemove.Text  = "Remove"
$rbAdd.Text     = "Add"
$rbReplace.Text = "Replace"

$rbRemove.Checked = $true

$rbRemove.SetBounds(20,35,90,20)
$rbAdd.SetBounds(200,35,90,20)
$rbReplace.SetBounds(350,35,90,20)

$grpOp.Controls.AddRange(@($rbRemove,$rbAdd,$rbReplace))

# Text boxes
$txtOld = New-Object System.Windows.Forms.TextBox
$txtNew = New-Object System.Windows.Forms.TextBox

$txtOld.SetBounds(20,180,350,22)
$txtNew.SetBounds(20,230,350,22)

$txtOld.Text = "_spotdown.org"

# Scope
$grpScope = New-Object System.Windows.Forms.GroupBox
$grpScope.Text = "Apply To"
$grpScope.SetBounds(20,270,500,70)

$rbName = New-Object System.Windows.Forms.RadioButton
$rbExt  = New-Object System.Windows.Forms.RadioButton
$rbBoth = New-Object System.Windows.Forms.RadioButton

$rbName.Text = "File Name"
$rbExt.Text  = "Extension"
$rbBoth.Text = "Both"

$rbName.Checked = $true

$rbName.SetBounds(20,30,120,20)
$rbExt.SetBounds(200,30,120,20)
$rbBoth.SetBounds(360,30,100,20)

$grpScope.Controls.AddRange(@($rbName,$rbExt,$rbBoth))

# Run
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Execute"
$btnRun.SetBounds(210,370,120,35)

$btnRun.Add_Click({
    if (-not (Test-Path $txtFolder.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Invalid folder selected")
        return
    }

    $escapeOld = [regex]::Escape($txtOld.Text)
    $files = Get-ChildItem $txtFolder.Text -File

    foreach ($file in $files) {
        $base = $file.BaseName
        $ext  = $file.Extension

        try {
            if ($rbRemove.Checked) {
                if ($rbName.Checked -or $rbBoth.Checked) { $base = $base -replace $escapeOld, "" }
                if ($rbExt.Checked  -or $rbBoth.Checked) { $ext  = $ext  -replace $escapeOld, "" }
            }

            if ($rbAdd.Checked -and $txtNew.Text) {
                if ($rbName.Checked) { $base = $base + $txtNew.Text }
            }

            if ($rbReplace.Checked) {
                if ($rbName.Checked -or $rbBoth.Checked) {
                    $base = $base -replace $escapeOld, $txtNew.Text
                }
            }

            $newName = $base + $ext
            if ($file.Name -ne $newName) {
                Rename-Item $file.FullName $newName -ErrorAction Stop
            }

        } catch {
            Grant-FullAccess $file.FullName
            Rename-Item $file.FullName ($base + $ext) -ErrorAction SilentlyContinue
        }
    }

    [System.Windows.Forms.MessageBox]::Show("Completed successfully")
})

# Add to form
$form.Controls.AddRange(@(
    $txtFolder,$btnBrowse,
    $grpOp,$txtOld,$txtNew,
    $grpScope,$btnRun
))

$form.ShowDialog()