#!/bin/sh
# Track niri's keyboard-shortcuts-inhibitor state per window.
#
# niri exposes no IPC for the inhibitor (it lives in
# Niri::keyboard_shortcuts_inhibiting_surfaces, keyed by wl_surface), so we
# bookkeep it ourselves: every time the user hits the toggle bind we flip the
# recorded state for the currently focused window id.
#
#   kbd-inhibit.sh toggle   -> toggle in niri + record + poke waybar
#   kbd-inhibit.sh watch    -> follow the event stream, poke waybar on focus change
#   kbd-inhibit.sh state    -> print state of focused window (free|eaten|unknown)

DIR="${XDG_RUNTIME_DIR:-/tmp}/niri-kbd-inhibit"
SIG=9   # waybar "signal": 9  ==  SIGRTMIN+9

focused_id() { niri msg -j focused-window 2>/dev/null | jq -r '.id // empty'; }
poke()       { pkill -RTMIN+$SIG waybar 2>/dev/null; }

mkdir -p "$DIR"

case "$1" in
toggle)
    id=$(focused_id)
    niri msg action toggle-keyboard-shortcuts-inhibit
    if [ -n "$id" ]; then
        f="$DIR/$id"
        # Only windows we've toggled at least once are known to hold an
        # inhibitor at all; everything else stays "unknown" (no indicator).
        if [ "$(cat "$f" 2>/dev/null)" = free ]; then
            echo eaten >"$f"
        else
            echo free >"$f"
        fi
    fi
    poke
    ;;

state)
    id=$(focused_id)
    [ -n "$id" ] && cat "$DIR/$id" 2>/dev/null || echo unknown
    ;;

watch)
    rm -f "$DIR"/*            # stale ids from a previous niri session
    poke
    niri msg -j event-stream 2>/dev/null | while IFS= read -r line; do
        case "$line" in
        *WindowFocusChanged*)
            poke
            ;;
        *WindowClosed*)
            id=$(printf '%s' "$line" | jq -r '.WindowClosed.id // empty')
            [ -n "$id" ] && rm -f "$DIR/$id"
            poke
            ;;
        esac
    done
    ;;

*)
    echo "usage: $0 {toggle|watch|state}" >&2
    exit 2
    ;;
esac
