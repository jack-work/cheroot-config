#!/bin/sh
# waybar custom module: keyboard-shortcuts-inhibitor indicator.
# Silent unless the focused window is known to hold an inhibitor.

DIR="${XDG_RUNTIME_DIR:-/tmp}/niri-kbd-inhibit"
id=$(niri msg -j focused-window 2>/dev/null | jq -r '.id // empty')
state=unknown
[ -n "$id" ] && state=$(cat "$DIR/$id" 2>/dev/null || echo unknown)

case "$state" in
eaten) printf '{"text":"\xe2\x97\x8f","class":"eaten","tooltip":"shortcuts inhibited — this window eats Mod (Mod+Escape to take it back)"}\n' ;;
free)  printf '{"text":"\xe2\x97\x8f","class":"free","tooltip":"inhibitor suppressed — niri keeps your binds (Mod+Escape to give them back)"}\n' ;;
*)     printf '{"text":"","class":"unknown","tooltip":""}\n' ;;
esac
