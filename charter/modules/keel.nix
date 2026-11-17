let
  mkKcCli =
    {
      pkgs,
      src,
      baseUrl,
      oidcIssuer,
    }:
    pkgs.writeShellApplication {
      name = "kc";
      runtimeInputs = with pkgs; [
        curl
        git
        python3
      ];
      text = ''
        export KEEL_BASE=''${KEEL_BASE:-${baseUrl}}
        export KEEL_OIDC_ISSUER=''${KEEL_OIDC_ISSUER:-${oidcIssuer}}
        exec bash ${src}/kc.sh "$@"
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
        enable = lib.mkEnableOption "keel CLI wrapper built from injected src";
        src = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
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
            assertion = cfg.src != null;
            message = "my.keel.src must be set by the consuming system flake when my.keel.enable is true";
          }
          {
            assertion = cfg.baseUrl != null && cfg.oidcIssuer != null;
            message = "my.keel.baseUrl and my.keel.oidcIssuer must be set by the consuming system flake";
          }
        ];

        environment.systemPackages = [
          (mkKcCli {
            inherit pkgs;
            inherit (cfg) src baseUrl oidcIssuer;
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
        src = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
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
            assertion = cfg.src != null;
            message = "my.keel.src must be set by the consuming system flake when the keel aspect is enabled";
          }
          {
            assertion = cfg.baseUrl != null && cfg.oidcIssuer != null;
            message = "my.keel.baseUrl and my.keel.oidcIssuer must be set by the consuming system flake";
          }
        ];

        home.packages = [
          (mkKcCli {
            inherit pkgs;
            inherit (cfg) src baseUrl oidcIssuer;
          })
        ];
      };
    };
}
