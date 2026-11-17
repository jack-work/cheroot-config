{
  flake.modules.homeManager.preflight =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {
      options.my.preflight = {
        binaries = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };

        optional = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };

        pacman = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };

        etc = lib.mkOption {
          type = lib.types.attrsOf lib.types.lines;
          default = { };
        };
      };

      config.home.activation.preflight = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        preflight_missing=""
        preflight_path="${config.home.profileDirectory}/bin:$HOME/.nix-profile/bin${lib.optionalString config.my.platform.desktopFromNix ":/run/current-system/sw/bin"}:/usr/local/bin:/usr/bin:/bin"

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

        preflight_etc=""
        ${lib.concatStrings (
          lib.mapAttrsToList (
            path: text:
            let
              want = pkgs.writeText (baseNameOf path) text;
            in
            ''
              if ! ${pkgs.diffutils}/bin/cmp -s ${want} /etc/${path}; then
                preflight_etc="$preflight_etc
                sudo install -Dm644 ${want} /etc/${path}"
              fi
            ''
          ) config.my.preflight.etc
        )}

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

        if [ -n "$preflight_etc" ]; then
          echo "preflight: /etc differs from this configuration. Install it with:$preflight_etc" >&2
          exit 1
        fi
      '';
    };
}
