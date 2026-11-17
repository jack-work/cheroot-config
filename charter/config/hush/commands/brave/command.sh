# Brave Search — stateless. The free plan allows 1 request/second, so the
# only concurrency control is retry with exponential backoff + jitter:
# nothing is written to disk, no locks, no coordination between callers.
# The first attempt always fires immediately, so a lone caller pays nothing.

query="$1"

max_attempts=8     # total tries, including the first
base=1.2           # seconds; first backoff window
cap=30             # seconds; largest backoff window

# Random 0..1, seeded per-process from /dev/urandom so that parallel callers
# never pick the same delay (awk's srand() would collide within a second).
rand01() {
  r=$(od -An -N2 -tu2 /dev/urandom 2>/dev/null | tr -d ' ')
  [ -n "$r" ] || r=$$
  awk -v r="$r" 'BEGIN { printf "%.6f", (r % 65536) / 65536 }'
}

url="https://api.search.brave.com/res/v1/web/search?q=$(printf '%s' "$query" | jq -sRr @uri)&count=5"

attempt=1
while :; do
  response=$(curl -s -w "\n%{http_code}" \
    -H "Accept: application/json" \
    -H "X-Subscription-Token: $BRAVE_API_KEY" \
    "$url")

  http_code=$(printf '%s' "$response" | tail -1)
  body=$(printf '%s\n' "$response" | sed '$d')

  case "$http_code" in
    200) break ;;
    429|500|502|503|504)
      if [ "$attempt" -ge "$max_attempts" ]; then
        echo "Error: HTTP $http_code after $attempt attempts" >&2
        echo "$body" >&2
        exit 1
      fi
      # half jitter: window = min(cap, base * 2^(attempt-1)); sleep 50..100% of it
      delay=$(awk -v a="$attempt" -v b="$base" -v c="$cap" -v j="$(rand01)" \
        'BEGIN { w = b * (2 ^ (a - 1)); if (w > c) w = c; printf "%.3f", w * (0.5 + j / 2) }')
      echo "brave: HTTP $http_code, retrying in ${delay}s (attempt $attempt/$max_attempts)" >&2
      sleep "$delay"
      attempt=$((attempt + 1))
      ;;
    *)
      echo "Error: HTTP $http_code" >&2
      echo "$body" >&2
      exit 1
      ;;
  esac
done

echo "$body" | jq -e '.web.results' > /dev/null 2>&1 || {
  echo "No results found." >&2
  exit 0
}

echo "$body" | jq -r '.web.results[:5][] | "\(.title)\n  \(.url)\n  \(.description)\n"'
