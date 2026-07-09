# Lunaris OPlus Camera Patches

Universal patches for OPlus camera port on Lunaris AOSP.

## Patches Included

| Repo | Patches |
|------|---------|
| frameworks/native | 2 |
| frameworks/av | 7 |
| frameworks/base | 2 |
| device/qcom/sepolicy_vndr/sm8550 | 1 |
| art | 1 |
| build/soong | 1 |
| system/sepolicy | 1 |

## Usage

```bash
# From Lunaris source root
bash /path/to/apply_patches.sh .
```

## Features

- Dependency-ordered application
- Skip if already applied
- Semantic content detection
- Auto-fix rejected hunks
