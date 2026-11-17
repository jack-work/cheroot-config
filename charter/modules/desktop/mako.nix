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
