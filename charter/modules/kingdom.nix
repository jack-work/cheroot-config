{ inputs, ... }:
let
  kingdomLib = import ../lib/kingdom.nix { inherit (inputs.nixpkgs) lib; };
  grantsLib = import ../lib/grants.nix { inherit (inputs.nixpkgs) lib; };
in
{
  flake.lib.kingdom = kingdomLib;

  flake.modules.homeManager.figaro =
    hm@{ pkgs, lib, ... }:
    let
      cfg = hm.config.my.kingdom;
      figaroPkg = hm.config.my.figaro.package;
      toml = pkgs.formats.toml { };

      expanded = kingdomLib.expand { inherit (cfg) root seats; };
      regiments = kingdomLib.regimentsOf expanded;
      regimentOutfits = lib.foldl' (acc: r: acc // kingdomLib.regimentOutfits r) { } (
        lib.attrValues regiments
      );

      standingOf = s: if s.role == null then { } else cfg.standing // s.standing;
      partialKeys = [
        "standing"
        "orchestration"
        "lanes"
      ];
      managedFields =
        fields:
        builtins.filter (k: !(builtins.elem k partialKeys)) (builtins.attrNames fields)
        ++ lib.concatMap (
          k: map (sub: "${k}.${sub}") (builtins.attrNames (fields.${k} or { }))
        ) partialKeys;

      seats = lib.mapAttrs (
        _: s:
        let
          titled = lib.optionalAttrs (s.title != null) {
            name = s.title;
            role-name = s.title;
          };
          whenFull = lib.optionalAttrs (cfg.whenFull != null && s.role != null) {
            fanout = (s.fields.fanout or { }) // {
              when-full = cfg.whenFull;
            };
          };
          standing = lib.optionalAttrs (standingOf s != { }) { standing = standingOf s; };
          orchestration = lib.optionalAttrs (cfg.orchestration != null && s.role != null) {
            orchestration = (s.fields.orchestration or { }) // {
              policy = cfg.orchestration;
            };
          };
          lanes = lib.optionalAttrs (s.lanes != { }) { inherit (s) lanes; };
        in
        s
        // {
          fields = s.fields // titled // whenFull // standing // orchestration // lanes;
        }
      ) expanded;

      roster = pkgs.linkFarm "figaro-roster" (
        lib.mapAttrsToList (name: s: {
          name = "${name}.toml";
          path = toml.generate "roster-${name}.toml" (kingdomLib.rosterEntry seats name s);
        }) seats
      );

      authority = lib.filterAttrs (_: a: a != null) (lib.mapAttrs (kingdomLib.authorityOf seats) seats);
      applied = lib.filterAttrs (
        n: s:
        s.duty != null
        || s.limit.children != null
        || s.fields != { }
        || s.outfits != null
        || authority ? ${n}
      ) seats;

      charterOutfit = name: "role-${name}-charter";
      fanoutOutfit = name: "role-${name}-fanout";
      fieldsOutfit = name: "role-${name}-fields";
      grantsOutfit = name: "role-${name}-grants";
      outfitsOutfit = name: "role-${name}-outfits";

      fanoutOf =
        name: s:
        lib.filterAttrs (_: v: v != null) {
          max_children = s.limit.children;
          quota = authority.${name}.quota or null;
        };

      manifest = toml.generate "figaro-roles.toml" {
        roles =
          lib.mapAttrs
            (name: s: {
              id = s.role;
              outfits =
                lib.optional (s.duty != null) (charterOutfit name)
                ++ lib.optional (fanoutOf name s != { }) (fanoutOutfit name)
                ++ lib.optional (s.fields != { }) (fieldsOutfit name)
                ++ lib.optional (s.outfits != null) (outfitsOutfit name);
              managed =
                lib.optional (s.duty != null) "charter"
                ++ lib.optional (s.limit.children != null) "system.fanout.max_children"
                ++ lib.optional ((authority.${name}.quota or null) != null) "system.fanout.quota"
                ++ lib.optionals (s.primary != null) [
                  "system.fanout.max_children"
                  "system.fanout.quota"
                ]
                ++ lib.optional (s.outfits != null) "system.grants.outfits"
                ++ managedFields s.fields;
              inherit (s) mode;
            })
            (
              lib.filterAttrs (
                n: s: s.duty != null || fanoutOf n s != { } || s.fields != { } || s.outfits != null
              ) applied
            );
      };

      seatsJson = pkgs.writeText "figaro-seats.json" (
        builtins.toJSON (
          lib.mapAttrs (name: a: {
            form = applied.${name}.role;
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
            cfg.runtimeDir != null
          ) "export FIGARO_RUNTIME_DIR=${lib.escapeShellArg cfg.runtimeDir}"}
          export FIGARO_APPLY_BIN=${if figaroPkg != null then lib.getExe' figaroPkg "figaro" else "figaro"}
          export FIGARO_APPLY_MANIFEST=${manifest} FIGARO_APPLY_SEATS=${seatsJson}
          exec python3 ${../lib/apply-roles.py} "$@"
        '';
      };

      outfitFile = name: spec: {
        "figaro/outfits/${name}.toml".source = toml.generate "outfit-${name}.toml" spec;
      };
      outfitFiles =
        sel: render: set:
        lib.concatMapAttrs (n: x: outfitFile (sel n) (render x)) set;
    in
    {
      options.my.kingdom = {
        root = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "The seat every other seat answers to unless it names a leader.";
        };
        seats = lib.mkOption {
          type = lib.types.lazyAttrsOf (lib.types.uniq lib.types.raw);
          default = { };
          description = ''
            The roster: seats made with kingdom.seat and regiments with kingdom.regiment,
            keyed by seat name. A seat name defined twice is an error.
          '';
        };
        standing = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = ''
            Standing orders every seat with a role carries, each applied as the managed key
            standing.<name>; a seat's own standing wins by name. Other standing keys on a form
            are left alone.
          '';
        };
        orchestration = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "orchestration.policy of every seat with a role, a regiment's own included.";
        };
        whenFull = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "What a seat does when fan-out refuses it, applied to every seat with a role as the managed key fanout.when-full.";
        };
        runtimeDir = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Runtime directory of the daemon figaro-apply-roles addresses; null keeps figaro's default.";
        };
      };

      config = lib.mkIf (cfg.seats != { }) {
        home.packages = lib.optional (applied != { }) applyRoles;

        xdg.configFile = {
          "figaro/roster".source = roster;
        }
        // lib.concatMapAttrs outfitFile regimentOutfits
        // outfitFiles fieldsOutfit (s: s.fields) (lib.filterAttrs (_: s: s.fields != { }) applied)
        // outfitFiles charterOutfit (s: { charter = s.duty; }) (
          lib.filterAttrs (_: s: s.duty != null) applied
        )
        // lib.concatMapAttrs (n: s: outfitFile (fanoutOutfit n) { system.fanout = fanoutOf n s; }) (
          lib.filterAttrs (n: s: fanoutOf n s != { }) applied
        )
        // outfitFiles outfitsOutfit (s: { system.grants.outfits = s.outfits; }) (
          lib.filterAttrs (_: s: s.outfits != null) applied
        )
        // outfitFiles grantsOutfit (a: { system.scopes = a.scopes; }) (
          lib.filterAttrs (_: a: a.scopes != null) authority
        );
      };
    };
}
