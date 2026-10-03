# OnePlus 12R / Ace 3 (Aston) — YAAP 17 Complete Build & Source Guide

This document explains everything configured and patched to achieve a fully functional, production-ready **YAAP 17 (Android 15)** build for the **OnePlus 12R / Ace 3 (`aston` / `astonc`)**, and how to replicate it from scratch on a fresh machine.

---

## 1. Quick Start: Building on Bare YAAP Source

### Step 1: Initialize and Sync YAAP
```bash
mkdir -p ~/yaap && cd ~/yaap
repo init -u https://github.com/yaap/manifest.git -b seventeen --git-lfs
repo sync -c --no-clone-bundle --optimized-fetch --prune --force-sync -j$(nproc --all)
```

### Step 2: Clone Local Manifest & Sync Trees
Instead of running dozens of manual `git clone` and `rm -rf` commands, clone the unified local manifest repository directly into `.repo/local_manifests`:

```bash
git clone https://github.com/gaurav-paul9/yaap_aston_manifest.git .repo/local_manifests
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
```

This automatically pulls all device trees, kernel modules/devicetrees, HALs, and vendor blobs cleanly on branch `seventeen`.

### Step 3: Apply Lunaris Patches
Clone the patch repository and run the applicator:

```bash
git clone https://github.com/gaurav-paul9/lunaris-patches.git -b seventeen ~/lunaris-patches
bash ~/lunaris-patches/apply_patches.sh ~/yaap
```

All 33 patches will apply cleanly with 0 failures (or automatically skip if already present).

### Step 4: Run the Build
```bash
source build/envsetup.sh
lunch yaap_aston-userdebug
m yaap -j$(nproc --all)
```

---

## 2. Repositories Pushed Directly to GitHub

All active device and HAL repositories have been standardized onto branch **`seventeen`** and pushed to GitHub:

1. **`device/oneplus/aston`** (`branch: seventeen`):
   - UDFPS Soong flag: `$(call soong_config_set_bool,qtidisplay,oplus_udfps,true)`
   - Pixelworks Iris 7: `sm8550_pxlw_vendor_namespace` and `sm8550_pxlw_hw_iris7`
   - LTPO / ADFR: `supports_oplus_adfr` and `arr_use_oplus_ltpo_rates`
   - OplusParts inheritance: `packages/apps/OplusParts/oplusparts.mk`
   - BCR (Basic Call Recorder) inheritance

2. **`device/oneplus/sm8550-common`** (`branch: seventeen`):
   - SurfaceFlinger UDFPS lib: `TARGET_SURFACEFLINGER_UDFPS_LIB := //hardware/oplus:libudfps_extension.oplus`
   - Oplus framework inheritance: `oplus-fwk`

3. **`kernel/oneplus/sm8550`** (`branch: seventeen`):
   - Power-efficient workqueues, writeback tuning, UFS clock scaling, disable I/O stats accounting, PM QoS non-negative frequency clamp, noatime.
   - Clean of any experimental KernelSU hooks.

4. **`hardware/oplus`** (`branch: seventeen`):
   - Includes `c4ff9eb`: remove duplicate `vendor.oplus.hardware.cwb` interface collision.

5. **`hardware/qcom-caf/sm8550/display`** (`branch: seventeen`):
   - Optical UDFPS connector mask in SDM composer (`54cf453ac` and `6e8c92e9b`).
   - FOD pressed layer ZPOS bit marking (`81d492289` and `93763ceaf`).
   - Pixelworks Iris 7 hardware color calibration (`80dd52275` and `ab979401e`).
   - Prefixed Pixelworks Soong variables with `sm8550_` (`99a1779a1`) to prevent namespace collision with `sm8350`.

6. **`packages/apps/OplusParts`** (`branch: seventeen`):
   - Stripped Lineage SDK dependencies; streamlined for clean LTPO toggle.

7. **`lunaris-patches`** (`branch: seventeen`):
   - Complete patchset and automated `apply_patches.sh` applicator, plus `.repo/local_manifests/aston.xml`.

---

## 3. Lunaris Patches Applied to AOSP / YAAP Repositories

The 33 patches in `lunaris-patches/` cover all core OS modifications:

### A. OOS Camera Port (17 patches)
- **`frameworks/av` (11 patches)**:
  - Add Oplus `CameraServiceExt` and `OPlusCameraProviderManager` extensions.
  - Relax monotonic timestamp guards for still capture & custom capture intents (`ro.camera.relax_timestamp_guard`).
  - Google Lens back provider deadlock fix.
  - Preserve Oplus `'oplu'` user data metadata atom in `MPEG4Writer` for video HDR post-processing.
  - Fix `CAMERA_PACKAGE_NAME` conflict via Soong config.
- **`frameworks/base` (2 patches)**:
  - `0001`: Redirect proprietary OPlus file manager intents to DocumentsUI.
  - `0002`: `ImageReader.getOplusHardwareBuffer()` no-cleaner buffer for Master / RAW photo capture.
