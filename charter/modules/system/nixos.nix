{
  flake.modules.nixos.system-base =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        git
        vim
        wget
        pciutils
        usbutils
      ];
    };

  flake.modules.nixos.system-desktop = {
    programs.niri.enable = true;
    hardware.graphics.enable = true;
    security.polkit.enable = true;
  };
}
