{
  pkgs,
  charter,
  houseModule,
}:
pkgs.testers.runNixOSTest {
  name = "merlin-house";

  nodes.merlin =
    { ... }:
    {
      imports = [ houseModule ];
      virtualisation.memorySize = 2048;
      users.users.jack = {
        isNormalUser = true;
        uid = 1000;
      };
      users.users.bob = {
        isNormalUser = true;
        uid = 1001;
      };
      my.figaro = {
        providers.gateway.base_url = "http://127.0.0.1:8099/v1";
        outfits.bare.system = {
          provider = "gateway";
          model = "stub";
        };
        outfits.role-probe-charter.charter = "Probe duty.";
      };
      systemd.services.stub-model = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig.ExecStart = "${pkgs.python3}/bin/python3 ${./stub-model.py} ${./merlin-house-probe.sh}";
      };
      environment.systemPackages = [
        pkgs.jq
        pkgs.python3
      ];
    };

  testScript = ''
    import json

    def jack(cmd):
        return merlin.succeed(f"su - jack -c {json.dumps(cmd)}")

    def idle(fig):
        merlin.wait_until_succeeds(
            f"su - jack -c 'figaro status {fig} -j' | grep -Eq '\"state\": ?\"idle\"'", timeout=90)

    start_all()
    merlin.wait_for_unit("figaro.socket")
    merlin.wait_for_unit("stub-model.service")
    merlin.wait_for_unit("user@1000.service")
    merlin.wait_for_unit("figaro-valet.socket", "jack")

    with subtest("hush: jack's agent socket is up in his user manager"):
        merlin.wait_until_succeeds("systemctl --user -M jack@ list-sockets --no-legend | grep -q hush", timeout=60)

    with subtest("house mode: the angelus runs as uid figaro and jack owns it"):
        print(jack("figaro ls --json"))
        assert merlin.succeed("ps -o user= -p $(systemctl show -p MainPID --value figaro.service)").strip() == "figaro"
        doc = json.loads(jack("figaro doctor mode -j"))
        print(doc)
        assert doc["mode"] == "house" and doc["valet"]["answers"] is True, doc
        status, out = merlin.execute("su - bob -c 'figaro ls --json' 2>&1")
        assert status != 0, out

    with subtest("valet and tool start: a tool runs as jack in a granted directory"):
        jack("mkdir -p ~/dev/work && figaro valet grant '*' ~/dev/work rw --for 1h")
        fig = json.loads(jack("figaro new -j -O bare -S system.cwd=/home/jack/dev/work -- probe").strip().splitlines()[-1])["aria_id"]
        idle(fig)
        shown = jack(f"figaro show {fig}")
        print(shown)
        assert "uid=1000" in shown and "pwd=/home/jack/dev/work" in shown and "wrote" in shown, shown
        assert "door-absent" in shown, shown
        assert merlin.succeed("stat -c %U /home/jack/dev/work/written").strip() == "jack"

    with subtest("roles apply: check reports a seated role and an unseated one"):
        seated = json.loads(jack(f"figaro form new -S name=probe,target-aria={fig} -j"))["form_id"]
        unseated = json.loads(jack("figaro form new -S name=probe-unseated -j"))["form_id"]
        manifest = "\n".join([
            "[roles.probe]", f'id = "{seated}"', 'outfits = ["role-probe-charter"]', 'managed = ["charter"]', 'mode = "check"',
            "[roles.probe-unseated]", f'id = "{unseated}"', 'outfits = ["role-probe-charter"]', 'managed = ["charter"]', 'mode = "check"',
        ])
        merlin.succeed("cat > /tmp/roles.toml <<'EOF'\n" + manifest + "\nEOF")
        merlin.succeed("echo '{}' > /tmp/seats.json && chmod 644 /tmp/roles.toml /tmp/seats.json")
        out = jack("FIGARO_APPLY_MANIFEST=/tmp/roles.toml FIGARO_APPLY_SEATS=/tmp/seats.json python3 ${charter}/lib/apply-roles.py --check -j")
        print(out)
        rows = {r["role"]: r for r in map(json.loads, out.strip().splitlines())}
        assert rows["probe"]["outcome"] == "would-apply" and rows["probe"]["role_form"]["set"] == ["charter"], rows
        assert rows["probe-unseated"]["outcome"] == "unseated", rows

    with subtest("outfits: managed root and user overlay (waits on figaro outfit roots)"):
        print("skipped until lane/outfit-roots ships")
  '';
}
