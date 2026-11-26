{ inputs, config, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    let
      inherit (pkgs) lib;
      lockGate = config.flake.lib.lockGate;
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
            config.flake.modules.nixos.remote-builder-host
            {
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
              users.users.operator = {
                isNormalUser = true;
                uid = 1000;
              };
              my.figaro = {
                mode = "house";
                owner = "operator";
                credo = "Sample shared credo.";
                outfits.builder.system = {
                  provider = "gateway";
                  model = "sample-model";
                };
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

      figaroModeNixos =
        mode:
        (inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            config.flake.modules.nixos.figaro
            {
              boot.loader.grub.enable = false;
              fileSystems."/" = {
                device = "none";
                fsType = "tmpfs";
              };
              system.stateVersion = "26.11";
              users.users.operator = {
                isNormalUser = true;
                uid = 1000;
              };
              my.figaro = {
                inherit mode;
              }
              // lib.optionalAttrs (mode != "estate") { owner = "operator"; };
            }
          ];
        }).config;
      aliasNixos = figaroModeNixos "system";
      estateNixos = figaroModeNixos "estate";

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
              my.figaroFormsBridge.tunnel = "edge-host";
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
              };
              my.roles = {
                standing.patrol = "Walk the walls.";
                orchestration = "Start from the lane index.";
                roles.crown = {
                  form = "@aaaaaaaa";
                  title = "Crown";
                  seat = "king";
                };
                roles.planner = {
                  title = "Planner";
                  seat = "strategist";
                  regiment = "backend";
                  reportsTo = "lead";
                };
                roles.lead = {
                  form = "@0123456789abcdef0123456789abcdef";
                  title = "Lead";
                  seat = "knight";
                  regiment = "backend";
                  reportsTo = "crown";
                  charter = "Holds the order.";
                  outfits = [ "fast" ];
                  lanes.gate = "fleet.lane.lead.gate";
                  standing.patrol = "Hold the gate.";
                  fanout = {
                    min_children = 1;
                    max_children = 2;
                    quota = 4;
                  };
                };
                roles.clerk = {
                  form = "@89abcdef";
                  title = "Clerk";
                  seat = "lead";
                  regiment = "figaro";
                  index = "fleet.clerk";
                };
                roles.inspector = {
                  form = "@fedcba98";
                  title = "Inspector";
                  seat = "inspector";
                  reviewers.max_children = 1;
                };
                forms.handoff = {
                  form = "@cccccccc";
                  title = "Handoff";
                  under = "lead";
                  studiedBy = [ "lead" ];
                  kinds = [
                    "work"
                    "handoff"
                  ];
                };
                forms.reviews = {
                  form = "@dddddddd";
                  title = "Reviews";
                  under = "inspector";
                  studiedBy = [
                    "inspector"
                    "crown"
                  ];
                  kinds = [ "review" ];
                  priority = true;
                };
                forms.later = {
                  title = "Later";
                  under = "crown";
                  studiedBy = [ "crown" ];
                  kinds = [ "deploy" ];
                };
                queueContract = "https://contract.example.invalid/work-orders";
              };
            }
          ];
        }).config;
      bridge = sampleHm.systemd.user.services.figaro-forms-bridge.Service;
      bridgeTunnel = sampleHm.systemd.user.services.figaro-forms-bridge-tunnel;
    in
    {
      checks = {
        lock-github-only =
          assert lockGate.assertGithubOnlyLock realLock;
          assert !(builtins.tryEval (lockGate.assertGithubOnlyLock fakeSshLock)).success;
          assert !(builtins.tryEval (lockGate.assertGithubOnlyLock fakePathLock)).success;
          assert !(builtins.tryEval (lockGate.assertGithubOnlyLock fakeDualNixpkgsLock)).success;
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

        charter-roles =
          let
            files = sampleHm.xdg.configFile;
            refusedWith =
              decl:
              !(builtins.tryEval (
                (inputs.home-manager.lib.homeManagerConfiguration {
                  inherit pkgs;
                  modules = [
                    config.flake.modules.homeManager.figaro
                    {
                      home.username = "operator";
                      home.homeDirectory = "/home/operator";
                      home.stateVersion = "26.05";
                      my.figaro.package = null;
                    }
                    decl
                  ];
                }).activationPackage.drvPath
              )).success;
            refused = roles: refusedWith { my.roles.roles = roles; };
            one = extra: {
              a = {
                form = "@01234567";
                title = "A";
                seat = "lead";
                regiment = "figaro";
              }
              // extra;
            };
            withForm = f: {
              my.roles.roles = one { };
              my.roles.forms.q = {
                title = "Q";
                under = "a";
                studiedBy = [ "a" ];
                kinds = [ "work" ];
              }
              // f;
            };
            regiment = {
              lead.title = "Lead";
              strategist = {
                title = "Strategist";
                fanout.max_children = 1;
              };
              knight = {
                title = "Knight";
                fanout.max_children = 1;
              };
            };
            templated =
              (inputs.home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                modules = [
                  config.flake.modules.homeManager.figaro
                  {
                    home.username = "operator";
                    home.homeDirectory = "/home/operator";
                    home.stateVersion = "26.05";
                    my.figaro.package = null;
                    my.charter = {
                      centralCommand = {
                        form = "@aaaaaaaa";
                        title = "Crown";
                      };
                      regiments.north = regiment // {
                        knight = regiment.knight // {
                          form = "@bbbbbbbb";
                        };
                        handoff.form = "@cccccccc";
                      };
                      regiments.south = regiment;
                      inspector = {
                        seat.title = "Inspector";
                        reviewers.max_children = 1;
                      };
                      edge = {
                        seat = {
                          form = "@eeeeeeee";
                          title = "Edge";
                          fanout.max_children = 1;
                        };
                        deploy.form = "@dddddddd";
                      };
                    };
                  }
                ];
              }).config;
          in
          assert refused (one { form = "@xyz"; });
          assert refused (
            one { lanes.b = "fleet.lane.a.b"; }
            // {
              b = {
                form = "@11234567";
                title = "B";
                seat = "lead";
                regiment = "figaro";
              };
            }
          );
          assert refused (one { lanes.c = "fleet.lane.b.d"; });
          assert !(refused (one { lanes.c = "fleet.lane.b.c"; }));
          assert refused (one { seat = "lead"; fanout.max_children = 1; });
          assert refused (one { reviewers.max_children = 1; });
          assert refused (one { seat = "knight"; regiment = null; });
          assert refused (one { reportsTo = "nobody"; });
          assert refused (
            one {
              seat = "edge";
              fanout = {
                min_children = 3;
                max_children = 2;
              };
            }
          );
          assert refused {
            reviewer-a = {
              form = "@01234567";
              title = "Reviewer";
              seat = "lead";
              regiment = "figaro";
            };
          };
          assert refused (
            one { seat = "king"; regiment = null; }
            // {
              b = {
                form = "@11234567";
                title = "B";
                seat = "king";
              };
            }
          );
          assert !(refusedWith (withForm { }));
          assert refusedWith (withForm { kinds = [ ]; });
          assert refusedWith (withForm { priority = true; });
          assert refusedWith (withForm { under = "nobody"; });
          assert refusedWith (withForm { studiedBy = [ "nobody" ]; });
          assert refusedWith (withForm { studiedBy = [ ]; });
          assert refusedWith (
            lib.recursiveUpdate (withForm { kinds = [ "review" ]; }) {
              my.roles.forms.r = {
                title = "R";
                under = "a";
                studiedBy = [ "a" ];
                kinds = [ "review" ];
              };
            }
          );
          pkgs.runCommand "charter-roles"
            {
              nativeBuildInputs = [ pkgs.python3 ];
              roleOutfits = builtins.toJSON (
                lib.mapAttrs (_: f: "${f.source}") (
                  lib.filterAttrs (n: _: lib.hasPrefix "figaro/outfits/role-" n) files
                )
              );
              templatedRoles = builtins.toJSON (
                lib.mapAttrs (_: r: {
                  inherit (r) form seat regiment reportsTo;
                  max = r.fanout.max_children;
                }) templated.my.roles.roles
              );
              templatedForms = builtins.toJSON (
                lib.mapAttrs (_: f: { inherit (f) form under studiedBy kinds priority; }) templated.my.roles.forms
              );
            }
            ''
            python3 - <<'PY'
            import json, os, tomllib
            m = json.load(open("${files."figaro/roles.json".source}"))
            roles = {r["name"]: r for r in m["roles"]}
            assert set(roles) == {"lead", "clerk", "inspector", "crown", "form-handoff", "form-reviews"}, roles
            assert m["unminted"] == ["planner", "form-later"], m["unminted"]
            chartered = ["chartered." + k for k in ["regiment", "reports-to", "root", "seat", "studies", "succession-abdication", "succession-ttl"]]
            assert roles["lead"] == {"name": "lead", "form": "@0123456789abcdef0123456789abcdef", "outfits": ["role-lead"],
                "managed": ["charter"] + chartered + ["lanes.gate", "name", "orchestration.policy", "role-name", "standing.patrol",
                "system.fanout.max_children", "system.fanout.min_children", "system.fanout.quota", "system.grants.outfits"]}, roles["lead"]
            assert roles["clerk"]["managed"] == ["chartered.regiment", "chartered.root", "chartered.seat", "chartered.succession-abdication", "chartered.succession-ttl",
                "index", "name", "orchestration.policy", "role-name", "standing.patrol"], roles["clerk"]
            assert not any(k == "queue" or k.startswith("queue.") for r in m["roles"] for k in r["managed"]), "the charter never manages queue entries"
            assert not any(k.startswith("queue-contract") for n, r in roles.items() if not n.startswith("form-") for k in r["managed"]), "queues live on queue forms, not role forms"
            out = lambda n: tomllib.load(open(json.loads(os.environ["roleOutfits"])["figaro/outfits/role-" + n + ".toml"], "rb"))
            lead = out("lead")
            charter = lead.pop("charter")
            assert charter.startswith("Holds the order.\n\n## Work orders\n\n"), charter
            assert "conditional on the version it read" in charter and "handcrafted codename" in charter and "priority map" not in charter, charter
            assert lead.pop("chartered") == {"seat": "knight", "regiment": "backend", "root": "@aaaaaaaa", "reports-to": "@aaaaaaaa",
                "studies": ["@cccccccc"], "succession-abdication": "retire", "succession-ttl": "5m"}
            assert lead == {"name": "Lead", "role-name": "Lead", "lanes": {"gate": "fleet.lane.lead.gate"},
                "standing": {"patrol": "Hold the gate."}, "orchestration": {"policy": "Start from the lane index."},
                "system": {"grants": {"outfits": ["fast"]}, "fanout": {"min_children": 1, "max_children": 2, "quota": 4}}}, lead
            crown = out("crown")
            assert crown["chartered"] == {"seat": "king", "root": "@aaaaaaaa", "central-command": True, "studies": ["@dddddddd"],
                "succession-abdication": "retire", "succession-ttl": "5m"}, crown
            assert "priority map" in crown["charter"], crown["charter"]
            inspector = out("inspector")
            assert inspector["charter"].startswith("## Work orders\n\n") and "minted here at runtime" in inspector["charter"], inspector["charter"]
            assert inspector["chartered"]["reviewer-max-children"] == 1 and "queue-contract" not in inspector, inspector
            handoff = out("form-handoff")
            assert handoff == {"name": "Handoff", "chartered": {"kind": "queue-form", "root": "@aaaaaaaa", "under": "@0123456789abcdef0123456789abcdef"},
                "queue-contract": {"version": "v0", "contract": "https://contract.example.invalid/work-orders", "kinds": ["work", "handoff"], "priority": False,
                "entries": "queue.<id>", "id": "two hyphenated lowercase words, unique on the form", "order": "priority, then state_at", "posters-write": "queue.**",
                "states": ["posted", "claimed", "blocked", "review", "done", "cancelled"]}}, handoff
            reviews = out("form-reviews")
            assert reviews["queue-contract"]["priority"] is True and reviews["queue-contract"]["kinds"] == ["review"] and reviews["chartered"]["under"] == "@fedcba98", reviews
            clerk = out("clerk")
            assert clerk["standing"] == {"patrol": "Walk the walls."} and "succession-policy" not in clerk, clerk
            for r in m["roles"]:
                assert not any(k.startswith(("system.model", "system.provider", "succession-policy")) for k in r["managed"]), r
            rendered = json.loads(os.environ["roleOutfits"])
            assert not [n for n in rendered if n.endswith("-grants.toml")], ("the daemon holds holder grants; no role-*-grants outfit", rendered)
            for n, f in rendered.items():
                assert "succession-policy" not in tomllib.load(open(f, "rb")), (n, "the daemon holds succession-policy")
            t = json.loads(os.environ["templatedRoles"])
            assert set(t) == {"central-command", "north-lead", "north-strategist", "north-knight", "south-lead", "south-strategist", "south-knight", "inspector", "edge-engineer"}, t
            assert t["central-command"]["seat"] == "king" and t["central-command"]["reportsTo"] is None, t
            for r in ("north", "south"):
                assert t[r + "-lead"] == {"form": None, "seat": "lead", "regiment": r, "reportsTo": "central-command", "max": None}, t
                assert t[r + "-strategist"]["reportsTo"] == r + "-lead" and t[r + "-strategist"]["max"] == 1, t
                assert t[r + "-knight"]["reportsTo"] == r + "-lead" and t[r + "-knight"]["max"] == 1, t
            assert t["north-knight"]["form"] == "@bbbbbbbb", t
            assert t["inspector"]["reportsTo"] == "central-command" and t["inspector"]["max"] is None, t
            assert t["edge-engineer"] == {"form": "@eeeeeeee", "seat": "edge", "regiment": None, "reportsTo": "central-command", "max": 1}, t
            f = json.loads(os.environ["templatedForms"])
            assert set(f) == {"north-handoff", "south-handoff", "inspector", "deploy"}, f
            assert f["north-handoff"] == {"form": "@cccccccc", "under": "north-lead", "studiedBy": ["north-knight"], "kinds": ["work", "handoff"], "priority": False}, f
            assert f["inspector"]["studiedBy"] == ["inspector", "central-command"] and f["inspector"]["priority"] is True, f
            assert f["deploy"] == {"form": "@dddddddd", "under": "edge-engineer", "studiedBy": ["edge-engineer"], "kinds": ["deploy"], "priority": False}, f
            PY
            touch $out
          '';

        charter-eval-aspects =
          assert sampleNixos.services.figaro.enable;
          assert sampleNixos.services.figaro.mode == "house";
          assert sampleNixos.services.figaro.settings.authz.owner == "user:1000";
          assert !sampleNixos.services.figaro.settings.sandbox.local_tools;
          assert aliasNixos.services.figaro.mode == "house";
          assert builtins.any (lib.hasInfix "is house mode") aliasNixos.warnings;
          assert estateNixos.services.figaro.mode == "estate";
          assert !((estateNixos.services.figaro.settings.authz or { }) ? owner);
          assert sampleNixos.services.figaro.outfits.builder.system.credo == "Sample shared credo.";
          assert sampleNixos.services.hush-cred.enable;
          assert sampleNixos.services.hush-agent.enable;
          assert sampleNixos.systemd.services ? captains-log-append;
          assert sampleNixos.systemd.slices ? heavy;
          assert !(lib.hasInfix "--dport 7481" sampleNixos.networking.firewall.extraCommands);
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
          assert sampleHm.xdg.configFile ? "figaro/roles.json";
          assert sampleHm.systemd.user.services ? figaro-forms-bridge;
          assert builtins.any (p: lib.getName p == "remote-builder-host-setup") sampleHm.home.packages;
          assert builtins.any (p: lib.getName p == "figaro-apply") sampleHm.home.packages;
          assert builtins.match ".*/bin/figaro-forms-bridge --edge --port 7481 --admin admin --drift-command /nix/store/[^ ]+/bin/figaro-apply --peer 127.0.0.1" (
            lib.concatStringsSep " " (lib.toList bridge.ExecStart)
          ) != null;
          assert lib.toList bridge.LoadCredential == [ "edge:%h/.config/figaro-forms-bridge/edge-token" ];
          assert !(sampleHm.xdg.configFile ? "hush/commands/figaro-forms-bridge/command.toml");
          assert lib.hasSuffix "-R 127.0.0.1:7481:127.0.0.1:7481 edge-host" (
            lib.concatStringsSep " " (lib.toList bridgeTunnel.Service.ExecStart)
          );
          assert bridgeTunnel.Unit.Requires == [ "figaro-forms-bridge.service" ];
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
