# waybar.
#
# The base config DEFINES every module, including battery and backlight, but
# displays only what `my.waybar.modulesRight` lists. The default is gluck's
# desktop set; roles/laptop.nix supplies its own list adding backlight and
# battery.
#
# Because the option carries a `default` rather than a definition, a role simply
# sets it — no mkForce, no mkIf, and the base file never mentions laptops.
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
        description = "Right-hand waybar modules, in display order.";
      };

      # WHY A HOST NEEDS TO APPEND CSS AT ALL.
      #
      # waybar centres `modules-center` in the FULL bar width, and GTK centres a
      # widget INCLUDING its margins. A symmetric margin therefore moves the
      # clock by exactly zero pixels; only an ASYMMETRIC one shifts it. The
      # correcting value depends on the bar's pixel width AND on how wide the
      # left and right groups render — which is to say on the screen and on
      # `modulesRight`. It cannot be shared, and it cannot be derived.
      #
      # `types.lines` so several definitions concatenate rather than conflict,
      # the same mechanism `my.niri.extra` uses.
      options.my.waybar.extraStyle = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = ''
          CSS appended after the shared stylesheet. Later rules of equal
          specificity win, so a host overrides by restating the selector.
        '';
      };

      config = {
        home.packages = lib.optionals config.my.platform.desktopFromNix [ pkgs.waybar ];

        # WAYBAR IS A SYSTEMD USER UNIT, NOT A COMPOSITOR SPAWN.
        #
        # niri's `spawn-at-startup "waybar"` used to start it, and waybar was
        # missing after roughly every other boot: the compositor is still
        # bringing outputs up when the session target is reached, and waybar
        # exits on that race. spawn-at-startup fires once and cannot retry, so
        # the bar simply never appeared. `Restart=always` with `RestartSec=1`
        # and no start-limit is the cure — it comes back until the outputs are
        # there.
        #
        # Declaring it HERE rather than leaving a hand-written unit in
        # ~/.config/systemd/user matters for two reasons: the next host gets
        # the fix for free, and there is exactly one owner. A hand-written unit
        # plus niri's spawn is how you end up with two bars.
        #
        # PartOf/Requisite graphical-session.target: the bar belongs to the
        # session and must not linger after it, or outlive a compositor crash.
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
            # Same rule as everything else that draws: pacman owns the GPU
            # stack on Arch (nixpkgs#9415), so use the distro binary unless the
            # host says nix provides the desktop. See modules/platform.nix.
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
          # TEXT, not source: the host's `extraStyle` is concatenated after the
          # shared sheet so the last rule wins. A bare `.source` would make the
          # stylesheet unextendable and force every screen-specific tweak into
          # the shared file, where it would be wrong for the other machine.
          "waybar/style.css".text =
            builtins.readFile ../../config/waybar/style.css + config.my.waybar.extraStyle;

          "waybar/modules".source = ../../config/waybar/modules;

          # A single unambiguous @MODULES_RIGHT@ placeholder, NOT a multi-line
          # match. Nix '' strings strip common leading indentation, so matching
          # a pretty-printed JSON block silently fails and replaceStrings no-ops.
          #
          # niri spawns waybar with `-c ~/.config/waybar/config-niri`, so the
          # file must land under that exact name.
          "waybar/config-niri".text =
            builtins.replaceStrings
              [ "@MODULES_RIGHT@" ]
              [ (lib.concatMapStringsSep ", " (m: "\"${m}\"") config.my.waybar.modulesRight) ]
              (builtins.readFile ../../config/waybar/config-niri);
        };
      };
    };
}
