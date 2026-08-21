# 12-wayland — repair a lost/stale Wayland session environment.
#
# Symptom this cures:
#
#   $ wl-paste -t image/png > /tmp/toner.png
#   Failed to connect to a Wayland server: No such file or directory
#   Note: WAYLAND_DISPLAY is unset (falling back to wayland-0)
#
# Cause: tmux's `update-environment` rewrites a *session's* environment on every
# attach. Attach once from a bare TTY (or any client without WAYLAND_DISPLAY)
# and tmux records a removal (`-WAYLAND_DISPLAY`) for that session. Session env
# overrides the server's global env, so every pane spawned afterwards is blind
# to the compositor — even though the socket is alive and well.
#
# niri (and any compositor that calls dbus-update-activation-environment /
# systemctl --user import-environment) keeps the systemd user manager's
# environment authoritative and current. That is our source of truth.
#
# Cheap: the systemctl call only runs when the environment is actually broken,
# so a healthy graphical shell pays nothing.

status is-interactive; or exit 0
test -n "$XDG_RUNTIME_DIR"; or exit 0

# Healthy? Socket named by WAYLAND_DISPLAY must actually exist.
if test -n "$WAYLAND_DISPLAY"
    if string match -q '/*' -- $WAYLAND_DISPLAY
        test -S "$WAYLAND_DISPLAY"; and exit 0
    else
        test -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"; and exit 0
    end
end

# Broken. Re-import the graphical bits from the systemd user manager.
if command -q systemctl
    for line in (systemctl --user show-environment 2>/dev/null)
        set -l kv (string split -m 1 '=' -- $line)
        test (count $kv) -eq 2; or continue
        switch $kv[1]
            case WAYLAND_DISPLAY DISPLAY NIRI_SOCKET XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE
                set -gx $kv[1] $kv[2]
        end
    end
end

# Last resort: no systemd answer, but a socket is sitting right there.
if test -z "$WAYLAND_DISPLAY" -o ! -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
    set -l socks $XDG_RUNTIME_DIR/wayland-[0-9]
    if test (count $socks) -ge 1
        set -gx WAYLAND_DISPLAY (basename $socks[1])
    end
end
