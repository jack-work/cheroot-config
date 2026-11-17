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

  flake.modules.homeManager.shell = {
    home = { inherit sessionVariables; };

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
