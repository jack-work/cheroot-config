identity="$FIGARO_STATE_DIR/root-identity.json"
if [ ! -f "$identity" ]; then
  echo "No root identity recorded at $identity; create the root once using the bootstrap run sheet." >&2
  exit 3
fi
role=$(jq -er '.role | select(type == "string" and test("^@[0-9a-f]{32}$"))' "$identity")
holder=$(jq -er '.holder | select(type == "string" and test("^[0-9a-f]{32}$"))' "$identity")
unset FIGARO_ARIA
snapshot=$(figaro form show "$role" -j)
if ! jq -e --arg holder "$holder" '.["target-aria"] == $holder' <<<"$snapshot" >/dev/null; then
  echo "Root binding differs from the recorded holder; refusing to create, cast or replace anything." >&2
  exit 1
fi
status=$(figaro status "$holder" -j)
if ! jq -e --arg holder "$holder" '.id == $holder and (.state == "idle" or .state == "active" or .state == "dormant") and ((.reaped_at // 0) == 0) and ((.retired_at // 0) == 0)' <<<"$status" >/dev/null; then
  echo "Recorded root holder is absent, reaped, retired or in an unsupported state." >&2
  exit 1
fi
printf 'Root %s is bound to %s.\n' "$role" "$holder"
