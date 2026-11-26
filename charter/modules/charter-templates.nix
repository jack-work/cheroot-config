{ ... }:
{
  flake.modules.homeManager.figaro =
    hm@{ lib, ... }:
    let
      cfg = hm.config.my.charter;

      seat =
        extra:
        lib.types.submodule {
          options = {
            form = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            title = lib.mkOption { type = lib.types.str; };
            charter = lib.mkOption {
              type = lib.types.nullOr (lib.types.either lib.types.str lib.types.path);
              default = null;
            };
            outfits = lib.mkOption {
              type = lib.types.nullOr (lib.types.listOf lib.types.str);
              default = null;
            };
            lanes = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
            };
            index = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            standing = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
            };
          }
          // extra;
        };

      limits = {
        fanout = {
          min_children = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.unsigned;
            default = null;
          };
          max_children = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.unsigned;
            default = null;
          };
          quota = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.unsigned;
            default = null;
          };
        };
      };

      floor = {
        fanout.min_children = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.unsigned;
          default = null;
        };
      };

      queueForm =
        title:
        lib.types.submodule {
          options = {
            form = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            title = lib.mkOption {
              type = lib.types.str;
              default = title;
            };
          };
        };

      roleOf =
        s: extra:
        {
          inherit (s)
            form
            title
            charter
            outfits
            lanes
            index
            standing
            ;
        }
        // extra;

      kingName = "central-command";

      regimentRoles = lib.concatMapAttrs (name: r: {
        "${name}-lead" = roleOf r.lead {
          seat = "lead";
          regiment = name;
          reportsTo = kingName;
          fanout.min_children = r.lead.fanout.min_children;
        };
        "${name}-strategist" = roleOf r.strategist {
          seat = "strategist";
          regiment = name;
          reportsTo = "${name}-lead";
          inherit (r.strategist) fanout;
        };
        "${name}-knight" = roleOf r.knight {
          seat = "knight";
          regiment = name;
          reportsTo = "${name}-lead";
          inherit (r.knight) fanout;
        };
      }) cfg.regiments;

      regimentForms = lib.concatMapAttrs (name: r: {
        "${name}-handoff" = {
          inherit (r.handoff) form title;
          under = "${name}-lead";
          studiedBy = [ "${name}-knight" ];
          kinds = [
            "work"
            "handoff"
          ];
        };
      }) cfg.regiments;
    in
    {
      options.my.charter = {
        centralCommand = lib.mkOption {
          type = lib.types.nullOr (seat floor);
          default = null;
          description = "The King's seat, the root of central command: every regiment lead, the Inspector and the Edge Engineer are drawn under it.";
        };
        regiments = lib.mkOption {
          default = { };
          description = "Persistent regiments, each the same shape: a lead with a Strategist and a Knight drawn under it, and a handoff form the Knight studies.";
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                options = {
                  lead = lib.mkOption { type = seat floor; };
                  strategist = lib.mkOption { type = seat limits; };
                  knight = lib.mkOption { type = seat limits; };
                  handoff = lib.mkOption {
                    type = queueForm "${name} handoff";
                    default = { };
                  };
                };
              }
            )
          );
        };
        inspector = lib.mkOption {
          default = null;
          description = "The Inspector: studies the inspector form (as does the King) and leases reviewers under itself on demand.";
          type = lib.types.nullOr (
            lib.types.submodule {
              options = {
                seat = lib.mkOption { type = seat floor; };
                form = lib.mkOption {
                  type = queueForm "inspector form";
                  default = { };
                };
                reviewers.max_children = lib.mkOption {
                  type = lib.types.nullOr lib.types.ints.unsigned;
                  default = null;
                };
              };
            }
          );
        };
        edge = lib.mkOption {
          default = null;
          description = "The Edge Engineer: studies the one deploy form every regiment posts to, and fans out edge forks.";
          type = lib.types.nullOr (
            lib.types.submodule {
              options = {
                seat = lib.mkOption { type = seat limits; };
                deploy = lib.mkOption {
                  type = queueForm "deploy form";
                  default = { };
                };
              };
            }
          );
        };
      };

      config = lib.mkIf (cfg.centralCommand != null) {
        my.roles.roles =
          {
            ${kingName} = roleOf cfg.centralCommand {
              seat = "king";
              fanout.min_children = cfg.centralCommand.fanout.min_children;
            };
          }
          // regimentRoles
          // lib.optionalAttrs (cfg.inspector != null) {
            inspector = roleOf cfg.inspector.seat {
              seat = "inspector";
              reportsTo = kingName;
              fanout.min_children = cfg.inspector.seat.fanout.min_children;
              inherit (cfg.inspector) reviewers;
            };
          }
          // lib.optionalAttrs (cfg.edge != null) {
            edge-engineer = roleOf cfg.edge.seat {
              seat = "edge";
              reportsTo = kingName;
              inherit (cfg.edge.seat) fanout;
            };
          };

        my.roles.forms =
          regimentForms
          // lib.optionalAttrs (cfg.inspector != null) {
            inspector = {
              inherit (cfg.inspector.form) form title;
              under = "inspector";
              studiedBy = [
                "inspector"
                kingName
              ];
              kinds = [ "review" ];
              priority = true;
            };
          }
          // lib.optionalAttrs (cfg.edge != null) {
            deploy = {
              inherit (cfg.edge.deploy) form title;
              under = "edge-engineer";
              studiedBy = [ "edge-engineer" ];
              kinds = [ "deploy" ];
            };
          };
      };
    };
}
