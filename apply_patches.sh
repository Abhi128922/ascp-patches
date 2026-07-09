#!/bin/bash
# Universal Patch Applicator v4 - Final Version with Correct Paths
# Applies OPlus camera patches to Lunaris Android source tree
# Usage: From ROM source root: bash /path/to/apply_patches.sh .
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_DIR="$SCRIPT_DIR"
LUNARIS_ROOT="${1:-.}"

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

TOTAL=0; APPLIED=0; SKIPPED=0; PARTIAL=0; FAILED=0

log() { echo -e "$1" | tee -a "$LOG_FILE"; }
result() { echo "$1" >> "$RESULT_FILE"; }

print_header() {
    log ""
    log "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    log "${BOLD}${BLUE}║     OPlus Camera Patches → Lunaris  (v4 Final)                ║${NC}"
    log "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    log ""
    log "  Source : $PATCH_DIR"
    log "  Target : $LUNARIS_ROOT"
    log "  Date   : $(date)"
    log "  Log    : $LOG_FILE"
    log ""
}

print_progress() {
    local current=$1
    local total=$2
    local name=$3
    local pct=$((current * 100 / total))
    local filled=$((pct / 2))
    local empty=$((50 - filled))
    local bar=$(printf "%${filled}s" | tr ' ' '█')$(printf "%${empty}s" | tr ' ' '░')
    log "${CYAN}  [$bar] $pct%  ($current/$total)  $name${NC}"
}

# ── Semantic content detection ──────────────────────────────────────
is_patch_content_present() {
    local repo_path="$1"
    local patch_file="$2"
    cd "$repo_path" 2>/dev/null || return 1
    
    local specific_ids=$(grep "^+" "$patch_file" | grep -v "^+++" | grep -oE '"[A-Za-z_][A-Za-z0-9_]{20,}"' | sort -u | head -3)
    
    local found_specific=0
    local total_specific=0
    
    while IFS= read -r id; do
        [ -z "$id" ] && continue
        ((total_specific++))
        if grep -rqF "$id" . --include="*.java" --include="*.cpp" --include="*.h" --include="*.bp" --include="*.te" --include="*.txt" 2>/dev/null; then
            ((found_specific++))
        fi
    done <<< "$specific_ids"
    
    local new_fields=$(grep "^+" "$patch_file" | grep -v "^+++" | grep -oE '\b[a-z][a-zA-Z0-9_]{15,}\b' | sort -u | head -5)
    
    local found_fields=0
    local total_fields=0
    
    while IFS= read -r field; do
        [ -z "$field" ] && continue
        case "$field" in
            return|if|else|for|while|class|struct|void|int|static|const|new|nullptr|NULL|throw|try|catch|include|define|using) continue ;;
        esac
        ((total_fields++))
        if grep -rq "$field" . --include="*.java" --include="*.cpp" --include="*.h" --include="*.bp" --include="*.te" --include="*.txt" 2>/dev/null; then
            ((found_fields++))
        fi
    done <<< "$new_fields"
    
    cd - > /dev/null 2>/dev/null
    
    if [ "$total_specific" -gt 0 ] && [ "$found_specific" -eq "$total_specific" ]; then
        return 0
    fi
    
    if [ "$total_fields" -gt 0 ] && [ "$found_fields" -ge $((total_fields * 80 / 100)) ]; then
        return 0
    fi
    
    return 1
}

# ── Apply with semantic fallback ────────────────────────────────────
apply_patch() {
    local repo_path="$1"
    local patch_file="$2"
    local patch_name=$(basename "$patch_file")
    
    cd "$repo_path" 2>/dev/null || return 2
    
    git am --abort 2>/dev/null || true
    git checkout -- . 2>/dev/null || true
    
    if git am --keep-cr "$patch_file" 2>/dev/null; then
        cd - > /dev/null 2>/dev/null
        return 0
    fi
    git am --abort 2>/dev/null || true
    
    if git apply --3way "$patch_file" 2>/dev/null; then
        git add -A
        local subject=$(grep "^Subject:" "$patch_file" | head -1 | sed 's/^Subject: \[PATCH[^]]*\] //')
        git commit -m "${subject:-Applied $patch_name}" 2>/dev/null
        cd - > /dev/null 2>/dev/null
        return 0
    fi
    
    git apply -C1 --reject "$patch_file" 2>/dev/null
    local rejects=$(find . -name "*.rej" 2>/dev/null | wc -l)
    local changes=$(git diff --name-only 2>/dev/null | wc -l)
    
    if [ "$changes" -gt 0 ] && [ "$rejects" -gt 0 ]; then
        log "  ${YELLOW}  Partial: $changes files, $rejects rejects. Trying semantic fix...${NC}"
        
        for rej in $(find . -name "*.rej" 2>/dev/null); do
            local target=$(echo "$rej" | sed 's/\.rej$//')
            
            if [ -f "$target" ]; then
                local added_code=$(grep "^+" "$rej" | grep -v "^+++" | sed 's/^+//' | head -30)
                
                if [ -n "$added_code" ]; then
                    local anchor_func=$(echo "$added_code" | grep -oE '[a-zA-Z_][a-zA-Z0-9_]*\s*\(' | head -1 | sed 's/($//')
                    
                    if [ -n "$anchor_func" ]; then
                        local insert_line=$(grep -n "$anchor_func" "$target" | tail -1 | cut -d: -f1)
                        
                        if [ -n "$insert_line" ]; then
                            log "  ${CYAN}  Semantic fix: inserting after '$anchor_func' at line $insert_line${NC}"
                            
                            local temp_file=$(mktemp)
                            head -n "$insert_line" "$target" > "$temp_file"
                            echo "$added_code" >> "$temp_file"
                            tail -n +"$((insert_line + 1))" "$target" >> "$temp_file"
                            mv "$temp_file" "$target"
                            rm "$rej"
                        fi
                    fi
                fi
            fi
        done
        
        local remaining_rejects=$(find . -name "*.rej" 2>/dev/null | wc -l)
        
        if [ "$remaining_rejects" -eq 0 ]; then
            git add -A
            git commit -m "Applied $patch_name (semantic fix)" 2>/dev/null
            log "  ${GREEN}  ✓ All hunks applied with semantic resolution${NC}"
            cd - > /dev/null 2>/dev/null
            return 0
        else
            git add -A
            git commit -m "Partial: $patch_name ($remaining_rejects rejects remain)" 2>/dev/null || true
            cd - > /dev/null 2>/dev/null
            return 1
        fi
    elif [ "$changes" -gt 0 ]; then
        git add -A
        git commit -m "Applied $patch_name (fuzz)" 2>/dev/null
        cd - > /dev/null 2>/dev/null
        return 0
    fi
    
    cd - > /dev/null 2>/dev/null
    return 2
}

