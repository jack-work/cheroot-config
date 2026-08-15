# Role: laptop.
#
# This file OWNS everything that is true because the machine has a battery, a
# backlight and a trackpad. Nothing in the shared configuration mentions
# laptops; the role adds itself. That inversion is the point of the pattern.
{
  flake.modules.homeManager.laptop = {
    my.waybar.modulesRight = [
      "custom/kbdinhibit"
      "custom/weather"
      "custom/wifi"
      "custom/storage"
      "memory"
      "cpu"
      "backlight"
      "wireplumber"
      "battery"
    ];

    # Trackpad. Appended rather than living in the base config, so a desktop
    # never carries input rules for hardware it does not have.
    my.niri.extra = ''

      // ===== role: laptop =====
      input {
          touchpad {
              tap
              natural-scroll
              dwt                    // disable-while-typing
              accel-profile "adaptive"
              scroll-method "two-finger"
          }
      }
    '';
  };
}
