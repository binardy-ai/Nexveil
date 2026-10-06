#!/bin/sh
# Управление клиентами Mieru панели: поднимает и гасит клиентов.
# Использование: mieru.sh sync | up <раздел> | down <раздел> | check <раздел>
. /usr/lib/xraypanel/lib.sh 2>/dev/null

case "$1" in
	sync)
		mieru_sync
		;;
	up)
		[ -n "$2" ] || { echo "не указан раздел сервера"; exit 1; }
		mieru_up "$2"
		;;
	down)
		[ -n "$2" ] || { echo "не указан раздел сервера"; exit 1; }
		mieru_down "$2"
		;;
	stop-all)
		mieru_stop_all
		;;
	*)
		echo "использование: mieru.sh sync | up <раздел> | down <раздел> | stop-all"
		exit 1
		;;
esac
