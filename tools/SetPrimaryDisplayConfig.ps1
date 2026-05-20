param(
    [string]$WowDir = (Get-Location).Path,
    [string]$ConfigPath = '',
    [string]$Resolution = '',
    [int]$RefreshRate = 0,
    [switch]$Backup,
    [switch]$LockReadOnly,
    [switch]$Launch,
    [string]$LauncherPath = '',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$nativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class DisplayNative
{
    public const int ENUM_CURRENT_SETTINGS = -1;
    public const int DISPLAY_DEVICE_ATTACHED_TO_DESKTOP = 0x00000001;
    public const int DISPLAY_DEVICE_PRIMARY_DEVICE = 0x00000004;

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct DISPLAY_DEVICE
    {
        public int cb;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string DeviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string DeviceString;
        public int StateFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string DeviceID;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string DeviceKey;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct DEVMODE
    {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public int dmDisplayOrientation;
        public int dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel;
        public int dmPelsWidth;
        public int dmPelsHeight;
        public int dmDisplayFlags;
        public int dmDisplayFrequency;
        public int dmICMMethod;
        public int dmICMIntent;
        public int dmMediaType;
        public int dmDitherType;
        public int dmReserved1;
        public int dmReserved2;
        public int dmPanningWidth;
        public int dmPanningHeight;
    }

    [DllImport("user32.dll", CharSet = CharSet.Ansi)]
    public static extern bool EnumDisplayDevices(string lpDevice, uint iDevNum, ref DISPLAY_DEVICE lpDisplayDevice, uint dwFlags);

    [DllImport("user32.dll", CharSet = CharSet.Ansi)]
    public static extern bool EnumDisplaySettings(string lpszDeviceName, int iModeNum, ref DEVMODE lpDevMode);
}
'@

if (-not ('DisplayNative' -as [type])) {
    Add-Type -TypeDefinition $nativeCode
}

function New-DisplayModeObject {
    param(
        [string]$DeviceName,
        [string]$DeviceString,
        [DisplayNative+DEVMODE]$Mode
    )

    return [pscustomobject]@{
        DeviceName = $DeviceName
        DeviceString = $DeviceString
        Width = [int]$Mode.dmPelsWidth
        Height = [int]$Mode.dmPelsHeight
        RefreshRate = [int]$Mode.dmDisplayFrequency
        BitsPerPel = [int]$Mode.dmBitsPerPel
    }
}

function Get-PrimaryDisplayMode {
    param([int]$FallbackRefreshRate)

    for ($i = 0; $i -lt 32; $i++) {
        $device = New-Object DisplayNative+DISPLAY_DEVICE
        $device.cb = [Runtime.InteropServices.Marshal]::SizeOf([type]'DisplayNative+DISPLAY_DEVICE')

        if (-not [DisplayNative]::EnumDisplayDevices($null, [uint32]$i, [ref]$device, 0)) {
            break
        }

        $isAttached = (($device.StateFlags -band [DisplayNative]::DISPLAY_DEVICE_ATTACHED_TO_DESKTOP) -ne 0)
        $isPrimary = (($device.StateFlags -band [DisplayNative]::DISPLAY_DEVICE_PRIMARY_DEVICE) -ne 0)
        if (-not ($isAttached -and $isPrimary)) {
            continue
        }

        $mode = New-Object DisplayNative+DEVMODE
        $mode.dmSize = [Runtime.InteropServices.Marshal]::SizeOf([type]'DisplayNative+DEVMODE')
        if (-not [DisplayNative]::EnumDisplaySettings($device.DeviceName, [DisplayNative]::ENUM_CURRENT_SETTINGS, [ref]$mode)) {
            throw "Could not read current settings for primary display $($device.DeviceName)."
        }

        return New-DisplayModeObject -DeviceName $device.DeviceName -DeviceString $device.DeviceString -Mode $mode
    }

    $defaultMode = New-Object DisplayNative+DEVMODE
    $defaultMode.dmSize = [Runtime.InteropServices.Marshal]::SizeOf([type]'DisplayNative+DEVMODE')
    if ([DisplayNative]::EnumDisplaySettings($null, [DisplayNative]::ENUM_CURRENT_SETTINGS, [ref]$defaultMode)) {
        return New-DisplayModeObject -DeviceName 'default' -DeviceString 'Windows default display' -Mode $defaultMode
    }

    if ($FallbackRefreshRate -gt 0) {
        try {
            Add-Type -AssemblyName System.Windows.Forms
            $screen = [System.Windows.Forms.Screen]::PrimaryScreen
            if ($screen) {
                return [pscustomobject]@{
                    DeviceName = 'winforms'
                    DeviceString = 'Windows primary screen fallback'
                    Width = [int]$screen.Bounds.Width
                    Height = [int]$screen.Bounds.Height
                    RefreshRate = [int]$FallbackRefreshRate
                    BitsPerPel = 0
                }
            }
        } catch {}
    }

    throw 'No primary attached display was found. Re-run with -Resolution and -RefreshRate.'
}

function Set-WowCVarLine {
    param(
        [string[]]$Lines,
        [string]$Name,
        [string]$Value
    )

    $pattern = "^\s*SET\s+$([regex]::Escape($Name))\s+"
    $replacement = "SET $Name `"$Value`""
    $updated = $false
    $result = foreach ($line in $Lines) {
        if ($line -match $pattern) {
            $updated = $true
            $replacement
        } else {
            $line
        }
    }

    if (-not $updated) {
        $result += $replacement
    }

    return @($result)
}

function Resolve-LauncherPath {
    param(
        [string]$Directory,
        [string]$ExplicitPath
    )

    if ($ExplicitPath) {
        return [System.IO.Path]::GetFullPath($ExplicitPath)
    }

    foreach ($name in @('SuperWoWlauncher.exe', 'WoW.exe')) {
        $candidate = Join-Path -Path $Directory -ChildPath $name
        if (Test-Path -LiteralPath $candidate) {
            return [System.IO.Path]::GetFullPath($candidate)
        }
    }

    throw "Could not find SuperWoWlauncher.exe or WoW.exe in $Directory. Pass -LauncherPath explicitly."
}

$wowDirFull = [System.IO.Path]::GetFullPath($WowDir)
$configPathWasProvided = [bool]$ConfigPath
if (-not $ConfigPath) {
    $ConfigPath = Join-Path -Path $wowDirFull -ChildPath 'WTF\Config.wtf'
}

$ConfigPath = [System.IO.Path]::GetFullPath($ConfigPath)
$configDir = Split-Path -Parent $ConfigPath

if (-not (Test-Path -LiteralPath $configDir)) {
    $wowExe = Join-Path -Path $wowDirFull -ChildPath 'WoW.exe'
    $superWowLauncher = Join-Path -Path $wowDirFull -ChildPath 'SuperWoWlauncher.exe'
    if (-not $configPathWasProvided -and ((Test-Path -LiteralPath $wowExe) -or (Test-Path -LiteralPath $superWowLauncher))) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    } else {
        throw "Config directory does not exist: $configDir. Pass -WowDir with the folder that contains WTF\Config.wtf."
    }
}

if ($Resolution) {
    if ($Resolution -notmatch '^\d{3,5}x\d{3,5}$') {
        throw "Invalid -Resolution value '$Resolution'. Expected format like 3440x1440."
    }
    if ($RefreshRate -le 0) {
        throw 'When -Resolution is provided, also provide -RefreshRate.'
    }
    $display = [pscustomobject]@{
        DeviceName = 'manual'
        DeviceString = 'manual override'
        Width = [int](($Resolution -split 'x')[0])
        Height = [int](($Resolution -split 'x')[1])
        RefreshRate = [int]$RefreshRate
        BitsPerPel = 0
    }
} else {
    $display = Get-PrimaryDisplayMode -FallbackRefreshRate $RefreshRate
    if ($RefreshRate -gt 0) {
        $display.RefreshRate = [int]$RefreshRate
    }
}

$resolutionValue = "$($display.Width)x$($display.Height)"
$refreshValue = "$($display.RefreshRate)"

Write-Host "Primary display: $($display.DeviceString) [$($display.DeviceName)]"
Write-Host "Mode: $resolutionValue @ ${refreshValue}Hz, $($display.BitsPerPel)bpp"
Write-Host "Config: $ConfigPath"

if (Test-Path -LiteralPath $ConfigPath) {
    $lines = @(Get-Content -LiteralPath $ConfigPath)
} else {
    $lines = @()
}

$lines = Set-WowCVarLine -Lines $lines -Name 'gxResolution' -Value $resolutionValue
$lines = Set-WowCVarLine -Lines $lines -Name 'gxRefresh' -Value $refreshValue

if ($DryRun) {
    Write-Host 'Dry run only. Proposed Config.wtf lines:'
    $lines | Where-Object { $_ -match '^\s*SET\s+gx(Resolution|Refresh)\s+' } | ForEach-Object { Write-Host "  $_" }
    exit 0
}

if ($Backup -and (Test-Path -LiteralPath $ConfigPath)) {
    $backupPath = "$ConfigPath.$(Get-Date -Format 'yyyyMMdd-HHmmss').bak"
    Copy-Item -LiteralPath $ConfigPath -Destination $backupPath
    Write-Host "Backup: $backupPath"
}

$wasReadOnly = $false
if (Test-Path -LiteralPath $ConfigPath) {
    $item = Get-Item -LiteralPath $ConfigPath
    $wasReadOnly = (($item.Attributes -band [System.IO.FileAttributes]::ReadOnly) -ne 0)
    if ($wasReadOnly) {
        $item.Attributes = ($item.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly))
    }
}

$lines | Set-Content -LiteralPath $ConfigPath -Encoding ASCII

if ($LockReadOnly -or $wasReadOnly) {
    $item = Get-Item -LiteralPath $ConfigPath
    $item.Attributes = ($item.Attributes -bor [System.IO.FileAttributes]::ReadOnly)
    Write-Host 'Config.wtf is now read-only.'
}

Write-Host 'Updated Config.wtf with primary-display gxResolution and gxRefresh.'

if ($Launch) {
    $resolvedLauncher = Resolve-LauncherPath -Directory $wowDirFull -ExplicitPath $LauncherPath
    Write-Host "Launching: $resolvedLauncher"
    Start-Process -FilePath $resolvedLauncher -WorkingDirectory (Split-Path -Parent $resolvedLauncher)
}
