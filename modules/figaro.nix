# figaro — ONE feature, BOTH shells, in one file.
#
# This aspect is the reason the dendritic refactor pays for itself: the fish and
# bash prompt hooks MUST differ, because bash loses figaro's parent-pid binding
# to any pipe or redirect inside a command substitution while fish does not.
# Here the two files sit side by side and the asymmetry is the first thing you
# see, instead of being a comment nobody finds.
#
# ---------------------------------------------------------------------------
# COMPLETIONS ARE DELIBERATELY *NOT* MANAGED HERE.
# ---------------------------------------------------------------------------
# The figaro package already ships them:
#
#   $out/share/fish/vendor_completions.d/{figaro,fig}.fish
#   $out/share/bash-completion/completions/{figaro,fig}.bash
#
# and ~/.nix-profile/share is on XDG_DATA_DIRS, so BOTH shells autoload them.
# Verified on gluck: fish finds them via fish_complete_path, and
# bash-completion's dynamic loader matches the `.bash` suffix.
#
# Checking copies into this repo was worse than redundant — it was harmful.
# ~/.config/fish/completions comes FIRST in fish_complete_path, so a committed
# copy SHADOWS the package's. The copies taken from this machine were already
# stale against figaro 0.26.0 (`promote` and `doctor` carried older
# descriptions), so completions silently lagged the binary.
#
# The rule: completions ship with the binary that generates them. If figaro is
# ever installed by something other than nix, run `figaro completion install`
# rather than committing a snapshot here.
#
# Aliases (fig/q/qe/qf/l/x) are likewise not here: they are plain shell aliases
# with no figaro-specific machinery, so they live with the other shared aliases
# in shell/core.nix and are rendered into both shells from one attrset.
{
  flake.modules.homeManager.figaro = {
    # fish forks each pipeline member itself, so a pipe AND a redirect both keep
    # fish as figaro's parent. The binding survives.
    xdg.configFile."fish/conf.d/65-figaro-prompt.fish".source = ../config/figaro/prompt.fish;

    # bash does NOT. Any pipe or redirect INSIDE a command substitution forks a
    # subshell, and figaro reports "no figaro bound to this shell" forever,
    # silently. Read the header of that file before editing it.
    home.file.".bashrc.d/65-figaro-prompt.sh".source = ../config/figaro/prompt.bash;
  };
}
