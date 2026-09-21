#!/bin/sh
# Снимок статистики по выходам: нужен, чтобы показать, сколько трафика прошло
# через каждый сервер (и напрямую) и как оно переключалось между серверами.
# Запускается из cron каждые 5 минут.

STATE="${XRAYPANEL_STATE:-/etc/xraypanel}"
. /usr/lib/xraypanel/lib.sh 2>/dev/null
mkdir -p "$STATE" 2>/dev/null

H="$STATE/exits-history.tsv"
_now=$(date +%s 2>/dev/null)
[ -n "$_now" ] || exit 0

# какой выход работал в этот момент (по журналу) и сколько байт накопилось
_act=$(active_server_now 2>/dev/null); _act=${_act%%	*}
_pay=$(exit_traffic 2>/dev/null | awk -F'\t' '{ printf "%s=%s.%s;", $1, $2, $3 }')
[ -n "$_pay" ] || exit 0

printf '%s\t%s\t%s\n' "$_now" "$_act" "$_pay" >> "$H" 2>/dev/null
# держим примерно сутки (288 записей по 5 минут) с небольшим запасом
tail -n 400 "$H" > "$H.new" 2>/dev/null && mv "$H.new" "$H" 2>/dev/null
exit 0
