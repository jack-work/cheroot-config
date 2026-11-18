{ lib }:
let
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
  ];

  isFormId = s: builtins.isString s && builtins.match "@[0-9a-f]{8,32}" s != null;
  isDate = s: builtins.isString s && builtins.match "[0-9]{4}-[0-9]{2}-[0-9]{2}" s != null;

  leaderOf = role: role.leader or "none";

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
      forward = role.forward or [ ];
      forward_until = role.forwardUntil or null;
    };
in
{
  inherit
    validKinds
    reservedFields
    validateRole
    validateRoster
    roleToTomlAttrs
    ;
}
