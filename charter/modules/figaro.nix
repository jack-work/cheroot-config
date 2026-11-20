{ inputs, config, ... }:
{
  flake.modules.nixos.figaro =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.figaro;
      systemMode = if cfg.mode == "system" then "house" else cfg.mode;
      onHost = systemMode == "house" || systemMode == "estate";
      toml = pkgs.formats.toml { };
      withCredoOutfits =
        if cfg.credo == null then
          cfg.outfits
        else
          lib.mapAttrs (
            _: spec:
            spec
            // {
              system = {
                credo = cfg.credo;
              }
              // (spec.system or { });
            }
          ) cfg.outfits;
    in
    {
      imports = [
        inputs.figaro.nixosModules.default
        inputs.figaro.nixosModules.container
      ];

      options.my.figaro = {
        mode = lib.mkOption {
          type = lib.types.enum [
            "none"
            "house"
            "estate"
            "system"
            "container"
          ];
          default = "none";
          description = ''
            house: a person's NixOS machine; the angelus runs as uid figaro
            and `owner` owns it. estate: a server with no person's files in
            play. Both are services.figaro.mode. system is house, kept for
            one release. container: the angelus in figaro-container.
          '';
        };
        owner = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "House mode: the user who owns the angelus (services.figaro.owner); his uid must be pinned.";
        };
        users = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Other users who reach the CLI door (services.figaro.users).";
        };
        localTools = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Let a figaro on local run tools as the angelus's own uid (services.figaro.localTools).";
        };
        importFrom = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "A home-mode state directory copied into the house's store once, before its first start (services.figaro.importFrom).";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.figaro.packages.${pkgs.stdenv.hostPlatform.system}.figaro;
        };
        credo = lib.mkOption {
          type = lib.types.nullOr lib.types.lines;
          default = null;
        };
        settings = lib.mkOption {
          type = toml.type;
          default = { };
        };
        providers = lib.mkOption {
          type = lib.types.attrsOf toml.type;
          default = { };
        };
        outfits = lib.mkOption {
          type = lib.types.attrsOf toml.type;
          default = { };
        };
      };

      config = lib.mkMerge [
        (lib.mkIf (cfg.mode == "none") {
          services.figaro.enable = lib.mkDefault false;
        })
        (lib.mkIf onHost {
          warnings =
            lib.optional (cfg.mode == "system")
              "my.figaro.mode = \"system\" is house mode; write \"house\", since system goes in the next release.";
          services.figaro = {
            enable = true;
            mode = systemMode;
            package = cfg.package;
            settings = cfg.settings;
            providers = cfg.providers;
            outfits = withCredoOutfits;
            inherit (cfg)
              owner
              users
              localTools
              importFrom
              ;
          };
          systemd.services.figaro.serviceConfig.OOMPolicy = lib.mkDefault "continue";
        })
        (lib.mkIf (cfg.mode == "container") {
          services.figaro-container = {
            enable = true;
            package = cfg.package;
            figaro.services.figaro = {
              settings = cfg.settings;
              providers = cfg.providers;
              outfits = withCredoOutfits;
            };
          };
        })
      ];
    };

  flake.modules.homeManager.figaro =
    hm@{ pkgs, lib, ... }:
    let
      cfg = hm.config.my.figaro;
      toml = pkgs.formats.toml { };
    in
    {
      options.my.figaro = {
        package = lib.mkOption {
          type = lib.types.nullOr lib.types.package;
          default = inputs.figaro.packages.${pkgs.stdenv.hostPlatform.system}.default;
          defaultText = lib.literalExpression "inputs.figaro.packages.\${system}.default";
        };
        credo = lib.mkOption {
          type = lib.types.nullOr lib.types.lines;
          default = null;
        };
        outfits = lib.mkOption {
          type = lib.types.attrsOf toml.type;
          default = { };
        };
        providers = lib.mkOption {
          type = lib.types.attrsOf toml.type;
          default = { };
        };
        skills = lib.mkOption {
          type = lib.types.attrsOf lib.types.path;
          default = { };
        };
      };

      config = {
        home.packages = lib.optional (cfg.package != null) cfg.package;

        xdg.configFile =
          config.flake.lib.linkDir ../config/figaro/skills "figaro/skills"
          // {
            "fish/conf.d/65-figaro-prompt.fish".source = ../config/figaro/prompt.fish;
          }
          // lib.optionalAttrs (cfg.credo != null) {
            "figaro/credo.md".text = cfg.credo;
          }
          // lib.mapAttrs' (
            name: spec:
            lib.nameValuePair "figaro/outfits/${name}.toml" {
              source = toml.generate "outfit-${name}.toml" spec;
            }
          ) cfg.outfits
          // lib.mapAttrs' (
            name: spec:
            lib.nameValuePair "figaro/providers/${name}.toml" {
              source = toml.generate "provider-${name}.toml" spec;
            }
          ) cfg.providers
          // lib.mapAttrs' (
            name: path: lib.nameValuePair "figaro/skills/${name}.md" { source = path; }
          ) cfg.skills;

        home.file.".bashrc.d/65-figaro-prompt.sh".source = ../config/figaro/prompt.bash;
      };
    };
}
