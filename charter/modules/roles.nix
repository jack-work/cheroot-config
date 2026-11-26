{ ... }:
{
  flake.modules.homeManager.figaro =
    hm@{ pkgs, lib, ... }:
    let
      cfg = hm.config.my.roles;
      figaroPkg = hm.config.my.figaro.package;
      toml = pkgs.formats.toml { };
      text = d: if builtins.isPath d then lib.removeSuffix "\n" (builtins.readFile d) else d;

      queueRoles = lib.filterAttrs (_: r: r.queue != null) cfg.roles;
      minted = lib.filterAttrs (_: r: r.form != null) cfg.roles;
      limited = [
        "strategist"
        "knight"
        "edge"
      ];
      ofSeat = seat: lib.attrNames (lib.filterAttrs (_: r: r.seat == seat) cfg.roles);
      rootForm =
        let
          kings = ofSeat "king";
        in
        if kings == [ ] then null else cfg.roles.${builtins.head kings}.form;
      takes = kind: lib.attrNames (lib.filterAttrs (_: r: lib.elem kind r.queue.kinds) queueRoles);

      faults =
        lib.concatLists (
          lib.mapAttrsToList (
            name: r:
            lib.optional (
              r.form != null && builtins.match "@([0-9a-f]{8}|[0-9a-f]{32})" r.form == null
            ) "${name}: form '${r.form}' must be @ and 8 or 32 hex digits"
            ++ map (l: "${name}: lane ${l} is a role; a lane is never a role") (
              builtins.filter (l: cfg.roles ? ${l}) (builtins.attrNames r.lanes)
            )
            ++ map (l: "${name}: lane ${l}: '${r.lanes.${l}}' is not fleet.lane.<lead>.${l}") (
              builtins.filter (l: builtins.match "fleet\\.lane\\.[a-z0-9-]+\\.${l}" r.lanes.${l} == null) (
                builtins.attrNames r.lanes
              )
            )
            ++ lib.optionals (r.queue != null) (
              lib.optional (r.queue.kinds == [ ]) "${name}: a queue takes at least one kind"
              ++ lib.optional (
                r.queue.priority && !lib.elem "review" r.queue.kinds
              ) "${name}: only the review queue is a priority map"
            )
            ++ lib.optional (
              r.fanout.min_children != null
              && r.fanout.max_children != null
              && r.fanout.min_children > r.fanout.max_children
            ) "${name}: fanout.min_children is above max_children"
            ++ lib.optional (lib.hasPrefix "reviewer" name) "${name}: reviewer roles are minted at runtime by the Inspector, never declared"
            ++
              lib.optional ((r.fanout.max_children != null || r.fanout.quota != null) && !lib.elem r.seat limited)
                "${name}: fan-out limits sit only on Knights, Strategists, reviewers and the Edge Engineer, not on a ${r.seat} seat"
            ++ lib.optional (
              r.reviewers.max_children != null && r.seat != "inspector"
            ) "${name}: only the Inspector sets the fan-out of the reviewers it mints"
            ++ lib.optional (
              lib.elem r.seat [
                "strategist"
                "knight"
                "lead"
              ]
              && r.regiment == null
            ) "${name}: a ${r.seat} belongs to a regiment"
            ++ lib.optional (
              r.reportsTo != null && !(cfg.roles ? ${r.reportsTo})
            ) "${name}: reports to ${r.reportsTo}, which the charter does not declare"
            ++ lib.optional (r.form == null && r.queue != null) "${name}: a queue needs a minted role form"
          ) cfg.roles
        )
        ++
          lib.concatMap
            (
              seat:
              lib.optional (
                builtins.length (ofSeat seat) > 1
              ) "one ${seat} seat only; declared by ${lib.concatStringsSep ", " (ofSeat seat)}"
            )
            [
              "king"
              "inspector"
              "edge"
            ]
        ++
          lib.optional (builtins.length (takes "review") > 1)
            "review requests have one home, the Inspector; taken by ${lib.concatStringsSep ", " (takes "review")}";

      claimSection =
        q:
        "## Work orders\n\n"
        + text cfg.claimRules
        + lib.optionalString q.priority ("\n\n" + text cfg.reviewRules);

      charterOf =
        r:
        let
          own = if r.charter == null then null else text r.charter;
        in
        if r.queue == null then
          own
        else
          lib.concatStringsSep "\n\n" (lib.optional (own != null) own ++ [ (claimSection r.queue) ]);

      contractOf =
        r:
        lib.filterAttrs (_: v: v != null) {
          version = "v0";
          contract = cfg.queueContract;
          inherit (r.queue) kinds priority;
          entries = "queue.<id>";
          id = "two hyphenated lowercase words, unique on the form";
          order = "priority, then state_at";
          posters-write = "queue.**";
          grant = "write:role:${r.form}#queue.**";
          states = [
            "posted"
            "claimed"
            "blocked"
            "review"
            "done"
            "cancelled"
          ];
        };

      keysOf =
        r:
        lib.filterAttrs (_: v: v != null) {
          charter = charterOf r;
          queue-contract = if r.queue == null then null else contractOf r;
          name = r.title;
          role-name = r.title;
          lanes = if r.lanes == { } then null else r.lanes;
          inherit (r) index;
          standing = if cfg.standing // r.standing == { } then null else cfg.standing // r.standing;
          orchestration = if cfg.orchestration == null then null else { policy = cfg.orchestration; };
          chartered = lib.filterAttrs (_: v: v != null) {
            inherit (r) seat regiment;
            root = rootForm;
            central-command = if r.seat == "king" then true else null;
            reports-to = if r.reportsTo == null then null else cfg.roles.${r.reportsTo}.form;
            succession-abdication = cfg.succession.abdication;
            succession-ttl = cfg.succession.ttl;
            reviewer-max-children = r.reviewers.max_children;
          };
          system =
            let
              fanout = lib.filterAttrs (_: v: v != null) { inherit (r.fanout) min_children max_children quota; };
              sys =
                lib.optionalAttrs (r.outfits != null) { grants.outfits = r.outfits; }
                // lib.optionalAttrs (fanout != { }) { inherit fanout; };
            in
            if sys == { } then null else sys;
        };

      managedOf =
        keys:
        lib.concatMap (
          k:
          if builtins.isAttrs keys.${k} then
            map (sub: "${k}.${sub}") (
              if k == "system" then
                lib.concatLists (
                  lib.mapAttrsToList (g: v: map (leaf: "${g}.${leaf}") (builtins.attrNames v)) keys.system
                )
              else
                builtins.attrNames keys.${k}
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
        }) minted;
        unminted = lib.attrNames (lib.filterAttrs (_: r: r.form == null) cfg.roles);
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
                form = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "The role form. A seat the charter declares before its form is minted has none; figaro-apply skips it and roles.json lists it as unminted.";
                };
                seat = lib.mkOption {
                  type = lib.types.enum [
                    "king"
                    "strategist"
                    "knight"
                    "lead"
                    "inspector"
                    "edge"
                    "herald"
                  ];
                  description = "What kind of seat this is; fan-out limits are allowed only on strategist, knight and edge seats.";
                };
                regiment = lib.mkOption {
                  type = lib.types.nullOr (
                    lib.types.enum [
                      "frontend"
                      "backend"
                      "figaro"
                    ]
                  );
                  default = null;
                };
                reportsTo = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "The declared role this seat reports to, written as chartered.reports-to (its form).";
                };
                reviewers.max_children = lib.mkOption {
                  type = lib.types.nullOr lib.types.ints.unsigned;
                  default = null;
                  description = "The Inspector's limit for each reviewer role it mints at runtime.";
                };
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
                fanout = {
                  min_children = lib.mkOption {
                    type = lib.types.nullOr lib.types.ints.unsigned;
                    default = null;
                    description = "system.fanout.min_children on the role: the floor its holder is meant to keep (reported short, never refused; 2026/11/26/min-children-proposal.md).";
                  };
                  max_children = lib.mkOption {
                    type = lib.types.nullOr lib.types.ints.unsigned;
                    default = null;
                    description = "system.fanout.max_children on the role: its holder is bound by it across succession.";
                  };
                  quota = lib.mkOption {
                    type = lib.types.nullOr lib.types.ints.unsigned;
                    default = null;
                    description = "system.fanout.quota on the role: a ceiling on its holder's whole subtree.";
                  };
                };
                queue = lib.mkOption {
                  default = null;
                  description = "Work orders this role's form holds under queue.<id>; its charter gains the claim rules and queue-contract describes the entries.";
                  type = lib.types.nullOr (
                    lib.types.submodule {
                      options = {
                        kinds = lib.mkOption {
                          type = lib.types.listOf (
                            lib.types.enum [
                              "work"
                              "handoff"
                              "review"
                              "deploy"
                            ]
                          );
                        };
                        priority = lib.mkOption {
                          type = lib.types.bool;
                          default = false;
                          description = "Entries are a priority map (the Inspector's review requests).";
                        };
                      };
                    }
                  );
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
        handoffRoot = lib.mkOption {
          type = lib.types.str;
          default = "${hm.config.home.homeDirectory}/.captains-log";
          description = "figaro-roles-handoff-check warns about a role whose live handoff lies outside this tree. It only reads; the charter never writes handoff.";
        };
        orchestration = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "orchestration.policy on every role.";
        };
        succession = {
          abdication = lib.mkOption {
            type = lib.types.enum [ "retire" ];
            default = "retire";
            description = "Only a succession that retires its predecessor in the same step may exceed child limits; linger never does.";
          };
          ttl = lib.mkOption {
            type = lib.types.str;
            default = "5m";
            description = "The retiring predecessor's ttl in such a succession.";
          };
        };
        queueContract = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Where the work-order contract is written; every queue role names it as queue-contract.contract.";
        };
        claimRules = lib.mkOption {
          type = lib.types.either lib.types.str lib.types.path;
          default = ''
            Work orders live on this form under queue.<id>, about 1 KB each; queue-contract names the fields.
            - An id is a handcrafted codename: two hyphenated lowercase words, unique on this form (queue.amber-falcon). Order is by priority, then state_at.
            - Anyone may post: one new queue.<id> with state posted, source, requested_by and owner. A poster writes nothing outside queue.**.
            - Only a holder of the owner role claims: one write of claimed_by {role, aria, at, lease_until} and state claimed, conditional on the version it read. If the version moved, read again and never overwrite another claim:
                v=$(figaro state show --id @<role> --version)
                figaro state show --id @<role> -j   (queue.<id>.claimed_by must be empty)
                figaro set --id @<role> --if-version "$v" queue.<id>.claimed_by '{"role": ..., "aria": ..., "at": ..., "lease_until": ...}'
              A refused write means someone else wrote first.
            - Renew the lease before lease_until. An expired lease may be claimed again.
            - The claimant alone moves the state on (blocked, review, done, cancelled) and stamps state_at.
            - The lead owns the tree: it alone writes parent, children and amendments, and amends the plan as work lands.
            - Text past an entry's size goes to body {uri, sha256, bytes}, an immutable blob; a change is a new blob.
            - attention owner means the King tells the owner.
            - done and cancelled entries leave the live state after the grace period.'';
          description = "Claim rules every queue role's charter carries under Work orders.";
        };
        reviewRules = lib.mkOption {
          type = lib.types.either lib.types.str lib.types.path;
          default = ''
            Review requests are a priority map.
            - While the Inspector is at its child limit, entries wait. Only an entry with a live reviewer carries review.reviewer_role.
            - Reviewer roles are minted here at runtime, one per review, and never declared in the charter.
            - When a review closes its reviewer retires, and the waiting entry with the highest priority gets the next reviewer.
            - Only the Knight that commissioned a review acts on its feedback; its fan-out forks may study the review.'';
          description = "Rules the priority (review) queue's charter adds.";
        };
      };

      config = lib.mkIf (cfg.roles != { }) {
        assertions = map (f: {
          assertion = false;
          message = "my.roles: ${f}";
        }) faults;

        home.packages = [
          (pkgs.callPackage ../tools/figaro-apply { })
          (pkgs.writeShellApplication {
            name = "figaro-roles-handoff-check";
            runtimeInputs = [ pkgs.jq ] ++ lib.optional (figaroPkg != null) figaroPkg;
            text = ''
              roles=''${1:-''${XDG_CONFIG_HOME:-$HOME/.config}/figaro/roles.json}
              root=${lib.escapeShellArg cfg.handoffRoot}
              jq -r '.roles[] | "\(.name) \(.form)"' "$roles" | while read -r name form; do
                handoff=$(figaro state show --id "$form" -j 2>/dev/null | jq -r '.handoff // empty') || handoff=""
                case "$handoff" in
                  "" | "$root"/*) ;;
                  *) echo "warn: $name ($form) handoff $handoff is not under $root" ;;
                esac
              done
            '';
          })
        ];

        xdg.configFile = {
          "figaro/roles.json".text = builtins.toJSON manifest;
        }
        // lib.mapAttrs' (
          name: r:
          lib.nameValuePair "figaro/outfits/role-${name}.toml" {
            source = toml.generate "outfit-role-${name}.toml" (keysOf r);
          }
        ) minted;
      };
    };
}
