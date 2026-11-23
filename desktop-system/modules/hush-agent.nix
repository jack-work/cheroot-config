{ inputs, ... }:
{
  flake.modules.homeManager.hush-agent =
    { pkgs, ... }:
    let
      hush = inputs.hush.packages.${pkgs.stdenv.hostPlatform.system}.hush;
    in
    {
      systemd.user.sockets.hush-agent = {
        Unit = {
          Description = "hush agent socket";
          Documentation = "https://github.com/jack-work/hush";
        };
        Socket = {
          ListenStream = "%t/hush/agent.sock";
          SocketMode = "0600";
          DirectoryMode = "0700";
        };
        Install.WantedBy = [ "sockets.target" ];
      };

      systemd.user.services.hush-agent = {
        Unit = {
          Description = "hush agent";
          Documentation = "https://github.com/jack-work/hush";
          Requires = [ "hush-agent.socket" ];
          After = [ "hush-agent.socket" ];
          StartLimitIntervalSec = 0;
        };
        Service = {
          Type = "exec";
          ExecStart = "${hush}/bin/hush up";
          Restart = "no";
          Environment = "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus";
        };
      };

      xdg.configFile."systemd/user/hush-agent.socket".force = true;
      xdg.configFile."systemd/user/hush-agent.service".force = true;
    };
}
