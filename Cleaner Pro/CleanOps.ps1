$scriptPath = $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($scriptPath)) {
    # Running via irm | iex — download and re-execute as a temp file
    $tempFile = Join-Path $env:TEMP "CleanOps_Run.ps1"
    $scriptUrl = "https://raw.githubusercontent.com/R-Rinku/Windows-Tweaks-Hub/refs/heads/main/Cleaner%20Pro/CleanOps.ps1"
    Invoke-RestMethod -Uri $scriptUrl -OutFile $tempFile
    Start-Process powershell.exe -ArgumentList "-NoProfile -STA -ExecutionPolicy Bypass -File `"$tempFile`"" -Verb RunAs
    exit
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
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TabControl Grid.Row="0" Background="#F8FAFC" BorderBrush="#CBD5E1">
            <TabItem Header="Cleanup">
                <Grid Margin="10">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="2*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <ScrollViewer Grid.Column="0" VerticalScrollBarVisibility="Auto" Margin="0,0,10,0">
                        <StackPanel>
                            <Border Background="#F8FAFC" BorderBrush="#CBD5E1" BorderThickness="1" CornerRadius="12" Padding="10" Margin="0,0,0,10">
                                <StackPanel>
                                    <TextBlock Text="Recommended Selections" FontWeight="Bold" FontSize="16" Foreground="#0F172A" Margin="0,0,0,8"/>
                                    <UniformGrid Columns="3" Margin="0,0,0,8">
                                        <Button Name="StandardPresetBtn" Content="Standard" Background="#334155" Foreground="White" Height="42" FontSize="14"/>
                                        <Button Name="MinimalPresetBtn" Content="Minimal" Background="#0F766E" Foreground="White" Height="42" FontSize="14"/>
                                        <Button Name="ClearAllBtn" Content="Clear" Background="#475569" Foreground="White" Height="42" FontSize="14"/>
                                    </UniformGrid>
                                    <DockPanel LastChildFill="False" Margin="0,0,0,6">
                                        <TextBlock Text="Quick Profiles" FontWeight="SemiBold" FontSize="13" Foreground="#334155" VerticalAlignment="Center" Margin="0,0,10,0"/>
                                        <Button Name="VDIPresetBtn" Content="VDI" Background="#0EA5E9" Foreground="White" Padding="10,5"/>
                                        <Button Name="LaptopPresetBtn" Content="Laptop" Background="#16A34A" Foreground="White" Padding="10,5"/>
                                        <Button Name="SelectAllBtn" Content="All" Background="#1E40AF" Foreground="White" Padding="10,5"/>
                                    </DockPanel>
                                    <DockPanel LastChildFill="False">
                                        <CheckBox Name="EnterpriseModeCB" Content="Enterprise Mode (Recommended) (?)" IsChecked="True" Margin="0,2,8,0" VerticalAlignment="Center" ToolTip="Keeps risky options disabled for enterprise stability (DISM, Prefetch, Spooler, Hibernation, profile rename/delete)."/>
                                        <TextBlock Name="PresetStatusText" Text="Preset: Custom" FontWeight="SemiBold" Foreground="#334155" VerticalAlignment="Center"/>
                                    </DockPanel>
                                </StackPanel>
                            </Border>

                            <Border Background="#F8FAFC" BorderBrush="#CBD5E1" BorderThickness="1" CornerRadius="12" Padding="14" Margin="0,0,0,10">
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>

                                    <StackPanel Grid.Column="0" Margin="0,0,8,0">
                                        <TextBlock Text="Essential Tweaks" Foreground="#0C4A6E" FontSize="18" FontWeight="Bold" Margin="0,0,0,8"/>
                                        <CheckBox Name="TempCB" Content="User Temp Files (?)" ToolTip="Clears per-user temporary files from the current user temp directory."/>
                                        <CheckBox Name="WinTempCB" Content="Windows Temp (?)" ToolTip="Removes temporary files from C:\Windows\Temp (admin required)."/>
                                        <CheckBox Name="RecycleCB" Content="Recycle Bin (?)" ToolTip="Empties Recycle Bin for all accessible drives."/>
                                        <CheckBox Name="UpdateCB" Content="Windows Update Cache (?)" ToolTip="Clears Windows Update download cache. Useful after patch cycles."/>
                                        <CheckBox Name="DeliveryCB" Content="Delivery Optimization Cache (?)" ToolTip="Removes Delivery Optimization cached content."/>
                                        <CheckBox Name="ErrorCB" Content="Windows Error Reports (?)" ToolTip="Cleans Windows Error Reporting data in ProgramData."/>
                                        <CheckBox Name="ThumbCB" Content="Thumbnail Cache (?)" ToolTip="Rebuilds Explorer thumbnail cache by removing existing cache files."/>
                                        <CheckBox Name="BrowserCB" Content="Browser Cache (Chrome/Edge/Firefox) (?)" ToolTip="Clears common browser cache paths for faster profile cleanup."/>
                                        <CheckBox Name="RecentCB" Content="Recent Items List (?)" ToolTip="Removes recently accessed item shortcuts for privacy cleanup."/>
                                        <CheckBox Name="CrashDumpCB" Content="Crash Dumps (?)" ToolTip="Deletes memory dump files that can consume significant disk space."/>
                                        <CheckBox Name="LogFilesCB" Content="CBS and DISM Logs (?)" ToolTip="Removes component servicing logs. Keep disabled for deep troubleshooting cases."/>
                                        <CheckBox Name="StorageCB" Content="Run Disk Cleanup (At End) (?)" ToolTip="Runs CleanMgr as the final step for additional system-managed cleanup categories."/>
                                    </StackPanel>

                                    <StackPanel Grid.Column="1" Margin="8,0,0,0">
                                        <TextBlock Text="Customize Preferences" Foreground="#166534" FontSize="18" FontWeight="Bold" Margin="0,0,0,8"/>
                                        <CheckBox Name="AnimCB" Content="Disable Animations (?)" ToolTip="Turns off Windows animations to improve perceived responsiveness."/>
                                        <CheckBox Name="TransCB" Content="Disable Transparency (?)" ToolTip="Disables visual transparency effects for lighter UI rendering."/>
                                        <CheckBox Name="DnsCB" Content="Flush DNS Cache (?)" ToolTip="Clears local DNS resolver cache."/>
                                        <CheckBox Name="ClipboardCB" Content="Clear Clipboard (?)" ToolTip="Wipes current clipboard contents."/>
                                        <CheckBox Name="BalancedPowerCB" Content="Set Balanced Power Plan (?)" ToolTip="Applies Balanced power scheme for safer enterprise defaults."/>
                                        <CheckBox Name="StartupDelayCB" Content="Disable Startup Delay (?)" ToolTip="Reduces startup delay in Explorer shell initialization."/>
                                        <CheckBox Name="BackgroundAppsCB" Content="Restrict Background Apps (?)" ToolTip="Limits background app activity to reduce CPU and memory usage."/>
                                        <CheckBox Name="PrefetchCB" Content="Prefetch Cache (Advanced) (?)" ToolTip="Clears prefetch files. Usually avoid in persistent enterprise endpoints."/>
                                        <CheckBox Name="SpoolerCB" Content="Clear Print Spooler Queue (Advanced) (?)" ToolTip="Stops Print Spooler and clears queued jobs. Use only for print issues."/>
                                        <CheckBox Name="ComponentCB" Content="DISM Component Cleanup (Advanced) (?)" ToolTip="Runs DISM StartComponentCleanup. Can take long and should be change-controlled."/>
                                        <CheckBox Name="HiberCB" Content="Disable Hibernation (Advanced) (?)" ToolTip="Disables hibernation and removes hiberfil.sys. Not recommended for laptop fleets by default."/>
                                    </StackPanel>
                                </Grid>
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

            <TabItem Header="Tweeks &amp; Settings">
                <Grid Margin="10">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <ScrollViewer Grid.Column="0" VerticalScrollBarVisibility="Auto" Margin="0,0,10,0">
                        <StackPanel>
                            <Border Background="#F8FAFC" BorderBrush="#CBD5E1" BorderThickness="1" CornerRadius="12" Padding="12" Margin="0,0,0,10">
                                <StackPanel>
                                    <TextBlock Text="Features" FontSize="18" FontWeight="Bold" Foreground="#0F172A" Margin="0,0,0,8"/>
                                    <CheckBox Name="DotNetFeatureCB" Content="All .Net Framework (2,3,4) (?)" ToolTip="Installs .NET optional framework components (restart may be required)."/>
                                    <CheckBox Name="DisableLegacyF8CB" Content="Disable Legacy F8 Boot Recovery (?)" ToolTip="Sets boot menu policy to standard."
                                              Foreground="#7F1D1D"/>
                                    <CheckBox Name="EnableRegBackupTaskCB" Content="Enable Daily Registry Backup Task 12.30am (?)" ToolTip="Creates a daily scheduled task for registry export backup."/>
                                    <CheckBox Name="EnableLegacyF8CB" Content="Enable Legacy F8 Boot Recovery (?)" ToolTip="Sets boot menu policy to legacy."
                                              Foreground="#7F1D1D"/>
                                    <CheckBox Name="HyperVCB" Content="HyperV Virtualization (?)" ToolTip="Installs Hyper-V related optional features (restart may be required)."/>
                                    <CheckBox Name="LegacyMediaCB" Content="Legacy Media (WMP, DirectPlay) (?)" ToolTip="Installs classic media components and DirectPlay."/>
                                    <CheckBox Name="NfsCB" Content="NFS - Network File System (?)" ToolTip="Installs NFS client components."/>
                                    <CheckBox Name="SandboxCB" Content="Windows Sandbox (?)" ToolTip="Installs Windows Sandbox optional feature."/>
                                    <CheckBox Name="WslCB" Content="Windows Subsystem for Linux (?)" ToolTip="Installs WSL and VirtualMachinePlatform features."/>
                                    <Button Name="InstallFeaturesBtn" Content="Install Features" Background="#334155" Foreground="White" Margin="0,8,0,0"/>
                                </StackPanel>
                            </Border>

                            <Border Background="#F8FAFC" BorderBrush="#CBD5E1" BorderThickness="1" CornerRadius="12" Padding="12">
                                <StackPanel>
                                    <TextBlock Text="Fixes" FontSize="18" FontWeight="Bold" Foreground="#0F172A" Margin="0,0,0,8"/>
                                    <Button Name="ResetNetworkBtn" Content="Reset Network" Background="#475569" Foreground="White"/>
                                    <Button Name="SystemCorruptionScanBtn" Content="System Corruption Scan" Background="#475569" Foreground="White"/>
                                </StackPanel>
                            </Border>
                        </StackPanel>
                    </ScrollViewer>

                    <ScrollViewer Grid.Column="1" VerticalScrollBarVisibility="Auto">
                        <StackPanel>
                            <Border Background="#F8FAFC" BorderBrush="#CBD5E1" BorderThickness="1" CornerRadius="12" Padding="12" Margin="0,0,0,10">
                                <StackPanel>
                                    <TextBlock Text="Legacy Windows Panels" FontSize="18" FontWeight="Bold" Foreground="#0F172A" Margin="0,0,0,8"/>
                                    <Button Name="ComputerManagementBtn" Content="Computer Management" Background="#E2E8F0" Foreground="#1E293B"/>
                                    <Button Name="ControlPanelBtn" Content="Control Panel" Background="#E2E8F0" Foreground="#1E293B"/>
                                    <Button Name="NetworkConnectionsBtn" Content="Network Connections" Background="#E2E8F0" Foreground="#1E293B"/>
                                    <Button Name="PowerPanelBtn" Content="Power Panel" Background="#E2E8F0" Foreground="#1E293B"/>
                                    <Button Name="PrinterPanelBtn" Content="Printer Panel" Background="#E2E8F0" Foreground="#1E293B"/>
                                    <Button Name="RegionBtn" Content="Region" Background="#E2E8F0" Foreground="#1E293B"/>
                                    <Button Name="SoundSettingsBtn" Content="Sound Settings" Background="#E2E8F0" Foreground="#1E293B"/>
                                    <Button Name="SystemPropertiesBtn" Content="System Properties" Background="#E2E8F0" Foreground="#1E293B"/>
                                    <Button Name="TimeAndDateBtn" Content="Time and Date" Background="#E2E8F0" Foreground="#1E293B"/>
                                </StackPanel>
                            </Border>

                            <Border Background="#F8FAFC" BorderBrush="#CBD5E1" BorderThickness="1" CornerRadius="12" Padding="12">
                                <StackPanel>
                                    <TextBlock Text="User Profiles Registry Path" FontSize="18" FontWeight="Bold" Foreground="#0F172A" Margin="0,0,0,8"/>
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
                            </Border>
                        </StackPanel>
                    </ScrollViewer>
                </Grid>
            </TabItem>

            <TabItem Header="About">
                <Grid Margin="14">
                    <StackPanel>
                        <TextBlock Text="Cleaner Pro" FontSize="24" FontWeight="Bold" Foreground="#0F172A" Margin="0,0,0,10"/>
                        <TextBlock Text="Advanced Cleanup &amp; Optimization Tool" FontSize="14" Foreground="#475569" Margin="0,0,0,20"/>

                        <TextBlock Text="Credits" FontSize="18" FontWeight="Bold" Foreground="#0C4A6E" Margin="0,0,0,10"/>
                        <TextBlock Text="Original Concept: DNS Labs" FontSize="13" Foreground="#334155" Margin="0,0,0,5"/>
                        <TextBlock Text="Enhanced Version &amp; UI Development: Ri" FontSize="13" Foreground="#334155" Margin="0,0,0,20"/>

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

        <DockPanel Grid.Row="1" Margin="0,10,0,0" LastChildFill="False">
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
$StandardPresetBtn = $window.FindName("StandardPresetBtn")
$MinimalPresetBtn = $window.FindName("MinimalPresetBtn")
$EnterpriseModeCB = $window.FindName("EnterpriseModeCB")
$PresetStatusText = $window.FindName("PresetStatusText")

$RefreshUsersBtn = $window.FindName("RefreshUsersBtn")
$RenameUserBtn = $window.FindName("RenameUserBtn")
$DeleteUserBtn = $window.FindName("DeleteUserBtn")

$RegPathBox = $window.FindName("RegPathBox")
$CopyRegPathBtn = $window.FindName("CopyRegPathBtn")

$DotNetFeatureCB = $window.FindName("DotNetFeatureCB")
$DisableLegacyF8CB = $window.FindName("DisableLegacyF8CB")
$EnableRegBackupTaskCB = $window.FindName("EnableRegBackupTaskCB")
$EnableLegacyF8CB = $window.FindName("EnableLegacyF8CB")
$HyperVCB = $window.FindName("HyperVCB")
$LegacyMediaCB = $window.FindName("LegacyMediaCB")
$NfsCB = $window.FindName("NfsCB")
$SandboxCB = $window.FindName("SandboxCB")
$WslCB = $window.FindName("WslCB")

$InstallFeaturesBtn = $window.FindName("InstallFeaturesBtn")
$ResetNetworkBtn = $window.FindName("ResetNetworkBtn")
$SystemCorruptionScanBtn = $window.FindName("SystemCorruptionScanBtn")

$ComputerManagementBtn = $window.FindName("ComputerManagementBtn")
$ControlPanelBtn = $window.FindName("ControlPanelBtn")
$NetworkConnectionsBtn = $window.FindName("NetworkConnectionsBtn")
$PowerPanelBtn = $window.FindName("PowerPanelBtn")
$PrinterPanelBtn = $window.FindName("PrinterPanelBtn")
$RegionBtn = $window.FindName("RegionBtn")
$SoundSettingsBtn = $window.FindName("SoundSettingsBtn")
$SystemPropertiesBtn = $window.FindName("SystemPropertiesBtn")
$TimeAndDateBtn = $window.FindName("TimeAndDateBtn")

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
$StandardPresetBtn = Ensure-Control -Control $StandardPresetBtn -ControlType ([System.Windows.Controls.Button])
$MinimalPresetBtn = Ensure-Control -Control $MinimalPresetBtn -ControlType ([System.Windows.Controls.Button])
$EnterpriseModeCB = Ensure-Control -Control $EnterpriseModeCB -ControlType ([System.Windows.Controls.CheckBox])
$PresetStatusText = Ensure-Control -Control $PresetStatusText -ControlType ([System.Windows.Controls.TextBlock])

$RefreshUsersBtn = Ensure-Control -Control $RefreshUsersBtn -ControlType ([System.Windows.Controls.Button])
$RenameUserBtn = Ensure-Control -Control $RenameUserBtn -ControlType ([System.Windows.Controls.Button])
$DeleteUserBtn = Ensure-Control -Control $DeleteUserBtn -ControlType ([System.Windows.Controls.Button])

$RegPathBox = Ensure-Control -Control $RegPathBox -ControlType ([System.Windows.Controls.TextBox])
$CopyRegPathBtn = Ensure-Control -Control $CopyRegPathBtn -ControlType ([System.Windows.Controls.Button])

$DotNetFeatureCB = Ensure-Control -Control $DotNetFeatureCB -ControlType ([System.Windows.Controls.CheckBox])
$DisableLegacyF8CB = Ensure-Control -Control $DisableLegacyF8CB -ControlType ([System.Windows.Controls.CheckBox])
$EnableRegBackupTaskCB = Ensure-Control -Control $EnableRegBackupTaskCB -ControlType ([System.Windows.Controls.CheckBox])
$EnableLegacyF8CB = Ensure-Control -Control $EnableLegacyF8CB -ControlType ([System.Windows.Controls.CheckBox])
$HyperVCB = Ensure-Control -Control $HyperVCB -ControlType ([System.Windows.Controls.CheckBox])
$LegacyMediaCB = Ensure-Control -Control $LegacyMediaCB -ControlType ([System.Windows.Controls.CheckBox])
$NfsCB = Ensure-Control -Control $NfsCB -ControlType ([System.Windows.Controls.CheckBox])
$SandboxCB = Ensure-Control -Control $SandboxCB -ControlType ([System.Windows.Controls.CheckBox])
$WslCB = Ensure-Control -Control $WslCB -ControlType ([System.Windows.Controls.CheckBox])

$InstallFeaturesBtn = Ensure-Control -Control $InstallFeaturesBtn -ControlType ([System.Windows.Controls.Button])
$ResetNetworkBtn = Ensure-Control -Control $ResetNetworkBtn -ControlType ([System.Windows.Controls.Button])
$SystemCorruptionScanBtn = Ensure-Control -Control $SystemCorruptionScanBtn -ControlType ([System.Windows.Controls.Button])

$ComputerManagementBtn = Ensure-Control -Control $ComputerManagementBtn -ControlType ([System.Windows.Controls.Button])
$ControlPanelBtn = Ensure-Control -Control $ControlPanelBtn -ControlType ([System.Windows.Controls.Button])
$NetworkConnectionsBtn = Ensure-Control -Control $NetworkConnectionsBtn -ControlType ([System.Windows.Controls.Button])
$PowerPanelBtn = Ensure-Control -Control $PowerPanelBtn -ControlType ([System.Windows.Controls.Button])
$PrinterPanelBtn = Ensure-Control -Control $PrinterPanelBtn -ControlType ([System.Windows.Controls.Button])
$RegionBtn = Ensure-Control -Control $RegionBtn -ControlType ([System.Windows.Controls.Button])
$SoundSettingsBtn = Ensure-Control -Control $SoundSettingsBtn -ControlType ([System.Windows.Controls.Button])
$SystemPropertiesBtn = Ensure-Control -Control $SystemPropertiesBtn -ControlType ([System.Windows.Controls.Button])
$TimeAndDateBtn = Ensure-Control -Control $TimeAndDateBtn -ControlType ([System.Windows.Controls.Button])

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

function Set-EnterpriseMode {
    param([bool]$Enabled)

    $enterpriseRestrictedOptions = @(
        $PrefetchCB, $SpoolerCB, $ComponentCB, $HiberCB,
        $DisableLegacyF8CB, $EnableLegacyF8CB, $HyperVCB, $LegacyMediaCB,
        $SandboxCB, $WslCB
    )

    $enterpriseRestrictedButtons = @(
        $RenameUserBtn, $DeleteUserBtn
    )

    if ($Enabled) {
        foreach ($control in $enterpriseRestrictedOptions) {
            if ($null -ne $control) {
                $control.IsChecked = $false
                $control.IsEnabled = $false
            }
        }

        foreach ($control in $enterpriseRestrictedButtons) {
            if ($null -ne $control) {
                $control.IsEnabled = $false
            }
        }
    } else {
        foreach ($control in $enterpriseRestrictedOptions) {
            if ($null -ne $control) {
                $control.IsEnabled = $true
            }
        }

        foreach ($control in $enterpriseRestrictedButtons) {
            if ($null -ne $control) {
                $control.IsEnabled = $true
            }
        }
    }
}

function Add-OptionalFeatureNames {
    param(
        [System.Collections.Generic.List[string]]$Target,
        [string[]]$Names
    )

    foreach ($name in $Names) {
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        if (-not $Target.Contains($name)) {
            $Target.Add($name)
        }
    }
}

function Enable-OptionalFeatureSafe {
    param(
        [string]$FeatureName,
        [System.Collections.Generic.List[string]]$Status
    )

    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName -ErrorAction Stop
        if ($feature.State -eq "Enabled") {
            $Status.Add("Already enabled: $FeatureName")
            return $true
        }

        Enable-WindowsOptionalFeature -Online -FeatureName $FeatureName -All -NoRestart -ErrorAction Stop | Out-Null
        $Status.Add("Installed: $FeatureName")
        return $true
    } catch {
        $Status.Add("Skipped: $FeatureName ($($_.Exception.Message))")
        return $false
    }
}

function Install-SelectedFeatures {
    $featuresToInstall = New-Object 'System.Collections.Generic.List[string]'

    if ($DotNetFeatureCB.IsChecked) {
        Add-OptionalFeatureNames -Target $featuresToInstall -Names @("NetFx3", "NetFx4-AdvSrvs")
    }
    if ($HyperVCB.IsChecked) {
        Add-OptionalFeatureNames -Target $featuresToInstall -Names @("Microsoft-Hyper-V-All", "HypervisorPlatform")
    }
    if ($LegacyMediaCB.IsChecked) {
        Add-OptionalFeatureNames -Target $featuresToInstall -Names @("WindowsMediaPlayer", "DirectPlay")
    }
    if ($NfsCB.IsChecked) {
        Add-OptionalFeatureNames -Target $featuresToInstall -Names @("ServicesForNFS-ClientOnly", "ClientForNFS-Infrastructure")
    }
    if ($SandboxCB.IsChecked) {
        Add-OptionalFeatureNames -Target $featuresToInstall -Names @("Containers-DisposableClientVM")
    }
    if ($WslCB.IsChecked) {
        Add-OptionalFeatureNames -Target $featuresToInstall -Names @("Microsoft-Windows-Subsystem-Linux", "VirtualMachinePlatform")
    }

    $didWork = $false
    $status = New-Object System.Collections.Generic.List[string]

    foreach ($featureName in $featuresToInstall) {
        if (Enable-OptionalFeatureSafe -FeatureName $featureName -Status $status) {
            $didWork = $true
        }
    }

    if ($DisableLegacyF8CB.IsChecked) {
        try {
            bcdedit /set "{default}" bootmenupolicy standard | Out-Null
            $status.Add("Applied: Legacy F8 disabled")
            $didWork = $true
        } catch {
            $status.Add("Failed: Disable Legacy F8 ($($_.Exception.Message))")
        }
    }

    if ($EnableLegacyF8CB.IsChecked) {
        try {
            bcdedit /set "{default}" bootmenupolicy legacy | Out-Null
            $status.Add("Applied: Legacy F8 enabled")
            $didWork = $true
        } catch {
            $status.Add("Failed: Enable Legacy F8 ($($_.Exception.Message))")
        }
    }

    if ($EnableRegBackupTaskCB.IsChecked) {
        try {
            $backupFolder = Join-Path $env:ProgramData "CleanerPro\RegistryBackups"
            New-Item -Path $backupFolder -ItemType Directory -Force | Out-Null

            $backupScriptPath = Join-Path $backupFolder "ExportRegistry.ps1"
            $backupScript = @"
`$dest = Join-Path "$backupFolder" ("RegistryBackup_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".reg")
reg export HKLM `$dest /y | Out-Null
"@
            Set-Content -Path $backupScriptPath -Value $backupScript -Encoding UTF8

            $taskAction = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$backupScriptPath`""
            schtasks /Create /F /TN "CleanerPro\DailyRegistryBackup" /SC DAILY /ST 00:30 /RL HIGHEST /TR $taskAction | Out-Null
            $status.Add("Applied: Daily registry backup task created")
            $didWork = $true
        } catch {
            $status.Add("Failed: Registry backup task ($($_.Exception.Message))")
        }
    }

    if (-not $didWork) {
        [System.Windows.MessageBox]::Show(
            "No Tweeks & Settings feature option is selected.",
            "Install Features",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
        return
    }

    $message = ($status -join [Environment]::NewLine) + [Environment]::NewLine + [Environment]::NewLine + "A restart may be required for some changes."
    [System.Windows.MessageBox]::Show(
        $message,
        "Install Features",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Information
    ) | Out-Null
}

