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
        home.packages = lib.optionals config.my.platform.desktopFromNix (
          with pkgs;
          [
            niri
            swaybg
          ]
        );

        home.file.".local/share/wallpaper/wallpaper.jpg".source = config.my.wallpaper;

        # Helper scripts niri spawns. Kept executable and out of conf.d so the
        # compositor can exec them directly.
        home.file.".config/niri/scripts/kbd-inhibit.sh" = {
          source = ../../config/niri/scripts/kbd-inhibit.sh;
          executable = true;
        };

        xdg.configFile."niri/config.kdl".text =
          builtins.replaceStrings
            [ "@HOME@" "@WALLPAPER@" ]
            [
              config.home.homeDirectory
              "${config.home.homeDirectory}/.local/share/wallpaper/wallpaper.jpg"
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