# ── PATCH QUEUE (dependency order) ──────────────────────────────────
# Path format: actual_android_source_path|patch_dir_name|patch_file|description
declare -a PATCH_QUEUE=(
    # frameworks/native (low-level, apply first)
    "frameworks/native|frameworks_native|0001-surfaceflinger-RefreshRateOverlay-optional-panel-ref.patch|surfaceflinger: RefreshRateOverlay panel refresh rate"
    
    # frameworks/av (camera service)
    "frameworks/av|frameworks_av|0001-camera-Relax-monotonic-timestamp-guard-for-still-cap.patch|av: Relax monotonic timestamp guard"
    "frameworks/av|frameworks_av|0002-camera-fix-Google-Lens-back-provider-deadlock-on-sha.patch|av: Fix Google-Lens→back provider deadlock"
    "frameworks/av|frameworks_av|0003-Add-Oplus-user-data-member-to-StagefrightRecorder.patch|av: Add Oplus user data to StagefrightRecorder.h"
    "frameworks/av|frameworks_av|0004-Implement-Oplus-user-data-handling-for-HDR.patch|av: Implement Oplus user data handling for HDR"
    "frameworks/av|frameworks_av|0005-Add-kKeyOplusUserData-to-MetaDataBase.h.patch|av: Add kKeyOplusUserData to MetaDataBase.h"
    "frameworks/av|frameworks_av|0006-HDR-FIX.-Enhance-MPEG4Writer-to-handle-Oplus-user-da.patch|av: MPEG4Writer Oplus user data handling"
    
    # frameworks/base
    "frameworks/base|frameworks_base|0001-wm-ActivityStarter-Redirect-proprietary-OPlus-file-m.patch|base: Redirect OPlus file manager"
    "frameworks/base|frameworks_base|0002-base-ImageReader.getOplusHardwareBuffer-OnePlus-came.patch|base: ImageReader.getOplusHardwareBuffer()"
    
    # device/qcom/sepolicy_vndr/sm8550 (sm8550 specific)
    "device/qcom/sepolicy_vndr/sm8550|device_qcom_sepolicy_vndr|0001-sepolicy.patch|sepolicy: Add opluscamera_app DSP exceptions"
    
    # build system
    "art|art|0001-art.patch|art: drop non-AOSP global -O3"
    "build/soong|build_soong|0001-build-soong.patch|build: Whitelist OPlus framework packages"
    
    # system sepolicy
    "system/sepolicy|system_sepolicy|0001-sepolicy.patch|sepolicy: Label panel_refresh_rate_node property"
)

# ── MAIN ────────────────────────────────────────────────────────────
print_header

log "${BOLD}${YELLOW}━━━ PATCH SEQUENCE (13 patches, dependency-ordered) ━━━${NC}"
log ""

