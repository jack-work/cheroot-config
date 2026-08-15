# niri — the compositor's configuration (niri itself comes from pacman: it
# draws, so nixpkgs Mesa on a non-NixOS host would render it in software or not
# at all — nixpkgs#9415).
#
# `my.niri.extra` is `types.lines`, which the module system MERGES BY
# CONCATENATION. That is the dendritic win here: any aspect or role may append
# KDL without the base file knowing it exists. The old layout had a single
# host-supplied `my.niriExtra` string, so the shared file had to anticipate
# every difference in advance.
{
  flake.modules.homeManager.niri =
    { config, lib, ... }:
    {
      options.my.niri.extra = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = ''
          Host- or role-specific niri KDL, appended verbatim to the
          machine-agnostic base. Use for output blocks (scale, position) that
          only make sense on one machine. Multiple modules may contribute.
        '';
      };

      config.xdg.configFile."niri/config.kdl".text =
        builtins.replaceStrings [ "@HOME@" ] [ config.home.homeDirectory ] (
          builtins.readFile ../../config/niri/config.kdl
        )
        + config.my.niri.extra;

      # Validate the KDL we just wrote. Catching a bad config here beats
      # discovering it at the greeter with no way back in.
      config.home.activation.validateNiri = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
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
}
