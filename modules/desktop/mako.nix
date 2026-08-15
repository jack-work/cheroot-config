# mako — notifications. mako itself comes from pacman (it draws).
{
  flake.modules.homeManager.mako =
    { pkgs, ... }:
    {
      home.packages = [ (pkgs.callPackage ../../pkgs/mako-term.nix { }) ];

      xdg.configFile."mako/config".source = ../../config/mako/config;

      home.file.".config/mako/mako-term.sh" = {
        source = ../../config/mako/mako-term.sh;
        executable = true;
      };
    };
}
