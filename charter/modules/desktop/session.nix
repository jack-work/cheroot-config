{ config, ... }:
{
  flake.modules.homeManager.graphical = {
    home.sessionVariables = {
      QT_QPA_PLATFORMTHEME = "qt5ct";
      TERM = "alacritty";
    };

    xdg.configFile = config.flake.lib.linkDir ../../config/fish/conf.d-graphical "fish/conf.d";

    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };
}
