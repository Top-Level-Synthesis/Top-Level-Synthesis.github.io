#!/usr/bin/env bash
# Writes live.json: for each demo name, true only if the /go link is live, the session holds a board that is online,
# and the board app answers stats.json with 200. Uses only the public /go link and the read-only share cookie it sets.
set -uo pipefail
BASE=https://topls-1x.nrp-nautilus.io
OUT=${1:-live.json}
check() {
  local n=$1 jar; jar=$(mktemp)
  local final sid bv vp code
  final=$(curl -s -m 20 -c "$jar" -b "$jar" -L -o /dev/null -w '%{url_effective}' "$BASE/go/$n" || true)
  sid=$(printf '%s' "$final" | grep -o 'session=[0-9a-f]*' | cut -d= -f2)
  [ -n "$sid" ] || { rm -f "$jar"; echo false; return; }
  bv=$(curl -s -m 20 -b "$jar" "$BASE/session/$sid/board-view" || true)
  vp=$(printf '%s' "$bv" | python3 -c 'import sys,json
try:
  d=json.load(sys.stdin); print(d.get("view_prefix") or "" if d.get("held") and d.get("online") else "")
except Exception: print("")')
  [ -n "$vp" ] || { rm -f "$jar"; echo false; return; }
  code=$(curl -s -m 20 -o /dev/null -w '%{http_code}' -b "$jar" "$BASE${vp}app/stats.json" || echo 000)
  rm -f "$jar"
  [ "$code" = 200 ] && echo true || echo false
}
d=$(check detect); h=$(check hb)
printf '{"detect":%s,"hb":%s,"checked_at":"%s"}\n' "$d" "$h" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$OUT"
cat "$OUT"
