# cheroot — ThinkPad X13 Gen 1 (20T2003UUS)
#   i7-10510U · Intel UHD (Comet Lake) · 13.3" 1920x1080 · 16 GB · plain Arch
#
# A host is a LIST OF ASPECT NAMES plus whatever is true of this machine alone.
# Compare with hosts/gluck.nix: they differ by one role, three platform flags,
# and their output blocks. Everything else is shared.
{ inputs, config, ... }:
{
  flake.homeConfigurations."marlowe@cheroot" = inputs.home-manager.lib.homeManagerConfiguration {
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

        laptop
      ])
      ++ [
        {
          home.username = "marlowe";
          home.homeDirectory = "/home/marlowe";

          # Arch: pacman owns the graphical stack and the login shell.
          my.platform.desktopFromNix = false;
          # Minimal install with no system toolchain, so neovim's treesitter
          # and mason need nix to supply one. This is the flag's reason to
          # exist: gluck sets it false, cheroot true, and neither has to know
          # about the other.
          my.platform.toolchainFromNix = true;

          # Internal panel. 1920x1080 at 13.3" is ~166 DPI; scale 1.0 is
          # legible but tight. Change to 1.25 and re-switch if it reads small.
          #
          # This is the ONLY output block, and it names the internal panel
          # only. External monitors are deliberately unlisted so niri
          # auto-enables them at their preferred mode.
          my.niri.extra = ''

            // ===== host: cheroot (laptop) =====
            output "eDP-1" {
                scale 1.0
            }
          '';
        }
      ];
  };
}
