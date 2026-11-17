{ lib }:
let
  forbiddenPrefixes = [
    "git+ssh:"
    "ssh:"
    "path:"
    "file:"
    "git+file:"
    "tarball:"
    "http:"
    "https:"
  ];

  hasForbiddenPrefix =
    url: url != null && builtins.any (prefix: lib.hasPrefix prefix url) forbiddenPrefixes;

  nodeViolations =
    name: node:
    let
      locked = node.locked or { };
      original = node.original or { };
      lockedType = locked.type or "";
      originalType = original.type or lockedType;
      lockedUrl = locked.url or null;
      originalUrl = original.url or null;
      describe =
        if lockedUrl != null then
          lockedUrl
        else if locked ? path then
          "path:${toString locked.path}"
        else if locked ? owner && locked ? repo then
          "${lockedType}:${locked.owner}/${locked.repo}"
        else
          lockedType;
    in
    lib.optional (lockedType != "github") "${name}: locked.type=${lockedType} (${describe})"
    ++ lib.optional (originalType != "github") "${name}: original.type=${originalType}"
    ++ lib.optional (hasForbiddenPrefix lockedUrl) "${name}: locked.url=${lockedUrl}"
    ++ lib.optional (hasForbiddenPrefix originalUrl) "${name}: original.url=${originalUrl}";

  nonRootNodes = lock: builtins.removeAttrs (lock.nodes or { }) [ (lock.root or "root") ];

  violations = lock: lib.concatLists (lib.mapAttrsToList nodeViolations (nonRootNodes lock));

  nixpkgsNodes =
    lock:
    builtins.attrNames (
      lib.filterAttrs (
        _: node:
        let
          repo = node.locked.repo or node.original.repo or "";
        in
        repo == "nixpkgs"
      ) (nonRootNodes lock)
    );

  assertGithubOnlyLock =
    lock:
    let
      bad = violations lock;
      pkgsCount = builtins.length (nixpkgsNodes lock);
    in
    if bad != [ ] then
      throw ("charter flake.lock rejects non-github inputs:\n  " + lib.concatStringsSep "\n  " bad)
    else if pkgsCount != 1 then
      throw "charter flake.lock must carry exactly 1 nixpkgs node, got ${toString pkgsCount}: ${lib.concatStringsSep ", " (nixpkgsNodes lock)}"
    else
      true;
in
{
  inherit
    violations
    nixpkgsNodes
    assertGithubOnlyLock
    ;
}
