{ inputs, ... }:
{
  flake.modules.homeManager.gluck-backup =
    { config, pkgs, ... }:
    let
      home = config.home.homeDirectory;
      hush = inputs.hush.packages.${pkgs.stdenv.hostPlatform.system}.hush;
      restic = "${hush}/bin/hush restic-gluck";
      role = "@4f6f262b";

      excludes = pkgs.writeText "gluck-backup-excludes" ''
        ${home}/.cache
        ${home}/go/pkg
        ${home}/.nix-*
        ${home}/.ssh/fleet_ed25519
        ${home}/.local/share/containers
        ${home}/.local/share/pipx
        ${home}/.local/share/uv
        ${home}/.local/share/Trash
        ${home}/.npm
        ${home}/.bun
        ${home}/.conda
        ${home}/.terraform.d
        ${home}/.rustup
        ${home}/.cargo/registry
        ${home}/.cargo/git
        ${home}/.nuget
        ${home}/.dotnet
        ${home}/.local/state/figaro/bundled-skills
        ${home}/.config/obs-studio/logs
        ${home}/.config/net.imput.helium/*/Cache
        ${home}/.config/net.imput.helium/*/Code Cache
        ${home}/.config/net.imput.helium/*/GPUCache
        ${home}/.config/net.imput.helium/*/Service Worker/CacheStorage
        ${home}/dev/figaro-tapes/**/*.mkv
        node_modules
        .venv
        __pycache__
        .terraform
      '';

      unit = description: execs: {
        Unit = {
          Description = description;
          Wants = [ "fleet-ssh-agent.service" ];
          After = [
            "fleet-ssh-agent.service"
            "network-online.target"
          ];
          OnFailure = [ "gluck-backup-failed@%n.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = execs;
          Environment = [
            "SSH_AUTH_SOCK=%t/fleet-ssh-agent.sock"
            "PATH=${pkgs.openssh}/bin:/usr/bin"
          ];
          Nice = 19;
          IOSchedulingClass = "idle";
          CPUSchedulingPolicy = "idle";
        };
      };

      timer = description: calendar: {
        Unit.Description = description;
        Timer = {
          OnCalendar = calendar;
          RandomizedDelaySec = "1h";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    in
    {
      xdg.configFile."hush/commands/restic-gluck/command.toml".source =
        (pkgs.formats.toml { }).generate "restic-gluck-command.toml"
          {
            description = "restic against gluck's backup repo on spain";
            exec = "${pkgs.restic}/bin/restic";
            env = {
              RESTIC_REPOSITORY = "sftp:gluck-backup@spain:/repo";
              RESTIC_CACHE_DIR = "${home}/.cache/restic";
            };
            secrets.password = "RESTIC_PASSWORD";
          };

      systemd.user.services.gluck-backup = unit "restic backup of ${home} to spain" [
        "${restic} backup --host gluck --tag home --retry-lock 30m --exclude-caches --exclude-larger-than 2G --exclude-file ${excludes} ${home}"
      ];
      systemd.user.timers.gluck-backup = timer "gluck-backup, nightly" "*-*-* 02:30";

      systemd.user.services.gluck-backup-prune = unit "prune and check gluck's restic repo on spain" [
        "${restic} forget --host gluck --tag home --retry-lock 30m --keep-daily 7 --keep-weekly 4 --keep-monthly 3 --prune"
        "${restic} check --retry-lock 30m"
      ];
      systemd.user.timers.gluck-backup-prune = timer "gluck-backup-prune, weekly" "Sun 04:00";

      systemd.user.services."gluck-backup-failed@" = {
        Unit.Description = "tell the Backend role that %i failed";
        Service = {
          Type = "oneshot";
          ExecStart = "${home}/.nix-profile/bin/figaro send ${role} -f -- \"%i failed on gluck; journalctl --user -u %i\"";
        };
      };
    };
}
