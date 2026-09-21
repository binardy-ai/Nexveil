#!/bin/sh
# Сбор названий готовых списков из geoip.dat / geosite.dat.
#
# Панель показывает эти названия в выпадающем списке, чтобы не набирать
# их руками (geosite:ru, geoip:private и так далее). Разбор идёт по байтам
# штатными средствами busybox — ничего доставлять не нужно.
#
# Результат: /etc/xraypanel/geo-tags.tsv, строки вида «geosite<TAB>ru».

STATE="${XRAYPANEL_STATE:-/etc/xraypanel}"
LIB="${XRAYPANEL_LIB:-/usr/lib/xraypanel/lib.sh}"
PARSER="${XRAYPANEL_GEO_PARSER:-/usr/lib/xraypanel/geo-parse.awk}"
PARSER_BYTES="${XRAYPANEL_GEO_PARSER_BYTES:-/usr/lib/xraypanel/geo-parse-bytes.awk}"

# Подсказки из библиотеки панели (какие файлы есть, как они называются).
# Если библиотеки нет — обходимся своим маленьким списком папок, чтобы сбор
# всё равно работал.
[ -f "$LIB" ] && . "$LIB"
if ! type geo_dirs >/dev/null 2>&1; then
	geo_dirs() {
		printf '%s\n' "$XRAYPANEL_GEO_DIR" /usr/share/xray /usr/share/v2ray /etc/xray
	}
fi
mkdir -p "$STATE" 2>/dev/null

OUT="$STATE/geo-tags.tsv"
TMP="$STATE/geo-tags.tsv.new"
RUN="$STATE/geo-tags.running"
REPORT="$STATE/geo-tags.files"
SIGN="$STATE/geo-tags.sig"

# если разбор уже идёт — второй не запускаем
if [ -f "$RUN" ]; then
	echo "$(date '+%Y-%m-%d %H:%M:%S') сбор уже идёт — выхожу"
	exit 0
fi
touch "$RUN"

# байты файла числами: обычно это od, но если его в сборке нет — hexdump
geo_bytes() {
	if command -v od >/dev/null 2>&1; then
		od -An -v -tu1 "$1" 2>/dev/null
	elif command -v hexdump >/dev/null 2>&1; then
		hexdump -v -e '1/1 "%u "' "$1" 2>/dev/null
	fi
}

: > "$TMP"
: > "$REPORT"

add_file() { # $1 вид (geosite|geoip), $2 файл
	[ -f "$2" ] || return 0
	echo "$(date '+%Y-%m-%d %H:%M:%S') разбираю $2"
	_part="$STATE/geo-tags.part"
	# основной способ: читаем файл напрямую, память при этом не растёт
	LC_ALL=C awk -f "$PARSER" "$2" 2>/dev/null | LC_ALL=C sort -u > "$_part"
	_cnt=$(wc -l < "$_part" 2>/dev/null)
	case "$_cnt" in ''|*[!0-9]*) _cnt=0 ;; esac
	# если напрямую ничего не вышло (необычная сборка awk) — запасной способ
	# через od/hexdump, он тяжелее по памяти, поэтому только как запасной
	if [ "$_cnt" = 0 ]; then
		echo "$(date '+%Y-%m-%d %H:%M:%S')   прямой разбор не сработал, пробую через od"
		geo_bytes "$2" | LC_ALL=C awk -f "$PARSER_BYTES" | LC_ALL=C sort -u > "$_part" 2>/dev/null
		_cnt=$(wc -l < "$_part" 2>/dev/null)
		case "$_cnt" in ''|*[!0-9]*) _cnt=0 ;; esac
	fi
	if [ "$_cnt" -gt 0 ]; then
		LC_ALL=C awk -F'\t' -v k="$1" '{ print k "\t" $0 }' "$_part" >> "$TMP"
	fi
	printf '%s\t%s\t%s\n' "$2" "$1" "$_cnt" >> "$REPORT"
	echo "$(date '+%Y-%m-%d %H:%M:%S')   названий из файла: $_cnt"
	rm -f "$_part"
}

for _d in $(geo_dirs); do
	for _n in geosite.dat dlc.dat iran.dat; do
		[ -f "$_d/$_n" ] && add_file geosite "$_d/$_n"
	done
	for _n in geoip.dat geoip_RU.dat geoip_IR.dat geoip_CN.dat; do
		[ -f "$_d/$_n" ] && add_file geoip "$_d/$_n"
	done
done

_n=$(LC_ALL=C sort -u "$TMP" 2>/dev/null | wc -l)
if [ "${_n:-0}" -gt 0 ]; then
	LC_ALL=C sort -u "$TMP" > "$TMP.sorted" 2>/dev/null && mv "$TMP.sorted" "$OUT"
	geo_signature > "$SIGN" 2>/dev/null
	echo "$(date '+%Y-%m-%d %H:%M:%S') готово: названий $((_n))"
else
	echo "$(date '+%Y-%m-%d %H:%M:%S') ничего не нашлось — проверьте, что файлы со списками на месте"
fi

rm -f "$TMP" "$TMP.sorted" "$RUN"
