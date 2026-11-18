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
          maxChildren = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.unsigned;
            default = null;
            description = ''
              Fork limit of this seat, applied to its role form as the managed key
              system.fanout.max_children. Null leaves the key alone, so a seat that a
              holder shares with a role it must not cap stays unset. A holder is capped
              by the smallest limit across the role forms it holds.
            '';
          };
          forward = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Old names of a renamed role that keep reaching its holder until forwardUntil.";
          };
          forwardUntil = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          charter = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "The role form's charter, applied by figaro-apply-roles to the exact form.";
          };
          mode = lib.mkOption {
            type = lib.types.enum [
              "check"
              "apply"
            ];
            default = "check";
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
        path = toml.generate "roster-${name}.toml" (rosterLib.roleToTomlAttrs checked name role);
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
            if role.get("leader_form"):
                payload["leader"] = role["leader_form"]
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
      applied = lib.filterAttrs (_: r: r.charter != null || r.maxChildren != null) (
        rosterLib.validateRoster cfg.roster
      );
      charterOutfit = name: "role-${name}-charter";
      fanoutOutfit = name: "role-${name}-fanout";
      manifest = toml.generate "figaro-roles.toml" {
        roles = lib.mapAttrs (name: role: {
          id = role.form;
          outfits =
            lib.optional (role.charter != null) (charterOutfit name)
            ++ lib.optional (role.maxChildren != null) (fanoutOutfit name);
          managed =
            lib.optional (role.charter != null) "charter"
            ++ lib.optional (role.maxChildren != null) "system.fanout.max_children";
          inherit (role) mode;
        }) applied;
      };
      applyRoles = pkgs.writeShellApplication {
        name = "figaro-apply-roles";
        text = ''
          unset FIGARO_ARIA FIGARO_TROUPE
          ${lib.optionalString (
            cfg.roleRuntimeDir != null
          ) "export FIGARO_RUNTIME_DIR=${lib.escapeShellArg cfg.roleRuntimeDir}"}
          exec ${
            if cfg.package != null then lib.getExe' cfg.package "figaro" else "figaro"
          } form apply --manifest ${manifest} "$@"
        '';
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
        roleRuntimeDir = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Runtime directory of the daemon figaro-apply-roles addresses; null keeps figaro's default.";
        };
      };

      config = {
        assertions = [
          {
            assertion = !cfg.managedRolesHook.enable || cfg.roster != { };
            message = "my.figaro.managedRolesHook.enable requires non-empty my.figaro.roster";
          }
        ]
        ++ map (n: {
          assertion = builtins.match "@([0-9a-f]{8}|[0-9a-f]{32})" (cfg.roster.${n}.form or "") != null;
          message = "my.figaro.roster.${n}: a charter or fork limit applies only to an exact form, @ and 8 or 32 hex digits";
        }) (builtins.attrNames applied);

        home.packages =
          lib.optional (cfg.package != null) cfg.package
          ++ lib.optional cfg.managedRolesHook.enable reconcilePkg
          ++ lib.optional (applied != { }) applyRoles;

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
          }
          // lib.mapAttrs' (
            name: role:
            lib.nameValuePair "figaro/outfits/${charterOutfit name}.toml" {
              source = toml.generate "outfit-${charterOutfit name}.toml" { inherit (role) charter; };
            }
          ) (lib.filterAttrs (_: r: r.charter != null) applied)
          // lib.mapAttrs' (
            name: role:
            lib.nameValuePair "figaro/outfits/${fanoutOutfit name}.toml" {
              source = toml.generate "outfit-${fanoutOutfit name}.toml" {
                system.fanout.max_children = role.maxChildren;
              };
            }
          ) (lib.filterAttrs (_: r: r.maxChildren != null) applied);

        home.file.".bashrc.d/65-figaro-prompt.sh".source = ../config/figaro/prompt.bash;
      };
    };
}
