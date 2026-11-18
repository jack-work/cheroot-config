import argparse
import json
import os
import subprocess
import sys
import tomllib

SUCCESSION_OUTFIT = "succession-policy.outfit"


def figaro(*args, check=True):
    env = {k: v for k, v in os.environ.items() if k not in ("FIGARO_ARIA", "FIGARO_TROUPE", "FIGARO_CALLER")}
    out = subprocess.run([FIGARO, *args], env=env, capture_output=True, text=True)
    if check and out.returncode != 0:
        raise RuntimeError(f"figaro {' '.join(args)}: {out.stderr.strip() or out.stdout.strip()}")
    return out


def form_of(form_id):
    out = figaro("state", "show", "--id", form_id, "-j").stdout
    doc = json.loads(out)
    return doc if isinstance(doc, dict) else {}


def lookup(doc, path):
    cur = doc
    for part in path.split("."):
        if not isinstance(cur, dict) or part not in cur:
            return None
        cur = cur[part]
    return cur


def apply_role_form(role, check):
    args = ["form", "apply", "--id", role["id"], "-O", ",".join(role["outfits"]),
            "--managed", ",".join(role["managed"]), "-j"]
    if check:
        args.append("--check")
    return json.loads(figaro(*args).stdout)


def with_outfit(current, outfit):
    names = [n for n in (current or "").split(",") if n]
    return ",".join(names if outfit in names else names + [outfit])


def plan_seat(seat):
    role_form = form_of(seat["form"])
    holder = role_form.get("target-aria") or ""
    plan = {"holder": holder, "holder_set": {}, "succession_outfit": None}
    current = lookup(role_form, SUCCESSION_OUTFIT)
    want = with_outfit(current, seat["outfit"]) if seat["outfit"] else current
    if current is not None and want != current:
        plan["succession_outfit"] = {"from": current, "to": want}
    if not holder:
        plan["error"] = f"{seat['form']} has no holder"
        return plan
    held = form_of(holder)
    for key, value in seat["grants"].items():
        if lookup(held, key) != value:
            plan["holder_set"][key] = value
    return plan


def main():
    ap = argparse.ArgumentParser(prog="figaro-apply-roles")
    ap.add_argument("--check", action="store_true", help="plan every role, change nothing")
    ap.add_argument("-j", "--json", action="store_true")
    opts = ap.parse_args()

    with open(MANIFEST, "rb") as f:
        roles = tomllib.load(f).get("roles", {})
    with open(SEATS) as f:
        seats = json.load(f)

    failed = 0
    names = sorted(set(roles) | set(seats))
    for name in names:
        role = roles.get(name)
        seat = seats.get(name)
        form_id = role["id"] if role else seat["form"]
        check = opts.check or (role or seat).get("mode", "check") != "apply"
        row = {"role": name, "form": form_id, "mode": "check" if check else "apply", "role_form": {"set": [], "remove": []}}
        try:
            if role:
                applied = apply_role_form(role, check=True)
                row["role_form"] = {"set": applied.get("set") or [], "remove": applied.get("remove") or []}
            if seat:
                row.update(plan_seat(seat))
            if "error" in row:
                raise RuntimeError(row["error"])
            if not check:
                if role and (row["role_form"]["set"] or row["role_form"]["remove"]):
                    apply_role_form(role, check=False)
                if row.get("succession_outfit"):
                    figaro("set", "--id", form_id, SUCCESSION_OUTFIT, row["succession_outfit"]["to"])
                for key, value in row.get("holder_set", {}).items():
                    figaro("set", "--id", row["holder"], key, json.dumps(value))
        except (RuntimeError, json.JSONDecodeError) as err:
            failed += 1
            row["error"] = str(err)
        changes = len(row.get("role_form", {}).get("set", [])) + len(row.get("role_form", {}).get("remove", [])) \
            + len(row.get("holder_set", {})) + (1 if row.get("succession_outfit") else 0)
        row["outcome"] = "error" if "error" in row else ("unchanged" if changes == 0 else ("would-apply" if check else "applied"))
        if opts.json:
            print(json.dumps(row, sort_keys=True))
        else:
            print(f"{name} {form_id}: {row['outcome']}")
            if "error" in row:
                print(f"  error: {row['error']}")
            for verb in ("set", "remove"):
                if row.get("role_form", {}).get(verb):
                    print(f"  role form {verb}: {', '.join(row['role_form'][verb])}")
            if row.get("succession_outfit"):
                print(f"  role form {SUCCESSION_OUTFIT}: {row['succession_outfit']['from']} -> {row['succession_outfit']['to']}")
            for key in sorted(row.get("holder_set", {})):
                print(f"  holder {row['holder']} set: {key}")
    if failed:
        print(f"figaro-apply-roles: {failed} of {len(names)} roles failed", file=sys.stderr)
        sys.exit(1)


FIGARO = os.environ.get("FIGARO_APPLY_BIN", "figaro")
MANIFEST = os.environ["FIGARO_APPLY_MANIFEST"]
SEATS = os.environ["FIGARO_APPLY_SEATS"]

if __name__ == "__main__":
    main()
