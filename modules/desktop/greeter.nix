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

      "pam.d/greetd" = ''
        #%PAM-1.0
        auth       include      system-local-login
        -auth      optional     pam_gnome_keyring.so
        -auth      optional     pam_kwallet5.so
        account    include      system-local-login
        password   include      system-local-login
        -password  optional     pam_gnome_keyring.so use_authtok
        session    include      system-local-login
        -session   optional     pam_gnome_keyring.so auto_start
        -session   optional     pam_kwallet5.so auto_start
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
