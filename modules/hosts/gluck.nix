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
      "zen"
      "helium"
      "greeter"
      "splash"
      "keel-sync"
      "keel"
    ];

    settings = {
      # Arch-family: pacman owns everything that draws, and gcc 16.2.1 / node
      # 26.4 are already installed and must not be shadowed by older nixpkgs
      # builds sitting earlier in PATH. See modules/platform.nix.
      my.platform.desktopFromNix = false;
      my.platform.toolchainFromNix = false;

      # polkit-KDE here, polkit-GNOME on cheroot. Whichever the machine has is
      # a fact about the machine, so it is spawned from its host file, below in
      # the same my.niri.extra that carries this machine's outputs.
      my.preflight.binaries = [ "/usr/lib/polkit-kde-authentication-agent-1" ];
      my.preflight.pacman = [ "polkit-kde-agent" ];

      # Names a CachyOS binary, so it is host-specific rather than part of the
      # graphical aspect: plain Arch (cheroot) has no cachy-browser, and a
      # BROWSER pointing at a missing binary is worse than an unset one.
      # Rescued from gluck's hand-written ~/.profile, which home-manager
      # replaces wholesale.
      home.sessionVariables.BROWSER = "cachy-browser";

      # Zen's profile directory, read out of ~/.zen/profiles.ini. Do not guess:
      # a wrong value configures a profile the browser never opens.
      my.zen.profileDir = "829beuvl.Default (release)";

      my.helium.exits = {
        seattle = "root@exit-seattle";
        newjersey = "root@exit-newjersey";
        amsterdam = "root@exit-amsterdam";
      };
      my.helium.defaultExit = "seattle";

      # THIS IS THE MACHINE WHERE FIGARO IS WRITTEN, so it does not take figaro
      # from this repo's lockfile. 76 tags and counting; the working tree is
      # routinely ahead of the newest one. Pinning here would cost
      # `nix flake update figaro` + a commit + a switch per build, and buy
      # nothing a dev host wants.
      #
      # The binary stays in the imperative profile, upgraded with the one
      # command figaro itself prints (`figaro update` → `nix profile upgrade
      # figaro`). This null is not an omission — it is the declaration that
      # another owner is intended. See modules/figaro.nix.
      my.figaro.package = null;

      # Likewise hush: gluck develops it (~/dev/hush) and installs it with
      # `go install`, so the pin would be shadowed by a binary that is routinely
      # ahead of it. See modules/hush.nix.
      my.hush.package = null;

      # Dual 2560x1440 stacked vertically, Dell above Lenovo. Named by EDID
      # make/model/serial rather than connector: DP-N is the GPU socket, so
      # moving a cable renames the monitor and silently drops its position.
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
