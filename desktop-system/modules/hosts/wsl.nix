{ config, ... }:
{
  flake.homeConfigurations = config.flake.lib.mkHost {
    user = "gluck";
    host = "wsl";

    aspects = config.flake.lib.coreAspects;
    roles = [
      "wsl"
      "muse-code"
    ];
  };
}
