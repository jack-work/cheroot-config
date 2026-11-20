{ inputs, ... }:
{
  flake.modules.homeManager.figaro-forms-bridge =
    hm@{ lib, pkgs, ... }:
    let
      cfg = hm.config.my.figaroFormsBridge;
      port = toString cfg.port;
    in
    {
      options.my.figaroFormsBridge = {
        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.figaro-forms.packages.${pkgs.stdenv.hostPlatform.system}.bridge;
          defaultText = lib.literalExpression "inputs.figaro-forms.packages.\${system}.bridge";
        };
        port = lib.mkOption {
          type = lib.types.port;
          default = 7481;
          description = "Loopback port, the same on both ends of the tunnel.";
        };
        tunnel = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "edge-host";
          description = "ssh destination that gets the bridge on its own 127.0.0.1:<port> by a reverse tunnel.";
        };
        peers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "127.0.0.1" ];
          description = "Addresses the edge reaches the bridge from: the tunnel's end on loopback.";
        };
        admin = lib.mkOption {
          type = lib.types.str;
          default = "admin";
          description = "The one Remote-User the edge may sign in.";
        };
        edgeSecretFile = lib.mkOption {
          type = lib.types.str;
          default = "%h/.config/figaro-forms-bridge/edge-token";
          description = "File holding the X-Figaro-Edge secret (32 bytes or more), loaded with LoadCredential; never in the store.";
        };
        driftCommand = lib.mkOption {
          type = lib.types.str;
          default = lib.getExe (pkgs.callPackage ../tools/figaro-apply { });
          defaultText = lib.literalExpression "figaro-apply from the charter";
          description = "What GET /drift runs with --check -j, as this user, outside any figaro.";
        };
      };

      config.systemd.user.services = {
        figaro-forms-bridge = {
          Unit = {
            Description = "figaro-forms hierarchy and drift for the order site, behind the edge";
            StartLimitIntervalSec = 0;
          };
          Service = {
            ExecStart = lib.escapeShellArgs (
              [
                (lib.getExe' cfg.package "figaro-forms-bridge")
                "--edge"
                "--port"
                port
                "--admin"
                cfg.admin
                "--drift-command"
                cfg.driftCommand
              ]
              ++ lib.concatMap (p: [
                "--peer"
                p
              ]) cfg.peers
            );
            LoadCredential = "edge:${cfg.edgeSecretFile}";
            Restart = "always";
            RestartSec = 5;
            UMask = "0077";
            NoNewPrivileges = true;
            PrivateTmp = true;
            LockPersonality = true;
            RestrictSUIDSGID = true;
            RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6";
            SystemCallArchitectures = "native";
          };
          Install.WantedBy = [ "default.target" ];
        };

        figaro-forms-bridge-tunnel = lib.mkIf (cfg.tunnel != null) {
          Unit = {
            Description = "Reverse tunnel: ${cfg.tunnel} 127.0.0.1:${port} -> the figaro-forms bridge";
            After = [ "figaro-forms-bridge.service" ];
            Requires = [ "figaro-forms-bridge.service" ];
            StartLimitIntervalSec = 0;
          };
          Service = {
            ExecStart = "${lib.getExe pkgs.openssh} -N -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -R 127.0.0.1:${port}:127.0.0.1:${port} ${cfg.tunnel}";
            Restart = "always";
            RestartSec = 10;
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
    };
}
