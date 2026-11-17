{
  flake.modules.homeManager.alacritty =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = lib.optionals config.my.platform.desktopFromNix [ pkgs.alacritty ];
      xdg.configFile."alacritty/alacritty.toml".source = ../../config/alacritty/alacritty.toml;
    };
}