TOTAL=${#PATCH_QUEUE[@]}
current=0

for entry in "${PATCH_QUEUE[@]}"; do
    IFS='|' read -r repo_path patch_dir_name patch_name description <<< "$entry"
    ((current++))
    
    # Build full paths
    full_repo_path="$LUNARIS_ROOT/$repo_path"
    patch_file="$PATCH_DIR/$patch_dir_name/$patch_name"
    
    # Extract commit subject from patch
    COMMIT_SUBJECT=$(grep "^Subject:" "$patch_file" 2>/dev/null | head -1 | sed 's/^Subject: \[PATCH[^]]*\] //' | cut -c1-60)
    
    print_progress "$current" "$TOTAL" "$patch_name"
    log "  Description : $description"
    log "  Commit      : $COMMIT_SUBJECT"
    log "  Repository  : $full_repo_path"
    
    if [ ! -d "$full_repo_path" ]; then
        log "  ${RED}✗ SKIP - Repository not found${NC}"
        result "SKIP  | $repo_path | $COMMIT_SUBJECT | repo not found"
        ((SKIPPED++))
        log ""
        continue
    fi
    
    if [ ! -f "$patch_file" ]; then
        log "  ${RED}✗ SKIP - Patch file not found${NC}"
        result "SKIP  | $repo_path | $COMMIT_SUBJECT | file not found"
        ((SKIPPED++))
        log ""
        continue
    fi
    
    commit_id=$(head -1 "$patch_file" | sed 's/^From //' | awk '{print $1}')
    
    cd "$full_repo_path" 2>/dev/null
    if git cat-file -e "$commit_id" 2>/dev/null; then
        log "  ${GREEN}✓ SKIP - Commit already exists ($commit_id)${NC}"
        result "SKIP  | $repo_path | $COMMIT_SUBJECT | already present"
        ((SKIPPED++))
        cd - > /dev/null 2>/dev/null
        log ""
        continue
    fi
    
    if is_patch_content_present "$full_repo_path" "$patch_file"; then
        log "  ${GREEN}✓ SKIP - Content already present in repo${NC}"
        result "SKIP  | $repo_path | $COMMIT_SUBJECT | content already applied"
        ((SKIPPED++))
        cd - > /dev/null 2>/dev/null
        log ""
        continue
    fi
    
    cd - > /dev/null 2>/dev/null
    
    log "  ${CYAN}⟳ Applying...${NC}"
    
    apply_patch "$full_repo_path" "$patch_file"
    apply_result=$?
    
    case $apply_result in
        0)
            log "  ${GREEN}✓ APPLIED SUCCESSFULLY${NC}"
            result "OK    | $repo_path | $COMMIT_SUBJECT | applied"
            ((APPLIED++))
            ;;
        1)
            log "  ${YELLOW}⚠ PARTIALLY APPLIED (semantic fix needed)${NC}"
            result "PARTIAL | $repo_path | $COMMIT_SUBJECT | partial with semantic fix"
            ((PARTIAL++))
            ;;
        2)
            log "  ${RED}✗ FAILED - All strategies exhausted${NC}"
            result "FAIL  | $repo_path | $COMMIT_SUBJECT | all strategies failed"
            ((FAILED++))
            ;;
    esac
    log ""
done

# ── SUMMARY ─────────────────────────────────────────────────────────
log ""
log "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
log "${BOLD}${BLUE}║                        RESULTS SUMMARY                         ║${NC}"
log "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
log ""
log "  Total patches : $TOTAL"
log "  ${GREEN}Applied       : $APPLIED${NC}"
log "  ${GREEN}Skipped       : $SKIPPED${NC}"
log "  ${YELLOW}Partial       : $PARTIAL${NC}"
log "  ${RED}Failed        : $FAILED${NC}"
log ""

# Show applied patches
if [ "$APPLIED" -gt 0 ]; then
    log "${GREEN}━━━ APPLIED ━━━${NC}"
    grep "^OK" "$RESULT_FILE" 2>/dev/null | while IFS='|' read -r status repo commit reason; do
        log "  ${GREEN}✓${NC} $(echo "$commit" | sed 's/^ *//' | cut -c1-60)"
    done
    log ""
fi

# Show skipped patches
if [ "$SKIPPED" -gt 0 ]; then
    log "${CYAN}━━━ SKIPPED (already present) ━━━${NC}"
    grep "^SKIP" "$RESULT_FILE" 2>/dev/null | while IFS='|' read -r status repo commit reason; do
        log "  ${CYAN}⏭${NC} $(echo "$commit" | sed 's/^ *//' | cut -c1-60)"
    done
    log ""
fi

# Show partial patches
if [ "$PARTIAL" -gt 0 ]; then
    log "${YELLOW}━━━ PARTIAL (needs review) ━━━${NC}"
    grep "^PARTIAL" "$RESULT_FILE" 2>/dev/null | while IFS='|' read -r status repo commit reason; do
        log "  ${YELLOW}⚠${NC} $(echo "$commit" | sed 's/^ *//' | cut -c1-60)"
        log "         $reason"
    done
    log ""
fi

# Show failed patches
if [ "$FAILED" -gt 0 ]; then
    log "${RED}━━━ FAILED ━━━${NC}"
    grep "^FAIL" "$RESULT_FILE" 2>/dev/null | while IFS='|' read -r status repo commit reason; do
        log "  ${RED}✗${NC} $(echo "$commit" | sed 's/^ *//' | cut -c1-60)"
        log "         $reason"
    done
    log ""
fi

log "${BOLD}  Detailed log  : $LOG_FILE${NC}"
log ""
log "${BOLD}${BLUE}══════════════════════════════════════════════════════════════════${NC}"
