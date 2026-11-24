usage() {
  cat >&2 <<'EOF'
usage: deploy-span [-a key=value]... [-o ok|fail|skip] <step> <sha>[,<sha>...] [-- command [arg...]]

Runs the command and sends one span per sha into the trace named by that sha
(trace id = its first 32 hex). The span records the command's duration and
deploy.outcome; deploy-span exits with the command's status. With no command,
-o gives the outcome and the span has no duration.

steps: queue review merge build dev_deploy prod_deploy cut
env:   DEPLOY_SPAN_ENDPOINT  OTLP/HTTP base (default http://127.0.0.1:4318)
       DEPLOY_ACTOR          role name, sent as actor
       FIGARO_ARIA           holder's aria id, sent as actor.aria
EOF
  exit 2
}

attrs=()
outcome=
while [ $# -gt 0 ]; do
  case $1 in
    -a) [ $# -ge 2 ] || usage; attrs+=("$2"); shift 2 ;;
    -o) [ $# -ge 2 ] || usage; outcome=$2; shift 2 ;;
    -h|--help) usage ;;
    -*) usage ;;
    *) break ;;
  esac
done
[ $# -ge 2 ] || usage
step=$1 shas=$2
shift 2

case $step in
  queue|review|merge|build|dev_deploy|prod_deploy|cut) ;;
  *) echo "deploy-span: unknown step $step" >&2; usage ;;
esac

if [ $# -gt 0 ]; then
  [ "$1" = "--" ] || usage
  shift
fi

case $outcome in
  ""|ok|fail|skip) ;;
  *) echo "deploy-span: outcome must be ok, fail or skip" >&2; exit 2 ;;
esac
if [ $# -eq 0 ] && [ -z "$outcome" ]; then
  echo "deploy-span: give a command or -o" >&2
  exit 2
fi

full_shas=()
IFS=, read -ra given <<<"$shas"
for s in "${given[@]}"; do
  if [[ $s =~ ^[0-9a-f]{40}$ ]]; then
    full_shas+=("$s")
  elif full=$(git rev-parse --verify --quiet "$s^{commit}" 2>/dev/null); then
    full_shas+=("$full")
  else
    echo "deploy-span: $s is not a full sha and does not resolve here" >&2
    exit 2
  fi
done

start=$(date +%s.%N)
status=0
if [ $# -gt 0 ]; then
  "$@" || status=$?
  if [ -z "$outcome" ]; then
    if [ "$status" -eq 0 ]; then outcome=ok; else outcome=fail; fi
  fi
fi
end=$(date +%s.%N)

csv() { printf '"%s"' "${1//\"/\"\"}"; }

common=(
  -a "$(csv "deploy.step=$step")"
  -a "$(csv "deploy.outcome=$outcome")"
)
[ $# -gt 0 ] && common+=(-a "$(csv "process.exit_code=$status")")
[ -n "${DEPLOY_ACTOR:-}" ] && common+=(-a "$(csv "actor=$DEPLOY_ACTOR")")
[ -n "${FIGARO_ARIA:-}" ] && common+=(-a "$(csv "actor.aria=$FIGARO_ARIA")")
for kv in "${attrs[@]}"; do
  [[ $kv == *=* ]] || { echo "deploy-span: attribute $kv lacks =" >&2; continue; }
  common+=(-a "$(csv "$kv")")
done

span_status=ok
[ "$outcome" = fail ] && span_status=error

for sha in "${full_shas[@]}"; do
  otel-cli span \
    --endpoint "${DEPLOY_SPAN_ENDPOINT:-http://127.0.0.1:4318}" \
    --protocol http/protobuf \
    --timeout 2s \
    --service deploy-span \
    --name "deploy.$step" \
    --kind internal \
    --force-trace-id "${sha:0:32}" \
    --start "$start" --end "$end" \
    --status-code "$span_status" \
    -a "$(csv "vcs.sha=$sha")" \
    "${common[@]}" || true
done

exit "$status"
