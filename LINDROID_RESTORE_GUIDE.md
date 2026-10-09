# Lindroid Convergence Support — Complete Restoration & Re-Integration Guide

This document preserves the exact, comprehensive steps and configuration required to re-enable **Lindroid** (LXC-based Linux desktop container environment with native DRM/KMS hardware acceleration) on the **OnePlus 12R / Ace 3 (`aston`)** running **ASCP 17 (Android 15)**.

All cloned repositories and patches are preserved on-disk in `/serverhive/gaurav/lindroid_staging/`.

---

## 1. Upstream Repositories

| Component | Upstream Git URL | Branch | Local Target Directory | Staged Backup Location |
|---|---|---|---|---|
| **vendor_lindroid** | `https://github.com/yaap/vendor_lindroid` | `seventeen` | `vendor/lindroid` | `/serverhive/gaurav/lindroid_staging/vendor_lindroid` |
| **external_lxc** | `https://github.com/yaap/external_lxc` | `seventeen` | `external/lxc` | `/serverhive/gaurav/lindroid_staging/external_lxc` |
| **libhybris** | `https://github.com/yaap/libhybris` | `seventeen` | `libhybris` | `/serverhive/gaurav/lindroid_staging/libhybris` |
| **lindroid-drm** | `https://github.com/Linux-on-droid/lindroid-drm-loopback` | `master` | `kernel/oneplus/sm8550/drivers/lindroid-drm` | `/serverhive/gaurav/lindroid_staging/lindroid-drm` |

To restore the directories from staging:
```bash
cp -r /serverhive/gaurav/lindroid_staging/vendor_lindroid ~/ascp/vendor/lindroid
cp -r /serverhive/gaurav/lindroid_staging/external_lxc ~/ascp/external/lxc
cp -r /serverhive/gaurav/lindroid_staging/libhybris ~/ascp/libhybris
cp -r /serverhive/gaurav/lindroid_staging/lindroid-drm ~/ascp/kernel/oneplus/sm8550/drivers/lindroid-drm
```

Or re-add to `.repo/local_manifests/aston.xml`:
```xml
  <!-- Lindroid (YAAP seventeen & Linux-on-droid) -->
  <project path="vendor/lindroid" name="yaap/vendor_lindroid" remote="github" revision="seventeen" clone-depth="1" />
  <project path="external/lxc" name="yaap/external_lxc" remote="github" revision="seventeen" clone-depth="1" />
  <project path="libhybris" name="yaap/libhybris" remote="github" revision="seventeen" clone-depth="1" />
  <project path="kernel/oneplus/sm8550/drivers/lindroid-drm" name="Linux-on-droid/lindroid-drm-loopback" remote="github" revision="master" clone-depth="1" />
```

---

## 2. Kernel Changes (`kernel/oneplus/sm8550`)

### A. Driver Wiring
1. In `drivers/Makefile`:
   ```makefile
   obj-y += lindroid-drm/
   ```
2. In `drivers/Kconfig`:
   ```kconfig
   source "drivers/lindroid-drm/Kconfig"
   ```

### B. Defconfig Settings (`arch/arm64/configs/vendor/oplus/kalama_GKI.config`)
Add container namespaces, cgroups, EVDI loopback display driver, and POSIX ACLs:
```config
# Lindroid / LXC container support
CONFIG_SYSVIPC=y
CONFIG_UTS_NS=y
CONFIG_PID_NS=y
CONFIG_IPC_NS=y
CONFIG_USER_NS=y
CONFIG_NET_NS=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CGROUP_FREEZER=y
CONFIG_DRM_LINDROID_EVDI=y
CONFIG_TMPFS_POSIX_ACL=y
```

### C. Casefolding Overlayfs Dentry Fix (`fs/overlayfs/util.c`)
Because Android `/data` enables casefolding (`f2fs`), overlayfs rejects mounts without this patch:
```c
bool ovl_dentry_weird(struct dentry *dentry)
{
	if (!d_can_lookup(dentry) && !d_is_file(dentry) && !d_is_symlink(dentry))
		return true;

	return dentry->d_flags & (DCACHE_NEED_AUTOMOUNT |
				  DCACHE_MANAGE_TRANSIT);
}
```

---

## 3. SELinux Policy (`system/sepolicy`)

Required to permit `perspectived` and Lindroid mutations without build-time neverallow violations:
1. **`public/attributes`**:
   ```te
   attribute init_dir_mutation_exempt;
   ```
2. **`private/domain.te`**:
   ```te
   neverallow {
     domain
     -init
     -vendor_init
     -init_dir_mutation_exempt
   } system_data_file:dir_file_class_set ...
   ```
3. **`Android.bp`**:
   Add `"perspectived"` to `permissive_domains_on_user_builds`.

---

## 4. Frameworks Native Soft-Reboot Workaround (`frameworks/native`)

When Lindroid virtual input devices register, `EventHub` must respect `device.disabled` in `.idc` files to prevent Android apps from crashing / soft-rebooting:
In `services/inputflinger/reader/EventHub.cpp`:
```cpp
// Disable device if device config property set
if (device->configuration &&
    device->configuration->getBool("device.disabled")) {
    device->disable();
    ALOGV("Disabling device with id %d\n", device->id);
}
```

---

## 5. Device Tree Integration (`device/oneplus/aston`)

In `device/oneplus/aston/device.mk`:
```makefile
# Lindroid
$(call inherit-product-if-exists, vendor/lindroid/lindroid.mk)

# VINTF — bypass kernel FCM check for Lindroid SYSVIPC requirement
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false
```
