#!/bin/bash
# ==============================================================================
# YAAP Aston (OnePlus Ace 3 / 12R) Source Patches Applicator
# Applies OOS Camera, Auto-Brightness, HDR, and LTPO patches to YAAP 17 source
# Usage: From ROM source root:
#        bash /path/to/apply_patches.sh .
# ==============================================================================
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_DIR="$SCRIPT_DIR"
ROM_ROOT="${1:-.}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$PATCH_DIR/logs/apply_$TIMESTAMP.log"
RESULT_FILE="$PATCH_DIR/logs/results_$TIMESTAMP.txt"
mkdir -p "$PATCH_DIR/logs"

TOTAL=0; APPLIED=0; SKIPPED=0; FAILED=0

log() { echo -e "$1" | tee -a "$LOG_FILE"; }
result() { echo "$1" >> "$RESULT_FILE"; }

print_header() {
    log ""
    log "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    log "${BOLD}${BLUE}║   YAAP Aston (OnePlus 12R) Source Patches Applicator (A17)       ║${NC}"
    log "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    log ""
    log "  Source : $PATCH_DIR"
    log "  Target : $ROM_ROOT"
    log "  Date   : $(date)"
    log "  Log    : $LOG_FILE"
    log ""
}

# ── Check if patch content is already present in repo ────────────────
is_patch_already_applied() {
    local repo_path="$1"
    local patch_file="$2"
    cd "$repo_path" 2>/dev/null || return 1

    local subject=$(grep "^Subject:" "$patch_file" | head -1 | sed -E 's/^Subject: \[PATCH[^]]*\] //')
    if [ -n "$subject" ] && git log -n 50 --oneline 2>/dev/null | grep -Fq "$subject"; then
        cd - > /dev/null 2>/dev/null
        return 0
    fi

    # Dry-run test: if git apply --reverse --check passes, changes already exist
    if git apply --reverse --check "$patch_file" 2>/dev/null; then
        cd - > /dev/null 2>/dev/null
        return 0
    fi

    cd - > /dev/null 2>/dev/null
    return 1
}

# ── Apply patch cleanly ──────────────────────────────────────────────
apply_single_patch() {
    local repo_path="$1"
    local patch_file="$2"
    local description="$3"
    local patch_name=$(basename "$patch_file")

    if [ ! -d "$repo_path" ]; then
        log "  ${YELLOW}⏭  [Directory not found: $repo_path] - Skipping${NC}"
        return 3
    fi

    cd "$repo_path" 2>/dev/null || return 2

    # Check if already present
    if is_patch_already_applied "$repo_path" "$patch_file"; then
        log "  ${CYAN}⏭  [Already Present] $description${NC}"
        cd - > /dev/null 2>/dev/null
        return 0
    fi

    git am --abort 2>/dev/null || true

    # Attempt 1: git am
    if git am --keep-cr "$patch_file" 2>/dev/null; then
        log "  ${GREEN}✓  [Applied: git am] $description${NC}"
        cd - > /dev/null 2>/dev/null
        return 1
    fi
    git am --abort 2>/dev/null || true

    # Attempt 2: git apply --3way
    if git apply --3way "$patch_file" 2>/dev/null; then
        git add -A
        local subject=$(grep "^Subject:" "$patch_file" | head -1 | sed -E 's/^Subject: \[PATCH[^]]*\] //')
        local author=$(grep "^From:" "$patch_file" | head -1 | sed -E 's/^From: //')
        if [ -n "$author" ]; then
            git commit --author="$author" -m "${subject:-Applied $patch_name}" 2>/dev/null || true
        else
            git commit -m "${subject:-Applied $patch_name}" 2>/dev/null || true
        fi
        log "  ${GREEN}✓  [Applied: 3way] $description${NC}"
        cd - > /dev/null 2>/dev/null
        return 1
    fi

    # Attempt 3: git apply with fuzz
    if git apply -C1 "$patch_file" 2>/dev/null; then
        git add -A
        local subject=$(grep "^Subject:" "$patch_file" | head -1 | sed -E 's/^Subject: \[PATCH[^]]*\] //')
        git commit -m "${subject:-Applied $patch_name (fuzz)}" 2>/dev/null || true
        log "  ${GREEN}✓  [Applied: fuzz] $description${NC}"
        cd - > /dev/null 2>/dev/null
        return 1
    fi

    log "  ${RED}✗  [FAILED] $description ($patch_name)${NC}"
    cd - > /dev/null 2>/dev/null
    return 2
}

