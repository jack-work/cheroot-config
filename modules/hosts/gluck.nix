# gluck — the desktop (CachyOS, Arch-family, nix as package manager).
#
# THIS HOST IS THE SOURCE OF TRUTH. cheroot was derived from gluck by copying
# config files, and drifted; the base configs in this repo are gluck's, with
# only the genuinely machine-specific parts factored out into this file.
#
# Home-manager has been installed here for 49 generations while managing
# essentially nothing but ~/.config/environment.d. This is the takeover.
#
# The FIRST switch collides with real files that already exist — ~/.bashrc,
# ~/.profile, ~/.config/fish/config.fish, mako, niri, tmux, waybar. Use:
#
#     home-manager switch --flake .#gluck@gluck -b bak
#
# which renames each to *.bak instead of refusing. Without -b, activation aborts.
{ inputs, config, ... }:
{
  flake.homeConfigurations."gluck@gluck" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";

    modules =
      (with config.flake.modules.homeManager; [
        base
        platform
        shell
        fish
        bash
        figaro
        prompt
        cli
        editor
        tmux
        fonts

        niri
        waybar
        mako
        rofi
        alacritty

        desktop
      ])
      ++ [
        {
          home.username = "gluck";
          home.homeDirectory = "/home/gluck";

          # Arch-family: pacman owns everything that draws, and the login
          # shell must come from /etc/shells. gcc 16.2.1 and node 26.4 are
          # already installed and must not be shadowed by older nixpkgs
          # builds sitting earlier in PATH. See modules/platform.nix.
          my.platform.desktopFromNix = false;
          my.platform.toolchainFromNix = false;

          # Dual 2560x1440 stacked vertically, DP-2 above DP-3. These are the
          # only host-specific niri lines gluck needs — and exactly what a
          # cheroot-derived config would have silently discarded, leaving
          # niri to re-arrange both monitors side by side at the next login.
          my.niri.extra = ''

            // ===== host: gluck (desktop) =====
            output "DP-2" {
                mode "2560x1440@59.91"
                position x=0 y=0
            }
            output "DP-3" {
                mode "2560x1440@59.91"
                position x=0 y=1440
            }
          '';
        }
      ];
  };
}
