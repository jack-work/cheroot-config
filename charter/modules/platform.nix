{ lib, ... }:
{
  flake.modules.homeManager.platform = {
    options.my.platform = {
      desktopFromNix = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      shellsFromNix = lib.mkOption {
        type = lib.types.bool;
        default = false;
        internal = true;
      };

      toolchainFromNix = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      mediaFromNix = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      fhsMason = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
  };
}
