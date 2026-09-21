#!/bin/sh
# Обновление файлов со списками (geosite.dat и geoip.dat) из интернета.
# Как в PassWall: файлы берутся из релизов на GitHub, старые сохраняются рядом
# как .bak, после обновления пересобираются названия списков и перезапускается
# xray (он читает эти файлы при запуске).
#
# Запуск: sh geo-update.sh [loyalsoldier|v2fly|russia]

STATE="${XRAYPANEL_STATE:-/etc/xraypanel}"
LIB="${XRAYPANEL_LIB:-/usr/lib/xraypanel/lib.sh}"
PARSER="${XRAYPANEL_GEO_PARSER:-/usr/lib/xraypanel/geo-parse.awk}"
GEO_TAGS="${XRAYPANEL_GEO_TAGS:-/usr/lib/xraypanel/geo-tags.sh}"
SRC="${1:-loyalsoldier}"

[ -f "$LIB" ] && . "$LIB"
if ! type geo_dirs >/dev/null 2>&1; then
	geo_dirs() { printf '%s\n' "${XRAYPANEL_GEO_DIR:-/usr/share/xray}" /usr/share/xray /usr/share/v2ray; }
fi
mkdir -p "$STATE" 2>/dev/null
LOG="$STATE/geo-update.log"
RUN="$STATE/geo-update.running"
trap 'rm -f "$RUN" 2>/dev/null' EXIT INT TERM
touch "$RUN" 2>/dev/null

say() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

case "$SRC" in
	loyalsoldier)
		NAME="Loyalsoldier (как в PassWall)"
		URL_GEOIP="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
		URL_GEOSITE="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
		;;
	v2fly)
		NAME="v2fly (официальные)"
		URL_GEOIP="https://github.com/v2fly/geoip/releases/latest/download/geoip.dat"
		URL_GEOSITE="https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat"
		;;
	russia)
		NAME="runetfreedom (российские списки, файлы большие)"
		URL_GEOIP="https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geoip.dat"
		URL_GEOSITE="https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geosite.dat"
		;;
	*)
		say "неизвестный источник «$SRC» — выхожу"
		exit 1
		;;
esac

say "обновляю списки: $NAME"

# чем качать: на OpenWrt обычно wget из busybox
dl() { # $1 ссылка, $2 куда
	if command -v wget >/dev/null 2>&1; then
		wget -q -T 60 -O "$2" "$1" && return 0
		rm -f "$2"
	fi
	if command -v curl >/dev/null 2>&1; then
		curl -sSL --max-time 180 -o "$2" "$1" && return 0
		rm -f "$2"
	fi
	if command -v uclient-fetch >/dev/null 2>&1; then
		uclient-fetch -q -O "$2" "$1" && return 0
		rm -f "$2"
	fi
	return 1
}

# куда класть файл: рядом с уже существующим (по ссылке — в настоящий файл),
# иначе в первую подходящую папку
target_for() { # $1 = имя файла (geosite.dat|geoip.dat)
	_what="$1"
	if [ "$_what" = "geosite.dat" ]; then
		_list=$(geo_files geosite 2>/dev/null | head -1 | cut -f1)
	else
		_list=$(geo_files geoip 2>/dev/null | head -1 | cut -f1)
	fi
	if [ -n "$_list" ]; then
		_real=$(readlink -f "$_list" 2>/dev/null)
		[ -n "$_real" ] || _real="$_list"
		printf '%s' "$_real"
		return 0
	fi
	for _d in $(geo_dirs); do
		[ -d "$_d" ] || continue
		printf '%s/%s' "$_d" "$_what"
		return 0
	done
	printf '/usr/share/xray/%s' "$_what"
}

# скачиваем, проверяем и ставим на место
install_file() { # $1 ссылка, $2 имя файла, $3 как называть в журнале
	_target=$(target_for "$2")
	_tmp="$STATE/$2.new"
	rm -f "$_tmp" 2>/dev/null
	say "  качаю $3 ($2)…"
	if ! dl "$1" "$_tmp"; then
		say "  не удалось скачать $3 — оставляю прежний файл"
		rm -f "$_tmp" 2>/dev/null
		return 1
	fi
	_size=$(wc -c < "$_tmp" 2>/dev/null)
	case "$_size" in ''|*[!0-9]*) _size=0 ;; esac
	if [ "$_size" -lt 100000 ]; then
		say "  файл подозрительно маленький ($_size байт) — не ставлю"
		rm -f "$_tmp" 2>/dev/null
		return 1
	fi
	# проверяем, что это действительно файл со списками
	_cnt=$(LC_ALL=C awk -f "$PARSER" "$_tmp" 2>/dev/null | LC_ALL=C sort -u | wc -l)
	case "$_cnt" in ''|*[!0-9]*) _cnt=0 ;; esac
	if [ "$_cnt" -lt 20 ]; then
		say "  в файле не нашлось названий списков ($_cnt) — не ставлю"
		rm -f "$_tmp" 2>/dev/null
		return 1
	fi
	mkdir -p "$(dirname "$_target")" 2>/dev/null
	if [ -f "$_target" ]; then
		cp -f "$_target" "$_target.bak-$(date +%Y%m%d-%H%M%S)" 2>/dev/null
	fi
	if mv -f "$_tmp" "$_target" 2>/dev/null; then
		say "  поставлен $2: $(human_bytes "$_size" 2>/dev/null || echo "$_size байт"), названий $_cnt → $_target"
		return 0
	fi
	say "  не смог записать $_target"
	rm -f "$_tmp" 2>/dev/null
	return 1
}

_ok=0
install_file "$URL_GEOSITE" "geosite.dat" "списки доменов" && _ok=1
install_file "$URL_GEOIP" "geoip.dat" "списки адресов" && _ok=1

if [ "$_ok" = 0 ]; then
	say "обновить не удалось — ничего не менял"
	exit 1
fi

# названия списков пересобираем и сбрасываем кэши поиска
say "пересобираю названия списков…"
rm -f "$STATE/geo-tags.tsv" "$STATE/geo-tags.sig" "$STATE/geo-lookup.cache" "$STATE/geo-list.cache" 2>/dev/null
XRAYPANEL_STATE="$STATE" XRAYPANEL_LIB="$LIB" XRAYPANEL_GEO_PARSER="$PARSER" sh "$GEO_TAGS" >>"$LOG" 2>&1

# xray читает эти файлы при запуске — перезапускаем
if type svc_restart >/dev/null 2>&1; then
	if svc_restart >>"$LOG" 2>&1; then
		say "xray перезапущен со свежими списками"
	else
		say "xray не поднялся — проверьте конфиг (файлы на месте, старые сохранены как .bak)"
	fi
fi
say "готово"
exit 0
