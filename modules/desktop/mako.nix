# mako — notifications.
#
# The config uses `invoke-action term` for figaro's supervisor pings rather than
# shelling out to a script with a hardcoded path. That matters for portability:
# the older cheroot config carried `exec /home/marlowe/.config/mako/mako-term.sh`,
# which was silently wrong on every host but one.
{
  flake.modules.homeManager.mako =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = [
        (pkgs.callPackage ../../pkgs/mako-term.nix { })
      ]
      ++ lib.optionals config.my.platform.desktopFromNix [ pkgs.mako ];

      xdg.configFile."mako/config".source = ../../config/mako/config;

      home.file.".config/mako/mako-term.sh" = {
        source = ../../config/mako/mako-term.sh;
        executable = true;
      };
    };
}
