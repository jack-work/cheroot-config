let
  buildCaptainsLog =
    {
      pkgs,
      src,
      vendorHash,
      version ? "charter",
    }:
    rec {
      skill = pkgs.runCommand "captains-log-skill" { } ''
        cp -r ${src}/skills/captains-log $out
      '';

      package = pkgs.buildGoModule {
        pname = "captains-log";
        inherit version src vendorHash;
        subPackages = [ "cmd/cl" ];
        passthru = { inherit skill; };
        meta.mainProgram = "cl";
      };
    };
in
{
  flake.modules.nixos.captains-log =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.captainsLog.service;
      resolvedPkg =
        if cfg.package != null then
          cfg.package
        else
          (buildCaptainsLog {
            inherit pkgs;
            inherit (cfg) src vendorHash;
          }).package;
      allow = pkgs.writeText "captains-log-allow.json" (
        builtins.toJSON {
          appenders = lib.mapAttrs (_: a: { inherit (a) name email ops; }) cfg.appenders;
          principal_sockets = cfg.principalSockets;
        }
      );
      aclScript = pkgs.writeShellScript "captains-log-acl" ''
        set -eu
        PATH=${
          lib.makeBinPath [
            pkgs.acl
            pkgs.findutils
            pkgs.coreutils
          ]
        }
        d=${lib.escapeShellArg cfg.instance}
        test -d "$d/.git" || { echo "captains-log-acl: $d is not a git instance"; exit 1; }
        setfacl -R -m u:captains-log:rwX "$d"
        find "$d" -type d -print0 | xargs -0 -r setfacl -d -m u:captains-log:rwX,u:${cfg.ownerUser}:rwX
      '';
    in
    {
      options.my.captainsLog.service = {
        enable = lib.mkEnableOption "append-only captains-log socket service";
        src = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
        };
        package = lib.mkOption {
          type = lib.types.nullOr lib.types.package;
          default = null;
        };
        vendorHash = lib.mkOption {
          type = lib.types.str;
          default = "sha256-CVycV7wxo7nOHm7qjZKfJrIkNcIApUNzN1mSIIwQN0g=";
        };
        instance = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        ownerUser = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        committerEmail = lib.mkOption {
          type = lib.types.str;
          default = "captains-log@localhost";
        };
        appenders = lib.mkOption {
          default = { };
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                options = {
                  name = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                  };
                  email = lib.mkOption {
                    type = lib.types.str;
                    default = "${name}@localhost";
                  };
                  ops = lib.mkOption {
                    type = lib.types.listOf (
                      lib.types.enum [
                        "append"
                        "reindex"
                      ]
                    );
                    default = [ "append" ];
                  };
                };
              }
            )
          );
        };
        principalSockets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.src != null || cfg.package != null;
            message = "my.captainsLog.service requires src or package from the consuming system flake";
          }
          {
            assertion = cfg.instance != null && cfg.ownerUser != null;
            message = "my.captainsLog.service requires instance and ownerUser";
          }
          {
            assertion = lib.all (p: cfg.appenders ? ${p}) cfg.principalSockets;
            message = "my.captainsLog.service: every principalSockets entry needs an appenders entry";
          }
        ];

        users.users.captains-log = {
          isSystemUser = true;
          group = "captains-log";
          home = "/var/lib/captains-log";
        };
        users.groups.captains-log = { };

        systemd.services.captains-log-acl = {
          description = "captains-log instance ACL setup";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = aclScript;
          };
        };

        systemd.services.captains-log-append = {
          description = "captains-log append-only socket service";
          wantedBy = [ "multi-user.target" ];
          requires = [ "captains-log-acl.service" ];
          after = [ "captains-log-acl.service" ];
          environment = {
            HOME = "/var/lib/captains-log";
            GIT_CONFIG_COUNT = "1";
            GIT_CONFIG_KEY_0 = "safe.directory";
            GIT_CONFIG_VALUE_0 = cfg.instance;
            GIT_COMMITTER_NAME = "captains-log";
            GIT_COMMITTER_EMAIL = cfg.committerEmail;
            GIT_AUTHOR_NAME = "captains-log";
            GIT_AUTHOR_EMAIL = cfg.committerEmail;
          };
          path = [
            pkgs.git
            pkgs.acl
          ];
          serviceConfig = {
            User = "captains-log";
            Group = "captains-log";
            ExecStart = "${resolvedPkg}/bin/cl -C ${cfg.instance} serve --runtime-dir /run/captains-log --allow ${allow} --forwarder ${cfg.ownerUser}";
            Restart = "on-failure";
            RestartSec = 5;
            RuntimeDirectory = "captains-log";
            RuntimeDirectoryMode = "0755";
            StateDirectory = "captains-log";
            StateDirectoryMode = "0700";
            UMask = "0022";
            ProtectHome = "tmpfs";
            BindPaths = [ cfg.instance ];
            ReadWritePaths = [ cfg.instance ];
            ProtectSystem = "strict";
            PrivateTmp = true;
            PrivateNetwork = true;
            RestrictAddressFamilies = [ "AF_UNIX" ];
            NoNewPrivileges = true;
            CapabilityBoundingSet = "";
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            LockPersonality = true;
            RestrictSUIDSGID = true;
            SystemCallArchitectures = "native";
          };
        };
      };
    };

  flake.modules.homeManager.captains-log =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.captainsLog;
      built = buildCaptainsLog {
        inherit pkgs;
        inherit (cfg) src vendorHash;
      };
      resolvedPkg = if cfg.package != null then cfg.package else built.package;
      resolvedSkill =
        if cfg.package != null && cfg.package ? skill then cfg.package.skill else built.skill;
      timerEnv = [
        "PATH=${
          lib.makeBinPath [
            pkgs.git
            pkgs.openssh
            pkgs.coreutils
          ]
        }"
        "CL_FIGARO=${config.home.profileDirectory}/bin/figaro"
      ];
    in
    {
      options.my.captainsLog = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        src = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
        };
        package = lib.mkOption {
          type = lib.types.nullOr lib.types.package;
          default = null;
        };
        vendorHash = lib.mkOption {
          type = lib.types.str;
          default = "sha256-CVycV7wxo7nOHm7qjZKfJrIkNcIApUNzN1mSIIwQN0g=";
        };
        skillPath = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = ".config/figaro/skills/captains-log";
        };
        timers = {
          enable = lib.mkEnableOption "captains-log snapshot, analyse, and health timers";
          instance = lib.mkOption {
            type = lib.types.str;
            default = "${config.home.homeDirectory}/.captains-log";
          };
          snapshotEvery = lib.mkOption {
            type = lib.types.str;
            default = "5min";
          };
          analyseAt = lib.mkOption {
            type = lib.types.str;
            default = "*-*-* 05:30:00 UTC";
          };
          healthAt = lib.mkOption {
            type = lib.types.str;
            default = "*-*-* 13:00:00 UTC";
          };
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            assertions = [
              {
                assertion = cfg.src != null || cfg.package != null;
                message = "my.captainsLog requires src or package from the consuming system flake";
              }
            ];

            home.packages = [
              resolvedPkg
              pkgs.gitleaks
            ];

            home.file = lib.mkIf (cfg.skillPath != null && (cfg.src != null || cfg.package ? skill)) {
              ${cfg.skillPath}.source = resolvedSkill;
            };
          }
          (lib.mkIf cfg.timers.enable {
            systemd.user.services.captains-log-snapshot = {
              Unit.Description = "captains-log snapshot ${cfg.timers.instance}";
              Service = {
                Type = "oneshot";
                ExecStart = "${resolvedPkg}/bin/cl -C ${cfg.timers.instance} snapshot";
                Environment = timerEnv;
                Nice = 10;
                TimeoutStartSec = "10min";
              };
            };
            systemd.user.timers.captains-log-snapshot = {
              Unit.Description = "captains-log snapshot every ${cfg.timers.snapshotEvery}";
              Timer = {
                OnBootSec = "5min";
                OnUnitActiveSec = cfg.timers.snapshotEvery;
              };
              Install.WantedBy = [ "timers.target" ];
            };
            systemd.user.services.captains-log-analyse = {
              Unit.Description = "captains-log daily analyser";
              Service = {
                Type = "oneshot";
                ExecStartPre = "${resolvedPkg}/bin/cl -C ${cfg.timers.instance} snapshot";
                ExecStart = "${resolvedPkg}/bin/cl -C ${cfg.timers.instance} analyse --since 26h --sequential";
                Environment = timerEnv;
                TimeoutStartSec = "8h";
              };
            };
            systemd.user.timers.captains-log-analyse = {
              Unit.Description = "captains-log daily analyser";
              Timer = {
                OnCalendar = cfg.timers.analyseAt;
                Persistent = true;
              };
              Install.WantedBy = [ "timers.target" ];
            };
            systemd.user.services.captains-log-health = {
              Unit.Description = "captains-log daily health check";
              Service = {
                Type = "oneshot";
                ExecStart = "${resolvedPkg}/bin/cl -C ${cfg.timers.instance} health --nudge";
                Environment = timerEnv;
                Nice = 10;
                TimeoutStartSec = "10min";
              };
            };
            systemd.user.timers.captains-log-health = {
              Unit.Description = "captains-log daily health";
              Timer = {
                OnCalendar = cfg.timers.healthAt;
                Persistent = true;
              };
              Install.WantedBy = [ "timers.target" ];
            };
          })
        ]
      );
    };
}
