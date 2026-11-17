top@{ ... }:
let
  options =
    lib: with lib; {
      enable = mkEnableOption "accepting nix builds over ssh-ng from one client";
      user = mkOption {
        type = types.str;
        default = "nixremote";
      };
      clientKey = mkOption {
        type = types.str;
        description = "The client's ssh public key line (type, key, comment).";
      };
      clientSigningKey = mkOption {
        type = types.str;
        description = "The client's nix signing public key. Its builds are accepted as inputs; the user stays untrusted.";
      };
      clientAddress = mkOption {
        type = types.str;
        description = "The one address the client connects from.";
      };
      daemon = mkOption {
        type = types.str;
        default = "/run/current-system/sw/bin/nix-daemon";
      };
      cpuWeight = mkOption {
        type = types.int;
        default = 20;
      };
      ioWeight = mkOption {
        type = types.int;
        default = 20;
      };
    };

  keyLine =
    cfg: ''restrict,from="${cfg.clientAddress}",command="${cfg.daemon} --stdio" ${cfg.clientKey}'';
in
{
  flake.modules.nixos.remote-builder-host =
    { config, lib, ... }:
    let
      cfg = config.my.remoteBuilderHost;
    in
    {
      options.my.remoteBuilderHost = options lib;

      config = lib.mkIf cfg.enable (lib.mkMerge [
        (top.config.flake.lib.tailnetAllow {
          inherit config;
          from = [ cfg.clientAddress ];
          port = 22;
        })
        {
        users.groups.${cfg.user} = { };
        users.users.${cfg.user} = {
          isSystemUser = true;
          group = cfg.user;
          shell = "/run/current-system/sw/bin/bash";
          openssh.authorizedKeys.keys = [ (keyLine cfg) ];
        };
        nix.settings.extra-trusted-public-keys = [ cfg.clientSigningKey ];
        systemd.services.nix-daemon.serviceConfig = {
          CPUWeight = cfg.cpuWeight;
          IOWeight = cfg.ioWeight;
        };
        }
      ]);
    };

  flake.modules.homeManager.remote-builder-host =
    hm@{ lib, pkgs, ... }:
    let
      cfg = hm.config.my.remoteBuilderHost;
    in
    {
      options.my.remoteBuilderHost = options lib;

      config = lib.mkIf cfg.enable {
        home.packages = [
          (pkgs.writeShellApplication {
            name = "remote-builder-host-setup";
            runtimeInputs = [ pkgs.coreutils pkgs.gnugrep ];
            text = ''
              if [ "$(id -u)" -ne 0 ]; then
                echo "run with sudo: it creates a system user and adds a trusted public key to /etc/nix/nix.conf" >&2
                exit 1
              fi
              user=${lib.escapeShellArg cfg.user}
              if ! getent passwd "$user" >/dev/null; then
                useradd --system --create-home --home-dir "/var/lib/$user" --shell /bin/bash "$user"
              fi
              home=$(getent passwd "$user" | cut -d: -f6)
              install -d -m 0700 -o "$user" -g "$user" "$home/.ssh"
              printf '%s\n' ${lib.escapeShellArg (keyLine cfg)} > "$home/.ssh/authorized_keys"
              chown "$user:$user" "$home/.ssh/authorized_keys"
              chmod 0600 "$home/.ssh/authorized_keys"
              signing=${lib.escapeShellArg cfg.clientSigningKey}
              if ! grep -Fq "$signing" /etc/nix/nix.conf; then
                printf 'extra-trusted-public-keys = %s\n' "$signing" >> /etc/nix/nix.conf
              fi
              install -d /etc/systemd/system/nix-daemon.service.d
              printf '[Service]\nCPUWeight=%s\nIOWeight=%s\n' ${toString cfg.cpuWeight} ${toString cfg.ioWeight} \
                > /etc/systemd/system/nix-daemon.service.d/remote-builder.conf
              systemctl daemon-reload
              systemctl restart nix-daemon
              echo "$user accepts nix-daemon --stdio from ${cfg.clientAddress} only"
            '';
          })
        ];
      };
    };
}
