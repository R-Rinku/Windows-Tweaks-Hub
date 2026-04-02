$scriptPath = $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($scriptPath)) {
    Write-Error "Unable to resolve script path. Run this as a .ps1 file, not pasted commands."
    exit 1
}

if (-not ([Security.Principal.WindowsPrincipal]`
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {

    $elevatedPowerShell = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
    $elevatedArgs = @(
        "-NoProfile",
        "-STA",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$scriptPath`""
    )

    try {
        Start-Process -FilePath $elevatedPowerShell -ArgumentList $elevatedArgs -Verb RunAs -ErrorAction Stop
    } catch {
        Write-Error "Failed to relaunch as Administrator: $($_.Exception.Message)"
    }

    exit
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

$screenSize = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$windowHeight = [int]($screenSize.Height * 0.7)
$windowWidth = [int]($screenSize.Width * 0.8)
$minHeight = [int]($screenSize.Height * 0.6)
$minWidth = [int]($screenSize.Width * 0.7)

function Get-DirectorySizeBytes {
    param([string]$Path)

    if (-not (Test-Path $Path)) { return 0 }

    try {
        return (Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue -File |
            Measure-Object -Property Length -Sum).Sum
    } catch {
        return 0
    }
}

function Get-FileSizeBytes {
    param([string]$Path)

    if (-not (Test-Path $Path)) { return 0 }

    try {
        return (Get-Item -Path $Path -ErrorAction SilentlyContinue).Length
    } catch {
        return 0
    }
}

function Load-UserProfiles {
    param([System.Windows.Controls.ListBox]$TargetList)

    $selected = @($TargetList.SelectedItems)
    $currentUser = $env:USERNAME
    $exclude = @("Public", "Default", "Default User", "All Users", $currentUser)

    $TargetList.Items.Clear()
    Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin $exclude } |
        Sort-Object Name |
        ForEach-Object { [void]$TargetList.Items.Add($_.Name) }

    foreach ($item in $selected) {
        if ($TargetList.Items.Contains($item)) {
            [void]$TargetList.SelectedItems.Add($item)
        }
    }
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Cleaner Pro"
        Height="$windowHeight"
        Width="$windowWidth"
        MinHeight="$minHeight"
        MinWidth="$minWidth"
        Background="#EAF1F8"
        WindowStartupLocation="CenterScreen">

    <Grid Margin="16">
        <Grid.Resources>
            <Style TargetType="CheckBox">
                <Setter Property="Foreground" Value="#0F172A"/>
                <Setter Property="Margin" Value="0,4,0,4"/>
                <Setter Property="FontSize" Value="13"/>
            </Style>
            <Style TargetType="Button">
                <Setter Property="Margin" Value="0,0,8,0"/>
                <Setter Property="Padding" Value="12,8"/>
                <Setter Property="FontWeight" Value="SemiBold"/>
                <Setter Property="BorderThickness" Value="0"/>
                <Setter Property="Cursor" Value="Hand"/>
            </Style>
        </Grid.Resources>

        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0" Background="#F8FAFC" BorderBrush="#CBD5E1" BorderThickness="1" CornerRadius="12" Padding="12" Margin="0,0,0,10">
            <DockPanel LastChildFill="False">
                <TextBlock Text="Presets" FontWeight="Bold" FontSize="15" Foreground="#0F172A" VerticalAlignment="Center" Margin="0,0,16,0"/>
                <Button Name="VDIPresetBtn" Content="VDI Tweaks" Background="#0EA5E9" Foreground="White"/>
                <Button Name="LaptopPresetBtn" Content="Laptop Tweaks" Background="#16A34A" Foreground="White"/>
                <Button Name="SelectAllBtn" Content="Select All" Background="#1E40AF" Foreground="White"/>
                <Button Name="ClearAllBtn" Content="Clear All" Background="#475569" Foreground="White"/>
                <TextBlock Name="PresetStatusText" Text="Preset: Custom" FontWeight="SemiBold" Foreground="#334155" VerticalAlignment="Center" Margin="8,0,0,0"/>
            </DockPanel>
        </Border>

        <TabControl Grid.Row="1" Background="#F8FAFC" BorderBrush="#CBD5E1">
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
                                        <CheckBox Name="PrefetchCB" Content="Prefetch Cache (Advanced)"/>
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
                                        <CheckBox Name="StorageCB" Content="Run Disk Cleanup (At End)"/>
                                        <CheckBox Name="DnsCB" Content="Flush DNS Cache"/>
                                        <CheckBox Name="ClipboardCB" Content="Clear Clipboard"/>
                                        <CheckBox Name="SpoolerCB" Content="Clear Print Spooler Queue (Advanced)"/>
                                        <CheckBox Name="ComponentCB" Content="DISM Component Cleanup (Advanced)"/>
                                    </UniformGrid>
                                </StackPanel>
                            </Border>

                            <Border Background="#F8FAFC" BorderBrush="#CBD5E1" BorderThickness="1" CornerRadius="12" Padding="14">
                                <StackPanel>
                                    <TextBlock Text="Laptop Boost Tweaks" Foreground="#7C2D12" FontSize="18" FontWeight="Bold" Margin="0,0,0,8"/>
                                    <UniformGrid Columns="2">
                                        <CheckBox Name="BalancedPowerCB" Content="Set Balanced Power Plan"/>
                                        <CheckBox Name="StartupDelayCB" Content="Disable Startup Delay"/>
                                        <CheckBox Name="BackgroundAppsCB" Content="Restrict Background Apps"/>
                                        <CheckBox Name="HiberCB" Content="Disable Hibernation (Advanced)"/>
                                    </UniformGrid>
                                </StackPanel>
                            </Border>
                        </StackPanel>
                    </ScrollViewer>

                    <Border Grid.Column="1" Background="#F8FAFC" BorderBrush="#CBD5E1" BorderThickness="1" CornerRadius="12" Padding="14">
                        <StackPanel>
                            <TextBlock Text="User Profiles" Foreground="#854D0E" FontSize="18" FontWeight="Bold" Margin="0,0,0,8"/>
                            <TextBlock Text="Select profiles for cleanup review" Foreground="#475569" Margin="0,0,0,8"/>
                            <ListBox Name="UserList" Height="295" SelectionMode="Extended"/>
                            <DockPanel Margin="0,10,0,0" LastChildFill="False">
                                <Button Name="RefreshUsersBtn" Content="Refresh" Background="#1E40AF" Foreground="White"/>
                                <Button Name="RenameUserBtn" Content="Rename" Background="#0F766E" Foreground="White"/>
                                <Button Name="DeleteUserBtn" Content="Delete" Background="#B91C1C" Foreground="White"/>
                            </DockPanel>
                        </StackPanel>
                    </Border>
                </Grid>
            </TabItem>

            <TabItem Header="Registry Paths">
                <Grid Margin="14">
                    <StackPanel>
                        <TextBlock Text="User Profiles Registry Path" FontSize="20" FontWeight="Bold" Foreground="#0F172A" Margin="0,0,0,10"/>
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
                        <Button Name="CopyRegPathBtn" Content="Copy to Clipboard" Background="#0EA5E9" Foreground="White" Margin="0,10,0,0" Padding="12,8"/>
                    </StackPanel>
                </Grid>
            </TabItem>

            <TabItem Header="About">
                <Grid Margin="14">
                    <StackPanel>
                        <TextBlock Text="Cleaner Pro" FontSize="24" FontWeight="Bold" Foreground="#0F172A" Margin="0,0,0,10"/>
                        <TextBlock Text="Advanced Cleanup &amp; Optimization Tool" FontSize="14" Foreground="#475569" Margin="0,0,0,20"/>

                        <TextBlock Text="Credits" FontSize="18" FontWeight="Bold" Foreground="#0C4A6E" Margin="0,0,0,10"/>
                        <TextBlock Text="Original Concept &amp; DNS Tools: DNS Labs" FontSize="13" Foreground="#334155" Margin="0,0,0,5"/>
                        <TextBlock Text="Enhanced Version &amp; UI Development: Your Name" FontSize="13" Foreground="#334155" Margin="0,0,0,20"/>

                        <TextBlock Text="Features" FontSize="18" FontWeight="Bold" Foreground="#0C4A6E" Margin="0,0,0,10"/>
                        <TextBlock Text="✓ VDI &amp; Laptop Presets" TextWrapping="Wrap" FontSize="12" Foreground="#334155" Margin="0,0,0,5"/>
                        <TextBlock Text="✓ Safe Cleanup &amp; Profile Management" TextWrapping="Wrap" FontSize="12" Foreground="#334155" Margin="0,0,0,5"/>
                        <TextBlock Text="✓ Space Estimation &amp; Preview" TextWrapping="Wrap" FontSize="12" Foreground="#334155" Margin="0,0,0,5"/>
                        <TextBlock Text="✓ Admin-Level Disk Cleanup" TextWrapping="Wrap" FontSize="12" Foreground="#334155" Margin="0,0,0,5"/>
                        <TextBlock Text="✓ System Registry Path References" TextWrapping="Wrap" FontSize="12" Foreground="#334155" Margin="0,0,0,20"/>

                        <TextBlock Text="Version: 2.0" FontSize="12" Foreground="#64748B" Margin="0,0,0,5"/>
                        <TextBlock Text="Regularly Updated for Latest Windows Versions" FontSize="12" Foreground="#64748B"/>
                    </StackPanel>
                </Grid>
            </TabItem>
        </TabControl>

        <DockPanel Grid.Row="2" Margin="0,10,0,0" LastChildFill="False">
            <TextBlock Name="EstimateText"
                       Text="Selected: 0 actions. Click Preview to estimate reclaimable space."
                       Foreground="#334155"
                       VerticalAlignment="Center"
                       Margin="0,0,10,0"/>
            <Button Name="PreviewBtn" Content="Preview Space" Height="42" Width="160" Background="#0EA5E9" Foreground="White"/>
            <Button Name="RunBtn" Content="Run Cleanup" Height="42" Width="220" Background="#2563EB" Foreground="White"/>
        </DockPanel>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

if ($null -eq $window) {
    [System.Windows.MessageBox]::Show(
        "UI failed to load. XAML is invalid or unsupported on this host.",
        "Cleaner Pro Startup Error",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    ) | Out-Null
    exit 1
}

$RunBtn = $window.FindName("RunBtn")
$PreviewBtn = $window.FindName("PreviewBtn")
$EstimateText = $window.FindName("EstimateText")
$UserList = $window.FindName("UserList")

$VDIPresetBtn = $window.FindName("VDIPresetBtn")
$LaptopPresetBtn = $window.FindName("LaptopPresetBtn")
$SelectAllBtn = $window.FindName("SelectAllBtn")
$ClearAllBtn = $window.FindName("ClearAllBtn")
$PresetStatusText = $window.FindName("PresetStatusText")

$RefreshUsersBtn = $window.FindName("RefreshUsersBtn")
$RenameUserBtn = $window.FindName("RenameUserBtn")
$DeleteUserBtn = $window.FindName("DeleteUserBtn")

$RegPathBox = $window.FindName("RegPathBox")
$CopyRegPathBtn = $window.FindName("CopyRegPathBtn")

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
$BalancedPowerCB = $window.FindName("BalancedPowerCB")
$StartupDelayCB = $window.FindName("StartupDelayCB")
$BackgroundAppsCB = $window.FindName("BackgroundAppsCB")
$HiberCB = $window.FindName("HiberCB")

function Ensure-Control {
    param(
        $Control,
        [Type]$ControlType
    )

    if ($null -eq $Control) {
        return New-Object $ControlType
    }

    return $Control
}

$RunBtn = Ensure-Control -Control $RunBtn -ControlType ([System.Windows.Controls.Button])
$PreviewBtn = Ensure-Control -Control $PreviewBtn -ControlType ([System.Windows.Controls.Button])
$EstimateText = Ensure-Control -Control $EstimateText -ControlType ([System.Windows.Controls.TextBlock])
$UserList = Ensure-Control -Control $UserList -ControlType ([System.Windows.Controls.ListBox])

$VDIPresetBtn = Ensure-Control -Control $VDIPresetBtn -ControlType ([System.Windows.Controls.Button])
$LaptopPresetBtn = Ensure-Control -Control $LaptopPresetBtn -ControlType ([System.Windows.Controls.Button])
$SelectAllBtn = Ensure-Control -Control $SelectAllBtn -ControlType ([System.Windows.Controls.Button])
$ClearAllBtn = Ensure-Control -Control $ClearAllBtn -ControlType ([System.Windows.Controls.Button])
$PresetStatusText = Ensure-Control -Control $PresetStatusText -ControlType ([System.Windows.Controls.TextBlock])

$RefreshUsersBtn = Ensure-Control -Control $RefreshUsersBtn -ControlType ([System.Windows.Controls.Button])
$RenameUserBtn = Ensure-Control -Control $RenameUserBtn -ControlType ([System.Windows.Controls.Button])
$DeleteUserBtn = Ensure-Control -Control $DeleteUserBtn -ControlType ([System.Windows.Controls.Button])

$RegPathBox = Ensure-Control -Control $RegPathBox -ControlType ([System.Windows.Controls.TextBox])
$CopyRegPathBtn = Ensure-Control -Control $CopyRegPathBtn -ControlType ([System.Windows.Controls.Button])

$TempCB = Ensure-Control -Control $TempCB -ControlType ([System.Windows.Controls.CheckBox])
$WinTempCB = Ensure-Control -Control $WinTempCB -ControlType ([System.Windows.Controls.CheckBox])
$RecycleCB = Ensure-Control -Control $RecycleCB -ControlType ([System.Windows.Controls.CheckBox])
$UpdateCB = Ensure-Control -Control $UpdateCB -ControlType ([System.Windows.Controls.CheckBox])
$DeliveryCB = Ensure-Control -Control $DeliveryCB -ControlType ([System.Windows.Controls.CheckBox])
$PrefetchCB = Ensure-Control -Control $PrefetchCB -ControlType ([System.Windows.Controls.CheckBox])
$ErrorCB = Ensure-Control -Control $ErrorCB -ControlType ([System.Windows.Controls.CheckBox])
$ThumbCB = Ensure-Control -Control $ThumbCB -ControlType ([System.Windows.Controls.CheckBox])
$BrowserCB = Ensure-Control -Control $BrowserCB -ControlType ([System.Windows.Controls.CheckBox])
$RecentCB = Ensure-Control -Control $RecentCB -ControlType ([System.Windows.Controls.CheckBox])
$CrashDumpCB = Ensure-Control -Control $CrashDumpCB -ControlType ([System.Windows.Controls.CheckBox])
$LogFilesCB = Ensure-Control -Control $LogFilesCB -ControlType ([System.Windows.Controls.CheckBox])

$AnimCB = Ensure-Control -Control $AnimCB -ControlType ([System.Windows.Controls.CheckBox])
$TransCB = Ensure-Control -Control $TransCB -ControlType ([System.Windows.Controls.CheckBox])
$StorageCB = Ensure-Control -Control $StorageCB -ControlType ([System.Windows.Controls.CheckBox])
$DnsCB = Ensure-Control -Control $DnsCB -ControlType ([System.Windows.Controls.CheckBox])
$ClipboardCB = Ensure-Control -Control $ClipboardCB -ControlType ([System.Windows.Controls.CheckBox])
$SpoolerCB = Ensure-Control -Control $SpoolerCB -ControlType ([System.Windows.Controls.CheckBox])
$ComponentCB = Ensure-Control -Control $ComponentCB -ControlType ([System.Windows.Controls.CheckBox])
$BalancedPowerCB = Ensure-Control -Control $BalancedPowerCB -ControlType ([System.Windows.Controls.CheckBox])
$StartupDelayCB = Ensure-Control -Control $StartupDelayCB -ControlType ([System.Windows.Controls.CheckBox])
$BackgroundAppsCB = Ensure-Control -Control $BackgroundAppsCB -ControlType ([System.Windows.Controls.CheckBox])
$HiberCB = Ensure-Control -Control $HiberCB -ControlType ([System.Windows.Controls.CheckBox])

$allOptionControls = @(
    $TempCB, $WinTempCB, $RecycleCB, $UpdateCB, $DeliveryCB, $PrefetchCB,
    $ErrorCB, $ThumbCB, $BrowserCB, $RecentCB, $CrashDumpCB, $LogFilesCB,
    $AnimCB, $TransCB, $StorageCB, $DnsCB, $ClipboardCB, $SpoolerCB, $ComponentCB,
    $BalancedPowerCB, $StartupDelayCB, $BackgroundAppsCB, $HiberCB
)

$controlMap = @{
    TempCB = $TempCB
    WinTempCB = $WinTempCB
    RecycleCB = $RecycleCB
    UpdateCB = $UpdateCB
    DeliveryCB = $DeliveryCB
    PrefetchCB = $PrefetchCB
    ErrorCB = $ErrorCB
    ThumbCB = $ThumbCB
    BrowserCB = $BrowserCB
    RecentCB = $RecentCB
    CrashDumpCB = $CrashDumpCB
    LogFilesCB = $LogFilesCB
    AnimCB = $AnimCB
    TransCB = $TransCB
    StorageCB = $StorageCB
    DnsCB = $DnsCB
    ClipboardCB = $ClipboardCB
    SpoolerCB = $SpoolerCB
    ComponentCB = $ComponentCB
    BalancedPowerCB = $BalancedPowerCB
    StartupDelayCB = $StartupDelayCB
    BackgroundAppsCB = $BackgroundAppsCB
    HiberCB = $HiberCB
}

$allOptionControls = @($allOptionControls | Where-Object { $null -ne $_ })
$filteredControlMap = @{}
foreach ($entry in $controlMap.GetEnumerator()) {
    if ($null -ne $entry.Value) {
        $filteredControlMap[$entry.Key] = $entry.Value
    }
}
$controlMap = $filteredControlMap

function Set-PresetState {
    param(
        [hashtable]$State,
        [string]$PresetName
    )

    foreach ($control in $allOptionControls) {
        $control.IsChecked = $false
    }

    foreach ($key in $State.Keys) {
        if ($controlMap.ContainsKey($key)) {
            $controlMap[$key].IsChecked = [bool]$State[$key]
        }
    }

    $PresetStatusText.Text = "Preset: $PresetName"
}

function Update-SelectionCount {
    $checkedCount = (@($allOptionControls | Where-Object { $_.IsChecked }) | Measure-Object).Count
    $EstimateText.Text = "Selected: $checkedCount actions. Click Preview to estimate reclaimable space."
}

function Get-EstimatedSelectedSizeBytes {
    $total = 0

    if ($TempCB.IsChecked) { $total += Get-DirectorySizeBytes -Path $env:TEMP }
    if ($WinTempCB.IsChecked) { $total += Get-DirectorySizeBytes -Path "C:\Windows\Temp" }
    if ($UpdateCB.IsChecked) { $total += Get-DirectorySizeBytes -Path "C:\Windows\SoftwareDistribution\Download" }
    if ($DeliveryCB.IsChecked) { $total += Get-DirectorySizeBytes -Path "C:\Windows\SoftwareDistribution\DeliveryOptimization" }
    if ($PrefetchCB.IsChecked) { $total += Get-DirectorySizeBytes -Path "C:\Windows\Prefetch" }
    if ($ErrorCB.IsChecked) { $total += Get-DirectorySizeBytes -Path "C:\ProgramData\Microsoft\Windows\WER" }
    if ($RecentCB.IsChecked) { $total += Get-DirectorySizeBytes -Path "$env:APPDATA\Microsoft\Windows\Recent" }
    if ($CrashDumpCB.IsChecked) {
        $total += Get-DirectorySizeBytes -Path "C:\Windows\Minidump"
        $total += Get-FileSizeBytes -Path "C:\Windows\MEMORY.DMP"
    }

    if ($BrowserCB.IsChecked) {
        $total += Get-DirectorySizeBytes -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
        $total += Get-DirectorySizeBytes -Path "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
        Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $total += Get-DirectorySizeBytes -Path (Join-Path $_.FullName "cache2\entries")
        }
    }

    if ($ThumbCB.IsChecked) {
        try {
            $total += (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" -Filter "thumbcache_*" -File -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
        } catch {
            $null = $null
        }
    }

    if ($LogFilesCB.IsChecked) {
        try {
            $total += (Get-ChildItem "C:\Windows\Logs\CBS" -Filter "*.log" -File -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
            $total += (Get-ChildItem "C:\Windows\Logs\DISM" -Filter "*.log" -File -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
        } catch {
            $null = $null
        }
    }

    foreach ($user in @($UserList.SelectedItems)) {
        $total += Get-DirectorySizeBytes -Path ("C:\Users\{0}" -f $user)
    }

    return $total
}

function Start-CleanupInSeparateWindow {
    param(
        [hashtable]$Options,
        [string[]]$SelectedUsers
    )

    $optionsJson = $Options | ConvertTo-Json -Compress
    $usersJson = @($SelectedUsers) | ConvertTo-Json -Compress
    $runnerPath = Join-Path $env:TEMP "CleanerProRunner.ps1"

    $runnerScript = @"
`$ErrorActionPreference = "Continue"
`$options = ConvertFrom-Json @'
$optionsJson
'@
`$users = ConvertFrom-Json @'
$usersJson
'@

if (`$users -is [string]) { `$users = @(`$users) }
if (`$null -eq `$users) { `$users = @() }

function Write-Step {
    param([string]`$Message)
    `$time = Get-Date -Format "HH:mm:ss"
    Write-Host "[`$time] `$Message"
}

function Invoke-Step {
    param(
        [string]`$Name,
        [scriptblock]`$Action
    )

    try {
        Write-Step "`$Name..."
        & `$Action
        Write-Step "`$Name completed"
    } catch {
        Write-Step "`$Name failed: `$(`$_.Exception.Message)"
    }
}

