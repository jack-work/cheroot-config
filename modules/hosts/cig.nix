{ config, ... }:
{
  flake.homeConfigurations = config.flake.lib.mkHost {
    user = "cig";
    host = "gluck";
    roles = [
      "desktop"
      "helium"
    ];

    settings = {
      my.platform.desktopFromNix = false;
      my.platform.toolchainFromNix = false;

      my.preflight.binaries = [ "/usr/lib/polkit-kde-authentication-agent-1" ];
      my.preflight.pacman = [ "polkit-kde-agent" ];

      my.niri.extra = ''

        // ===== host: gluck (desktop), user cig =====
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
