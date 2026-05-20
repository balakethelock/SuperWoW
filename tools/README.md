# Primary display resolution helper

`SetPrimaryDisplayConfig.ps1` is a launcher-side workaround for machines where
the 1.12.1 client lists resolutions or refresh rates from the wrong monitor.

The script does not patch `SuperWoWhook.dll`, `SuperWoWlauncher.exe`, or
`WoW.exe`. It reads the current Windows primary display mode, then updates:

```text
WTF\Config.wtf
SET gxResolution "WIDTHxHEIGHT"
SET gxRefresh "HZ"
```

## Dry run

From the folder that contains `WoW.exe` and `SuperWoWlauncher.exe`:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\tools\SetPrimaryDisplayConfig.ps1 -Backup -DryRun
```

## Apply only

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\tools\SetPrimaryDisplayConfig.ps1 -Backup
```

## Apply and launch

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\tools\SetPrimaryDisplayConfig.ps1 -Backup -Launch
```

## Manual override

Use this if Windows reports the wrong display mode or the script is run from an
environment that cannot see the desktop session:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\tools\SetPrimaryDisplayConfig.ps1 -Resolution "3440x1440" -RefreshRate 120 -Backup -Launch
```

## Read-only lock

If the client keeps overwriting the values after opening video options, add
`-LockReadOnly`. This prevents the game from saving any other settings to
`Config.wtf` until the read-only attribute is removed.
