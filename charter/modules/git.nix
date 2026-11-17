{
  flake.modules.nixos.git = {
    programs.git.enable = true;
  };

  flake.modules.homeManager.git =
    { config, lib, ... }:
    let
      cfg = config.my.git;
      userSettings =
        lib.optionalAttrs (cfg.userName != null) { name = cfg.userName; }
        // lib.optionalAttrs (cfg.userEmail != null) { email = cfg.userEmail; };
    in
    {
      options.my.git = {
        userName = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        userEmail = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        defaultBranch = lib.mkOption {
          type = lib.types.str;
          default = "master";
        };
      };

      config = {
        programs.git = {
          enable = true;
          settings = lib.optionalAttrs (userSettings != { }) { user = userSettings; } // {
            init.defaultBranch = cfg.defaultBranch;
            credential."https://github.com".helper = [
              ""
              "!gh auth git-credential"
            ];
            credential."https://gist.github.com".helper = [
              ""
              "!gh auth git-credential"
            ];
          };
        };

        programs.delta = {
          enable = true;
          enableGitIntegration = true;
        };
      };
    };
}
