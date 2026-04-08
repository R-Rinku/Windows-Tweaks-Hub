# ================= ADMIN CHECK =================
if (-not ([Security.Principal.WindowsPrincipal] `
[Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator")) {

    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName PresentationFramework

# ================= LOG =================
$logPath = "$env:TEMP\CleanerLogV2.txt"

function Log($msg) {
    $time = Get-Date -Format "HH:mm:ss"
    $line = "[$time] $msg"
    Add-Content $logPath $line
    if ($OutputBox) {
        $OutputBox.AppendText("$line`n")
        $OutputBox.ScrollToEnd()
    }
}

function Remove-PathContents {
    param(
        [string]$Path,
        [string]$Filter = "*"
    )

    if (Test-Path $Path) {
        Get-ChildItem -Path $Path -Filter $Filter -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-CleanAction {
    param(
        [string]$Name,
        [scriptblock]$Action
    )

    try {
        Log "$Name..."
        & $Action
        Log "$Name completed"
    } catch {
        Log "$Name failed: $($_.Exception.Message)"
    }
}

# ================= UI =================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Cleaner Pro V2"
        Height="780"
        Width="1080"
        MinHeight="740"
        MinWidth="980"
        Background="#EAF1F8"
        WindowStartupLocation="CenterScreen">

    <Grid Margin="18">
        <Grid.Resources>
            <Style TargetType="CheckBox">
                <Setter Property="Foreground" Value="#0F172A"/>
                <Setter Property="Margin" Value="0,4,0,4"/>
                <Setter Property="FontSize" Value="13"/>
            </Style>
            <Style TargetType="Button">
                <Setter Property="Margin" Value="0,0,8,0"/>
                <Setter Property="Padding" Value="14,8"/>
                <Setter Property="FontWeight" Value="SemiBold"/>
                <Setter Property="BorderThickness" Value="0"/>
                <Setter Property="Cursor" Value="Hand"/>
            </Style>
        </Grid.Resources>

        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="180"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0" CornerRadius="14" Padding="18" Margin="0,0,0,12">
            <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                    <GradientStop Color="#0B3A6E" Offset="0"/>
                    <GradientStop Color="#0F766E" Offset="1"/>
                </LinearGradientBrush>
            </Border.Background>
            <StackPanel>
                <TextBlock Text="Cleaner Pro V2" FontSize="30" FontWeight="Bold" Foreground="White"/>
                <TextBlock Text="Advanced cleanup presets for VDI and Laptop environments" FontSize="14" Foreground="#DDF5FF"/>
            </StackPanel>
        </Border>

        <Border Grid.Row="1" Background="#F8FAFC" BorderBrush="#CBD5E1" BorderThickness="1" CornerRadius="12" Padding="12" Margin="0,0,0,12">
            <DockPanel LastChildFill="False">
                <TextBlock Text="Category Presets" FontWeight="Bold" FontSize="15" Foreground="#0F172A" VerticalAlignment="Center" Margin="0,0,16,0"/>
                <Button Name="VDIPresetBtn" Content="Apply VDI" Background="#0EA5E9" Foreground="White"/>
                <Button Name="LaptopPresetBtn" Content="Apply Laptop" Background="#16A34A" Foreground="White"/>
                <Button Name="SelectAllBtn" Content="Select All" Background="#1E40AF" Foreground="White"/>
                <Button Name="ClearAllBtn" Content="Clear All" Background="#475569" Foreground="White"/>
                <TextBlock Name="PresetStatusText" Text="Preset: Custom" FontWeight="SemiBold" Foreground="#334155" VerticalAlignment="Center" Margin="12,0,0,0"/>
            </DockPanel>
        </Border>

        <TabControl Grid.Row="2" Margin="0,0,0,0" Background="#F8FAFC" BorderBrush="#CBD5E1">
            <TabItem Header="Cleanup">
                <Grid Margin="10">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="2*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <ScrollViewer Grid.Column="0" VerticalScrollBarVisibility="Auto" Margin="0,0,10,0">
                        <StackPanel>
                            <Border Background="#F8FAFC" BorderBrush="#CBD5E1" BorderThickness="1" CornerRadius="12" Padding="14" Margin="0,0,0,10">
                                <StackPanel>
                                    <TextBlock Text="Cleanup Utilities" Foreground="#0C4A6E" FontSize="18" FontWeight="Bold" Margin="0,0,0,8"/>
                                    <UniformGrid Columns="2">
                                        <CheckBox Name="TempCB" Content="User Temp Files"/>
                                        <CheckBox Name="WinTempCB" Content="Windows Temp"/>
                                        <CheckBox Name="RecycleCB" Content="Recycle Bin"/>
                                        <CheckBox Name="UpdateCB" Content="Windows Update Cache"/>
                                        <CheckBox Name="DeliveryCB" Content="Delivery Optimization Cache"/>
                                        <CheckBox Name="PrefetchCB" Content="Prefetch Cache"/>
                                        <CheckBox Name="ErrorCB" Content="Windows Error Reports"/>
                                        <CheckBox Name="ThumbCB" Content="Thumbnail Cache"/>
                                        <CheckBox Name="BrowserCB" Content="Browser Cache (Chrome/Edge/Firefox)"/>
                                        <CheckBox Name="RecentCB" Content="Recent Items List"/>
                                        <CheckBox Name="CrashDumpCB" Content="Crash Dumps"/>
                                        <CheckBox Name="LogFilesCB" Content="CBS and DISM Logs"/>
                                    </UniformGrid>
                                </StackPanel>
                            </Border>

                            <Border Background="#F8FAFC" BorderBrush="#CBD5E1" BorderThickness="1" CornerRadius="12" Padding="14" Margin="0,0,0,10">
                                <StackPanel>
                                    <TextBlock Text="System Tuning" Foreground="#166534" FontSize="18" FontWeight="Bold" Margin="0,0,0,8"/>
                                    <UniformGrid Columns="2">
                                        <CheckBox Name="AnimCB" Content="Disable Animations"/>
                                        <CheckBox Name="TransCB" Content="Disable Transparency"/>
                                        <CheckBox Name="StorageCB" Content="Run Disk Cleanup"/>
                                        <CheckBox Name="DnsCB" Content="Flush DNS Cache"/>
                                        <CheckBox Name="ClipboardCB" Content="Clear Clipboard"/>
                                        <CheckBox Name="SpoolerCB" Content="Clear Print Spooler Queue"/>
                                        <CheckBox Name="ComponentCB" Content="DISM Component Cleanup"/>
                                    </UniformGrid>
                                </StackPanel>
                            </Border>
                        </StackPanel>
                    </ScrollViewer>

                    <Border Grid.Column="1" Background="#F8FAFC" BorderBrush="#CBD5E1" BorderThickness="1" CornerRadius="12" Padding="14">
                        <StackPanel>
                            <TextBlock Text="User Profiles" Foreground="#854D0E" FontSize="18" FontWeight="Bold" Margin="0,0,0,8"/>
                            <TextBlock Text="Select profiles to remove" Foreground="#475569" Margin="0,0,0,8"/>
                            <ListBox Name="UserList" Height="300" SelectionMode="Extended"/>
                            <StackPanel Orientation="Horizontal" HorizontalAlignment="Left" Margin="0,10,0,0">
                                <Button Name="DeleteUserBtn" Content="Delete" Background="#DC2626" Foreground="White" Width="80" Margin="0,0,10,0"/>
                                <Button Name="RenameUserBtn" Content="Rename" Background="#F59E42" Foreground="White" Width="80" IsEnabled="False"/>
                            </StackPanel>
                        # Enable/disable Rename button based on selection
                        $UserList.Add_SelectionChanged({
                            if ($UserList.SelectedItems.Count -eq 1) {
                                $RenameUserBtn.IsEnabled = $true
                            } else {
                                $RenameUserBtn.IsEnabled = $false
                            }
                        })
                        </StackPanel>
                    </Border>
                </Grid>
            </TabItem>

            <TabItem Header="Profile Registry Path">
                <Grid Margin="14">
                    <StackPanel>
                        <TextBlock Text="User Profiles Registry Path" FontSize="20" FontWeight="Bold" Foreground="#0F172A" Margin="0,0,0,10"/>
                        <TextBlock Text="Use this path in Regedit to locate Windows profile metadata." Foreground="#334155" Margin="0,0,0,10"/>
                        <TextBox Name="RegPathBox"
                                 Text="HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
                                 IsReadOnly="True"
                                 FontFamily="Consolas"
                                 FontSize="13"
                                 Background="White"
                                 Foreground="#0F172A"
                                 BorderBrush="#94A3B8"
                                 BorderThickness="1"
                                 Padding="10"/>
                    </StackPanel>
                </Grid>
            </TabItem>
        </TabControl>

        <TextBox Name="OutputBox"
                 Grid.Row="3"
                 Margin="0,12,0,12"
                 Background="White"
                 Foreground="#0F172A"
                 BorderBrush="#94A3B8"
                 BorderThickness="1"
                 FontFamily="Consolas"
                 FontSize="12"
                 AcceptsReturn="True"
                 IsReadOnly="True"
                 VerticalScrollBarVisibility="Auto"
                 TextWrapping="Wrap"/>

        <DockPanel Grid.Row="4" LastChildFill="False">
            <TextBlock Text="Tip: Presets auto-select common options, then you can fine-tune manually." Foreground="#334155" VerticalAlignment="Center"/>
            <Button Name="RunBtn"
                    Content="RUN CLEANUP V2"
                    Height="46"
                    Width="250"
                    Background="#2563EB"
                    Foreground="White"
                    HorizontalAlignment="Right"/>
        </DockPanel>
    </Grid>
</Window>
"@

# Load UI
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Controls
$OutputBox = $window.FindName("OutputBox")
$RunBtn = $window.FindName("RunBtn")
$UserList = $window.FindName("UserList")


$VDIPresetBtn = $window.FindName("VDIPresetBtn")
$LaptopPresetBtn = $window.FindName("LaptopPresetBtn")
$SelectAllBtn = $window.FindName("SelectAllBtn")
$ClearAllBtn = $window.FindName("ClearAllBtn")
$PresetStatusText = $window.FindName("PresetStatusText")
$RegPathBox = $window.FindName("RegPathBox")

$TempCB = $window.FindName("TempCB")
$WinTempCB = $window.FindName("WinTempCB")
$RecycleCB = $window.FindName("RecycleCB")
$UpdateCB = $window.FindName("UpdateCB")
$DeliveryCB = $window.FindName("DeliveryCB")
$PrefetchCB = $window.FindName("PrefetchCB")
$ErrorCB = $window.FindName("ErrorCB")
$ThumbCB = $window.FindName("ThumbCB")
$BrowserCB = $window.FindName("BrowserCB")
$RecentCB = $window.FindName("RecentCB")
$CrashDumpCB = $window.FindName("CrashDumpCB")
$LogFilesCB = $window.FindName("LogFilesCB")

$AnimCB = $window.FindName("AnimCB")
$TransCB = $window.FindName("TransCB")
$StorageCB = $window.FindName("StorageCB")
$DnsCB = $window.FindName("DnsCB")
$ClipboardCB = $window.FindName("ClipboardCB")
$SpoolerCB = $window.FindName("SpoolerCB")
$ComponentCB = $window.FindName("ComponentCB")

# User profile management buttons
$DeleteUserBtn = $window.FindName("DeleteUserBtn")
$RenameUserBtn = $window.FindName("RenameUserBtn")
# ================= USER PROFILE DELETE/RENAME BUTTONS =================
$DeleteUserBtn.Add_Click({
    if ($UserList.SelectedItems.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Please select at least one user to delete.", "No User Selected", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        return
    }
    $selectedUsers = @($UserList.SelectedItems)
    $userPreview = ($selectedUsers -join ", ")
    $promptText = "Delete selected profile folders?`n`n$userPreview`n`nThis action cannot be undone."
    $confirmResult = [System.Windows.MessageBox]::Show(
        $promptText,
        "Confirm Profile Deletion",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )
    if ($confirmResult -eq [System.Windows.MessageBoxResult]::Yes) {
        foreach ($user in $selectedUsers) {
            try {
                Log "Removing profile $user via Delete button"
                Remove-Item "C:\Users\$user" -Recurse -Force -ErrorAction Stop
                $UserList.Items.Remove($user)
                Log "Profile $user deleted"
            } catch {
                Log "Failed to delete profile $user: $($_.Exception.Message)"
            }
        }
    } else {
        Log "Profile deletion cancelled by user (Delete button)"
    }
})

$RenameUserBtn.Add_Click({
    $oldName = $UserList.SelectedItem
    # Popup for new name
    $inputBox = New-Object System.Windows.Window
    $inputBox.Title = "Rename User Profile"
    $inputBox.Width = 350
    $inputBox.Height = 160
    $inputBox.WindowStartupLocation = 'CenterScreen'
    $inputBox.ResizeMode = 'NoResize'
    $panel = New-Object System.Windows.Controls.StackPanel
    $panel.Margin = '16'
    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = "Enter new name for user profile:"
    $label.Margin = '0,0,0,8'
    $oldLabel = New-Object System.Windows.Controls.TextBlock
    $oldLabel.Text = "Old name: $oldName"
    $oldLabel.Margin = '0,0,0,8'
    $textBox = New-Object System.Windows.Controls.TextBox
    $textBox.Text = $oldName
    $textBox.Margin = '0,0,0,8'
    $okBtn = New-Object System.Windows.Controls.Button
    $okBtn.Content = "OK"
    $okBtn.Width = 60
    $okBtn.Margin = '0,0,8,0'
    $cancelBtn = New-Object System.Windows.Controls.Button
    $cancelBtn.Content = "Cancel"
    $cancelBtn.Width = 60
    $btnPanel = New-Object System.Windows.Controls.StackPanel
    $btnPanel.Orientation = 'Horizontal'
    $btnPanel.Children.Add($okBtn) | Out-Null
    $btnPanel.Children.Add($cancelBtn) | Out-Null
    $panel.Children.Add($label) | Out-Null
    $panel.Children.Add($oldLabel) | Out-Null
    $panel.Children.Add($textBox) | Out-Null
    $panel.Children.Add($btnPanel) | Out-Null
    $inputBox.Content = $panel
    $inputBox.Topmost = $true
    $okClicked = $false
    $okBtn.Add_Click({
        $okClicked = $true
        $inputBox.Close()
    })
    $cancelBtn.Add_Click({
        $inputBox.Close()
    })
    $inputBox.ShowDialog() | Out-Null
    if (-not $okClicked) { return }
    $newName = $textBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($newName) -or $newName -eq $oldName) {
        [System.Windows.MessageBox]::Show("Invalid or unchanged name.", "Rename Failed", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }
    $oldPath = "C:\Users\$oldName"
    $newPath = "C:\Users\$newName"
    if (Test-Path $newPath) {
        [System.Windows.MessageBox]::Show("A profile with the new name already exists.", "Rename Failed", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
        return
    }
    try {
        Log "Renaming profile $oldName to $newName"
        Rename-Item -Path $oldPath -NewName $newName -ErrorAction Stop
        $UserList.Items.Remove($oldName)
        $UserList.Items.Add($newName)
        Log "Profile $oldName renamed to $newName"
    } catch {
        Log "Failed to rename profile $oldName: $($_.Exception.Message)"
        [System.Windows.MessageBox]::Show("Failed to rename profile: $($_.Exception.Message)", "Rename Failed", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})

$allOptionControls = @(
    $TempCB, $WinTempCB, $RecycleCB, $UpdateCB, $DeliveryCB, $PrefetchCB,
    $ErrorCB, $ThumbCB, $BrowserCB, $RecentCB, $CrashDumpCB, $LogFilesCB,
    $AnimCB, $TransCB, $StorageCB, $DnsCB, $ClipboardCB, $SpoolerCB, $ComponentCB
)

function Set-PresetState {
    param(
        [hashtable]$State,
        [string]$PresetName
    )

    foreach ($control in $allOptionControls) {
        $control.IsChecked = $false
    }

    foreach ($key in $State.Keys) {
        if (Get-Variable -Name $key -Scope Script -ErrorAction SilentlyContinue) {
            (Get-Variable -Name $key -Scope Script).Value.IsChecked = [bool]$State[$key]
        }
    }

    $PresetStatusText.Text = "Preset: $PresetName"
}

# Load users safely
$currentUser = $env:USERNAME
Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -notin @("Public", "Default", "Default User", "All Users", $currentUser)
} | ForEach-Object {
    $UserList.Items.Add($_.Name)
}

# Presets
$VDIPresetBtn.Add_Click({
    $vdiState = @{
        TempCB       = $true
        WinTempCB    = $true
        RecycleCB    = $true
        UpdateCB     = $true
        DeliveryCB   = $true
        PrefetchCB   = $true
        ErrorCB      = $true
        ThumbCB      = $true
        BrowserCB    = $true
        RecentCB     = $true
        CrashDumpCB  = $true
        LogFilesCB   = $true
        AnimCB       = $true
        TransCB      = $true
        StorageCB    = $true
        DnsCB        = $true
        ClipboardCB  = $true
        SpoolerCB    = $false
        ComponentCB  = $true
    }
    Set-PresetState -State $vdiState -PresetName "VDI"
    Log "VDI preset selected"
})

$LaptopPresetBtn.Add_Click({
    $laptopState = @{
        TempCB       = $true
        WinTempCB    = $true
        RecycleCB    = $true
        UpdateCB     = $false
        DeliveryCB   = $true
        PrefetchCB   = $false
        ErrorCB      = $true
        ThumbCB      = $true
        BrowserCB    = $true
        RecentCB     = $true
        CrashDumpCB  = $true
        LogFilesCB   = $false
        AnimCB       = $true
        TransCB      = $true
        StorageCB    = $true
        DnsCB        = $true
        ClipboardCB  = $true
        SpoolerCB    = $false
        ComponentCB  = $false
    }
    Set-PresetState -State $laptopState -PresetName "Laptop"
    Log "Laptop preset selected"
})

$SelectAllBtn.Add_Click({
    foreach ($control in $allOptionControls) {
        $control.IsChecked = $true
    }
    $PresetStatusText.Text = "Preset: All Selected"
    Log "All options selected"
})

$ClearAllBtn.Add_Click({
    foreach ($control in $allOptionControls) {
        $control.IsChecked = $false
    }
    $PresetStatusText.Text = "Preset: Custom"
    Log "All options cleared"
})

# ================= RUN =================
$RunBtn.Add_Click({
    Log "=== CLEANUP START (V2) ==="

    if ($TempCB.IsChecked) {
        Invoke-CleanAction "Cleaning user temp" {
            Remove-PathContents -Path $env:TEMP
        }
    }

    if ($WinTempCB.IsChecked) {
        Invoke-CleanAction "Cleaning Windows temp" {
            Remove-PathContents -Path "C:\Windows\Temp"
        }
    }

    if ($RecycleCB.IsChecked) {
        Invoke-CleanAction "Cleaning recycle bin" {
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        }
    }

    if ($UpdateCB.IsChecked) {
        Invoke-CleanAction "Cleaning Windows Update cache" {
            Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
            Remove-PathContents -Path "C:\Windows\SoftwareDistribution\Download"
            Start-Service wuauserv -ErrorAction SilentlyContinue
        }
    }

    if ($DeliveryCB.IsChecked) {
        Invoke-CleanAction "Cleaning delivery optimization cache" {
            Remove-PathContents -Path "C:\Windows\SoftwareDistribution\DeliveryOptimization"
        }
    }

    if ($PrefetchCB.IsChecked) {
        Invoke-CleanAction "Cleaning prefetch cache" {
            Remove-PathContents -Path "C:\Windows\Prefetch"
        }
    }

    if ($ErrorCB.IsChecked) {
        Invoke-CleanAction "Cleaning Windows error reports" {
            Remove-PathContents -Path "C:\ProgramData\Microsoft\Windows\WER"
        }
    }

    if ($ThumbCB.IsChecked) {
        Invoke-CleanAction "Cleaning thumbnail cache" {
            Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" -Filter "thumbcache_*" -ErrorAction SilentlyContinue |
                Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }

    if ($BrowserCB.IsChecked) {
        Invoke-CleanAction "Cleaning browser caches" {
            Remove-PathContents -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
            Remove-PathContents -Path "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
            Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                Remove-PathContents -Path (Join-Path $_.FullName "cache2\entries")
            }
        }
    }

    if ($RecentCB.IsChecked) {
        Invoke-CleanAction "Cleaning recent items" {
            Remove-PathContents -Path "$env:APPDATA\Microsoft\Windows\Recent"
        }
    }

    if ($CrashDumpCB.IsChecked) {
        Invoke-CleanAction "Cleaning crash dumps" {
            Remove-PathContents -Path "C:\Windows\Minidump"
            Remove-Item "C:\Windows\MEMORY.DMP" -Force -ErrorAction SilentlyContinue
        }
    }

    if ($LogFilesCB.IsChecked) {
        Invoke-CleanAction "Cleaning CBS and DISM logs" {
            Get-ChildItem "C:\Windows\Logs\CBS" -Filter "*.log" -ErrorAction SilentlyContinue |
                Remove-Item -Force -ErrorAction SilentlyContinue
            Get-ChildItem "C:\Windows\Logs\DISM" -Filter "*.log" -ErrorAction SilentlyContinue |
                Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }

    if ($AnimCB.IsChecked) {
        Invoke-CleanAction "Disabling animations" {
            Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name VisualFXSetting -Value 2
        }
    }

    if ($TransCB.IsChecked) {
        Invoke-CleanAction "Disabling transparency" {
            Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name EnableTransparency -Value 0
        }
    }

    if ($StorageCB.IsChecked) {
        Invoke-CleanAction "Running disk cleanup" {
            Start-Process cleanmgr.exe -ArgumentList "/VERYLOWDISK" -Wait
        }
    }

    if ($DnsCB.IsChecked) {
        Invoke-CleanAction "Flushing DNS cache" {
            Clear-DnsClientCache -ErrorAction SilentlyContinue
        }
    }

    if ($ClipboardCB.IsChecked) {
        Invoke-CleanAction "Clearing clipboard" {
            Set-Clipboard -Value ""
        }
    }

    if ($SpoolerCB.IsChecked) {
        Invoke-CleanAction "Clearing print spooler queue" {
            Stop-Service spooler -Force -ErrorAction SilentlyContinue
            Remove-PathContents -Path "C:\Windows\System32\spool\PRINTERS"
            Start-Service spooler -ErrorAction SilentlyContinue
        }
    }

    if ($ComponentCB.IsChecked) {
        Invoke-CleanAction "Running DISM component cleanup" {
            Start-Process dism.exe -ArgumentList "/Online /Cleanup-Image /StartComponentCleanup" -Wait
        }
    }

    if ($UserList.SelectedItems.Count -gt 0) {
        $selectedUsers = @($UserList.SelectedItems)
        $userPreview = ($selectedUsers -join ", ")
        $promptText = "Delete selected profile folders?`n`n$userPreview`n`nThis action cannot be undone."
        $confirmResult = [System.Windows.MessageBox]::Show(
            $promptText,
            "Confirm Profile Deletion",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )

        if ($confirmResult -eq [System.Windows.MessageBoxResult]::Yes) {
            foreach ($user in $selectedUsers) {
                Invoke-CleanAction "Removing profile $user" {
                    Remove-Item "C:\Users\$user" -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        } else {
            Log "Profile deletion skipped by user"
        }
    }

    Log "=== CLEANUP DONE (V2) ==="
})

$window.ShowDialog() | Out-Null