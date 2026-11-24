set -uo pipefail
unset FIGARO_ARIA FIGARO_NO_BIND
STEWARD=${KIC_FAILOVER_STEWARD:-}
WINDOW_MS=$((30 * 60 * 1000))
ROLES=(@96447061 @4f6f262b @62c5c9bf @ee927149 @2c164594 @460d7227d652f5af0603f96290376b01 @db5727fe69feb38e67959086ecabcad3 @581b64cf67e173c530197a6c77f383f9)
LOG=$HOME/.captains-log/workstreams/kic-copilot-failover.md
now=$(date +%s%3N)
switched=()

TARGETS=()
LIST=$(figaro list -j 2>/dev/null)
for role in "${ROLES[@]}"; do
  holder=$(figaro state "$role" -j 2>/dev/null | jq -r '."target-aria" // empty')
  [ -n "$holder" ] || continue
  TARGETS+=("$role $holder")
  while read -r kid; do [ -n "$kid" ] && TARGETS+=("$role/lane $kid"); done < <(echo "$LIST" | jq -r --arg h "$holder" '.[] | select((.parent == $h or .present == $h) and (.reaped_at == null)) | .id')
done
for t in "${TARGETS[@]}"; do
  role=${t%% *}; aria=${t#* }
  read -r provider model at reason < <(figaro state "$aria" -j 2>/dev/null |
    jq -r '[.system.provider, .system.model, (.runtime.failure.at // 0), ((.runtime.failure.reason // "-") | gsub("\\s+"; "_") | .[0:120])] | @tsv')
  [ "$provider" = rou2 ] || continue
  case "$model" in anthropic-kic*|anthropic-max*) ;; *) continue ;; esac
  [ $((now - at)) -lt $WINDOW_MS ] || continue
  echo "$reason" | grep -qiE '429|rate.?limit|quota|exhaust|usage.?limit' || continue
  case "$model" in *sonnet*) new=claude-sonnet-5.5 ;; *) new=claude-opus-5.5 ;; esac
  figaro set --id "$aria" system.provider copilot >/dev/null &&
    figaro set --id "$aria" system.model "$new" >/dev/null &&
    figaro send -f --id "$aria" -- "continue: the ${model%%/*} quota ran out, so you were moved to copilot/$new (kic-copilot-failover). Check state before re-running a tool. Fan-out limits unchanged." >/dev/null 2>&1
  switched+=("$role $aria $model -> copilot/$new")
done

[ ${#switched[@]} -gt 0 ] || exit 0
{
  [ -s "$LOG" ] || printf '# KIC to Copilot failover log\n\ndate: 2026-11-20\nsource: kic-copilot-failover timer on gluck (Gluck 11-20: roll over to Copilot on overage)\n\n'
  for s in "${switched[@]}"; do printf -- '- %s %s\n' "$(date -Is)" "$s"; done
} >> "$LOG"
git -C "$HOME/.captains-log" add -- "$LOG" >/dev/null 2>&1
git -C "$HOME/.captains-log" commit -q -m "Record a KIC to Copilot failover" -- "$LOG" >/dev/null 2>&1
[ -n "$STEWARD" ] && figaro send -f --id "$STEWARD" -- "kic-copilot-failover switched: $(printf '%s; ' "${switched[@]}")" >/dev/null 2>&1
exit 0
