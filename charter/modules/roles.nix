{ ... }:
{
  flake.modules.homeManager.figaro =
    hm@{ pkgs, lib, ... }:
    let
      cfg = hm.config.my.roles;
      figaroPkg = hm.config.my.figaro.package;
      toml = pkgs.formats.toml { };
      text = d: if builtins.isPath d then lib.removeSuffix "\n" (builtins.readFile d) else d;

      formsOf = name: lib.filterAttrs (_: f: lib.elem name f.studiedBy) cfg.forms;
      formIds = fs: builtins.filter (v: v != null) (lib.mapAttrsToList (_: f: f.form) fs);
      minted = lib.filterAttrs (_: r: r.form != null) cfg.roles;
      mintedForms = lib.filterAttrs (_: f: f.form != null) cfg.forms;
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
      takes = kind: lib.attrNames (lib.filterAttrs (_: f: lib.elem kind f.kinds) cfg.forms);

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
        ++ lib.concatLists (
          lib.mapAttrsToList (
            name: f:
            lib.optional (
              f.form != null && builtins.match "@([0-9a-f]{8}|[0-9a-f]{32})" f.form == null
            ) "form ${name}: '${f.form}' must be @ and 8 or 32 hex digits"
            ++ lib.optional (f.kinds == [ ]) "form ${name}: a queue takes at least one kind"
            ++ lib.optional (f.priority && !lib.elem "review" f.kinds) "form ${name}: only the review queue is a priority map"
            ++ lib.optional (!(cfg.roles ? ${f.under})) "form ${name}: drawn under ${f.under}, which the charter does not declare"
            ++ map (r: "form ${name}: studied by ${r}, which the charter does not declare") (
              builtins.filter (r: !(cfg.roles ? ${r})) f.studiedBy
            )
            ++ lib.optional (f.studiedBy == [ ]) "form ${name}: nobody studies it, so nobody claims from it"
          ) cfg.forms
        )
        ++
          lib.optional (builtins.length (takes "review") > 1)
            "review requests have one home, the Inspector; taken by ${lib.concatStringsSep ", " (takes "review")}";

      claimSection =
        priority:
        "## Work orders\n\n"
        + text cfg.claimRules
        + lib.optionalString priority ("\n\n" + text cfg.reviewRules);

      charterOf =
        name: r:
        let
          own = if r.charter == null then null else text r.charter;
          studied = formsOf name;
        in
        if studied == { } then
          own
        else
          lib.concatStringsSep "\n\n" (
            lib.optional (own != null) own
            ++ [ (claimSection (lib.any (f: f.priority) (lib.attrValues studied))) ]
          );

      contractOf =
        f:
        lib.filterAttrs (_: v: v != null) {
          version = "v0";
          contract = cfg.queueContract;
          inherit (f) kinds priority;
          entries = "queue.<id>";
          id = "two hyphenated lowercase words, unique on the form";
          order = "priority, then state_at";
          posters-write = "queue.**";
          states = [
            "posted"
            "claimed"
            "blocked"
            "review"
            "done"
            "cancelled"
          ];
        };

      shortHistory.system.history = "short";

      formKeysOf = f: {
        name = f.title;
        inherit (shortHistory) system;
        queue-contract = contractOf f;
        chartered = lib.filterAttrs (_: v: v != null) {
          kind = "queue-form";
          root = rootForm;
          under = cfg.roles.${f.under}.form or null;
        };
      };

      keysOf =
        name: r:
        lib.filterAttrs (_: v: v != null) {
          charter = charterOf name r;
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
            studies = if formIds (formsOf name) == [ ] then null else formIds (formsOf name);
          };
          system =
            let
              fanout = lib.filterAttrs (_: v: v != null) { inherit (r.fanout) min_children max_children quota; };
            in
            shortHistory.system
            // lib.optionalAttrs (r.outfits != null) { grants.outfits = r.outfits; }
            // lib.optionalAttrs (fanout != { }) { inherit fanout; };
        };

      managedOf =
        keys:
        lib.concatMap (
          k:
          if builtins.isAttrs keys.${k} then
            map (sub: "${k}.${sub}") (
              if k == "system" then
                lib.concatLists (
                  lib.mapAttrsToList (
                    g: v: if builtins.isAttrs v then map (leaf: "${g}.${leaf}") (builtins.attrNames v) else [ g ]
                  ) keys.system
                )
              else
                builtins.attrNames keys.${k}
            )
          else
            [ k ]
        ) (builtins.attrNames keys);

      manifest = {
        figaro = if figaroPkg == null then "" else lib.getExe' figaroPkg "figaro";
        roles =
          lib.mapAttrsToList (name: r: {
            inherit name;
            inherit (r) form;
            outfits = [ "role-${name}" ];
            managed = managedOf (keysOf name r);
          }) minted
          ++ lib.mapAttrsToList (name: f: {
            name = "form-${name}";
            inherit (f) form;
            outfits = [ "role-form-${name}" ];
            managed = managedOf (formKeysOf f);
          }) mintedForms;
        unminted =
          lib.attrNames (lib.filterAttrs (_: r: r.form == null) cfg.roles)
          ++ map (n: "form-${n}") (lib.attrNames (lib.filterAttrs (_: f: f.form == null) cfg.forms));
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
                  ];
                  description = "What kind of seat this is; fan-out limits are allowed only on strategist, knight and edge seats.";
                };
                regiment = lib.mkOption {
                  type = lib.types.nullOr (lib.types.strMatching "[a-z][a-z0-9-]*");
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
              };
            }
          );
        };
        forms = lib.mkOption {
          default = { };
          description = "Queue forms: work orders live on these, not on role forms. Each is drawn under a role and studied by the roles that claim from it.";
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                form = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "The form; none until it is minted, and then figaro-apply skips it.";
                };
                title = lib.mkOption { type = lib.types.str; };
                under = lib.mkOption {
                  type = lib.types.str;
                  description = "The declared role this form is drawn under.";
                };
                studiedBy = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  description = "Declared roles that study this form and claim from it.";
                };
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
            Work orders live under queue.<id> on the queue forms this role studies (chartered.studies), about 1 KB each; each form's queue-contract names the fields.
            - An id is a handcrafted codename: two hyphenated lowercase words, unique on this form (queue.amber-falcon). Order is by priority, then state_at.
            - Anyone may post: one new queue.<id> with state posted, source, requested_by and owner. A poster writes nothing outside queue.**.
            - Only a holder of the owner role claims: one write of claimed_by {role, aria, at, lease_until} and state claimed, conditional on the version it read. If the version moved, read again and never overwrite another claim:
                v=$(figaro state show --id @<form> --version)
                figaro state show --id @<form> -j   (queue.<id>.claimed_by must be empty)
                figaro set --id @<form> --if-version "$v" queue.<id>.claimed_by '{"role": ..., "aria": ..., "at": ..., "lease_until": ...}'
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
            source = toml.generate "outfit-role-${name}.toml" (keysOf name r);
          }
        ) minted
        // lib.mapAttrs' (
          name: f:
          lib.nameValuePair "figaro/outfits/role-form-${name}.toml" {
            source = toml.generate "outfit-role-form-${name}.toml" (formKeysOf f);
          }
        ) mintedForms;
      };
    };
}