- **`frameworks/native` (1 patch)**:
  - `0001`: Bump Binder VM size 1MB → 4MB for high-resolution RAW camera payloads.
- **`build/soong` (1 patch)**:
  - `0001`: Whitelist OPlus framework packages in `check_boot_jars`.
- **`vendor/yaap` (1 patch)**:
  - `0001`: Forward `TARGET_CAMERA_PACKAGE_NAME` to `camera:package_name`.
- **`device/qcom/sepolicy_vndr/sm8550` (1 patch)**:
  - `0001`: Add `opluscamera_app` to DSP neverallow exceptions.

### B. Auto-Brightness & Fullscreen HDR (4 patches)
- **`frameworks/native` (2 patches)**:
  - `0002`: Flag fullscreen video layers in HDR layer info.
  - `0003`: Load OPLUS Fusion Light Engine in `sensorservice` for content-immune ALS.
- **`frameworks/base` (2 patches)**:
  - `0003`: Fullscreen HDR brightness pin & SDR video floor.
  - `0004`: Drop fusion ALS hard-zero samples (`≤0.5 lux` when ambient `≥2 lux`) to avoid darkening timer poisoning.

### C. LTPO Dynamic Refresh Rate (4 patches)
- **`kernel/oneplus/sm8550-modules` (1 patch)**:
  - `0001`: Allow force-enabling ADFR via `/sys/kernel/oplus_display/ltpo_enable`.
- **`frameworks/native` (1 patch)**:
  - `0004`: SurfaceFlinger: Use refresh rate values from Oplus ADFR.
- **`vendor/yaap` (1 patch)**:
  - `0003`: Add flags for SurfaceFlinger Oplus ADFR and LTPO rates.
- **`device/oneplus/aston` (1 patch)**:
  - `0003`: Enable SurfaceFlinger Oplus ADFR and LTPO rates.

### D. Under-Display Fingerprint (UDFPS) (1 patch)
- **`frameworks/native` (1 patch)**:
  - `0005`: In `UdfpsExtension.h`, align `UDFPS_TOUCHED_LAYER_NAME` to `"SurfaceView[UdfpsControllerOverlay]"`, matching Android 15 BLAST layer naming.

### E. Build Conflict & Device Fixes (5 patches)
- **`hardware/qcom-caf/bootctrl` (1 patch)**:
  - `0001`: Remove duplicate `android.hardware.boot-service.qti` binary definitions from `aidl/Android.bp` so `hardware/oplus/bootctrl` can supply the Oplus-specific binary without build collisions.
- **`device/oneplus/aston` (2 patches)**:
  - `0001`: Track and build OplusParts.
  - `0002`: Inherit BCR.
- **`device/oneplus/sm8550-common` (1 patch)**:
  - `0001`: Inherit `oplus-fwk`.
- **`vendor/yaap` (1 patch)**:
  - `0002`: Fix DTB naming hash and cleanup signing keys build.

### F. Unofficial OTA Infrastructure (2 patches)
- **`vendor/yaap` (1 patch)**:
  - `0004`: Adapt `generate_json_build_info` for custom index file and enable for homemade builds.
- **`packages/apps/OpenDelta` (1 patch)**:
  - `0001`: Adapt OpenDelta update client for unofficial OTA servers and JSON index.

---

## 4. Key Subsystem Details

### Why the Screen Flickered Earlier (and How It Was Fixed)
- The display blinking (~0.5s restart loop) and blank screen with only the gesture pill was caused by **font implementation recursion** (`StackOverflowError` in `Typeface.getNativeInstance()`), where `DEFAULT.updatePendingTypeface(DEFAULT)` formed a self-loop.
- The font changes have been completely dropped from the ROM source. `frameworks/base` is back to stock YAAP default (`747b3578b`), ensuring rock-solid UI stability.

### Optical UDFPS Architecture
- SDM composer tags the touched layer with the `kFnFodPressed` bit on ZPOS.
- SurfaceFlinger's `UdfpsExtension` matches layer `"SurfaceView[UdfpsControllerOverlay]"`.
- `BoardConfigCommon.mk` specifies `TARGET_SURFACEFLINGER_UDFPS_LIB := //hardware/oplus:libudfps_extension.oplus`, which communicates with the OnePlus optical sensor daemon to trigger panel HBM illumination during fingerprint authentication.

### Pixelworks Iris 7
- Aston includes a Pixelworks Iris 7 co-processor (`pxlw_i7p_panel_AA551_P_3_A0004_dsc_cmd.fw`).
- Wired via `sm8550_pxlw_vendor_namespace := vendor/oneplus/aston` and `sm8550_pxlw_hw_iris7 := true` in `device.mk`.
- Links `libpwirisfeature` and `libpwirishalwrapper` directly into QTI composer without colliding with `sm8350`.
