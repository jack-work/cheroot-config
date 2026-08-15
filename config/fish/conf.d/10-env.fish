# Environment variables only.
# PATH lives in 30-path.fish; aliases in 40-aliases.fish.

set -gx CRYPTOGRAPHY_OPENSSL_NO_LEGACY 1

# Go: skip the VCS stamp. Was a stray universal variable (`set -Ux`), which
# meant it was invisible in this repo and survived config rollbacks. Declared.
set -gx GOFLAGS -buildvcs=false

# ssh-agent socket, published by the systemd user unit.
# Was hardcoded /run/user/1000 — correct on this box, wrong on any other.
if set -q XDG_RUNTIME_DIR
    set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
end

# tmux drops SSH_TTY. Restore it so remote-session detection keeps working.
if set -q SSH_CONNECTION; and not set -q SSH_TTY
    set -gx SSH_TTY (tty)
end
