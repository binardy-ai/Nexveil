#!/bin/sh
# Выключение прозрачного режима: снимаем правила, потом применяем конфиг без
# перехватчика и перезапускаем xray.

PATH="${XRAYPANEL_PATH:-/usr/sbin:/usr/bin:/sbin:/bin}"
LIB="${XRAYPANEL_LIB:-/usr/lib/xraypanel/lib.sh}"
TRANSPARENT="${XRAYPANEL_TRANSPARENT:-/usr/lib/xraypanel/transparent.sh}"
STATE="${XRAYPANEL_STATE:-/etc/xraypanel}"
mkdir -p "$STATE" 2>/dev/null

"$TRANSPARENT" off

# shellcheck source=/dev/null
. "$LIB" 2>/dev/null
: > "$STATE/apply.log"
apply_config >>"$STATE/apply.log" 2>&1
svc_restart
echo "xray перезапущен без перехватчика"
