# Fonts.
#
# THE GAP THIS CLOSES: on gluck the Nerd Font is hand-installed under
# ~/.local/share/fonts/GoMonoNerdFont/ and owned by no package at all — which is
# why cheroot, built from gluck by copying *config* files, renders boxes instead
# of glyphs. Configs referenced a font that nothing installed.
#
# Both fonts below are named by configuration elsewhere in this repo, so they
# belong to the same dependency graph:
#
#   GoMono Nerd Font  -> config/alacritty/alacritty.toml, config/waybar/style.css
#   Sarasa UI SC      -> config/mako/config
#
# fontconfig.enable makes home-manager generate the fontconfig files that let
# non-nix applications (pacman's alacritty, waybar, mako) actually FIND fonts
# installed into the nix profile. Without it the packages are present and
# invisible.
{
  flake.modules.homeManager.fonts =
    { pkgs, ... }:
    {
      fonts.fontconfig.enable = true;

      home.packages = with pkgs; [
        nerd-fonts.go-mono
        sarasa-gothic
      ];
    };
}
