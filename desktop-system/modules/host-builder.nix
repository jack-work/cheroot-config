{ inputs, config, ... }:
{
  flake.lib = {
    inherit (inputs.charter.lib) linkDir coreAspects;

    guiAspects = inputs.charter.lib.guiAspects ++ [ "idle-lock" ];

    defaultAspects = config.flake.lib.coreAspects ++ config.flake.lib.guiAspects;

    mkHost =
      args:
      inputs.charter.lib.mkHomeHostWith {
        homeManagerLib = inputs.home-manager.lib;
        nixpkgsInput = inputs.nixpkgs;
        homeModules = config.flake.modules.homeManager;
      } ({ aspects = config.flake.lib.defaultAspects; } // args);
  };
}
