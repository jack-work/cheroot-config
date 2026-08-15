# alacritty — terminal configuration.
#
# alacritty.toml sets no `[terminal] shell`, so it launches the login shell from
# /etc/passwd. Switching between fish and bash therefore needs no change here.
#
# The font it names (GoMono Nerd Font) is installed by modules/fonts.nix. That
# pairing is the whole reason fonts became an aspect: the config and the package
# that satisfies it must travel together, or you get a terminal full of boxes —
# which is exactly what happened on cheroot.
{
  flake.modules.homeManager.alacritty =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = lib.optionals config.my.platform.desktopFromNix [ pkgs.alacritty ];

      xdg.configFile."alacritty/alacritty.toml".source = ../../config/alacritty/alacritty.toml;
    };
}
