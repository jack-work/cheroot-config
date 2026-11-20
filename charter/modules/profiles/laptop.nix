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

    my.niri.extra = ''
      switch-events {
          lid-close { spawn "swaylock" "-f" "-c" "000000"; }
      }
    '';

    my.preflight.etc = {
      "systemd/logind.conf.d/10-laptop.conf" = ''
        [Login]
        HandleLidSwitch=suspend
        HandleLidSwitchExternalPower=ignore
        HandleLidSwitchDocked=ignore
        HandlePowerKey=suspend
        IdleAction=ignore
      '';

      "tlp.d/10-laptop.conf" = ''
        CPU_SCALING_GOVERNOR_ON_AC=powersave
        CPU_SCALING_GOVERNOR_ON_BAT=powersave
        CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
        CPU_ENERGY_PERF_POLICY_ON_BAT=power
        PLATFORM_PROFILE_ON_AC=balanced
        PLATFORM_PROFILE_ON_BAT=low-power
        WIFI_PWR_ON_AC=off
        WIFI_PWR_ON_BAT=off
        START_CHARGE_THRESH_BAT0=75
        STOP_CHARGE_THRESH_BAT0=85
        USB_AUTOSUSPEND=0
      '';

      "udev/rules.d/90-usb-wake.rules" = ''
        ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usb", ATTR{bDeviceClass}=="09", TEST=="power/wakeup", ATTR{power/wakeup}="enabled"
        ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usb", ATTR{bDeviceClass}=="e0", TEST=="power/wakeup", ATTR{power/wakeup}="enabled"
      '';
    };

    my.preflight.binaries = [
      "swaylock"
      "brightnessctl"
    ];

    my.preflight.pacman = [
      "tlp"
      "sof-firmware"
      "bluez"
      "bluez-utils"
    ];

    my.niri.inputExtra = ''
      touchpad {
          tap
          natural-scroll
          dwt
          accel-profile "adaptive"
          scroll-method "two-finger"
      }
    '';
  };
}
