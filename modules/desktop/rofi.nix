# rofi — the picker, Kanagawa theme.
#
# A previous port substituted fuzzel because rofi was missing from a minimal
# Arch install, and it rendered bare defaults — if the picker ever looks
# unstyled, check which program is actually bound to Mod+Space.
{
  flake.modules.homeManager.rofi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = lib.optionals config.my.platform.desktopFromNix [ pkgs.rofi-wayland ];

      xdg.configFile = {
        "rofi/config.rasi".source = ../../config/rofi/config.rasi;
        "rofi/kanagawa.rasi".source = ../../config/rofi/kanagawa.rasi;
      };
    };
}
