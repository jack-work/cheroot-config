{ config, ... }:
{
  flake.homeConfigurations = config.flake.lib.mkHost {
    user = "gluck";
    host = "gluck";
    extraAspects = [
      "desktop"
      "muse-code"
      "audio"
      "zig"
      "helium"
      "greeter"
      "splash"
      "keel-sync"
      "fleet-ssh-agent"
      "hush-agent"
      "keel"
      "captains-log"
      "heavy"
      "aria2"
      "figaro-forms-bridge"
      "rou2"
      "remote-builder-host"
      "roster"
      "keel-tasks"
    ];

    settings = {
      my.platform.desktopFromNix = false;
      my.platform.toolchainFromNix = false;

      my.preflight.binaries = [ "/usr/lib/polkit-kde-authentication-agent-1" ];
      my.preflight.pacman = [ "polkit-kde-agent" ];

      my.figaro.package = null;
      my.hush.package = null;

      my.remoteBuilderHost = {
        enable = true;
        clientKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIH5ozXOcnYVTNKRnp6bO7ywYhsuimKYDOg+3yOND2qC spain nix-daemon -> gluck nixremote";
        clientAddress = "100.103.40.20";
        clientSigningKey = "spain-1:9aBltrVUZU3rVBT7nWaUFAXoJjVcwfsVw0PdriywiSc=";
        daemon = "/usr/bin/nix-daemon";
      };

      my.figaroFormsBridge.tunnel = "spain";

      systemd.user.services.figaro-web-serve = {
        Unit.Description = "figaro's bearer web door on the tailnet only: https 7445 -> the daemon's web.sock";
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "/usr/bin/tailscale serve --bg --https=7445 unix:%t/figaro/web.sock";
          ExecStop = "/usr/bin/tailscale serve --https=7445 off";
        };
        Install.WantedBy = [ "default.target" ];
      };

      systemd.user.services.figaro-forms-bridge-tunnel = {
        Unit = {
          Wants = [ "fleet-ssh-agent.service" ];
          After = [ "fleet-ssh-agent.service" ];
        };
        Service.Environment = [ "SSH_AUTH_SOCK=%t/fleet-ssh-agent.sock" ];
      };

      systemd.user.services.figaro-door-tunnel = {
        Unit = {
          Description = "Reverse tunnel: spain 127.0.0.1:7446 -> figaro's bearer web door, for figaro-gateway";
          After = [ "network-online.target" "fleet-ssh-agent.service" ];
          Wants = [ "fleet-ssh-agent.service" ];
          StartLimitIntervalSec = 0;
        };
        Service = {
          Environment = [ "SSH_AUTH_SOCK=%t/fleet-ssh-agent.sock" ];
          ExecStart = "/usr/bin/ssh -N -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o StreamLocalBindUnlink=yes -R 127.0.0.1:7446:%t/figaro/web.sock spain";
          Restart = "always";
          RestartSec = 10;
        };
        Install.WantedBy = [ "default.target" ];
      };

      my.niri.extra = ''

        // ===== host: gluck (desktop) =====
        output "Dell Inc. DELL U2719D DDZQJS2" {
            mode "2560x1440@59.951"
            position x=0 y=0
        }
        output "Lenovo Group Limited LEN P27h-10 0x58314841" {
            mode "2560x1440@59.951"
            position x=0 y=1440
        }

        spawn-at-startup "/usr/lib/polkit-kde-authentication-agent-1"
      '';
    };
  };
}
