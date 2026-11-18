{ inputs, config, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    let
      inherit (pkgs) lib;
      lockGate = config.flake.lib.lockGate;
      rosterLib = config.flake.lib.roster;
      regimentLib = config.flake.lib.regiment;

      kindDefaults = {
        provider = null;
        model = null;
        maxChildren = null;
        quota = null;
        scopes = null;
        childPolicy = null;
      };
      mkSeat = kind: form: {
        inherit kind form;
        title = "Seat ${kind}";
        purpose = "p";
        charter = "c";
        handoff = null;
        mantra = null;
      };
      mkRegiment = leader: seats: {
        inherit leader seats;
        mode = "check";
        kinds = lib.genAttrs regimentLib.kinds (_: kindDefaults);
        reviewer = {
          ttl = "1h";
          retireTtl = "10m";
        };
        orchestration = "o";
        agreement = [ "{strategist} {knight} {steward}" ];
        successionLayers = [ ];
        successorBase = [ "default" ];
      };
      fullSeats = {
        s = mkSeat "strategist" "@01234567";
        k = mkSeat "knight" "@11234567";
        w = mkSeat "steward" null;
      };
      regimentFails =
        roster: regiments: !(builtins.tryEval (regimentLib.render roster regiments).roster).success;
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

      fakeKcPkg = pkgs.writeShellScriptBin "kc" ''
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
            config.flake.modules.nixos.figaro-forms-bridge
            config.flake.modules.nixos.remote-builder-host
            {
              my.figaroFormsBridge.allowFrom = [ "192.0.2.20" ];
              my.remoteBuilderHost = {
                enable = true;
                clientKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIH5ozXOcnYVTNKRnp6bO7ywYhsuimKYDOg+3yOND2qC sample";
                clientAddress = "192.0.2.20";
                clientSigningKey = "sample-1:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
              };
            }
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
                package = fakeKcPkg;
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
                package = fakeKcPkg;
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
                  charter = "Holds the order.";
                  maxChildren = 3;
                };
                roster.clerk = {
                  kind = "secretary";
                  leader = "lead";
                  purpose = "Keep the ledger";
                  form = "@89abcdef";
                  maxChildren = 0;
                };
                roster.builder = {
                  kind = "builder";
                  leader = "lead";
                  purpose = "Run isolated tasks";
                  forward = [ "mason" ];
                  forwardUntil = "2026-12-01";
                };
                regiments.sample = {
                  leader = "lead";
                  seats = {
                    thinker = {
                      kind = "strategist";
                      title = "Sample Strategist";
                      purpose = "Plan";
                      form = "@fedcba9876543210fedcba9876543210";
                      charter = "Plans.";
                      handoff = "/tmp/thinker.md";
                    };
                    vanguard = {
                      kind = "knight";
                      title = "Sample Knight";
                      purpose = "Ship";
                      form = "@76543210";
                      charter = "Ships.";
                    };
                    pool = {
                      kind = "steward";
                      title = "Sample Steward";
                      purpose = "Keep reviewers";
                      charter = "Keeps reviewers.";
                    };
                  };
                  kinds.strategist.model = "big";
                  kinds.knight.quota = 5;
                  kinds.knight.maxChildren = null;
                  kinds.reviewer = {
                    provider = "cheap";
                    model = "small";
                  };
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
              bad = {
                kind = "steward";
                purpose = "p";
                maxChildren = -1;
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
            })
              ? mid;
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

        charter-roster-fanout =
          let
            files = sampleHm.xdg.configFile;
            apply = lib.findFirst (p: lib.getName p == "figaro-apply-roles") null sampleHm.home.packages;
          in
          pkgs.runCommand "charter-roster-fanout"
            {
              nativeBuildInputs = [
                pkgs.python3
                pkgs.gnugrep
              ];
            }
            ''
              python3 - <<'PY'
              import re, tomllib
              def load(p):
                  return tomllib.load(open(p, "rb"))
              roster = "${files."figaro/roster".source}"
              assert load(f"{roster}/lead.toml")["max_children"] == 3
              assert load(f"{roster}/clerk.toml")["max_children"] == 0
              assert "max_children" not in load(f"{roster}/builder.toml")
              assert load("${
                files."figaro/outfits/role-lead-fanout.toml".source
              }") == {"system": {"fanout": {"max_children": 3}}}
              assert load("${
                files."figaro/outfits/role-clerk-fanout.toml".source
              }") == {"system": {"fanout": {"max_children": 0}}}
              script = open("${lib.getExe apply}").read()
              manifest = load(re.search(r"--manifest (\S+)", script).group(1))["roles"]
              assert manifest["lead"]["outfits"] == ["role-lead-charter", "role-lead-fanout"], manifest
              assert manifest["lead"]["managed"] == ["charter", "system.fanout.max_children"], manifest
              assert manifest["clerk"] == {"id": "@89abcdef", "outfits": ["role-clerk-fanout"], "managed": ["system.fanout.max_children"], "mode": "check"}, manifest
              assert "builder" not in manifest, manifest
              PY
              touch $out
            '';

        charter-regiment =
          let
            files = sampleHm.xdg.configFile;
            apply = lib.findFirst (p: lib.getName p == "figaro-apply-roles") null sampleHm.home.packages;
            outfit = n: files."figaro/outfits/${n}.toml".source;
          in
          assert regimentFails { lead = { }; } {
            r = mkRegiment "lead" (fullSeats // { s2 = mkSeat "strategist" null; });
          };
          assert regimentFails { lead = { }; } { r = mkRegiment "lead" (removeAttrs fullSeats [ "k" ]); };
          assert regimentFails { } { r = mkRegiment "missing" fullSeats; };
          assert regimentFails { lead = { }; } { r = mkRegiment "s" fullSeats; };
          assert regimentFails { s = { }; } { r = mkRegiment "none" fullSeats; };
          assert regimentFails { lead = { }; } {
            r = mkRegiment "lead" (fullSeats // { k = mkSeat "knight" "@xyz"; });
          };
          assert regimentFails { lead = { }; } {
            r = mkRegiment "lead" fullSeats;
            r2 = mkRegiment "lead" fullSeats;
          };
          assert !(regimentFails { lead = { }; } { r = mkRegiment "lead" fullSeats; });
          assert
            !(regimentFails { } {
              a = mkRegiment "none" fullSeats;
              b = mkRegiment "s" {
                s9 = mkSeat "strategist" null;
                k9 = mkSeat "knight" null;
                w9 = mkSeat "steward" null;
              };
            });
          assert
            !(builtins.tryEval (
              rosterLib.validateRoster {
                x = {
                  kind = "steward";
                  purpose = "p";
                  fields.charter = "c";
                };
              }
            )).success;
          assert builtins.any (lib.hasInfix "regiment sample: knight.quota") sampleHm.warnings;
          pkgs.runCommand "charter-regiment" { nativeBuildInputs = [ pkgs.python3 ]; } ''
            python3 - <<'PY'
            import re, tomllib
            def load(p):
                return tomllib.load(open(p, "rb"))
            roster = "${files."figaro/roster".source}"
            thinker = load(f"{roster}/thinker.toml")
            assert (thinker["kind"], thinker["leader"], thinker["leader_form"]) == ("leader", "lead", "@0123456789abcdef0123456789abcdef"), thinker
            assert thinker["max_children"] == 6 and thinker["model"] == "big", thinker
            assert load(f"{roster}/vanguard.toml")["kind"] == "builder"
            pool = load(f"{roster}/pool.toml")
            assert pool["kind"] == "steward" and "form" not in pool and "max_children" not in pool, pool
            script = open("${lib.getExe apply}").read()
            manifest = load(re.search(r"--manifest (\S+)", script).group(1))["roles"]
            assert manifest["thinker"] == {
                "id": "@fedcba9876543210fedcba9876543210",
                "outfits": ["role-thinker-charter", "role-thinker-fanout", "role-thinker-fields"],
                "managed": ["charter", "system.fanout.max_children", "name", "orchestration", "regiment", "role-name"],
                "mode": "check",
            }, manifest["thinker"]
            assert manifest["vanguard"]["outfits"][-1] == "role-vanguard-fields"
            assert "pool" not in manifest, manifest
            fields = load("${outfit "role-thinker-fields"}")
            assert fields["name"] == fields["role-name"] == "Sample Strategist", fields
            assert fields["regiment"]["name"] == "sample" and fields["regiment"]["seat"] == "strategist", fields
            agreement = fields["regiment"]["agreement"]
            assert "Sample Knight" in agreement and "regiment-sample-reviewer" in agreement and "{" not in agreement, agreement
            assert fields["orchestration"]["policy"].startswith("Classify every dispatched child"), fields
            assert load("${outfit "regiment-sample-strategist"}") == {"system": {"model": "big"}}
            assert load("${outfit "regiment-sample-knight"}") == {}
            reviewer = load("${outfit "regiment-sample-reviewer"}")
            assert reviewer["system"] == {"provider": "cheap", "model": "small", "ttl": "4h"}, reviewer
            assert reviewer["regiment"]["seat"] == "reviewer" and reviewer["regiment"]["agreement"] == agreement, reviewer
            mint = load("${outfit "role-pool-mint"}")
            assert mint["layers"] == ["succession-standard"], mint
            assert mint["succession-policy"] == {"outfit": "default,succession-standard,regiment-sample-steward"}, mint
            assert mint["system"] == {"fanout": {"max_children": 3}}, mint
            assert mint["charter"] == "Keeps reviewers." and mint["regiment"]["seat"] == "steward", mint
            assert load("${outfit "role-thinker-mint"}")["handoff"] == "/tmp/thinker.md"
            assert "system" not in load("${outfit "role-vanguard-mint"}"), "a null maxChildren renders no fork limit"
            PY
            touch $out
          '';

        charter-eval-aspects =
          assert sampleNixos.services.figaro.enable;
          assert sampleNixos.services.figaro.outfits.builder.system.credo == "Sample shared credo.";
          assert sampleNixos.systemd.services ? figaro-roster-reconcile;
          assert sampleNixos.services.hush-cred.enable;
          assert sampleNixos.services.hush-agent.enable;
          assert sampleNixos.systemd.services ? captains-log-append;
          assert sampleNixos.systemd.slices ? heavy;
          assert lib.hasInfix "-s 192.0.2.20 -p tcp --dport 7481 -j nixos-fw-accept"
            sampleNixos.networking.firewall.extraCommands;
          assert lib.hasInfix "-s 192.0.2.20 -p tcp --dport 22 -j nixos-fw-accept"
            sampleNixos.networking.firewall.extraCommands;
          assert builtins.elem "sample-1:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
            sampleNixos.nix.settings.extra-trusted-public-keys;
          assert !(builtins.elem "nixremote" (sampleNixos.nix.settings.trusted-users or [ ]));
          assert builtins.any (lib.hasInfix "my.keel.package") missingSrcFailed;
          assert builtins.any (lib.hasInfix "my.captainsLog.service") missingSrcFailed;
          assert sampleHm.systemd.user.slices ? heavy;
          assert sampleHm.systemd.user.timers ? captains-log-snapshot;
          assert sampleHm.xdg.configFile ? "figaro/outfits/fast.toml";
          assert sampleHm.xdg.configFile ? "figaro/roster";
          assert sampleHm.systemd.user.services ? figaro-forms-bridge;
          assert builtins.any (p: lib.getName p == "remote-builder-host-setup") sampleHm.home.packages;
          assert builtins.any (p: lib.getName p == "figaro-apply-roles") sampleHm.home.packages;
          assert sampleHm.xdg.configFile ? "figaro/outfits/role-lead-charter.toml";
          assert !(sampleHm.xdg.configFile ? "figaro/outfits/role-builder-charter.toml");
          assert sampleHm.xdg.configFile ? "figaro/outfits/role-lead-fanout.toml";
          assert sampleHm.xdg.configFile ? "figaro/outfits/role-clerk-fanout.toml";
          assert !(sampleHm.xdg.configFile ? "figaro/outfits/role-clerk-charter.toml");
          assert !(sampleHm.xdg.configFile ? "figaro/outfits/role-builder-fanout.toml");
          assert
            (rosterLib.roleToTomlAttrs { lead = { }; } "x" {
              kind = "builder";
              purpose = "p";
              mint = false;
              maxChildren = 0;
            }).max_children == 0;
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
