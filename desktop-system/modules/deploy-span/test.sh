set -euo pipefail
dir=$(mktemp -d)
otel-cli server json --endpoint http://127.0.0.1:14399 --dir "$dir" >/dev/null 2>&1 &
srv=$!
trap 'kill $srv 2>/dev/null || true' EXIT
for _ in $(seq 100); do (exec 3<>/dev/tcp/127.0.0.1/14399) 2>/dev/null && break; sleep 0.1; done

export DEPLOY_SPAN_ENDPOINT=http://127.0.0.1:14399 DEPLOY_ACTOR=flakes-charter FIGARO_ARIA=0123abcd
a=0123456789abcdef0123456789abcdef01234567
b=fedcba9876543210fedcba9876543210fedcba98

deploy-span -a deploy.cand=c1 -a vcs.ref=a,b build "$a,$b" -- true
if deploy-span review "$a" -- sh -c 'exit 3'; then
  echo "the command's failure was swallowed"; exit 1
else
  [ $? -eq 3 ] || { echo "exit status not passed through"; exit 1; }
fi
deploy-span -o skip cut "$b"
DEPLOY_SPAN_ENDPOINT=http://127.0.0.1:9 deploy-span build "$a" -- true

for _ in $(seq 100); do [ "$(find "$dir" -name span.json | wc -l)" -ge 4 ] && break; sleep 0.1; done

python3 - "$dir" <<'EOF'
import base64, json, pathlib, sys
spans = []
for p in pathlib.Path(sys.argv[1]).rglob("span.json"):
    s = json.loads(p.read_text())
    attrs = {a["key"]: next(iter(a["value"]["Value"].values())) for a in s["attributes"]}
    spans.append((base64.b64decode(s["trace_id"]).hex(), s["name"], attrs))
assert len(spans) == 4, spans
by = {(t, n): a for t, n, a in spans}
a, b = "0123456789abcdef0123456789abcdef", "fedcba9876543210fedcba9876543210"
for t in (a, b):
    x = by[(t, "deploy.build")]
    assert x["deploy.outcome"] == "ok" and x["deploy.cand"] == "c1" and x["vcs.ref"] == "a,b", x
    assert x["vcs.sha"].startswith(t) and x["actor"] == "flakes-charter" and x["actor.aria"] == "0123abcd", x
r = by[(a, "deploy.review")]
assert r["deploy.outcome"] == "fail" and r["process.exit_code"] == 3, r
c = by[(b, "deploy.cut")]
assert c["deploy.outcome"] == "skip" and "process.exit_code" not in c, c
print("deploy-span ok")
EOF
