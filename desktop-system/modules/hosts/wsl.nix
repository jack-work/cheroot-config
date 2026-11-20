{ config, ... }:
{
  flake.homeConfigurations = config.flake.lib.mkHost {
    user = "gluck";
    host = "wsl";

    aspects = config.flake.lib.coreAspects;
    extraAspects = [
      "wsl"
      "muse-code"
    ];
  };
}
