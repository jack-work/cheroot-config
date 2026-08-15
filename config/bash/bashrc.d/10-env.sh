# Environment variables only.
# PATH lives in 30-path.sh; aliases come from home-manager (shell/core.nix).
#
# Mirrors config/fish/conf.d/10-env.fish — keep the two in step.

export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1
# GOFLAGS/GOPATH: see modules/go.nix -> ~/.config/go/env (read by the go tool
# itself, so it applies to editors and IDEs too, not just shells).

# ssh-agent socket, published by the systemd user unit.
# XDG_RUNTIME_DIR rather than a hardcoded /run/user/1000: correct on any host.
if [ -n "$XDG_RUNTIME_DIR" ]; then
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi

# tmux drops SSH_TTY. Restore it so remote-session detection keeps working.
if [ -n "$SSH_CONNECTION" ] && [ -z "$SSH_TTY" ]; then
    SSH_TTY=$(tty) && export SSH_TTY
fi

# Format man pages through bat, matching the CachyOS fish default.
export MANROFFOPT="-c"
if command -v bat >/dev/null 2>&1; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi
