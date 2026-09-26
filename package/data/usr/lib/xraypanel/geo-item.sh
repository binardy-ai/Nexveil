#!/bin/sh
# Разбор готовых списков (geosite), которые стоят в наборах панели.
#
# Зачем это нужно. Правило панель проверяет по журналу xray: видит адрес,
# куда ушёл трафик, и решает, какое правило его поймало. Но если в наборе
# стоит готовый список (например TELEGRAM), по одному названию понять нечего:
# нужно знать, какие домены в этот список входят. Тогда лампочка в наборе
# загорается ровно так же, как в правиле, а не «вероятно».
#
# Здесь мы делаем файл доменов для каждого имени, которое реально стоит в
# наборах: /etc/xraypanel/geosite.<ИМЯ>.domains (по строке на домен).
# Разбор идёт по файлам geosite.dat штатными средствами роутера, ничего
# доставлять не нужно.
#
# Запускается в фоне (как «собрать названия списков»): одно имя — несколько
# секунд. Результат кэшируется и пересобирается только если обновился сам
# файл geosite.dat.

STATE="${XRAYPANEL_STATE:-/etc/xraypanel}"
LIB="${XRAYPANEL_LIB:-/usr/lib/xraypanel/lib.sh}"
LOOKUP="${XRAYPANEL_GEO_LIST:-/usr/lib/xraypanel/geo-list.awk}"
LOOKUP_IP="${XRAYPANEL_GEO_IP_LIST:-/usr/lib/xraypanel/geo-ip-list.awk}"
UCI_APP="${XRAYPANEL_UCI_APP:-xraypanel}"

[ -f "$LIB" ] && . "$LIB"
mkdir -p "$STATE" 2>/dev/null

# без разборщика делать нечего — тихо выходим, панель покажет «вероятно»
[ -f "$LOOKUP" ] || exit 0

# если разбор уже идёт — второй не запускаем
RUN="$STATE/geo-item.running"
if [ -f "$RUN" ]; then
	# признак «разбор идёт» мог остаться от оборванного запуска (перезагрузка,
	# нехватка памяти) — тогда снимаем его сами, иначе разбор больше никогда
	# не запустится
	if [ -n "$(find "$RUN" -mmin +10 2>/dev/null)" ]; then
		rm -f "$RUN" 2>/dev/null
	else
		exit 0
	fi
fi
touch "$RUN" 2>/dev/null
trap 'rm -f "$RUN" 2>/dev/null' EXIT

say() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*"; }

# какие файлы со списками есть на роутере (из библиотеки панели)
if ! type geo_files >/dev/null 2>&1; then
	geo_files() {
		for _d in ${XRAYPANEL_GEO_DIR:-} /usr/share/xray /usr/share/v2ray /etc/xray; do
			[ -n "$_d" ] || continue
			for _n in geosite.dat dlc.dat iran.dat; do
				[ -f "$_d/$_n" ] && printf '%s\t%s\n' "$_d/$_n" "$_n"
			done
		done
	}
fi
if ! type file_size >/dev/null 2>&1; then
	file_size() {
		_s=$(ls -l "$1" 2>/dev/null | awk '{ print $5 }')
		case "$_s" in ''|*[!0-9]*) _s=0 ;; esac
		printf '%s' "$_s"
	}
fi

# отпечаток файлов со списками: если geosite.dat обновили, соберём заново
if type geo_signature >/dev/null 2>&1; then
	SIG=$(geo_signature 2>/dev/null)
else
	SIG=""
	for _pair in $(geo_files geosite 2>/dev/null | tr '\t' ':'); do
		_f=${_pair%%:*}
		SIG="$SIG${_f}:$(file_size "$_f"):$(date -r "$_f" +%s 2>/dev/null);"
	done
fi

