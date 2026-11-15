set -euo pipefail
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
mkdir -p "$root/bin" "$root/state"
export FIGARO_STATE_DIR="$root/state"
export ROOT_CHECK_CALLS="$root/calls"
export PATH="$root/bin:$PATH"
printf '%s\n' '{"role":"@11111111111111111111111111111111","holder":"22222222222222222222222222222222"}' >"$FIGARO_STATE_DIR/root-identity.json"
cat >"$root/bin/figaro" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$ROOT_CHECK_CALLS"
[ -z "${FIGARO_ARIA:-}" ]
case "$*" in
  'form show @11111111111111111111111111111111 -j')
    printf '{"target-aria":"%s"}\n' "${CHECK_TARGET:-22222222222222222222222222222222}"
    ;;
  'status 22222222222222222222222222222222 -j')
    printf '{"id":"22222222222222222222222222222222","state":"%s","reaped_at":%s,"retired_at":%s}\n' "${CHECK_STATE:-dormant}" "${CHECK_REAPED:-0}" "${CHECK_RETIRED:-0}"
    ;;
  *) exit 90 ;;
esac
SH
chmod +x "$root/bin/figaro"
script="$(dirname "$0")/../scripts/figaro-root-check.sh"
FIGARO_ARIA=stale bash -euo pipefail "$script"
[ "$(wc -l <"$ROOT_CHECK_CALLS")" -eq 2 ]
if CHECK_TARGET=33333333333333333333333333333333 bash -euo pipefail "$script"; then
  exit 1
fi
[ "$(wc -l <"$ROOT_CHECK_CALLS")" -eq 3 ]
if CHECK_STATE=reaped bash -euo pipefail "$script"; then
  exit 1
fi
[ "$(wc -l <"$ROOT_CHECK_CALLS")" -eq 5 ]
if CHECK_REAPED=42 bash -euo pipefail "$script"; then
  exit 1
fi
[ "$(wc -l <"$ROOT_CHECK_CALLS")" -eq 7 ]
if CHECK_RETIRED=42 bash -euo pipefail "$script"; then
  exit 1
fi
[ "$(wc -l <"$ROOT_CHECK_CALLS")" -eq 9 ]
printf '%s\n' '{"role":"../wrong","holder":"22222222222222222222222222222222"}' >"$FIGARO_STATE_DIR/root-identity.json"
if bash -euo pipefail "$script"; then
  exit 1
fi
[ "$(wc -l <"$ROOT_CHECK_CALLS")" -eq 9 ]
rm "$FIGARO_STATE_DIR/root-identity.json"
if bash -euo pipefail "$script"; then
  exit 1
fi
[ "$(wc -l <"$ROOT_CHECK_CALLS")" -eq 9 ]
echo 'root checks passed without any creation or binding command'
