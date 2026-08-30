# figaro — ONE feature, BOTH shells, in one file.
#
# ---------------------------------------------------------------------------
# THE BINARY IS NULLABLE, AND ON GLUCK IT IS NULL. READ THIS BEFORE CHANGING IT.
# ---------------------------------------------------------------------------
# Until 2026-08-30 this aspect configured figaro and did not install it: the
# binary came from `nix profile install git+file:///home/gluck/dev/figaro-qua/
# .bare?ref=release`, invisible to this repo and — being a git+file: URL — not
# resolvable by any other machine. That is the same drift the nixfmt removal
# fixed, one level up.
#
# But the obvious correction is WRONG FOR THE DEVELOPMENT HOST. figaro has 76
# tags. Gluck cuts them, and his working tree is routinely ahead of the newest.
# Taking the binary from a flake input would make every single figaro release
# cost:
#
#     nix flake update figaro  →  git commit  →  home-manager switch
#
# in THIS repo — a lockfile bump and a config commit per figaro build, on the
# one machine that gains nothing from the pin. The existing loop is already one
# command, and figaro's own `update` subcommand prints it verbatim:
#
#     $ figaro update
#     figaro dev-d1270001dbc2 installed (channel: nix)
#     to upgrade: nix profile upgrade figaro
#
# figaro is channel-aware and never rewrites a nix-store binary, so the
# imperative profile and this aspect do not fight; they divide.
#
# So: `my.figaro.package` is nullable, exactly as programs.go's `package = null`
# takes the CONFIGURATION and leaves the binary to the distro (see
# modules/go.nix and the note in modules/git.nix). Here the "distro" is Gluck's
# own dev loop.
#
#   gluck              null — the dev host, `nix profile upgrade figaro`
#   everything else    the pinned `figaro` flake input: reproducible, moved on
#                      purpose, and resolvable from a machine that has never
#                      seen /home/gluck
#
# The prompt hooks below are installed either way, because they are TRUE OF THE
# SHELL and not of the binary — a host with a null package still wants them.
#
# ---------------------------------------------------------------------------
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
{ inputs, ... }:
{
  flake.modules.homeManager.figaro =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      options.my.figaro.package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = inputs.figaro.packages.${pkgs.stdenv.hostPlatform.system}.default;
        defaultText = lib.literalExpression "inputs.figaro.packages.\${system}.default";
        description = ''
          The figaro binary this host installs, or `null` to install none and
          take only the shell configuration.

          NULL ON THE DEVELOPMENT HOST. See the header of this file: figaro is
          released often enough that routing its binary through this repo's
          lockfile would cost a flake update and a config commit per build, on
          the one machine that gains nothing from a pin. Every other host takes
          the default, which is reproducible and does not name a path that only
          exists on gluck.
        '';
      };

      config = {
        home.packages = lib.optional (config.my.figaro.package != null) config.my.figaro.package;

        # fish forks each pipeline member itself, so a pipe AND a redirect both keep
        # fish as figaro's parent. The binding survives.
        xdg.configFile."fish/conf.d/65-figaro-prompt.fish".source = ../config/figaro/prompt.fish;

        # bash does NOT. Any pipe or redirect INSIDE a command substitution forks a
        # subshell, and figaro reports "no figaro bound to this shell" forever,
        # silently. Read the header of that file before editing it.
        home.file.".bashrc.d/65-figaro-prompt.sh".source = ../config/figaro/prompt.bash;
      };
    };
}
