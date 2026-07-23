#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)"
MODULE_PROP="$ROOT/module.prop"
PRERELEASE_JSON="$ROOT/update-prerelease.json"
RELEASE_NOTES="$ROOT/RELEASE_NOTES_2.0.0-alpha.2.md"
BOOTGUARD_GUARD="$ROOT/tools/bootguard/bootguard-threshold-policy-guard.sh"
PTUNE_GUARD="$ROOT/tools/ptune/ptune-install-state-observability-guard.sh"
POLICY_GUARD="$ROOT/tools/v2-public-alpha2-policy-guard.sh"
DELTA_GUARD="$ROOT/tools/outdoor-delta-validation-guard.sh"

fail=0
pass() { printf 'PASS %s\n' "$*"; }
err() { printf 'FAIL %s\n' "$*"; fail=1; }

for file in \
  "$MODULE_PROP" \
  "$PRERELEASE_JSON" \
  "$RELEASE_NOTES" \
  "$ROOT/tools/bootguard/bootguard-lib.sh" \
  "$ROOT/tools/install-finalize.sh" \
  "$ROOT/tools/ptune/ptune-guard.sh" \
  "$ROOT/tools/core/patch-thermal-validated.sh" \
  "$ROOT/tools/core/verify-outdoor-delta.sh" \
  "$BOOTGUARD_GUARD" \
  "$PTUNE_GUARD" \
  "$POLICY_GUARD" \
  "$DELTA_GUARD"
do
  [[ -s "$file" ]] && pass "file_present=${file#$ROOT/}" || err "file_missing=${file#$ROOT/}"
done

for script in \
  "$ROOT/tools/bootguard/bootguard-lib.sh" \
  "$ROOT/tools/install-finalize.sh" \
  "$ROOT/tools/ptune/ptune-guard.sh" \
  "$ROOT/tools/core/patch-thermal-validated.sh" \
  "$ROOT/tools/core/verify-outdoor-delta.sh" \
  "$BOOTGUARD_GUARD" \
  "$PTUNE_GUARD" \
  "$POLICY_GUARD" \
  "$DELTA_GUARD"
do
  bash -n "$script" && pass "syntax=${script#$ROOT/}" || err "syntax=${script#$ROOT/}"
done

grep -Fxq 'version=2.0.0-alpha.2' "$MODULE_PROP" && pass version || err version
grep -Fxq 'versionCode=1016210' "$MODULE_PROP" && pass version_code || err version_code
grep -Fxq '# 2.0.0-alpha.2' "$RELEASE_NOTES" && pass release_notes_version || err release_notes_version
grep -Fq 'Publication remains pending final package and runtime verification.' "$MODULE_PROP" && pass publication_boundary || err publication_boundary
grep -Fq '"version": "1.5.2-universal-v2-alpha.1"' "$PRERELEASE_JSON" && pass prerelease_channel_unchanged || err prerelease_channel_changed

if bash "$BOOTGUARD_GUARD"; then
  pass bootguard_threshold_policy
else
  err bootguard_threshold_policy
fi

if bash "$PTUNE_GUARD"; then
  pass ptune_install_state_observability
else
  err ptune_install_state_observability
fi

if bash "$POLICY_GUARD"; then
  pass v2_public_alpha2_policy
else
  err v2_public_alpha2_policy
fi

if bash "$DELTA_GUARD"; then
  pass outdoor_delta_validation
else
  err outdoor_delta_validation
fi

if [[ "$fail" -eq 0 ]]; then
  printf 'RESULT: V2_ALPHA2_CANDIDATE_VERIFY_PASS rc=0\n'
else
  printf 'RESULT: V2_ALPHA2_CANDIDATE_VERIFY_FAIL rc=1\n'
  exit 1
fi
