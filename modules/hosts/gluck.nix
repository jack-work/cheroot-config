# gluck — the desktop (CachyOS).
#
# Home-manager has been installed here for 49 generations while managing
# essentially nothing but ~/.config/environment.d. This is the takeover.
#
# The FIRST switch will collide with real files that already exist —
# ~/.config/fish, tmux.conf, alacritty.toml, starship.toml. Use:
#
#     home-manager switch --flake .#gluck@gluck -b bak
#
# which renames each existing file to *.bak instead of refusing. Without -b the
# activation aborts.
{ inputs, config, ... }:
{
  flake.homeConfigurations."gluck@gluck" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";

    modules =
      (with config.flake.modules.homeManager; [
        base
        shell
        fish
        bash
        figaro
        prompt
        cli
        editor
        tmux

        niri
        waybar
        mako
        rofi
        alacritty
        wallpaper

        desktop
      ])
      ++ [
        {
          home.username = "gluck";
          home.homeDirectory = "/home/gluck";

          # Desktop outputs are deliberately unlisted for the same reason
          # cheroot lists only its internal panel: niri auto-enables monitors
          # at their preferred mode. Add an output block here only to pin a
          # scale or position.
          my.niri.extra = ''

            // ===== host: gluck (desktop) =====
          '';
        }
      ];
  };
}
