{
  flake.modules.homeManager.greeter = {
    my.preflight.pacman = [
      "greetd"
      "greetd-tuigreet"
    ];

    my.preflight.etc = {
      "greetd/config.toml" = ''
        [terminal]
        vt = 1

        [default_session]
        command = "tuigreet --time --remember --remember-session --cmd niri-session"
        user = "greeter"
      '';

      "systemd/system/greetd.service.d/tty.conf" = ''
        [Service]
        Type=idle
        StandardInput=tty
        StandardOutput=tty
        StandardError=journal
        TTYReset=yes
        TTYVHangup=yes
        TTYVTDisallocate=yes
      '';

      "systemd/system.conf.d/10-status.conf" = ''
        [Manager]
        ShowStatus=error
      '';

      "sysctl.d/20-console-loglevel.conf" = ''
        kernel.printk = 3 3 3 3
      '';
    };
  };
}
