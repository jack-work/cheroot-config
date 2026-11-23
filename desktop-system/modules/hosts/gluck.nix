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
      "keel"
      "captains-log"
      "heavy"
      "aria2"
      "figaro-forms-bridge"
      "figaro-daemon"
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

      programs.figaro.daemon = {
        sshAuthSock = "%t/fleet-ssh-agent.sock";
        wants = [ "fleet-ssh-agent.service" ];
        environmentFile = "%h/.config/figaro/daemon.env";
        pathExtra = [
          "%h/.local/state/hush/bin"
          "%h/.cargo/bin"
          "%h/.bun/bin"
          "%h/go/bin"
          "/opt/brew/bin"
          "/opt/brew/sbin"
          "/usr/local/sbin"
          "/usr/local/bin"
          "/usr/bin"
          "/usr/bin/site_perl"
          "/usr/bin/vendor_perl"
          "/usr/bin/core_perl"
          "/usr/lib/rustup/bin"
        ];
      };

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
        Unit = {
          Description = "figaro's bearer web door on the tailnet only: https 7445 -> the daemon's web.sock";
          After = [ "figaro.service" ];
          BindsTo = [ "figaro.service" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "/usr/bin/tailscale serve --bg --https=7445 unix:%t/figaro/web.sock";
          ExecStop = "/usr/bin/tailscale serve --https=7445 off";
        };
        Install.WantedBy = [ "default.target" ];
      };

      systemd.user.services.figaro-door-tunnel = {
        Unit = {
          Description = "Reverse tunnel: spain 127.0.0.1:7446 -> figaro's bearer web door, for figaro-gateway";
          After = [
            "network-online.target"
            "figaro.service"
          ];
          BindsTo = [ "figaro.service" ];
          StartLimitIntervalSec = 0;
        };
        Service = {
          ExecStart = "/usr/bin/ssh -N -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o StreamLocalBindUnlink=yes -R 127.0.0.1:7446:%t/figaro/web.sock spain";
          Restart = "always";
          RestartSec = 10;
        };
        Install.WantedBy = [ "default.target" ];
      };

      systemd.user.services.figaro-forms-bridge.Unit = {
        After = [ "figaro.service" ];
        BindsTo = [ "figaro.service" ];
      };
      systemd.user.services.figaro-forms-bridge-tunnel.Unit.After = [ "figaro.service" ];

      xdg.configFile."systemd/user/figaro-approvals.service.d/10-daemon.conf".text = ''
        [Unit]
        After=figaro.service
        BindsTo=figaro.service
      '';
      xdg.configFile."systemd/user/figaro-approvals-tunnel.service.d/10-daemon.conf".text = ''
        [Unit]
        After=figaro.service
      '';

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