# Готовые списки, которые реально стоят в правилах и наборах панели:
# «тип<TAB>имя». Берём из условий правил (там же учтены записи наборов), а если
# библиотеки под рукой нет — перебираем записи наборов сами.
conditions() {
	if type rule_conditions >/dev/null 2>&1; then
		rule_conditions 2>/dev/null | awk -F'\t' 'NF >= 4 && $4 != "" { print $3 "\t" $4 }'
		return 0
	fi
	for _i in $(uci -q show "$UCI_APP" 2>/dev/null | sed -n "s/^$UCI_APP\.\([^.]*\)=item\$/\1/p"); do
		printf '%s\t%s\n' "$(uci -q get "$UCI_APP.$_i.type" 2>/dev/null)" "$(uci -q get "$UCI_APP.$_i.value" 2>/dev/null)"
	done
}

names() { # $1 = тип списка (geosite|geoip): печатает имена
	conditions | awk -F'\t' -v t="$1" '$1 == t && $2 != "" { print $2 }' | LC_ALL=C sort -u
}

_done=0
_seen=""
for _v in $(names geosite); do
	case " $_seen " in *" g:$_v "*) continue ;; esac
	_seen="$_seen g:$_v"
	_f="$STATE/geosite.$_v.domains"
	_sigf="$STATE/geosite.$_v.sig"
	_old=$(cat "$_sigf" 2>/dev/null)
	# уже разобрано и файлы со списками с тех пор не менялись
	if [ -f "$_f" ] && [ -n "$SIG" ] && [ "$_old" = "$SIG" ]; then continue; fi
	say "разбираю список $_v"
	_nl=$(printf '%s' "$_v" | tr 'A-Z' 'a-z')
	_new="$STATE/geosite.$_v.domains.new"
	: > "$_new"
	for _pair in $(geo_files geosite | tr '\t' ':'); do
		_fp=${_pair%%:*}
		[ -f "$_fp" ] || continue
		LC_ALL=C awk -v name="$_nl" -v lim=200000 -f "$LOOKUP" "$_fp" 2>/dev/null \
			| grep -v '^#всего' | cut -f1 >> "$_new"
	done
	# только домены, без повторов и пустых строк
	LC_ALL=C sort -u "$_new" 2>/dev/null | awk 'NF' > "$_new.sorted" 2>/dev/null
	if [ -s "$_new.sorted" ]; then
		mv -f "$_new.sorted" "$_f" 2>/dev/null
	fi
	rm -f "$_new" "$_new.sorted" 2>/dev/null
	printf '%s' "$SIG" > "$_sigf" 2>/dev/null
	say "  готово: доменов $(grep -c . "$_f" 2>/dev/null)"
	_done=$((_done + 1))
done

# то же для списков адресов (geoip): из них панель понимает правила вида
# «geoip:ru» — по адресу, а не «по выходу»
if [ -f "$LOOKUP_IP" ]; then
	for _v in $(names geoip); do
		case " $_seen " in *" i:$_v "*) continue ;; esac
		_seen="$_seen i:$_v"
		_f="$STATE/geoip.$_v.cidr"
		_sigf="$STATE/geoip.$_v.sig"
		_old=$(cat "$_sigf" 2>/dev/null)
		if [ -f "$_f" ] && [ -n "$SIG" ] && [ "$_old" = "$SIG" ]; then continue; fi
		say "разбираю адреса списка $_v"
		_nl=$(printf '%s' "$_v" | tr 'A-Z' 'a-z')
		_new="$STATE/geoip.$_v.cidr.new"
		: > "$_new"
		for _pair in $(geo_files geoip | tr '\t' ':'); do
			_fp=${_pair%%:*}
			[ -f "$_fp" ] || continue
			LC_ALL=C awk -v name="$_nl" -v lim=200000 -f "$LOOKUP_IP" "$_fp" 2>/dev/null \
				| grep -v '^#всего' | cut -f1 >> "$_new"
		done
		LC_ALL=C sort -u "$_new" 2>/dev/null | awk 'NF' > "$_new.sorted" 2>/dev/null
		if [ -s "$_new.sorted" ]; then
			mv -f "$_new.sorted" "$_f" 2>/dev/null
		fi
		rm -f "$_new" "$_new.sorted" 2>/dev/null
		printf '%s' "$SIG" > "$_sigf" 2>/dev/null
		say "  готово: диапазонов $(grep -c . "$_f" 2>/dev/null)"
		_done=$((_done + 1))
	done
fi

[ "$_done" = 0 ] && say "всё уже разобрано — ничего не делаю"
exit 0
