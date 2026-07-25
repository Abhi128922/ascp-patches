# Lunaris OPlus Patches

OPlus camera, display, and sensor patches for Lunaris AOSP. Organized by category for clean application.

## Categories (19 patches total)

### OOS Camera — OPlus Camera Functionality (13 patches)

| # | Repo | Patch | Description |
|---|------|-------|-------------|
| 1 | frameworks/av | 0001-camera-Relax-monotonic-timestamp-guard-for-still-cap.patch | camera: Relax monotonic timestamp guard for still captures |
| 2 | frameworks/av | 0002-camera-fix-Google-Lens-back-provider-deadlock-on-sha.patch | camera: fix Google-Lens→back provider deadlock on shared rear sensor |
| 3 | frameworks/av | 0003-Add-Oplus-user-data-member-to-StagefrightRecorder.patch | Add Oplus user data member to StagefrightRecorder |
| 4 | frameworks/av | 0004-Implement-Oplus-user-data-handling-for-HDR.patch | Implement Oplus user data handling for HDR |
| 5 | frameworks/av | 0005-Add-kKeyOplusUserData-to-MetaDataBase.h.patch | Add kKeyOplusUserData to MetaDataBase.h |
| 6 | frameworks/av | 0006-HDR-FIX.-Enhance-MPEG4Writer-to-handle-Oplus-user-da.patch | HDR FIX: Enhance MPEG4Writer to handle Oplus user data |
| 7 | frameworks/av | 0007-libcameraservice-bypass-timestamp-monotonic-guard-fo.patch | libcameraservice: bypass timestamp monotonic guard for custom intent |
| 8 | frameworks/av | 0008-libcameraservice-gate-timestamp-guard-bypass-behind-.patch | libcameraservice: gate timestamp guard bypass behind ro.camera.relax_timestamp_guard |
| 9 | frameworks/base | 0001-wm-ActivityStarter-Redirect-proprietary-OPlus-file-m.patch | wm: Redirect proprietary OPlus file manager intents to DocumentsUI |
| 10 | frameworks/base | 0002-base-ImageReader.getOplusHardwareBuffer-OnePlus-came.patch | base: ImageReader.getOplusHardwareBuffer() — OnePlus camera HardwareBuffer |
| 11 | art | 0001-art.patch | art: drop non-AOSP global -O3 |
| 12 | build/soong | 0001-build-soong.patch | check_boot_jars: Whitelist more OPlus framework packages |
| 13 | device/qcom/sepolicy_vndr | 0001-sepolicy.patch | sm8550: Add opluscamera_app to DSP neverallow exceptions |

### LTPO — Display Refresh Rate / Panel Control (3 patches)

| # | Repo | Patch | Description |
|---|------|-------|-------------|
| 14 | frameworks/native | 0001-surfaceflinger-RefreshRateOverlay-optional-panel-ref.patch | surfaceflinger: RefreshRateOverlay: optional panel refresh rate source |
| 15 | frameworks/native | 0002-surfaceflinger-Flag-fullscreen-video-layers-in-HDR-l.patch | surfaceflinger: Flag fullscreen video layers in HDR layer info |
| 16 | system/sepolicy | 0001-sepolicy.patch | Label ro.surface_flinger.panel_refresh_rate_node as surfaceflinger_prop |

### Auto Brightness — Fusion Light Sensor / ALS (3 patches)

| # | Repo | Patch | Description |
|---|------|-------|-------------|
| 17 | frameworks/native | 0003-sensorservice-Load-the-OPLUS-fusion-light-engine-con.patch | sensorservice: Load the OPLUS fusion light engine (content-immune ALS) |
| 18 | frameworks/base | 0003-display-Fullscreen-HDR-brightness-pin-ignore-freefor.patch | display: Fullscreen HDR brightness pin (ignore freeform/PiP, no SS crash) |
| 19 | frameworks/base | 0004-display-Brightness-floor-for-fullscreen-SDR-video.patch | display: Brightness floor for fullscreen SDR video |

## Application Order

Patches are applied in category order (order of addition to repo):
1. **OOS Camera** — Camera functionality (13 patches)
2. **LTPO** — Display refresh rate and panel control (3 patches)
3. **Auto Brightness** — Fusion Light Sensor and brightness handling (3 patches)

## Usage

### Standalone
```bash
cd ~/lunaris  # Android source root
bash /path/to/apply_patches.sh .
```

### With luna.sh (automated)
The build script automatically applies these patches after device tree cloning.

## Features

- **Category-ordered** — LTPO → Auto Brightness → OOS Camera
- **Skip detection** — Automatically skips if already applied
- **Semantic matching** — Detects by content, not just commit hash
- **Detailed output** — Shows category, commit subject for each applied/skipped/failed patch
- **Graceful failures** — Reports which patches failed but continues build

## Output Example

```
━━━ LTPO (3 patches) ━━━
  ✓ surfaceflinger: RefreshRateOverlay: optional panel refresh rate source
  ✓ surfaceflinger: Flag fullscreen video layers in HDR layer info
  ✓ sepolicy: Label panel_refresh_rate_node property

━━━ AUTO BRIGHTNESS (3 patches) ━━━
  ✓ sensorservice: Load OPLUS fusion light engine
  ✓ display: Fullscreen HDR brightness pin
  ✓ display: Brightness floor for fullscreen SDR video

━━━ OOS CAMERA (13 patches) ━━━
  ✓ camera: Relax monotonic timestamp guard
  ✓ camera: fix Google-Lens→back provider deadlock
  ...

━━━ SKIPPED (already present) ━━━
  ⏭ [commit hash] [subject]
```

## Source

Patches originally from [AlphaDroid-Project](https://github.com/AlphaDroid-Project)

## License

Patches are from AlphaDroid (GPLv3). Use as needed for your ROM.
