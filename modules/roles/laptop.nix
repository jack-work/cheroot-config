# Role: laptop.
#
# This file OWNS everything that is true because the machine has a battery and
# a backlight. Nothing in the shared configuration mentions laptops; the role
# adds itself. That inversion is the point of the pattern.
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
  };
}
