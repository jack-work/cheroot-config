{ inputs, ... }:
{
  flake.modules.homeManager.commander =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.commander;
      instance = "figaro-${cfg.instance}";
      configDir = "${config.xdg.configHome}/${instance}";
      stateDir = "${config.xdg.stateHome}/${instance}";
      cacheDir = "${config.xdg.cacheHome}/${instance}";
      toml = pkgs.formats.toml { };
      environment = {
        FIGARO_CONFIG_DIR = configDir;
        FIGARO_STATE_DIR = stateDir;
        FIGARO_CACHE_DIR = cacheDir;
        FIGARO_NO_SELF_SPAWN = "1";
      };
      environmentExports = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (key: value: "export ${key}=${lib.escapeShellArg value}") environment
      );
      check = pkgs.writeShellApplication {
        name = "figaro-root-check";
        runtimeInputs = [
          cfg.package
          pkgs.jq
        ];
        text = ''
          ${environmentExports}
          export FIGARO_RUNTIME_DIR="''${XDG_RUNTIME_DIR:?}/${instance}"
          ${builtins.readFile ../scripts/figaro-root-check.sh}
        '';
      };
    in
    {
      options.my.commander = {
        instance = lib.mkOption {
          type = lib.types.strMatching "[a-z][a-z0-9-]*";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.figaro.packages.${pkgs.stdenv.hostPlatform.system}.figaro;
        };
        provider = lib.mkOption {
          type = lib.types.str;
          default = "rou2";
        };
        model = lib.mkOption {
          type = lib.types.str;
          default = "chatgpt-personal/gpt-6.1-sol";
        };
        credo = lib.mkOption {
          type = lib.types.lines;
          default = ''
            You are this workstation's independent root commander. Start with this root only.
            Never read keys, tokens or credential files. Use only the explicitly provisioned
            subscription route, with no paid fallback. Treat partitioning, boot changes and
            store cutover as operator actions.
          '';
        };
        skills = lib.mkOption {
          type = lib.types.attrsOf lib.types.path;
          default = { };
        };
        bootstrapDoc = lib.mkOption {
          type = lib.types.str;
          default = "the host bootstrap run sheet";
        };
      };

      imports = [ inputs.figaro.homeManagerModules.default ];

      config = {
        programs.figaro = {
          enable = true;
          package = cfg.package;
          restartOnSwitch = false;
        };
        systemd.user.startServices = "suggest";
        home.packages = [ check ];
        home.sessionVariables = environment // {
          FIGARO_RUNTIME_DIR = "\${XDG_RUNTIME_DIR}/${instance}";
          FIGARO_SYSTEMD_UNIT = "figaro-commander.service";
        };

        xdg.configFile = {
          "${instance}/config.toml".source = toml.generate "${instance}-config.toml" {
            default_outfit = "root";
          };
          "${instance}/outfits/root-role.toml".source = toml.generate "${instance}-root-role.toml" {
            name = "${cfg.instance} root";
            purpose = "Independent workstation setup and daily driving";
          };
          "${instance}/outfits/root.toml".source = toml.generate "${instance}-root.toml" {
            mantra = "${cfg.instance} desktop setup and daily use";
            skills = {
              dirName = "skills";
            };
            system = {
              provider = cfg.provider;
              model = cfg.model;
              cwd = config.home.homeDirectory;
              ttl = 0;
              methods.enabled = false;
              credo = cfg.credo;
            };
          };
        }
        // lib.mapAttrs' (
          name: path: lib.nameValuePair "${instance}/skills/${name}.md" { source = path; }
        ) cfg.skills;

        systemd.user.services.figaro-commander = {
          Unit = {
            Description = "Independent ${cfg.instance} Figaro commander daemon";
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
          };
          Service = {
            Type = "exec";
            ExecStartPre = "${pkgs.coreutils}/bin/install -d -m 0700 ${
              lib.escapeShellArgs [
                stateDir
                cacheDir
              ]
            }";
            ExecStart = "${lib.getExe cfg.package} --angelus";
            Environment = lib.mapAttrsToList (key: value: "${key}=${value}") (
              environment
              // {
                HOME = config.home.homeDirectory;
                FIGARO_RUNTIME_DIR = "%t/${instance}";
                FIGARO_SYSTEMD_UNIT = "figaro-commander.service";
                PATH = "${
                  lib.makeBinPath [
                    pkgs.bash
                    pkgs.coreutils
                    pkgs.findutils
                    pkgs.gnugrep
                    pkgs.gnused
                    pkgs.git
                    pkgs.jq
                  ]
                }:${config.home.profileDirectory}/bin:/run/current-system/sw/bin";
              }
            );
            UnsetEnvironment = [ "FIGARO_ARIA" ];
            RuntimeDirectory = instance;
            RuntimeDirectoryMode = "0700";
            RuntimeDirectoryPreserve = true;
            UMask = "0077";
            Restart = "on-failure";
            RestartSec = 5;
            KillMode = "mixed";
            TimeoutStopSec = 30;
          };
          Install.WantedBy = [ "default.target" ];
        };

        home.activation.verifyCommanderRoot = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if [ -f ${lib.escapeShellArg "${stateDir}/root-identity.json"} ]; then
            if ${pkgs.systemd}/bin/systemctl --user is-active --quiet figaro-commander.service; then
              ${lib.getExe check}
            else
              echo "Root verification deferred: start figaro-commander.service, then run figaro-root-check."
            fi
          else
            echo "Root creation is manual and one-time; follow ${cfg.bootstrapDoc}."
          fi
        '';
      };
    };
}
