#!/bin/sh
# Периодическая проверка узлов (запускается из cron, если включено в панели).
# Качает тестовый адрес через каждый сервер и сохраняет результаты.

[ -f /usr/lib/xraypanel/lib.sh ] && . /usr/lib/xraypanel/lib.sh
[ -f "$STATE_DIR/urltest.lock" ] && exit 0
: > "$STATE_DIR/urltest.lock" 2>/dev/null
url_test_all
rm -f "$STATE_DIR/urltest.lock" 2>/dev/null
