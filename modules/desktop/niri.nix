# niri — the compositor's configuration.
#
# On Arch the compositor itself comes from pacman: it draws, so nixpkgs Mesa on
# a non-NixOS host renders it in software or not at all (nixpkgs#9415). On NixOS
# set my.platform.desktopFromNix and nix provides it. See modules/platform.nix.
#
# `my.niri.extra` is `types.lines`, which the module system MERGES BY
# CONCATENATION. That is the dendritic win: any aspect or role may append KDL
# without the base file knowing it exists. The old layout had a single
# host-supplied string, so the shared file had to anticipate every difference.
{
  flake.modules.homeManager.niri =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.niri.extra = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = ''
          Host- or role-specific niri KDL, appended verbatim to the
          machine-agnostic base. Use for output blocks (mode, scale, position)
          that only make sense on one machine. Multiple modules may contribute.
        '';
      };

      options.my.niri.inputExtra = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = ''
          Host- or role-specific KDL spliced INSIDE the single `input` node.
          niri permits exactly one `input` node, so roles that add hardware
          rules (a touchpad, a trackpoint) must contribute here rather than
          via `my.niri.extra`, which appends at top level.
        '';
      };

      options.my.wallpaper = lib.mkOption {
        type = lib.types.path;
        default = ../../wallpaper.jpg;
        description = ''
          Image swaybg paints at startup. Managed into the nix store and
          referenced by absolute path, so it does not depend on a file happening
          to sit in ~/Pictures.
        '';
      };

      config = {
        # Everything the compositor spawns at startup, or on a keybind. niri
        # reports a failed spawn nowhere a human looks, so the names are
        # asserted at switch time instead. Per-machine spawns (the polkit
        # agent, the idle locker) assert themselves where they are declared.
        my.preflight.binaries = [
          "xwayland-satellite"
          "swaybg"
          "mako"
          "makoctl"
          "niri"
          "systemctl"
          "dbus-update-activation-environment"
        ];

        # Keybinds only. A dead one costs a keypress, not a session.
        my.preflight.optional = [
          "alacritty"
          "rofi"
          "grim"
          "slurp"
          "swappy"
          "wl-paste"
          "playerctl"
          "pactl"
          "amixer"
          "nemo"
          "gnome-calculator"
          "bunx"
          "zen-browser"
        ];

        home.packages = lib.optionals config.my.platform.desktopFromNix (
          with pkgs;
          [
            niri
            swaybg
          ]
        );

        home.file.".local/share/wallpaper/wallpaper.jpg".source = config.my.wallpaper;

        # No helper scripts. `.config/niri/scripts/kbd-inhibit.sh` lived here
        # until 2026-08-21; Mod+Escape now calls niri's own
        # toggle-keyboard-shortcuts-inhibit action directly.

        xdg.configFile."niri/config.kdl".text =
          builtins.replaceStrings
            [ "@HOME@" "@WALLPAPER@" "@INPUT_EXTRA@" ]
            [
              config.home.homeDirectory
              "${config.home.homeDirectory}/.local/share/wallpaper/wallpaper.jpg"
              config.my.niri.inputExtra
            ]
            (builtins.readFile ../../config/niri/config.kdl)
          + config.my.niri.extra;

        # Validate the KDL we just wrote. Catching a bad config here beats
        # discovering it at the greeter with no way back in.
        home.activation.validateNiri = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          if command -v niri >/dev/null 2>&1; then
            if niri validate -c "${config.home.homeDirectory}/.config/niri/config.kdl" >/dev/null 2>&1; then
              echo "niri config: VALID"
            else
              echo "WARNING: niri config FAILED validation:"
              niri validate -c "${config.home.homeDirectory}/.config/niri/config.kdl" 2>&1 | head -20 || true
            fi
          fi
        '';
      };
    };
}
