{
  lib,
  pkgs ? null,
  ...
}:
{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      environment.systemPackages = with pkgs; [
        git
        vim
        wget
        pciutils
        usbutils
      ];
    };

  flake.modules.homeManager.base = {
    home.stateVersion = lib.mkDefault "26.11";
    programs.home-manager.enable = true;
  };
}
