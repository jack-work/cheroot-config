{ lib, ... }:
#=============================================================================
# cheroot — ThinkPad X13 Gen 1 (20T2003UUS)
#   i7-10510U · Intel UHD (Comet Lake) · 13.3" 1920x1080 · 16 GB
#=============================================================================
{
  # Laptop: show battery and backlight in the bar. The base waybar config
  # already DEFINES both modules; it simply does not display them (correct for
  # a desktop). This is the only host difference the bar needs.
  my.waybarModulesRight = [
    "custom/weather"
    "custom/wifi"
    "custom/storage"
    "memory"
    "cpu"
    "backlight"
    "wireplumber"
    "battery"
  ];

  # Internal panel. 1920x1080 at 13.3" is ~166 DPI; scale 1.0 is legible but
  # tight. Left at 1.0 per the default decision — change to 1.25 and re-switch
  # if it reads small. Fractional scaling in niri is well supported.
  #
  # NOTE: this is the ONLY output block, and it names the internal panel only.
  # External monitors are deliberately unlisted so niri auto-enables them at
  # their preferred mode — that is what makes this config portable.
  my.niriExtra = ''

    // ===== host: cheroot (laptop) =====
    output "eDP-1" {
        scale 1.0
    }
  '';
}
