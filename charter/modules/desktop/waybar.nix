{
  flake.modules.homeManager.waybar =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.waybar.modulesRight = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "custom/weather"
          "custom/wifi"
          "custom/storage"
          "memory"
          "cpu"
          "wireplumber"
        ];
      };

      options.my.waybar.extraStyle = lib.mkOption {
        type = lib.types.lines;
        default = "";
      };

      config = {
        my.preflight.binaries = [
          "waybar"
          "alacritty"
          "btop"
          "curl"
          "iwctl"
          "wiremix"
          "wpctl"
        ];

        home.packages = lib.optionals config.my.platform.desktopFromNix [ pkgs.waybar ];

        systemd.user.services.waybar = {
          Unit = {
            Description = "Waybar (niri session)";
            Documentation = "https://github.com/Alexays/Waybar/wiki/";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
            Requisite = [ "graphical-session.target" ];
          };
          Service = {
            Type = "simple";
            ExecStart =
              (if config.my.platform.desktopFromNix then "${pkgs.waybar}/bin/waybar" else "/usr/bin/waybar")
              + " -c %h/.config/waybar/config-niri -s %h/.config/waybar/style.css";
            ExecReload = "/bin/kill -SIGUSR2 $MAINPID";
            Restart = "always";
            RestartSec = 1;
            StartLimitIntervalSec = 0;
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };

        xdg.configFile = {
          "waybar/style.css".text =
            builtins.readFile ../../config/waybar/style.css + config.my.waybar.extraStyle;

          "waybar/modules".source = ../../config/waybar/modules;

          "waybar/config-niri".text =
            builtins.replaceStrings
              [ "@MODULES_RIGHT@" ]
              [ (lib.concatMapStringsSep ", " (m: "\"${m}\"") config.my.waybar.modulesRight) ]
              (builtins.readFile ../../config/waybar/config-niri);
        };
      };
    };
}
