{ config, ... }:
{
  flake.homeConfigurations = config.flake.lib.mkHost {
    user = "gluck";
    host = "gluck";
    roles = [
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
      "rou2"
      "remote-builder-host"
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

      my.figaroFormsBridge = {
        host = "100.92.208.109";
        hushExecutable = "/home/gluck/go/bin/hush";
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
