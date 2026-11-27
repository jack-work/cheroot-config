{ inputs, ... }:
{
  flake.modules.homeManager.school-tools =
    { pkgs, ... }:
    {
      home.packages = [ inputs.tuiz.packages.${pkgs.stdenv.hostPlatform.system}.tuiz ];
    };
}
