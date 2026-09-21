#!/bin/sh
# Периодическое обновление подписок (запускается из cron, если включено).

[ -f /usr/lib/xraypanel/lib.sh ] && . /usr/lib/xraypanel/lib.sh
[ -f "$STATE_DIR/sub.lock" ] && exit 0
: > "$STATE_DIR/sub.lock" 2>/dev/null
sub_update_all
rm -f "$STATE_DIR/sub.lock" 2>/dev/null
