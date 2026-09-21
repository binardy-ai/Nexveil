#!/bin/sh
# Включение прозрачного режима одной операцией:
#   1) применяем конфиг xray (проверка -> бэкап -> запись -> перезапуск);
#   2) только если конфиг применился — ставим правила фаервола.
# Если конфиг не применился, правила НЕ ставим: иначе трафик завернулся бы
# в порт, который никто не слушает, и у клиентов пропал бы интернет.

PATH="${XRAYPANEL_PATH:-/usr/sbin:/usr/bin:/sbin:/bin}"
LIB="${XRAYPANEL_LIB:-/usr/lib/xraypanel/lib.sh}"
TRANSPARENT="${XRAYPANEL_TRANSPARENT:-/usr/lib/xraypanel/transparent.sh}"
STATE="${XRAYPANEL_STATE:-/etc/xraypanel}"
mkdir -p "$STATE" 2>/dev/null

# shellcheck source=/dev/null
. "$LIB" 2>/dev/null

: > "$STATE/apply.log"
if ! apply_and_restart >>"$STATE/apply.log" 2>&1; then
	echo "конфиг xray не применён — правила фаервола не ставлю, интернет не тронут"
	cat "$STATE/apply.log" 2>/dev/null
	printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "ОШИБКА: конфиг xray не применился, правила не поставлены" > "$STATE/transparent.last"
	exit 1
fi

echo "xray перезапущен"
"$TRANSPARENT" on
