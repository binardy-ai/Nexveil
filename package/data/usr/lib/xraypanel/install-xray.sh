#!/bin/sh
# Доставить xray, если его на роутере нет, и подготовить конфиг панели.
# Запускается установщиком пакета в фоне (после того как opkg освободит
# блокировку) и при первом применении конфига из панели.

[ -f /usr/lib/xraypanel/lib.sh ] && . /usr/lib/xraypanel/lib.sh
[ -z "$(type xray_present 2>/dev/null)" ] && . /tmp/xptest/lib.sh 2>/dev/null

STATE="${XRAYPANEL_STATE:-/etc/xraypanel}"
LOG="$STATE/install.log"
mkdir -p "$STATE" 2>/dev/null

{
	echo "$(date '+%Y-%m-%d %H:%M:%S') проверяю, есть ли xray"
	if xray_present; then
		echo "xray уже установлен: $(xray_bin) — ничего не ставлю"
	else
		# ждём, пока завершится текущая установка пакета (opkg или apk держит
		# блокировку — на новых системах пакетный менеджер уже apk)
		_i=0
		while [ "$_i" -lt 90 ]; do
			pgrep -f "opkg install" >/dev/null 2>&1 || pgrep -f "apk add" >/dev/null 2>&1 ||
				pgrep -x opkg >/dev/null 2>&1 || pgrep -x apk >/dev/null 2>&1 || break
			_i=$((_i + 1))
			sleep 2
		done
		xray_install
	fi
	if xray_present; then
		# xray может быть уже запущен другой программой со своим конфигом:
		# в этом случае ничего не перезаписываем сами, только сообщаем.
		_conf=$(xray_config)
		if [ -f "$_conf" ] && ! grep -q '"local-access"' "$_conf" 2>/dev/null; then
			if pgrep -x xray >/dev/null 2>&1 || ps w 2>/dev/null | grep -q "[x]ray run"; then
				echo "xray уже запущен с конфигом другой программы — панель его не трогает."
				echo "Чтобы перейти на панель: откройте её, добавьте свои серверы и нажмите «Применить конфиг»."
				echo "Прежний конфиг перед этим сохранится рядом как .bak-<дата>."
				exit 0
			fi
		fi
		svc_enable
		config_dir_clean
		config_backup_foreign
		apply_config
		if svc_restart; then
			echo "$(date '+%Y-%m-%d %H:%M:%S') xray запущен"
		else
			echo "$(date '+%Y-%m-%d %H:%M:%S') xray не поднялся — откройте панель и посмотрите «Статус»"
		fi
	else
		echo "$(date '+%Y-%m-%d %H:%M:%S') xray поставить не удалось — поставьте вручную: $(pkg_cmd update) && $(pkg_cmd install xray-core)"
	fi
} >>"$LOG" 2>&1
