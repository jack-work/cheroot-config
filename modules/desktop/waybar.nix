# waybar.
#
# The base config DEFINES every module, including battery and backlight, but
# displays only what `my.waybar.modulesRight` lists. The default is the desktop
# set; roles/laptop.nix supplies its own list including battery and backlight.
#
# Because the option carries a `default` rather than a definition, a role can
# simply set it — no mkForce, no mkIf, and the base file never mentions laptops.
{
  flake.modules.homeManager.waybar =
    { config, lib, ... }:
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

      config.xdg.configFile = {
        "waybar/style.css".source = ../../config/waybar/style.css;
        "waybar/modules".source = ../../config/waybar/modules;

        # A single unambiguous @MODULES_RIGHT@ placeholder, NOT a multi-line
        # match. Nix '' strings strip common leading indentation, so matching a
        # pretty-printed JSON block silently fails and replaceStrings no-ops.
        "waybar/config".text =
          builtins.replaceStrings
            [ "@MODULES_RIGHT@" ]
            [ (lib.concatMapStringsSep ", " (m: "\"${m}\"") config.my.waybar.modulesRight) ]
            (builtins.readFile ../../config/waybar/config-niri);
      };
    };
}
