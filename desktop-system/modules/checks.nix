{ inputs, config, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    let
      inherit (pkgs) lib;
      lock = builtins.fromJSON (builtins.readFile ../flake.lock);

      countRepo =
        repo:
        builtins.length (
          builtins.attrNames (
            lib.filterAttrs (k: n: k != "root" && ((n.locked.repo or n.original.repo or "") == repo)) lock.nodes
          )
        );

      hmHosts = [
        "gluck@gluck"
        "marlowe@cheroot"
        "cig@gluck"
        "gluck@wsl"
        "jack@merlin"
      ];

      hmDrvs = builtins.listToAttrs (
        map (name: {
          inherit name;
          value =
            builtins.unsafeDiscardStringContext
              config.flake.homeConfigurations.${name}.activationPackage.drvPath;
        }) hmHosts
      );

      merlinSystem =
        (inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            config.flake.nixosModules.merlin
            {
              boot.loader.grub.enable = false;
              fileSystems."/" = {
                device = "none";
                fsType = "tmpfs";
              };
            }
          ];
        }).config;

      merlinDrv = builtins.unsafeDiscardStringContext merlinSystem.system.build.toplevel.drvPath;
      gluckCfg = config.flake.homeConfigurations."gluck@gluck".config;
      cherootCfg = config.flake.homeConfigurations."marlowe@cheroot".config;
      gluckPkgNames = map lib.getName gluckCfg.home.packages;
      cherootPkgNames = map lib.getName cherootCfg.home.packages;
    in
    {
      checks.desktop-hosts-eval =
        assert countRepo "nixpkgs" == 1;
        assert countRepo "home-manager" == 1;
        assert countRepo "import-tree" == 1;
        assert countRepo "hush" == 1;
        assert builtins.elem "kc" gluckPkgNames;
        assert builtins.elem "captains-log" gluckPkgNames;
        assert builtins.elem "muse-code" gluckPkgNames;
        assert builtins.elem "helium-exit" gluckPkgNames;
        assert builtins.elem "muse-code" cherootPkgNames;
        assert builtins.elem "figaro" cherootPkgNames;
        assert builtins.elem "hush" cherootPkgNames;
        assert !(builtins.elem "kc" cherootPkgNames);
        assert !(builtins.elem "captains-log" cherootPkgNames);
        assert merlinSystem.networking.hostName == "merlin";
        assert !merlinSystem.services.figaro.enable;
        assert merlinSystem.home-manager.users.jack.programs.figaro.package.version == "0.72.1";
        pkgs.runCommand "desktop-hosts-eval"
          {
            summary = builtins.toJSON {
              inherit hmDrvs merlinDrv;
            };
          }
          ''
            printf '%s\n' "$summary" > $out
          '';

      checks.kingdom-seats =
        let
          files = gluckCfg.xdg.configFile;
          apply = lib.findFirst (p: lib.getName p == "figaro-apply-roles") null gluckCfg.home.packages;
        in
        pkgs.runCommand "kingdom-seats"
          {
            nativeBuildInputs = [ pkgs.python3 ];
            outfits = builtins.toJSON (
              lib.mapAttrs (_: f: "${f.source}") (
                lib.filterAttrs (n: _: lib.hasPrefix "figaro/outfits/role-" n) files
              )
            );
          }
          ''
          python3 - <<'PY'
          import json, os, pathlib, re, tomllib
          roster = pathlib.Path("${files."figaro/roster".source}")
          outfits = {n.removeprefix("figaro/outfits/").removesuffix(".toml"): f for n, f in json.loads(os.environ["outfits"]).items()}
          script = open("${lib.getExe apply}").read()
          manifest = tomllib.load(open(re.search(r"FIGARO_APPLY_MANIFEST=(\S+)", script).group(1), "rb"))["roles"]
          seats_json = json.load(open(re.search(r"FIGARO_APPLY_SEATS=(\S+)", script).group(1)))
          lane = ["send:parent", "read:aria:self", "write:aria:self#@self", "delete:aria:self#@self"]
          verb = re.compile(r"^(\*|read|listen|send|fork|set|write|create|mint|kill|admin|use|join|decide|adopt|lease|say|delete|cast|succeed):(\*|[^*]+)$")
          count = lambda v: isinstance(v, int) and not isinstance(v, bool) and v >= 0
          roles = {f.stem: tomllib.load(open(f, "rb")) for f in roster.glob("*.toml")}
          fleet, seats = set(), {}
          for name, r in sorted(roles.items()):
              if "form" not in r:
                  continue
              if "companion_of" in r:
                  primary = roles[r["companion_of"]]
                  assert "max_children" in primary and not {"max_children", "quota", "scopes", "child_policy"} & r.keys(), name
                  assert name not in seats_json and f"role-{name}-grants" not in outfits, name
                  continue
              assert count(r.get("max_children")), (name, "budget")
              if r["reach"] == "fleet":
                  assert "quota" not in r, (name, "a fleet seat's quota is set by Gluck, never derived")
              else:
                  assert count(r.get("quota")) and r["quota"] >= r["max_children"], (name, "quota")
              policy = r["child_policy"]
              assert isinstance(policy, dict) and policy["system.scopes"][:4] == lane, (name, policy)
              assert f"send:role:{r['form']}" in policy["system.scopes"], (name, "own role")
              assert not any(s.startswith("read:aria:@") for s in policy["system.scopes"]), (name, "the daemon resolves a sent-to role; a lane reads no role holder")
              assert all(verb.match(s) for s in policy["system.scopes"]), (name, policy)
              if r["reach"] == "fleet":
                  assert r["scopes"] == ["*:*"], name
                  fleet.add(name)
              else:
                  assert "scopes" not in r, name
              m = manifest[name]
              assert ("system.fanout.quota" in m["managed"]) == ("quota" in r) and "system.fanout.max_children" in m["managed"], (name, m)
              fan = tomllib.load(open(outfits[f"role-{name}-fanout"], "rb"))["system"]["fanout"]
              assert fan == {k: r[k] for k in ("max_children", "quota") if k in r}, (name, fan)
              assert seats_json[name]["form"] == r["form"] and seats_json[name]["grants"]["system.child_policy"] == policy, name
              if r["reach"] == "fleet":
                  assert tomllib.load(open(outfits[f"role-{name}-grants"], "rb")) == {"system": {"scopes": ["*:*"]}}, name
                  assert seats_json[name]["outfit"] == f"role-{name}-grants", name
              else:
                  assert f"role-{name}-grants" not in outfits and seats_json[name]["outfit"] is None, name
              seats[name] = r
          when_full = "${gluckCfg.my.figaro.fanoutWhenFull}"
          for name, m in manifest.items():
              assert "fanout" in m["managed"] and f"role-{name}-fields" in m["outfits"], (name, m)
              assert tomllib.load(open(outfits[f"role-{name}-fields"], "rb"))["fanout"] == {"when-full": when_full}, name
          assert set(manifest) == {n for n, r in roles.items() if "form" in r}, "every seat with a form carries fanout.when-full"
          assert fleet == {"king-of-spain", "figaro-engineer", "figaro-knight", "figaro-review-steward"}, fleet
          sends = lambda n: [s for s in seats[n]["child_policy"]["system.scopes"] if s.startswith("send:role:")]
          assert sends("figaro-strategist") == ["send:role:@9bf485c24507fe8484a001c18a1b84cc", "send:role:@d121c4041785b13c6261d6055f113f8d", "send:role:@9e5bdab374ebdf583434860ff1fa9955"], sends("figaro-strategist")
          assert sends("figaro-engineer") == ["send:role:@ee9271497f3823d7f50922bec4899818", "send:role:@96447061"], sends("figaro-engineer")
          assert sends("king-of-spain") == ["send:role:@96447061", "send:role:@662ee4fedbd0fdbad7ad6adef20cdeee"], sends("king-of-spain")
          print(f"{len(seats)} seats, {len(fleet)} fleet, {len(roles) - len(seats)} roles without a seat of their own")
          PY
          touch $out
        '';
    };
}
