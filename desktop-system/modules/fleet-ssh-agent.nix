{
  flake.modules.homeManager.fleet-ssh-agent =
    hm@{ lib, pkgs, ... }:
    let
      cfg = hm.config.my.fleetSsh;
    in
    {
      options.my.fleetSsh = {
        key = lib.mkOption {
          type = lib.types.str;
          default = "%h/.ssh/fleet_ed25519";
          description = "The fleet's private key, a file only this user reads. Never in the store, never in a backup.";
        };
        socket = lib.mkOption {
          type = lib.types.str;
          default = "%t/fleet-ssh-agent.sock";
          readOnly = true;
          description = "The agent socket the fleet's units use as SSH_AUTH_SOCK, so none of them depend on the desktop keyring.";
        };
      };

      config = {
        systemd.user.services.fleet-ssh-agent = {
          Unit = {
            Description = "ssh agent for the fleet: holds only ${cfg.key}, independent of the desktop keyring";
            ConditionPathExists = cfg.key;
          };
          Service = {
            Type = "forking";
            Environment = "SSH_AUTH_SOCK=${cfg.socket}";
            ExecStart = "${pkgs.openssh}/bin/ssh-agent -a ${cfg.socket}";
            ExecStartPost = "${pkgs.openssh}/bin/ssh-add ${cfg.key}";
            Restart = "on-failure";
            RestartSec = 5;
            UMask = "0077";
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = "read-only";
            ReadWritePaths = "%t";
            LockPersonality = true;
            RestrictSUIDSGID = true;
            RestrictAddressFamilies = "AF_UNIX";
            SystemCallArchitectures = "native";
          };
          Install.WantedBy = [ "default.target" ];
        };

        xdg.configFile."systemd/user/figaro-approvals-tunnel.service.d/fleet-ssh.conf".text = ''
          [Unit]
          Wants=fleet-ssh-agent.service
          After=fleet-ssh-agent.service

          [Service]
          Environment=SSH_AUTH_SOCK=${cfg.socket}
        '';
      };
    };
}
