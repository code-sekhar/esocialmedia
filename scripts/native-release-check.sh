#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
action="${1:-checklist}"
case "$action" in
 checklist)
  cat <<'TEXT'
RELEASE BLOCKED until actual dedicated-device evidence is reviewed:
[ ] Android Keystore / iOS Keychain write/read/delete (smoke test below)
[ ] Remember-me off and remembered session app kill/restart/restoration
[ ] Locked/unavailable storage: no insecure fallback
[ ] Lost refresh response/crash: no spent credential replay
[ ] Current/all-device logout and failed storage deletion
[ ] Cloud backup, device transfer, restore/reinstall and surviving Keychain items
[ ] Plugin/app upgrade and account switch
[ ] Real release identifiers, merged resources, provisioning/entitlements and signing
[ ] Native auth/profile/consent/media workflows and accessibility
Record OS/device/SDK/plugin/build hash and redacted evidence. Smoke alone is not release sign-off.
TEXT
  ;;
 preflight)
  flutter --version
  flutter devices
  printf '%s\n' 'RELEASE BLOCKED: inspect dedicated Android/iOS targets; no storage/signing result is implied.'
  ;;
 storage-smoke)
  : "${2:?Pass a dedicated Android/iOS device ID}"
  if [[ "${EASTALYA_DEDICATED_DEVICE:-}" != true ]]; then
   printf '%s\n' 'Set EASTALYA_DEDICATED_DEVICE=true only for an approved synthetic test device.' >&2
   exit 3
  fi
  flutter test integration/native_storage_smoke_test.dart -d "$2"
  printf '%s\n' 'Storage smoke completed; restart/backup/signing gates remain RELEASE BLOCKED.'
  ;;
 *) printf '%s\n' 'Usage: native-release-check.sh checklist|preflight|storage-smoke <dedicated-device-id>' >&2; exit 2 ;;
esac
