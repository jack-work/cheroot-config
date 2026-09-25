# preflight: assert what the generated config SPAWNS but does not install.
#
# Every config file here can name a program that is not on the box. niri's
# spawn-at-startup, waybar's on-click, a keybind: all of them are strings, and
# a string that names nothing fails at the moment you click, into a log nobody
# reads. Two sessions were spent on exactly this. `wiremix` was absent on the
# laptop, so the volume button did nothing for weeks, and the only evidence
# was four lines of "Failed to spawn command" in the user journal. `fcitx5`
# and a polkit agent had been in spawn-at-startup since July, neither
# installed, so the session came up with no input method and no way to answer
# an authentication prompt.
#
# So the requirement is declared next to the thing that requires it, and
# checked when the generation is built rather than when a human clicks:
#
#   my.preflight.binaries = [ "wiremix" "wpctl" ];   session breaks without it
#   my.preflight.optional = [ "nemo" ];              one keybind is dead
#   my.preflight.pacman   = [ "sof-firmware" ];      a package with no binary
#
# `binaries` FAILS the switch. That is the whole point: `validateNiri` printed
# WARNING and exited 0, which is how a fatal niri config error shipped and ran
# for six days. A check that cannot fail is a check nobody reads.
#
# `optional` prints the missing names and lets the switch through, for things
# only a keybind reaches. It names them rather than counting them, because
# "2 missing" sends you back to grep.
{
  flake.modules.homeManager.preflight =
    { lib, config, ... }:
    {
      options.my.preflight = {
        binaries = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "wiremix" ];
          description = ''
            Commands the session cannot work without: anything in
            spawn-at-startup, and the handlers of waybar modules that are
            actually displayed. A name here that is not on PATH fails
            activation. Absolute paths are allowed and tested for
            executability instead.
          '';
        };

        optional = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "gnome-calculator" ];
          description = ''
            Commands only a keybind or a right-click reaches. Missing ones are
            listed at the end of activation and cost nothing else.
          '';
        };

        pacman = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "sof-firmware" ];
          description = ''
            pacman packages this configuration depends on but cannot install,
            because they draw, ship firmware, or own a system unit. Asserted
            with `pacman -Qq`, never installed. Skipped where there is no
            pacman, so a NixOS or WSL host carries the list harmlessly.
          '';
        };
      };

      config.home.activation.preflight = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        preflight_missing=""

        # PATH during activation is not the PATH niri hands a spawned child:
        # home-manager runs with its own, and the session's includes the nix
        # profile and /usr/bin. Search the union, or a pacman binary reads as
        # missing on a machine that plainly has it.
        preflight_path="${config.home.profileDirectory}/bin:$HOME/.nix-profile/bin:/usr/local/bin:/usr/bin:/bin"

        preflight_have() {
          case "$1" in
            /*) [ -x "$1" ] ;;
            *) PATH="$preflight_path" command -v "$1" >/dev/null 2>&1 ;;
          esac
        }

        for bin in ${lib.escapeShellArgs config.my.preflight.binaries}; do
          preflight_have "$bin" || preflight_missing="$preflight_missing $bin"
        done

        preflight_absent=""
        for bin in ${lib.escapeShellArgs config.my.preflight.optional}; do
          preflight_have "$bin" || preflight_absent="$preflight_absent $bin"
        done

        preflight_unowned=""
        if [ -x /usr/bin/pacman ]; then
          for pkg in ${lib.escapeShellArgs config.my.preflight.pacman}; do
            /usr/bin/pacman -Qq "$pkg" >/dev/null 2>&1 || preflight_unowned="$preflight_unowned $pkg"
          done
        fi

        if [ -n "$preflight_absent" ]; then
          echo "preflight: optional, absent:$preflight_absent"
        fi

        if [ -n "$preflight_missing" ] || [ -n "$preflight_unowned" ]; then
          echo "preflight: THIS CONFIGURATION NAMES PROGRAMS THIS MACHINE DOES NOT HAVE." >&2
          [ -n "$preflight_missing" ] && echo "preflight: not on PATH:$preflight_missing" >&2
          [ -n "$preflight_unowned" ] && echo "preflight: not installed by pacman:$preflight_unowned" >&2
          echo "preflight: install them, or stop referring to them. Nothing was activated." >&2
          exit 1
        fi
      '';
    };
}
