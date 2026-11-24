{ config, ... }:
{
  flake.homeConfigurations = config.flake.lib.mkHost {
    user = "marlowe";
    host = "cheroot";
    extraAspects = [
      "laptop"
      "muse-code"
      "helium"
      "greeter"
      "cache-client"
    ];

    settings = {
      my.platform.desktopFromNix = false;
      my.platform.toolchainFromNix = true;

      my.preflight.binaries = [ "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1" ];
      my.preflight.pacman = [
        "bolt"
        "polkit-gnome"
        "ttf-jetbrains-mono-nerd"
      ];

      my.hush.unlock = ''
        ttl = "12h"

        [unlock]
        method = "file"
        file = "/home/marlowe/.config/hush/passphrase"
      '';

      my.waybar.extraStyle = ''

        /* host: cheroot, 1920px */
        #clock {
            margin: 1px 287px 1px 2px;
        }
      '';

      my.niri.extra = ''

        // ===== host: cheroot (laptop) =====
        output "eDP-1" {
            scale 1.0
            position x=320 y=2880
        }

        output "DVI-I-1" {
            mode "1920x1080@100.000"
            scale 0.8
        }

        output "Dell Inc. DELL U2719D DDZQJS2" {
            position x=0 y=0
        }
        output "Lenovo Group Limited LEN P27h-10 0x58314841" {
            position x=0 y=1440
        }

        spawn-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
      '';
    };
  };
}
