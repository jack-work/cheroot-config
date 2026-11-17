{ inputs, lib, ... }:
{
  options.flake.modules = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.deferredModule);
    default = { };
  };

  options.flake.homeConfigurations = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
  };

  options.flake.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
  };

  config = {
    systems = [ "x86_64-linux" ];
    debug = true;
    flake.modules = {
      homeManager = inputs.charter.modules.homeManager;
      nixos = inputs.charter.modules.nixos;
    };
  };
}
