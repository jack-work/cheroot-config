{ inputs, config, ... }:
{
  flake.modules.nixos.hush =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.hush;
      hasCredModule = inputs.hush.nixosModules ? hush-cred;
      credInstanceType = lib.types.submodule {
        options = {
          kind = lib.mkOption {
            type = lib.types.enum [
              "anthropic"
              "copilot"
              "chatgpt"
            ];
          };
          clientId = lib.mkOption {
            type = lib.types.str;
            default = "";
          };
          tokenUrl = lib.mkOption {
            type = lib.types.str;
            default = "";
          };
          scopes = lib.mkOption {
            type = lib.types.str;
            default = "";
          };
          authorizeUrl = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          redirectUri = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          deviceUrl = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          githubTokenUrl = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
        };
      };
    in
    {
      imports = [
        inputs.hush.nixosModules.default
      ]
      ++ lib.optional hasCredModule inputs.hush.nixosModules.hush-cred;

      options.my.hush = {
        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.hush.packages.${pkgs.stdenv.hostPlatform.system}.hush;
        };
        agent.enable = lib.mkEnableOption "socket-activated per-user hush agent";
        cred = {
          enable = lib.mkEnableOption "per-node hush cred plan-credential minter";
          uid = lib.mkOption {
            type = lib.types.int;
            default = 476;
          };
          allowUser = lib.mkOption {
            type = lib.types.str;
            default = "rou2";
          };
          socketGroup = lib.mkOption {
            type = lib.types.str;
            default = "rou2";
          };
          recipient = lib.mkOption {
            type = lib.types.nullOr (lib.types.strMatching "age1[0-9a-z]+");
            default = null;
          };
          identityFile = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          instances = lib.mkOption {
            type = lib.types.attrsOf credInstanceType;
            default = { };
          };
          resolvers = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ "127.0.0.1" ];
          };
          dnsmasq = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.agent.enable {
          services.hush-agent = {
            enable = true;
            package = cfg.package;
          };
        })
        (lib.mkIf cfg.cred.enable (
          {
            assertions = [
              {
                assertion = hasCredModule;
                message = "my.hush.cred.enable requires inputs.hush >= v0.15.0 exporting nixosModules.hush-cred";
              }
              {
                assertion = cfg.cred.recipient != null && cfg.cred.identityFile != null;
                message = "my.hush.cred.enable requires per-node recipient and identityFile options";
              }
            ];
          }
          // lib.optionalAttrs hasCredModule {
            services.hush-cred = {
              enable = true;
              package = cfg.package;
              uid = cfg.cred.uid;
              allowUser = cfg.cred.allowUser;
              socketGroup = cfg.cred.socketGroup;
              recipient = cfg.cred.recipient;
              identityFile = cfg.cred.identityFile;
              instances = cfg.cred.instances;
              egress = {
                resolvers = cfg.cred.resolvers;
                dnsmasq = cfg.cred.dnsmasq;
              };
            };
          }
        ))
      ];
    };

  flake.modules.homeManager.hush =
    hm@{ lib, pkgs, ... }:
    {
      options.my.hush.package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = inputs.hush.packages.${pkgs.stdenv.hostPlatform.system}.default;
        defaultText = lib.literalExpression "inputs.hush.packages.\${system}.default";
      };

      options.my.hush.unlock = lib.mkOption {
        type = lib.types.nullOr lib.types.lines;
        default = null;
      };

      config = {
        home.packages = lib.optional (hm.config.my.hush.package != null) hm.config.my.hush.package;

        xdg.configFile =
          config.flake.lib.linkDir ../config/hush/commands/brave "hush/commands/brave"
          // lib.optionalAttrs (hm.config.my.hush.unlock != null) {
            "hush/hush.toml".text = hm.config.my.hush.unlock;
          };
      };
    };
}
