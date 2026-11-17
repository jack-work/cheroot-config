{ inputs, config, ... }:
let
  rosterLib = import ../lib/roster.nix { inherit (inputs.nixpkgs) lib; };

  mkRoleSubmodule =
    lib:
    lib.types.submodule (
      { name, ... }:
      {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            default = name;
          };
          kind = lib.mkOption {
            type = lib.types.enum rosterLib.validKinds;
          };
          leader = lib.mkOption {
            type = lib.types.str;
            default = "none";
          };
          purpose = lib.mkOption {
            type = lib.types.str;
          };
          form = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          handoff = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          mantra = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          mint = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          provider = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          model = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          cacheControl = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
        };
      }
    );

  mkRosterDrv =
    {
      pkgs,
      lib,
      roster,
    }:
    let
      checked = rosterLib.validateRoster roster;
      toml = pkgs.formats.toml { };
      entries = lib.mapAttrsToList (name: role: {
        name = "${name}.toml";
        path = toml.generate "roster-${name}.toml" (rosterLib.roleToTomlAttrs name role);
      }) checked;
    in
    pkgs.linkFarm "figaro-roster" entries;

  mkRosterReconcileScript =
    {
      pkgs,
      lib,
      figaroPkg,
      rosterDir,
    }:
    pkgs.writeShellApplication {
      name = "figaro-roster-reconcile";
      runtimeInputs = lib.optional (figaroPkg != null) figaroPkg ++ [
        pkgs.python3
        pkgs.jq
      ];
      text = ''
        roster_dir="''${1:-${rosterDir}}"
        dry_run="''${FIGARO_ROSTER_DRY_RUN:-0}"
        unset FIGARO_ARIA
        python3 - "$roster_dir" "$dry_run" <<'PY'
        import json
        import pathlib
        import subprocess
        import sys
        import tomllib

        roster_dir = pathlib.Path(sys.argv[1])
        dry_run = sys.argv[2] == "1"
        files = sorted(roster_dir.glob("*.toml"))
        for f in files:
            role = tomllib.loads(f.read_text())
            name = role["name"]
            payload = {
                "name": name,
                "kind": role["kind"],
                "roster": {
                    "managed": True,
                    "purpose": role["purpose"],
                },
            }
            if role.get("leader", "none") != "none":
                payload["leader"] = role["leader"]
            if dry_run:
                print(json.dumps({"role": name, "plan": payload}))
                continue
            existing = role.get("form")
            if existing:
                for k, v in payload.items():
                    if isinstance(v, dict):
                        for sk, sv in v.items():
                            subprocess.run(["figaro", "form", "set", existing, f"{k}.{sk}", json.dumps(sv)], check=True)
                    else:
                        subprocess.run(["figaro", "form", "set", existing, k, str(v)], check=True)
        PY
      '';
    };
in
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
      toml = pkgs.formats.toml { };
      rosterDrv = mkRosterDrv {
        inherit pkgs lib;
        inherit (cfg) roster;
      };
      reconcilePkg = mkRosterReconcileScript {
        inherit pkgs lib;
        figaroPkg = cfg.package;
        rosterDir = "${rosterDrv}";
      };
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
            "system"
            "container"
          ];
          default = "none";
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
        roster = lib.mkOption {
          type = lib.types.attrsOf (mkRoleSubmodule lib);
          default = { };
        };
        managedRolesHook = {
          enable = lib.mkEnableOption "declarative figaro role-roster reconciliation hook";
        };
      };

      config = lib.mkMerge [
        (lib.mkIf (cfg.mode == "none") {
          services.figaro.enable = lib.mkDefault false;
        })
        (lib.mkIf (cfg.mode == "system") {
          services.figaro = {
            enable = true;
            package = cfg.package;
            settings = cfg.settings;
            providers = cfg.providers;
            outfits = withCredoOutfits;
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
        (lib.mkIf (cfg.roster != { }) {
          environment.etc."figaro/roster".source = rosterDrv;
        })
        (lib.mkIf cfg.managedRolesHook.enable {
          assertions = [
            {
              assertion = cfg.roster != { };
              message = "my.figaro.managedRolesHook.enable requires non-empty my.figaro.roster";
            }
          ];
          environment.systemPackages = [ reconcilePkg ];
          systemd.services.figaro-roster-reconcile = {
            description = "Reconcile declared figaro role forms";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = lib.getExe reconcilePkg;
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
      rosterDrv = mkRosterDrv {
        inherit pkgs lib;
        inherit (cfg) roster;
      };
      reconcilePkg = mkRosterReconcileScript {
        inherit pkgs lib;
        figaroPkg = cfg.package;
        rosterDir = "${rosterDrv}";
      };
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
        roster = lib.mkOption {
          type = lib.types.attrsOf (mkRoleSubmodule lib);
          default = { };
        };
        managedRolesHook.enable = lib.mkEnableOption "install figaro-roster-reconcile in user profile";
      };

      config = {
        assertions = [
          {
            assertion = !cfg.managedRolesHook.enable || cfg.roster != { };
            message = "my.figaro.managedRolesHook.enable requires non-empty my.figaro.roster";
          }
        ];

        home.packages =
          lib.optional (cfg.package != null) cfg.package
          ++ lib.optional cfg.managedRolesHook.enable reconcilePkg;

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
          ) cfg.skills
          // lib.optionalAttrs (cfg.roster != { }) {
            "figaro/roster".source = rosterDrv;
          };

        home.file.".bashrc.d/65-figaro-prompt.sh".source = ../config/figaro/prompt.bash;
      };
    };
}
