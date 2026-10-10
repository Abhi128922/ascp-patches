# OnePlus 12R / Ace 3 (Aston) — ASCP 17 Complete Build & Source Guide

This document explains everything configured and patched to achieve a fully functional, production-ready **ASCP 17 (Android 15)** build for the **OnePlus 12R / Ace 3 (`aston` / `astonc`)**, and how to replicate it cleanly from scratch on a fresh machine.

---

## 1. Quick Start: Building on Bare ASCP Source

### Step 1: Initialize and Sync ASCP
```bash
mkdir -p ~/ascp && cd ~/ascp
repo init -u https://github.com/Pixelify-AOSP/manifest -b 17 --git-lfs
repo sync -c --no-clone-bundle --optimized-fetch --prune --force-sync -j$(nproc --all)
```

### Step 2: Clone Local Manifest & Sync Trees
Copy the unified local manifest into `.repo/local_manifests`:

```bash
mkdir -p .repo/local_manifests
cp ~/ascp-patches/local_manifests/aston.xml .repo/local_manifests/
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
```

This automatically pulls all device trees, kernel modules/devicetrees, HALs, and vendor blobs cleanly on branch `ascp-17` and `alpha-16.2`.

### Step 3: Apply Patches
Clone the patch repository and run the applicator:

```bash
git clone https://github.com/Abhi128922/ascp-patches.git -b ascp-17 ~/ascp-patches
bash ~/ascp-patches/apply_patches.sh ~/ascp
```

All 26 patches will apply cleanly with 0 failures (or automatically skip if already present).

### Step 4: Run the Build
```bash
cd ~/ascp
source build/envsetup.sh
lunch aston-userdebug
m bacon -j$(nproc --all)   # or m ascp
```

---

## 2. Repositories Pushed Directly to GitHub / GitLab

All active device and HAL repositories have been standardized onto branch **`ascp-17`** (or **`alpha-16.2`**):

1. **`device/oneplus/aston`** (`branch: ascp-17`):
   - UDFPS Soong flag: `$(call soong_config_set_bool,qtidisplay,oplus_udfps,true)`
   - Pixelworks Iris 7: `sm8550_pxlw_vendor_namespace` and `sm8550_pxlw_hw_iris7`
   - LTPO / ADFR: `supports_oplus_adfr` and `arr_use_oplus_ltpo_rates`
   - OplusParts inheritance: `packages/apps/OplusParts/oplusparts.mk`
   - BCR (Basic Call Recorder) inheritance

2. **`device/oneplus/sm8550-common`** (`branch: ascp-17`):
   - SurfaceFlinger UDFPS lib: `TARGET_SURFACEFLINGER_UDFPS_LIB := //hardware/oplus:libudfps_extension.oplus`
   - Oplus framework inheritance: `oplus-fwk`

3. **`kernel/oneplus/sm8550`** (`branch: ascp-17`):
   - Power-efficient workqueues, writeback tuning, UFS clock scaling, disable I/O stats accounting, PM QoS non-negative frequency clamp, noatime.

4. **`hardware/oplus`** (`branch: ascp-17`):
   - Compiles source AIDL HAL libraries and shims: `cameraextension`, `cammidasservice`, `commondcs`, `camera_rfi`, `sendextcamcmd`.

5. **`vendor/oneplus/aston`** (`branch: ascp-17`, based on `alphadroid-project/vendor_oneplus_aston` `alpha-16.2`):
   - True 64-bit ELF shared objects for Turbo HDR and SenseTime SR zoom (`libarcsoft_turbo_hdr_raw.so`, `libsdk_sr.so`).
   - `check_elf_files: false` for `sr_models`, `sr_ref_models`, `libsdk_sr_ref`.
   - Prebuilt AIDL shims removed to avoid Soong collisions with `hardware/oplus`.
   - Verified non-LFS radio images aligned with `Android.mk` SHA1 checks.

---

## 3. Patch Applicator Verification

To check patch status at any time:
```bash
bash ~/ascp-patches/apply_patches.sh ~/ascp
```
Output confirms all 26 patches applied or safely skipped with zero failures.
