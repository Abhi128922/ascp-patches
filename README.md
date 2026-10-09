# ASCP Aston (OnePlus 12R / Ace 3) Complete Source & Build Guide

Comprehensive collection of source-side patches, device setup instructions, and architecture documentation for **OnePlus 12R / Ace 3 (`aston` / `astonc`)** on **ASCP 17 (Android 15 / seventeen)**.

---

## Table of Contents
1. [Overview & Architecture](#overview--architecture)
2. [Building from Bare ASCP Source (Step-by-Step)](#building-from-bare-ascp-source-step-by-step)
3. [Repositories & Local Manifest](#repositories--local-manifest)
4. [Vendor Tree Architecture (AlphaDroid 16.2 Base -> A17 Adapted)](#vendor-tree-architecture)
5. [Source Patch Inventory (31 Patches)](#source-patch-inventory-31-patches)
   - [1. OOS Camera Port Core](#1-oos-camera-port-core)
   - [2. Auto-Brightness & HDR Video](#2-auto-brightness--hdr-video)
   - [3. LTPO Dynamic Refresh Rate](#3-ltpo-dynamic-refresh-rate)
   - [4. Under-Display Fingerprint (UDFPS)](#4-under-display-fingerprint-udfps)
   - [5. Device Extras & Build Conflict Fixes](#5-device-extras--build-conflict-fixes)
6. [Patch Applicator Script (`apply_patches.sh`)](#patch-applicator-script-apply_patchessh)

---

## Overview & Architecture

This tree builds a production-grade, daily-driver ASCP 17 ROM for the OnePlus 12R (`aston` / `astonc`) with full hardware feature parity:
- **Full OOS Camera Support**: Master mode, RAW capture, video HDR, 4K/60, and dual-sensor camera extensions.
- **Optical Fingerprint (UDFPS)**: Hardware HBM illumination, custom touch layer detection, and SurfaceFlinger connector mask.
- **LTPO Dynamic Refresh Rate (1Hz–120Hz)**: OnePlus ADFR kernel driver control and OplusParts UI toggle.
- **Pixelworks Iris 7**: Hardware color calibration wired through QTI Composer with SoC-namespaced Soong variables.
- **Content-Immune Auto-Brightness**: Fusion Light Engine sensor routing + dark/colorful transition sample dropping.
- **Clean AOSP Typography**: Native Android 15 Typeface stack ensuring zero crashes and instant boot.

---

## Building from Bare ASCP Source (Step-by-Step)

Follow these steps to replicate this exact build on a clean/bare machine:

### 1. Initialize and Sync ASCP Source
```bash
mkdir -p ~/ascp && cd ~/ascp
repo init -u https://github.com/Pixelify-AOSP/manifest -b 17 --git-lfs
repo sync -c --no-clone-bundle --optimized-fetch --prune --force-sync -j$(nproc --all)
```

### 2. Setup Local Manifest & Sync Trees
Copy the unified local manifest into `.repo/local_manifests/aston.xml`:

```bash
mkdir -p .repo/local_manifests
cp ~/ascp-patches/local_manifests/aston.xml .repo/local_manifests/
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
```

This automatically pulls all device trees, kernel modules/devicetrees, HALs, and vendor blobs cleanly.

### 3. Apply ASCP Patches
Run the patch applicator:

```bash
bash ~/ascp-patches/apply_patches.sh ~/ascp
```

The script will verify and apply all 31 patches cleanly with 0 failures (or automatically skip if already present).

### 4. Build the ROM
```bash
cd ~/ascp
source build/envsetup.sh
lunch aston-userdebug
m bacon -j$(nproc --all)   # or m ascp
```

---

## Repositories & Local Manifest

The following trees are tracked and maintained in `.repo/local_manifests/aston.xml`:

| Repository | Remote | Path | Branch | Description |
|------------|--------|------|--------|-------------|
| `Abhi128922/android_device_oneplus_aston` | GitHub | `device/oneplus/aston` | `ascp-17` | Device tree for Aston (OnePlus 12R / Ace 3) |
| `Abhi128922/android_device_oneplus_sm8550-common` | GitHub | `device/oneplus/sm8550-common` | `ascp-17` | Common SoC device tree for SM8550 |
| `Abhi128922/hardware_oplus` | GitHub | `hardware/oplus` | `ascp-17` | OPlus interfaces, camera extension, and fwk shims |
| `LineageOS/android_hardware_pixelworks_interfaces` | GitHub | `hardware/pixelworks/interfaces` | `lineage-24.0` | Pixelworks Iris 7 AIDL / HIDL interfaces |
| `Abhi128922/hardware_dolby` | GitHub | `hardware/dolby` | `ascp-17` | Dolby Atmos hardware integration |
| `Abhi128922/android_kernel_oneplus_sm8550` | GitHub | `kernel/oneplus/sm8550` | `ascp-17` | OnePlus SM8550 kernel source |
| `Abhi128922/android_kernel_oneplus_sm8550-modules` | GitHub | `kernel/oneplus/sm8550-modules` | `ascp-17` | Prebuilt kernel modules |
| `Abhi128922/android_kernel_oneplus_sm8550-devicetrees` | GitHub | `kernel/oneplus/sm8550-devicetrees` | `ascp-17` | Device trees for SM8550 |
| `alphadroid-project/vendor_oneplus_aston` | GitLab | `vendor/oneplus/aston` | `alpha-16.2` | Proprietary Aston vendor blobs (A17 adapted) |
| `Abhi128922/android_vendor_oneplus_sm8550-common` | GitHub | `vendor/oneplus/sm8550-common` | `ascp-17` | Common SM8550 vendor blobs |
| `gauravpaul9/vendor_oplus_camera` | GitLab | `vendor/oplus/camera` | `alpha-16.2` | OxygenOS Camera app & system extension |
| `alphadroid-project/vendor_oneplus_fusion` | GitLab | `vendor/oneplus/fusion` | `alpha-16.2` | OPlus Fusion Light Sensor engine & CWB service |
| `alphadroid-project/vendor_oneplus_dolby` | GitLab | `vendor/oneplus/dolby` | `alpha-16.2` | Dolby Atmos vendor audio blobs |
| `crdroidandroid/proprietary_vendor_oneplus_ir` | GitLab | `vendor/oneplus/ir` | `17.0` | Consumer IR HAL & blobs |

---

## Vendor Tree Architecture

`vendor/oneplus/aston` uses `alphadroid-project/vendor_oneplus_aston` (`alpha-16.2`) adapted for ASCP 17:

1. **AIDL Module Collision Prevention**:
   - `hardware/oplus/interfaces` compiles the following AIDL HAL libraries from source:
     * `vendor.oplus.hardware.cameraextension-V1-ndk`
     * `vendor.oplus.hardware.cammidasservice-V1-ndk_vendor`
     * `vendor.oplus.hardware.commondcs-V1-ndk_platform`
     * `vendor.oplus.hardware.camera_rfi-V1-ndk`
     * `vendor.oplus.hardware.cammidasservice-V1-ndk`
     * `vendor.oplus.hardware.sendextcamcmd-V2-ndk`
   - These 6 prebuilts are removed from `vendor/oneplus/aston/Android.bp` and `aston-vendor.mk` so Soong compiles and links against `hardware/oplus` cleanly.

2. **Real Binary Blobs (Turbo HDR & SenseTime SR)**:
   - `libarcsoft_turbo_hdr_raw.so`, `libarcsoft_turbo_hdr_raw_front.so`, and `libsdk_sr.so` are included as true 64-bit ELF shared objects.
   - `check_elf_files: false` is configured for `sr_models`, `sr_ref_models`, and `libsdk_sr_ref` to resolve DT_SONAME mismatches.
   - `libapsfixup` is wired into `libAlgoProcess`.

3. **Radio Firmware Verification**:
   - Radio images (`radio/*.img`) are tracked as real binary blobs and verified via `add-radio-file-sha1-checked` in `Android.mk`.

---

## Source Patch Inventory (31 Patches)

### 1. OOS Camera Port Core
- **`frameworks/av` (9 patches)**:
  - Add Oplus `CameraServiceExt` and `OPlusCameraProviderManager` extensions.
  - Relax monotonic timestamp guards for still capture (`ro.camera.relax_timestamp_guard`).
  - Google Lens back provider deadlock fix.
  - Oplus user data handling (`StagefrightRecorder`, `MetaDataBase.h`, and `oplu` atom in `MPEG4Writer`) for HDR video.
  - Non-Oplus orderly `detachDevice`, `hasFlashUnit` guard, empty `CAMERA_PACKAGE_NAME` safety check, and `CameraServiceExtFactory` load latch.
- **`frameworks/base` (2 patches)**:
  - Redirect proprietary OPlus file manager intents to DocumentsUI.
  - `ImageReader.getOplusHardwareBuffer()` no-cleaner buffer for Master / RAW photo capture.
- **`frameworks/native` (1 patch)**:
  - Bump Binder VM size 1MB → 4MB for high-resolution RAW camera payloads.
- **`build/soong` (1 patch)**:
  - Whitelist OPlus framework packages (`net.oneplus`, `oplus`, `com.color.inner`, `android.os.oplusdevicepolicy`) in `check_boot_jars`.
- **`vendor/custom` (1 patch)**:
  - Forward `TARGET_CAMERA_PACKAGE_NAME` to `camera:package_name`.
- **`device/qcom/sepolicy_vndr/sm8550` (1 patch)**:
  - Add `opluscamera_app` to DSP neverallow exceptions.

### 2. Auto-Brightness & HDR Video
- **`frameworks/native` (2 patches)**:
  - SurfaceFlinger: Flag fullscreen video layers in HDR layer info.
  - SensorService: Load OPLUS fusion light engine (`OplusFusionExt` gated on `persist.ascp.fusion_light`).
- **`frameworks/base` (3 patches)**:
  - Display: Fullscreen HDR brightness pin & SDR video floor.
  - Display: Drop fusion ALS hard-zero samples in auto-brightness.
  - `AutomaticBrightnessController`: import `android.os.SystemProperties`.

### 3. LTPO Dynamic Refresh Rate
- **`system/sepolicy` (1 patch)**:
  - Label `ro.surface_flinger.panel_refresh_rate_node` as `surfaceflinger_prop`.
- **`frameworks/native` (1 patch)**:
  - SurfaceFlinger: Use refresh rate values from Oplus ADFR.
- **`vendor/custom` (1 patch)**:
  - Define `surfaceflinger:supports_oplus_adfr` and `surfaceflinger:arr_use_oplus_ltpo_rates`.
- **`device/oneplus/aston` (2 patches)**:
  - Enable ADFR support and build OplusParts.
  - Enable SurfaceFlinger Oplus ADFR and LTPO rates.

### 4. Under-Display Fingerprint (UDFPS)
- **`frameworks/native` (1 patch)**:
  - `UdfpsExtension`: Correct `UDFPS_TOUCHED_LAYER_NAME` to match `SurfaceView` layer.

### 5. Device Extras & Build Conflict Fixes
- **`art` (1 patch)**:
  - Drop global `-O3` to ensure compilation stability.
- **`hardware/qcom-caf/bootctrl` (1 patch)**:
  - Remove duplicate boot-service binary declarations in favor of `hardware/oplus`.
- **`device/oneplus/aston` (1 patch)**:
  - Inherit BCR (Basic Call Recorder).
- **`device/oneplus/sm8550-common` (1 patch)**:
  - Inherit `hardware/oplus/oplus-fwk/oplus-fwk.mk`.

---

## Patch Applicator Script (`apply_patches.sh`)

To apply all patches idempotently to any ASCP tree:

```bash
bash ~/ascp-patches/apply_patches.sh ~/ascp
```

The script verifies file content presence heuristics before attempting `git apply`, allowing it to run safely multiple times without generating conflicts or failures.
