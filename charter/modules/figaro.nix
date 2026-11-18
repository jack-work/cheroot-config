{ inputs, config, ... }:
let
  rosterLib = import ../lib/roster.nix { inherit (inputs.nixpkgs) lib; };
  regimentLib = import ../lib/regiment.nix { inherit (inputs.nixpkgs) lib; };
  grantsLib = import ../lib/grants.nix { inherit (inputs.nixpkgs) lib; };

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
          quota = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.unsigned;
            default = null;
            description = ''
              How many live figaros the seat's subtree may hold, applied to its role form as
              system.fanout.quota beside max_children. Null derives it: maxChildren times one
              plus the quota childPolicy gives each child (0 unless set), so a seat whose lanes
              cannot fork is held to maxChildren lanes. A fleet seat derives none: it reaps for
              the others, so its quota is only ever set by hand.
            '';
          };
          reach = lib.mkOption {
            type = lib.types.enum grantsLib.reaches;
            default = "lineage";
            description = ''
              How far the holder's demote, promote, retire and kill reach. lineage writes no
              system.scopes, so the holder keeps every verb but topology stays in its own
              subtree. fleet writes system.scopes = ["*:*"] on the holder: every verb on every
              figaro, which is the grant that reaps other seats' figaros.
            '';
          };
          reportsTo = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = ''
              Roles the seat's lanes may message, besides their parent and this seat's own role.
              Rendered into the holder's system.child_policy as send:role:<form>, so the grant
              follows each role through succession.
            '';
          };
          childPolicy = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
            description = ''
              Further key paths for the holder's system.child_policy (a lane's
              system.fanout.quota, say). The rendered system.scopes is replaced if named here.
            '';
          };
          companionOf = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              The seat whose holder also holds this role. A companion carries no fork limit,
              quota or grants: the holder is capped by the smallest limit across the role forms
              it holds, and its grants live on the holder, so they come from the primary seat.
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
          fields = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
            description = ''
              Further keys of the role form, applied by figaro-apply-roles through the outfit
              role-<name>-fields; each top-level key is one managed path. Keys with their own
              option (charter, system) and keys the daemon holds are refused.
            '';
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

  mkKindOption =
    lib:
    {
      maxChildren,
      reach ? "lineage",
      reportsTo ? [ ],
    }:
    lib.mkOption {
      default = { };
      type = lib.types.submodule {
        options = {
          provider = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          model = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          maxChildren = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.unsigned;
            default = maxChildren;
            description = "Fork limit, applied as system.fanout.max_children on the seat's role form.";
          };
          quota = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.unsigned;
            default = null;
            description = "system.fanout.quota of the seat's role form; null derives it from maxChildren, as for a roster role.";
          };
          reach = lib.mkOption {
            type = lib.types.enum grantsLib.reaches;
            default = reach;
            description = "The seat holder's topology reach, as for a roster role.";
          };
          reportsTo = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = reportsTo;
            description = ''
              Whom the seat's lanes may message besides their parent and the seat's own role:
              a seat kind of this regiment (strategist, knight, steward) or a declared role.
              A kind whose seat has no form yet is skipped.
            '';
          };
          childPolicy = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
            description = "Further key paths for the holder's system.child_policy.";
          };
        };
      };
    };

  mkRegimentSubmodule =
    lib:
    lib.types.submodule {
      options = {
        leader = lib.mkOption {
          type = lib.types.str;
          default = "none";
          description = "The role every seat reports to: a declared role or another regiment's seat.";
        };
        mode = lib.mkOption {
          type = lib.types.enum [
            "check"
            "apply"
          ];
          default = "check";
        };
        seats = lib.mkOption {
          description = ''
            The standing seats, keyed by role name: exactly one strategist, one knight and
            one steward. Reviewers are never seats; they are forks dressed in
            regiment-<regiment>-reviewer. A seat with a form is adopted in place and its
            managed keys are applied; a seat without one renders only role-<seat>-mint,
            the outfit to mint its role form from.
          '';
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                kind = lib.mkOption { type = lib.types.enum regimentLib.seatKinds; };
                title = lib.mkOption {
                  type = lib.types.str;
                  description = "The role form's name and role-name.";
                };
                purpose = lib.mkOption { type = lib.types.str; };
                form = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                charter = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                handoff = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Handoff path. The daemon holds the handoff key, so it reaches only a minted form.";
                };
                mantra = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
              };
            }
          );
        };
        kinds = {
          strategist = mkKindOption lib {
            maxChildren = 6;
            reportsTo = [
              "knight"
              "steward"
            ];
          };
          knight = mkKindOption lib {
            maxChildren = 1;
            reach = "fleet";
            reportsTo = [ "strategist" ];
          };
          steward = mkKindOption lib {
            maxChildren = 3;
            reach = "fleet";
            reportsTo = [
              "strategist"
              "knight"
            ];
          };
          reviewer = mkKindOption lib { maxChildren = null; };
        };
        reviewer = {
          ttl = lib.mkOption {
            type = lib.types.str;
            default = "4h";
            description = "system.ttl of a reviewer fork.";
          };
          retireTtl = lib.mkOption {
            type = lib.types.str;
            default = "10m";
          };
        };
        orchestration = lib.mkOption {
          type = lib.types.str;
          default = "Classify every dispatched child as one-off tail fork or continuing owner. One-offs need an explicit bounded deliverable, parent, completion criterion and finite TTL. Preserve outcomes/evidence/open obligations in dated captains-log entries, then retire with a short TTL, normally 10m, after accepted handoff. Do not retire active work or current role holders blindly. Parent owns child inventory and integration: keep active forks manageable, avoid duplicate owners and unbounded recursive fan-out, but delegate independent work when it removes a real bottleneck. Include this rule in handoffs, successors and child prompts. No standing role for a one-off.";
          description = "orchestration.policy of every seat.";
        };
        agreement = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = ''
            The working agreement, one clause per item, applied as regiment.agreement on
            every seat and carried by reviewers. {strategist}, {knight}, {steward},
            {reviewer-outfit} and {retire-ttl} are replaced.
          '';
          default = [
            "{strategist} builds the whole plan with transient forks and keeps the final vision. It restacks the work into incremental, non-conflicting commits for {knight}, and again as {knight} lands fixes on main. A hard rejection sends that part back to {strategist}, not into patch-on-patch."
            "{knight} carries only mutually non-conflicting changes at a time, produces the validated build of each and asks {steward} for a reviewer. It never merges to main."
            "{knight} and {strategist} talk directly with figaro send -f: {strategist} warns of anything found in later parts before {knight} reaches them; {knight} asks when a review makes a part unclear."
            "{steward} mints one reviewer per change as a turn-1 fork of {strategist} dressed in {reviewer-outfit}, points it at the validated build, relays the verdict and retires it."
            "Fan-out forks and reviewers are transient: finite system.ttl, never seats, retired with --ttl {retire-ttl} once their harvest (what they did, branch and sha, evidence, open obligations, lessons) is in a dated captains-log entry."
            "Ask your parent for quota before you need it, in one line: what for, how many, how long."
          ];
        };
        successionLayers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "succession-standard" ];
          description = "Outfits role-<seat>-mint is layered on, for its succession policy.";
        };
        successorBase = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "default"
            "succession-standard"
          ];
          description = "Outfits a successor is minted in, before regiment-<regiment>-<kind>.";
        };
      };
    };

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
      regiments = regimentLib.render cfg.roster cfg.regiments;
      roster = lib.mapAttrs (_: withHouseFields) (cfg.roster // regiments.roster);
      withHouseFields =
        r:
        if cfg.fanoutWhenFull == null || r.form == null then
          r
        else
          r
          // {
            fields = r.fields // {
              fanout = (r.fields.fanout or { }) // {
                when-full = cfg.fanoutWhenFull;
              };
            };
          };
      rosterDrv = mkRosterDrv {
        inherit pkgs lib roster;
      };
      reconcilePkg = mkRosterReconcileScript {
        inherit pkgs lib;
        figaroPkg = cfg.package;
        rosterDir = "${rosterDrv}";
      };
      checkedRoster = rosterLib.validateRoster roster;
      authority = lib.filterAttrs (_: a: a != null) (
        lib.mapAttrs (rosterLib.authorityOf checkedRoster) checkedRoster
      );
      applied = lib.filterAttrs (
        n: r: r.charter != null || r.maxChildren != null || r.fields != { } || authority ? ${n}
      ) checkedRoster;
      charterOutfit = name: "role-${name}-charter";
      fanoutOutfit = name: "role-${name}-fanout";
      fieldsOutfit = name: "role-${name}-fields";
      grantsOutfit = name: "role-${name}-grants";
      fanoutOf =
        name: role:
        lib.filterAttrs (_: v: v != null) {
          max_children = role.maxChildren;
          quota = authority.${name}.quota or null;
        };
      managedRoles = lib.filterAttrs (n: r: r.charter != null || fanoutOf n r != { } || r.fields != { }) applied;
      manifest = toml.generate "figaro-roles.toml" {
        roles = lib.mapAttrs (name: role: {
          id = role.form;
          outfits =
            lib.optional (role.charter != null) (charterOutfit name)
            ++ lib.optional (fanoutOf name role != { }) (fanoutOutfit name)
            ++ lib.optional (role.fields != { }) (fieldsOutfit name);
          managed =
            lib.optional (role.charter != null) "charter"
            ++ lib.optional (role.maxChildren != null) "system.fanout.max_children"
            ++ lib.optional ((authority.${name}.quota or null) != null) "system.fanout.quota"
            ++ builtins.attrNames role.fields;
          inherit (role) mode;
        }) managedRoles;
      };
      seats = pkgs.writeText "figaro-seats.json" (
        builtins.toJSON (
          lib.mapAttrs (name: a: {
            form = applied.${name}.form;
            inherit (applied.${name}) mode;
            outfit = if a.scopes == null then null else grantsOutfit name;
            grants = grantsLib.toFormKeys a;
          }) authority
        )
      );
      applyRoles = pkgs.writeShellApplication {
        name = "figaro-apply-roles";
        runtimeInputs = [ pkgs.python3 ];
        text = ''
          ${lib.optionalString (
            cfg.roleRuntimeDir != null
          ) "export FIGARO_RUNTIME_DIR=${lib.escapeShellArg cfg.roleRuntimeDir}"}
          export FIGARO_APPLY_BIN=${
            if cfg.package != null then lib.getExe' cfg.package "figaro" else "figaro"
          }
          export FIGARO_APPLY_MANIFEST=${manifest} FIGARO_APPLY_SEATS=${seats}
          exec python3 ${../lib/apply-roles.py} "$@"
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
        fanoutWhenFull = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "What a seat does when fan-out refuses it, applied to every seat with a form as the managed key fanout.when-full.";
        };
        regiments = lib.mkOption {
          type = lib.types.attrsOf (mkRegimentSubmodule lib);
          default = { };
          description = ''
            Regiments: a strategist, a knight and a steward with a pool of transient reviewers,
            bound by a working agreement. Each seat joins the roster as a role and is applied
            by figaro-apply-roles like any other; each regiment also renders the outfits
            regiment-<regiment>-<kind> (provider and model of a holder, or of a reviewer fork)
            and role-<seat>-mint.
          '';
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
            assertion = !cfg.managedRolesHook.enable || roster != { };
            message = "my.figaro.managedRolesHook.enable requires non-empty my.figaro.roster";
          }
        ]
        ++ map (n: {
          assertion = builtins.match "@([0-9a-f]{8}|[0-9a-f]{32})" (roster.${n}.form or "") != null;
          message = "my.figaro.roster.${n}: a charter, fork limit or field applies only to an exact form, @ and 8 or 32 hex digits";
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
          // lib.optionalAttrs (roster != { }) {
            "figaro/roster".source = rosterDrv;
          }
          // lib.mapAttrs' (
            name: spec:
            lib.nameValuePair "figaro/outfits/${name}.toml" {
              source = toml.generate "outfit-${name}.toml" spec;
            }
          ) regiments.outfits
          // lib.mapAttrs' (
            name: role:
            lib.nameValuePair "figaro/outfits/${fieldsOutfit name}.toml" {
              source = toml.generate "outfit-${fieldsOutfit name}.toml" role.fields;
            }
          ) (lib.filterAttrs (_: r: r.fields != { }) applied)
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
                system.fanout = fanoutOf name role;
              };
            }
          ) (lib.filterAttrs (n: r: fanoutOf n r != { }) applied)
          // lib.mapAttrs' (
            name: a:
            lib.nameValuePair "figaro/outfits/${grantsOutfit name}.toml" {
              source = toml.generate "outfit-${grantsOutfit name}.toml" { system.scopes = a.scopes; };
            }
          ) (lib.filterAttrs (_: a: a.scopes != null) authority);

        home.file.".bashrc.d/65-figaro-prompt.sh".source = ../config/figaro/prompt.bash;
      };
    };
}
