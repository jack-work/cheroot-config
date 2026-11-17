{ lib }:
let
  validKinds = [
    "secretary"
    "steward"
    "leader"
    "builder"
    "reviewer"
  ];

  isRoleRef = s: s == "none" || (builtins.isString s && builtins.match "@[0-9a-f]{8,32}" s != null);

  validateRole =
    name: role:
    lib.optional ((role.name or name) != name) "${name}: role.name '${role.name or ""}' must match key"
    ++ lib.optional (
      !(builtins.elem (role.kind or "") validKinds)
    ) "${name}: invalid kind '${role.kind or ""}'"
    ++ lib.optional (
      !(isRoleRef (role.leader or "none"))
    ) "${name}: leader '${toString (role.leader or "")}' must be 'none' or @<hex>"
    ++ lib.optional ((role.purpose or "") == "") "${name}: purpose must be non-empty";

  validateRoster =
    roster:
    let
      errs = lib.concatLists (lib.mapAttrsToList validateRole roster);
    in
    if errs == [ ] then
      roster
    else
      throw ("charter figaro roster invalid:\n  " + lib.concatStringsSep "\n  " errs);

  roleToTomlAttrs =
    name: role:
    lib.filterAttrs (_: v: v != null) {
      inherit name;
      inherit (role)
        kind
        leader
        purpose
        mint
        ;
      form = role.form or null;
      handoff = role.handoff or null;
      mantra = role.mantra or null;
      provider = role.provider or null;
      model = role.model or null;
      cache_control = role.cacheControl or null;
    };
in
{
  inherit
    validKinds
    validateRole
    validateRoster
    roleToTomlAttrs
    ;
}
