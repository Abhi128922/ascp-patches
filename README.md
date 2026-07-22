# Lunaris OPlus Camera & Display Patches

Universal patches for OPlus camera port and display features on Lunaris AOSP.

## What This Does

Applies camera, display, and sensor patches from AlphaDroid to Lunaris source tree. These patches enable OPlus camera functionality, content-immune ALS, HDR brightness handling, and display features on OnePlus devices.

## Patches Included (20 total)

### frameworks/native (3 patches)
| File | Commit | Description |
|------|--------|-------------|
| 0001-surfaceflinger-RefreshRateOverlay... | surfaceflinger: RefreshRateOverlay: optional panel refresh rate source |
| 0002-surfaceflinger-Flag-fullscreen-video... | surfaceflinger: Flag fullscreen video layers in HDR layer info |
| 0003-sensorservice-Load-the-OPLUS-fusion... | sensorservice: Load the OPLUS fusion light engine (content-immune ALS) |

### frameworks/av (8 patches)
| File | Commit | Description |
|------|--------|-------------|
| 0001-camera-Relax-monotonic-timestamp... | Relax monotonic timestamp guard for still captures |
| 0002-camera-fix-Google-Lens-back-provi... | Fix Google-Lens→back provider deadlock on shared rear sensor |
| 0003-Add-Oplus-user-data-member-to-St... | Add Oplus user data member to StagefrightRecorder |
| 0004-Implement-Oplus-user-data-handli... | Implement Oplus user data handling for HDR |
| 0005-Add-kKeyOplusUserData-to-MetaDat... | Add kKeyOplusUserData to MetaDataBase.h |
| 0006-HDR-FIX.-Enhance-MPEG4Writer-to-... | Enhance MPEG4Writer to handle Oplus user data with custom 'oplu' metadata atom in MP4 |
| 0007-libcameraservice-bypass-timestamp... | Bypass timestamp monotonic guard for custom intent |
| 0008-libcameraservice-gate-timestamp-g... | Gate timestamp guard bypass behind ro.camera.relax_timestamp_guard |

### frameworks/base (5 patches)
| File | Commit | Description |
|------|--------|-------------|
| 0001-wm-ActivityStarter-Redirect-propr... | Redirect proprietary OPlus file manager intents to DocumentsUI |
| 0002-base-ImageReader.getOplusHardware... | ImageReader.getOplusHardwareBuffer() — OnePlus camera no-cleaner HardwareBuffer |
| 0003-Picture-Adjustment-don-t-crash... | Picture Adjustment: don't crash system server if getPictureAdjustmentRanges fails |
| 0004-display-Fullscreen-HDR-brightness... | Fullscreen HDR brightness pin (ignore freeform/PiP, no SS crash) |
| 0005-display-Brightness-floor-for-full... | Brightness floor for fullscreen SDR video |

### device/qcom/sepolicy_vndr/sm8550 (1 patch)
| File | Commit | Description |
|------|--------|-------------|
| 0001-sepolicy | Add opluscamera_app to DSP neverallow exceptions |

### art (1 patch)
| File | Commit | Description |
|------|--------|-------------|
| 0001-art | Drop non-AOSP global -O3 optimization |

### build/soong (1 patch)
| File | Commit | Description |
|------|--------|-------------|
| 0001-build-soong | Whitelist more OPlus framework packages (com.color.inner, android.os.oplusdevicepolicy) |

### system/sepolicy (1 patch)
| File | Commit | Description |
|------|--------|-------------|
| 0001-sepolicy | Label ro.surface_flinger.panel_refresh_rate_node as surfaceflinger_prop |

## Usage

### Standalone
```bash
cd ~/lunaris  # Android source root
bash /path/to/apply_patches.sh .
```

### With luna.sh (automated)
The build script automatically clones and applies these patches after device tree cloning.

## Features

- **Dependency-ordered** - Patches applied in correct sequence
- **Skip detection** - Automatically skips if already applied
- **Semantic matching** - Detects by content, not just commit hash
- **Detailed output** - Shows commit subject for each applied/skipped/failed patch
- **Graceful failures** - Reports which patches failed but continues build

## Output Example

```
━━━ APPLIED ━━━
  ✓ surfaceflinger: RefreshRateOverlay: optional panel refresh rate sour
  ✓ Relax monotonic timestamp guard for still captures
  ✓ Add Oplus user data member to StagefrightRecorder

━━━ SKIPPED (already present) ━━━
  ⏭ native: bump BINDER_VM_SIZE 1MB->4MB for OPlus camera
  ⏭ av: CameraService extension support

━━━ FAILED ━━━
  ✗ base: ImageReader.getOplusHardwareBuffer()
         all strategies failed
```

## Source

All patches originally from [AlphaDroid-Project](https://github.com/AlphaDroid-Project)

## License

Patches are from AlphaDroid (GPLv3). Use as needed for your ROM.
