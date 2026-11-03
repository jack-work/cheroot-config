{
  flake.modules.homeManager.idle-lock =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.idleLock;
      waybarSignal = 9;
      span = s: if lib.mod s 3600 == 0 then "${toString (s / 3600)}h" else "${toString (s / 60)}m";
      swaylock =
        if config.my.platform.desktopFromNix then lib.getExe pkgs.swaylock else "/usr/bin/swaylock";
      lock = "${swaylock} -f -c 000000";
      idleLock = pkgs.writeShellApplication {
        name = "idle-lock";
        runtimeInputs = [ pkgs.procps ];
        text = ''
          state="''${XDG_RUNTIME_DIR:?}/idle-lock"
          mode=normal
          [[ -e $state ]] && mode=long

          case "''${1:-}" in
            is)
              [[ $mode == "''${2:?normal or long}" ]]
              ;;
            toggle)
              if [[ $mode == long ]]; then rm -f "$state"; else : >"$state"; fi
              pkill --signal RTMIN+${toString waybarSignal} -x waybar || true
              ;;
            waybar)
              if [[ $mode == long ]]; then
                printf '{"text":"%s","tooltip":"%s","class":"long"}\n' \
                  "󰌾 ${span cfg.long}" \
                  "Locks after ${span cfg.long} idle. Click or Mod+I for ${span cfg.normal}."
              else
                printf '{"text":""}\n'
              fi
              ;;
            *)
              echo "usage: idle-lock is normal|long | toggle | waybar" >&2
              exit 2
              ;;
          esac
        '';
      };
    in
    {
      options.my.idleLock = {
        normal = lib.mkOption {
          type = lib.types.ints.positive;
          default = 300;
          description = "Seconds idle before the screen locks.";
        };
        long = lib.mkOption {
          type = lib.types.ints.positive;
          default = 3600;
          description = "Seconds idle before the screen locks while Mod+I has the long mode on.";
        };
      };

      config = {
        home.packages = [ idleLock ] ++ lib.optionals config.my.platform.desktopFromNix [ pkgs.swaylock ];

        my.preflight.binaries = lib.optionals (!config.my.platform.desktopFromNix) [ swaylock ];

        services.swayidle = {
          enable = true;
          timeouts = [
            {
              timeout = cfg.normal;
              command = "${lib.getExe idleLock} is normal && ${lock}";
            }
            {
              timeout = cfg.long;
              command = "${lib.getExe idleLock} is long && ${lock}";
            }
          ];
          events.before-sleep = lock;
        };

        my.niri.bindsExtra = ''
          Mod+I { spawn "${lib.getExe idleLock}" "toggle"; }
        '';
      };
    };
}
