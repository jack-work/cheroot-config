{ lib }:
let
  grants = import ./grants.nix { inherit lib; };

  kinds = [
    "secretary"
    "steward"
    "leader"
    "builder"
    "reviewer"
  ];

  regimentKinds = {
    strategist = {
      kind = "leader";
      limit.children = 6;
      reach = "lineage";
      reportsTo = [
        "knight"
        "steward"
      ];
    };
    knight = {
      kind = "builder";
      limit.children = 1;
      reach = "fleet";
      reportsTo = [ "strategist" ];
    };
    steward = {
      kind = "steward";
      limit.children = 3;
      reach = "fleet";
      reportsTo = [
        "strategist"
        "knight"
      ];
    };
    reviewer = {
      limit.children = null;
      reach = "lineage";
      reportsTo = [ ];
    };
  };

  seatKinds = [
    "strategist"
    "knight"
    "steward"
  ];

  reservedFields = [
    "charter"
    "handoff"
    "system"
    "target-aria"
    "succession-policy"
    "name"
    "role-name"
    "standing"
  ];

  isRoleId = s: builtins.isString s && builtins.match "@([0-9a-f]{8}|[0-9a-f]{32})" s != null;
  isDate = s: builtins.isString s && builtins.match "[0-9]{4}-[0-9]{2}-[0-9]{2}" s != null;

  text = d: if builtins.isPath d then lib.removeSuffix "\n" (builtins.readFile d) else d;

  noLimit = {
    children = null;
    quota = null;
  };

  seat =
    {
      kind,
      purpose,
      role ? null,
      title ? null,
      duty ? null,
      leader ? null,
      handoff ? null,
      mantra ? null,
      provider ? null,
      model ? null,
      cacheControl ? null,
      limit ? { },
      reach ? "lineage",
      reportsTo ? [ ],
      outfits ? null,
      childPolicy ? { },
      aliases ? { },
      forward ? { },
      fields ? { },
      standing ? { },
      mode ? "check",
    }:
    {
      _type = "kingdom-seat";
      inherit
        kind
        purpose
        role
        title
        leader
        handoff
        mantra
        provider
        model
        cacheControl
        reach
        reportsTo
        outfits
        childPolicy
        aliases
        forward
        fields
        standing
        mode
        ;
      duty = text duty;
      limit = noLimit // limit;
      primary = null;
      regiment = null;
    };

  alias = role: {
    _type = "kingdom-alias";
    inherit role;
  };

  companion =
    {
      role,
      purpose,
      kind ? "secretary",
      title ? null,
      duty ? null,
      outfits ? null,
    }:
    {
      _type = "kingdom-companion";
      inherit
        role
        purpose
        kind
        title
        outfits
        ;
      duty = text duty;
    };

  regiment =
    {
      name,
      leader,
      seats,
      kinds ? { },
      mode ? "check",
      reviewer ? { },
      orchestration ? "Classify every dispatched child as one-off tail fork or continuing owner. One-offs need an explicit bounded deliverable, parent, completion criterion and finite TTL. Preserve outcomes/evidence/open obligations in dated captains-log entries, then retire with a short TTL, normally 10m, after accepted handoff. Do not retire active work or current role holders blindly. Parent owns child inventory and integration: keep active forks manageable, avoid duplicate owners and unbounded recursive fan-out, but delegate independent work when it removes a real bottleneck. Include this rule in handoffs, successors and child prompts. No standing role for a one-off.",
      agreement ? [
        "{strategist} builds the whole plan with transient forks and keeps the final vision. It restacks the work into incremental, non-conflicting commits for {knight}, and again as {knight} lands fixes on main. A hard rejection sends that part back to {strategist}, not into patch-on-patch."
        "{knight} carries only mutually non-conflicting changes at a time, produces the validated build of each and asks {steward} for a reviewer. It never merges to main."
        "{knight} and {strategist} talk directly with figaro send -f: {strategist} warns of anything found in later parts before {knight} reaches them; {knight} asks when a review makes a part unclear."
        "{steward} mints one reviewer per change as a turn-1 fork of {strategist} dressed in {reviewer-outfit}, points it at the validated build, relays the verdict and retires it."
        "Fan-out forks and reviewers are transient: finite system.ttl, never seats, retired with --ttl {retire-ttl} once their harvest (what they did, branch and sha, evidence, open obligations, lessons) is in a dated captains-log entry."
        "Ask your parent for quota before you need it, in one line: what for, how many, how long."
      ],
      successionLayers ? [ "succession-standard" ],
      successorBase ? [
        "default"
        "succession-standard"
      ],
    }:
    let
      reg = {
        inherit
          name
          leader
          mode
          orchestration
          agreement
          successionLayers
          successorBase
          ;
        seats = lib.mapAttrs (
          _: s:
          {
            role = null;
            duty = null;
            handoff = null;
            mantra = null;
          }
          // s
          // {
            duty = text (s.duty or null);
          }
        ) seats;
        kinds = lib.mapAttrs (
          k: d:
          let
            o = kinds.${k} or { };
          in
          {
            provider = null;
            model = null;
            outfits = null;
            childPolicy = { };
          }
          // removeAttrs d [ "kind" ]
          // removeAttrs o [ "limit" ]
          // {
            limit = noLimit // d.limit // (o.limit or { });
          }
        ) regimentKinds;
        reviewer = {
          ttl = "4h";
          retireTtl = "10m";
        }
        // reviewer;
      };
      faults = regimentFaults reg;
    in
    if faults != [ ] then
      throw ("charter kingdom: regiment ${name}:\n  " + lib.concatStringsSep "\n  " faults)
    else
      lib.mapAttrs (seatName: s: regimentSeat reg seatName s) reg.seats;

  seatsOfKind = reg: kind: lib.filterAttrs (_: s: s.kind == kind) reg.seats;

  regimentFaults =
    reg:
    let
      count = kind: builtins.length (builtins.attrNames (seatsOfKind reg kind));
    in
    map (k: "needs exactly one ${k}, has ${toString (count k)}") (
      builtins.filter (k: count k != 1) seatKinds
    )
    ++ lib.optional (
      reg.seats ? ${reg.leader}
    ) "its leader '${reg.leader}' cannot be one of its own seats"
    ++ lib.concatLists (
      lib.mapAttrsToList (
        n: s:
        lib.optional (
          !(builtins.elem s.kind seatKinds)
        ) "seat ${n}: kind '${s.kind}' is not one of ${toString seatKinds}"
        ++ lib.optional (
          s.role != null && !(isRoleId s.role)
        ) "seat ${n}: role '${s.role}' must be @ and 8 or 32 hex digits"
      ) reg.seats
    );

  regimentSeat =
    reg: seatName: s:
    let
      k = reg.kinds.${s.kind};
      adopted = s.role != null;
      reportsOf = lib.concatMap (
        to:
        if builtins.elem to seatKinds then
          builtins.attrNames (lib.filterAttrs (_: x: x.role != null) (seatsOfKind reg to))
        else
          [ to ]
      ) k.reportsTo;
    in
    {
      _type = "kingdom-seat";
      kind = regimentKinds.${s.kind}.kind;
      inherit (reg) leader mode;
      inherit (s)
        purpose
        role
        handoff
        mantra
        ;
      inherit (k) provider model reach;
      cacheControl = null;
      reportsTo = if adopted then reportsOf else [ ];
      limit =
        if adopted then
          {
            inherit (k.limit) children;
            quota = k.limit.quota;
          }
        else
          noLimit;
      childPolicy = if adopted then k.childPolicy else { };
      outfits = if adopted then k.outfits else null;
      duty = if adopted then s.duty else null;
      fields = if adopted then regimentFields reg s else { };
      title = if adopted then s.title else null;
      aliases = { };
      forward = { };
      standing = { };
      primary = null;
      regiment = reg;
    };

  regimentFields = reg: s: {
    orchestration.policy = reg.orchestration;
    regiment = {
      inherit (reg) name;
      seat = s.kind;
      agreement = agreementText reg;
    };
  };

  holderOutfit = reg: kind: "regiment-${reg.name}-${kind}";
  mintOutfit = seatName: "role-${seatName}-mint";

  agreementText =
    reg:
    let
      titleOf = kind: lib.concatMapStringsSep ", " (s: s.title) (lib.attrValues (seatsOfKind reg kind));
      subst =
        builtins.replaceStrings
          [ "{strategist}" "{knight}" "{steward}" "{reviewer-outfit}" "{retire-ttl}" ]
          [
            (titleOf "strategist")
            (titleOf "knight")
            (titleOf "steward")
            (holderOutfit reg "reviewer")
            reg.reviewer.retireTtl
          ];
    in
    lib.concatMapStringsSep "\n" (c: "- " + subst c) reg.agreement;

  holderSpec =
    reg: kind:
    let
      k = reg.kinds.${kind};
    in
    lib.optionalAttrs (k.provider != null || k.model != null) {
      system = lib.filterAttrs (_: v: v != null) { inherit (k) provider model; };
    };

  regimentOutfits =
    reg:
    lib.listToAttrs (
      map (kind: lib.nameValuePair (holderOutfit reg kind) (holderSpec reg kind)) seatKinds
    )
    // {
      ${holderOutfit reg "reviewer"} = lib.recursiveUpdate (holderSpec reg "reviewer") {
        system.ttl = reg.reviewer.ttl;
        regiment = {
          inherit (reg) name;
          seat = "reviewer";
          agreement = agreementText reg;
        };
      };
    }
    // lib.mapAttrs' (
      seatName: s:
      let
        k = reg.kinds.${s.kind};
      in
      lib.nameValuePair (mintOutfit seatName) (
        lib.filterAttrs (_: v: v != null) {
          layers = reg.successionLayers;
          charter = s.duty;
          inherit (s) handoff;
          succession-policy.outfit = lib.concatStringsSep "," (
            reg.successorBase ++ [ (holderOutfit reg s.kind) ]
          );
        }
        // lib.optionalAttrs (k.limit.children != null) {
          system.fanout = lib.filterAttrs (_: v: v != null) {
            max_children = k.limit.children;
            quota = grants.quotaOf {
              inherit (k) reach childPolicy;
              maxChildren = k.limit.children;
              quota = k.limit.quota;
            };
          };
        }
        // regimentFields reg s
      )
    ) reg.seats;

  expandAliases =
    seats:
    lib.concatMapAttrs (
      primary: p:
      lib.mapAttrs (
        name: a:
        if a._type == "kingdom-alias" then
          {
            _type = "kingdom-seat";
            kind = "steward";
            inherit (p) leader;
            inherit (a) role;
            purpose = "Routes to ${if p.title != null then p.title else primary}";
            title = null;
            duty = null;
            inherit (p) outfits mode;
            fields.lifecycle.status = "routing-alias";
          }
          // aliasDefaults primary
        else
          {
            _type = "kingdom-seat";
            inherit (a)
              kind
              role
              purpose
              title
              duty
              outfits
              ;
            leader = primary;
            inherit (p) mode;
            fields = { };
          }
          // aliasDefaults primary
      ) p.aliases
    ) seats;

  aliasDefaults = primary: {
    inherit primary;
    handoff = null;
    mantra = null;
    provider = null;
    model = null;
    cacheControl = null;
    limit = noLimit;
    reach = "lineage";
    reportsTo = [ ];
    childPolicy = { };
    aliases = { };
    forward = { };
    standing = { };
    regiment = null;
  };

  resolveLeaders =
    root: seats:
    lib.mapAttrs (
      name: s:
      s
      // {
        leader =
          if name == root then
            "none"
          else if s.leader != null then
            s.leader
          else if root != null then
            root
          else
            "none";
      }
    ) seats;

  seated = s: s.role != null && s.primary == null;

  authorityOf =
    seats: name: s:
    if !(seated s) then
      null
    else
      grants.render {
        form = s.role;
        inherit (s) reach childPolicy;
        reportsTo = builtins.filter isRoleId (map (n: seats.${n}.role or null) s.reportsTo);
        maxChildren = s.limit.children;
        quota = s.limit.quota;
      };

  seatFaults =
    seats: name: s:
    let
      forwardNames = builtins.attrNames s.forward;
    in
    lib.optional (!(builtins.elem s.kind kinds)) "${name}: invalid kind '${s.kind}'"
    ++ lib.optional (s.leader == name) "${name}: a seat cannot lead itself"
    ++ lib.optional (
      s.leader != "none" && !(seats ? ${s.leader})
    ) "${name}: leader '${toString s.leader}' must be a declared seat"
    ++ lib.optional (s.purpose == "") "${name}: purpose must be non-empty"
    ++ lib.optional (
      s.role != null && !(isRoleId s.role)
    ) "${name}: role '${s.role}' must be @ and 8 or 32 hex digits"
    ++ map (old: "${name}: forward name '${old}' needs a YYYY-MM-DD date") (
      builtins.filter (old: !(isDate s.forward.${old})) forwardNames
    )
    ++ map (old: "${name}: forward name '${old}' is a declared seat") (
      builtins.filter (old: seats ? ${old}) forwardNames
    )
    ++ map (l: "${name}: limit.${l} must be an integer >= 0") (
      builtins.filter (l: s.limit.${l} != null && !(builtins.isInt s.limit.${l} && s.limit.${l} >= 0)) [
        "children"
        "quota"
      ]
    )
    ++ lib.optional (
      s.limit.children != null && s.limit.quota != null && s.limit.quota < s.limit.children
    ) "${name}: limit.quota must be at least limit.children"
    ++ map (k: "${name}: fields.${k} has its own option or belongs to the daemon") (
      builtins.filter (k: builtins.elem k reservedFields) (builtins.attrNames s.fields)
    )
    ++ map (n: "${name}: reportsTo '${n}' must be a declared seat with a role") (
      builtins.filter (n: !(seats ? ${n}) || !(isRoleId seats.${n}.role)) s.reportsTo
    )
    ++ lib.optionals (s.primary != null) (aliasFaults seats name s)
    ++ lib.optionals (seated s) (grants.seatFaults name (authorityOf seats name s));

  aliasFaults =
    seats: name: s:
    lib.optional (s.role == null) "${name}: an alias needs a role"
    ++ lib.optional (s.primary == name) "${name}: an alias of itself"
    ++ lib.optional (
      !(seats ? ${s.primary} && seated seats.${s.primary})
    ) "${name}: aliased by '${s.primary}', which must be a seat with a role, held on its own";

  chainFaults =
    seats:
    let
      bound = builtins.length (builtins.attrNames seats);
      reachesTop =
        steps: cur:
        if cur == "none" || !(seats ? ${cur}) then
          true
        else if steps == 0 then
          false
        else
          reachesTop (steps - 1) seats.${cur}.leader;
    in
    map (n: "${n}: its leader chain is a cycle") (
      builtins.filter (n: !(reachesTop bound n)) (builtins.attrNames seats)
    );

  forwardClashes =
    seats:
    let
      olds = lib.concatLists (lib.mapAttrsToList (_: s: builtins.attrNames s.forward) seats);
    in
    map (o: "forward name '${o}' is claimed by more than one seat") (
      lib.unique (builtins.filter (o: lib.count (x: x == o) olds > 1) olds)
    );

  regimentClashes =
    seats:
    let
      claimed = lib.foldlAttrs (
        acc: name: s:
        if s.regiment == null then
          acc
        else
          acc // { ${s.regiment.name} = (acc.${s.regiment.name} or [ ]) ++ [ name ]; }
      ) { } seats;
    in
    lib.concatLists (
      lib.mapAttrsToList (
        reg: names:
        let
          declared = builtins.attrNames (seats.${builtins.head names}.regiment.seats);
        in
        lib.optional (
          lib.sort lib.lessThan names != declared
          || builtins.any (n: seats.${n}.regiment.seats != seats.${builtins.head names}.regiment.seats) names
        ) "regiment '${reg}' is declared more than once, or one of its seats is declared elsewhere"
      ) claimed
    );

  expand =
    {
      root ? null,
      seats,
    }:
    let
      notSeats = builtins.filter (n: (seats.${n}._type or null) != "kingdom-seat") (
        builtins.attrNames seats
      );
      resolved = resolveLeaders root seats;
      aliasSeats = expandAliases resolved;
      clashes = builtins.filter (a: seats ? ${a}) (builtins.attrNames aliasSeats);
      all = resolved // aliasSeats;
      faults =
        map (a: "${a}: declared as a seat and as an alias") clashes
        ++ lib.optional (root != null && !(seats ? ${root})) "root '${root}' is not a declared seat"
        ++ lib.concatLists (lib.mapAttrsToList (seatFaults all) all)
        ++ chainFaults all
        ++ forwardClashes all
        ++ regimentClashes all;
    in
    if notSeats != [ ] then
      throw "charter kingdom: ${toString notSeats}: write seats with kingdom.seat or kingdom.regiment"
    else if faults != [ ] then
      throw ("charter kingdom invalid:\n  " + lib.concatStringsSep "\n  " faults)
    else
      all;

  regimentsOf =
    seats:
    lib.foldlAttrs (
      acc: _: s:
      if s.regiment == null then acc else acc // { ${s.regiment.name} = s.regiment; }
    ) { } seats;

  rosterEntry =
    seats: name: s:
    let
      authority = authorityOf seats name s;
    in
    lib.filterAttrs (_: v: v != null && v != [ ]) {
      inherit name;
      inherit (s) leader kind purpose;
      mint = false;
      leader_form = if s.leader == "none" then null else seats.${s.leader}.role or null;
      form = s.role;
      inherit (s)
        handoff
        mantra
        provider
        model
        ;
      cache_control = s.cacheControl;
      max_children = s.limit.children;
      quota = if authority == null then null else authority.quota;
      reach = if authority == null then null else s.reach;
      scopes = if authority == null then null else authority.scopes;
      child_policy = if authority == null then null else authority.childPolicy;
      companion_of = s.primary;
      forward = builtins.attrNames s.forward;
      forward_until =
        if s.forward == { } then null else lib.last (lib.sort lib.lessThan (lib.attrValues s.forward));
    };
in
{
  inherit
    kinds
    seatKinds
    regimentKinds
    reservedFields
    seat
    alias
    companion
    regiment
    expand
    regimentsOf
    regimentOutfits
    authorityOf
    rosterEntry
    isRoleId
    ;
}
