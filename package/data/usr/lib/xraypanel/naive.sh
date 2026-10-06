#!/bin/sh
# Управление клиентами NaiveProxy панели: поднимает и гасит клиентов.
# Использование: naive.sh sync | up <раздел> | down <раздел> | stop-all
. /usr/lib/xraypanel/lib.sh 2>/dev/null

case "$1" in
	sync)
		naive_sync
		;;
	up)
		[ -n "$2" ] || { echo "не указан раздел сервера"; exit 1; }
		naive_up "$2"
		;;
	down)
		[ -n "$2" ] || { echo "не указан раздел сервера"; exit 1; }
		naive_down "$2"
		;;
	stop-all)
		naive_stop_all
		;;
	*)
		echo "использование: naive.sh sync | up <раздел> | down <раздел> | stop-all"
		exit 1
		;;
esac
