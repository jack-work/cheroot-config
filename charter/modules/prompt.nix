{
  flake.modules.nixos.prompt = {
    programs.starship.enable = true;
  };

  flake.modules.homeManager.prompt = {
    programs.starship = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
    };

    xdg.configFile."starship.toml".source = ../config/starship/starship.toml;
  };
}
