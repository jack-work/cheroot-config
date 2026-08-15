# THE CONGRUENCE POINT.
#
# Aliases and environment are declared ONCE here and rendered into both fish
# and bash by home-manager. Adding an alias below gives it to both shells; there
# is no second place to edit and no way for them to drift.
#
# What is deliberately NOT here:
#   PATH  — see shell/{fish,bash}.nix. Each shell assembles it with its own
#           deduplicating primitive (`fish_add_path -gmp` / a bash helper).
#           home.sessionPath exists, but it appends blindly, which is exactly
#           the bug that grew $PATH to 43 entries.
#   prompt/fzf/zoxide — those are their own aspects, and each enables both
#           shells' integration from a single `enable`.
{
  flake.modules.homeManager.shell =
    { ... }:
    let
      shellAliases = {
        # figaro shortcuts — these replace the in-binary multi-call symlinks.
        fig = "figaro";
        q = "figaro --";
        qe = "figaro send -e --";
        qf = "figaro send -f --";
        l = "figaro plain --";
        x = "figaro x --";

        # Dotfiles bare repo. Single-quoted in the generated rc files, so $HOME
        # stays literal and expands at call time.
        dotfiles = "git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME";
      };

      sessionVariables = {
        CRYPTOGRAPHY_OPENSSL_NO_LEGACY = "1";
        # Was a stray `set -Ux` universal on gluck: invisible to this repo and
        # surviving every config rollback. Declared.
        GOFLAGS = "-buildvcs=false";
      };
    in
    {
      home = { inherit sessionVariables; };

      # Both shells come from the distro (a login shell needs /etc/shells and a
      # stable path); nix only configures them. `enable` here does not install
      # a shell, it turns on home-manager's rc-file generation.
      programs.fish = {
        inherit shellAliases;
        enable = true;
      };
      programs.bash = {
        inherit shellAliases;
        enable = true;

        historyControl = [
          "ignoredups"
          "ignorespace"
        ];
        historySize = 100000;
        historyFileSize = 200000;
        # `histappend` — without it, the last shell to exit wins and the other
        # windows' history is silently discarded.
        shellOptions = [
          "histappend"
          "checkwinsize"
          "globstar"
        ];
      };
    };
}
