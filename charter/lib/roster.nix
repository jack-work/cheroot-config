{ lib }:
let
  grants = import ./grants.nix { inherit lib; };

  validKinds = [
    "secretary"
    "steward"
    "leader"
    "builder"
    "reviewer"
  ];

  reservedFields = [
    "charter"
    "handoff"
    "system"
    "target-aria"
    "succession-policy"
    "name"
    "role-name"
  ];

  isFormId = s: builtins.isString s && builtins.match "@[0-9a-f]{8,32}" s != null;
  isDate = s: builtins.isString s && builtins.match "[0-9]{4}-[0-9]{2}-[0-9]{2}" s != null;

  leaderOf = role: role.leader or "none";

  companionOf = role: role.companionOf or null;

  seated = role: (role.form or null) != null && companionOf role == null;

  authorityOf =
    roster: name: role:
    if !(seated role) then
      null
    else
      grants.render {
        inherit (role) form;
        reach = role.reach or "lineage";
        reportsTo = builtins.filter grants.isFormId (map (n: roster.${n}.form or null) (role.reportsTo or [ ]));
        maxChildren = role.maxChildren or null;
        quota = role.quota or null;
        childPolicy = role.childPolicy or { };
        holderScopes = role.holderScopes or [ ];
      };

  validateRole =
    roster: name: role:
    let
      leader = leaderOf role;
      forward = role.forward or [ ];
    in
    lib.optional ((role.name or name) != name) "${name}: role.name '${role.name or ""}' must match key"
    ++ lib.optional (
      !(builtins.elem (role.kind or "") validKinds)
    ) "${name}: invalid kind '${role.kind or ""}'"
    ++ lib.optional (leader == name) "${name}: a role cannot lead itself"
    ++ lib.optional (
      leader != "none" && !(roster ? ${leader})
    ) "${name}: leader '${toString leader}' must be 'none' or a declared role"
    ++ lib.optional ((role.purpose or "") == "") "${name}: purpose must be non-empty"
    ++ lib.optional (
      (role.form or null) != null && !(isFormId role.form)
    ) "${name}: form '${role.form}' must be @<hex>"
    ++ lib.optional (
      forward != [ ] && !(isDate (role.forwardUntil or null))
    ) "${name}: forward needs forwardUntil = \"YYYY-MM-DD\""
    ++ lib.optional (
      (role.maxChildren or null) != null && role.maxChildren < 0
    ) "${name}: maxChildren must not be negative"
    ++ map (k: "${name}: fields.${k} has its own option or belongs to the daemon") (
      builtins.filter (k: builtins.elem k reservedFields) (builtins.attrNames (role.fields or { }))
    )
    ++ map (old: "${name}: forward name '${old}' is a declared role") (
      builtins.filter (old: roster ? ${old}) forward
    )
    ++ companionErrors roster name role
    ++ map (n: "${name}: reportsTo '${n}' must be a declared role with an exact form") (
      builtins.filter (n: !(roster ? ${n}) || !(grants.isFormId (roster.${n}.form or null))) (
        role.reportsTo or [ ]
      )
    )
    ++ lib.optionals (seated role) (grants.seatFaults name (authorityOf roster name role));

  companionErrors =
    roster: name: role:
    let
      primary = companionOf role;
    in
    lib.optionals (primary != null) (
      lib.optional (primary == name) "${name}: a role cannot be its own companion"
      ++ lib.optional (
        primary != name && !(roster ? ${primary} && seated roster.${primary})
      ) "${name}: companionOf '${primary}' must be a declared seat with a form, held on its own"
      ++
        map
          (
            o:
            "${name}: a companion is capped and granted by ${primary}'s holder, so it sets no ${o}; a limit on a companion's role form would cap ${primary} too"
          )
          (
            builtins.filter (o: (role.${o} or null) != null && (role.${o} or null) != [ ] && (role.${o} or null) != { }) [
              "maxChildren"
              "quota"
              "reportsTo"
              "childPolicy"
            ]
            ++ lib.optional ((role.reach or "lineage") != "lineage") "reach"
          )
    );

  chainErrors =
    roster:
    let
      bound = builtins.length (builtins.attrNames roster);
      reachesTop =
        steps: cur:
        if cur == "none" || !(roster ? ${cur}) then
          true
        else if steps == 0 then
          false
        else
          reachesTop (steps - 1) (leaderOf roster.${cur});
    in
    map (n: "${n}: its leader chain is a cycle") (
      builtins.filter (n: !(reachesTop bound n)) (builtins.attrNames roster)
    );

  forwardClashes =
    roster:
    let
      olds = lib.concatLists (lib.mapAttrsToList (_: r: r.forward or [ ]) roster);
    in
    map (o: "forward name '${o}' is claimed by more than one role") (
      lib.unique (builtins.filter (o: lib.count (x: x == o) olds > 1) olds)
    );

  validateRoster =
    roster:
    let
      errs =
        lib.concatLists (lib.mapAttrsToList (validateRole roster) roster)
        ++ chainErrors roster
        ++ forwardClashes roster;
    in
    if errs == [ ] then
      roster
    else
      throw ("charter figaro roster invalid:\n  " + lib.concatStringsSep "\n  " errs);

  roleToTomlAttrs =
    roster: name: role:
    let
      leader = leaderOf role;
      authority = authorityOf roster name role;
    in
    lib.filterAttrs (_: v: v != null && v != [ ]) {
      inherit name leader;
      inherit (role)
        kind
        purpose
        mint
        ;
      leader_form = if leader == "none" then null else roster.${leader}.form or null;
      form = role.form or null;
      handoff = role.handoff or null;
      mantra = role.mantra or null;
      provider = role.provider or null;
      model = role.model or null;
      cache_control = role.cacheControl or null;
      max_children = role.maxChildren or null;
      quota = if authority == null then null else authority.quota;
      reach = if authority == null then null else role.reach or "lineage";
      scopes = if authority == null then null else authority.scopes;
      child_policy = if authority == null then null else authority.childPolicy;
      companion_of = companionOf role;
      forward = role.forward or [ ];
      forward_until = role.forwardUntil or null;
    };
in
{
  inherit
    validKinds
    reservedFields
    authorityOf
    validateRole
    validateRoster
    roleToTomlAttrs
    ;
}
