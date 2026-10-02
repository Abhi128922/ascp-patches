# YAAP Aston (OnePlus Ace 3 / 12R) Source Patches

Comprehensive collection of source-side patches for **OnePlus Ace 3 / 12R (`aston` / `astonc`)** on **YAAP 17 (AOSP seventeen)**.

Organized by feature category for clean, modular application.

---

## Patch Inventory (26 patches total)

### 1. OOS Camera Port Core (17 patches)

| # | Target Repository | Patch File | Description |
|---|-------------------|------------|-------------|
| 1 | `frameworks/av` | `0001-av-add-OPlus-CameraService-extension-support.patch` | av: add OPlus CameraService extension support |
| 2 | `frameworks/av` | `0002-camera-Relax-monotonic-timestamp-guard-for-still-cap.patch` | camera: Relax monotonic timestamp guard for still captures |
| 3 | `frameworks/av` | `0003-camera-fix-Google-Lens-back-provider-deadlock-on-sha.patch` | camera: fix Google-Lens→back provider deadlock on shared rear sensor |
| 4 | `frameworks/av` | `0004-Add-Oplus-user-data-member-to-StagefrightRecorder.patch` | Add Oplus user data member to StagefrightRecorder |
| 5 | `frameworks/av` | `0005-Implement-Oplus-user-data-handling-for-HDR.patch` | Implement Oplus user data handling for HDR |
| 6 | `frameworks/av` | `0006-Add-kKeyOplusUserData-to-MetaDataBase.h.patch` | Add kKeyOplusUserData to MetaDataBase.h |
| 7 | `frameworks/av` | `0007-HDR-FIX.-Enhance-MPEG4Writer-to-handle-Oplus-user-da.patch` | HDR FIX: MPEG4Writer Oplus user data handling ('oplu' atom) |
| 8 | `frameworks/av` | `0008-libcameraservice-bypass-timestamp-monotonic-guard-fo.patch` | libcameraservice: bypass timestamp monotonic guard for custom intent |
| 9 | `frameworks/av` | `0009-libcameraservice-gate-timestamp-guard-bypass-behind-.patch` | libcameraservice: gate timestamp guard bypass behind ro.camera.relax_timestamp_guard |
| 10 | `frameworks/av` | `0010-libcameraservice-Add-camera-extension-infrastructure.patch` | libcameraservice: Add camera extension infrastructure and OEM prerequisites |
| 11 | `frameworks/av` | `0011-libcameraservice-Resolve-CAMERA_PACKAGE_NAME-conflic.patch` | libcameraservice: Resolve CAMERA_PACKAGE_NAME conflict via Soong config |
| 12 | `frameworks/base` | `0001-wm-ActivityStarter-Redirect-proprietary-OPlus-file-m.patch` | wm: ActivityStarter: Redirect proprietary OPlus file manager to DocumentsUI |
| 13 | `frameworks/base` | `0002-base-ImageReader.getOplusHardwareBuffer-OnePlus-came.patch` | base: ImageReader.getOplusHardwareBuffer() — no-cleaner buffer |
| 14 | `frameworks/native` | `0001-native-bump-BINDER_VM_SIZE-1MB-4MB-for-OPlus-camera-.patch` | native: bump BINDER_VM_SIZE 1MB→4MB for RAW/Master capture |
| 15 | `build/soong` | `0001-check_boot_jars-Whitelist-more-OPlus-framework-packa.patch` | check_boot_jars: Whitelist more OPlus framework packages |
| 16 | `vendor/yaap` | `0001-BoardConfigSoong-Forward-TARGET_CAMERA_PACKAGE_NAME-.patch` | BoardConfigSoong: Forward TARGET_CAMERA_PACKAGE_NAME to camera:package_name |
| 17 | `device/qcom/sepolicy_vndr/sm8550` | `0001-sm8550-Add-opluscamera_app-to-DSP-neverallow-excepti.patch` | sm8550: Add opluscamera_app to DSP neverallow exceptions |

### 2. Auto Brightness & HDR (4 patches)

| # | Target Repository | Patch File | Description |
|---|-------------------|------------|-------------|
| 18 | `frameworks/native` | `0002-surfaceflinger-Flag-fullscreen-video-layers-in-HDR-l.patch` | surfaceflinger: Flag fullscreen video layers in HDR layer info |
| 19 | `frameworks/native` | `0003-sensorservice-Load-the-OPLUS-fusion-light-engine-con.patch` | sensorservice: Load OPLUS fusion light engine (content-immune ALS) |
| 20 | `frameworks/base` | `0003-display-Fullscreen-HDR-brightness-pin-SDR-video-floo.patch` | display: Fullscreen HDR brightness pin & SDR video floor |
| 21 | `frameworks/base` | `0004-display-Drop-fusion-ALS-hard-zero-samples-in-auto-br.patch` | display: Drop fusion ALS hard-zero samples in auto-brightness |

### 3. LTPO (ADFR & Display Panel Control) (2 patches)

| # | Target Repository | Patch File | Description |
|---|-------------------|------------|-------------|
| 22 | `kernel/oneplus/sm8550-modules` | `0001-display-driver-oplus_adfr-Allow-force-enabling-of-AD.patch` | display-driver: oplus_adfr: Allow force enabling of ADFR (`/sys/kernel/oplus_display/ltpo_enable`) |
| 23 | `device/oneplus/aston` | `0001-aston-Track-and-build-OplusParts.patch` | aston: Track and build OplusParts, enable ADFR support in SurfaceFlinger |

> **Note on OplusParts App:**
> `device/oneplus/aston` inherits `packages/apps/OplusParts/oplusparts.mk`. Clone the repository into `packages/apps/OplusParts`:
> ```bash
> git clone --branch seventeen https://github.com/inferno0230/android_packages_apps_OplusParts packages/apps/OplusParts
> ```

### 4. Device Extras & Build Fixes (3 patches)

| # | Target Repository | Patch File | Description |
|---|-------------------|------------|-------------|
| 24 | `device/oneplus/aston` | `0002-aston-inherit-BCR.patch` | aston: inherit BCR (Basic Call Recorder) |
| 25 | `device/oneplus/sm8550-common` | `0001-sm8550-common-inherit-oplus-fwk.patch` | sm8550-common: inherit oplus-fwk |
| 26 | `vendor/yaap` | `0002-yaap-fix-dtb-naming-hash-and-cleanup-signing-keys-BU.patch` | yaap: fix dtb naming hash and cleanup signing keys BUILD |

---

## How to Apply

From your Android source root (`yaap/`):

```bash
bash /path/to/lunaris-patches/apply_patches.sh .
```

### Script Features
- **Idempotent**: Automatically checks whether a commit is already present and safely skips it.
- **Clean Application**: Uses `git am --keep-cr`, with automatic 3-way merge fallback.
- **Detailed Logging**: Logs every patch status to `logs/apply_<timestamp>.log`.
