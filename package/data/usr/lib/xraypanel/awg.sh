#!/bin/sh
# Управление AmneziaWG-клиентами панели: поднимает и гасит интерфейсы.
# Использование: awg.sh sync | up <раздел> | down <раздел> | check <раздел>
# Вызывается панелью при сохранении сервера и автозапуском после перезагрузки.
. /usr/lib/xraypanel/lib.sh 2>/dev/null

case "$1" in
	sync)
		awg_sync
		;;
	up)
		[ -n "$2" ] || { echo "не указан раздел сервера"; exit 1; }
		awg_up "$2"
		;;
	down)
		[ -n "$2" ] || { echo "не указан раздел сервера"; exit 1; }
		awg_down "$2"
		;;
	stop-all)
		awg_stop_all
		;;
	check)
		[ -n "$2" ] || { echo "не указан раздел сервера"; exit 1; }
		awg_check "$2"
		;;
	*)
		echo "использование: awg.sh sync | up <раздел> | down <раздел> | stop-all | check <раздел>"
		exit 1
		;;
esac
