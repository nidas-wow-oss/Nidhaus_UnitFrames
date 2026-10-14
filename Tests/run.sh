#!/bin/sh
# =========================================================
# Corre todas las pruebas del addon.
#
#   ./Tests/run.sh              desde la raiz del repo
#   ./Tests/run.sh /otra/ruta   contra otra copia del addon
#
# Hace falta lua5.1 (el cliente de WoW usa Lua 5.1):
#   apt install lua5.1      /     brew install lua@5.1
#
# Devuelve 0 si pasa todo, 1 si algo falla: sirve tal cual para CI.
# =========================================================
ROOT=${1:-$(dirname "$0")/..}
LUA=${LUA:-lua5.1}
command -v "$LUA" >/dev/null 2>&1 || { echo "falta $LUA"; exit 2; }

fail=0
total_p=0
total_f=0

for t in "$(dirname "$0")"/t_*.lua; do
    name=$(basename "$t" .lua)
    out=$("$LUA" "$t" "$ROOT" 2>&1)
    line=$(printf '%s\n' "$out" | grep -E '^PASS [0-9]+  FAIL [0-9]+$' | tail -1)
    p=$(printf '%s' "$line" | awk '{print $2}')
    f=$(printf '%s' "$line" | awk '{print $4}')
    if [ -z "$line" ]; then
        printf '  %-26s ERROR\n' "$name"
        printf '%s\n' "$out" | sed 's/^/      /'
        fail=1
        continue
    fi
    total_p=$((total_p + p))
    total_f=$((total_f + f))
    if [ "$f" -gt 0 ]; then
        printf '  %-26s %s pasan, %s FALLAN\n' "$name" "$p" "$f"
        printf '%s\n' "$out" | grep '^FAIL:' | sed 's/^/      /'
        fail=1
    else
        printf '  %-26s %s pasan\n' "$name" "$p"
    fi
done

echo
echo "TOTAL: $total_p pasan, $total_f fallan"
exit $fail
