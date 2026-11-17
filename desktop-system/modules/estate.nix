{ inputs, lib, ... }:
{
  flake.modules.homeManager.git = {
    my.git = {
      userName = lib.mkDefault "gluck";
      userEmail = lib.mkDefault "gluck@kelliher.info";
    };
  };

  flake.modules.homeManager.editor = {
    my.editor.nvimRepoUrl = lib.mkDefault "https://github.com/jack-work/nvim-gluck";
  };

  flake.modules.homeManager.helium = {
    my.helium = {
      originOverride = lib.mkDefault "https://spain.tail34d120.ts.net";
      exitHost = lib.mkDefault "100.103.40.20";
      defaultExit = lib.mkDefault "seattle";
      exits = lib.mkDefault {
        seattle = 1081;
        newjersey = 1082;
        amsterdam = 1083;
      };
    };
  };

  flake.modules.homeManager.keel = {
    my.keel = {
      src = lib.mkDefault inputs.keel;
      baseUrl = lib.mkDefault "https://keel.kelliher.info";
      oidcIssuer = lib.mkDefault "https://auth.kelliher.info";
    };
  };

  flake.modules.homeManager.captains-log =
    { pkgs, ... }:
    {
      my.captainsLog = {
        src = lib.mkDefault inputs.captains-log;
        package = lib.mkDefault inputs.captains-log.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
    };
}
