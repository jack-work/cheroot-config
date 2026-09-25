# Role: laptop.
#
# This file OWNS everything that is true because the machine has a battery, a
# backlight and a trackpad. Nothing in the shared configuration mentions
# laptops; the role adds itself. That inversion is the point of the pattern.
{
  flake.modules.homeManager.laptop = {
    my.waybar.modulesRight = [
      "custom/weather"
      "custom/wifi"
      "custom/storage"
      "memory"
      "cpu"
      "backlight"
      "wireplumber"
      "battery"
    ];

    # A laptop locks when it is left alone; a desktop does not, and gluck has
    # no swayidle installed to do it with. The spawn lives with the reason.
    my.niri.extra = ''
      // ===== role: laptop =====
      spawn-at-startup "swayidle" "-w" "timeout" "300" "swaylock -f -c 000000" "before-sleep" "swaylock -f -c 000000"
    '';

    my.preflight.binaries = [
      "swayidle"
      "swaylock"
      "brightnessctl"
    ];

    # Packages with no binary of their own, or that own a system unit. Arch's
    # sof-firmware is the one that bit: without it the Comet Lake DSP fails to
    # probe, every sink is auto_null, and the machine looks like it has no
    # audio hardware at all.
    my.preflight.pacman = [
      "sof-firmware"
      "bluez"
      "bluez-utils"
    ];

    # Trackpad. Appended rather than living in the base config, so a desktop
    # never carries input rules for hardware it does not have.
    my.niri.inputExtra = ''
      // ===== role: laptop =====
      touchpad {
          tap
          natural-scroll
          dwt                    // disable-while-typing
          accel-profile "adaptive"
          scroll-method "two-finger"
      }
    '';
  };
}
