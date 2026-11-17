let
  mkKcCli =
    {
      pkgs,
      package,
      baseUrl,
      oidcIssuer,
    }:
    pkgs.writeShellApplication {
      name = "kc";
      text = ''
        export KEEL_BASE=''${KEEL_BASE:-${baseUrl}}
        export KEEL_OIDC_ISSUER=''${KEEL_OIDC_ISSUER:-${oidcIssuer}}
        exec ${pkgs.lib.getExe package} "$@"
      '';
    };
in
{
  flake.modules.nixos.keel =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.keel;
    in
    {
      options.my.keel = {
        enable = lib.mkEnableOption "the kc CLI from an injected keel package";
        package = lib.mkOption {
          type = lib.types.nullOr lib.types.package;
          default = null;
        };
        baseUrl = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        oidcIssuer = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.package != null;
            message = "my.keel.package must be set by the consuming system flake when my.keel.enable is true";
          }
          {
            assertion = cfg.baseUrl != null && cfg.oidcIssuer != null;
            message = "my.keel.baseUrl and my.keel.oidcIssuer must be set by the consuming system flake";
          }
        ];

        environment.systemPackages = [
          (mkKcCli {
            inherit pkgs;
            inherit (cfg) package baseUrl oidcIssuer;
          })
        ];
      };
    };

  flake.modules.homeManager.keel =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.keel;
    in
    {
      options.my.keel = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        package = lib.mkOption {
          type = lib.types.nullOr lib.types.package;
          default = null;
        };
        baseUrl = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        oidcIssuer = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.package != null;
            message = "my.keel.package must be set by the consuming system flake when the keel aspect is enabled";
          }
          {
            assertion = cfg.baseUrl != null && cfg.oidcIssuer != null;
            message = "my.keel.baseUrl and my.keel.oidcIssuer must be set by the consuming system flake";
          }
        ];

        home.packages = [
          (mkKcCli {
            inherit pkgs;
            inherit (cfg) package baseUrl oidcIssuer;
          })
        ];
      };
    };
}
