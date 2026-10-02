#!/bin/sh
# Установка клиента AmneziaWG на роутер: userspace amneziawg-go + amneziawg-tools.
# Модуль ядра (kmod-amneziawg) не нужен: клиент работает в пользовательском
# пространстве, ему хватает /dev/net/tun (пакет kmod-tun).
#
# Порядок действий:
#   1) если рядом уже лежат готовые пакеты (их можно закинуть вручную) — ставим их;
#   2) иначе скачиваем подходящий набор с GitHub (релизы samara1531/awg2) —
#      под нашу версию OpenWrt, цель и архитектуру;
#   3) доставляем kmod-tun, если нет /dev/net/tun.
# Результат пишется в журнал: его видно на странице «Серверы».
#
# Переменная AWG_INSTALL_DRY=1 — только скачать и распаковать, ничего не ставить
# (нужно для проверки на живом роутере).
. /usr/lib/xraypanel/lib.sh 2>/dev/null

DRY="${AWG_INSTALL_DRY:-0}"
WORK="/tmp/amneziawg-install"

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }

pkg_ok() { # $1 = файл, $2 = имя пакета в системе
	[ -e "$2" ]
}

already_installed() {
	[ -x /usr/bin/amneziawg-go ] && [ -x /usr/bin/awg ]
}

finish_check() {
	if already_installed; then
		log "готово: клиент AmneziaWG установлен"
		[ -e /dev/net/tun ] && log "интерфейс TUN на месте (/dev/net/tun)" \
			|| log "ВНИМАНИЕ: нет /dev/net/tun — нужен пакет kmod-tun"
		return 0
	fi
	log "клиент не установился — смотрите строки выше"
	return 1
}

# --- 1. готовые файлы рядом --------------------------------------------------
localfiles() {
	for _d in "$STATE_DIR/versions" /tmp; do
		for _f in "$_d"/amneziawg-go*.ipk "$_d"/amneziawg-go*.apk \
				"$_d"/amneziawg-tools*.ipk "$_d"/amneziawg-tools*.apk \
				"$_d"/kmod-amneziawg*.ipk "$_d"/kmod-amneziawg*.apk; do
			[ -f "$_f" ] && printf '%s\n' "$_f"
		done
	done
}

install_local() {
	_any=0
	for _f in $(localfiles); do
		_any=1
		if [ "$DRY" = 1 ]; then
			log "(проверка) нашёл готовый файл: $(basename "$_f")"
			continue
		fi
		_out=$(pkg_add_file "$_f" 2>&1)
		log "$(basename "$_f"): $(printf '%s' "$_out" | tail -1)"
	done
	[ "$_any" = 1 ]
}

# --- 2. скачивание с GitHub --------------------------------------------------
pick_release() { # $1 = версия системы (23.05.4) -> тег сборки (23.05.6)
	_series="${1%.*}"
	_api="https://api.github.com/repos/samara1531/awg2/releases?per_page=100"
	_json="$WORK/releases.json"
	mkdir -p "$WORK"
	if command -v wget >/dev/null 2>&1; then
		wget -q -T 20 -O "$_json" "$_api" 2>/dev/null
	else
		curl -fsS --max-time 30 -o "$_json" "$_api" 2>/dev/null
	fi
	[ -s "$_json" ] || { log "не смог получить список сборок с GitHub"; return 1; }
	# свежие релизы идут первыми; берём первый подходящий по серии
	grep -o '"tag_name": *"[^"]*"' "$_json" | sed 's/.*: *"//; s/"$//' | \
		grep -v "_v3" | grep -F "${_series}." | head -1
}

asset_url() { # $1 = тег, $2 = цель (x86-64), $3 = архитектура (x86_64)
	_api="https://api.github.com/repos/samara1531/awg2/releases/tags/$1"
	_json="$WORK/release.json"
	if command -v wget >/dev/null 2>&1; then
		wget -q -T 20 -O "$_json" "$_api" 2>/dev/null
	else
		curl -fsS --max-time 30 -o "$_json" "$_api" 2>/dev/null
	fi
	[ -s "$_json" ] || return 1
	grep -o '"browser_download_url": *"[^"]*"' "$_json" | sed 's/.*: *"//; s/"$//' | \
		grep -F -e "-$2-$3.zip" | head -1
}

