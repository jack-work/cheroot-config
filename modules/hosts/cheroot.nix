# cheroot — ThinkPad X13 Gen 1 (20T2003UUS)
#   i7-10510U · Intel UHD (Comet Lake) · 13.3" 1920x1080 · 16 GB · plain Arch
#
# A host is a LIST OF ASPECT NAMES plus whatever is true of this machine alone.
# Compare with hosts/gluck.nix: the two differ by exactly one role name and
# their output blocks.
{ inputs, config, ... }:
{
  flake.homeConfigurations."marlowe@cheroot" = inputs.home-manager.lib.homeManagerConfiguration {
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

        laptop
      ])
      ++ [
        {
          home.username = "marlowe";
          home.homeDirectory = "/home/marlowe";

          # Internal panel. 1920x1080 at 13.3" is ~166 DPI; scale 1.0 is
          # legible but tight. Change to 1.25 and re-switch if it reads small.
          #
          # NOTE: this is the ONLY output block, and it names the internal
          # panel only. External monitors are deliberately unlisted so niri
          # auto-enables them at their preferred mode — that is what makes
          # this config portable.
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
