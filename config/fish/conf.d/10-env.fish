# Environment variables only.
# PATH lives in 30-path.fish; aliases in 40-aliases.fish.

set -gx CRYPTOGRAPHY_OPENSSL_NO_LEGACY 1

# Go configuration lives in modules/go.nix -> ~/.config/go/env, which the go
# tool reads directly. It is NOT a shell variable any more, so it also applies
# to editors and IDEs that never source a shell.

# ssh-agent socket, published by a systemd user unit.
# Was hardcoded /run/user/1000 — correct on this box, wrong on any other.
#
# gcr-ssh-agent, not OpenSSH's ssh-agent.socket: it wraps the same ssh-agent but
# preloads ~/.ssh/*.pub and, when a key is actually used, takes its passphrase
# from the login keyring (schema org.freedesktop.Secret.Generic, attribute
# unique=ssh-store:<path>). The keyring opens at login, so the key loads itself
# on first use and `ssh-add` per boot is no longer a thing. This is convenience,
# not hardening: the key is exactly as available as the login keyring — the same
# posture as typing ssh-add once per session.
#
# Fall back to OpenSSH's socket where gcr is absent, so a host without
# gnome-keyring still gets an agent instead of a path to nothing.
if set -q XDG_RUNTIME_DIR
    if test -S $XDG_RUNTIME_DIR/gcr/ssh
        set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/gcr/ssh
    else
        set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
    end
end

# tmux drops SSH_TTY. Restore it so remote-session detection keeps working.
if set -q SSH_CONNECTION; and not set -q SSH_TTY
    set -gx SSH_TTY (tty)
end
