# gluck — the desktop (CachyOS, Arch-family, nix as package manager).
#
# THIS HOST IS THE SOURCE OF TRUTH. cheroot was derived from gluck by copying
# config files and drifted; the base configs in this repo are gluck's, with only
# the genuinely machine-specific parts factored out into this file.
#
# Everything shared comes from flake.lib.defaultAspects. What remains below is
# exactly what is true of THIS machine and no other.
#
#     home-manager switch --flake .          # resolves gluck@gluck by hostname
#
# The FIRST switch collides with real files that already exist, so use `-b bak`
# once; without it, activation aborts rather than clobbering.
{ config, ... }:
{
  flake.homeConfigurations = config.flake.lib.mkHost {
    user = "gluck";
    host = "gluck";
    roles = [
      "desktop"
      # Opt-in aspects, not machine classes — `roles` is just extra aspect
      # names. See modules/audio.nix and modules/zig.nix.
      "audio"
      "zig"
    ];

    settings = {
      # Arch-family: pacman owns everything that draws, and gcc 16.2.1 / node
      # 26.4 are already installed and must not be shadowed by older nixpkgs
      # builds sitting earlier in PATH. See modules/platform.nix.
      my.platform.desktopFromNix = false;
      my.platform.toolchainFromNix = false;

      # Names a CachyOS binary, so it is host-specific rather than part of the
      # graphical aspect: plain Arch (cheroot) has no cachy-browser, and a
      # BROWSER pointing at a missing binary is worse than an unset one.
      # Rescued from gluck's hand-written ~/.profile, which home-manager
      # replaces wholesale.
      home.sessionVariables.BROWSER = "cachy-browser";

      # Dual 2560x1440 stacked vertically, DP-2 above DP-3. The only
      # host-specific niri lines gluck needs — and exactly what a
      # cheroot-derived config would have silently discarded, leaving niri to
      # re-arrange both monitors side by side at the next login.
      my.niri.extra = ''

        // ===== host: gluck (desktop) =====
        output "DP-2" {
            mode "2560x1440@59.91"
            position x=0 y=0
        }
        output "DP-3" {
            mode "2560x1440@59.91"
            position x=0 y=1440
        }
      '';
    };
  };
}
