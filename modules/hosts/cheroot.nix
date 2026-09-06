# cheroot — ThinkPad X13 Gen 1 (20T2003UUS)
#   i7-10510U · Intel UHD (Comet Lake) · 13.3" 1920x1080 · 16 GB · plain Arch
#
# Compare with hosts/gluck.nix: the two machines differ by one role, one
# platform flag, and their output blocks. Everything else is shared, and neither
# file knows the other exists.
{ config, ... }:
{
  flake.homeConfigurations = config.flake.lib.mkHost {
    user = "marlowe";
    host = "cheroot";
    roles = [
      "laptop"
      # Opt-in aspects, not machine classes. See modules/desktop/zen.nix.
      "zen"
    ];

    settings = {
      my.platform.desktopFromNix = false;

      # This machine's zen (1.21.9b) uses the XDG path; gluck's (1.21.13b)
      # still uses ~/.zen. Both values read out of the real profiles.ini; a
      # wrong one configures a profile the browser never opens.
      my.zen.configPath = ".config/zen";
      my.zen.profileDir = "y9w3yl5l.Default (release)";

      # Temporary: this Zen speaks shortcut schema 19, the export was taken at
      # gluck's 20. Drop the line once `pacman -Syu zen-browser-bin` levels
      # them, and let the default take over.
      my.zen.shortcutsVersion = 19;

      # Clock centring at 1920px with the laptop module set. Measured: left
      # group ended x=137, clock 733-970, weather began x=996, so 596px slack
      # left against 26px right; equalising needs a 285px leftward shift, and
      # margin-right shifts 1:1, hence 287. Re-measure if modulesRight changes.
      # (The old hand-written sheet had a second copy of this under
      # `#clock#date`, which names two ids and never matched anything.)
      my.waybar.extraStyle = ''

        /* host: cheroot, 1920px */
        #clock {
            margin: 1px 287px 1px 2px;
        }
      '';

      # Minimal install with no system toolchain, so neovim's treesitter and
      # mason need nix to supply one. This is the flag's reason to exist: gluck
      # sets it false, cheroot true, and neither has to know about the other.
      my.platform.toolchainFromNix = true;

      # Internal panel. 1920x1080 at 13.3" is ~166 DPI; scale 1.0 is legible but
      # tight. Change to 1.25 and re-switch if it reads small.
      #
      # This is the ONLY output block, and it names the internal panel only.
      # External monitors are deliberately unlisted so niri auto-enables them at
      # their preferred mode — that is what keeps the config portable.
      my.niri.extra = ''

        // ===== host: cheroot (laptop) =====
        output "eDP-1" {
            scale 1.0
        }
      '';
    };
  };
}