# ── PATCH QUEUE ──────────────────────────────────────────────────────
# Format: repo_rel_path|patch_dir|patch_file|category|description
declare -a PATCH_QUEUE=(
    # Category 1: OOS Camera Port Core
    "frameworks/av|frameworks_av|0001-av-add-OPlus-CameraService-extension-support.patch|OOS CAM|av: add OPlus CameraService extension support"
    "frameworks/av|frameworks_av|0002-camera-Relax-monotonic-timestamp-guard-for-still-cap.patch|OOS CAM|camera: Relax monotonic timestamp guard for still captures"
    "frameworks/av|frameworks_av|0003-camera-fix-Google-Lens-back-provider-deadlock-on-sha.patch|OOS CAM|camera: fix Google-Lens->back provider deadlock on shared rear sensor"
    "frameworks/av|frameworks_av|0004-Add-Oplus-user-data-member-to-StagefrightRecorder.patch|OOS CAM|Add Oplus user data member to StagefrightRecorder"
    "frameworks/av|frameworks_av|0005-Implement-Oplus-user-data-handling-for-HDR.patch|OOS CAM|Implement Oplus user data handling for HDR"
    "frameworks/av|frameworks_av|0006-Add-kKeyOplusUserData-to-MetaDataBase.h.patch|OOS CAM|Add kKeyOplusUserData to MetaDataBase.h"
    "frameworks/av|frameworks_av|0007-HDR-FIX.-Enhance-MPEG4Writer-to-handle-Oplus-user-da.patch|OOS CAM|HDR FIX: MPEG4Writer Oplus user data handling ('oplu' atom)"
    "frameworks/av|frameworks_av|0008-libcameraservice-bypass-timestamp-monotonic-guard-fo.patch|OOS CAM|libcameraservice: bypass timestamp monotonic guard for custom intent"
    "frameworks/av|frameworks_av|0009-libcameraservice-gate-timestamp-guard-bypass-behind-.patch|OOS CAM|libcameraservice: gate timestamp guard bypass behind ro.camera.relax_timestamp_guard"
    "frameworks/av|frameworks_av|0010-libcameraservice-Add-camera-extension-infrastructure.patch|OOS CAM|libcameraservice: Add camera extension infrastructure and OEM prerequisites"
    "frameworks/av|frameworks_av|0011-libcameraservice-Resolve-CAMERA_PACKAGE_NAME-conflic.patch|OOS CAM|libcameraservice: Resolve CAMERA_PACKAGE_NAME conflict via Soong config"
    "frameworks/base|frameworks_base|0001-wm-ActivityStarter-Redirect-proprietary-OPlus-file-m.patch|OOS CAM|wm: ActivityStarter: Redirect proprietary OPlus file manager to DocumentsUI"
    "frameworks/base|frameworks_base|0002-base-ImageReader.getOplusHardwareBuffer-OnePlus-came.patch|OOS CAM|base: ImageReader.getOplusHardwareBuffer() — no-cleaner buffer"
    "frameworks/native|frameworks_native|0001-native-bump-BINDER_VM_SIZE-1MB-4MB-for-OPlus-camera-.patch|OOS CAM|native: bump BINDER_VM_SIZE 1MB->4MB for RAW/Master capture"
    "build/soong|build_soong|0001-check_boot_jars-Whitelist-more-OPlus-framework-packa.patch|OOS CAM|check_boot_jars: Whitelist more OPlus framework packages"
    "vendor/yaap|vendor_yaap|0001-BoardConfigSoong-Forward-TARGET_CAMERA_PACKAGE_NAME-.patch|OOS CAM|BoardConfigSoong: Forward TARGET_CAMERA_PACKAGE_NAME to camera:package_name"
    "device/qcom/sepolicy_vndr/sm8550|device_qcom_sepolicy_vndr|0001-sm8550-Add-opluscamera_app-to-DSP-neverallow-excepti.patch|OOS CAM|sm8550: Add opluscamera_app to DSP neverallow exceptions"

    # Category 2: Auto-Brightness & HDR
    "frameworks/native|frameworks_native|0002-surfaceflinger-Flag-fullscreen-video-layers-in-HDR-l.patch|HDR|surfaceflinger: Flag fullscreen video layers in HDR layer info"
    "frameworks/native|frameworks_native|0003-sensorservice-Load-the-OPLUS-fusion-light-engine-con.patch|AUTO BRIGHTNESS|sensorservice: Load the OPLUS fusion light engine (content-immune ALS)"
    "frameworks/base|frameworks_base|0003-display-Fullscreen-HDR-brightness-pin-SDR-video-floo.patch|HDR & BRIGHTNESS|display: Fullscreen HDR brightness pin & SDR video floor"
    "frameworks/base|frameworks_base|0004-display-Drop-fusion-ALS-hard-zero-samples-in-auto-br.patch|AUTO BRIGHTNESS|display: Drop fusion ALS hard-zero samples in auto-brightness"

    # Category 3: LTPO & Device Features (Applied if repos exist)
    "kernel/oneplus/sm8550-modules|kernel_modules|0001-display-driver-oplus_adfr-Allow-force-enabling-of-AD.patch|LTPO|display-driver: oplus_adfr: Allow force enabling of ADFR (/sys/kernel/oplus_display/ltpo_enable)"
    "device/oneplus/aston|device_oneplus_aston|0001-aston-Track-and-build-OplusParts.patch|LTPO & PARTS|aston: Track and build OplusParts, enable ADFR support"
    "device/oneplus/aston|device_oneplus_aston|0002-aston-inherit-BCR.patch|DEVICE EXTRAS|aston: inherit BCR (Basic Call Recorder)"
    "device/oneplus/sm8550-common|device_oneplus_sm8550_common|0001-sm8550-common-inherit-oplus-fwk.patch|DEVICE EXTRAS|sm8550-common: inherit oplus-fwk"
    "vendor/yaap|vendor_yaap|0002-yaap-fix-dtb-naming-hash-and-cleanup-signing-keys-BU.patch|BUILD FIX|yaap: fix dtb naming hash and cleanup signing keys BUILD"

    # Category 4: System-Wide Fonts
    "frameworks/base|frameworks_base|0005-graphics-FontController-Implement-system-wide-font-c.patch|SYSTEM FONTS|graphics/FontController: Implement system-wide font coverage"
)

