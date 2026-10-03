# YAAP Aston (OnePlus 12R / Ace 3) Complete Source & Build Guide

Comprehensive collection of source-side patches, device setup instructions, and architecture documentation for **OnePlus 12R / Ace 3 (`aston` / `astonc`)** on **YAAP 17 (Android 15 / AOSP seventeen)**.

---

## Table of Contents
1. [Overview & Architecture](#overview--architecture)
2. [Building from Bare YAAP Source (Step-by-Step)](#building-from-bare-yaap-source-step-by-step)
3. [Repositories Pushed to GitHub](#repositories-pushed-to-github)
4. [Source Patch Inventory (33 Patches)](#source-patch-inventory-33-patches)
   - [1. OOS Camera Port Core (17 patches)](#1-oos-camera-port-core-17-patches)
   - [2. Auto-Brightness & HDR Video (4 patches)](#2-auto-brightness--hdr-video-4-patches)
   - [3. LTPO Dynamic Refresh Rate (4 patches)](#3-ltpo-dynamic-refresh-rate-4-patches)
   - [4. Under-Display Fingerprint (UDFPS) (1 patch)](#4-under-display-fingerprint-udfps-1-patch)
   - [5. Device Extras & Build Conflict Fixes (5 patches)](#5-device-extras--build-conflict-fixes-5-patches)
   - [6. Unofficial OTA Infrastructure (2 patches)](#6-unofficial-ota-infrastructure-2-patches)
5. [Feature Implementation Details](#feature-implementation-details)
   - [Optical UDFPS & Dim Layer](#optical-udfps--dim-layer)
   - [Pixelworks Iris 7 Hardware Calibration](#pixelworks-iris-7-hardware-calibration)
   - [OOS Camera Port Integration](#oos-camera-port-integration)
   - [Content-Immune Auto-Brightness & HDR Pin](#content-immune-auto-brightness--hdr-pin)
   - [Boot Control HAL Deduplication](#boot-control-hal-deduplication)
   - [Font System Note](#font-system-note)
6. [Patch Applicator Script (`apply_patches.sh`)](#patch-applicator-script-apply_patchessh)

---

## Overview & Architecture

This tree builds a production-grade, daily-driver YAAP 17 ROM for the OnePlus 12R (`aston` / `astonc`) with full hardware feature parity:
- **Full OOS Camera Support**: Master mode, RAW capture, video HDR, 4K/60, and dual-sensor camera extensions.
- **Optical Fingerprint (UDFPS)**: Hardware HBM illumination, custom touch layer detection, and SurfaceFlinger connector mask.
- **LTPO Dynamic Refresh Rate (1Hz–120Hz)**: OnePlus ADFR kernel driver control and OplusParts UI toggle.
- **Pixelworks Iris 7**: Hardware color calibration wired through QTI Composer with SoC-namespaced Soong variables.
- **Content-Immune Auto-Brightness**: Fusion Light Engine sensor routing + dark/colorful transition sample dropping.
- **Clean AOSP Typography**: Native Android 15 Typeface stack ensuring zero crashes and instant boot.

---

## Building from Bare YAAP Source (Step-by-Step)

Follow these steps to replicate this exact build on a clean/bare machine:

### 1. Initialize and Sync YAAP Source
```bash
mkdir -p ~/yaap && cd ~/yaap
repo init -u https://github.com/yaap/manifest.git -b seventeen --git-lfs
repo sync -c --no-clone-bundle --optimized-fetch --prune --force-sync -j$(nproc --all)
```

### 2. Clone Device, Kernel, Display, and Parts Repositories
Clone the repositories managed directly on GitHub:

```bash
# Device trees
git clone https://github.com/gaurav-paul9/android_device_oneplus_aston_yaap.git -b cam device/oneplus/aston
git clone https://github.com/gaurav-paul9/android_device_oneplus_sm8550-common_yaap.git -b cam device/oneplus/sm8550-common

# Kernel source
git clone https://github.com/gaurav-paul9/android_kernel_oneplus_sm8550.git -b 17 kernel/oneplus/sm8550

# Display HAL (with UDFPS mask and Pixelworks Iris 7 support)
git clone https://github.com/gaurav-paul9/android_hardware_qcom_display.git -b seventeen hardware/qcom-caf/sm8550/display

# OplusParts (LTPO UI control)
git clone https://github.com/inferno0230/android_packages_apps_OplusParts.git -b seventeen packages/apps/OplusParts

# Proprietary vendor blobs
# Ensure vendor/oneplus/aston, vendor/oneplus/sm8550-common, and vendor/oplus/camera are present
```

### 3. Clone and Apply Lunaris Patches
```bash
git clone https://github.com/gaurav-paul9/lunaris-patches.git ~/lunaris-patches
bash ~/lunaris-patches/apply_patches.sh ~/yaap
```
The script will verify and apply all 33 patches cleanly.

### 4. Build the ROM
```bash
cd ~/yaap
source build/envsetup.sh
lunch yaap_aston-userdebug
m yaap -j$(nproc --all)
```

---

## Repositories Pushed to GitHub

The following repositories are tracked and maintained directly on GitHub, so their changes are preserved in their respective Git histories:

| Repository | Local Path | Branch | Description |
|------------|------------|--------|-------------|
| `android_device_oneplus_aston_yaap` | `device/oneplus/aston` | `cam` | Device tree for Aston (OnePlus 12R / Ace 3) |
| `android_device_oneplus_sm8550-common_yaap` | `device/oneplus/sm8550-common` | `cam` | Common SoC device tree for SM8550 OnePlus devices |
| `android_kernel_oneplus_sm8550` | `kernel/oneplus/sm8550` | `17` | Linux 6.1 OnePlus SM8550 kernel |
| `android_hardware_qcom_display` | `hardware/qcom-caf/sm8550/display` | `seventeen` | QTI Display HAL with optical UDFPS and Pixelworks Iris 7 |
| `android_packages_apps_OplusParts` | `packages/apps/OplusParts` | `seventeen` | Settings extension for LTPO dynamic refresh rate |

---

## Source Patch Inventory (33 Patches)

All patches below are organized in `lunaris-patches/` and applied automatically by `apply_patches.sh`.

### 1. OOS Camera Port Core (17 patches)

| # | Target Repository | Patch File | Description |
|---|-------------------|------------|-------------|
| 1 | `frameworks/av` | `frameworks_av/0001-av-add-OPlus-CameraService-extension-support.patch` | av: add OPlus CameraService extension support |
| 2 | `frameworks/av` | `frameworks_av/0002-camera-Relax-monotonic-timestamp-guard-for-still-cap.patch` | camera: Relax monotonic timestamp guard for still captures |
| 3 | `frameworks/av` | `frameworks_av/0003-camera-fix-Google-Lens-back-provider-deadlock-on-sha.patch` | camera: fix Google-Lens→back provider deadlock on shared rear sensor |
| 4 | `frameworks/av` | `frameworks_av/0004-Add-Oplus-user-data-member-to-StagefrightRecorder.patch` | Add Oplus user data member to StagefrightRecorder |
| 5 | `frameworks/av` | `frameworks_av/0005-Implement-Oplus-user-data-handling-for-HDR.patch` | Implement Oplus user data handling for HDR |
| 6 | `frameworks/av` | `frameworks_av/0006-Add-kKeyOplusUserData-to-MetaDataBase.h.patch` | Add kKeyOplusUserData to MetaDataBase.h |
| 7 | `frameworks/av` | `frameworks_av/0007-HDR-FIX.-Enhance-MPEG4Writer-to-handle-Oplus-user-da.patch` | HDR FIX: MPEG4Writer Oplus user data handling ('oplu' atom) |
| 8 | `frameworks/av` | `frameworks_av/0008-libcameraservice-bypass-timestamp-monotonic-guard-fo.patch` | libcameraservice: bypass timestamp monotonic guard for custom intent |
| 9 | `frameworks/av` | `frameworks_av/0009-libcameraservice-gate-timestamp-guard-bypass-behind-.patch` | libcameraservice: gate timestamp guard bypass behind ro.camera.relax_timestamp_guard |
| 10 | `frameworks/av` | `frameworks_av/0010-libcameraservice-Add-camera-extension-infrastructure.patch` | libcameraservice: Add camera extension infrastructure and OEM prerequisites |
| 11 | `frameworks/av` | `frameworks_av/0011-libcameraservice-Resolve-CAMERA_PACKAGE_NAME-conflic.patch` | libcameraservice: Resolve CAMERA_PACKAGE_NAME conflict via Soong config |
| 12 | `frameworks/base` | `frameworks_base/0001-wm-ActivityStarter-Redirect-proprietary-OPlus-file-m.patch` | wm: ActivityStarter: Redirect proprietary OPlus file manager to DocumentsUI |
| 13 | `frameworks/base` | `frameworks_base/0002-base-ImageReader.getOplusHardwareBuffer-OnePlus-came.patch` | base: ImageReader.getOplusHardwareBuffer() — no-cleaner buffer for Master mode |
| 14 | `frameworks/native` | `frameworks_native/0001-native-bump-BINDER_VM_SIZE-1MB-4MB-for-OPlus-camera-.patch` | native: bump BINDER_VM_SIZE 1MB→4MB for RAW/Master capture |
| 15 | `build/soong` | `build_soong/0001-check_boot_jars-Whitelist-more-OPlus-framework-packa.patch` | check_boot_jars: Whitelist more OPlus framework packages |
| 16 | `vendor/yaap` | `vendor_yaap/0001-BoardConfigSoong-Forward-TARGET_CAMERA_PACKAGE_NAME-.patch` | BoardConfigSoong: Forward TARGET_CAMERA_PACKAGE_NAME to camera:package_name |
| 17 | `device/qcom/sepolicy_vndr/sm8550` | `device_qcom_sepolicy_vndr/0001-sm8550-Add-opluscamera_app-to-DSP-neverallow-excepti.patch` | sm8550: Add opluscamera_app to DSP neverallow exceptions |

### 2. Auto-Brightness & HDR Video (4 patches)

| # | Target Repository | Patch File | Description |
|---|-------------------|------------|-------------|
| 18 | `frameworks/native` | `frameworks_native/0002-surfaceflinger-Flag-fullscreen-video-layers-in-HDR-l.patch` | surfaceflinger: Flag fullscreen video layers in HDR layer info |
| 19 | `frameworks/native` | `frameworks_native/0003-sensorservice-Load-the-OPLUS-fusion-light-engine-con.patch` | sensorservice: Load OPLUS fusion light engine (content-immune ALS) |
| 20 | `frameworks/base` | `frameworks_base/0003-display-Fullscreen-HDR-brightness-pin-SDR-video-floo.patch` | display: Fullscreen HDR brightness pin & SDR video floor |
| 21 | `frameworks/base` | `frameworks_base/0004-display-Drop-fusion-ALS-hard-zero-samples-in-auto-br.patch` | display: Drop fusion ALS hard-zero samples in auto-brightness |

### 3. LTPO Dynamic Refresh Rate (4 patches)

| # | Target Repository | Patch File | Description |
|---|-------------------|------------|-------------|
| 22 | `kernel/oneplus/sm8550-modules` | `kernel_modules/0001-display-driver-oplus_adfr-Allow-force-enabling-of-AD.patch` | display-driver: oplus_adfr: Allow force enabling of ADFR (`/sys/kernel/oplus_display/ltpo_enable`) |
| 23 | `frameworks/native` | `frameworks_native/0004-surfaceflinger-Use-Refresh-rate-values-from-Oplus-AD.patch` | surfaceflinger: Use Refresh rate values from Oplus ADFR |
| 24 | `vendor/yaap` | `vendor_yaap/0003-BoardConfigSoong-Add-flags-for-SurfaceFlinger-Oplus-.patch` | BoardConfigSoong: Add flags for SurfaceFlinger Oplus ADFR and LTPO rates |
| 25 | `device/oneplus/aston` | `device_oneplus_aston/0003-aston-Enable-SurfaceFlinger-Oplus-ADFR-and-LTPO-rate.patch` | aston: Enable SurfaceFlinger Oplus ADFR and LTPO rates |

### 4. Under-Display Fingerprint (UDFPS) (1 patch)

| # | Target Repository | Patch File | Description |
|---|-------------------|------------|-------------|
| 26 | `frameworks/native` | `frameworks_native/0005-surfaceflinger-UdfpsExtension-Correct-UDFPS_TOUCHED_.patch` | surfaceflinger: UdfpsExtension: Correct UDFPS_TOUCHED_LAYER_NAME to match SurfaceView layer |

### 5. Device Extras & Build Conflict Fixes (5 patches)

| # | Target Repository | Patch File | Description |
|---|-------------------|------------|-------------|
| 27 | `hardware/qcom-caf/bootctrl` | `hardware_qcom-caf_bootctrl/0001-bootctrl-Remove-duplicate-boot-service-binary-declar.patch` | bootctrl: Remove duplicate boot-service binary declarations in favor of hardware/oplus |
| 28 | `device/oneplus/aston` | `device_oneplus_aston/0001-aston-Track-and-build-OplusParts.patch` | aston: Track and build OplusParts, enable ADFR support |
| 29 | `device/oneplus/aston` | `device_oneplus_aston/0002-aston-inherit-BCR.patch` | aston: inherit BCR (Basic Call Recorder) |
| 30 | `device/oneplus/sm8550-common` | `device_oneplus_sm8550_common/0001-sm8550-common-inherit-oplus-fwk.patch` | sm8550-common: inherit oplus-fwk |
| 31 | `vendor/yaap` | `vendor_yaap/0002-yaap-fix-dtb-naming-hash-and-cleanup-signing-keys-BU.patch` | yaap: fix dtb naming hash and cleanup signing keys BUILD |

### 6. Unofficial OTA Infrastructure (2 patches)

| # | Target Repository | Patch File | Description |
|---|-------------------|------------|-------------|
| 32 | `vendor/yaap` | `vendor_yaap/0004-vendor-generate_json_build_info-Adapt-for-custom-ind.patch` | vendor: generate_json_build_info: Adapt for custom index and enable for homemade builds |
| 33 | `packages/apps/OpenDelta` | `packages_apps_OpenDelta/0001-OpenDelta-Adapt-for-unofficial-OTA-updates-and-custo.patch` | OpenDelta: Adapt for unofficial OTA updates and custom file index |

---

## Feature Implementation Details

### Optical UDFPS & Dim Layer
1. **Connector Mask in SDM**:
   - `hardware/qcom-caf/sm8550/display` commits `54cf453ac` and `6e8c92e9b` operate the optical fingerprint connector mask (`kFnOpticalFingerprintMask`) in SDM composer when `oplus_udfps` is active.
   - Enforces `kFnFodPressed` bit tagging on the UDFPS touched layer ZPOS to trigger optical high-brightness mode (HBM) on the panel.
2. **Layer Name Alignment in SurfaceFlinger**:
   - `frameworks/native`: `UdfpsExtension.h` aligns `UDFPS_TOUCHED_LAYER_NAME` to `"SurfaceView[UdfpsControllerOverlay]"`, matching Android 15's BLAST SurfaceView naming.
3. **Configuration**:
   - `device/oneplus/aston/device.mk`: `$(call soong_config_set_bool,qtidisplay,oplus_udfps,true)`
   - `device/oneplus/sm8550-common/BoardConfigCommon.mk`: `TARGET_SURFACEFLINGER_UDFPS_LIB := //hardware/oplus:libudfps_extension.oplus`

### Pixelworks Iris 7 Hardware Calibration
1. **Soong Namespace Isolation**:
   - SM8350 display HAL in YAAP defines `pxlw_vendor_namespace` without a SoC prefix. To prevent Soong namespace collisions during tree-wide parsing, SM8550 uses `sm8550_pxlw_vendor_namespace` and `sm8550_pxlw_hw_iris7` (matching LineageOS SM8650 convention).
2. **Library Linking**:
   - Links `libpwirisfeature` and `libpwirishalwrapper` from `vendor/oneplus/aston`.
3. **Configuration**:
   ```make
   $(call soong_config_set,qtidisplay,sm8550_pxlw_vendor_namespace,vendor/oneplus/aston)
   $(call soong_config_set_bool,qtidisplay,sm8550_pxlw_hw_iris7,true)
   ```

### OOS Camera Port Integration
1. **CameraService Extension**:
   - Injects `OPlusCameraProviderManager` and `CameraServiceExt` to handle proprietary OnePlus camera sessions.
2. **Timestamp Guard Relaxation**:
   - Relaxed monotonic timestamp validation in `libcameraservice` via `ro.camera.relax_timestamp_guard=1` to allow OOS Camera's custom capture pipelines.
3. **HDR MP4 Writer**:
   - `MPEG4Writer.cpp` enhanced to preserve the `'oplu'` metadata atom in MP4 containers required for OnePlus video HDR post-processing.
4. **HardwareBuffer Handling**:
   - `ImageReader.getOplusHardwareBuffer()` prevents premature buffer recycling during Master and RAW photo capture.
5. **Binder VM Expansion**:
   - Increased Binder VM size from 1MB to 4MB in `frameworks/native` to support massive multi-frame sensor payloads without TransactionTooLarge exceptions.

### Content-Immune Auto-Brightness & HDR Pin
1. **Fusion ALS**:
   - Routes ambient light sensing to the under-display OPLUS Fusion Light Sensor.
   - Drops `≤ 0.5 lux` hard-zero samples when ambient is `≥ 2 lux` to prevent darkening timer poisoning caused by content transitions.
2. **HDR Pinning**:
   - SurfaceFlinger flags fullscreen video layers to pin minimum display brightness floor during SDR/HDR playback.

### Boot Control HAL Deduplication
- `hardware/oplus/bootctrl` defines `android.hardware.boot-service.qti` linked against `libgptutils.oplus`.
- `hardware_qcom-caf_bootctrl/0001` removes the redundant non-Oplus binary from `hardware/qcom-caf/bootctrl/aidl/Android.bp`, preventing duplicate module definition errors.

### Font System Note
- Dynamic runtime repointing of Zygote placeholders in `Typeface.java` (`DEFAULT.updatePendingTypeface(DEFAULT)`) caused `StackOverflowError` infinite recursion in Android 15, resulting in SetupWizard and SystemUI crashloops.
- The font subsystem has been completely reverted to **native AOSP YAAP 17 default** (`747b3578b`), guaranteeing 100% stability across all apps, SetupWizard, and SystemUI.

---

## Patch Applicator Script (`apply_patches.sh`)

The script located at `lunaris-patches/apply_patches.sh` automatically applies all 33 patches:

### Usage:
```bash
bash /path/to/lunaris-patches/apply_patches.sh /path/to/yaap
```

### Features:
- **Idempotent**: Checks `git log` and `git apply --reverse --check` before applying; safely skips commits that are already present.
- **Robust Merging**: Attempts `git am --keep-cr`, falling back to `git apply --3way` and fuzz matching if needed.
- **Auditing**: Generates timestamped logs in `lunaris-patches/logs/apply_<timestamp>.log`.
