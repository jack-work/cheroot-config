export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1
# Skip global tool prepends inside a nix shell so the dev env's tools win.
if not set -q IN_NIX_SHELL
    export PATH="$(go env GOPATH)/bin:$PATH"
end

# Ensure SSH_TTY is set when in an SSH session (tmux drops it)
if set -q SSH_CONNECTION; and not set -q SSH_TTY
    set -gx SSH_TTY (tty)
end

source /usr/share/cachyos-fish-config/cachyos-config.fish
# In config.fish
starship init fish | source
zoxide init fish | source

# Sync colors with GTK theme on startup
sync_gtk_theme
# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
function load_conda
    if test -f /opt/miniconda3/bin/conda
        eval /opt/miniconda3/bin/conda "shell.fish" hook $argv | source
    else
        if test -f "/opt/miniconda3/etc/fish/conf.d/conda.fish"
            source "/opt/miniconda3/etc/fish/conf.d/conda.fish"
        else
            set -x PATH /opt/miniconda3/bin $PATH
        end
    end
    # <<< conda initialize <<<
end

function conda
    load_conda
    conda
end
if not set -q IN_NIX_SHELL
    set -gx PATH $HOME/.cargo/bin $PATH
    set -gx PATH $HOME/.local/bin $PATH
    set -gx PATH $HOME/.nix-profile/bin $PATH
end
set -gx SSH_AUTH_SOCK /run/user/1000/ssh-agent.socket
# Dotfiles bare repo alias
alias dotfiles "git --git-dir=\$HOME/.dotfiles/ --work-tree=\$HOME"

# Figaro shortcuts (replaces the in-binary multi-call symlinks)
alias fig figaro
alias q 'figaro --'
alias qe 'figaro send -e --'
alias qf 'figaro send -f --'
alias l 'figaro plain --'
alias x 'figaro x --'

# In a figaro dev shell, prefer THIS worktree's build (the dev-bin holds
# figaro/fig/q symlinks). Runs last so it sits ahead of the ~/go/bin and
# ~/.nix-profile prepends above; only active when $FIGARO_DEV_BIN is set.
if set -q FIGARO_DEV_BIN
    set -gx PATH $FIGARO_DEV_BIN $PATH
end
