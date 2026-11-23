{ inputs, ... }:
{
  flake.modules.homeManager.figaro-daemon =
    { lib, ... }:
    {
      imports = [ inputs.figaro.homeManagerModules.default ];

      config.programs.figaro = {
        enable = true;
        restartOnSwitch = lib.mkDefault true;
        daemon.enable = true;
      };
    };
}
