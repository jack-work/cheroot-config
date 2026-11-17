{
  flake.modules.homeManager.rofi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = lib.optionals config.my.platform.desktopFromNix [ pkgs.rofi ];

      xdg.configFile = {
        "rofi/config.rasi".source = ../../config/rofi/config.rasi;
        "rofi/kanagawa.rasi".source = ../../config/rofi/kanagawa.rasi;
      };
    };
}
