# Environment variables only.
# PATH lives in 30-path.fish; aliases in 40-aliases.fish.

set -gx CRYPTOGRAPHY_OPENSSL_NO_LEGACY 1

# Go configuration lives in modules/go.nix -> ~/.config/go/env, which the go
# tool reads directly. It is NOT a shell variable any more, so it also applies
# to editors and IDEs that never source a shell.

# ssh-agent socket, published by the systemd user unit.
# Was hardcoded /run/user/1000 — correct on this box, wrong on any other.
if set -q XDG_RUNTIME_DIR
    set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
end

# tmux drops SSH_TTY. Restore it so remote-session detection keeps working.
if set -q SSH_CONNECTION; and not set -q SSH_TTY
    set -gx SSH_TTY (tty)
end
