{ lib }:
let
  keys = {
    scopes = "system.scopes";
    childPolicy = "system.child_policy";
    maxChildren = "system.fanout.max_children";
    quota = "system.fanout.quota";
    successionOutfit = "succession-policy.outfit";
  };

  verbs = [
    "*"
    "read"
    "listen"
    "send"
    "fork"
    "set"
    "write"
    "create"
    "mint"
    "kill"
    "admin"
    "use"
    "join"
    "decide"
    "adopt"
    "lease"
    "say"
    "delete"
    "cast"
    "succeed"
  ];

  reaches = [
    "lineage"
    "fleet"
  ];

  fleetScopes = [ "*:*" ];

  laneScopes = [
    "send:parent"
    "read:aria:self"
    "write:aria:self#@self"
    "delete:aria:self#@self"
  ];

  isFormId = s: builtins.isString s && builtins.match "@([0-9a-f]{8}|[0-9a-f]{32})" s != null;

  reachRole = form: [ "send:role:${form}" ];

  scopeFault =
    s:
    let
      m = builtins.match "([a-z*]+):(.+)" s;
      selector = lib.head (lib.splitString "#" (builtins.elemAt m 1));
      role = builtins.match "role:(.*)" selector;
    in
    if !(builtins.isString s) then
      "a scope must be a string"
    else if m == null then
      "scope '${s}' is not verb:selector"
    else if !(builtins.elem (builtins.head m) verbs) then
      "scope '${s}' names no verb figaro knows"
    else if lib.hasInfix "*" selector && selector != "*" then
      "scope '${s}': a selector takes no wildcard"
    else if role != null && !(isFormId (builtins.head role)) then
      "scope '${s}': role takes the role form's id, @ and 8 or 32 hex"
    else
      null;

  scopesFaults =
    v:
    if !(builtins.isList v) then
      [ "${keys.scopes} must be a list of verb:selector strings" ]
    else
      builtins.filter (f: f != null) (map scopeFault v);

  isCount = v: builtins.isInt v && v >= 0;

  childPolicyFaults =
    v:
    if !(builtins.isAttrs v) then
      [ "${keys.childPolicy} must be an object of key paths" ]
    else
      lib.concatLists (
        lib.mapAttrsToList (
          k: x:
          lib.optional (
            lib.hasPrefix "runtime." k || k == "runtime"
          ) "${keys.childPolicy}: ${k} is written only by the daemon"
          ++ lib.optional (
            (k == keys.quota || k == keys.maxChildren) && !(isCount x)
          ) "${keys.childPolicy}: ${k} must be an integer >= 0"
          ++ lib.optionals (k == keys.scopes) (scopesFaults x)
        ) v
      );

  seatFaults =
    name: seat:
    map (f: "${name}: ${f}") (
      lib.optionals (seat.scopes != null) (scopesFaults seat.scopes)
      ++ childPolicyFaults seat.childPolicy
      ++ lib.optional (
        seat.maxChildren != null && !(isCount seat.maxChildren)
      ) "${keys.maxChildren} must be an integer >= 0"
      ++ lib.optional (seat.quota != null && !(isCount seat.quota)) "${keys.quota} must be an integer >= 0"
    );

  quotaOf =
    {
      reach,
      maxChildren,
      quota,
      childPolicy,
    }:
    if quota != null || maxChildren == null || reach == "fleet" then
      quota
    else
      maxChildren * (1 + (childPolicy.${keys.quota} or 0));

  render =
    {
      form,
      reach,
      reportsTo,
      maxChildren,
      quota,
      childPolicy,
    }:
    let
      policy = {
        ${keys.scopes} = lib.unique (laneScopes ++ lib.concatMap reachRole ([ form ] ++ reportsTo));
      }
      // childPolicy;
    in
    {
      scopes = if reach == "fleet" then fleetScopes else null;
      childPolicy = policy;
      inherit maxChildren;
      quota = quotaOf {
        inherit
          reach
          maxChildren
          quota
          childPolicy
          ;
      };
    };

  toFormKeys =
    seat:
    lib.filterAttrs (_: v: v != null) {
      ${keys.scopes} = seat.scopes;
      ${keys.childPolicy} = seat.childPolicy;
    };
in
{
  inherit
    keys
    reaches
    fleetScopes
    laneScopes
    isFormId
    render
    quotaOf
    seatFaults
    toFormKeys
    ;
}
