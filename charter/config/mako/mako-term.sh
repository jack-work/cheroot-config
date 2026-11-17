# mako-term.sh — open a terminal (optionally a tmux pane) from a notification.
#
# Wire it up ONCE in ~/.config/mako/config:
#     on-button-right=exec ~/.config/mako/mako-term.sh "$id"
# and never edit the mako config again. All logic lives here.
#
# Behaviour: looks up the notification by id, picks a command from the
# routing table below based on app-name, and runs it in a terminal.
# Unknown apps fall back to an interactive shell — so it is useful
# without any routing entries at all.

# (strict mode supplied by writeShellApplication)

TERMINAL=${TERMINAL:-alacritty}
TMUX_SESSION=${MAKO_TMUX_SESSION:-main}
USE_TMUX=${MAKO_USE_TMUX:-0}   # 1 = split a pane instead of a new window

id=${1:-}

# --- pull notification metadata (empty strings if it already expired) -------
if [[ $id =~ ^[0-9]+$ ]]; then
    meta=$(makoctl list -j 2>/dev/null | jq -r --argjson id "$id" '
        [ .[] | select(.id == $id) ][0] // {}
        | "\(.app_name // "")\t\(.summary // "")\t\(.body // "")"
    ' 2>/dev/null)
fi
IFS=$'\t' read -r app summary body <<<"${meta:-$'\t\t'}"

# --- routing table: app-name -> command ------------------------------------
# Add a line here when you want an app to do something specific.
# Everything else gets a shell. This is the only part worth maintaining.
case "$app" in
    figaro)      cmd="figaro list" ;;
    Thunderbird) cmd="aerc" ;;
    *)           cmd="" ;;         # empty = interactive shell
esac

# Export context so whatever you launch can see it.
export MAKO_APP="$app" MAKO_SUMMARY="$summary" MAKO_BODY="$body"

# --- launch ----------------------------------------------------------------
if [[ $USE_TMUX == 1 ]]; then
    tmux has-session -t "$TMUX_SESSION" 2>/dev/null \
        || tmux new-session -d -s "$TMUX_SESSION"
    if [[ -n $cmd ]]; then
        tmux split-window -t "$TMUX_SESSION" -d "$cmd; exec ${SHELL:-bash}"
    else
        tmux split-window -t "$TMUX_SESSION" -d
    fi
    # surface it if nothing is attached
    pgrep -f "tmux.*attach.*$TMUX_SESSION" >/dev/null \
        || exec "$TERMINAL" -e tmux attach -t "$TMUX_SESSION"
else
    title="notif${app:+: $app}"
    if [[ -n $cmd ]]; then
        exec "$TERMINAL" --title "$title" -e bash -c "$cmd; exec ${SHELL:-bash}"
    else
        exec "$TERMINAL" --title "$title"
    fi
fi
