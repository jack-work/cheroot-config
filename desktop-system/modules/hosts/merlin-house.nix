{ config, ... }:
{
  flake.nixosModules.merlin-house = {
    imports = [
      config.flake.modules.nixos.figaro
      config.flake.modules.nixos.hush
    ];
    my.figaro = {
      mode = "house";
      owner = "jack";
    };
    services.figaro.valet.users = [ "jack" ];
    my.hush.agent.enable = true;
  };
}
