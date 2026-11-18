{ lib, config, ... }:
{
  flake.lib = {
    linkDir = import ../lib/link-dir.nix lib;
    lockGate = import ../lib/lock-gate.nix { inherit lib; };
    roster = import ../lib/roster.nix { inherit lib; };
    regiment = import ../lib/regiment.nix { inherit lib; };
    tailnetAllow = import ../lib/tailnet-allow.nix { inherit lib; };

    nixosAspectFrom =
      modulesSet: name:
      let
        aspectMod = modulesSet.${name};
        defs = aspectMod.imports or [ ];
      in
      if builtins.length defs == 1 && builtins.length ((builtins.head defs).imports or [ ]) == 1 then
        let
          d = builtins.head defs;
          m = builtins.head d.imports;
        in
        if lib.isFunction m then
          lib.setFunctionArgs (args: m args // { _file = d._file; }) (lib.functionArgs m)
        else
          m // { _file = d._file; }
      else
        aspectMod;

    nixosAspect = name: config.flake.lib.nixosAspectFrom config.flake.modules.nixos name;
  };
}
