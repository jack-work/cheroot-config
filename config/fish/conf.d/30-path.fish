# PATH assembly.
#
# WHY fish_add_path AND NOT `set -gx PATH $x $PATH`:
# the old config prepended unconditionally, so every nested shell re-added the
# same directories. Measured before this change: $PATH held FIVE copies of
# ~/.local/bin and ~/.cargo/bin, four of ~/.nix-profile/bin.
#
#   -g / --global   write to PATH only, never to the fish_user_paths universal
#                   (universals persist across sessions and compound the mess)
#   -m / --move     already present? relocate it instead of adding a duplicate
#   -p / --prepend  ours take precedence over system paths
#
# Order is bottom-up: the LAST fish_add_path ends up FIRST in PATH.

if not set -q IN_NIX_SHELL
    # go is not installed on every host — `go env` would error and print noise.
    if command -q go
        fish_add_path -gmp (go env GOPATH)/bin
    end
    fish_add_path -gmp $HOME/.bun/bin
    fish_add_path -gmp $HOME/.cargo/bin
    fish_add_path -gmp $HOME/.local/bin
    fish_add_path -gmp $HOME/.nix-profile/bin
end

# In a figaro dev shell, prefer THIS worktree's build (dev-bin holds the
# figaro/fig/q symlinks). Last, so it sits ahead of everything above.
if set -q FIGARO_DEV_BIN
    fish_add_path -gmp $FIGARO_DEV_BIN
end
