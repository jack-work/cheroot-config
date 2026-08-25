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
    {
      config,
      lib,
      pkgs,
      ...
    }:
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

      # THE TEST FOR THIS ATTRSET: would a headless box, a container or WSL
      # want it? If the answer is no, it does not belong in a core aspect.
      # The desktop session's variables (QT_QPA_PLATFORMTHEME, TERM) live in
      # modules/desktop/session.nix; BROWSER names a specific binary and lives
      # in the host file.
      sessionVariables = {
        CRYPTOGRAPHY_OPENSSL_NO_LEGACY = "1";
        # Was a stray `set -Ux` universal on gluck: invisible to this repo and
        # surviving every config rollback. Declared.
        GOFLAGS = "-buildvcs=false";
      };
    in
    {
      home = { inherit sessionVariables; };

      # NOTE ON THE FISH BINARY. home-manager's fish module runs `fish_indent`
      # to format the config.fish it generates, and invokes `fish` to build
      # completions — so enabling fish config management NECESSARILY installs a
      # nix fish. Pointing `package` at an empty derivation was tried and fails
      # the build outright ("fish_indent: No such file or directory").
      #
      # On Arch that is benign today: the distro ships fish 4.8.1 and nixpkgs
      # pins 4.8.1, and /etc/passwd launches /bin/fish by ABSOLUTE path, so the
      # login shell is always the system one. Be aware only that `fish` invoked
      # from PATH resolves to the nix copy, since ~/.nix-profile/bin precedes
      # /usr/bin. If the two versions ever diverge, that is where it will show.
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
