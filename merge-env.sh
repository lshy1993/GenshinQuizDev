#!/bin/sh
# 把 .env.example 中缺失的 key 补进实际 .env，不覆盖已有值。
#
# 用法：
#   ./merge-env.sh                  # .env.example -> .env，保留 example 默认值
#   ./merge-env.sh .env.example .env local   # 本地开发安全值
#
# 本地模式会把以下 key 设为空：
#   SESSION_COOKIE_DOMAIN  （localhost 不能使用 .moelink.site）
#   SSO_CLIENTS
set -eu

EXAMPLE="${1:-.env.example}"
TARGET="${2:-.env}"
MODE="${3:-keep}"

[ -f "$EXAMPLE" ] || { echo "missing $EXAMPLE" >&2; exit 1; }
[ -f "$TARGET" ] || { echo "missing $TARGET" >&2; exit 1; }

STAMP=$(date +%Y%m%d%H%M%S)
BACKUP="${TARGET}.bak.${STAMP}"
cp "$TARGET" "$BACKUP"
echo "backup: $BACKUP"

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
added=0

while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
        ''|\#*) continue ;;
    esac
    key=${line%%=*}
    case "$key" in
        ''|*[!A-Za-z0-9_]*) continue ;;
    esac

    if grep -q "^${key}=" "$TARGET"; then
        continue
    fi

    value=${line#*=}
    if [ "$MODE" = "local" ]; then
        case "$key" in
            SESSION_COOKIE_DOMAIN|SSO_CLIENTS) value="" ;;
        esac
    fi

    printf '%s=%s\n' "$key" "$value" >> "$TMP"
    added=$((added + 1))
    echo "add: $key"
done < "$EXAMPLE"

if [ "$added" -eq 0 ]; then
    echo "nothing to add; $TARGET already contains all example keys"
    exit 0
fi

{
    printf '\n# added from %s by merge-env.sh on %s\n' "$EXAMPLE" "$(date '+%Y-%m-%d %H:%M:%S')"
    cat "$TMP"
} >> "$TARGET"

echo "done: added $added key(s)"
