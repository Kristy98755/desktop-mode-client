# Desktop Mode Client — Android Virtual Display via ADB + scrcpy

> Turn your Android phone into a second monitor or desktop workspace. No root required.

A zero-install Windows console utility that detects your PC hardware, queries your Android device over ADB, and launches **scrcpy** with an optimized virtual display — in one double-click.

## What it does

1. **Reads PC hardware** — CPU, GPU, RAM, display resolution, disks (via WMI)
2. **Queries Android device** — model, SoC, screen, battery, temperature, Desktop Mode status
3. **Generates 4 virtual display profiles** — scored by resolution, load, smoothness, quality
4. **Auto-enables Desktop Mode** if the device supports it (`enable_freeform_support`)
5. **Launches scrcpy** with the chosen profile — new virtual display, no mirror of existing screen

## Requirements

| Tool | Why |
|------|-----|
| [scrcpy](https://github.com/Genymobile/scrcpy) ≥ 2.0 | Virtual display, video encoding, input forwarding |
| [ADB](https://developer.android.com/tools/releases/platform-tools) (Android Debug Bridge) | Device communication |
| Windows 10+ | Console ANSI colors, PowerShell 5.1 |
| USB debugging enabled on Android | ADB access |

Both `scrcpy` and `adb` must be in `PATH` or `C:\Windows`.

## Quick start

```
git clone https://github.com/YOUR/desktop-mode-client.git
cd desktop-mode-client
AndroidDesktopWizard.bat
```

Or just download → extract → double-click `AndroidDesktopWizard.bat`.

## How it works

### Profile scoring

Each profile is scored on 4 axes (0–100):

| Factor | Weight | Description |
|--------|--------|-------------|
| Smooth | 4× | Predicted frame stability (higher res = lower) |
| Quality | 3× | Pixel density sharpness |
| Load | 2× | Inverse of GPU memory pressure |
| Headroom | 1× | Available RAM and CPU budget |

The profile with the highest total score is recommended.

### Auto-enable Desktop Mode

If `enable_freeform_support` or `force_desktop_mode_on_external_displays` is off, the wizard enables them automatically:

```
settings put global enable_freeform_support 1
settings put global force_desktop_mode_on_external_displays 1
settings put global force_allow_on_external 1
```

This requires the device to support freeform windows (Android 10+).

### Virtual display creation

scrcpy creates a new virtual display inside Android — separate from the physical screen:

```
scrcpy --new-display=1920x1080/240 --video-codec=h264 --max-fps=60 --video-bit-rate=8M
```

This is **not** screen mirroring. It's a second desktop you can interact with via scrcpy window on your PC.

## File structure

```
desktop-mode-client/
├── AndroidDesktopWizard.bat   # Main entry point — double-click to run
└── modules/
    ├── banner.txt              # UTF-8 box-drawing logo
    ├── pc_info.ps1             # WMI hardware detection (CPU, GPU, RAM, disks, monitors)
    └── table.ps1               # Auto-aligned CLI table renderer
```

## Tested on

| Device | SoC | Android | scrcpy | Status |
|--------|-----|---------|--------|--------|
| POCO M2102J20SG | Snapdragon 855 | 15 (LineageOS) | 4.0 | ✓ Full support |

### Known limitations

- **No SoC-based codec detection** — codec is always `h264` (scrcpy negotiates hardware encoding internally)
- **Single device** — if multiple devices are connected, unplug extras or use `adb -s SERIAL`
- **No Linux/macOS support** — uses Windows-specific WMI and console features
- **No root required** — Desktop Mode flags are standard ADB settings (may require developer options)

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "adb" not recognized | Add Android SDK platform-tools to PATH |
| "scrcpy" not recognized | Add scrcpy folder to PATH or copy to C:\Windows |
| Device not found | Enable USB debugging + accept RSA key on phone |
| Desktop Mode won't enable | Device may not support freeform windows; check developer options |
| Black scrcpy window | Update GPU drivers; try `--render-driver=opengl` |

## Contributing

Open issues or PRs. The project is plain-text BAT + PowerShell — edit and run instantly, no build step.

## License

MIT
