import json, os, pathlib, re, tomllib
roster = pathlib.Path(os.environ["roster"])
outfits = {n.removeprefix("figaro/outfits/").removesuffix(".toml"): f for n, f in json.loads(os.environ["outfits"]).items()}
script = open(os.environ["apply"]).read()
manifest = tomllib.load(open(re.search(r"FIGARO_APPLY_MANIFEST=(\S+)", script).group(1), "rb"))["roles"]
seats_json = json.load(open(re.search(r"FIGARO_APPLY_SEATS=(\S+)", script).group(1)))
lane = ["send:parent", "read:aria:self", "write:aria:self#@self", "delete:aria:self#@self"]
roles = {f.stem: tomllib.load(open(f, "rb")) for f in roster.glob("*.toml")}
fleet, seats = set(), {}
for name, r in sorted(roles.items()):
    if "form" not in r:
        continue
    if "companion_of" in r:
        primary = roles[r["companion_of"]]
        assert "max_children" in primary and not {"max_children", "quota", "scopes", "child_policy"} & r.keys(), name
        assert name not in seats_json and f"role-{name}-grants" not in outfits, name
        assert {"system.fanout.max_children", "system.fanout.quota"} <= set(manifest[name]["managed"]), (name, "a companion's own limit is removed, so only its primary's counts")
        continue
    assert "max_children" in r, (name, "budget")
    if r["reach"] == "fleet":
        assert "quota" not in r, (name, "a fleet seat's quota is set by Gluck, never derived")
    else:
        assert "quota" in r, (name, "quota")
    policy = r["child_policy"]
    assert isinstance(policy, dict) and policy["system.scopes"][:4] == lane, (name, policy)
    assert f"send:role:{r['form']}" in policy["system.scopes"], (name, "own role")
    assert not any(s.startswith("read:aria:@") for s in policy["system.scopes"]), (name, "the daemon resolves a sent-to role; a lane reads no role holder")
    if r["reach"] == "fleet":
        assert r["scopes"][0] == "*:*", name
        fleet.add(name)
    else:
        assert "scopes" not in r, name
    m = manifest[name]
    assert ("system.fanout.quota" in m["managed"]) == ("quota" in r) and "system.fanout.max_children" in m["managed"], (name, m)
    fan = tomllib.load(open(outfits[f"role-{name}-fanout"], "rb"))["system"]["fanout"]
    assert fan == {k: r[k] for k in ("max_children", "quota") if k in r}, (name, fan)
    assert seats_json[name]["form"] == r["form"] and seats_json[name]["grants"]["system.child_policy"] == policy, name
    if r["reach"] == "fleet":
        assert tomllib.load(open(outfits[f"role-{name}-grants"], "rb")) == {"system": {"scopes": r["scopes"]}}, name
        assert seats_json[name]["outfit"] == f"role-{name}-grants", name
    else:
        assert f"role-{name}-grants" not in outfits and seats_json[name]["outfit"] is None, name
    seats[name] = r
when_full = os.environ["whenFull"]
for name, m in manifest.items():
    assert "fanout" in m["managed"] and f"role-{name}-fields" in m["outfits"], (name, m)
    assert tomllib.load(open(outfits[f"role-{name}-fields"], "rb"))["fanout"] == {"when-full": when_full}, name
assert set(manifest) == {n for n, r in roles.items() if "form" in r}, "every seat with a form carries fanout.when-full"
assert fleet == {"king-of-spain", "figaro-engineer", "figaro-knight"}, fleet
sends = lambda n: [s for s in seats[n]["child_policy"]["system.scopes"] if s.startswith("send:role:")]
assert sends("figaro-engineer") == ["send:role:@ee9271497f3823d7f50922bec4899818", "send:role:@96447061"], sends("figaro-engineer")
assert sends("king-of-spain") == ["send:role:@96447061", "send:role:@662ee4fedbd0fdbad7ad6adef20cdeee"], sends("king-of-spain")
print(f"{len(seats)} seats, {len(fleet)} fleet, {len(roles) - len(seats)} roles without a seat of their own")
