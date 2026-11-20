{ ... }:
{
  flake.modules.homeManager.figaro =
    hm@{ pkgs, lib, ... }:
    let
      cfg = hm.config.my.roles;
      figaroPkg = hm.config.my.figaro.package;
      toml = pkgs.formats.toml { };
      text = d: if builtins.isPath d then lib.removeSuffix "\n" (builtins.readFile d) else d;

      faults = lib.concatLists (
        lib.mapAttrsToList (
          name: r:
          lib.optional (
            builtins.match "@([0-9a-f]{8}|[0-9a-f]{32})" r.form == null
          ) "${name}: form '${r.form}' must be @ and 8 or 32 hex digits"
          ++ map (l: "${name}: lane ${l} is a role; a lane is never a role") (
            builtins.filter (l: cfg.roles ? ${l}) (builtins.attrNames r.lanes)
          )
          ++ map (l: "${name}: lane ${l}: '${r.lanes.${l}}' is not fleet.lane.<lead>.${l}") (
            builtins.filter (l: builtins.match "fleet\\.lane\\.[a-z0-9-]+\\.${l}" r.lanes.${l} == null) (
              builtins.attrNames r.lanes
            )
          )
        ) cfg.roles
      );

      keysOf =
        r:
        lib.filterAttrs (_: v: v != null) {
          charter = if r.charter == null then null else text r.charter;
          name = r.title;
          role-name = r.title;
          lanes = if r.lanes == { } then null else r.lanes;
          inherit (r) index;
          standing = if cfg.standing // r.standing == { } then null else cfg.standing // r.standing;
          orchestration = if cfg.orchestration == null then null else { policy = cfg.orchestration; };
          system = if r.outfits == null then null else { grants.outfits = r.outfits; };
        };

      managedOf =
        keys:
        lib.concatMap (
          k:
          if builtins.isAttrs keys.${k} then
            map (sub: "${k}.${sub}") (
              if k == "system" then [ "grants.outfits" ] else builtins.attrNames keys.${k}
            )
          else
            [ k ]
        ) (builtins.attrNames keys);

      manifest = {
        figaro = if figaroPkg == null then "" else lib.getExe' figaroPkg "figaro";
        roles = lib.mapAttrsToList (name: r: {
          inherit name;
          inherit (r) form;
          outfits = [ "role-${name}" ];
          managed = managedOf (keysOf r);
        }) cfg.roles;
      };
    in
    {
      options.my.roles = {
        roles = lib.mkOption {
          default = { };
          description = "Every role figaro-apply keeps; anything else is a lane, never a role.";
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                form = lib.mkOption { type = lib.types.str; };
                title = lib.mkOption { type = lib.types.str; };
                charter = lib.mkOption {
                  type = lib.types.nullOr (lib.types.either lib.types.str lib.types.path);
                  default = null;
                };
                outfits = lib.mkOption {
                  type = lib.types.nullOr (lib.types.listOf lib.types.str);
                  default = null;
                  description = "Outfits the role's figaros may dress in, as system.grants.outfits.";
                };
                lanes = lib.mkOption {
                  type = lib.types.attrsOf lib.types.str;
                  default = { };
                  description = "Lane name to its captains-log index, written as lanes.<name>.";
                };
                index = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "The role's own captains-log index, for a role with no lanes.";
                };
                standing = lib.mkOption {
                  type = lib.types.attrsOf lib.types.str;
                  default = { };
                };
              };
            }
          );
        };
        standing = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "standing.<name> on every role; a role's own wins by name.";
        };
        orchestration = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "orchestration.policy on every role.";
        };
      };

      config = lib.mkIf (cfg.roles != { }) {
        assertions = map (f: {
          assertion = false;
          message = "my.roles: ${f}";
        }) faults;

        home.packages = [ (pkgs.callPackage ../tools/figaro-apply { }) ];

        xdg.configFile = {
          "figaro/roles.json".text = builtins.toJSON manifest;
        }
        // lib.mapAttrs' (
          name: r:
          lib.nameValuePair "figaro/outfits/role-${name}.toml" {
            source = toml.generate "outfit-role-${name}.toml" (keysOf r);
          }
        ) cfg.roles;
      };
    };
}
