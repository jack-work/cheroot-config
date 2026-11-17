top@{ inputs, ... }:
{
  flake.modules.nixos.figaro-forms-bridge =
    { config, lib, ... }:
    let
      cfg = config.my.figaroFormsBridge;
    in
    {
      options.my.figaroFormsBridge = {
        port = lib.mkOption {
          type = lib.types.port;
          default = 7481;
        };
        allowFrom = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Addresses on the tailnet allowed to reach the bridge port; the edge that injects the bearer.";
        };
      };

      config = top.config.flake.lib.tailnetAllow {
        inherit config;
        inherit (cfg) port;
        from = cfg.allowFrom;
      };
    };

  flake.modules.homeManager.figaro-forms-bridge =
    hm@{ lib, pkgs, ... }:
    let
      cfg = hm.config.my.figaroFormsBridge;
      hushPackage = hm.config.my.hush.package or null;
      spec = {
        description = "figaro-forms bridge serving GET /hierarchy to the edge";
        exec = lib.getExe' cfg.package "figaro-forms-bridge";
        args = [
          "--hierarchy-only"
          "--host"
          cfg.host
          "--port"
          (toString cfg.port)
        ];
        secrets.${cfg.secretName} = "FIGARO_FORMS_BRIDGE_TOKEN";
      };
    in
    {
      options.my.figaroFormsBridge = {
        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.figaro-forms.packages.${pkgs.stdenv.hostPlatform.system}.bridge;
          defaultText = lib.literalExpression "inputs.figaro-forms.packages.\${system}.bridge";
        };
        host = lib.mkOption {
          type = lib.types.str;
          description = "Address the edge reaches, such as the node's tailnet IP. Never 0.0.0.0.";
        };
        port = lib.mkOption {
          type = lib.types.port;
          default = 7481;
        };
        hushExecutable = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = if hushPackage == null then null else lib.getExe' hushPackage "hush";
          defaultText = lib.literalExpression ''"''${my.hush.package}/bin/hush", or null when hush is not from nix'';
        };
        command = lib.mkOption {
          type = lib.types.str;
          default = "figaro-forms-bridge";
          description = "hush command name; its secrets.toml is sealed on the node, never in the store.";
        };
        secretName = lib.mkOption {
          type = lib.types.str;
          default = "token";
        };
        commandSpec = lib.mkOption {
          type = lib.types.attrs;
          readOnly = true;
          default = spec;
          description = "The hush command spec written to command.toml.";
        };
      };

      config = {
        assertions = [
          {
            assertion = cfg.hushExecutable != null;
            message = "my.figaroFormsBridge.hushExecutable: hush is not from nix here, so name its path";
          }
          {
            assertion = !(builtins.elem cfg.host [
              "0.0.0.0"
              "::"
              ""
            ]);
            message = "my.figaroFormsBridge.host: bind one address the edge reaches, not every interface";
          }
        ];

        xdg.configFile."hush/commands/${cfg.command}/command.toml".source =
          (pkgs.formats.toml { }).generate "figaro-forms-bridge-command.toml" spec;

        systemd.user.services.figaro-forms-bridge = {
          Unit = {
            Description = "figaro-forms hierarchy for the order site";
            StartLimitIntervalSec = 0;
          };
          Service = {
            ExecStart = "${cfg.hushExecutable} ${cfg.command}";
            Restart = "always";
            RestartSec = 5;
            UMask = "0077";
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
    };
}