function Remove-PathContents {
    param([string]`$Path)
    if (Test-Path `$Path) {
        Get-ChildItem -Path `$Path -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "Cleaner Pro - External Run Window" -ForegroundColor Cyan
Write-Host ""

if (`$options.TempCB) {
    Invoke-Step "Cleaning user temp" { Remove-PathContents -Path `$env:TEMP }
}

if (`$options.WinTempCB) {
    Invoke-Step "Cleaning Windows temp" { Remove-PathContents -Path "C:\Windows\Temp" }
}

if (`$options.RecycleCB) {
    Invoke-Step "Cleaning recycle bin" { Clear-RecycleBin -Force -ErrorAction SilentlyContinue }
}

if (`$options.UpdateCB) {
    Invoke-Step "Cleaning Windows Update cache" {
        Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
        Remove-PathContents -Path "C:\Windows\SoftwareDistribution\Download"
        Start-Service wuauserv -ErrorAction SilentlyContinue
    }
}

if (`$options.DeliveryCB) {
    Invoke-Step "Cleaning delivery optimization cache" {
        Remove-PathContents -Path "C:\Windows\SoftwareDistribution\DeliveryOptimization"
    }
}

if (`$options.PrefetchCB) {
    Invoke-Step "Cleaning prefetch cache" { Remove-PathContents -Path "C:\Windows\Prefetch" }
}

if (`$options.ErrorCB) {
    Invoke-Step "Cleaning Windows error reports" { Remove-PathContents -Path "C:\ProgramData\Microsoft\Windows\WER" }
}

if (`$options.ThumbCB) {
    Invoke-Step "Cleaning thumbnail cache" {
        Get-ChildItem "`$env:LOCALAPPDATA\Microsoft\Windows\Explorer" -Filter "thumbcache_*" -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

if (`$options.BrowserCB) {
    Invoke-Step "Cleaning browser cache" {
        Remove-PathContents -Path "`$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
        Remove-PathContents -Path "`$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
        Get-ChildItem "`$env:APPDATA\Mozilla\Firefox\Profiles" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-PathContents -Path (Join-Path `$_.FullName "cache2\entries")
        }
    }
}

if (`$options.RecentCB) {
    Invoke-Step "Cleaning recent items" { Remove-PathContents -Path "`$env:APPDATA\Microsoft\Windows\Recent" }
}

if (`$options.CrashDumpCB) {
    Invoke-Step "Cleaning crash dumps" {
        Remove-PathContents -Path "C:\Windows\Minidump"
        Remove-Item "C:\Windows\MEMORY.DMP" -Force -ErrorAction SilentlyContinue
    }
}

if (`$options.LogFilesCB) {
    Invoke-Step "Cleaning CBS and DISM logs" {
        Get-ChildItem "C:\Windows\Logs\CBS" -Filter "*.log" -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
        Get-ChildItem "C:\Windows\Logs\DISM" -Filter "*.log" -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

if (`$options.AnimCB) {
    Invoke-Step "Disabling animations" {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Force | Out-Null
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name VisualFXSetting -Value 2
    }
}

if (`$options.TransCB) {
    Invoke-Step "Disabling transparency" {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Force | Out-Null
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name EnableTransparency -Value 0
    }
}

if (`$options.DnsCB) {
    Invoke-Step "Flushing DNS cache" { Clear-DnsClientCache -ErrorAction SilentlyContinue }
}

if (`$options.ClipboardCB) {
    Invoke-Step "Clearing clipboard" { Set-Clipboard -Value "" }
}

if (`$options.SpoolerCB) {
    Invoke-Step "Clearing print spooler queue" {
        Stop-Service spooler -Force -ErrorAction SilentlyContinue
        Remove-PathContents -Path "C:\Windows\System32\spool\PRINTERS"
        Start-Service spooler -ErrorAction SilentlyContinue
    }
}

if (`$options.ComponentCB) {
    Invoke-Step "Running DISM component cleanup" {
        Start-Process dism.exe -ArgumentList "/Online /Cleanup-Image /StartComponentCleanup" -Wait
    }
}

if (`$options.BalancedPowerCB) {
    Invoke-Step "Setting balanced power plan" { powercfg /setactive SCHEME_BALANCED | Out-Null }
}

if (`$options.StartupDelayCB) {
    Invoke-Step "Disabling startup delay" {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Force | Out-Null
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name StartupDelayInMSec -Type DWord -Value 0
    }
}

if (`$options.BackgroundAppsCB) {
    Invoke-Step "Restricting background apps" {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Force | Out-Null
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name GlobalUserDisabled -Type DWord -Value 1
    }
}

if (`$options.HiberCB) {
    Invoke-Step "Disabling hibernation" { powercfg -h off }
}

if (`$users.Count -gt 0) {
    foreach (`$user in `$users) {
        Invoke-Step "Removing profile `$user" {
            Remove-Item "C:\Users\`$user" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

if (`$options.StorageCB) {
    Invoke-Step "Running Disk Cleanup (final step)" {
        Start-Process cleanmgr.exe -ArgumentList "/VERYLOWDISK" -Wait
    }
}

Write-Step "All selected operations completed"
Write-Host ""
Write-Host "Window will remain open for review." -ForegroundColor Yellow
"@

    Set-Content -Path $runnerPath -Value $runnerScript -Encoding UTF8
    $runnerPowerShell = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
    Start-Process -FilePath $runnerPowerShell -ArgumentList "-NoProfile -NoExit -STA -ExecutionPolicy Bypass -File `"$runnerPath`"" | Out-Null
}

Load-UserProfiles -TargetList $UserList
Update-SelectionCount

$VDIPresetBtn.Add_Click({
    $vdiState = @{
        TempCB = $true
        WinTempCB = $true
        RecycleCB = $true
        UpdateCB = $true
        DeliveryCB = $true
        PrefetchCB = $false
        ErrorCB = $true
        ThumbCB = $true
        BrowserCB = $true
        RecentCB = $true
        CrashDumpCB = $true
        LogFilesCB = $true
        AnimCB = $false
        TransCB = $false
        StorageCB = $true
        DnsCB = $true
        ClipboardCB = $true
        SpoolerCB = $false
        ComponentCB = $false
        BalancedPowerCB = $false
        StartupDelayCB = $false
        BackgroundAppsCB = $false
        HiberCB = $false
    }

    Set-PresetState -State $vdiState -PresetName "VDI"
    Update-SelectionCount
})

$LaptopPresetBtn.Add_Click({
    $laptopState = @{
        TempCB = $true
        WinTempCB = $true
        RecycleCB = $true
        UpdateCB = $false
        DeliveryCB = $true
        PrefetchCB = $false
        ErrorCB = $true
        ThumbCB = $true
        BrowserCB = $true
        RecentCB = $true
        CrashDumpCB = $true
        LogFilesCB = $false
        AnimCB = $true
        TransCB = $true
        StorageCB = $true
        DnsCB = $true
        ClipboardCB = $true
        SpoolerCB = $false
        ComponentCB = $false
        BalancedPowerCB = $true
        StartupDelayCB = $true
        BackgroundAppsCB = $true
        HiberCB = $false
    }

    Set-PresetState -State $laptopState -PresetName "Laptop"
    Update-SelectionCount
})

$SelectAllBtn.Add_Click({
    foreach ($control in $allOptionControls) {
        $control.IsChecked = $true
    }

    $PresetStatusText.Text = "Preset: All Selected"
    Update-SelectionCount
})

$ClearAllBtn.Add_Click({
    foreach ($control in $allOptionControls) {
        $control.IsChecked = $false
    }

    $PresetStatusText.Text = "Preset: Custom"
    Update-SelectionCount
})

$RefreshUsersBtn.Add_Click({
    Load-UserProfiles -TargetList $UserList
})

$RenameUserBtn.Add_Click({
    if ($UserList.SelectedItems.Count -ne 1) {
        [System.Windows.MessageBox]::Show(
            "Select exactly one profile to rename.",
            "Rename Profile",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
        return
    }

    $oldName = [string]$UserList.SelectedItem
    $newName = [Microsoft.VisualBasic.Interaction]::InputBox(
        "Enter new profile folder name for '$oldName':",
        "Rename Profile",
        $oldName
    )

    if ([string]::IsNullOrWhiteSpace($newName) -or $newName -eq $oldName) {
        return
    }

    $warningText = "Renaming a profile folder can break profile mapping if SID registry values are not updated. Continue?"
    $renameConfirm = [System.Windows.MessageBox]::Show(
        $warningText,
        "Advanced Warning",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )

    if ($renameConfirm -ne [System.Windows.MessageBoxResult]::Yes) {
        return
    }

    try {
        Rename-Item -Path ("C:\Users\{0}" -f $oldName) -NewName $newName -ErrorAction Stop
        Load-UserProfiles -TargetList $UserList
        [System.Windows.MessageBox]::Show("Profile renamed: $oldName -> $newName", "Rename Profile") | Out-Null
    } catch {
        [System.Windows.MessageBox]::Show("Rename failed: $($_.Exception.Message)", "Rename Profile") | Out-Null
    }
})

$DeleteUserBtn.Add_Click({
    if ($UserList.SelectedItems.Count -eq 0) {
        [System.Windows.MessageBox]::Show(
            "Select at least one profile to delete.",
            "Delete Profile",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
        return
    }

    $selectedUsers = @($UserList.SelectedItems)
    $preview = $selectedUsers -join ", "
    $confirm = [System.Windows.MessageBox]::Show(
        "Delete selected profile folders now?`n`n$preview`n`nThis cannot be undone.",
        "Advanced Warning",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )

    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) {
        return
    }

    foreach ($user in $selectedUsers) {
        try {
            Remove-Item ("C:\Users\{0}" -f $user) -Recurse -Force -ErrorAction Stop
        } catch {
            [System.Windows.MessageBox]::Show("Delete failed for ${user}: $($_.Exception.Message)", "Delete Profile") | Out-Null
        }
    }

    Load-UserProfiles -TargetList $UserList
})

$CopyRegPathBtn.Add_Click({
    $regPath = $RegPathBox.Text
    Set-Clipboard -Value $regPath
    [System.Windows.MessageBox]::Show(
        "Registry path copied to clipboard:`n`n$regPath",
        "Copy Success",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Information
    ) | Out-Null
})

$PreviewBtn.Add_Click({
    $sizeBytes = Get-EstimatedSelectedSizeBytes
    $sizeGB = [math]::Round($sizeBytes / 1GB, 2)
    $checkedCount = (@($allOptionControls | Where-Object { $_.IsChecked }) | Measure-Object).Count
    $profileCount = $UserList.SelectedItems.Count
    $EstimateText.Text = "Selected: $checkedCount actions, $profileCount profiles. Estimated reclaimable space: $sizeGB GB"
})

foreach ($control in $allOptionControls) {
    $control.Add_Checked({ Update-SelectionCount })
    $control.Add_Unchecked({ Update-SelectionCount })
}

$UserList.Add_SelectionChanged({ Update-SelectionCount })

$RunBtn.Add_Click({
    $selectedUsers = @($UserList.SelectedItems | ForEach-Object { [string]$_ })

    $options = @{}
    foreach ($key in $controlMap.Keys) {
        $options[$key] = [bool]$controlMap[$key].IsChecked
    }

    $checkedCount = (@($allOptionControls | Where-Object { $_.IsChecked }) | Measure-Object).Count
    if ($checkedCount -eq 0 -and $selectedUsers.Count -eq 0) {
        [System.Windows.MessageBox]::Show(
            "Select at least one cleanup option or profile first.",
            "Run Cleanup",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
        return
    }

    if ($ComponentCB.IsChecked -or $SpoolerCB.IsChecked -or $HiberCB.IsChecked -or $PrefetchCB.IsChecked) {
        $advancedConfirm = [System.Windows.MessageBox]::Show(
            "Advanced options are selected. Continue with cleanup?",
            "Advanced Warning",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )

        if ($advancedConfirm -ne [System.Windows.MessageBoxResult]::Yes) {
            return
        }
    }

    Start-CleanupInSeparateWindow -Options $options -SelectedUsers $selectedUsers
})

$window.ShowDialog() | Out-Null