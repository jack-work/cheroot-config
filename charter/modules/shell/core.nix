let
  shellAliases = {
    fig = "figaro";
    q = "figaro --";
    qe = "figaro send -e --";
    qf = "figaro send -f --";
    l = "figaro plain --";
    x = "figaro x --";
    dotfiles = "git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME";
  };

  sessionVariables = {
    CRYPTOGRAPHY_OPENSSL_NO_LEGACY = "1";
    GOFLAGS = "-buildvcs=false";
  };
in
{
  flake.modules.nixos.shell = {
    programs.fish.enable = true;
    environment.shellAliases = shellAliases;
  };

  flake.modules.homeManager.shell =
    { lib, ... }:
    {
      home = { inherit sessionVariables; };

      systemd.user.sessionVariables = sessionVariables // {
        PATH = lib.concatStringsSep ":" [
          "\${HOME}/.local/state/hush/bin"
          "\${HOME}/.nix-profile/bin"
          "\${HOME}/.local/bin"
          "\${HOME}/.cargo/bin"
          "\${HOME}/.bun/bin"
          "\${HOME}/go/bin"
          "/opt/brew/bin"
          "/opt/brew/sbin"
          "\${PATH}"
        ];
      };

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
        shellOptions = [
          "histappend"
          "checkwinsize"
          "globstar"
        ];
      };
    };
}