# ── MAIN EXECUTION ───────────────────────────────────────────────────
print_header

TOTAL=${#PATCH_QUEUE[@]}
current_category=""

for entry in "${PATCH_QUEUE[@]}"; do
    IFS='|' read -r repo_path patch_dir patch_file category description <<< "$entry"

    if [ "$category" != "$current_category" ]; then
        current_category="$category"
        log ""
        log "${BOLD}${YELLOW}━━━ $current_category ━━━${NC}"
    fi

    full_repo="$ROM_ROOT/$repo_path"
    full_patch="$PATCH_DIR/$patch_dir/$patch_file"

    apply_single_patch "$full_repo" "$full_patch" "$description"
    rc=$?

    if [ $rc -eq 1 ]; then
        ((APPLIED++))
    elif [ $rc -eq 0 ]; then
        ((SKIPPED++))
    else
        ((FAILED++))
    fi
done

log ""
log "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
log "${BOLD}${BLUE}║                     SUMMARY REPORT                               ║${NC}"
log "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
log "  Total Patches : $TOTAL"
log "  Applied       : ${GREEN}$APPLIED${NC}"
log "  Skipped       : ${CYAN}$SKIPPED${NC}"
log "  Failed        : ${RED}$FAILED${NC}"
log "  Log File      : $LOG_FILE"
log ""

if [ $FAILED -gt 0 ]; then
    log "${RED}Some patches failed to apply. Please check the log above.${NC}"
    exit 1
else
    log "${GREEN}All applicable patches processed successfully!${NC}"
    exit 0
fi
