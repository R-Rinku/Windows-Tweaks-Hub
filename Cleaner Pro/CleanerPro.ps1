# ================= ADMIN CHECK =================
if (-not ([Security.Principal.WindowsPrincipal] `
[Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator")) {

    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName PresentationFramework

# ================= LOG =================
$logPath = "$env:TEMP\CleanerLog.txt"
function Log($msg) {
    $time = Get-Date -Format "HH:mm:ss"
    $line = "[$time] $msg"
    Add-Content $logPath $line
    $OutputBox.AppendText("$line`n")
    $OutputBox.ScrollToEnd()
}

# ================= UI =================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
Title="Cleaner Pro"
Height="720" Width="900"
Background="#0B1220"
WindowStartupLocation="CenterScreen">

<Grid Margin="15">

<Grid.RowDefinitions>
<RowDefinition Height="Auto"/>
<RowDefinition Height="*"/>
<RowDefinition Height="180"/>
</Grid.RowDefinitions>

<!-- HEADER -->
<TextBlock Text="Cleaner Pro"
FontSize="26"
FontWeight="Bold"
Foreground="White"
Margin="0,0,0,10"/>

<!-- MAIN CONTENT -->
<ScrollViewer Grid.Row="1">
<WrapPanel>

<!-- CLEANUP CARD -->
<Border Background="#111827" CornerRadius="12" Padding="15" Margin="10" Width="260">
<StackPanel>
<TextBlock Text="Cleanup" Foreground="#60A5FA" FontSize="18" Margin="0,0,0,10"/>

<CheckBox Name="TempCB" Content="User Temp"/>
<CheckBox Name="WinTempCB" Content="Windows Temp"/>
<CheckBox Name="RecycleCB" Content="Recycle Bin"/>
<CheckBox Name="UpdateCB" Content="Update Cache"/>
<CheckBox Name="DeliveryCB" Content="Delivery Cache"/>
<CheckBox Name="PrefetchCB" Content="Prefetch"/>
<CheckBox Name="ErrorCB" Content="Error Reports"/>
<CheckBox Name="ThumbCB" Content="Thumbnail Cache"/>
<CheckBox Name="BrowserCB" Content="Browser Cache"/>

</StackPanel>
</Border>

<!-- PERFORMANCE CARD -->
<Border Background="#111827" CornerRadius="12" Padding="15" Margin="10" Width="260">
<StackPanel>
<TextBlock Text="Performance" Foreground="#34D399" FontSize="18" Margin="0,0,0,10"/>

<CheckBox Name="AnimCB" Content="Disable Animations"/>
<CheckBox Name="TransCB" Content="Disable Transparency"/>
<CheckBox Name="StorageCB" Content="Run Storage Sense"/>

</StackPanel>
</Border>

<!-- USERS CARD -->
<Border Background="#111827" CornerRadius="12" Padding="15" Margin="10" Width="260">
<StackPanel>
<TextBlock Text="User Profiles" Foreground="#FBBF24" FontSize="18" Margin="0,0,0,10"/>

<ListBox Name="UserList" Height="180" SelectionMode="Extended"/>

</StackPanel>
</Border>

</WrapPanel>
</ScrollViewer>

<!-- LOG OUTPUT -->
<TextBox Name="OutputBox"
Grid.Row="2"
Background="#020617"
Foreground="#22C55E"
AcceptsReturn="True"
VerticalScrollBarVisibility="Auto"/>

<!-- BUTTON -->
<Button Name="RunBtn"
Content="RUN CLEANUP"
Height="45"
Width="260"
HorizontalAlignment="Right"
VerticalAlignment="Bottom"
Margin="0,0,10,10"
Background="#2563EB"
Foreground="White"
FontWeight="Bold"/>

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

$TempCB = $window.FindName("TempCB")
$WinTempCB = $window.FindName("WinTempCB")
$RecycleCB = $window.FindName("RecycleCB")
$UpdateCB = $window.FindName("UpdateCB")
$DeliveryCB = $window.FindName("DeliveryCB")
$PrefetchCB = $window.FindName("PrefetchCB")
$ErrorCB = $window.FindName("ErrorCB")
$ThumbCB = $window.FindName("ThumbCB")
$BrowserCB = $window.FindName("BrowserCB")

$AnimCB = $window.FindName("AnimCB")
$TransCB = $window.FindName("TransCB")
$StorageCB = $window.FindName("StorageCB")

# Load users safely
$currentUser = $env:USERNAME
Get-ChildItem "C:\Users" -Directory | Where-Object {
    $_.Name -notin @("Public","Default","Default User","All Users",$currentUser)
} | ForEach-Object {
    $UserList.Items.Add($_.Name)
}

# ================= RUN =================
$RunBtn.Add_Click({

    Log "=== START ==="

    if ($TempCB.IsChecked) {
        Log "Cleaning temp..."
        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    }

    if ($WinTempCB.IsChecked) {
        Log "Cleaning Windows temp..."
        Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    }

    if ($RecycleCB.IsChecked) {
        Log "Recycle bin..."
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    }

    if ($UpdateCB.IsChecked) {
        Log "Update cache..."
        Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Service wuauserv
    }

    if ($DeliveryCB.IsChecked) {
        Log "Delivery cache..."
        Remove-Item "C:\Windows\SoftwareDistribution\DeliveryOptimization\*" -Recurse -Force -ErrorAction SilentlyContinue
    }

    if ($PrefetchCB.IsChecked) {
        Log "Prefetch..."
        Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
    }

    if ($ErrorCB.IsChecked) {
        Log "Error reports..."
        Remove-Item "C:\ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue
    }

    if ($ThumbCB.IsChecked) {
        Log "Thumbnails..."
        Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*" -Force -ErrorAction SilentlyContinue
    }

    if ($BrowserCB.IsChecked) {
        Log "Browser cache..."
        Remove-Item "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue
    }

    if ($AnimCB.IsChecked) {
        Log "Animations OFF"
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
        -Name VisualFXSetting -Value 2
    }

    if ($TransCB.IsChecked) {
        Log "Transparency OFF"
        Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
        -Name EnableTransparency -Value 0
    }

    if ($StorageCB.IsChecked) {
        Log "Storage Sense..."
        Start-Process cleanmgr.exe -ArgumentList "/VERYLOWDISK"
    }

    foreach ($user in $UserList.SelectedItems) {
        Log "Deleting $user"
        Remove-Item "C:\Users\$user" -Recurse -Force -ErrorAction SilentlyContinue
    }

    Log "=== DONE ==="
})

$window.ShowDialog() | Out-Null