ensure_unzip() {
	command -v unzip >/dev/null 2>&1 && return 0
	log "нет unzip — ставлю пакет unzip"
	# unzip — это не клиент, а инструмент для распаковки: в режиме проверки
	# тоже ставим его, иначе весь путь скачивания не проверить
	pkg_update >/dev/null 2>&1
	_out=$(pkg_add unzip 2>&1)
	log "unzip: $(printf '%s' "$_out" | tail -1)"
	command -v unzip >/dev/null 2>&1
}

download_and_install() {
	[ -f /etc/openwrt_release ] || { log "не нашёл /etc/openwrt_release"; return 1; }
	. /etc/openwrt_release
	_rel="$DISTRIB_RELEASE"
	_tgt=$(printf '%s' "$DISTRIB_TARGET" | tr '/' '-')
	_arch="$DISTRIB_ARCH"
	log "система: $DISTRIB_ID $DISTRIB_RELEASE, цель $DISTRIB_TARGET, архитектура $DISTRIB_ARCH"
	_tag=$(pick_release "$_rel") || return 1
	[ -n "$_tag" ] || { log "нет сборки клиента под $DISTRIB_ID $_rel (серия ${_rel%.*})"; return 1; }
	log "нашёл сборку клиента: $_tag"
	_url=$(asset_url "$_tag" "$_tgt" "$_arch") || return 1
	[ -n "$_url" ] || { log "в сборке $_tag нет набора для $_tgt/$_arch"; return 1; }
	log "скачиваю: $(basename "$_url")"
	_zip="$WORK/client.zip"
	mkdir -p "$WORK"
	if command -v wget >/dev/null 2>&1; then
		wget -q -T 30 -O "$_zip" "$_url" || { log "не скачался архив"; return 1; }
	else
		curl -fsS --max-time 120 -o "$_zip" "$_url" || { log "не скачался архив"; return 1; }
	fi
	[ -s "$_zip" ] || { log "архив пустой"; return 1; }
	ensure_unzip || { log "без unzip распаковать архив нельзя"; return 1; }
	rm -rf "$WORK/unpacked"
	mkdir -p "$WORK/unpacked"
	unzip -o -q "$_zip" -d "$WORK/unpacked" 2>/dev/null || { log "не смог распаковать архив"; return 1; }
	_files=$(find "$WORK/unpacked" -type f \( -name 'amneziawg-go*' -o -name 'amneziawg-tools*' \) | sort)
	[ -n "$_files" ] || { log "в архиве нет пакетов клиента"; return 1; }
	for _f in $_files; do
		case "$_f" in
			*.ipk|*.apk) ;;
			*) continue ;;
		esac
		if [ "$DRY" = 1 ]; then
			log "(проверка) поставил бы: $(basename "$_f")"
			continue
		fi
		_out=$(pkg_add_file "$_f" 2>&1)
		log "$(basename "$_f"): $(printf '%s' "$_out" | tail -1)"
	done
	return 0
}

# --- 3. kmod-tun -------------------------------------------------------------
ensure_tun() {
	[ -e /dev/net/tun ] && return 0
	log "нет /dev/net/tun — ставлю kmod-tun"
	[ "$DRY" = 1 ] && { log "(проверка) kmod-tun не ставлю"; return 1; }
	_out=$(pkg_add kmod-tun 2>&1)
	log "kmod-tun: $(printf '%s' "$_out" | tail -1)"
	[ -e /dev/net/tun ]
}

# --- ход установки -----------------------------------------------------------
log "=== установка клиента AmneziaWG ($(date '+%d.%m.%Y %H:%M')) ==="
if already_installed && [ "$DRY" != 1 ]; then
	log "клиент уже установлен — ничего не делаю"
	ensure_tun
	finish_check
	exit $?
fi
[ "$DRY" = 1 ] && log "режим проверки: ничего не устанавливаю, только скачиваю и распаковываю"

if install_local; then
	ensure_tun
	finish_check
	exit $?
fi

log "готовых файлов рядом нет — беру набор с GitHub"
download_and_install || { log "установка с GitHub не удалась"; exit 1; }
ensure_tun
finish_check
exit $?
