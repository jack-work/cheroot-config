{
  flake.modules.homeManager.niri =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cursorTheme = "vimix-kanagawa-cursors-lotus";
    in
    {
      options.my.niri.extra = lib.mkOption {
        type = lib.types.lines;
        default = "";
      };

      options.my.niri.inputExtra = lib.mkOption {
        type = lib.types.lines;
        default = "";
      };

      options.my.niri.bindsExtra = lib.mkOption {
        type = lib.types.lines;
        default = "";
      };

      options.my.wallpaper = lib.mkOption {
        type = lib.types.path;
        default = ../../wallpaper.jpg;
      };

      config = {
        my.preflight.binaries = [
          "xwayland-satellite"
          "swaybg"
          "mako"
          "makoctl"
          "niri"
          "systemctl"
          "dbus-update-activation-environment"
        ];

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
          "helium-browser"
        ];

        home.packages = lib.optionals config.my.platform.desktopFromNix (
          with pkgs;
          [
            niri
            swaybg
          ]
        );

        home.file.".local/share/wallpaper/wallpaper.jpg".source = config.my.wallpaper;

        my.preflight.pacman = [ "vimix-kanagawa-cursors" ];

        home.file.".icons/default/index.theme".text = ''
          [Icon Theme]
          Inherits=${cursorTheme}
        '';

        dconf.settings."org/gnome/desktop/interface" = {
          cursor-theme = cursorTheme;
          cursor-size = 16;
        };

        xdg.configFile."niri/config.kdl".text =
          builtins.replaceStrings
            [ "@HOME@" "@WALLPAPER@" "@INPUT_EXTRA@" "@BINDS_EXTRA@" "@CURSOR_THEME@" ]
            [
              config.home.homeDirectory
              "${config.home.homeDirectory}/.local/share/wallpaper/wallpaper.jpg"
              config.my.niri.inputExtra
              config.my.niri.bindsExtra
              cursorTheme
            ]
            (builtins.readFile ../../config/niri/config.kdl)
          + config.my.niri.extra;

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
