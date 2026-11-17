# PATH assembly.
#
# The bash counterpart of fish's `fish_add_path -gmp`. Plain
# `export PATH="$x:$PATH"` re-prepends on every nested shell; measured on the
# fish side, that grew $PATH by 8 entries per nesting level (19 -> 27 -> 35 ->
# 43). path_prepend removes any existing copy first, so nesting is idempotent.
#
# Mirrors config/fish/conf.d/30-path.fish — keep the two in step.

path_prepend() {
    local dir="$1"
    [ -d "$dir" ] || return 0
    # Strip existing occurrences (any position), then prepend.
    PATH=":$PATH:"
    PATH="${PATH//:$dir:/:}"
    PATH="${PATH#:}"
    PATH="${PATH%:}"
    PATH="$dir${PATH:+:$PATH}"
    export PATH
}

if [ -z "$IN_NIX_SHELL" ]; then
    # Order is bottom-up: the LAST path_prepend ends up FIRST in PATH.
    # $GOPATH/bin is added earlier, by ~/.bashrc.d/25-go.sh, so that it lands
    # BEHIND these entries. See modules/go.nix.
    path_prepend "$HOME/.bun/bin"
    path_prepend "$HOME/.cargo/bin"
    path_prepend "$HOME/.local/bin"
    path_prepend "$HOME/.nix-profile/bin"
fi

# In a figaro dev shell, prefer THIS worktree's build (dev-bin holds the
# figaro/fig/q symlinks). Last, so it sits ahead of everything above.
if [ -n "$FIGARO_DEV_BIN" ]; then
    path_prepend "$FIGARO_DEV_BIN"
fi
