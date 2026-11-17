{ inputs, ... }:
{
  flake.modules.homeManager.rou2 =
    { pkgs, ... }:
    {
      home.packages = [
        (inputs.rou2.packages.${pkgs.stdenv.hostPlatform.system}.rou2.overrideAttrs (_: {
          doCheck = false;
        }))
      ];
    };
}
