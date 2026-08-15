# alacritty — terminal configuration only; the binary comes from pacman
# (GPU-accelerated, so nixpkgs Mesa on a non-NixOS host is a trap).
#
# alacritty.toml sets no `[terminal] shell`, so it launches the login shell from
# /etc/passwd. Switching between fish and bash therefore needs no change here.
{
  flake.modules.homeManager.alacritty = {
    xdg.configFile."alacritty/alacritty.toml".source = ../../config/alacritty/alacritty.toml;
  };

  flake.modules.homeManager.wallpaper = {
    home.file.".local/share/wallpaper/wallpaper.jpg".source = ../../wallpaper.jpg;
  };
}
