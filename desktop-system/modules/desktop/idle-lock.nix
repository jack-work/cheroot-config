{ inputs, ... }:
{
  flake.modules.homeManager.idle-lock =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      swaylock =
        if config.my.platform.desktopFromNix then lib.getExe pkgs.swaylock else "/usr/bin/swaylock";
      cerrojo = lib.getExe config.services.cerrojo.package;
    in
    {
      imports = [ inputs.cerrojo.homeManagerModules.default ];

      services.cerrojo = {
        enable = true;
        lockCommand = "${swaylock} -f -c 000000";
      };

      home.packages = lib.optionals config.my.platform.desktopFromNix [ pkgs.swaylock ];

      my.preflight.binaries = lib.optionals (!config.my.platform.desktopFromNix) [ swaylock ];

      my.niri.bindsExtra = ''
        Mod+I { spawn "${cerrojo}" "next"; }
        Mod+Shift+I { spawn "${cerrojo}" "prev"; }
      '';
    };
}
