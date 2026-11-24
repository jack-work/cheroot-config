{
  flake.modules.homeManager.kic-copilot-failover =
    { config, pkgs, ... }:
    let
      home = config.home.homeDirectory;
      run = pkgs.writeShellScript "kic-copilot-failover" (builtins.readFile ./kic-copilot-failover/run.sh);
    in
    {
      systemd.user.services.kic-copilot-failover = {
        Unit.Description = "Move central-command role holders from KIC or Max to Copilot when that quota runs out";
        Service = {
          Type = "oneshot";
          ExecStart = "${run}";
          Environment = [
            "KIC_FAILOVER_STEWARD=ef60306d956a9d2c55b0e1cf1ab97a2a"
            "PATH=${home}/.nix-profile/bin:${home}/.local/bin:${pkgs.jq}/bin:${pkgs.git}/bin:/usr/bin:/bin"
          ];
        };
      };

      systemd.user.timers.kic-copilot-failover = {
        Unit.Description = "Check every 2 minutes whether KIC or Max quota ran out for central command";
        Timer = {
          OnBootSec = "2min";
          OnUnitActiveSec = "2min";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
}
