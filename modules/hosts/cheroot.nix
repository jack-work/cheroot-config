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

      # No profile exists here yet — cheroot has the AUR binary installed and
      # has never launched it — so home-manager creates one at this name and
      # Zen adopts it. Compare gluck, which must name the random prefix Zen
      # generated for it years ago.
      my.zen.profileDir = "default";

      # THE BAR IS CENTRED FOR 1920px, AND THIS IS WHY IT IS HOST-SPECIFIC.
      #
      # waybar centres `modules-center` in the full bar width and GTK centres a
      # widget including its margins, so only an asymmetric margin moves the
      # clock. Measured on cheroot at 1920px with the laptop module set: the
      # left group ended at x=137, the clock occupied 733→970 and weather began
      # at x=996 — 596px of slack on the left against 26px on the right.
      # Equalising at 311px needs a 285px leftward shift, and margin-right was
      # measured to shift the widget 1:1 (not by half), hence 2 + 285 = 287.
      #
      # ONE RULE, NOT TWO. The old hand-written stylesheet on cheroot carried a
      # second copy of this margin under `#clock#date` with a different number
      # (574). That selector names two ids and is invalid CSS — it matched
      # nothing and never had any effect. It is deliberately not carried over.
      #
      # These numbers are tuned to THIS screen and THIS module list. Adding a
      # right-hand module, or a battery reading that gains a digit, means
      # re-measuring. On gluck's 2560px screen the shared symmetric margins are
      # already correct, which is exactly why this block cannot live in the
      # shared stylesheet.
      my.waybar.extraStyle = ''

        /* ===== host: cheroot — clock centring at 1920px ===== */
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