function Invoke-OpenLegacyPanel {
    param(
        [string]$FilePath,
        [string[]]$Arguments
    )

    try {
        if ($Arguments -and $Arguments.Count -gt 0) {
            Start-Process -FilePath $FilePath -ArgumentList $Arguments | Out-Null
        } else {
            Start-Process -FilePath $FilePath | Out-Null
        }
    } catch {
        [System.Windows.MessageBox]::Show(
            "Unable to open panel: $($_.Exception.Message)",
            "Tweeks & Settings",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
}

function Apply-StandardPreset {
    $state = @{
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

    Set-PresetState -State $state -PresetName "Standard"
    Update-SelectionCount
}

function Apply-MinimalPreset {
    $state = @{
        TempCB = $true
        WinTempCB = $true
        RecycleCB = $true
        UpdateCB = $false
        DeliveryCB = $true
        PrefetchCB = $false
        ErrorCB = $true
        ThumbCB = $true
        BrowserCB = $true
        RecentCB = $false
        CrashDumpCB = $false
        LogFilesCB = $false
        AnimCB = $false
        TransCB = $false
        StorageCB = $true
        DnsCB = $false
        ClipboardCB = $false
        SpoolerCB = $false
        ComponentCB = $false
        BalancedPowerCB = $false
        StartupDelayCB = $false
        BackgroundAppsCB = $false
        HiberCB = $false
    }

    Set-PresetState -State $state -PresetName "Minimal"
    Update-SelectionCount
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
Set-EnterpriseMode -Enabled ([bool]$EnterpriseModeCB.IsChecked)

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

$StandardPresetBtn.Add_Click({
    Apply-StandardPreset
})

$MinimalPresetBtn.Add_Click({
    Apply-MinimalPreset
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

$EnterpriseModeCB.Add_Checked({
    Set-EnterpriseMode -Enabled $true
    $PresetStatusText.Text = "Preset: Enterprise Safe"
    Update-SelectionCount
})

$EnterpriseModeCB.Add_Unchecked({
    Set-EnterpriseMode -Enabled $false
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

$InstallFeaturesBtn.Add_Click({
    Install-SelectedFeatures
})

$ResetNetworkBtn.Add_Click({
    $cmd = @'
Write-Host "Resetting network stack..." -ForegroundColor Cyan
netsh winsock reset
netsh int ip reset
ipconfig /flushdns
Write-Host "Network reset completed. Restart is recommended." -ForegroundColor Yellow
'@
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile", "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $cmd | Out-Null
})

$SystemCorruptionScanBtn.Add_Click({
    $cmd = @'
Write-Host "Starting system corruption scan..." -ForegroundColor Cyan
sfc /scannow
DISM /Online /Cleanup-Image /RestoreHealth
Write-Host "System corruption scan completed." -ForegroundColor Green
'@
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile", "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $cmd | Out-Null
})

$ComputerManagementBtn.Add_Click({ Invoke-OpenLegacyPanel -FilePath "compmgmt.msc" })
$ControlPanelBtn.Add_Click({ Invoke-OpenLegacyPanel -FilePath "control.exe" })
$NetworkConnectionsBtn.Add_Click({ Invoke-OpenLegacyPanel -FilePath "ncpa.cpl" })
$PowerPanelBtn.Add_Click({ Invoke-OpenLegacyPanel -FilePath "powercfg.cpl" })
$PrinterPanelBtn.Add_Click({ Invoke-OpenLegacyPanel -FilePath "control.exe" -Arguments @("printers") })
$RegionBtn.Add_Click({ Invoke-OpenLegacyPanel -FilePath "intl.cpl" })
$SoundSettingsBtn.Add_Click({ Invoke-OpenLegacyPanel -FilePath "mmsys.cpl" })
$SystemPropertiesBtn.Add_Click({ Invoke-OpenLegacyPanel -FilePath "sysdm.cpl" })
$TimeAndDateBtn.Add_Click({ Invoke-OpenLegacyPanel -FilePath "timedate.cpl" })

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