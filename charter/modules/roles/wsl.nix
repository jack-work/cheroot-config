{ lib, ... }:
{
  flake.modules.homeManager.wsl = {
    my.platform.toolchainFromNix = lib.mkDefault true;
  };
}
