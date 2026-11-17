{ inputs, config, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    let
      inherit (pkgs) lib;
      lockGate = config.flake.lib.lockGate;
      rosterLib = config.flake.lib.roster;
      realLock = builtins.fromJSON (builtins.readFile ../flake.lock);

      fakeSshLock = {
        root = "root";
        nodes = {
          root = { };
          nixpkgs.locked = {
            type = "github";
            owner = "NixOS";
            repo = "nixpkgs";
          };
          keel = {
            locked = {
              type = "git";
              url = "ssh://git@example.invalid/keel.git";
            };
            original = {
              type = "git";
              url = "git+ssh://git@example.invalid/keel.git";
            };
          };
        };
      };

      fakePathLock = {
        root = "root";
        nodes = {
          root = { };
          nixpkgs.locked = {
            type = "github";
            owner = "NixOS";
            repo = "nixpkgs";
          };
          local = {
            locked = {
              type = "path";
              path = "/tmp/local-input";
            };
          };
        };
      };

      fakeDualNixpkgsLock = {
        root = "root";
        nodes = {
          root = { };
          nixpkgs.locked = {
            type = "github";
            owner = "NixOS";
            repo = "nixpkgs";
          };
          nixpkgs_2.locked = {
            type = "github";
            owner = "NixOS";
            repo = "nixpkgs";
          };
        };
      };

      fakeKeelSrc = pkgs.writeTextDir "kc.sh" ''
        echo "kc stub"
      '';

      fakeCaptainsLogSrc = pkgs.runCommand "fake-captains-log-src" { } ''
        mkdir -p $out/skills/captains-log $out/cmd/cl
        echo "# skill" > $out/skills/captains-log/SKILL.md
      '';

      fakeClPkg = (pkgs.writeShellScriptBin "cl" "exit 0") // {
        skill = pkgs.writeTextDir "SKILL.md" "# skill";
      };

      sampleNixos =
        (inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            config.flake.modules.nixos.base
            config.flake.modules.nixos.shell
            config.flake.modules.nixos.tmux
            config.flake.modules.nixos.editor
            config.flake.modules.nixos.git
            config.flake.modules.nixos.go
            config.flake.modules.nixos.heavy
            config.flake.modules.nixos.figaro
            config.flake.modules.nixos.hush
            config.flake.modules.nixos.keel
            config.flake.modules.nixos.captains-log
            {
              boot.loader.grub.enable = false;
              fileSystems."/" = {
                device = "none";
                fsType = "tmpfs";
              };
              system.stateVersion = "26.11";
              my.heavy.enable = true;
              my.figaro = {
                mode = "system";
                credo = "Sample shared credo.";
                outfits.builder.system = {
                  provider = "gateway";
                  model = "sample-model";
                };
                roster.sample-steward = {
                  kind = "steward";
                  leader = "none";
                  purpose = "Maintain shared charter modules";
                };
                managedRolesHook.enable = true;
              };
              my.hush = {
                agent.enable = true;
                cred = {
                  enable = true;
                  recipient = "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p";
                  identityFile = "/var/lib/hush-cred/identity.agekey";
                  instances.sample = {
                    kind = "chatgpt";
                  };
                };
              };
              my.keel = {
                enable = true;
                src = fakeKeelSrc;
                baseUrl = "https://keel.example.invalid";
                oidcIssuer = "https://auth.example.invalid";
              };
              my.captainsLog.service = {
                enable = true;
                package = fakeClPkg;
                instance = "/var/lib/sample-log";
                ownerUser = "operator";
                appenders.sbx = {
                  ops = [ "append" ];
                };
              };
            }
          ];
        }).config;

      missingSrcNixos =
        (inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            config.flake.modules.nixos.keel
            config.flake.modules.nixos.captains-log
            {
              my.keel.enable = true;
              my.captainsLog.service.enable = true;
            }
          ];
        }).config;

      missingSrcFailed = map (a: a.message) (
        builtins.filter (a: !a.assertion) missingSrcNixos.assertions
      );

      containerNixos =
        (inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            config.flake.modules.nixos.figaro
            {
              my.figaro = {
                mode = "container";
                outfits.shell.system.tools = [ "bash" ];
              };
            }
          ];
        }).config;

      sampleHm =
        (inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = map (n: config.flake.modules.homeManager.${n}) config.flake.lib.coreAspects ++ [
            config.flake.modules.homeManager.heavy
            config.flake.modules.homeManager.keel
            config.flake.modules.homeManager.captains-log
            config.flake.modules.homeManager.figaro-forms-bridge
            config.flake.modules.homeManager.remote-builder-host
            {
              my.remoteBuilderHost = {
                enable = true;
                clientKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIH5ozXOcnYVTNKRnp6bO7ywYhsuimKYDOg+3yOND2qC sample";
                clientAddress = "192.0.2.20";
                clientSigningKey = "sample-1:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
              };
              my.figaroFormsBridge.host = "192.0.2.10";
              my.figaroFormsBridge.hushExecutable = "/opt/hush/bin/hush";
              home.username = "operator";
              home.homeDirectory = "/home/operator";
              my.keel = {
                src = fakeKeelSrc;
                baseUrl = "https://keel.example.invalid";
                oidcIssuer = "https://auth.example.invalid";
              };
              my.captainsLog = {
                src = fakeCaptainsLogSrc;
                package = fakeClPkg;
                timers.enable = true;
              };
              my.figaro = {
                credo = "User credo.";
                outfits.fast.system.ttl = "1h";
                roster.lead = {
                  kind = "leader";
                  purpose = "Hold the order";
                  form = "@0123456789abcdef0123456789abcdef";
                };
                roster.builder = {
                  kind = "builder";
                  leader = "lead";
                  purpose = "Run isolated tasks";
                  forward = [ "mason" ];
                  forwardUntil = "2026-12-01";
                };
                managedRolesHook.enable = true;
              };
            }
          ];
        }).config;
      bridgeSpec = sampleHm.my.figaroFormsBridge.commandSpec;
    in
    {
      checks = {
        lock-github-only =
          assert lockGate.assertGithubOnlyLock realLock;
          assert !(builtins.tryEval (lockGate.assertGithubOnlyLock fakeSshLock)).success;
          assert !(builtins.tryEval (lockGate.assertGithubOnlyLock fakePathLock)).success;
          assert !(builtins.tryEval (lockGate.assertGithubOnlyLock fakeDualNixpkgsLock)).success;
          assert builtins.all (r: !(builtins.tryEval (rosterLib.validateRoster r)).success) [
            {
              bad = {
                kind = "unknown";
                purpose = "";
              };
            }
            {
              orphan = {
                kind = "builder";
                leader = "missing";
                purpose = "p";
              };
            }
            {
              self = {
                kind = "builder";
                leader = "self";
                purpose = "p";
              };
            }
            {
              a = {
                kind = "leader";
                leader = "b";
                purpose = "p";
              };
              b = {
                kind = "leader";
                leader = "a";
                purpose = "p";
              };
            }
            {
              renamed = {
                kind = "steward";
                purpose = "p";
                forward = [ "old" ];
              };
            }
            {
              a = {
                kind = "steward";
                purpose = "p";
              };
              b = {
                kind = "steward";
                purpose = "p";
                forward = [ "a" ];
                forwardUntil = "2026-12-01";
              };
            }
          ];
          assert
            (rosterLib.validateRoster {
              top = {
                kind = "leader";
                purpose = "p";
              };
              mid = {
                kind = "steward";
                leader = "top";
                purpose = "p";
              };
            }) ? mid;
          pkgs.runCommand "charter-lock-github-only" { } ''
            echo "verified github-only charter lock (${toString (builtins.length (builtins.attrNames realLock.nodes))} nodes, 1 nixpkgs)" > $out
          '';

        charter-zero-host-leaks =
          let
            forbiddenRegex = builtins.concatStringsSep "|" [
              "\\bgluk\\b"
              "\\bspain\\b"
              "\\bcheroot\\b"
              "\\bmerlin\\b"
              "\\bmarlowe\\b"
              "\\bgioco\\b"
              "\\bbach\\b"
              "\\bleob\\b"
              "\\bsego\\b"
              "\\bpucc\\b"
              "\\bross\\b"
              "\\bverd\\b"
              "\\bbarr\\b"
              "kelliher\\.info"
              "tail34d120"
              "100\\.103\\."
              "100\\.74\\."
              "100\\.92\\."
              "sopsFile"
              "git\\+ssh://"
            ];
          in
          pkgs.runCommand "charter-zero-host-leaks"
            {
              nativeBuildInputs = [
                pkgs.ripgrep
                pkgs.findutils
              ];
              inherit forbiddenRegex;
            }
            ''
              if rg -n "$forbiddenRegex" ${../.} --glob '*.nix' --glob '!**/checks.nix'; then
                echo "charter contains host, IP, domain, sops, or git+ssh references" >&2
                exit 1
              fi
              echo "zero host/IP/port/sops leaks in charter nix modules" > $out
            '';

        charter-eval-aspects =
          assert sampleNixos.services.figaro.enable;
          assert sampleNixos.services.figaro.outfits.builder.system.credo == "Sample shared credo.";
          assert sampleNixos.systemd.services ? figaro-roster-reconcile;
          assert sampleNixos.services.hush-cred.enable;
          assert sampleNixos.services.hush-agent.enable;
          assert sampleNixos.systemd.services ? captains-log-append;
          assert sampleNixos.systemd.slices ? heavy;
          assert builtins.any (lib.hasInfix "my.keel.src") missingSrcFailed;
          assert builtins.any (lib.hasInfix "my.captainsLog.service") missingSrcFailed;
          assert sampleHm.systemd.user.slices ? heavy;
          assert sampleHm.systemd.user.timers ? captains-log-snapshot;
          assert sampleHm.xdg.configFile ? "figaro/outfits/fast.toml";
          assert sampleHm.xdg.configFile ? "figaro/roster";
          assert sampleHm.systemd.user.services ? figaro-forms-bridge;
          assert builtins.any (p: lib.getName p == "remote-builder-host-setup") sampleHm.home.packages;
          assert
            bridgeSpec.args == [
              "--hierarchy-only"
              "--host"
              "192.0.2.10"
              "--port"
              "7481"
            ];
          assert bridgeSpec.secrets == { token = "FIGARO_FORMS_BRIDGE_TOKEN"; };
          assert containerNixos.services.figaro-container.enable;
          assert lib.getName containerNixos.services.figaro-container.package == "figaro";
          assert containerNixos.containers.figaro.config.services.figaro.outfits ? shell;
          pkgs.runCommand "charter-eval-aspects"
            {
              nixosDrv = builtins.unsafeDiscardStringContext sampleNixos.system.build.toplevel.drvPath;
              hmDrv = builtins.unsafeDiscardStringContext sampleHm.home.activationPackage.drvPath;
            }
            ''
              printf 'nixos=%s\nhm=%s\n' "$nixosDrv" "$hmDrv" > $out
            '';
      };
    };
}
