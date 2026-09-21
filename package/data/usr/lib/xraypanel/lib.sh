#!/bin/sh
# Ядро панели xraypanel: чтение настроек, генерация конфига xray, применение, откат.
# Только POSIX sh (busybox ash). Без сторонних утилит, кроме стандартных OpenWrt.

UCI_APP="xraypanel"
STATE_DIR="${XRAYPANEL_STATE:-/etc/xraypanel}"
INITD="${XRAYPANEL_INITD:-/etc/init.d}"

cfg() { # cfg ключ [по умолчанию]
	_v=$(uci -q get "$UCI_APP.settings.$1" 2>/dev/null)
	if [ -n "$_v" ]; then printf '%s' "$_v"; else printf '%s' "${2:-}"; fi
}

# --- поиск бинарника xray и службы -------------------------------------------
xray_bin() {
	_b=$(cfg xray_bin "")
	if [ -n "$_b" ] && [ -x "$_b" ]; then printf '%s' "$_b"; return; fi
	for _p in /usr/bin/xray /usr/sbin/xray /usr/share/xray/xray /opt/bin/xray; do
		[ -x "$_p" ] && { printf '%s' "$_p"; return; }
	done
	printf '/usr/bin/xray'
}

xray_service() {
	_s=$(cfg service "xray")
	printf '%s' "$_s"
}

xray_config() {
	printf '%s' "$(cfg config_path "/etc/xray/config.json")"
}

# Тег выхода: панель разбирает списки тегов по пробелам, поэтому пробелы и
# разные символы в теге ломают и конфиг, и саму панель (сервер «не виден»).
# Оставляем только латиницу, цифры, точку, дефис и подчёркивание.
tag_clean() {
	printf '%s' "$1" \
		| sed -e 's/[[:space:]]\{1,\}/-/g' \
			-e 's/а/a/g; s/б/b/g; s/в/v/g; s/г/g/g; s/д/d/g; s/е/e/g; s/ё/e/g; s/ж/zh/g; s/з/z/g; s/и/i/g; s/й/y/g; s/к/k/g; s/л/l/g; s/м/m/g; s/н/n/g; s/о/o/g; s/п/p/g; s/р/r/g; s/с/s/g; s/т/t/g; s/у/u/g; s/ф/f/g; s/х/h/g; s/ц/c/g; s/ч/ch/g; s/ш/sh/g; s/щ/sch/g; s/ъ//g; s/ы/y/g; s/ь//g; s/э/e/g; s/ю/yu/g; s/я/ya/g' \
			-e 's/А/A/g; s/Б/B/g; s/В/V/g; s/Г/G/g; s/Д/D/g; s/Е/E/g; s/Ё/E/g; s/Ж/Zh/g; s/З/Z/g; s/И/I/g; s/Й/Y/g; s/К/K/g; s/Л/L/g; s/М/M/g; s/Н/N/g; s/О/O/g; s/П/P/g; s/Р/R/g; s/С/S/g; s/Т/T/g; s/У/U/g; s/Ф/F/g; s/Х/H/g; s/Ц/C/g; s/Ч/Ch/g; s/Ш/Sh/g; s/Щ/Sch/g; s/Ъ//g; s/Ы/Y/g; s/Ь//g; s/Э/E/g; s/Ю/Yu/g; s/Я/Ya/g' \
		| sed -e 's/[^A-Za-z0-9._-]/-/g' -e 's/-\{1,\}/-/g' -e 's/^[._-]*//' -e 's/[._-]*$//'
}

# Диагностика статистики трафика: видно, отвечает ли API xray и что он вернул
#
# Чужие .json в каталоге конфига: служба xray запускается с -confdir, то есть
# склеивает ВСЕ .json из каталога. Лишний файл (например, старая копия
# config.new.json) продолжает подсовывать серверы и правила, которых в панели
# уже нет. Здесь показываем такие файлы, а по кнопке — убираем их в .bak.
config_extra_json() {
	_conf=$(xray_config)
	_dir=$(dirname "$_conf")
	_base=$(basename "$_conf")
	[ -d "$_dir" ] || return 0
	for _f in "$_dir"/*.json; do
		[ -f "$_f" ] || continue
		_b=$(basename "$_f")
		[ "$_b" = "$_base" ] && continue
		case "$_b" in *.tmp.*.json) continue ;; esac
		printf '%s\n' "$_f"
	done
}

# убрать лишние .json в .bak (с датой), чтобы xray их больше не читал
config_extra_clean() {
	_n=0
	for _f in $(config_extra_json); do
		[ -f "$_f" ] || continue
		mv -f "$_f" "$_f.bak-$(date +%Y%m%d-%H%M%S)" 2>/dev/null && _n=$((_n + 1))
	done
	printf '%s' "$_n"
}

stats_debug() {
	_bin=$(xray_bin)
	_api=$(cfg api_port 62789)
	[ -x "$_bin" ] || { echo "xray не найден: $_bin"; return 0; }
	echo "порт API: $_api"
	_out=$("$_bin" api statsquery --server="127.0.0.1:$_api" -pattern "outbound>>>" 2>&1)
	_rc=$?
	echo "код возврата: $_rc"
	if [ -n "$_out" ]; then
		printf '%s\n' "$_out" | head -c 700
		echo
	else
		echo "(пустой ответ)"
	fi
	echo "разобрано строк со счётчиками: $(outbound_stats 2>/dev/null | wc -l | tr -d ' ')"
	outbound_stats 2>/dev/null | head -10
}

# версия панели: берём из файла, который ставится вместе с пакетом,
# если его нет — из данных пакета в opkg
panel_version() {
	_v=""
	[ -f "$STATE_DIR/version" ] && _v=$(sed -n '1p' "$STATE_DIR/version" 2>/dev/null)
	[ -n "$_v" ] || _v=$(sed -n 's/^Version: //p' /usr/lib/opkg/info/xraypanel.control 2>/dev/null | head -1)
	[ -n "$_v" ] || _v="неизвестна"
	printf '%s' "$_v"
}

# --- пакеты самой панели (.ipk): версия внутри файла, проверка, список ------
# Нужны для смены версии прямо из панели: положить пакет на роутер и нажать
# «поставить». Версию читаем из самого пакета, а не из имени файла.
panel_ipk_version() { # $1 — путь к .ipk: печатает версию (или пусто)
	_t="/tmp/.xpi.$$"
	rm -rf "$_t" 2>/dev/null
	mkdir -p "$_t" 2>/dev/null || return 0
	if tar -xzf "$1" -C "$_t" ./control.tar.gz 2>/dev/null &&
	   tar -xzf "$_t/control.tar.gz" -C "$_t" ./control 2>/dev/null; then
		sed -n 's/^Version: //p' "$_t/control" 2>/dev/null | head -1 | tr -d '\r'
	fi
	rm -rf "$_t" 2>/dev/null
}

panel_ipk_ok() { # $1 — путь: это пакет панели?
	tar tzf "$1" 2>/dev/null | grep -qx '\./debian-binary' || return 1
	_p="$(panel_ipk_version "$1")"
	[ -n "$_p" ] || return 1
	return 0
}

panel_ipk_list() { # «путь<TAB>версия<TAB>байт» по всем найденным пакетам
	for _d in $(cfg panel_ipk_dirs "/tmp /etc/xraypanel/versions"); do
		[ -d "$_d" ] || continue
		for _f in "$_d"/*.ipk; do
			[ -f "$_f" ] || continue
			_v="$(panel_ipk_version "$_f")"
			[ -n "$_v" ] || continue
			printf '%s\t%s\t%s\n' "$_f" "$_v" "$(wc -c <"$_f" 2>/dev/null | tr -d ' ')"
		done
	done
}

panel_ipk_sane() { # $1 — путь: панель внутри пакета вообще запустится?
	# Проверяем то, из-за чего чаще всего «панель не открылась» — синтаксис
	# самой панели. Пакет, у которого панель не проходит sh -n, ставить нельзя:
	# на удалённом роутере это значит потерять доступ к настройкам.
	_t="/tmp/.xps.$$"
	rm -rf "$_t" 2>/dev/null
	mkdir -p "$_t" 2>/dev/null || return 1
	if ! tar -xzf "$1" -C "$_t" 2>/dev/null; then rm -rf "$_t" 2>/dev/null; return 1; fi
	if ! tar -xzf "$_t/data.tar.gz" -C "$_t" 2>/dev/null; then rm -rf "$_t" 2>/dev/null; return 1; fi
	_r=0
	[ -f "$_t/www/cgi-bin/xraypanel" ] || _r=1
	[ -f "$_t/usr/lib/xraypanel/lib.sh" ] || _r=1
	if [ "$_r" = 0 ] && ! sh -n "$_t/www/cgi-bin/xraypanel" 2>/dev/null; then _r=1; fi
	if [ "$_r" = 0 ] && ! sh -n "$_t/usr/lib/xraypanel/lib.sh" 2>/dev/null; then _r=1; fi
	rm -rf "$_t" 2>/dev/null
	return $_r
}

# Сравнение конфига на диске с тем, что собрано из настроек.
# Пустые строки и хвостовые пробелы не учитываются — иначе панель ругалась бы
# на «одинаковые» файлы. $1 — текст собранного конфига.
config_text_matches() { # 0 = совпадает
	_conf=$(xray_config)
	[ -f "$_conf" ] || return 1
	_t="${_conf}.check.$$"
	printf '%s\n' "$1" | sed -e 's/[[:space:]]*$//' -e '/^[[:space:]]*$/d' > "$_t.a" 2>/dev/null
	sed -e 's/[[:space:]]*$//' -e '/^[[:space:]]*$/d' "$_conf" > "$_t.b" 2>/dev/null
	_res=1
	cmp -s "$_t.a" "$_t.b" && _res=0
	rm -f "$_t.a" "$_t.b" 2>/dev/null
	return $_res
}

# Короткий список различий: что есть в файле, а чего нет в настройках, и наоборот.
# $1 — текст собранного конфига, $2 — сколько строк показать.
config_diff_lines() {
	_n=${2:-6}
	_conf=$(xray_config)
	[ -f "$_conf" ] || { echo "файла конфига на роутере нет"; return 0; }
	_t="${_conf}.check.$$"
	printf '%s\n' "$1" | sed -e 's/[[:space:]]*$//' -e '/^[[:space:]]*$/d' > "$_t.a" 2>/dev/null
	sed -e 's/[[:space:]]*$//' -e '/^[[:space:]]*$/d' "$_conf" > "$_t.b" 2>/dev/null
	# сравниваем построчно без опоры на формат вывода diff: он на разных
	# сборках busybox бывает разным, и список различий оставался пустым
	: > "$_t.out" 2>/dev/null
	grep -Fxv -f "$_t.a" "$_t.b" 2>/dev/null |
		sed -e 's/^/в файле, но не в настройках: /' -e 's/^\(.\{0,150\}\).*/\1/' >> "$_t.out" 2>/dev/null
	grep -Fxv -f "$_t.b" "$_t.a" 2>/dev/null |
		sed -e 's/^/в настройках, но не в файле: /' -e 's/^\(.\{0,150\}\).*/\1/' >> "$_t.out" 2>/dev/null
	if [ -s "$_t.out" ]; then
		head -n "$_n" "$_t.out"
	elif ! cmp -s "$_t.a" "$_t.b" 2>/dev/null; then
		# строки те же, но идут в другом порядке (например, поменялся порядок
		# серверов или правил) — так и пишем, чтобы поле не оставалось пустым
		echo "строки те же, но идут в другом порядке — файл на роутере отличается порядком строк"
	fi
	rm -f "$_t.a" "$_t.b" "$_t.out" 2>/dev/null
}

# Быстрая проверка «есть неприменённые изменения»: настройки панели менялись
# позже, чем был записан конфиг. Возвращает 0, если применять есть что.
config_dirty() {
	_conf=$(xray_config)
	[ -f "$_conf" ] || return 0
	_ucif="${XRAYPANEL_CONF_DIR:-/etc/config}/$UCI_APP"
	[ -f "$_ucif" ] || return 1
	[ "$_ucif" -nt "$_conf" ] && return 0
	return 1
}

# Что уже изменено, но ещё не попало в конфиг: панель пишет сюда короткие
# пометки при каждом изменении настроек, а после применения список очищается.
# Так видно не просто «есть изменения», а какие именно.
PENDING_FILE="$STATE_DIR/pending.log"

pending_note() { # $1 = что изменили, простыми словами
	[ -n "$1" ] || return 0
	mkdir -p "$STATE_DIR" 2>/dev/null
	printf '%s\t%s\n' "$(date '+%H:%M' 2>/dev/null)" "$1" >> "$PENDING_FILE" 2>/dev/null
	# длинный список подрезаем, одинаковые пометки не копим
	tail -n 40 "$PENDING_FILE" 2>/dev/null | awk -F'\t' '!seen[$2]++' | tail -n 20 > "$PENDING_FILE.tmp" 2>/dev/null
	mv -f "$PENDING_FILE.tmp" "$PENDING_FILE" 2>/dev/null
	return 0
}

pending_list() { # $1 = сколько последних пометок показать (по умолчанию 5)
	_n=${1:-5}
	[ -f "$PENDING_FILE" ] || return 0
	_all=$(cut -f2- "$PENDING_FILE" 2>/dev/null)
	[ -n "$_all" ] || return 0
	_total=$(printf '%s\n' "$_all" | awk 'NF { n++ } END { print n+0 }')
	# склеиваем простым разделителем: busybox-paste многобайтные не умеет
	_txt=$(printf '%s\n' "$_all" | tail -n "$_n" | awk '{ if (n++) printf "; "; printf "%s", $0 }' 2>/dev/null)
	[ -n "$_txt" ] || return 0
	if [ "$_total" -gt "$_n" ]; then
		_txt="$_txt; и ещё $((_total - _n))"
	fi
	printf '%s' "$_txt"
}

pending_clear() {
	rm -f "$PENDING_FILE" "$PENDING_FILE.tmp" 2>/dev/null
	return 0
}

svc_state() { # running | stopped | absent
	_ss=$(xray_service)
	[ -x "$INITD/$_ss" ] || { printf 'absent'; return; }
	if "$INITD/$_ss" running >/dev/null 2>&1; then printf 'running'; else printf 'stopped'; fi
}

# Служба xray в OpenWrt по умолчанию выключена (в /etc/config/xray стоит
# enabled='0'). Тогда «/etc/init.d/xray restart» ничего не делает, процесса нет
# — и панель пишет «xray не поднялся», хотя и бинарник, и конфиг в порядке.
# Включаем её сами: без работающего xray панель всё равно бесполезна.
svc_enable() {
	_ch=0
	for _s in $(uci -q show xray 2>/dev/null | sed -n "s/^xray\.\([^.]*\)\.enabled='0'\$/\1/p"); do
		uci -q set "xray.$_s.enabled=1" && _ch=1
	done
	if [ "$_ch" = 1 ]; then
		uci -q commit xray >/dev/null 2>&1
		echo "служба xray была выключена в настройках OpenWrt — включил её"
	fi
	# и автозапуск при загрузке роутера
	_ss=$(xray_service)
	if [ -x "$INITD/$_ss" ] && ! "$INITD/$_ss" enabled >/dev/null 2>&1; then
		"$INITD/$_ss" enable >/dev/null 2>&1 && echo "включил автозапуск службы $_ss"
	fi
	return 0
}

# есть ли вообще xray в системе
xray_present() {
	[ -x "$(xray_bin)" ]
}

# пробуем поставить xray из репозитория OpenWrt/ImmortalWrt
xray_install() {
	command -v opkg >/dev/null 2>&1 || { echo "opkg не найден — установите xray вручную"; return 1; }
	echo "ставлю xray из репозитория…"
	opkg update >/dev/null 2>&1
	for _p in xray-core xray; do
		if opkg install "$_p" >/dev/null 2>&1 && xray_present; then
			echo "установлен пакет $_p"
			return 0
		fi
	done
	echo "не удалось поставить xray автоматически — поставьте вручную: opkg update && opkg install xray-core"
	return 1
}

# xray запускается с -confdir и читает из каталога конфига все *.json подряд.
# Чужие файлы там только мешают, поэтому переименовываем их в .bak.
config_dir_clean() {
	# Убираем только СВОИ временные файлы (config.tmp.*.json). Чужие .json в
	# каталоге конфига не трогаем: там могут лежать файлы других программ —
	# прежняя версия панели переименовывала их в .bak, и это выглядело так,
	# будто «панель что-то испортила».
	_conf=$(xray_config)
	_dir=$(dirname "$_conf")
	_base=$(basename "$_conf")
	[ -d "$_dir" ] || return 0
	_removed=""
	for _f in "$_dir/${_base%.json}".tmp.*.json; do
		[ -f "$_f" ] || continue
		rm -f "$_f" 2>/dev/null && _removed="$_removed$(basename "$_f"), "
	done
	[ -n "$_removed" ] && echo "убран свой временный файл: ${_removed%, }"
	_other=""
	for _f in "$_dir"/*.json; do
		[ -f "$_f" ] || continue
		_b=$(basename "$_f")
		[ "$_b" = "$_base" ] && continue
		case "$_b" in *.tmp.*.json) continue ;; esac
		_other="$_other$_b, "
	done
	[ -n "$_other" ] && echo "в каталоге конфига есть другие .json (не трогаю): ${_other%, }"
	return 0
}

# Конфиг в каталоге мог принадлежать другой программе (xray любят ставить
# вместе с другими панелями). Наш конфиг узнаём по служебному входу
# local-access: если его нет — файл чужой, и перед перезаписью делаем копию.
# Копию держим в каталоге настроек панели, чтобы не мусорить в каталоге
# конфига (служба запускается с -confdir и читает оттуда все .json).
config_backup_foreign() {
	_conf=$(xray_config)
	[ -f "$_conf" ] || return 0
	grep -q '"local-access"' "$_conf" 2>/dev/null && return 0
	_cp="$STATE_DIR/config.foreign-$(date +%Y%m%d-%H%M%S).json"
	if cp -f "$_conf" "$_cp" 2>/dev/null; then
		echo "конфиг был от другой программы — копия сохранена: $_cp"
		# держим только свежую копию, старые убираем
		ls -1t "$STATE_DIR"/config.foreign-*.json 2>/dev/null | tail -n +2 | while read -r _f; do rm -f "$_f" 2>/dev/null; done
	fi
	return 0
}

# --- DNS самого роутера через туннель -----------------------------------------
# Перехватывать DNS роутера правилами (DNAT) нельзя: запрос создаётся локально,
# и ответ приходит с адреса xray (127.0.0.1:порт), а резолвер ждёт ответ с того
# адреса, куда сам спрашивал — и молча его выбрасывает. Поэтому переводим
# dnsmasq на локальный порт xray: тогда это обычный обмен по петле, без подмены
# адресов. Прежние настройки сохраняем и возвращаем при выключении.
DNSMASQ_STATE="$STATE_DIR/dnsmasq.saved"

# Чистка списка серверов dnsmasq от «склеенных» записей.
# Прежняя версия панели возвращала сохранённый список одной строкой, и в
# настройках появлялось значение вида `'127.0.0.1#5053' '127.0.0.1#5054'` —
# dnsmasq такое уже не понимает. Нормальные записи не трогаем.
dnsmasq_servers_clean() {
	uci -q show dhcp 2>/dev/null | sed -n 's/^dhcp\.@dnsmasq\[[0-9]*\]\.server=//p' | tr "'" '\n' |
	while IFS= read -r _v; do
		_v=$(printf '%s' "$_v" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
		[ -n "$_v" ] || continue
		case "$_v" in
			*" "*|*"'"*|*'"'*) uci -q del_list dhcp.@dnsmasq[0].server="$_v" 2>/dev/null ;;
		esac
	done
	return 0
}

# Возвращается ли значение в список как есть: склеенные строки пропускаем,
# иначе панель снова испортит список (это и была прежняя ошибка).
serv_done() { # $1 = значение; 0 — уже есть в списке или это мусор
	case "$1" in
		*" "*|*"'"*|*'"'*) return 0 ;;
	esac
	_ex=" $(uci -q get dhcp.@dnsmasq[0].server 2>/dev/null) "
	case "$_ex" in *" $1 "*) return 0 ;; esac
	return 1
}

# Список DNS-резолверов для туннеля: в настройках одна строка, адресов может
# быть несколько (через запятую, точку с запятой или пробел).
dns_resolver_list() {
	printf '%s' "$(cfg dns_resolvers "$(cfg dns_resolver "1.1.1.1")")" |
		tr -s ',;' '  ' | tr -s ' ' '\n' | awk 'NF { print }' | head -n 4
}

# Порты входов DNS-туннеля: базовый порт + по одному на каждый резолвер.
# Конфликтующие порты (перехват трафика, SOCKS, API) пропускаем.
dns_tunnel_ports() {
	_base=$(cfg dns_port 5353); [ -n "$_base" ] || _base=5353
	_tport=$(cfg transparent_port 12345)
	_socks=$(cfg socks_port 10808)
	_api=$(cfg api_port 62789)
	_i=0
	for _r in $(dns_resolver_list); do
		_p=$((_base + _i))
		while [ "$_p" = "$_tport" ] || [ "$_p" = "$_socks" ] || [ "$_p" = "$_api" ]; do
			_i=$((_i + 1))
			_p=$((_base + _i))
		done
		printf '%s\n' "$_p"
		_i=$((_i + 1))
	done
}

dnsmasq_tunnel_on() {
	# мусорные «склеенные» строки от прежних версий убираем сразу
	dnsmasq_servers_clean
	# Запоминаем только то, что меняем сами: значение noresolv и свои строки.
	if [ ! -f "$DNSMASQ_STATE" ]; then
		printf 'noresolv=%s\n' "$(uci -q get dhcp.@dnsmasq[0].noresolv 2>/dev/null)" > "$DNSMASQ_STATE" 2>/dev/null
	fi
	grep -v '^our=' "$DNSMASQ_STATE" 2>/dev/null > "$DNSMASQ_STATE.tmp" 2>/dev/null
	mv -f "$DNSMASQ_STATE.tmp" "$DNSMASQ_STATE" 2>/dev/null
	uci -q set dhcp.@dnsmasq[0].noresolv='1' 2>/dev/null
	# По строке на каждый резолвер: dnsmasq сам выберет, кто отвечает быстрее,
	# и уйдёт на другого при сбое. Чужие строки (DoH от https-dns-proxy и любые
	# другие) не трогаем — они остаются как запасной путь. Свои строки сначала
	# убираем, чтобы от повторных включений не копились дубли.
	_first=""
	_n=0
	# Чужие строки (DoH и любые другие) запоминаем и возвращаем после своих:
	# свои строки ставим В НАЧАЛО списка. При включённом строгом порядке
	# (strict-order) dnsmasq опрашивает их первыми, а остальные остаются
	# запасным путём. Без строгого порядка порядок роли не играет — dnsmasq
	# всё равно выбирает по времени ответа.
	_others=$(uci -q get dhcp.@dnsmasq[0].server 2>/dev/null)
	uci -q delete dhcp.@dnsmasq[0].server 2>/dev/null
	for _p in $(dns_tunnel_ports); do
		_line="127.0.0.1#$_p"
		[ -n "$_first" ] || _first="$_p"
		_n=$((_n + 1))
		printf 'our=%s\n' "$_line" >> "$DNSMASQ_STATE" 2>/dev/null
		uci -q add_list dhcp.@dnsmasq[0].server="$_line" 2>/dev/null
	done
	for _o in $_others; do
		[ -n "$_o" ] || continue
		serv_done "$_o" && continue
		uci -q add_list dhcp.@dnsmasq[0].server="$_o" 2>/dev/null
	done
	uci -q commit dhcp 2>/dev/null
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
	sleep 2
	# Если dnsmasq с нашими настройками не поднялся — возвращаем как было:
	# иначе на роутере пропадёт DNS целиком.
	_up=0
	/etc/init.d/dnsmasq status >/dev/null 2>&1 && _up=1
	if [ "$_up" = 0 ] && netstat -lnup 2>/dev/null | grep -q ':53 '; then _up=1; fi
	if [ "$_up" = 0 ]; then
		dnsmasq_tunnel_off >/dev/null 2>&1
		echo "dnsmasq не поднялся с настройками туннеля — вернул прежние, DNS у роутера работает как обычно"
		return 1
	fi
	echo "dnsmasq переведён на DNS-вход xray (порт $_first, серверов $_n); остальные серверы оставлены как запасной путь"
}

dnsmasq_tunnel_off() {
	[ -f "$DNSMASQ_STATE" ] || return 0
	_nr=$(sed -n 's/^noresolv=//p' "$DNSMASQ_STATE" 2>/dev/null | head -1)
	_port=$(cfg dns_port 5353)
	[ -n "$_port" ] || _port=5353
	dnsmasq_servers_clean
	# убираем ровно свои строки, чужие серверы не трогаем
	sed -n 's/^our=//p' "$DNSMASQ_STATE" 2>/dev/null | while IFS= read -r _l; do
		[ -n "$_l" ] && uci -q del_list dhcp.@dnsmasq[0].server="$_l" 2>/dev/null
	done
	# на случай старого файла без списка своих строк — убираем основной порт
	uci -q del_list dhcp.@dnsmasq[0].server="127.0.0.1#$_port" 2>/dev/null
	# если список оказался пустым (так делали прежние версии панели — стирали
	# чужие строки), возвращаем то, что было сохранено
	if [ -z "$(uci -q get dhcp.@dnsmasq[0].server 2>/dev/null)" ]; then
		sed -n 's/^server //p' "$DNSMASQ_STATE" 2>/dev/null | tr "'" '\n' | while IFS= read -r _s; do
			_s=$(printf '%s' "$_s" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
			[ -n "$_s" ] || continue
			serv_done "$_s" && continue
			uci -q add_list dhcp.@dnsmasq[0].server="$_s" 2>/dev/null
		done
	fi
	if [ -n "$_nr" ]; then
		uci -q set dhcp.@dnsmasq[0].noresolv="$_nr" 2>/dev/null
	else
		uci -q delete dhcp.@dnsmasq[0].noresolv 2>/dev/null
	fi
	uci -q commit dhcp 2>/dev/null
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
	rm -f "$DNSMASQ_STATE"
	echo "строка DNS-туннеля убрана, остальные серверы не тронуты"
}

# --- имена сайтов из журнала dnsmasq: «адрес -> имя» ------------------------
# В журнале xray вместо имени сайта стоит адрес, поэтому правила по домену,
# слову и шаблону панель проверить не могла (она отмечала их «по выходу»).
# Здесь панель просит dnsmasq записывать разобранные имена — но НЕ в отдельный
# файл, а в обычный системный журнал (это штатная возможность dnsmasq, одна
# настройка logqueries). Отдельный файл был в 0.61.3 и оказался опасен: dnsmasq
# из-за него терял связь, поэтому от файла отказались совсем — панель просто
# читает системный журнал (logread) и берёт оттуда строки вида
# «reply www.youtube.com is 142.250.1.1».
DNS_LOG_STATE="$STATE_DIR/dns-log.state"   # прежнее значение logqueries
DNS_LOG_MAP="$STATE_DIR/dns-names.map"
DNS_LOG_MAP_AT="$STATE_DIR/dns-names.map.at"
DNS_LOG_HIST="$STATE_DIR/dns-names.hist"   # история: «адрес, имя, когда видели»
DNS_LOG_NEW="$STATE_DIR/dns-names.new"
DNS_LOG_TTL=20
# сколько держим имена и сколько записей максимум: системный журнал на роутере
# короткий (десятки килобайт), поэтому свою историю панель помнит дольше
DNS_LOG_KEEP="${XRAYPANEL_DNS_KEEP:-3600}"
DNS_LOG_MAX="${XRAYPANEL_DNS_MAX:-2000}"
DNS_LOG_OLD_FILE="/tmp/xraypanel-dns.log"  # что ставила версия 0.61.3

dns_log_state() { # on | off — включена ли запись запросов
	if [ "$(uci -q get dhcp.@dnsmasq[0].logqueries 2>/dev/null)" = "1" ]; then
		printf 'on'
	else
		printf 'off'
	fi
}

dns_log_alive() { # работает ли dnsmasq прямо сейчас
	pgrep -x dnsmasq >/dev/null 2>&1
}

dns_log_restore() { # вернуть прежнее значение logqueries (без перезапуска)
	if [ -f "$DNS_LOG_STATE" ]; then
		_lq=$(sed -n 's/^logqueries=//p' "$DNS_LOG_STATE" 2>/dev/null | head -1)
		if [ -n "$_lq" ]; then
			uci -q set dhcp.@dnsmasq[0].logqueries="$_lq" 2>/dev/null
		else
			uci -q delete dhcp.@dnsmasq[0].logqueries 2>/dev/null
		fi
	fi
	# следы прежней версии (отдельный файл журнала) убираем всегда
	if [ "$(uci -q get dhcp.@dnsmasq[0].logfacility 2>/dev/null)" = "$DNS_LOG_OLD_FILE" ]; then
		uci -q delete dhcp.@dnsmasq[0].logfacility 2>/dev/null
	fi
	uci -q commit dhcp >/dev/null 2>&1
	return 0
}

dns_log_on() { # включить запись запросов
	[ -n "$(uci -q get dhcp.@dnsmasq[0] 2>/dev/null)" ] || return 1
	# если dnsmasq и так не работает — настройки не трогаем
	dns_log_alive || return 1
	if [ ! -f "$DNS_LOG_STATE" ]; then
		printf 'logqueries=%s\n' "$(uci -q get dhcp.@dnsmasq[0].logqueries 2>/dev/null)" >"$DNS_LOG_STATE" 2>/dev/null
	fi
	# убираем следы 0.61.3, если они остались
	if [ "$(uci -q get dhcp.@dnsmasq[0].logfacility 2>/dev/null)" = "$DNS_LOG_OLD_FILE" ]; then
		uci -q delete dhcp.@dnsmasq[0].logfacility 2>/dev/null
	fi
	uci -q set dhcp.@dnsmasq[0].logqueries='1' 2>/dev/null
	uci -q commit dhcp >/dev/null 2>&1
	# ВАЖНО: перезапуск, а не «перечитать настройки». Проверено на роутере:
	# при перечитывании dnsmasq эту настройку не применяет, и запись запросов
	# молча остаётся выключенной (снаружи выглядит как «включено, но имён нет»).
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
	sleep 3
	# проверяем, что dnsmasq жив: если нет — возвращаем настройки и поднимаем
	if ! dns_log_alive; then
		dns_log_restore
		/etc/init.d/dnsmasq restart >/dev/null 2>&1
		rm -f "$DNS_LOG_STATE" 2>/dev/null
		return 2
	fi
	# и проверяем, что записи запросов действительно идут в журнал
	dns_log_check || return 3
	return 0
}

# проверка: делаем один запрос имени через сам роутер и смотрим, выросло ли
# число строк-ответов в системном журнале
dns_log_check() {
	command -v logread >/dev/null 2>&1 || return 0
	command -v nslookup >/dev/null 2>&1 || return 0
	_before=$(logread 2>/dev/null | grep -c "reply .* is ")
	nslookup www.google.com 127.0.0.1 >/dev/null 2>&1
	sleep 2
	_after=$(logread 2>/dev/null | grep -c "reply .* is ")
	[ "${_after:-0}" -gt "${_before:-0}" ] 2>/dev/null
}

# что мешает записи запросов (пусто — ничего не мешает)
dns_log_blocker() {
	if [ -f /etc/dnsmasq.conf ] && grep -q "^[[:space:]]*log-facility=/dev/null" /etc/dnsmasq.conf 2>/dev/null; then
		printf 'в файле /etc/dnsmasq.conf стоит строка log-facility=/dev/null — она отправляет весь журнал dnsmasq «в никуда». Закомментируйте её (или удалите) и перезапустите dnsmasq: /etc/init.d/dnsmasq restart'
	fi
}

# сколько сейчас строк dnsmasq в системном журнале (0 = журнал молчит)
dns_log_lines() {
	command -v logread >/dev/null 2>&1 || { printf '0'; return 0; }
	_n=$(logread 2>/dev/null | grep -c dnsmasq 2>/dev/null)
	case "$_n" in ''|*[!0-9]*) _n=0 ;; esac
	printf '%s' "$_n"
}

# «починить»: перезапустить dnsmasq, чтобы он снова писал в журнал.
# Нужно после перезапуска системного журнала (logd): dnsmasq теряет с ним связь
# и молчит до собственного перезапуска.
dns_log_repair() {
	dns_log_alive || return 1
	/etc/init.d/dnsmasq restart >/dev/null 2>&1
	sleep 3
	dns_log_alive || return 2
	dns_log_check >/dev/null 2>&1 || return 3
	return 0
}

dns_log_off() { # выключить и вернуть прежние настройки
	dns_log_restore
	rm -f "$DNS_LOG_STATE" "$DNS_LOG_MAP" "$DNS_LOG_MAP_AT" "$DNS_LOG_HIST" "$DNS_LOG_NEW" "$DNS_LOG_OLD_FILE" 2>/dev/null
	if dns_log_alive; then
		/etc/init.d/dnsmasq reload >/dev/null 2>&1
	else
		# если dnsmasq по какой-то причине не работает — поднимаем его
		/etc/init.d/dnsmasq restart >/dev/null 2>&1
	fi
	return 0
}

dns_log_map_fresh() {
	[ -f "$DNS_LOG_MAP" ] || return 1
	_now=$(date +%s 2>/dev/null)
	case "$_now" in ''|*[!0-9]*) return 1 ;; esac
	_old=$(cat "$DNS_LOG_MAP_AT" 2>/dev/null)
	case "$_old" in ''|*[!0-9]*) return 1 ;; esac
	[ $((_now - _old)) -lt "$DNS_LOG_TTL" ]
}

dns_log_pairs() { # «адрес<TAB>имя» из системного журнала (с коротким кэшем)
	if dns_log_map_fresh; then cat "$DNS_LOG_MAP" 2>/dev/null; return 0; fi
	command -v logread >/dev/null 2>&1 || return 0
	mkdir -p "$STATE_DIR" 2>/dev/null
	_now=$(date +%s 2>/dev/null)
	case "$_now" in ''|*[!0-9]*) _now=0 ;; esac
	# dnsmasq пишет запросы в системный журнал; берём только хвост и только
	# его строки — остальные записи журнала нас не интересуют
	logread 2>/dev/null | tail -n 3000 | grep -a "dnsmasq" | LC_ALL=C awk -v now="$_now" '
		{
			line = $0
			if (index(line, " reply ") == 0 && index(line, " cached ") == 0) next
			n = split(line, f, " ")
			for (i = 1; i <= n; i++) {
				if (f[i] != "reply" && f[i] != "cached") continue
				name = f[i + 1]
				if (name == "" || index(name, ".") == 0) break
				ip = ""
				for (k = i + 2; k <= n; k++)
					if (f[k] ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) { ip = f[k]; break }
				if (ip != "") print ip "\t" name "\t" now
				break
			}
		}
	' | LC_ALL=C awk -F'\t' '!seen[$1]++' >"$DNS_LOG_NEW" 2>/dev/null

	# Журнал на роутере короткий (десятки килобайт), поэтому имена копим в своей
	# истории: свежие записи перекрывают старые, имя живёт DNS_LOG_KEEP секунд,
	# всего не больше DNS_LOG_MAX записей — тогда файл не растёт.
	cat "$DNS_LOG_HIST" "$DNS_LOG_NEW" 2>/dev/null | LC_ALL=C awk -F'\t' -v now="$_now" -v ttl="$DNS_LOG_KEEP" '
		NF >= 2 {
			ip = $1; nm = $2; ts = $3 + 0
			if (ts <= 0) ts = now
			if (now > 0 && ttl > 0 && now - ts > ttl) next
			if (ip in seen && seen[ip] >= ts) next
			seen[ip] = ts; names[ip] = nm
		}
		END { for (ip in seen) printf "%s\t%s\t%s\n", ip, names[ip], seen[ip] }
	' | LC_ALL=C sort -t"$(printf '\t')" -k3,3nr | head -n "$DNS_LOG_MAX" >"$DNS_LOG_HIST.tmp" 2>/dev/null
	mv -f "$DNS_LOG_HIST.tmp" "$DNS_LOG_HIST" 2>/dev/null
	LC_ALL=C awk -F'\t' 'NF >= 2 { print $1 "\t" $2 }' "$DNS_LOG_HIST" >"$DNS_LOG_MAP.tmp" 2>/dev/null
	mv -f "$DNS_LOG_MAP.tmp" "$DNS_LOG_MAP" 2>/dev/null
	rm -f "$DNS_LOG_NEW" 2>/dev/null
	date +%s >"$DNS_LOG_MAP_AT" 2>/dev/null
	cat "$DNS_LOG_MAP" 2>/dev/null
}

dns_log_count() { dns_log_pairs 2>/dev/null | grep -c . 2>/dev/null; }

svc_restart() {
	_ss=$(xray_service)
	[ -x "$INITD/$_ss" ] || return 1
	svc_enable
	"$INITD/$_ss" restart >/dev/null 2>&1
	sleep 2
	# пишем, с каким конфигом запустилась служба: в её команде виден путь к файлу
	if command -v ps >/dev/null 2>&1; then
		_cmd=$(ps w 2>/dev/null | grep "[x]ray" | head -1)
		[ -n "$_cmd" ] && echo "служба xray запущена так: $_cmd"
	fi
	[ "$(svc_state)" = "running" ]
}

svc_enabled() { # включён ли автозапуск службы при загрузке роутера
	_ss=$(xray_service)
	[ -x "$INITD/$_ss" ] || return 1
	for _f in /etc/rc.d/S*"$_ss"; do
		[ -e "$_f" ] && return 0
	done
	return 1
}

active_outbound() { # последний выход, через который шёл перехваченный трафик
	_log="$(cfg log_dir "/var/log")/xray-access.log"
	[ -f "$_log" ] || return 0
	# смотрим только хвост журнала: целиком читать его на роутере дорого
	tail -n 5000 "$_log" 2>/dev/null | grep -a "transparent -> " | tail -1 \
		| sed -n 's/.*transparent -> \([^]]*\)\].*/\1/p'
}

effective_outbound() { # какой выход используется сейчас
	if [ "$(cfg transparent 0)" = 1 ]; then
		_t=$(cfg transparent_out "")
		[ -n "$_t" ] && ! outbound_off "$_t" && { printf '%s' "$_t"; return; }
	fi
	if [ "$(cfg auto_best 0)" = 1 ]; then
		active_outbound
		return
	fi
	_d=$(cfg default_outbound "")
	[ -n "$_d" ] && outbound_off "$_d" && return 0
	printf '%s' "$_d"
}

tcp_conn_to() { # $1 адрес, $2 порт: есть ли установленное соединение
	[ -n "$1" ] && [ -n "$2" ] || return 1
	if command -v ss >/dev/null 2>&1; then
		ss -tn 2>/dev/null | grep -q "$1:$2"
	elif command -v netstat >/dev/null 2>&1; then
		netstat -tn 2>/dev/null | grep -i estab | grep -q "$1:$2"
	else
		return 1
	fi
}

ip_hex_rev() { # 82.22.184.147 -> 93B81652 (как ядро печатает адреса в /proc/net/tcp)
	case "$1" in ''|*[!0-9.]*) return 1 ;; esac
	_o1=${1%%.*}; _r=${1#*.}
	_o2=${_r%%.*}; _r=${_r#*.}
	_o3=${_r%%.*}; _o4=${_r#*.}
	printf '%02X%02X%02X%02X' "$_o4" "$_o3" "$_o2" "$_o1"
}

tcp_conn_proc() { # $1 адрес (IP), $2 порт: соединение по таблице ядра
	[ -n "$1" ] && [ -n "$2" ] || return 1
	_hex=$(ip_hex_rev "$1") || return 1
	_port=$(printf '%04X' "$2" 2>/dev/null) || return 1
	_want="$_hex:$_port"
	for _f in /proc/net/tcp /proc/net/tcp6; do
		[ -f "$_f" ] || continue
		awk -v w="$_want" '$3 == w && $4 == "01" {f=1} END {exit !f}' "$_f" && return 0
	done
	return 1
}

resolve_ip() { # домен или IP -> IP (для проверки соединений)
	case "$1" in
		''|*[!0-9.]*) ;;
		*) printf '%s' "$1"; return 0 ;;
	esac
	_ip=""
	if command -v nslookup >/dev/null 2>&1; then
		_ip=$(nslookup "$1" 2>/dev/null | awk '/^Address: /{a=$2} END{if (a) print a}')
	fi
	if [ -z "$_ip" ]; then
		_ip=$(ping -c 1 -W 2 "$1" 2>/dev/null | sed -n 's/^PING [^(]*(\([0-9.]*\)).*/\1/p' | head -1)
	fi
	[ -n "$_ip" ] && printf '%s' "$_ip"
}

bridge_debug() { # $1 тег моста, $2 тег выхода: что видит проверка
	_btag="$1"; _otag="$2"
	_sec=$(tag_to_section "$_otag")
	_a=$(uci -q get "$UCI_APP.$_sec.address")
	_p=$(uci -q get "$UCI_APP.$_sec.port")
	printf 'мост %s (выход: %s)\n' "$_btag" "${_otag:-не задан}"
	printf '  время на роутере сейчас: %s\n' "$(date '+%Y/%m/%d %H:%M:%S')"
	printf '  адрес сервера: %s:%s\n' "${_a:-?}" "${_p:-?}"
	_t=""
	for _c in ss netstat awk nslookup ping; do
		command -v "$_c" >/dev/null 2>&1 && _t="$_t$_c "
	done
	printf '  есть команды: %s\n' "${_t:-нет}"
	[ -f /proc/net/tcp ] && printf '  таблица соединений /proc/net/tcp: есть\n' || printf '  таблица соединений /proc/net/tcp: НЕТ\n'
	_ip=$(resolve_ip "$_a" 2>/dev/null)
	printf '  адрес для проверки: %s\n' "${_ip:-не определился}"
	if [ -n "$_ip" ] && [ -n "$_p" ]; then
		if tcp_conn_to "$_a" "$_p" 2>/dev/null; then
			printf '  соединение: найдено (ss/netstat)\n'
		elif tcp_conn_proc "$_ip" "$_p" 2>/dev/null; then
			printf '  соединение: найдено (таблица ядра)\n'
		else
			printf '  соединение: не найдено\n'
		fi
	fi
	_log="$(cfg log_dir "/var/log")/xray-access.log"
	if [ -f "$_log" ]; then
		_n=$(tail -n 3000 "$_log" 2>/dev/null | grep -ac "\[$_btag ->")
		_last=$(tail -n 3000 "$_log" 2>/dev/null | grep -a "\[$_btag ->" | tail -1 | cut -c1-19)
		printf '  журнал %s: есть, записей моста: %s, последняя: %s\n' "$_log" "${_n:-0}" "${_last:-нет}"
	else
		printf '  журнал %s: НЕТ\n' "$_log"
	fi
}

bridge_state() { # $1 = тег моста, $2 = тег выхода (сервер): пояснение состояния
	_btag="$1"; _otag="$2"
	# выключенный мост в конфиг не попадает — так и пишем в состоянии
	_bsec=$(bridge_section_by_tag "$_btag")
	if [ -n "$_bsec" ] && bridge_disabled "$_bsec"; then
		printf 'выключен — в конфиг не попадает'
		return 1
	fi
	_sec=$(tag_to_section "$_otag")
	_a=$(uci -q get "$UCI_APP.$_sec.address")
	_p=$(uci -q get "$UCI_APP.$_sec.port")
	# 1) главный признак — живое соединение роутера с сервером моста
	_a_ip=$(resolve_ip "$_a" 2>/dev/null)
	# если соединение можно проверить (есть адрес и таблица соединений) —
	# верим только ему: тогда «отвалился» видно сразу, без ожидания окна журнала
	_can_check=0
	if [ -n "$_a_ip" ] && [ -n "$_p" ]; then
		if [ -f /proc/net/tcp ] || command -v ss >/dev/null 2>&1 || command -v netstat >/dev/null 2>&1; then
			_can_check=1
		fi
	fi
	if [ "$_can_check" = 1 ]; then
		if tcp_conn_to "$_a" "$_p" || tcp_conn_proc "$_a_ip" "$_p"; then
			printf 'соединение с %s:%s есть' "$_a" "$_p"
			return 0
		fi
		printf 'соединения с %s:%s нет — мост не подключён' "$_a" "$_p"
		return 1
	fi
	# 2) если соединений не видно — смотрим свежесть записей моста в журнале
	_log="$(cfg log_dir "/var/log")/xray-access.log"
	if [ -f "$_log" ]; then
		_ts=$(tail -n 3000 "$_log" 2>/dev/null | grep -a "\[$_btag ->" | tail -1 | awk '{print $1" "$2}')
		if [ -n "$_ts" ]; then
			# сравнение строк: формат времени в журнале упорядочен как есть
			# окно живости: мост шлёт служебные сообщения примерно раз в 30 секунд,
			# поэтому двух минут достаточно, а вердикт обновляется быстро
			_cut=$(date -d "@$(( $(date +%s) - 120 ))" "+%Y/%m/%d %H:%M:%S" 2>/dev/null)
			if [ -n "$_cut" ]; then
				if [ "$_ts" \> "$_cut" ]; then
					printf 'активность меньше 2 минут назад'
					return 0
				fi
				printf 'соединения не видно, последняя запись: %s' "$_ts"
				return 1
			fi
			printf 'журнал есть, время сверить не удалось'
			return 0
		fi
	fi
	if [ -n "$_a" ] && [ -n "$_p" ]; then
		printf 'нет соединения с %s:%s' "$_a" "$_p"
	elif [ -z "$_a" ]; then
		printf 'у моста не указан выход (сервер)'
	else
		printf 'нет данных'
	fi
	return 1
}

bridge_active() { bridge_state "$1" "$2" >/dev/null 2>&1; }

router_tz() { # часовой пояс, заданный в настройках роутера
	_z=$(uci -q get system.@system[0].zonename 2>/dev/null)
	[ -n "$_z" ] || _z="UTC"
	printf '%s' "$_z"
}

tz_package() { # какой пакет zoneinfo нужен для этого пояса
	_region=${1%/*}
	case "$_region" in
		''|*[!A-Za-z]*) _region=core ;;
	esac
	printf 'zoneinfo-%s' "$(printf '%s' "$_region" | tr 'A-Z' 'a-z')"
}

tz_state() { # совпадает ли системная зона с зоной роутера
	_z=$(router_tz)
	_p="/usr/share/zoneinfo/$_z"
	[ -f "$_p" ] || { printf 'нет файла зоны %s — установите: opkg install %s' "$_p" "$(tz_package "$_z")"; return; }
	if [ -L /etc/localtime ]; then
		_l=$(readlink /etc/localtime 2>/dev/null)
		[ "$_l" = "$_p" ] && printf 'совпадает (%s)' "$_z" || printf 'не совпадает (%s вместо %s)' "$_l" "$_z"
	elif [ -f /etc/localtime ]; then
		printf 'файл, а не ссылка — службы могут писать время по UTC'
	else
		printf 'нет /etc/localtime — службы пишут время по UTC'
	fi
}

# Перезапуск в фоне. Нужен потому, что ответ браузеру отдаётся ДО перезапуска:
# если ждать перезапуск внутри CGI, uhttpd убивает процесс по таймауту и
# показывает «Bad Gateway / The process did not produce any response».
svc_restart_async() {
	_ss=$(xray_service)
	_log="$STATE_DIR/service.log"
	mkdir -p "$STATE_DIR" 2>/dev/null
	if [ ! -x "$INITD/$_ss" ]; then
		printf '%s служба %s не найдена\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$_ss" >>"$_log"
		return 1
	fi
	printf '%s перезапуск %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$_ss" >>"$_log"
	svc_enable >>"$_log" 2>&1
	if command -v setsid >/dev/null 2>&1; then
		setsid "$INITD/$_ss" restart >>"$_log" 2>&1 &
	else
		"$INITD/$_ss" restart >>"$_log" 2>&1 &
	fi
	return 0
}

# --- JSON -------------------------------------------------------------------
jesc() { # экранирование строки для JSON
	# переводы строк оставляем как \n: иначе многострочные значения (например
	# хвост журнала) склеиваются в одну длинную строку
	printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr -d '\r' | \
		awk 'BEGIN { ORS = "" } { if (NR > 1) printf "\\n"; printf "%s", $0 }'
}

json_lines() { # читает строки со stdin, склеивает через запятую
	_first=1
	while IFS= read -r _l || [ -n "$_l" ]; do
		[ -n "$_l" ] || continue
		if [ "$_first" = 1 ]; then _first=0; else printf ',\n'; fi
		printf '    %s' "$_l"
	done
}

# --- выборки из UCI ---------------------------------------------------------
server_sections() { uci -q show "$UCI_APP" 2>/dev/null | sed -n 's/^xraypanel\.\([^.]*\)=server$/\1/p'; }
bridge_sections() { uci -q show "$UCI_APP" 2>/dev/null | sed -n 's/^xraypanel\.\([^.]*\)=bridge$/\1/p'; }
# Правила идут в том порядке, который задан кнопками «вверх/вниз»: у каждого
# правила есть необязательный номер (ord), а без номера порядок — как в файле.
rule_sections() {
	_list=""
	_i=0
	for _r in $(uci -q show "$UCI_APP" 2>/dev/null | sed -n 's/^xraypanel\.\([^.]*\)=rule$/\1/p'); do
		_i=$((_i + 1))
		_o=$(uci -q get "$UCI_APP.$_r.ord" 2>/dev/null)
		case "$_o" in ''|*[!0-9]*) _o=0 ;; esac
		_list="$_list$(printf '%06d %06d %s\n' "$_o" "$_i" "$_r")
"
	done
	printf '%s' "$_list" | sort | awk 'NF { print $3 }'
}

# какой тип у значения правила: ip, domain, full, keyword, regexp, geosite, geoip
guess_rule_type() {
	case "$1" in
		'')        printf '';        return 0 ;;
		geoip:*)   printf 'geoip';   return 0 ;;
		geosite:*) printf 'geosite'; return 0 ;;
		full:*)    printf 'full';    return 0 ;;
		keyword:*) printf 'keyword'; return 0 ;;
		regexp:*)  printf 'regexp';  return 0 ;;
		domain:*|ext:*|ext-ip:*) printf 'domain'; return 0 ;;
	esac
	# адрес, сеть, список адресов — цифры, точки, запятые и «/»
	case "$1" in
		*[!0-9.,/]*) ;;
		*) printf 'ip'; return 0 ;;
	esac
	# IPv6
	case "$1" in
		*:*) case "$1" in *[!0-9a-fA-F:.,/]*) ;; *) printf 'ip'; return 0 ;; esac ;;
	esac
	printf 'domain'
}

# Значение правила в том виде, в каком его понимает xray: если человек выбрал
# тип «geosite», панель сама добавит префикс «geosite:». Готовые префиксы
# (старые правила, вставленный текст) не трогаем — они и так правильные.
rule_matcher_value() { # $1 тип, $2 значение -> строка для конфига
	case "$2" in
		geoip:*|geosite:*|full:*|keyword:*|regexp:*|domain:*|ext:*|ext-ip:*) printf '%s' "$2"; return 0 ;;
	esac
	case "$1" in
		geoip)   printf 'geoip:%s' "$2" ;;
		geosite) printf 'geosite:%s' "$2" ;;
		# «domain» пишем с префиксом явно: так в списке правил сразу видно, что
		# это домен со всеми поддоменами, а не «ровно этот домен» (full)
		full|keyword|regexp|domain) printf '%s:%s' "$1" "$2" ;;
		*)       printf '%s' "$2" ;;
	esac
}

# Обратный разбор для формы: «geosite:ru» -> тип geosite, значение ru.
rule_split_value() { # $1 значение -> «тип<TAB>значение»
	case "$1" in
		geoip:*)   printf 'geoip\t%s'   "${1#geoip:}" ;;
		geosite:*) printf 'geosite\t%s' "${1#geosite:}" ;;
		full:*)    printf 'full\t%s'    "${1#full:}" ;;
		keyword:*) printf 'keyword\t%s' "${1#keyword:}" ;;
		regexp:*)  printf 'regexp\t%s'  "${1#regexp:}" ;;
		domain:*)  printf 'domain\t%s'  "${1#domain:}" ;;
		*)         printf '\t%s' "$1" ;;
	esac
}

# из чего состоит правило: «кто идёт<TAB>тип адреса<TAB>куда идём».
# Старые правила (одно поле value и тип source) тоже понимаем.
rule_parts() {
	_src=$(uci -q get "$UCI_APP.$1.source" 2>/dev/null)
	_t=$(uci -q get "$UCI_APP.$1.type" 2>/dev/null)
	_v=$(uci -q get "$UCI_APP.$1.value" 2>/dev/null)
	if [ "$_t" = source ]; then
		[ -n "$_src" ] || _src="$_v"
		_v=""
		_t=""
	fi
	# в значении может оказаться готовый префикс — тогда он и задаёт тип
	_split=$(rule_split_value "$_v")
	_st=$(printf '%s' "$_split" | cut -f1)
	_sv=$(printf '%s' "$_split" | cut -f2)
	if [ -n "$_st" ]; then
		_t="$_st"; _v="$_sv"
	elif [ -z "$_t" ] && [ -n "$_v" ]; then
		_t=$(guess_rule_type "$_v")
	fi
	printf '%s\t%s\t%s\n' "$_src" "$_t" "$_v"
}

# пронумеровать правила по текущему порядку — чтобы кнопки ↑/↓ двигали точно
rule_renumber() {
	_i=0
	for _r in $(rule_sections); do
		_i=$((_i + 1))
		uci -q set "$UCI_APP.$_r.ord=$((_i * 10))"
	done
	printf '%s' "$_i"
}

# правило можно не удалять, а просто выключить: тогда оно видно в списке, но в
# конфиг xray и в маршруты через интерфейс не попадает
rule_disabled() { # $1 = раздел правила
	[ "$(uci -q get "$UCI_APP.$1.disabled" 2>/dev/null)" = 1 ]
}

# --- категории правил (0.62): напрямую / через прокси / заблокировать -------
# Новая модель: у каждого правила есть категория, и все правила собираются
# группами: сперва «заблокировать», затем «напрямую», затем «через прокси».
# У старых правил поля нет — выводим категорию из выхода, поэтому текущие
# настройки раскладываются по группам сами, без ручного переноса.
rule_category() { # $1 = раздел правила -> direct | proxy | block
	_c=$(uci -q get "$UCI_APP.$1.category" 2>/dev/null)
	case "$_c" in
		direct|proxy|block) printf '%s' "$_c"; return 0 ;;
	esac
	case "$(uci -q get "$UCI_APP.$1.outbound" 2>/dev/null)" in
		blocked)        printf 'block' ;;
		direct|iface:*) printf 'direct' ;;
		*)              printf 'proxy' ;;
	esac
}

rule_category_title() { # $1 = категория -> подпись
	case "$1" in
		direct) printf 'Напрямую' ;;
		block)  printf 'Заблокировать' ;;
		*)      printf 'Через прокси' ;;
	esac
}

# --- наборы (категории) 0.62 -------------------------------------------------
# Набор — это список того, что маршрутизируется вместе: домены, адреса, готовые
# списки. Правило ссылается на наборы и говорит: кто → какие наборы → через что.
set_sections() { # разделы-наборы в порядке показа
	_list=""
	_i=0
	for _s in $(uci -q show "$UCI_APP" 2>/dev/null | sed -n 's/^xraypanel\.\([^.]*\)=set$/\1/p'); do
		_i=$((_i + 1))
		_o=$(uci -q get "$UCI_APP.$_s.ord" 2>/dev/null)
		case "$_o" in ''|*[!0-9]*) _o=0 ;; esac
		_list="$_list$(printf '%06d %06d %s\n' "$_o" "$_i" "$_s")
"
	done
	printf '%s' "$_list" | sort | awk 'NF { print $3 }'
}

set_name() { # $1 = раздел -> подпись
	_n=$(uci -q get "$UCI_APP.$1.name" 2>/dev/null)
	[ -n "$_n" ] || _n="$1"
	printf '%s' "$_n"
}

set_section_by_name() { # $1 = подпись -> раздел (или пусто)
	for _s in $(set_sections); do
		[ "$(set_name "$_s")" = "$1" ] && { printf '%s' "$_s"; return 0; }
	done
	return 1
}

set_disabled() { # $1 = раздел набора
	[ "$(uci -q get "$UCI_APP.$1.disabled" 2>/dev/null)" = 1 ]
}

item_disabled() { # $1 = раздел записи
	[ "$(uci -q get "$UCI_APP.$1.disabled" 2>/dev/null)" = 1 ]
}

set_item_sections() { # $1 = раздел набора -> разделы записей
	_list=""
	_i=0
	for _s in $(uci -q show "$UCI_APP" 2>/dev/null | sed -n 's/^xraypanel\.\([^.]*\)=item$/\1/p'); do
		[ "$(uci -q get "$UCI_APP.$_s.set" 2>/dev/null)" = "$1" ] || continue
		_i=$((_i + 1))
		_o=$(uci -q get "$UCI_APP.$_s.ord" 2>/dev/null)
		case "$_o" in ''|*[!0-9]*) _o=0 ;; esac
		_list="$_list$(printf '%06d %06d %s\n' "$_o" "$_i" "$_s")
"
	done
	printf '%s' "$_list" | sort | awk 'NF { print $3 }'
}

recent_dests() { # «имя<TAB>сколько секунд назад» — что недавно шло через xray
	_log="$(cfg log_dir "/var/log")/xray-access.log"
	[ -f "$_log" ] || return 0
	_now=$(date +%s 2>/dev/null)
	[ -n "$_now" ] || _now=0
	# адреса переводим в имена по карте dnsmasq — иначе в журнале почти всегда
	# только IP, и записи-домены в наборах никогда бы не «загорались»
	tail -n 400 "$_log" 2>/dev/null | LC_ALL=C awk -v now="$_now" -v mapf="$DNS_LOG_MAP" '
		BEGIN {
			while ((getline ln < mapf) > 0) {
				split(ln, mf, "\t")
				if (mf[1] != "" && mf[2] != "") byname[mf[1]] = mf[2]
			}
			close(mapf)
		}
		/ accepted / {
			split($1, d, "/"); split($2, t, ":")
			ep = mktime(d[1] " " d[2] " " d[3] " " t[1] " " t[2] " " t[3])
			if (ep <= 0) next
			age = now - ep
			if (age < 0) age = 0
			dst = ""
			for (i = 1; i <= NF; i++) if ($i == "accepted") dst = $(i + 1)
			sub(/^(tcp|udp):/, "", dst)
			sub(/:[0-9]+$/, "", dst)
			if (dst == "" || dst == "reverse") next
			if (dst in byname) dst = byname[dst]
			if (!(dst in best) || age < best[dst]) best[dst] = age
		}
		END { for (d in best) printf "%s\t%d\n", d, best[d] }
	'
}

set_item_hit() { # $1 = раздел записи -> сколько секунд назад сработала (пусто)
	_t=$(uci -q get "$UCI_APP.$1.type" 2>/dev/null)
	_v=$(uci -q get "$UCI_APP.$1.value" 2>/dev/null)
	[ -n "$_v" ] || return 0
	_low=$(printf '%s' "$_v" | tr 'A-Z' 'a-z')
	_gl=""
	if [ "$_t" = geosite ]; then
		_gl=$(geo_list_domains "$_v" 20000 2>/dev/null | cut -f1 | tr 'A-Z' 'a-z')
	fi
	_best=""
	while IFS="$(printf '\t')" read -r _d _a; do
		[ -n "$_d" ] || continue
		case "$_a" in ''|*[!0-9]*) continue ;; esac
		_dl=$(printf '%s' "$_d" | tr 'A-Z' 'a-z')
		_ok=""
		case "$_t" in
			full)    [ "$_dl" = "$_low" ] && _ok=1 ;;
			domain)  [ "$_dl" = "$_low" ] && _ok=1
			         case "$_dl" in *".$_low") _ok=1 ;; esac ;;
			keyword) case "$_dl" in *"$_low"*) _ok=1 ;; esac ;;
			regexp)  printf '%s\n' "$_dl" | grep -Eq -- "$_low" 2>/dev/null && _ok=1 ;;
			ip|geoip) [ "$_dl" = "$_low" ] && _ok=1 ;;
			geosite)
				if [ -n "$_gl" ]; then
					_d2="$_dl"
					while [ -n "$_d2" ]; do
						printf '%s\n' "$_gl" | grep -qxF -- "$_d2" && { _ok=1; break; }
						case "$_d2" in
							*.*) _d2=${_d2#*.} ;;
							*) break ;;
						esac
					done
				fi
				;;
		esac
		if [ -n "$_ok" ]; then
			if [ -z "$_best" ] || [ "$_a" -lt "$_best" ]; then _best="$_a"; fi
		fi
	done <<EOL
$(recent_dests)
EOL
	printf '%s' "$_best"
}

set_create() { # $1 = подпись -> имя раздела
	_i=0
	while :; do
		_i=$((_i + 1))
		_s="set$_i"
		[ -n "$(uci -q get "$UCI_APP.$_s" 2>/dev/null)" ] || break
	done
	uci -q set "$UCI_APP.$_s=set"
	uci -q set "$UCI_APP.$_s.name=$1"
	uci -q set "$UCI_APP.$_s.ord=$(( $(set_sections | wc -l | tr -d ' ') * 10 + 10 ))"
	printf '%s' "$_s"
}

item_create() { # $1 = набор, $2 = тип, $3 = значение -> имя раздела
	_i=0
	while :; do
		_i=$((_i + 1))
		_s="it$_i"
		[ -n "$(uci -q get "$UCI_APP.$_s" 2>/dev/null)" ] || break
	done
	uci -q set "$UCI_APP.$_s=item"
	uci -q set "$UCI_APP.$_s.set=$1"
	[ -n "$2" ] && uci -q set "$UCI_APP.$_s.type=$2"
	[ -n "$3" ] && uci -q set "$UCI_APP.$_s.value=$3"
	uci -q set "$UCI_APP.$_s.ord=$(( $(set_item_sections "$1" | wc -l | tr -d ' ') * 10 + 10 ))"
	printf '%s' "$_s"
}

# условия правила: «раздел<TAB>источник<TAB>тип<TAB>значение».
# У нового правила (со ссылкой на наборы) — по строке на каждую запись набора.
# Нужно лампочкам: по журналу xray видно, какое правило сработало.
rule_conditions() {
	for _r in $(rule_sections); do
		_parts=$(rule_parts "$_r")
		_rs=$(printf '%s' "$_parts" | cut -f1)
		_sets=$(uci -q get "$UCI_APP.$_r.sets" 2>/dev/null)
		if [ -n "$_sets" ]; then
			for _st in $(printf '%s' "$_sets" | tr ',' ' '); do
				[ -n "$_st" ] || continue
				for _it in $(set_item_sections "$_st"); do
					item_disabled "$_it" && continue
					_t=$(uci -q get "$UCI_APP.$_it.type" 2>/dev/null)
					_v=$(uci -q get "$UCI_APP.$_it.value" 2>/dev/null)
					printf '%s\t%s\t%s\t%s\n' "$_r" "$_rs" "$_t" "$_v"
				done
			done
		else
			printf '%s\t%s\t%s\t%s\n' "$_r" "$_rs" "$(printf '%s' "$_parts" | cut -f2)" "$(printf '%s' "$_parts" | cut -f3)"
		fi
	done
}

# перенос старых правил (адрес + выход) в новую модель: записи раскладываются
# по наборам «Прямые» / «Прокси» / «Блок» / «Всё», а из пар «кто + выход»
# получаются правила-ссылки. Копия настроек сохраняется рядом.
rules_migrate_v062() {
	_old=""
	for _r in $(rule_sections); do
		[ -n "$(uci -q get "$UCI_APP.$_r.sets" 2>/dev/null)" ] && continue
		_old="$_old$_r "
	done
	[ -n "$_old" ] || return 0
	_cf="${XRAYPANEL_CONF_DIR:-/etc/config}/$UCI_APP"
	_bak="$_cf.bak-v062-$(date +%Y%m%d-%H%M%S)"
	cp -f "$_cf" "$_bak" 2>/dev/null
	_ordn=0
	for _r in $_old; do
		_parts=$(rule_parts "$_r")
		_rs=$(printf '%s' "$_parts" | cut -f1)
		_rt=$(printf '%s' "$_parts" | cut -f2)
		_rv=$(printf '%s' "$_parts" | cut -f3)
		_ro=$(uci -q get "$UCI_APP.$_r.outbound" 2>/dev/null)
		case "$_ro" in
			blocked)        _sname="Блок" ;;
			direct|iface:*) _sname="Прямые" ;;
			*)              _sname="Прокси" ;;
		esac
		[ -n "$_rv" ] || _sname="Всё"
		_st=$(set_section_by_name "$_sname" 2>/dev/null)
		[ -n "$_st" ] || _st=$(set_create "$_sname")
		if [ -n "$_rv" ]; then
			_dup=0
			for _it in $(set_item_sections "$_st"); do
				[ "$(uci -q get "$UCI_APP.$_it.type")" = "$_rt" ] && [ "$(uci -q get "$UCI_APP.$_it.value")" = "$_rv" ] && _dup=1
			done
			[ "$_dup" = 1 ] || item_create "$_st" "$_rt" "$_rv" >/dev/null
		fi
		_keep=""
		for _r2 in $(rule_sections); do
			[ "$_r2" = "$_r" ] && continue
			_s2=$(uci -q get "$UCI_APP.$_r2.sets" 2>/dev/null)
			[ -n "$_s2" ] || continue
			[ "$(uci -q get "$UCI_APP.$_r2.source" 2>/dev/null)" = "$_rs" ] || continue
			[ "$(uci -q get "$UCI_APP.$_r2.outbound" 2>/dev/null)" = "$_ro" ] || continue
			_keep="$_r2"
			break
		done
		if [ -n "$_keep" ]; then
			_s2=$(uci -q get "$UCI_APP.$_keep.sets")
			case ",$_s2," in
				*",$_st,"*) ;;
				*) uci -q set "$UCI_APP.$_keep.sets=$_s2,$_st" ;;
			esac
		else
			_i=0
			while :; do
				_i=$((_i + 1))
				_new="nr$_i"
				[ -n "$(uci -q get "$UCI_APP.$_new" 2>/dev/null)" ] || break
			done
			uci -q set "$UCI_APP.$_new=rule"
			uci -q set "$UCI_APP.$_new.sets=$_st"
			[ -n "$_ro" ] && uci -q set "$UCI_APP.$_new.outbound=$_ro"
			[ -n "$_rs" ] && uci -q set "$UCI_APP.$_new.source=$_rs"
			_ordn=$((_ordn + 1))
			uci -q set "$UCI_APP.$_new.ord=$((_ordn * 10))"
		fi
		uci -q delete "$UCI_APP.$_r"
	done
	uci -q commit "$UCI_APP" >/dev/null 2>&1
	printf '%s' "$_bak"
}

# Сервер и реверс-мост тоже можно не удалять, а выключать: они остаются в
# списке панели, но в конфиг xray не попадают
server_disabled() { # $1 = раздел сервера
	[ "$(uci -q get "$UCI_APP.$1.disabled" 2>/dev/null)" = 1 ]
}

bridge_disabled() { # $1 = раздел моста
	[ "$(uci -q get "$UCI_APP.$1.disabled" 2>/dev/null)" = 1 ]
}

# раздел моста по его тегу (нужно для проверок состояния)
bridge_section_by_tag() { # $1 = тег моста
	for _b in $(bridge_sections); do
		[ "$(uci -q get "$UCI_APP.$_b.tag" 2>/dev/null)" = "$1" ] && { printf '%s' "$_b"; return 0; }
	done
	return 1
}

# тег выхода выключен (или это не сервер)? нужно при проверке правил и ссылок
outbound_off() { # $1 = тег выхода; 0 — выключен
	case "$1" in ''|auto|direct|blocked|iface:*) return 1 ;; esac
	_sec=$(tag_to_section "$1")
	[ -n "$_sec" ] || return 1
	server_disabled "$_sec"
}

# имя для нового правила (правила больше не спрашивают имя у пользователя)
rule_new_name() {
	_i=0
	while [ "$_i" -lt 500 ]; do
		_i=$((_i + 1))
		uci -q get "$UCI_APP.r$_i" >/dev/null 2>&1 || { printf 'r%s' "$_i"; return 0; }
	done
	printf 'r%s' "$_i"
}

# сдвинуть правило на одну позицию: rule_move <раздел> up|down
# поставить правило первым в списке
rule_move_first() {
	_sec="$1"
	[ -n "$_sec" ] || return 1
	uci -q set "$UCI_APP.$_sec.ord=0"
	rule_renumber >/dev/null
	uci -q commit "$UCI_APP" >/dev/null 2>&1
	return 0
}

# поставить правило последним в списке
rule_move_last() {
	_sec="$1"
	[ -n "$_sec" ] || return 1
	uci -q set "$UCI_APP.$_sec.ord=999999"
	rule_renumber >/dev/null
	uci -q commit "$UCI_APP" >/dev/null 2>&1
	return 0
}

rule_move() {
	_sec="$1"
	_dir="$2"
	[ -n "$_sec" ] || return 1
	_pos=0
	_i=0
	for _r in $(rule_sections); do
		_i=$((_i + 1))
		[ "$_r" = "$_sec" ] && _pos=$_i
	done
	_n=$_i
	[ "$_pos" -gt 0 ] || return 1
	case "$_dir" in
		up)   [ "$_pos" -gt 1 ] || return 0; _swap=$((_pos - 1)) ;;
		down) [ "$_pos" -lt "$_n" ] || return 0; _swap=$((_pos + 1)) ;;
		top)
			# на самый верх: ставим номер меньше самого маленького и перенумеровываем
			rule_move_first "$_sec"
			return 0
			;;
		bottom)
			rule_move_last "$_sec"
			return 0
			;;
		*)    return 1 ;;
	esac
	_other=""
	_i=0
	for _r in $(rule_sections); do
		_i=$((_i + 1))
		[ "$_i" = "$_swap" ] && _other="$_r"
	done
	[ -n "$_other" ] || return 1
	# перенумеровываем всех и меняем номера двух соседей местами
	_i=0
	for _r in $(rule_sections); do
		_i=$((_i + 1))
		if [ "$_r" = "$_sec" ]; then
			uci -q set "$UCI_APP.$_r.ord=$((_swap * 10))"
		elif [ "$_r" = "$_other" ]; then
			uci -q set "$UCI_APP.$_r.ord=$((_pos * 10))"
		else
			uci -q set "$UCI_APP.$_r.ord=$((_i * 10))"
		fi
	done
	uci -q commit "$UCI_APP" >/dev/null 2>&1
	return 0
}

server_tag() { # имя секции -> тег выхода
	_t=$(uci -q get "$UCI_APP.$1.tag" 2>/dev/null)
	[ -n "$_t" ] || _t="srv-$1"
	printf '%s' "$_t"
}

tag_to_section() { # тег выхода -> имя секции
	for _s in $(server_sections); do
		[ "$(server_tag "$_s")" = "$1" ] && { printf '%s' "$_s"; return; }
	done
}

# --- серверы, задействованные в реверсе --------------------------------------
# Такой сервер — это вход туннеля, а не выход в интернет: трафик, отправленный
# в него, вернётся на роутер и выйдет через его собственный интернет. Поэтому
# в списках выхода (и в автовыборе по пингу) они не участвуют.
# Каким способом собирать реверс-мосты:
#   legacy — старый reverse.bridges (xray до 25.x), по умолчанию;
#   new    — новый «VLESS Reverse Proxy» (xray 25.x и новее);
#   off    — бинарник не умеет старый способ, а новый ещё не настроен.
reverse_style() {
	_rf="$STATE_DIR/reverse.style"
	_v=$(cat "$_rf" 2>/dev/null)
	case "$_v" in
		legacy|new|off) printf '%s' "$_v" ;;
		*)              printf 'legacy' ;;
	esac
}

# Сервер с Hysteria 2 требует xray 25+ (там появился этот транспорт). Если
# сборка его не знает, такой сервер нельзя писать в конфиг: иначе xray вообще
# не запустится. Признак ставится при первой неудачной проверке конфига.
server_available() { # $1 = имя секции сервера
	_p=$(uci -q get "$UCI_APP.$1.protocol" 2>/dev/null)
	case "$_p" in
		hy|hysteria|hysteria2)
			[ -f "$STATE_DIR/hysteria.unsupported" ] && return 1
			;;
	esac
	return 0
}

reverse_tags() {
	for _b in $(bridge_sections); do
		_t=$(uci -q get "$UCI_APP.$_b.outbound" 2>/dev/null)
		[ -n "$_t" ] && printf '%s\n' "$_t"
	done
}

server_is_reverse() { # $1 = тег выхода
	for _rt in $(reverse_tags); do
		[ "$_rt" = "$1" ] && return 0
	done
	return 1
}

# --- создание разделов UCI ---------------------------------------------------
valid_uci_name() { # имя раздела допустимо для UCI?
	case "$1" in ''|*[!A-Za-z0-9_]*) return 1 ;; *) return 0 ;; esac
}

reality_key_ok() { # публичный ключ Reality: 43 символа base64url
	case "$1" in
		''|*[!A-Za-z0-9_-]*) return 1 ;;
	esac
	[ "${#1}" = 43 ]
}

# --- Shadowsocks: методы и проверка ключа ------------------------------------
ss2022_key_len() { # сколько байт должно быть в ключе для метода (0 — не ss2022)
	case "$1" in
		2022-blake3-aes-128-gcm)                               printf '16' ;;
		2022-blake3-aes-256-gcm|2022-blake3-chacha20-poly1305) printf '32' ;;
		*)                                                     printf '0' ;;
	esac
}

ss_key_check() { # $1 метод, $2 пароль -> пусто, если ключ похож на правду
	_want=$(ss2022_key_len "$1")
	[ "$_want" != 0 ] || return 0
	# Ключ — это base64 от ключа нужной длины. Длину самой строки base64
	# считаем арифметикой, а не раскодированием: декодирование в awk зависит
	# от сборки (некоторые awk пишут многобайтные символы) и врёт.
	case "$_want" in
		16) _chars=22 ;;   # 16 байт — 22 символа base64 плюс «==»
		32) _chars=43 ;;   # 32 байта — 43 символа base64 плюс «=»
	esac
	_p="$2"
	case "$_p" in
		*:*) _keys="${_p%%:*} ${_p#*:}" ;;   # многопользовательский вид: ключ сервера : ключ клиента
		*)   _keys="$_p" ;;
	esac
	for _k in $_keys; do
		_n="${_k%%=*}"                # хвостовые «=» (выравнивание) не считаем
		case "$_n" in
			'') _len=0 ;;
			*[!A-Za-z0-9+/]*) _len=-1 ;;
			*) _len=${#_n} ;;
		esac
		[ "$_len" = "$_chars" ] || {
			printf 'ключ метода %s — это base64 на %s байт (%s символа), а тут %s (сервер с таким ключом не поднимется)' \
				"$1" "$_want" "$_chars" "$([ "$_len" -lt 0 ] && echo "не base64" || echo "${_len}")"
			return 1
		}
	done
	return 0
}

ensure_section() { # $1 тип, $2 желаемое имя -> печатает имя раздела
	_type="$1"; _want="$2"
	if [ -n "$_want" ] && valid_uci_name "$_want"; then
		_cur=$(uci -q get "$UCI_APP.$_want" 2>/dev/null)
		if [ -n "$_cur" ]; then
			# раздел с таким именем уже есть — берём его, только если тип совпал
			if [ "$_cur" = "$_type" ]; then printf '%s' "$_want"; return 0; fi
			_want=""
		elif uci -q set "$UCI_APP.$_want=$_type" >/dev/null 2>&1; then
			printf '%s' "$_want"; return 0
		fi
	fi
	uci -q add "$UCI_APP" "$_type" 2>/dev/null
}

unique_section_name() { # $1 желаемое имя -> свободное имя раздела
	_base=$(printf '%s' "$1" | sed -e 's/[^A-Za-z0-9_]/_/g' -e 's/^_*//' -e 's/_*$//' | cut -c1-24)
	[ -n "$_base" ] || _base="node"
	_n=0
	while [ "$_n" -lt 200 ]; do
		if [ "$_n" = 0 ]; then _try="$_base"; else _try="${_base}${_n}"; fi
		uci -q get "$UCI_APP.$_try" >/dev/null 2>&1 || { printf '%s' "$_try"; return 0; }
		_n=$((_n+1))
	done
	printf '%s' "$_base"
}

unique_tag() { # $1 желаемый тег выхода -> свободный тег
	_base=$(printf '%s' "$1" | sed -e 's/[^A-Za-z0-9._-]/-/g' -e 's/-\{1,\}/-/g' -e 's/^[._-]*//' -e 's/[._-]*$//' | cut -c1-32)
	[ -n "$_base" ] || _base="srv"
	_n=0
	while [ "$_n" -lt 200 ]; do
		if [ "$_n" = 0 ]; then _try="$_base"; else _try="${_base}-${_n}"; fi
		_taken=0
		for _s in $(server_sections); do [ "$(server_tag "$_s")" = "$_try" ] && _taken=1; done
		[ "$_taken" = 0 ] && { printf '%s' "$_try"; return 0; }
		_n=$((_n+1))
	done
	printf '%s' "$_base"
}

# --- генерация конфига xray -------------------------------------------------
gen_outbound_server() { # имя секции
	_s="$1"
	_tag=$(server_tag "$_s")
	_proto=$(uci -q get "$UCI_APP.$_s.protocol" 2>/dev/null)
	case "$_proto" in
		ss|shadowsocks)      _proto=ss ;;
		wg|wireguard)        _proto=wireguard ;;
		hy|hysteria|hysteria2) _proto=hysteria ;;
		vm|vmess)            _proto=vmess ;;
		trojan)              _proto=trojan ;;
		*)                   _proto=vless ;;
	esac
	_addr=$(jesc "$(uci -q get "$UCI_APP.$_s.address")")
	_port=$(uci -q get "$UCI_APP.$_s.port" 2>/dev/null)
	[ -n "$_port" ] || _port=443
	_mark=""
	[ "$TRANSPARENT_ON" = 1 ] && _mark=',"sockopt":{"mark":255}'
	# --- Shadowsocks: старый (вложенный) формат настроек понимают и старые,
	# и новые сборки xray, поэтому пишем именно его
	if [ "$_proto" = ss ]; then
		printf '{"tag":"%s","protocol":"shadowsocks","settings":{"servers":[{"address":"%s","port":%s,"method":"%s","password":"%s"}]},"streamSettings":{"network":"tcp"%s}}' \
			"$_tag" "$_addr" "$_port" \
			"$(jesc "$(uci -q get "$UCI_APP.$_s.method")")" \
			"$(jesc "$(uci -q get "$UCI_APP.$_s.password")")" "$_mark"
		return 0
	fi
	# --- WireGuard
	if [ "$_proto" = wireguard ]; then
		_mtu=$(uci -q get "$UCI_APP.$_s.mtu" 2>/dev/null)
		case "$_mtu" in ''|*[!0-9]*) _mtu=1420 ;; esac
		_waddr=$(jesc "$(uci -q get "$UCI_APP.$_s.wg_address" 2>/dev/null)")
		[ -n "$_waddr" ] || _waddr="10.0.0.2/32"
		_wallowed=$(jesc "$(uci -q get "$UCI_APP.$_s.wg_allowed" 2>/dev/null)")
		[ -n "$_wallowed" ] || _wallowed="0.0.0.0/0"
		printf '{"tag":"%s","protocol":"wireguard","settings":{"secretKey":"%s","address":["%s"],"peers":[{"endpoint":"%s:%s","publicKey":"%s","allowedIPs":["%s"]}],"mtu":%s}}' \
			"$_tag" \
			"$(jesc "$(uci -q get "$UCI_APP.$_s.wg_private")")" "$_waddr" \
			"$_addr" "$_port" "$(jesc "$(uci -q get "$UCI_APP.$_s.wg_peer")")" "$_wallowed" "$_mtu"
		return 0
	fi
	# --- Hysteria 2 (нужен xray 25+, где появился этот транспорт)
	if [ "$_proto" = hysteria ]; then
		_ins=$(uci -q get "$UCI_APP.$_s.insecure" 2>/dev/null)
		[ "$_ins" = 1 ] && _insl=',"allowInsecure":true' || _insl=""
		printf '{"tag":"%s","protocol":"hysteria","settings":{"version":2,"address":"%s","port":%s},"streamSettings":{"network":"hysteria","hysteriaSettings":{"version":2,"auth":"%s"%s}}}' \
			"$_tag" "$_addr" "$_port" \
			"$(jesc "$(uci -q get "$UCI_APP.$_s.password")")" "$_insl"
		return 0
	fi
	# --- VMess (часто приходит в подписках)
	if [ "$_proto" = vmess ]; then
		_net=$(uci -q get "$UCI_APP.$_s.network" 2>/dev/null)
		[ -n "$_net" ] || _net=tcp
		_aid=$(uci -q get "$UCI_APP.$_s.alterid" 2>/dev/null)
		case "$_aid" in ''|*[!0-9]*) _aid=0 ;; esac
		_str='"network":"'"$_net"'"'
		if [ "$_net" = ws ]; then
			_str="$_str,\"wsSettings\":{\"path\":\"$(jesc "$(uci -q get "$UCI_APP.$_s.path")")\",\"headers\":{\"Host\":\"$(jesc "$(uci -q get "$UCI_APP.$_s.hosthdr")")\"}}"
		fi
		if [ "$(uci -q get "$UCI_APP.$_s.tls")" = 1 ]; then
			# allowInsecure в новых сборках xray удалён, поэтому не пишем его
			_str="$_str,\"security\":\"tls\",\"tlsSettings\":{\"serverName\":\"$(jesc "$(uci -q get "$UCI_APP.$_s.sni")")\"}"
		fi
		printf '{"tag":"%s","protocol":"vmess","settings":{"vnext":[{"address":"%s","port":%s,"users":[{"id":"%s","alterId":%s,"security":"auto"}]}]},"streamSettings":{%s}}' \
			"$_tag" "$_addr" "$_port" "$(jesc "$(uci -q get "$UCI_APP.$_s.uuid")")" "$_aid" "$_str"
		return 0
	fi
	# --- Trojan
	if [ "$_proto" = trojan ]; then
		printf '{"tag":"%s","protocol":"trojan","settings":{"servers":[{"address":"%s","port":%s,"password":"%s"}]},"streamSettings":{"security":"tls","tlsSettings":{"serverName":"%s"}}}' \
			"$_tag" "$_addr" "$_port" "$(jesc "$(uci -q get "$UCI_APP.$_s.password")")" \
			"$(jesc "$(uci -q get "$UCI_APP.$_s.sni")")"
		return 0
	fi
	_uuid=$(jesc "$(uci -q get "$UCI_APP.$_s.uuid")")
	_flow=$(jesc "$(uci -q get "$UCI_APP.$_s.flow" 2>/dev/null)")
	_sni=$(jesc "$(uci -q get "$UCI_APP.$_s.sni" 2>/dev/null)")
	_pub=$(jesc "$(uci -q get "$UCI_APP.$_s.publickey" 2>/dev/null)")
	_sid=$(jesc "$(uci -q get "$UCI_APP.$_s.shortid" 2>/dev/null)")
	_fp=$(jesc "$(uci -q get "$UCI_APP.$_s.fingerprint" 2>/dev/null)")
	[ -n "$_fp" ] || _fp="chrome"
	# Транспорт: tcp (обычный VLESS+Reality, как было) или ws (WebSocket —
	# так подключаются через CDN). Для ws Reality и flow не годятся: нужен
	# обычный TLS, а путь и Host берутся из ссылки/настроек сервера.
	# имена переменных свои: _sec занято вызывающим кодом (имя сервера),
	# перезаписывать его нельзя — из-за этого проверка сервера уходила не туда
	_wsnet=$(uci -q get "$UCI_APP.$_s.network" 2>/dev/null)
	case "$_wsnet" in
		ws|websocket)
			_wpath=$(jesc "$(uci -q get "$UCI_APP.$_s.path" 2>/dev/null)")
			_whost=$(jesc "$(uci -q get "$UCI_APP.$_s.hosthdr" 2>/dev/null)")
			[ -n "$_wpath" ] || _wpath="/"
			_wtls=""
			_wsec="none"
			if [ -n "$_sni" ]; then
				_wsec="tls"
				_wtls=",\"tlsSettings\":{\"serverName\":\"$_sni\""
				[ "$(uci -q get "$UCI_APP.$_s.insecure" 2>/dev/null)" = 1 ] && _wtls="$_wtls,\"allowInsecure\":true"
				_wtls="$_wtls}"
			fi
			printf '{"tag":"%s","protocol":"vless","settings":{"vnext":[{"address":"%s","port":%s,"users":[{"id":"%s","encryption":"none"}]}]},"streamSettings":{"network":"ws","security":"%s"%s,"wsSettings":{"path":"%s"' \
				"$_tag" "$_addr" "$_port" "$_uuid" "$_wsec" "$_wtls" "$_wpath"
			[ -n "$_whost" ] && printf ',"headers":{"Host":"%s"}' "$_whost"
			printf '}%s}}' "$_mark"
			return 0
			;;
	esac
	printf '{"tag":"%s","protocol":"vless","settings":{"vnext":[{"address":"%s","port":%s,"users":[{"id":"%s","flow":"%s","encryption":"none"}]}]},"streamSettings":{"network":"tcp","security":"reality","realitySettings":{"serverName":"%s","publicKey":"%s","shortId":"%s","fingerprint":"%s","spiderX":"/"}%s}}' \
		"$_tag" "$_addr" "$_port" "$_uuid" "$_flow" "$_sni" "$_pub" "$_sid" "$_fp" "$_mark"
}

# Выводит готовый конфиг xray в stdout.
# --- проверка настроек после переноса на другой роутер -----------------------
# Интерфейсы, из которых можно выбирать: мосты, LAN и WAN. Определяем по ядру
# (/sys/class/net/<имя>/bridge) — это работает и там, где busybox-ip не умеет
# «link show type bridge», а потом добираем данными из конфигурации сети.
lan_ifaces() {
	_list=""
	for _d in /sys/class/net/*/bridge; do
		[ -d "$_d" ] || continue
		_n=$(basename "$(dirname "$_d")")
		[ "$_n" = "lo" ] && continue
		_list="$_list $_n"
	done
	for _s in $(uci -q show network 2>/dev/null | sed -n "s/^network\.\([^.]*\)\.type='bridge'\$/\1/p"); do
		case " $_list " in *" $_s "*) ;; *) _list="$_list $_s" ;; esac
	done
	_lan=$(uci -q get network.lan.device 2>/dev/null)
	[ -n "$_lan" ] || _lan=$(uci -q get network.lan.ifname 2>/dev/null)
	_wan=$(uci -q get network.wan.device 2>/dev/null)
	[ -n "$_wan" ] || _wan=$(uci -q get network.wan.ifname 2>/dev/null)
	for _x in $_lan $_wan; do
		case " $_list " in *" $_x "*) ;; *) _list="$_list $_x" ;; esac
	done
	for _x in $_list; do printf '%s\n' "$_x"; done
}

# мосты, которые видит этот роутер (для проверки моста в панели)
lan_bridges() {
	_b=$(ip -o link show type bridge 2>/dev/null | sed -n 's/^[0-9]*: \([^:]*\):.*/\1/p' | tr '\n' ' ')
	if [ -z "$_b" ]; then
		for _d in /sys/class/net/*/bridge; do
			[ -d "$_d" ] || continue
			_n=$(basename "$(dirname "$_d")")
			[ "$_n" = "lo" ] && continue
			_b="$_b$_n "
		done
	fi
	if [ -z "$_b" ]; then
		_b=$(uci -q show network 2>/dev/null | sed -n "s/^network\.\([^.]*\)\.type='bridge'\$/\1/p" | tr '\n' ' ')
	fi
	printf '%s' "$_b"
}

# основной интерфейс локальной сети: то, что висит на интерфейсе lan
# (обычно br-lan). Нужен только там, где заворачивается вся сеть.
lan_main_iface() {
	_x=$(uci -q get network.lan.device 2>/dev/null)
	[ -n "$_x" ] || _x=$(uci -q get network.lan.ifname 2>/dev/null)
	[ -n "$_x" ] || _x=$(uci -q get network.lan.ifname 2>/dev/null)
	if [ -z "$_x" ]; then
		_x=$(uci -q get network.lan.type 2>/dev/null)
		[ "$_x" = bridge ] && _x=br-lan
	fi
	if [ -z "$_x" ]; then
		for _b in $(lan_bridges); do
			_x="$_b"
			break
		done
	fi
	printf '%s' "$_x"
}

# Список клиентов хранит адреса устройств. На другом роутере таких устройств
# может не быть — тогда адрес из настроек просто ни на кого не сработает.
# Здесь убираем такие адреса и печатаем, что именно убрали (для сообщения).
prune_transparent_clients() {
	_cur=$(uci -q get "$UCI_APP.settings.transparent_clients" 2>/dev/null)
	[ -n "$_cur" ] || return 0
	_known=""
	for _h in $(uci -q show dhcp 2>/dev/null | sed -n 's/^dhcp\.\([^.]*\)=host$/\1/p'); do
		_ip=$(uci -q get "dhcp.$_h.ip" 2>/dev/null)
		[ -n "$_ip" ] && _known="$_known $_ip"
	done
	for _f in /tmp/dhcp.leases /var/dhcp.leases; do
		[ -f "$_f" ] || continue
		while read -r _exp _mac _ip _host _cid; do
			[ -n "$_ip" ] && _known="$_known $_ip"
		done < "$_f"
	done
	_keep=""; _drop=""
	for _ip in $(printf '%s' "$_cur" | tr ',' ' '); do
		[ -n "$_ip" ] || continue
		case " $_known " in
			*" $_ip "*) _keep="$_keep$_ip," ;;
			*)          _drop="$_drop$_ip, " ;;
		esac
	done
	_keep=${_keep%,}
	[ -n "$_drop" ] || return 0
	if [ -n "$_keep" ]; then
		uci -q set "$UCI_APP.settings.transparent_clients=$_keep"
	else
		uci -q delete "$UCI_APP.settings.transparent_clients"
	fi
	uci commit "$UCI_APP" >/dev/null 2>&1
	printf '%s' "${_drop%, }"
}

gen_config() {
	_api=$(cfg api_port 62789)
	_socks=$(cfg socks_port 10808)
	_socks_udp=$(cfg socks_udp 1)
	_logdir=$(cfg log_dir "/var/log")
	_default=$(cfg default_outbound "")
	# выключенный сервер не может быть выходом по умолчанию
	[ -n "$_default" ] && outbound_off "$_default" && _default=""
	_auto=$(cfg auto_best 0)
	_probe=$(cfg probe_url "https://www.gstatic.com/generate_204")
	_trans=$(cfg transparent 0)
	_tport=$(cfg transparent_port 12345)
	_tout=$(cfg transparent_out "")
	[ -n "$_tout" ] && outbound_off "$_tout" && _tout=""
	_dnst=$(cfg dns_tunnel 0)
	# отдельная галочка: пускать ли через туннель DNS самого роутера (dnsmasq).
	# Раньше это делала та же галочка, что и перехват DNS у клиентов, из-за чего
	# панель и https-dns-proxy спорили за один и тот же список серверов dnsmasq.
	# Если значение не задано — ведём себя как раньше.
	_dnsr=$(cfg dns_router "$_dnst")
	_dnsport=$(cfg dns_port 5353)
	# резолверов может быть несколько: первый считается основным (для входа,
	# который используется при заворачивании клиентов прямо в xray)
	_dnsres=$(dns_resolver_list | head -1)
	# страховка: если в настройке несколько адресов через пробел — берём первый
	_dnsres=${_dnsres%% *}
	[ -n "$_dnsres" ] || _dnsres="1.1.1.1"
	_dnsout=$(cfg dns_out "")
	[ -n "$_dnsout" ] && outbound_off "$_dnsout" && _dnsout=""
	# по умолчанию пересылаем DNS через выбранный сервер: внутренний
	# DNS-выход xray (dns-out) поддерживают не все сборки — на 24.12.31 он
	# ругается «non existing outTag: dns-out» и запрос уходил бы мимо туннеля
	_dnsmode=$(cfg dns_mode relay)
	TRANSPARENT_ON=0
	[ "$_trans" = 1 ] && TRANSPARENT_ON=1
	DNS_TUNNEL_ON=0
	[ "$_dnst" = 1 ] && DNS_TUNNEL_ON=1
	# вход dns-tunnel нужен и тогда, когда через туннель идёт только DNS роутера
	[ "$_dnsr" = 1 ] && DNS_TUNNEL_ON=1
	# relay: перехваченный DNS отдаём прямо выбранному серверу как есть.
	# Нужен там, где xray не умеет внутренний DNS-выход (dns-out): иначе
	# запрос уходил бы мимо туннеля, то есть с утечкой.
	DNS_RELAY=1
	[ "$_dnsmode" = module ] && DNS_RELAY=0
	# теги входов DNS-туннеля: по одному на каждый резолвер из списка
	_dns_tags=""
	_dns_n=0
	for _r in $(dns_resolver_list); do
		_dns_n=$((_dns_n + 1))
		_t="dns-tunnel"
		[ "$_dns_n" -gt 1 ] && _t="dns-tunnel-$_dns_n"
		_dns_tags="${_dns_tags:+$_dns_tags, }\"$_t\""
	done
	[ -n "$_dns_tags" ] || _dns_tags='"dns-tunnel"'

	# список тегов всех серверов (для балансировщика и observatory)
	_srv_tags=""
	_srv_count=0
	for _s in $(server_sections); do
		# выключенные серверы в автовыбор не берём
		server_disabled "$_s" && continue
		# серверы, занятые реверсом, в автовыбор не берём
		server_is_reverse "$(server_tag "$_s")" && continue
		# и те, что эта сборка xray не умеет (например Hysteria 2 на 24.x)
		server_available "$_s" || continue
		_srv_count=$((_srv_count+1))
		_t=$(jesc "$(server_tag "$_s")")
		if [ "$_srv_count" = 1 ]; then _srv_tags="\"$_t\""; else _srv_tags="$_srv_tags, \"$_t\""; fi
	done
	_auto_on=0
	[ "$_auto" = 1 ] && [ "$_srv_count" -gt 0 ] && _auto_on=1
	# Балансировщик «auto» нужен и тогда, когда правило само указывает выход
	# «по пингу», даже если автовыбор не включён как основной режим.
	_bal_on="$_auto_on"
	if [ "$_srv_count" -gt 0 ]; then
		for _r in $(rule_sections); do
			rule_disabled "$_r" && continue
			case "$(uci -q get "$UCI_APP.$_r.outbound" 2>/dev/null)" in
				auto) _bal_on=1 ;;
			esac
		done
	fi
	# Адреса серверов, заданные доменом: их нельзя разрешать через туннель
	# (чтобы подключиться к серверу, нужно знать его IP — иначе замкнутый круг)
	_srv_domains=""
	for _s in $(server_sections); do
		server_disabled "$_s" && continue
		_a=$(uci -q get "$UCI_APP.$_s.address" 2>/dev/null)
		[ -n "$_a" ] || continue
		case "$_a" in
			*[!0-9.]*)
				_d=$(jesc "$_a")
				_srv_domains="$_srv_domains\"full:$_d\", "
				;;
		esac
	done
	_srv_domains=$(printf '%s' "$_srv_domains" | sed 's/, $//')

	cat <<EOF
{
  "log": {"loglevel": "warning", "error": "$_logdir/xray-error.log", "access": "$_logdir/xray-access.log"},
  "api": {"tag": "api", "services": ["HandlerService", "LoggerService", "StatsService"]},
EOF
	# свой DNS нужен, когда адреса серверов заданы доменами: тогда их
	# разрешаем напрямую, а всё остальное — как настроено
	if [ -n "$_srv_domains" ]; then
		# имена наших серверов разрешаем напрямую, но по возможности шифрованно
		# (DoH) — тогда провайдер видит только соединение с резолвером,
		# а не сам запрос
		if [ "$(cfg dns_server_mode doh)" = plain ]; then
			printf '  "dns": {"servers": ["%s"]},\n' "$(jesc "$_dnsres")"
		else
		case "$_dnsres" in
			1.1.1.1) _dnsdirect="https://1.1.1.1/dns-query" ;;
			8.8.8.8) _dnsdirect="https://8.8.8.8/dns-query" ;;
			9.9.9.9) _dnsdirect="https://9.9.9.9/dns-query" ;;
			*)       _dnsdirect="$_dnsres" ;;
		esac
		printf '  "dns": {"servers": ["%s"]},\n' "$(jesc "$_dnsdirect")"
		fi
	fi
	if [ "$DNS_TUNNEL_ON" = 1 ] && [ "$DNS_RELAY" = 0 ]; then
		# свой резолвер xray: перехваченные DNS-запросы отдаём ему, он сам
		# ходит к внешнему серверу — так ответы гарантированно возвращаются
		printf '  "dns": {"tag": "dns-out", "servers": ["%s"], "queryStrategy": "UseIP"},\n' "$(jesc "$_dnsres")"
	fi
	cat <<EOF
  "inbounds": [
    {"listen": "127.0.0.1", "port": $_api, "protocol": "dokodemo-door", "settings": {"address": "127.0.0.1"}, "tag": "api"},
    {"listen": "0.0.0.0", "port": $_socks, "protocol": "socks", "settings": {"auth": "noauth", "udp": $([ "$_socks_udp" = 1 ] && echo true || echo false)}, "tag": "local-access"}
EOF
	if [ "$TRANSPARENT_ON" = 1 ]; then
		printf ',\n    {"listen": "0.0.0.0", "port": %s, "protocol": "dokodemo-door", "settings": {"network": "tcp", "followRedirect": true}, "streamSettings": {"sockopt": {"tproxy": "redirect"}}, "sniffing": {"enabled": true, "destOverride": ["http", "tls"]}, "tag": "transparent"}\n' "$_tport"
	fi
	if [ "$DNS_TUNNEL_ON" = 1 ]; then
		# перехват DNS-запросов клиентов и передача их через туннель
		# Резолверов может быть несколько: под каждый — свой вход (следующий
		# порт). Все они попадают в список dnsmasq, который сам выберет, кто
		# отвечает быстрее, и уйдёт на другого при сбое.
		_n=0
		for _r in $(dns_resolver_list); do
			_n=$((_n + 1))
			_p=$(dns_tunnel_ports | sed -n "${_n}p")
			[ -n "$_p" ] || continue
			_tag="dns-tunnel"
			[ "$_n" -gt 1 ] && _tag="dns-tunnel-$_n"
			_dnsaddr=${_r%%:*}
			case "$_r" in
				*:*) _dnsrport=${_r##*:} ;;
				*)   _dnsrport=53 ;;
			esac
			# followRedirect=false: запрос идёт на указанный резолвер через
			# туннель, а не на исходный адрес (иначе клиент, спросивший у
			# роутера, уходил бы на 192.168.x.x — и запрос умирал бы на
			# удалённой стороне)
			printf ',\n    {"listen": "0.0.0.0", "port": %s, "protocol": "dokodemo-door", "settings": {"address": "%s", "port": %s, "network": "tcp,udp", "followRedirect": false}, "streamSettings": {"sockopt": {"tproxy": "tproxy"}}, "tag": "%s"}\n' \
				"$_p" "$(jesc "$_dnsaddr")" "$_dnsrport" "$_tag"
		done
	fi
	printf '  ],\n'

	printf '  "outbounds": [\n'
	# выбранный по умолчанию сервер ставим первым — тогда весь трафик без своих правил идёт через него
	if [ -n "$_default" ] && [ "$_auto_on" = 0 ]; then
		_sec=$(tag_to_section "$_default")
		[ -n "$_sec" ] && { gen_outbound_server "$_sec"; printf ',\n'; }
	fi
	if [ "$TRANSPARENT_ON" = 1 ]; then
		printf '    {"tag": "direct", "protocol": "freedom", "settings": {"domainStrategy": "AsIs"}, "streamSettings": {"sockopt": {"mark": 255}}},\n'
	else
		printf '    {"tag": "direct", "protocol": "freedom", "settings": {"domainStrategy": "AsIs"}},\n'
	fi
	printf '    {"tag": "blocked", "protocol": "blackhole", "settings": {}}\n'
	for _s in $(server_sections); do
		# выключенные серверы в конфиг не пишем — они остаются только в списке
		server_disabled "$_s" && continue
		# серверы, которые эта сборка xray не умеет, в конфиг не пишем:
		# иначе xray не запустится целиком
		server_available "$_s" || continue
		[ "$_auto_on" = 0 ] && [ -n "$_default" ] && [ "$_s" = "$(tag_to_section "$_default")" ] && continue
		printf ',\n'
		gen_outbound_server "$_s"
	done
	printf '\n  ],\n'

	# реверс-мосты. Старый способ (reverse.bridges) есть только в старых
	# сборках xray: начиная с 25.x его удалили и заменили на «VLESS Reverse
	# Proxy». Если бинарник новый, этот блок вообще не пишем — иначе xray
	# отказывается запускаться целиком.
	_rstyle=$(reverse_style)
	_br=$(for _b in $(bridge_sections); do
		bridge_disabled "$_b" && continue
		_bt=$(jesc "$(uci -q get "$UCI_APP.$_b.tag")")
		_bd=$(jesc "$(uci -q get "$UCI_APP.$_b.domain")")
		[ -n "$_bt" ] && [ -n "$_bd" ] && printf '{"tag":"%s","domain":"%s"}\n' "$_bt" "$_bd"
	done | json_lines)
	if [ -n "$_br" ] && [ "$_rstyle" = legacy ]; then
		printf '  "reverse": {\n    "bridges": [\n%s\n    ]\n  },\n' "$_br"
	fi

	# маршрутизация
	printf '  "routing": {\n    "domainStrategy": "AsIs",\n'
	if [ "$_bal_on" = 1 ]; then
		printf '    "balancers": [\n      {"tag": "auto", "selector": [%s], "strategy": {"type": "leastPing"}}\n    ],\n' "$_srv_tags"
	fi
	printf '    "rules": [\n'
	printf '      {"type": "field", "inboundTag": ["api"], "outboundTag": "api"}'
	# имена наших серверов разрешаем напрямую — иначе круг: чтобы подключиться
	# к серверу, нужен его IP, а DNS уходит через этот же сервер
	[ -n "$_srv_domains" ] && printf ',\n      {"type": "field", "inboundTag": ["dns"], "domain": [%s], "outboundTag": "direct"}' "$_srv_domains"
	# (правило «весь перехваченный трафик — в выбранный на странице „Прокси“
	#  сервер» ставим в САМЫЙ КОНЕЦ списка: иначе оно перекрывало бы правила
	#  маршрутизации, ведь xray останавливается на первом подходящем правиле)
	# перехваченные DNS-запросы клиентов отдаём внутреннему резолверу xray
	if [ "$DNS_TUNNEL_ON" = 1 ]; then
		if [ "$DNS_RELAY" = 0 ]; then
			printf ',\n      {"type": "field", "inboundTag": [%s], "outboundTag": "dns-out"}' "$_dns_tags"
			# а его собственные запросы к внешнему резолверу — через выбранный сервер
			if [ -n "$_dnsout" ]; then
				printf ',\n      {"type": "field", "inboundTag": ["dns"], "outboundTag": "%s"}' "$(jesc "$_dnsout")"
			fi
		else
			# пересылка: выпускаем запрос через тот же выход, что и трафик
			_dtag=""
			if [ -n "$_dnsout" ]; then
				_dtag="$_dnsout"
			elif [ -n "$_tout" ] && [ "$_tout" != "auto" ]; then
				_dtag="$_tout"
			fi
			if [ -n "$_dtag" ]; then
				printf ',\n      {"type": "field", "inboundTag": [%s], "outboundTag": "%s"}' "$_dns_tags" "$(jesc "$_dtag")"
			elif [ "$_bal_on" = 1 ]; then
				printf ',\n      {"type": "field", "inboundTag": [%s], "balancerTag": "auto"}' "$_dns_tags"
			fi
		fi
	fi
	for _b in $(bridge_sections); do
		bridge_disabled "$_b" && continue
		_bt=$(jesc "$(uci -q get "$UCI_APP.$_b.tag")")
		_bd=$(jesc "$(uci -q get "$UCI_APP.$_b.domain")")
		_bo=$(jesc "$(uci -q get "$UCI_APP.$_b.outbound")")
		# если выход моста выключен — выпускаем его трафик напрямую
		outbound_off "$(uci -q get "$UCI_APP.$_b.outbound" 2>/dev/null)" && _bo=$(jesc "direct")
		# куда выпускать трафик, пришедший из туннеля (клиенты портала):
		# direct = через интернет роутера, либо тег сервера
		_bn=$(jesc "$(uci -q get "$UCI_APP.$_b.net_outbound" 2>/dev/null)")
		outbound_off "$(uci -q get "$UCI_APP.$_b.net_outbound" 2>/dev/null)" && _bn=$(jesc "direct")
		[ -n "$_bn" ] || _bn="direct"
		[ -n "$_bt" ] || continue
		[ -n "$_bo" ] && printf ',\n      {"type": "field", "inboundTag": ["%s"], "domain": ["full:%s"], "outboundTag": "%s"}' "$_bt" "$_bd" "$_bo"
		printf ',\n      {"type": "field", "inboundTag": ["%s"], "outboundTag": "%s"}' "$_bt" "$_bn"
	done
	for _r in $(rule_sections); do
		# выключенные правила в конфиг не пишем, но в списке панели они видны
		rule_disabled "$_r" && continue
		# правило, которое указывает на выключенный сервер, тоже не применяем
		outbound_off "$(uci -q get "$UCI_APP.$_r.outbound" 2>/dev/null)" && continue
		_ro=$(jesc "$(uci -q get "$UCI_APP.$_r.outbound")")
		[ -n "$_ro" ] || continue
		# цели вида iface:… — это маршрутизация ядра (через интерфейс),
		# в конфиг xray их не пишем, ими занимается iface_routes_apply
		case "$_ro" in iface:*) continue ;; esac
		_parts=$(rule_parts "$_r")
		_rs=$(jesc "$(printf '%s' "$_parts" | cut -f1)")
		# условие «кто идёт»
		_scond=""
		[ -n "$_rs" ] && _scond=$(printf '"source": ["%s"]' "$_rs")
		# собираем цели правила: домены и адреса отдельными списками.
		# Источники — либо записи наборов (новая модель), либо само значение
		# правила (старые правила, если перенос ещё не делали).
		_dom=""; _ip=""
		_sets=$(uci -q get "$UCI_APP.$_r.sets" 2>/dev/null)
		if [ -n "$_sets" ]; then
			for _st in $(printf '%s' "$_sets" | tr ',' ' '); do
				[ -n "$_st" ] || continue
				set_disabled "$_st" && continue
				for _it in $(set_item_sections "$_st"); do
					item_disabled "$_it" && continue
					_it_t=$(uci -q get "$UCI_APP.$_it.type" 2>/dev/null)
					_it_v=$(uci -q get "$UCI_APP.$_it.value" 2>/dev/null)
					[ -n "$_it_v" ] || continue
					_it_mv=$(jesc "$(rule_matcher_value "$_it_t" "$_it_v")")
					case "$_it_t" in
						ip|geoip) _ip="$_ip\"$_it_mv\", " ;;
						*)        _dom="$_dom\"$_it_mv\", " ;;
					esac
				done
			done
		else
			_rt=$(printf '%s' "$_parts" | cut -f2)
			_rv=$(printf '%s' "$_parts" | cut -f3)
			_mv=$(jesc "$(rule_matcher_value "$_rt" "$_rv")")
			case "$_rt" in
				ip|geoip) [ -n "$_rv" ] && _ip="$_ip\"$_mv\", " ;;
				domain|full|keyword|regexp|geosite) [ -n "$_rv" ] && _dom="$_dom\"$_mv\", " ;;
			esac
		fi
		_dom=${_dom%, }; _ip=${_ip%, }
		# домены одним правилом, адреса — другим (так короче и понятнее)
		if [ -n "$_dom" ]; then
			_cond=$(printf '"domain": [%s]' "$_dom")
			if [ -n "$_scond" ]; then _all="$_scond, $_cond"; else _all="$_cond"; fi
			case "$_ro" in
				auto) [ "$_bal_on" = 1 ] && printf ',\n      {"type": "field", %s, "balancerTag": "auto"}' "$_all" ;;
				*)    printf ',\n      {"type": "field", %s, "outboundTag": "%s"}' "$_all" "$_ro" ;;
			esac
		fi
		if [ -n "$_ip" ]; then
			_cond=$(printf '"ip": [%s]' "$_ip")
			if [ -n "$_scond" ]; then _all="$_scond, $_cond"; else _all="$_cond"; fi
			case "$_ro" in
				auto) [ "$_bal_on" = 1 ] && printf ',\n      {"type": "field", %s, "balancerTag": "auto"}' "$_all" ;;
				*)    printf ',\n      {"type": "field", %s, "outboundTag": "%s"}' "$_all" "$_ro" ;;
			esac
		fi
		# правило без целей (только «кто») — направляем этого клиента целиком
		if [ -z "$_dom$_ip" ] && [ -n "$_scond" ]; then
			case "$_ro" in
				auto) [ "$_bal_on" = 1 ] && printf ',\n      {"type": "field", %s, "balancerTag": "auto"}' "$_scond" ;;
				*)    printf ',\n      {"type": "field", %s, "outboundTag": "%s"}' "$_scond" "$_ro" ;;
			esac
		fi
	done
	# куда направлять остальной перехваченный трафик: сервер, выбранный на
	# странице «Прокси». Стоит после правил — «частное» всегда важнее общего.
	if [ "$TRANSPARENT_ON" = 1 ] && [ -n "$_tout" ]; then
		printf ',\n      {"type": "field", "inboundTag": ["transparent"], "outboundTag": "%s"}' "$(jesc "$_tout")"
	fi
	# всё, что не попало под правила, идёт на сервер с лучшим пингом
	if [ "$_auto_on" = 1 ]; then
		printf ',\n      {"type": "field", "network": "tcp,udp", "balancerTag": "auto"}'
	fi
	printf '\n    ]\n  },\n'
	# балансировщику leastPing нужен наблюдатель: без него xray не стартует
	if [ "$_bal_on" = 1 ]; then
		printf '  "observatory": {\n    "subjectSelector": [%s],\n    "probeURL": "%s",\n    "probeInterval": "30s",\n    "enableConcurrency": true\n  },\n' "$_srv_tags" "$(jesc "$_probe")"
	fi
	# Без блока "system" xray не ведёт счётчики по входам и выходам вообще:
	# запрос статистики возвращает пустоту, хотя служба работает. Проверено на
	# чистом конфиге: с "system" счётчики появляются, без него — пусто.
	printf '  "policy": {"levels": {"0": {"statsUserUplink": true, "statsUserDownlink": true}}, "system": {"statsInboundUplink": true, "statsInboundDownlink": true, "statsOutboundUplink": true, "statsOutboundDownlink": true}},\n'
	printf '  "stats": {}\n}\n'
}

# --- применение / откат ------------------------------------------------------
xray_test_config() { # $1 бинарник, $2 файл конфига; код в $_rc, вывод в last-test.log
	_rc=0
	if command -v timeout >/dev/null 2>&1; then
		timeout 30 "$1" run -test -config "$2" >"$STATE_DIR/last-test.log" 2>&1 || _rc=$?
	else
		"$1" run -test -config "$2" >"$STATE_DIR/last-test.log" 2>&1 || _rc=$?
	fi
}

apply_config() {
	_conf=$(xray_config)
	_dir=$(dirname "$_conf")
	mkdir -p "$_dir" "$STATE_DIR"
	_dnsnote=""
	# xray определяет формат по расширению файла, поэтому временный файл тоже
	# должен оканчиваться на .json — но держим его ВНЕ каталога конфига: служба
	# запускается с -confdir и читает все .json из каталога, так что недописанный
	# временный файл мог бы попасть в работу. В каталоге настроек он безопасен,
	# а перемещение в каталог конфига проходит переименованием (тот же раздел).
	# ВАЖНО: имя переменной своё (_cfg_tmp) — общее _tmp перезаписывают служебные
	# функции (например, работа с cron), и панель переименовывала чужой файл.
	mkdir -p "$STATE_DIR" 2>/dev/null
	_cfg_tmp="$STATE_DIR/config.tmp.$$.json"
	# если xray вообще не установлен — ставим его из репозитория
	if ! xray_present; then
		xray_install || true
	fi
	config_dir_clean
	_bin=$(xray_bin)
	if ! gen_config > "$_cfg_tmp" 2>/dev/null; then
		echo "не удалось создать конфиг (файл $_cfg_tmp)"
		echo "Каталог: $(dirname "$_cfg_tmp"), доступен для записи: $([ -w "$(dirname "$_cfg_tmp")" ] && echo да || echo нет)"
		return 1
	fi
	if [ -x "$_bin" ]; then
		xray_test_config "$_bin" "$_cfg_tmp"
		# есть сборки xray, которые не умеют отдавать трафик внутреннему
		# резолверу (outboundTag dns-out). Там перехваченный DNS уходил бы
		# мимо туннеля — то есть с утечкой. Замечаем это и переключаемся на
		# обычную пересылку DNS через выбранный сервер.
		if [ "$_rc" = 0 ] && grep -q "non existing outTag: dns-out" "$STATE_DIR/last-test.log" 2>/dev/null; then
			uci -q set "$UCI_APP.settings.dns_mode=relay" >/dev/null 2>&1
			uci commit "$UCI_APP" >/dev/null 2>&1
			gen_config > "$_cfg_tmp" && xray_test_config "$_bin" "$_cfg_tmp"
			_dnsnote="xray этого роутера не умеет внутренний DNS-резолвер — DNS пойдёт прямо через выбранный сервер (без утечки)"
		fi
		# в новых сборках xray старый реверс удалён: если конфиг из-за него не
		# проходит, убираем блок и помечаем, что нужен новый способ
		if [ "$_rc" != 0 ] && grep -q "legacy reverse" "$STATE_DIR/last-test.log" 2>/dev/null; then
			printf 'new\n' > "$STATE_DIR/reverse.style"
			gen_config > "$_cfg_tmp" && xray_test_config "$_bin" "$_cfg_tmp"
			_dnsnote="в вашем xray нет старого реверса (его удалили начиная с 25.x) — мосты временно выключены, чтобы xray вообще запустился"
		fi
		# Hysteria 2 знаком только новым сборкам xray: если проверка ругается,
		# такие серверы из конфига убираем (иначе xray не запустится совсем)
		if [ "$_rc" != 0 ] && grep -q "unknown transport protocol: hysteria" "$STATE_DIR/last-test.log" 2>/dev/null; then
			printf 'unsupported\n' > "$STATE_DIR/hysteria.unsupported"
			gen_config > "$_cfg_tmp" && xray_test_config "$_bin" "$_cfg_tmp"
			_dnsnote="ваша сборка xray не умеет Hysteria 2 (нужен xray 25+) — такие серверы временно убраны из конфига"
		fi
		if [ "$_rc" != 0 ]; then
			if [ "$_rc" = 124 ]; then
				echo "проверка конфига не уложилась в 30 секунд — конфиг не применён"
			else
				echo "конфиг не прошёл проверку xray:"
				sed -n '1,10p' "$STATE_DIR/last-test.log"
			fi
			rm -f "$_cfg_tmp"
			return 1
		fi
	else
		echo "внимание: бинарник xray не найден ($_bin) — проверка конфига пропущена"
	fi
	[ -n "$_dnsnote" ] && echo "$_dnsnote"
	# снимки статистики по выходам (история переключений между серверами)
	cron_set_exits
	# маршруты через интерфейс (если такие правила есть) — на уровне ядра
	iface_routes_apply
	# Держим ровно одну копию прежнего конфига (перезаписываем её каждый раз):
	# этого достаточно, чтобы вернуться на шаг назад, и в каталоге настроек не
	# копятся десятки файлов.
	[ -f "$_conf" ] && cp -f "$_conf" "$STATE_DIR/config.prev.json"
	config_backup_foreign
	_sum=$(md5sum "$_cfg_tmp" 2>/dev/null | awk '{print $1}')
	_sz=$(wc -c < "$_cfg_tmp" 2>/dev/null | tr -d ' ')
	# копию собранного конфига держим рядом с настройками панели: этот каталог
	# обычно доступен на запись, и если запись основного файла не удалась —
	# конфиг можно скопировать руками
	cp -f "$_cfg_tmp" "$STATE_DIR/config.last.json" 2>/dev/null
	# ошибку переименования собираем в файл: так её текст не перепутается с
	# сообщениями других команд, которые пишут в тот же журнал
	mv -f "$_cfg_tmp" "$_conf" 2>"$STATE_DIR/mv.err"
	_mrc=$?
	_merr=$(sed -n '1,2p' "$STATE_DIR/mv.err" 2>/dev/null | tr '\n' ' ')
	rm -f "$STATE_DIR/mv.err" 2>/dev/null
	if [ "$_mrc" != 0 ] || [ ! -f "$_conf" ]; then
		echo "ОШИБКА: не удалось записать $_conf${_merr:+: $_merr}"
		echo "Каталог конфига: $(dirname "$_conf"), доступен для записи: $([ -w "$(dirname "$_conf")" ] && echo да || echo нет)"
		echo "Собранный конфиг сохранён в $STATE_DIR/config.last.json — его можно скопировать вручную:"
		echo "  cp $STATE_DIR/config.last.json $_conf"
		return 1
	fi
	_sum2=$(md5sum "$_conf" 2>/dev/null | awk '{print $1}')
	_sz2=$(wc -c < "$_conf" 2>/dev/null | tr -d ' ')
	if [ -n "$_sum" ] && [ "$_sum" = "$_sum2" ]; then
		echo "конфиг записан: $_conf (${_sz:-?} байт, md5 $_sum) — совпадает с собранным"
	elif [ "${_sz2:-0}" = 0 ]; then
		echo "ВНИМАНИЕ: $_conf остался пустым (0 байт) — запись не сохранилась. Это похоже на проблему файловой системы роутера."
		echo "Собранный конфиг лежит в $STATE_DIR/config.last.json — скопируйте его вручную: cp $STATE_DIR/config.last.json $_conf"
	else
		echo "ВНИМАНИЕ: $_conf после записи не совпадает с собранным (md5 $_sum -> ${_sum2:-нет}) — возможно, файл подменила другая программа"
		echo "Собранный конфиг лежит в $STATE_DIR/config.last.json"
	fi
	# конфиг записан — список неприменённых изменений больше не нужен
	pending_clear
	echo "конфиг применён: $_conf. xray перезапускается — обновите страницу через пару секунд."
	# храним последние 10 копий
	ls -1t "$STATE_DIR"/config.*.bak 2>/dev/null | tail -n +11 | while read -r _f; do rm -f "$_f"; done
	# от прежних версий панели могли остаться копии с датой: теперь достаточно
	# одной (config.prev.json), поэтому подчищаем их, чтобы каталог не пух
	_old=$(ls -1 "$STATE_DIR"/config.*.bak 2>/dev/null | wc -l | tr -d ' ')
	if [ "${_old:-0}" -gt 0 ] 2>/dev/null; then
		rm -f "$STATE_DIR"/config.*.bak 2>/dev/null
		echo "убраны старые копии конфига с датой: $_old"
	fi
}

# Применить конфиг и перезапустить службу. Если служба не поднялась — вернуть
# прежний конфиг (config.prev.json) и перезапустить снова: так роутер не
# остаётся без прокси из-за одного неудачного применения.
apply_and_restart() {
	apply_config || return 1
	if svc_restart; then
		echo "xray перезапущен"
		return 0
	fi
	echo "xray НЕ поднялся с новым конфигом — возвращаю прежний"
	if rollback_config && svc_restart; then
		echo "прежний конфиг возвращён, xray перезапущен"
		return 1
	fi
	echo "xray не поднялся и после возврата — проверьте конфиг вручную"
	return 1
}

rollback_config() {
	_conf=$(xray_config)
	_last=""
	# сперва одна копия прежнего конфига (так работает с 0.54), затем — старые
	# файлы с датой, оставшиеся от прежних версий панели
	[ -f "$STATE_DIR/config.prev.json" ] && _last="$STATE_DIR/config.prev.json"
	[ -n "$_last" ] || _last=$(ls -1t "$STATE_DIR"/config.*.bak 2>/dev/null | head -1)
	[ -n "$_last" ] || { echo "копий прежнего конфига нет"; return 1; }
	cp -f "$_last" "$_conf"
	pending_clear
	pending_note "восстановлен прошлый конфиг — настройки панели в него не входят"
	echo "восстановлено из $_last. xray перезапускается — обновите страницу через пару секунд."
}

ping_host() { # хост -> задержка в мс (или пусто)
	_p=$(ping -c 1 -W 2 "$1" 2>/dev/null | sed -n 's/.*time=\([0-9.]*\).*/\1/p' | head -1)
	printf '%s' "$_p"
}

# --- настоящая проверка узла: качаем тестовый адрес через этот сервер --------
# Пинг показывает только доступность адреса. Здесь мы поднимаем на секунду
# отдельный xray: вход на 127.0.0.1 смотрит на тестовый адрес, а выход — на
# проверяемый сервер. Через него скачиваем страницу и меряем время.
URLTEST_FILE="$STATE_DIR/urltest"

url_test_url() { cfg url_test_url "http://www.gstatic.com/generate_204"; }
url_test_port() { cfg url_test_port 18999; }

url_test_reason() { # $1 — файл журнала проверки: печатает причину отказа словами
	_f="${1:-$STATE_DIR/last-test.log}"
	[ -f "$_f" ] || return 0
	_t=$(tail -n 80 "$_f" 2>/dev/null)
	case "$_t" in
		*"404 Not Found"*) printf 'сервер не нашёл путь (404) — проверьте путь и Host' ;;
		*"close 1000"*)    printf 'сервер закрыл соединение, клиента не признал' ;;
		*"bad handshake"*) printf 'не удалось открыть WebSocket — проверьте путь, Host и TLS' ;;
		*"failed to verify certificate"*|*"x509:"*) printf 'сертификат сервера не принят' ;;
		*"connection refused"*) printf 'сервер отклонил соединение — порт закрыт' ;;
		*"network is unreachable"*|*"no route to host"*) printf 'нет маршрута до сервера' ;;
		*"i/o timeout"*|*"deadline exceeded"*)  printf 'сервер не ответил вовремя' ;;
		*"unexpected EOF"*|*"EOF"*) printf 'соединение оборвалось без ответа' ;;
		*"unknown transport"*|*"unsupported"*) printf 'эта сборка xray не умеет такой транспорт' ;;
		# запрос ушёл, ответа нет и ошибки нет — сервер просто молчит
		*"tunneling request"*) printf 'соединение открылось, но сервер не ответил на запрос' ;;
		*) : ;;
	esac
}

url_test_server() { # $1 = тег сервера; печатает «<мс> мс» или причину отказа
	_tag="$1"
	_sec=$(tag_to_section "$_tag")
	[ -n "$_sec" ] || { printf 'нет такого сервера'; return 1; }
	_bin=$(xray_bin)
	[ -x "$_bin" ] || { printf 'xray не найден'; return 1; }
	# журнал этой проверки переписываем каждый раз: по нему потом видно, из-за
	# чего выход не ответил («нет ответа» без причины ни о чём не говорит)
	_lgf="$STATE_DIR/last-test.log"
	: > "$_lgf" 2>/dev/null
	_url=$(url_test_url)
	_tport=$(url_test_port)
	_rest=${_url#*://}
	case "$_rest" in
		*/*) _h=${_rest%%/*}; _path="/${_rest#*/}" ;;
		*)   _h="$_rest"; _path="/" ;;
	esac
	case "$_h" in
		*:*) _hp=${_h##*:}; _h=${_h%:*} ;;
		*)   _hp=80 ;;
	esac
	# Проверяем через HTTP-прокси-вход, а не через dokodemo. Причина: при
	# dokodemo клиент (wget) отправляет запрос на 127.0.0.1, и в запросе уходит
	# «Host: 127.0.0.1» — серверы с проверкой Host его не понимают, а те, кто
	# включил блокировку приватных адресов, наглухо отбрасывают такой трафик
	# (проверка показывала «нет ответа» при полностью рабочем сервере).
	# С HTTP-прокси-входом wget сам подставляет правильный Host.
	_target="http://$_h$_path"
	_proxy="http://127.0.0.1:$_tport"
	_cfg="$STATE_DIR/urltest.json"
	{
		printf '{\n  "log": {"loglevel": "info", "error": "%s"},\n' "$(jesc "$_lgf")"
		printf '  "inbounds": [{"listen": "127.0.0.1", "port": %s, "protocol": "http", "tag": "t"}],\n' "$_tport"
		printf '  "outbounds": [\n    '
		gen_outbound_server "$_sec"
		printf ',\n    {"protocol": "freedom", "tag": "direct"}\n  ],\n'
		printf '  "routing": {"rules": [{"type": "field", "inboundTag": ["t"], "outboundTag": "%s"}]}\n}\n' "$(jesc "$(server_tag "$_sec")")"
	} > "$_cfg" 2>/dev/null
	"$_bin" run -config "$_cfg" >>"$STATE_DIR/urltest.log" 2>&1 &
	_pid=$!
	sleep 1
	_t0=$(cut -d' ' -f1 /proc/uptime 2>/dev/null)
	# Качаем с ограничением по времени: wget умеет повторять попытки, поэтому
	# без ограничения можно ждать минутами. Если есть timeout — берём его.
	_rc=1
	if command -v timeout >/dev/null 2>&1; then
		http_proxy="$_proxy" timeout 12 wget -q -O /dev/null -T 5 "$_target" >/dev/null 2>&1 && _rc=0
	else
		_rcf="$STATE_DIR/urltest.rc"
		rm -f "$_rcf" 2>/dev/null
		( http_proxy="$_proxy" wget -q -O /dev/null -T 5 "$_target" >/dev/null 2>&1; printf '%s' "$?" > "$_rcf" ) &
		_n=0
		while [ ! -f "$_rcf" ] && [ "$_n" -lt 12 ]; do
			sleep 1
			_n=$((_n + 1))
		done
		_rc=$(cat "$_rcf" 2>/dev/null)
		rm -f "$_rcf" 2>/dev/null
		pkill -f "127.0.0.1:$_tport" 2>/dev/null
	fi
	_t1=$(cut -d' ' -f1 /proc/uptime 2>/dev/null)
	if [ "$_rc" = 0 ]; then
		_ms=$(awk -v a="$_t0" -v b="$_t1" 'BEGIN { printf "%d", (b - a) * 1000 }')
	else
		_ms=""
		# даём проверочному xray дописать в журнал, почему не получилось
		sleep 1
		_why=$(url_test_reason "$_lgf")
	fi
	kill "$_pid" 2>/dev/null
	rm -f "$_cfg" 2>/dev/null
	if [ -n "$_ms" ]; then
		printf '%s мс' "$_ms"
	else
		# нет ответа — объясняем, на чём именно оборвалось
		if [ -n "$_why" ]; then printf 'нет ответа (%s)' "$_why"; else printf 'нет ответа'; fi
	fi
}

url_test_save() { # $1 = тег, $2 = результат
	_tf="$URLTEST_FILE.new.$$"
	[ -f "$URLTEST_FILE" ] && grep -v "^$1	" "$URLTEST_FILE" > "$_tf" 2>/dev/null || : > "$_tf"
	printf '%s\t%s\t%s\n' "$1" "$2" "$(date '+%H:%M:%S')" >> "$_tf"
	mv -f "$_tf" "$URLTEST_FILE" 2>/dev/null
}

url_test_all() {
	for _s in $(server_sections); do
		_t=$(server_tag "$_s")
		[ -n "$_t" ] || continue
		url_test_save "$_t" "$(url_test_server "$_t")"
	done
}

url_test_saved() { # $1 = тег -> сохранённый результат
	[ -f "$URLTEST_FILE" ] || return 0
	awk -F'\t' -v t="$1" '$1 == t { print $2 " (" $3 ")" }' "$URLTEST_FILE" 2>/dev/null | head -1
}

# --- статистика трафика ------------------------------------------------------
# xray сам считает байты по каждому выходу; забираем через его API.
outbound_stats() { # печатает «тег<TAB>вверх<TAB>вниз» по строкам
	# xray api — это отдельный запуск бинарника xray, для роутера заметно.
	# Спрашивают эти байты несколько раз за показ страницы (и живое обновление
	# каждые 10 секунд), поэтому держим короткий кэш: цифры трафика от этого
	# не страдают, а страницы открываются быстрее.
	_c="$STATE_DIR/traffic-stats.cache"
	_t="$STATE_DIR/traffic-stats.cache.at"
	if [ -f "$_c" ]; then
		_now=$(date +%s 2>/dev/null)
		case "$_now" in ''|*[!0-9]*) _now=0 ;; esac
		_old=$(cat "$_t" 2>/dev/null)
		case "$_old" in ''|*[!0-9]*) _old=0 ;; esac
		if [ "$_now" -gt 0 ] && [ $((_now - _old)) -lt 10 ]; then
			cat "$_c" 2>/dev/null
			return 0
		fi
	fi
	_bin=$(xray_bin)
	_api=$(cfg api_port 62789)
	[ -x "$_bin" ] || return 0
	mkdir -p "$STATE_DIR" 2>/dev/null
	_tmp="$STATE_DIR/traffic-stats.cache.tmp.$$"
	"$_bin" api statsquery --server="127.0.0.1:$_api" -pattern "outbound>>>" 2>/dev/null | awk '
		/"name":/ { n = $0; sub(/.*"name": *"/, "", n); sub(/".*/, "", n); name = n; next }
		/"value":/ {
			v = $0; sub(/.*"value": */, "", v); sub(/[^0-9].*/, "", v);
			if (v == "") v = 0;
			if (name ~ /^outbound>>>/) { split(name, a, ">>>"); print a[2] "\t" a[4] "\t" v }
		}
	' >"$_tmp" 2>/dev/null
	mv -f "$_tmp" "$_c" 2>/dev/null
	date +%s >"$_t" 2>/dev/null
	cat "$_c" 2>/dev/null
}

stat_of() { # $1 = тег, $2 = uplink|downlink -> байты
	outbound_stats | awk -F'\t' -v t="$1" -v d="$2" '$1 == t && $2 == d { print $3; found=1 } END { if (!found) print 0 }'
}

human_bytes() { # 12345 -> 12 КБ
	awk -v b="${1:-0}" 'BEGIN {
		split("Б КБ МБ ГБ ТБ", u, " ");
		i = 1;
		while (b >= 1024 && i < 5) { b /= 1024; i++ }
		printf (i == 1 ? "%d %s" : "%.1f %s"), b, u[i]
	}'
}

# --- маршрутизация через интерфейс (как pbr) ---------------------------------
# Правило вида «источник/адрес → iface:wan2» направляет трафик не в прокси,
# а в конкретный сетевой интерфейс: для этого нужны своя таблица маршрутов
# и правило ip rule. Таблица у панели одна — 91.
IFACE_TABLE=91

iface_routes_apply() {
	command -v ip >/dev/null 2>&1 || return 0
	# сначала снимаем прежние правила панели
	iface_routes_clear >/dev/null 2>&1
	_n=0
	for _r in $(rule_sections); do
		rule_disabled "$_r" && continue
		_ro=$(uci -q get "$UCI_APP.$_r.outbound" 2>/dev/null)
		case "$_ro" in iface:*) ;; *) continue ;; esac
		_dev=${_ro#iface:}
		[ -n "$_dev" ] || continue
		_parts=$(rule_parts "$_r")
		_rs=$(printf '%s' "$_parts" | cut -f1)
		_rv=$(printf '%s' "$_parts" | cut -f3)
		[ -n "$_rs$_rv" ] || continue
		# маршрут по умолчанию через интерфейс в своей таблице. Если у
		# интерфейса есть шлюз (обычный WAN) — указываем и его: маршрут
		# «только через устройство» работает не на всех сборках.
		_gw=$(ip route show table main 2>/dev/null | awk -v d="$_dev" '
			$1 == "default" {
				g = ""; ed = 0
				for (i = 1; i <= NF; i++) {
					if ($i == "via") g = $(i + 1)
					if ($i == "dev" && $(i + 1) == d) ed = 1
				}
				if (ed && g != "") { print g; exit }
			}
		' | head -1)
		if [ -n "$_gw" ]; then
			ip route add default via "$_gw" dev "$_dev" table "$IFACE_TABLE" 2>/dev/null \
				|| ip route add default dev "$_dev" table "$IFACE_TABLE" 2>/dev/null
		else
			ip route add default dev "$_dev" table "$IFACE_TABLE" 2>/dev/null
		fi
		# «кто идёт» → from, «куда идём» → to; если указано и то и другое,
		# правило всё равно одно: from … to …
		if [ -n "$_rs" ] && [ -n "$_rv" ]; then
			ip rule add from "$_rs" to "$_rv" lookup "$IFACE_TABLE" 2>/dev/null
		elif [ -n "$_rs" ]; then
			ip rule add from "$_rs" lookup "$IFACE_TABLE" 2>/dev/null
		else
			ip rule add to "$_rv" lookup "$IFACE_TABLE" 2>/dev/null
		fi
		_n=$((_n + 1))
	done
	[ "$_n" -gt 0 ] && echo "маршрутов через интерфейс применено: $_n"
	return 0
}

iface_routes_clear() {
	command -v ip >/dev/null 2>&1 || return 0
	_n=0
	while ip rule show 2>/dev/null | grep -q "lookup $IFACE_TABLE"; do
		_line=$(ip rule show 2>/dev/null | grep "lookup $IFACE_TABLE" | head -1)
		_prio=$(printf '%s' "$_line" | awk -F: '{print $1}')
		[ -n "$_prio" ] || break
		ip rule del prio "$_prio" 2>/dev/null || break
		_n=$((_n + 1))
		[ "$_n" -ge 20 ] && break
	done
	ip route flush table "$IFACE_TABLE" 2>/dev/null
	return 0
}

traffic_reset_client() { # $1 = адрес клиента: обнулить счётчик только у него
	_ip="$1"
	[ -n "$_ip" ] || return 1
	command -v nft >/dev/null 2>&1 || return 1
	# наборы со счётчиками: убираем адрес — при следующем пакете он вернётся
	# в набор с нулевым счётчиком. В режимах «вся сеть» и «роутер и сеть»
	# счётчики живут только в наборах — на этом и заканчиваем, иначе рядом
	# появилось бы второе правило-счётчик и трафик считался бы дважды.
	if nft list set ip xraypanel cli4 >/dev/null 2>&1; then
		nft delete element ip xraypanel cli4 "{ $_ip }" >/dev/null 2>&1
		nft delete element ip xraypanel cli4dn "{ $_ip }" >/dev/null 2>&1
		return 0
	fi
	# Новые версии держат счётчики в отдельных цепочках. Там порядок правил не
	# важен, поэтому правило-счётчик можно просто переставить заново.
	if nft list chain ip xraypanel ctr >/dev/null 2>&1; then
		for _ch in ctr ctrd outf; do
			nft -a list chain ip xraypanel "$_ch" 2>/dev/null | awk -v ip="$_ip" '
				(index($0, ip) > 0) && ($0 ~ /counter/) && (match($0, /handle [0-9]+/)) {
					h = substr($0, RSTART, RLENGTH); sub(/.*handle /, "", h); print h
				}
			' | while IFS= read -r _h; do
				[ -n "$_h" ] && nft delete rule ip xraypanel "$_ch" handle "$_h" >/dev/null 2>&1
			done
		done
		nft add rule ip xraypanel ctr  ip saddr "$_ip" meta l4proto tcp counter >/dev/null 2>&1
		nft add rule ip xraypanel ctrd ip daddr "$_ip" meta l4proto tcp counter >/dev/null 2>&1
		nft add rule ip xraypanel outf ip daddr "$_ip" meta l4proto tcp counter >/dev/null 2>&1
		return 0
	fi
	# прежний вариант: счётчик стоял прямо в правиле перехвата (цепочка pre)
	_port=$(cfg transparent_port 12345)
	_scope=$(cfg transparent_scope lan)
	# счётчик стоит в самом правиле, поэтому правило этого клиента убираем
	for _ch in pre outf; do
		nft -a list chain ip xraypanel "$_ch" 2>/dev/null | awk -v ip="$_ip" '
			(index($0, ip) > 0) && ($0 ~ /counter/) && (match($0, /handle [0-9]+/)) {
				h = substr($0, RSTART, RLENGTH); sub(/.*handle /, "", h); print h
			}
		' | while IFS= read -r _h; do
			[ -n "$_h" ] && nft delete rule ip xraypanel "$_ch" handle "$_h" >/dev/null 2>&1
		done
	done
	# и ставим заново — счётчик у этого клиента начинается с нуля
	case "$_scope" in
		list) nft add rule ip xraypanel pre ip saddr "$_ip" meta l4proto tcp counter redirect to :"$_port" >/dev/null 2>&1 ;;
		*)    nft add rule ip xraypanel pre ip saddr "$_ip" meta l4proto tcp counter >/dev/null 2>&1 ;;
	esac
	nft add rule ip xraypanel outf ip daddr "$_ip" meta l4proto tcp counter >/dev/null 2>&1
	return 0
}

# счётчики клиентов: «адрес<TAB>байты», по одной строке на каждый счётчик.
# Нужны, чтобы проверить, что обнуление действительно сработало.
# ВНИМАНИЕ: имена этих функций с префиксом panel_ — не случайно. В скрипте
# правил перехвата (transparent.sh) есть своя функция client_counters, которая
# СОЗДАЁТ счётчики. Скрипт подключает эту библиотеку, и раньше одноимённая
# функция отсюда перекрывала его собственную: счётчики не создавались, и
# трафик клиентов не считался (0.61.2–0.61.13). Не переименовывать обратно!
panel_counters_dump() {
	command -v nft >/dev/null 2>&1 || return 0
	for _ch in ctr ctrd outf pre; do
		nft -a list chain ip xraypanel "$_ch" 2>/dev/null | awk '
			/counter/ {
				ip = ""; b = 0
				if (match($0, /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/)) ip = substr($0, RSTART, RLENGTH)
				if (match($0, /bytes [0-9]+/)) { b = substr($0, RSTART, RLENGTH); sub(/.*bytes /, "", b) }
				if (ip != "") print ip "\t" b
			}
		'
	done
	# счётчики в наборах (в режиме «вся локальная сеть» считаются все клиенты)
	for _s in cli4 cli4dn; do
		nft list set ip xraypanel "$_s" 2>/dev/null | tr ',' '\n' | awk '
			match($0, /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/) { ip = substr($0, RSTART, RLENGTH) }
			match($0, /bytes [0-9]+/) {
				b = substr($0, RSTART, RLENGTH); sub(/.*bytes /, "", b)
				if (ip != "") { print ip "\t" b; ip = "" }
			}
		'
	done
}

panel_counters_sum() { # сколько всего байт в счётчиках клиентов
	panel_counters_dump 2>/dev/null | awk -F'\t' '{ s += $2 } END { print s + 0 }'
}

panel_counter_ips() { # адреса, у которых есть счётчики
	panel_counters_dump 2>/dev/null | awk -F'\t' '$1 != "" { print $1 }' | sort -u
}

traffic_reset() { # обнулить счётчики трафика по клиентам
	command -v nft >/dev/null 2>&1 || return 0
	# Наборы со счётчиками (режим «вся локальная сеть»): чистим их целиком —
	# адреса вернутся в набор сами, как только клиент снова что-то передаст.
	nft flush set ip xraypanel cli4 >/dev/null 2>&1
	nft flush set ip xraypanel cli4dn >/dev/null 2>&1
	# Сначала пробуем штатный сброс счётчиков по цепочке — он самый быстрый.
	# Но на части сборок nft эта команда молча ничего не делает, поэтому
	# проверяем результат: было больше нуля, стало ноль.
	_before=$(panel_counters_sum)
	for _ch in ctr ctrd outf pre; do
		nft reset rules chain ip xraypanel "$_ch" >/dev/null 2>&1
	done
	_after=$(panel_counters_sum)
	if [ "${_before:-0}" != 0 ] && [ "${_after:-0}" = 0 ]; then
		printf 'штатным сбросом'
		return 0
	fi
	# Не сработало — делаем так же, как одиночная кнопка (она у нас работает):
	# убираем правило-счётчик клиента и ставим заново, счётчик начинается с нуля.
	_n=0
	for _ip in $(panel_counter_ips); do
		traffic_reset_client "$_ip" >/dev/null 2>&1 && _n=$((_n + 1))
	done
	_after2=$(panel_counters_sum)
	if [ "${_after2:-0}" = 0 ]; then
		printf 'перестановкой счётчиков, клиентов: %s' "$_n"
	else
		printf 'перестановкой счётчиков, клиентов: %s; остаток: %s байт' "$_n" "$_after2"
	fi
	return 0
}

client_traffic() { # трафик по клиентам: «адрес<TAB>отправлено<TAB>принято»
	# не считаем встроенные адреса роутера
	case "$1" in
		"") _self="127.0.0.1 255.255.255.255" ;;
		*)  _self="$1" ;;
	esac
	_up_chain() { # $1 = цепочка со счётчиками «отправлено»
		nft list chain ip xraypanel "$1" 2>/dev/null | awk '
			/ip saddr [0-9]/ {
				ip = $0; sub(/.*ip saddr /, "", ip); sub(/ .*/, "", ip)
				b = 0
				if (match($0, /bytes [0-9]+/)) { b = substr($0, RSTART, RLENGTH); sub(/.*bytes /, "", b) }
				print ip "\t" b "\t0"
			}
		'
	}
	_dn_chain() { # $1 = цепочка со счётчиками «принято»
		nft list chain ip xraypanel "$1" 2>/dev/null | awk '
			/ip daddr [0-9]/ {
				ip = $0; sub(/.*ip daddr /, "", ip); sub(/ .*/, "", ip)
				b = 0
				if (match($0, /bytes [0-9]+/)) { b = substr($0, RSTART, RLENGTH); sub(/.*bytes /, "", b) }
				print ip "\t0\t" b
			}
		'
	}
	_meter() { # $1 = имя набора nft -> «адрес<TAB>байт»
		nft list set ip xraypanel "$1" 2>/dev/null | tr ',' '\n' | awk '
			match($0, /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/) { ip = substr($0, RSTART, RLENGTH) }
			match($0, /bytes [0-9]+/) {
				b = substr($0, RSTART, RLENGTH); sub(/.*bytes /, "", b)
				if (ip != "") { print ip "\t" b; ip = "" }
			}
		'
	}
	# Вверх считаем в цепочке pre (клиент отдаёт трафик в перехватчик), вниз —
	# в цепочке outf (xray отдаёт ответы клиенту уже от имени сайтов).
	command -v nft >/dev/null 2>&1 || return 0
	{
		# счётчики панели живут в отдельных цепочках: ctr — «вверх» (от
		# клиента), ctrd и outf — «вниз» (транзитом и от xray)
		_up_chain ctr
		_dn_chain ctrd
		_dn_chain outf
		# старые сборки панели держали счётчики прямо в правилах перехвата
		_up_chain pre
		# адреса клиентов в наборах (для совсем старых версий)
		_meter cli4   | awk '{ print $1 "\t" $2 "\t0" }'
		_meter cli4dn | awk '{ print $1 "\t0\t" $2 }'
	} | awk '
		{ up[$1] += $2; dn[$1] += $3; seen[$1] = 1 }
		END { for (ip in seen) print ip "\t" up[ip] + 0 "\t" dn[ip] + 0 }
	'
}

# периодическая проверка узлов: строка в cron
lan_clients() { # известные адреса клиентов локальной сети (из DHCP)
	for _h in $(uci -q show dhcp 2>/dev/null | sed -n 's/^dhcp\.\([^.]*\)=host$/\1/p'); do
		uci -q get "dhcp.$_h.ip" 2>/dev/null
	done > /tmp/.xraypanel-clients.$$ 2>/dev/null
	for _f in /tmp/dhcp.leases /var/dhcp.leases; do
		[ -f "$_f" ] && awk 'NF >= 3 { print $3 }' "$_f" >> /tmp/.xraypanel-clients.$$ 2>/dev/null
	done
	sort -u /tmp/.xraypanel-clients.$$ 2>/dev/null | awk 'NF && $1 != "0.0.0.0"'
	rm -f /tmp/.xraypanel-clients.$$ 2>/dev/null
}

# То же самое, но с именами: «имя<TAB>адрес» — для выпадающих списков,
# чтобы клиента можно было выбрать мышкой, а не вписывать адрес руками.
lan_clients_named() {
	_seen=" "
	# 1) постоянные аренды DHCP (LuCI → Сеть → DHCP и DNS → Статические аренды)
	for _h in $(uci -q show dhcp 2>/dev/null | sed -n 's/^dhcp\.\([^.]*\)=host$/\1/p'); do
		_ip=$(uci -q get "dhcp.$_h.ip" 2>/dev/null)
		[ -n "$_ip" ] || continue
		case "$_seen" in *" $_ip "*) continue ;; esac
		_nm=$(uci -q get "dhcp.$_h.name" 2>/dev/null)
		_seen="$_seen$_ip "
		printf '%s\t%s\n' "${_nm:-без имени}" "$_ip"
	done
	# 2) плюс текущие выданные адреса — их может не быть в постоянных арендах
	for _f in /tmp/dhcp.leases /var/dhcp.leases; do
		[ -f "$_f" ] || continue
		while read -r _exp _mac _ip _host _cid; do
			[ -n "$_ip" ] || continue
			case "$_seen" in *" $_ip "*) continue ;; esac
			_seen="$_seen$_ip "
			printf '%s\t%s\n' "${_host:-без имени}" "$_ip"
		done < "$_f"
	done
}

b64d() { # base64, в том числе url-safe, -> текст
	# Разбираем сами, на awk: на части сборок OpenWrt нет ни `base64 -d`, ни
	# подходящих внешних утилит, а awk есть всегда. Понимает url-safe (-, _)
	# и отсутствие выравнивания.
	if [ -n "$1" ]; then _in="$1"; else _in=$(cat); fi
	printf '%s' "$_in" | awk '
		BEGIN {
			_b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
			for (_i = 1; _i <= 64; _i++) _v[substr(_b, _i, 1)] = _i - 1
			_v["-"] = 62; _v["_"] = 63
		}
		{
			_s = $0
			gsub(/[^A-Za-z0-9+\/_-]/, "", _s)
			for (_i = 1; _i <= length(_s); _i += 4) {
				_c1 = substr(_s, _i, 1); _c2 = substr(_s, _i + 1, 1)
				_c3 = substr(_s, _i + 2, 1); _c4 = substr(_s, _i + 3, 1)
				_n1 = _v[_c1]; _n2 = _v[_c2]; _n3 = _v[_c3]; _n4 = _v[_c4]
				_o = _o sprintf("%c", _n1 * 4 + int(_n2 / 16))
				if (_c3 != "") _o = _o sprintf("%c", (_n2 % 16) * 16 + int(_n3 / 4))
				if (_c4 != "") _o = _o sprintf("%c", (_n3 % 4) * 64 + _n4)
			}
		}
		END { printf "%s", _o }
	'
}

# Добавить сервер из ссылки (vless://, ss://, hysteria2://). Печатает тег
# добавленного сервера или текст ошибки — ошибка всегда содержит пробел.
server_add_from_link() {
	_raw=$(printf '%s' "$1" | tr -d '\r\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
	[ -n "$_raw" ] || { printf 'пустая ссылка'; return 1; }
	case "$_raw" in
		vless://*)             _proto=vless ;;
		ss://*)                _proto=ss ;;
		hysteria2://*|hy2://*) _proto=hysteria ;;
		vmess://*)             _proto=vmess ;;
		trojan://*)            _proto=trojan ;;
		wireguard://*|wg://*)  _proto=wireguard ;;
		*) printf 'не понимаю ссылку (умею vless://, vmess://, trojan://, ss://, hysteria2://, wireguard://)'; return 1 ;;
	esac
	_body=${_raw#*://}
	_frag=""
	case "$_body" in *'#'*) _frag=${_body#*'#'}; _body=${_body%%'#'*} ;; esac
	_query=""
	case "$_body" in *'?'*) _query=${_body#*'?'}; _body=${_body%%'?'*} ;; esac
	_q() { _v=$(printf '%s' "$_query" | tr '&' '\n' | sed -n "s/^$1=//p" | head -1); [ -n "$_v" ] && urldecode "$_v"; }
	_hp=""; _method=""; _pass=""; _uuid=""
	case "$_proto" in
		vless)
			_uuid=${_body%%@*}
			_hp=${_body#*@}
			;;
		hysteria)
			_pass=$(urldecode "$(printf '%s' "${_body%%@*}" | sed 's/:/%3A/g')")
			_hp=${_body#*@}
			;;
		ss)
			# Ссылка на Shadowsocks бывает трёх видов:
			#   ss://base64(метод:пароль)@адрес:порт  — обычный (SIP002)
			#   ss://метод:пароль@адрес:порт          — открытым текстом (как в sing-box)
			#   ss://base64(метод:пароль@адрес:порт)  — самый старый
			_ui="${_body%@*}"
			case "$_body" in
				*@*) _hp="${_body##*@}" ;;
				*)
					_dec=$(b64d "$_body")
					case "$_dec" in
						*@*) _ui="${_dec%@*}"; _hp="${_dec##*@}" ;;
						*)   printf 'не разобрал ss-ссылку'; return 1 ;;
					esac
					;;
			esac
			_hp="${_hp%%/*}"   # хвостовой «/» перед параметрами нам не нужен
			# ссылку уже раскодировали при разборе формы, второй раз нельзя:
			# urldecode превращает «+» в пробел и портит ключ
			# в base64 двоеточия не бывает: если оно есть — это открытый текст
			case "$_ui" in
				*:*) ;;
				*)   _ui=$(b64d "$_ui") ;;
			esac
			_method=${_ui%%:*}
			_pass=${_ui#*:}
			# ключ ss не декодируем: в base64 символ «+» — это плюс,
			# а не пробел, иначе ключ портится
			case "$_query" in *plugin=*) _ss_plugin=1 ;; esac
			;;
		vmess)
			# вся ссылка — base64 от JSON
			_json=$(b64d "$_body")
			[ -n "$_json" ] || { printf 'не разобрал vmess-ссылку'; return 1; }
			_jv() { printf '%s' "$_json" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\{0,1\}\([^\",}]*\)\"\{0,1\}.*/\1/p" | head -1; }
			_p_host=$(_jv add); _p_port=$(_jv port); _uuid=$(_jv id)
			_vnet=$(_jv net); _vhost=$(_jv host); _vpath=$(_jv path)
			_vtls=$(_jv tls); _vsni=$(_jv sni); _vps=$(_jv ps)
			_hp="$_p_host:$_p_port"
			;;
		trojan)
			_pass=$(urldecode "${_body%%@*}")
			_hp=${_body#*@}
			;;
		wireguard)
			# до «@» — приватный ключ клиента, после — адрес сервера,
			# остальное (address, mtu, publickey) приходит параметрами
			_wgpriv=$(urldecode "${_body%%@*}")
			_hp=${_body#*@}
			;;
	esac
	if [ "$_proto" != vmess ]; then
		_p_host=""; _p_port=""
		case "$_hp" in
			\[*\]*) _p_host=$(printf '%s' "${_hp%%]*}" | sed 's/^\[//'); _p_port=$(printf '%s' "${_hp#*]}" | sed 's/^://') ;;
			*:*)    _p_host=${_hp%:*}; _p_port=${_hp##*:} ;;
			*)      _p_host=$_hp ;;
		esac
	fi
	[ -n "$_p_host" ] || { printf 'в ссылке нет адреса сервера'; return 1; }
	case "$_p_port" in ''|*[!0-9]*) _p_port=443 ;; esac
	_name=$(urldecode "$_frag")
	[ -n "$_name" ] || _name=${_vps:-}
	_base=$(printf '%s' "$_name" | sed -e 's/[^A-Za-z0-9._-]/-/g' -e 's/-\{1,\}/-/g' -e 's/^[._-]*//' -e 's/[._-]*$//')
	[ -n "$_base" ] || _base="srv"
	_tag=$(unique_tag "$_base")
	_sec=$(ensure_section server "$(unique_section_name "$_tag")")
	[ -n "$_sec" ] || { printf 'не удалось создать раздел сервера'; return 1; }
	uci -q set "$UCI_APP.$_sec.tag=$_tag"
	uci -q set "$UCI_APP.$_sec.address=$_p_host"
	uci -q set "$UCI_APP.$_sec.port=$_p_port"
	case "$_proto" in
		ss)
			uci -q set "$UCI_APP.$_sec.protocol=ss"
			uci -q set "$UCI_APP.$_sec.method=$_method"
			uci -q set "$UCI_APP.$_sec.password=$_pass"
			[ "${_ss_plugin:-0}" = 1 ] && uci -q set "$UCI_APP.$_sec.ss_plugin=1"
			# у ss2022 ключ строго определённой длины: если он не тот — сервер
			# всё равно не поднимется, поэтому говорим об этом сразу
			_badk=$(ss_key_check "$_method" "$_pass")
			if [ -n "$_badk" ]; then
				uci -q delete "$UCI_APP.$_sec"
				uci -q commit "$UCI_APP" >/dev/null 2>&1
				printf '%s' "$_badk"
				return 1
			fi
			;;
		hysteria)
			uci -q set "$UCI_APP.$_sec.protocol=hysteria"
			uci -q set "$UCI_APP.$_sec.password=$_pass"
			_sni=$(_q sni)
			[ -n "$_sni" ] && uci -q set "$UCI_APP.$_sec.sni=$_sni"
			case "$_query" in *insecure=1*) uci -q set "$UCI_APP.$_sec.insecure=1" ;; esac
			;;
		vmess)
			uci -q set "$UCI_APP.$_sec.protocol=vmess"
			uci -q set "$UCI_APP.$_sec.uuid=$_uuid"
			[ -n "$_vnet" ] && uci -q set "$UCI_APP.$_sec.network=$_vnet"
			[ -n "$_vpath" ] && uci -q set "$UCI_APP.$_sec.path=$_vpath"
			[ -n "$_vhost" ] && uci -q set "$UCI_APP.$_sec.hosthdr=$_vhost"
			case "$_vtls" in tls|1|true) uci -q set "$UCI_APP.$_sec.tls=1" ;; esac
			[ -n "$_vsni" ] && uci -q set "$UCI_APP.$_sec.sni=$_vsni"
			;;
		trojan)
			uci -q set "$UCI_APP.$_sec.protocol=trojan"
			uci -q set "$UCI_APP.$_sec.password=$_pass"
			_tsni=$(_q sni)
			[ -n "$_tsni" ] && uci -q set "$UCI_APP.$_sec.sni=$_tsni"
			case "$_query" in *allowInsecure=1*|*insecure=1*) uci -q set "$UCI_APP.$_sec.insecure=1" ;; esac
			;;
		wireguard)
			uci -q set "$UCI_APP.$_sec.protocol=wireguard"
			uci -q set "$UCI_APP.$_sec.wg_private=$_wgpriv"
			_wgpub=$(_q publickey)
			[ -n "$_wgpub" ] && uci -q set "$UCI_APP.$_sec.wg_peer=$_wgpub"
			_wgadr=$(_q address)
			[ -n "$_wgadr" ] && uci -q set "$UCI_APP.$_sec.wg_address=$_wgadr"
			_wgmtu=$(_q mtu)
			case "$_wgmtu" in ''|*[!0-9]*) ;; *) uci -q set "$UCI_APP.$_sec.mtu=$_wgmtu" ;; esac
			;;
		*)
			uci -q set "$UCI_APP.$_sec.protocol=vless"
			uci -q set "$UCI_APP.$_sec.uuid=$_uuid"
			# транспорт: tcp (обычный Reality) или ws (WebSocket, обычно CDN)
			_vtype=$(_q type); _vsec=$(_q security)
			case "$_vtype" in
				ws|websocket)
					uci -q set "$UCI_APP.$_sec.network=ws"
					_vpath=$(_q path)
					[ -n "$_vpath" ] && uci -q set "$UCI_APP.$_sec.path=$_vpath"
					_vhost=$(_q host)
					[ -n "$_vhost" ] && uci -q set "$UCI_APP.$_sec.hosthdr=$_vhost"
					# с ws flow несовместим: чистим, чтобы не мешал
					uci -q delete "$UCI_APP.$_sec.flow" 2>/dev/null
					;;
				*)
					_flow=$(_q flow)
					[ -n "$_flow" ] || _flow="xtls-rprx-vision"
					uci -q set "$UCI_APP.$_sec.flow=$_flow"
					;;
			esac
			_sni=$(_q sni)
			[ -n "$_sni" ] || _sni=$(_q host)
			[ -n "$_sni" ] || _sni=$_p_host
			uci -q set "$UCI_APP.$_sec.sni=$_sni"
			_pbk=$(_q pbk); _sid=$(_q sid); _fp=$(_q fp)
			[ -n "$_pbk" ] && uci -q set "$UCI_APP.$_sec.publickey=$_pbk"
			[ -n "$_sid" ] && uci -q set "$UCI_APP.$_sec.shortid=$_sid"
			[ -n "$_fp" ] && uci -q set "$UCI_APP.$_sec.fingerprint=$_fp"
			;;
	esac
	uci -q commit "$UCI_APP" >/dev/null 2>&1
	printf '%s' "$_tag"
	return 0
}

# Скачать подписку и сохранить список ссылок в файл; печатает путь к файлу
server_key() { # $1 = секция сервера -> строка для сравнения на дубли
	# у серверов, добавленных до появления выбора протокола, поле пустое —
	# считаем его таким же, как vless, иначе дубли не находятся
	_p=$(uci -q get "$UCI_APP.$1.protocol" 2>/dev/null)
	case "$_p" in
		''|vless)              _p=vless ;;
		ss|shadowsocks)        _p=ss ;;
		wg|wireguard)          _p=wireguard ;;
		hy|hysteria|hysteria2) _p=hysteria ;;
		vm|vmess)              _p=vmess ;;
	esac
	printf '%s|%s|%s|%s|%s|%s' \
		"$_p" \
		"$(uci -q get "$UCI_APP.$1.address" 2>/dev/null)" \
		"$(uci -q get "$UCI_APP.$1.port" 2>/dev/null)" \
		"$(uci -q get "$UCI_APP.$1.uuid" 2>/dev/null)" \
		"$(uci -q get "$UCI_APP.$1.password" 2>/dev/null)" \
		"$(uci -q get "$UCI_APP.$1.wg_private" 2>/dev/null)"
}

sub_fetch() { # $1 = имя секции подписки
	_s="$1"
	_url=$(uci -q get "$UCI_APP.$_s.url" 2>/dev/null)
	[ -n "$_url" ] || return 1
	_ua=$(uci -q get "$UCI_APP.$_s.ua" 2>/dev/null)
	[ -n "$_ua" ] || _ua="v2rayNG/1.8.5"
	_raw="$STATE_DIR/sub.$_s.raw"
	_links="$STATE_DIR/sub.$_s.links"
	: > "$_raw" 2>/dev/null
	# пробуем несколько вариантов: у разных сборок разные ключи (uclient-fetch
	# не понимает --user-agent, где-то нет --timeout и т.п.)
	_ok=0; _err=""
	_err=$(wget -q -O "$_raw" --user-agent="$_ua" "$_url" 2>&1) && _ok=1
	if [ "$_ok" != 1 ]; then
		_err=$(wget -q -O "$_raw" "$_url" 2>&1) && _ok=1
	fi
	if [ "$_ok" != 1 ]; then
		_err=$(wget -q -T 25 -O "$_raw" "$_url" 2>&1) && _ok=1
	fi
	if [ "$_ok" != 1 ]; then
		_err=$(uclient-fetch -q -O "$_raw" "$_url" 2>&1) && _ok=1
	fi
	if [ "$_ok" != 1 ] || [ ! -s "$_raw" ]; then
		printf 'не удалось скачать подписку (%s)' "$(printf '%s' "$_err" | tail -1 | cut -c1-120)"
		return 1
	fi
	# сразу подскажем, если сервер отдал не список ссылок, а конфиг клиента
	if grep -qiE '^\s*(proxies|proxy-providers)\s*:' "$_raw" 2>/dev/null; then
		printf 'подписка отдала конфиг Clash (YAML), а не список ссылок'
		return 1
	fi
	if grep -qiE '^\s*"' "$_raw" 2>/dev/null && ! grep -q '://' "$_raw" 2>/dev/null; then
		printf 'подписка отдала JSON-конфиг, а не список ссылок'
		return 1
	fi
	if grep -q '://' "$_raw" 2>/dev/null; then
		cp -f "$_raw" "$_links"
	else
		# содержимое закодировано base64: убираем пробелы и переводы строк,
		# при необходимости дописываем выравнивание «=»
		_b64=$(tr -d '\r\n \t' < "$_raw" 2>/dev/null)
		printf '%s' "$_b64" | b64d > "$_links" 2>/dev/null
		if ! grep -q '://' "$_links" 2>/dev/null; then
			_pad="$_b64"
			while [ $(( ${#_pad} % 4 )) -ne 0 ]; do _pad="$_pad="; done
			printf '%s' "$_pad" | b64d > "$_links" 2>/dev/null
		fi
		grep -q '://' "$_links" 2>/dev/null || cp -f "$_raw" "$_links"
	fi
	[ -s "$_links" ] || return 1
	printf '%s' "$_links"
}

# Обновить подписку: заново добавить все её узлы.
# Печатает «добавлено N (ошибок M)»; старые узлы этой подписки удаляются.
sub_update() { # $1 = имя секции подписки
	_s="$1"
	_links=$(sub_fetch "$_s" 2>&1)
	if [ ! -f "$_links" ]; then
		# sub_fetch печатает либо путь к файлу, либо причину
		printf '%s' "${_links:-не удалось скачать подписку}"
		return 1
	fi
	for _sec in $(server_sections); do
		[ "$(uci -q get "$UCI_APP.$_sec.sub" 2>/dev/null)" = "$_s" ] && uci -q delete "$UCI_APP.$_sec"
	done
	uci -q commit "$UCI_APP" >/dev/null 2>&1
	_added=0; _failed=0; _total=0; _unsup=0; _schemes=""
	while IFS= read -r _ln; do
		[ -n "$_ln" ] || continue
		_total=$((_total + 1))
		case "$_ln" in
			vless://*|ss://*|hysteria2://*|hy2://*) ;;
			*)
				_unsup=$((_unsup + 1))
				_sc=${_ln%%://*}
				case " $_schemes " in
					*" $_sc "*) ;;
					*) _schemes="$_schemes $_sc" ;;
				esac
				continue
				;;
		esac
		_tag=$(server_add_from_link "$_ln" 2>&1)
		case "$_tag" in
			*' '*) _failed=$((_failed + 1)) ;;
			'')    _failed=$((_failed + 1)) ;;
			*)
				_sec=$(tag_to_section "$_tag")
				if [ -z "$_sec" ]; then
					_failed=$((_failed + 1))
				else
					# такой же сервер уже может быть в списке — тогда дубль не нужен
					_key=$(server_key "$_sec")
					_dup=""
					for _o in $(server_sections); do
						[ "$_o" = "$_sec" ] && continue
						[ "$(server_key "$_o")" = "$_key" ] && { _dup="$_o"; break; }
					done
					if [ -n "$_dup" ]; then
						uci -q delete "$UCI_APP.$_sec"
						_skipped=$((_skipped + 1))
					else
						_added=$((_added + 1))
						uci -q set "$UCI_APP.$_sec.sub=$_s"
					fi
				fi
				;;
		esac
	done < "$_links"
	uci -q set "$UCI_APP.$_s.updated=$(date '+%Y-%m-%d %H:%M:%S')"
	uci -q set "$UCI_APP.$_s.count=$_added"
	uci -q commit "$UCI_APP" >/dev/null 2>&1
	printf 'ссылок в подписке: %s, добавлено узлов: %s' "$_total" "$_added"
	[ "$_failed" -gt 0 ] && printf ', не разобрал: %s' "$_failed"
	[ "$_unsup" -gt 0 ] && printf ', не поддерживаю схемы:%s' "$_schemes"
	[ "${_skipped:-0}" -gt 0 ] && printf ', уже есть таких: %s' "$_skipped"
	return 0
}

# все подписки разом — для cron
dedup_servers() { # убрать серверы-дубликаты, оставляя первый
	_seen=""
	_removed=0
	for _s in $(server_sections); do
		_k=$(server_key "$_s")
		case "|$_seen|" in
			*"|$_k|"*)
				uci -q delete "$UCI_APP.$_s"
				_removed=$((_removed + 1))
				;;
			*) _seen="$_seen|$_k" ;;
		esac
	done
	uci -q commit "$UCI_APP" >/dev/null 2>&1
	printf '%s' "$_removed"
}

sub_update_all() {
	for _s in $(uci -q show "$UCI_APP" 2>/dev/null | sed -n 's/^xraypanel\.\([^.]*\)=sub$/\1/p'); do
		sub_update "$_s" >>"$STATE_DIR/sub.log" 2>&1
	done
}

# периодическая проверка узлов: строка в cron
## добавить/убрать своё задание в cron (метка, расписание, команда)
cron_set() { # $1 метка, $2 расписание (пусто = удалить), $3 команда
	_cf=/etc/crontabs/root
	[ -d /etc/crontabs ] || return 0
	[ -f "$_cf" ] || : > "$_cf" 2>/dev/null
	_tmp="$_cf.tmp.$$"
	# в подоболочке, чтобы сообщение об ошибке записи не попадало в журнал
	( grep -v "$1" "$_cf" > "$_tmp" ) 2>/dev/null
	if [ -n "$2" ]; then
		printf '%s %s # %s\n' "$2" "$3" "$1" >> "$_tmp"
	fi
	# если временный файл почему-то не создался (нет места, каталог только для
	# чтения) — не ругаемся в журнал, просто ничего не меняем
	[ -f "$_tmp" ] && mv -f "$_tmp" "$_cf" 2>/dev/null
	/etc/init.d/cron reload >/dev/null 2>&1 || /etc/init.d/cron restart >/dev/null 2>&1
}

# снимок статистики по выходам — каждые 5 минут, чтобы была видна история
cron_set_exits() {
	cron_set "xraypanel-exits" "*/5 * * * *" "/usr/lib/xraypanel/exits-sample.sh >/dev/null 2>&1"
}

cron_set_subs() { # $1 = период в часах (0 = выключить)
	if [ "${1:-0}" -gt 0 ] 2>/dev/null; then
		cron_set "xraypanel-subs" "0 */$1 * * *" "/usr/lib/xraypanel/sub-update.sh >/dev/null 2>&1"
	else
		cron_set "xraypanel-subs" "" ""
	fi
}

cron_set_urltest() { # $1 = интервал в минутах, 0 — выключить
	_cf=/etc/crontabs/root
	[ -d /etc/crontabs ] || return 0
	[ -f "$_cf" ] || : > "$_cf" 2>/dev/null
	_tmp="$_cf.tmp.$$"
	( grep -v "xraypanel-urltest" "$_cf" > "$_tmp" ) 2>/dev/null
	if [ "${1:-0}" -gt 0 ] 2>/dev/null; then
		printf '*/%s * * * * /usr/lib/xraypanel/urltest.sh >/dev/null 2>&1 # xraypanel-urltest\n' "$1" >> "$_tmp"
	fi
	[ -f "$_tmp" ] && mv -f "$_tmp" "$_cf" 2>/dev/null
	/etc/init.d/cron reload >/dev/null 2>&1 || /etc/init.d/cron restart >/dev/null 2>&1
}

# --- helpers для HTML --------------------------------------------------------
h() { printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'; }

# то же самое, но для текста из потока: cat file | h_in
h_in() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g'; }

# Раскодирование %XX: %XX -> восьмеричный \0ooo -> байт.
# Каждый байт декодируется отдельным printf: некоторые printf жадно съедают
# цифры, идущие следом за escape-последовательностью, и портят строку.
urldecode() {
	_in=$(printf '%s' "$1" | sed 's/+/ /g')
	_out=""
	while :; do
		case "$_in" in
			*%[0-9a-fA-F][0-9a-fA-F]*)
				_head=${_in%%\%*}
				_rest=${_in#*\%}
				_hex=${_rest%"${_rest#??}"}
				_in=${_rest#??}
				case "$_hex" in
					0a|0A) # перевод строки: подстановка команды съела бы его,
						_out="$_out$_head
" ;;
					0d|0D) _out="$_out$_head" ;;
					*) _out="$_out$_head$(printf '%b' "\\0$(printf '%03o' "$((0x$_hex))")")" ;;
				esac
				;;
			*)
				_out="$_out$_in"
				break
				;;
		esac
	done
	printf '%s' "$_out"
}

# --- гео-списки (geoip.dat / geosite.dat) -----------------------------------
# В этих файлах лежат готовые списки доменов (geosite) и адресов (geoip).
# Панель умеет показать их названия, чтобы не набирать руками.

# где xray ищет файлы: настройка панели, потом то, что задано в /etc/config/xray
# (там это ключ datadir, он же XRAY_LOCATION_ASSET), потом типовые места
geo_dirs() {
	_seen=""
	_d=$(cfg geo_dir "")
	[ -n "$_d" ] && { printf '%s\n' "$_d"; _seen="$_seen $_d"; }
	for _d in $(uci -q show xray 2>/dev/null | sed -n "s/^xray\.[^.]*\.datadir='\(.*\)'\$/\1/p"); do
		[ -n "$_d" ] || continue
		case " $_seen " in *" $_d "*) continue ;; esac
		_seen="$_seen $_d"
		printf '%s\n' "$_d"
	done
	for _d in /usr/share/xray /usr/share/v2ray /etc/xray /usr/share/xraypanel; do
		case " $_seen " in *" $_d "*) continue ;; esac
		_seen="$_seen $_d"
		printf '%s\n' "$_d"
	done
	_b=$(xray_bin 2>/dev/null); _b=$(dirname "$_b" 2>/dev/null)
	[ -n "$_b" ] && [ "$_b" != "/usr/bin" ] && printf '%s\n' "$_b"
}

# какие файлы со списками есть на роутере: печатает «путь<TAB>имя файла»
geo_files() {
	case "$1" in
		geosite) _names="geosite.dat dlc.dat iran.dat" ;;
		geoip)   _names="geoip.dat geoip_RU.dat geoip_IR.dat geoip_CN.dat" ;;
		*)       _names="geosite.dat geoip.dat" ;;
	esac
	_seen=""
	for _d in $(geo_dirs); do
		[ -d "$_d" ] || continue
		for _n in $_names; do
			_f="$_d/$_n"
			[ -f "$_f" ] || continue
			case " $_seen " in *" $_f "*) continue ;; esac
			_seen="$_seen $_f"
			printf '%s\t%s\n' "$_f" "$_n"
		done
	done
}

geo_tags_cache() { printf '%s/geo-tags.tsv' "$STATE_DIR"; }

# сколько названий нашлось из кэша: $1 = geosite|geoip
geo_tags_count() {
	_c=$(geo_tags_cache)
	[ -f "$_c" ] || { printf '0'; return 0; }
	awk -F'\t' -v t="$1" '$1 == t { n++ } END { print n + 0 }' "$_c" 2>/dev/null
}

# есть ли такое название в кэше (для проверки перед сохранением правила)
geo_tag_exists() { # $1 тип, $2 название
	_c=$(geo_tags_cache)
	[ -s "$_c" ] || return 1
	# xray сам приводит название к верхнему регистру, поэтому «ru» и «RU» —
	# это один и тот же список
	awk -F'\t' -v t="$1" -v v="$2" '
		$1 == t && toupper($2) == toupper(v) { found = 1 }
		END { exit !found }
	' "$_c" 2>/dev/null
}

# как название записано в файле (если отличается только регистром букв)
geo_tag_similar() { # $1 тип, $2 название -> печатает написание из файла
	_c=$(geo_tags_cache)
	[ -s "$_c" ] || return 0
	awk -F'\t' -v t="$1" -v v="$2" '
		$1 == t && toupper($2) == toupper(v) && $2 != v { print $2; exit }
	' "$_c" 2>/dev/null
}

# сколько названий дал каждый файл при последнем сборе (путь<TAB>вид<TAB>сколько)
geo_files_report() { # $1 вид (необязательно)
	_r="$STATE_DIR/geo-tags.files"
	[ -f "$_r" ] || return 0
	if [ -n "$1" ]; then
		awk -F'\t' -v k="$1" '$2 == k { print $1 "\t" $3 }' "$_r" 2>/dev/null
	else
		awk -F'\t' '{ print $1 "\t" $2 "\t" $3 }' "$_r" 2>/dev/null
	fi
}

# подпись набора файлов: по ней видно, что файлы обновились и названия надо
# собрать заново
geo_signature() {
	_sig=""
	for _k in geosite geoip; do
		for _pair in $(geo_files "$_k" | tr '\t' ':'); do
			_f=${_pair%%:*}
			_sig="$_sig${_k}:${_f}:$(wc -c <"$_f" 2>/dev/null):$(date -r "$_f" +%s 2>/dev/null);"
		done
	done
	printf '%s' "$_sig"
}

geo_cache_fresh() { # кэш собран для текущего набора файлов?
	[ -s "$(geo_tags_cache)" ] || return 1
	_s=$(cat "$STATE_DIR/geo-tags.sig" 2>/dev/null)
	[ -n "$_s" ] || return 1
	[ "$_s" = "$(geo_signature)" ]
}

# названия, в которых встречается введённое — подсказка, когда точного нет
geo_tag_search() { # $1 тип, $2 часть названия, $3 сколько показать (по умолчанию 8)
	_c=$(geo_tags_cache)
	[ -s "$_c" ] || return 0
	awk -F'\t' -v t="$1" -v v="$2" -v lim="${3:-8}" '
		$1 == t && v != "" && index(tolower($2), tolower(v)) > 0 {
			print $2; n++
			if (n >= lim) exit
		}
	' "$_c" 2>/dev/null
}

geo_cache_ready() { [ -s "$(geo_tags_cache)" ]; }

# локальная сеть роутера в виде 192.168.11.0/24 — для правила «вся сеть»
lan_subnet() {
	_ip=$(uci -q get network.lan.ipaddr 2>/dev/null)
	_nm=$(uci -q get network.lan.netmask 2>/dev/null)
	if [ -z "$_ip" ]; then
		_ip=$(ip -4 addr show 2>/dev/null | awk '/br-lan|eth0|lan/ { getline; sub(/.*inet /, ""); sub(/\/.*/, ""); print; exit }')
	fi
	[ -n "$_ip" ] || return 0
	case "$_ip" in *[!0-9.]*) return 0 ;; esac
	[ -n "$_nm" ] || _nm="255.255.255.0"
	awk -v ip="$_ip" -v nm="$_nm" 'BEGIN {
		split(ip, a, "."); split(nm, m, ".")
		if (a[1] == "" || m[1] == "") exit
		n = ((a[1] * 256 + a[2]) * 256 + a[3]) * 256 + a[4]
		mask = ((m[1] * 256 + m[2]) * 256 + m[3]) * 256 + m[4]
		bits = 0
		for (i = 31; i >= 0; i--) { if (int(mask / (2 ^ i)) % 2 == 1) bits++; else break }
		if (bits < 8 || bits > 30) exit
		size = 2 ^ (32 - bits)
		net = int(n / size) * size
		printf "%d.%d.%d.%d/%d", int(net / 16777216) % 256, int(net / 65536) % 256, int(net / 256) % 256, net % 256, bits
	}'
}

# фоновые задания панели: running | idle (используется в JSON для страниц)
job_state() { # $1 = имя задания
	[ -f "$STATE_DIR/$1.running" ] && printf 'running' || printf 'idle'
}

# --- проверка DNS ------------------------------------------------------------
# Запрос «как у клиентов» идёт в dnsmasq, а тот (когда включён перехват) — на
# локальный порт xray. Второй запрос — напрямую к резолверу: по нему видно,
# отвечает ли резолвер вообще и не подменяет ли ответы провайдер.
dns_lookup() { # $1 домен, $2 сервер (пусто = через роутер) -> «адрес<TAB>мс»
	_t0=$(cut -d' ' -f1 /proc/uptime 2>/dev/null)
	if [ -n "$2" ]; then
		_out=$(nslookup "$1" "$2" 2>&1)
	else
		_out=$(nslookup "$1" 2>&1)
	fi
	_t1=$(cut -d' ' -f1 /proc/uptime 2>/dev/null)
	_ms=$(awk -v a="${_t0:-0}" -v b="${_t1:-0}" 'BEGIN { printf "%d", (b - a) * 1000 }')
	# первая строка «Address:» — адрес самого сервера, ответ идёт следующим
	# (адресов может быть несколько — собираем все и приводим к одному порядку)
	_addr=$(printf '%s\n' "$_out" | awk '
		/^Address/ { sub(/.*Address:?[ \t]*/, ""); n++; if (n >= 2) print }
	' | LC_ALL=C sort -u | tr '\n' ',' | sed -e 's/,$//')
	printf '%s\t%s' "${_addr:-нет ответа}" "$_ms"
}

# куда фактически уходит DNS-запрос при текущих настройках
dns_effective_out() {
	_do=$(cfg dns_out "")
	_to=$(cfg transparent_out "")
	if [ -n "$_do" ]; then printf '%s' "$_do"; return 0; fi
	if [ -n "$_to" ] && [ "$_to" != auto ]; then printf '%s' "$_to"; return 0; fi
	if [ "$(cfg auto_best 0)" = 1 ]; then printf 'auto'; return 0; fi
	printf ''
}

# --- активность правил (лампочки на странице «Маршруты») ---------------------
# Xray пишет в журнал доступа строки вида
#   2026/09/17 12:00:00 from 192.168.11.111:23456 accepted tcp:youtube.com:443 [transparent -> 🇩🇪frankfurt]
# Оттуда видно: кто, куда, через какой выход и когда. Панель сопоставляет эти
# записи с правилами и зажигает зелёную лампочку у правила, которое работает.
# секунды по-человечески: «12 сек», «3 мин», «1 ч»
human_age() {
	case "${1:-}" in
		''|*[!0-9]*) printf 'давно'; return 0 ;;
	esac
	if [ "$1" -lt 60 ]; then printf '%s сек' "$1"
	elif [ "$1" -lt 3600 ]; then printf '%s мин' "$(( ${1} / 60 ))"
	else printf '%s ч' "$(( ${1} / 3600 ))"
	fi
}

server_ips() { # адреса всех наших серверов (выходов)
	for _s in $(uci -q show "$UCI_APP" 2>/dev/null | sed -n 's/^xraypanel\.\([^.]*\)=server$/\1/p'); do
		uci -q get "$UCI_APP.$_s.address" 2>/dev/null
	done | awk 'NF' | LC_ALL=C sort -u
}

own_ips() { # адреса самого роутера: loopback и его адреса в локальной сети
	{
		printf '127.0.0.1\n'
		ip -4 addr show 2>/dev/null | sed -n 's/.*inet \([0-9.]*\)\/.*/\1/p'
	} | awk 'NF' | LC_ALL=C sort -u
}

probe_hosts() { # хосты из адресов проверки (probe_url / url_test_url)
	for _u in "$(cfg probe_url "https://www.gstatic.com/generate_204")" "$(url_test_url 2>/dev/null)"; do
		[ -n "$_u" ] || continue
		printf '%s\n' "$_u" | sed -e 's#^[A-Za-z][A-Za-z0-9+.-]*://##' -e 's#/.*$##' -e 's#:.*$##'
	done | awk 'NF' | LC_ALL=C sort -u
}

rule_activity() { # печатает «источник<TAB>куда<TAB>выход<TAB>сколько секунд назад»
	_log="$(cfg log_dir "/var/log")/xray-access.log"
	[ -f "$_log" ] || return 0
	_now=$(date +%s 2>/dev/null)
	[ -n "$_now" ] || _now=0
	# Лампочки должны показывать настоящий трафик из интернета, а не служебную
	# беготню: проверки панели ходят на адрес probe_url, панель и SSH — на сам
	# роутер и в локальную сеть, а к серверам-выходам обращается сам xray.
	# Всё это отсекаем, иначе одна лампочка горит вечно.
	_filter=$(cfg lamp_filter 1)
	_skip=""; _probe=""
	if [ "$_filter" = 1 ]; then
		_probe=$(probe_hosts)
		_skip=$( { own_ips; server_ips; } | awk 'NF' | LC_ALL=C sort -u | tr '\n' ' ')
	fi
	tail -n 400 "$_log" 2>/dev/null | LC_ALL=C awk -v now="$_now" -v skip="$_skip" -v probe="$_probe" -v cntf="$STATE_DIR/lamp-skip.count" '
		BEGIN {
			n = split(skip, a, " ")
			for (i = 1; i <= n; i++) if (a[i] != "") skipip[a[i]] = 1
			m = split(probe, p, " ")
			for (i = 1; i <= m; i++) if (p[i] != "") probeh[p[i]] = 1
		}
		/ accepted / && /\[[^]]*[-=]+>[^]]*\]/ {
			split($1, d, "/"); split($2, t, ":")
			if (d[1] == "" || t[1] == "") next
			ep = mktime(d[1] " " d[2] " " d[3] " " t[1] " " t[2] " " t[3])
			if (ep <= 0) next
			age = now - ep
			if (age < 0) age = 0
			src = ""; dst = ""
			for (i = 1; i <= NF; i++) {
				# вид строки: «from <адрес>:<порт> accepted <куда>» либо, когда
				# соединение поднял сам xray, — «from  accepted <куда>» (источника
				# нет, и поле перед accepted — это слово from, а не адрес)
				if ($i == "accepted") {
					dst = $(i + 1)
					if (i > 1 && $(i - 1) != "from") { src = $(i - 1); sub(/:[0-9]+$/, "", src) }
				}
			}
			sub(/^(tcp|udp):/, "", dst)
			sub(/:[0-9]+$/, "", dst)
			out = ""; inb = ""
			if (match($0, /\[[^]]*[-=]+>[^]]*\]/)) {
				br = substr($0, RSTART, RLENGTH)
				sub(/^\[/, "", br); sub(/\]$/, "", br)
				np = split(br, parts, /[-=]+>[ \t]*/)
				inb = parts[1]; out = parts[np]
				gsub(/^[ \t]+/, "", inb); gsub(/[ \t]+$/, "", inb)
				gsub(/^[ \t]+/, "", out); gsub(/[ \t]+$/, "", out)
			}
			# служебные входы (перехват DNS и API) к правилам не относим
			if (inb == "dns-tunnel" || inb == "api") { skipped++; next }
			# пусто в skipip/probeh — значит фильтр выключен, и эти проверки
			# просто ничего не отсекают
			if (src == "" && (dst in probeh)) { skipped++; next }
			# у служебных записей самого xray вместо адреса стоит имя-метка
			# (например «reverse» — служебный канал реверс-моста): настоящий
			# адрес всегда содержит точку — имя сайта или IP
			if (src == "" && dst !~ /\./) { skipped++; next }
			if (dst in skipip) { skipped++; next }
			if (src in skipip) { skipped++; next }
			if (out == "" || dst == "") next
			print src "\t" dst "\t" out "\t" age
		}
		END { if (cntf != "") printf "%d\n", skipped > cntf }
	'
}

# какие правила недавно вели трафик: «раздел<TAB>сколько секунд назад<TAB>куда»
# Записи журнала распределяются по правилам сверху вниз — так же, как это
# делает сам xray: первое подошедшее правило и забирает соединение.
rules_activity() {
	_rf="$STATE_DIR/rules-activity.list"
	_af="$STATE_DIR/rules-activity.log"
	: > "$_rf"
	rule_conditions 2>/dev/null | while IFS="$(printf '\t')" read -r _r _s _t _v; do
		[ -n "$_r" ] || continue
		rule_disabled "$_r" && continue
		_o=$(uci -q get "$UCI_APP.$_r.outbound" 2>/dev/null)
		case "$_o" in ''|iface:*) continue ;; esac
		printf '%s\t%s\t%s\t%s\t%s\n' "$_r" "$_s" "$_t" "$_v" "$_o"
	done >> "$_rf"
	rule_activity > "$_af" 2>/dev/null
	if [ ! -s "$_af" ] || [ ! -s "$_rf" ]; then
		rm -f "$_rf" "$_af" 2>/dev/null
		return 0
	fi
	# имена сайтов для проверки правил: если запись запросов включена, обновляем
	# карту «адрес → имя» прямо здесь. Так имена остаются свежими и при «живом»
	# обновлении страниц (оно идёт раз в 10 секунд), а не только когда открыли
	# «Маршруты». Внутри у карты свой короткий кэш, так что часто это не считается.
	if [ "$(dns_log_state)" = on ]; then
		dns_log_pairs >/dev/null 2>&1
	fi
	LC_ALL=C awk -F'\t' -v mapf="$DNS_LOG_MAP" '
		BEGIN {
			# имена сайтов из журнала запросов dnsmasq: по адресу видно, что
			# это за сайт. Тогда правила по домену, слову и шаблону можно
			# проверить точно, а не «по выходу».
			while ((getline ln < mapf) > 0) {
				split(ln, mf, "\t")
				if (mf[1] != "" && mf[2] != "") byname[mf[1]] = mf[2]
			}
			close(mapf)
		}
		FNR == NR {
			n++
			r_sec[n] = $1; r_src[n] = $2; r_typ[n] = $3; r_val[n] = $4; r_out[n] = $5
			# «неточные» правила: готовые списки (geosite/geoip) целиком на
			# роутере не разбираем, а правило без условий подходит ко всему —
			# такие разбираем во вторую очередь
			r_weak[n] = (($3 == "geosite" || $3 == "geoip") || ($4 == "" && $2 == "")) ? 1 : 0
			next
		}
		function src_ok(i, s,   a, b, c) {
			if (r_src[i] == "") return 1
			if (s == r_src[i]) return 1
			# правило на всю сеть: сравниваем первые три числа адреса
			if (index(r_src[i], "/") > 0) {
				split(r_src[i], a, "/"); split(a[1], c, ".")
				split(s, b, ".")
				if (b[1] == c[1] && b[2] == c[2] && b[3] == c[3]) return 1
			}
			return 0
		}
		function val_ok(i, d,   tail, a, c, b) {
			# готовые списки (geosite/geoip) целиком на роутере не разбираем —
			# для них признак один: трафик ушёл через выход этого правила
			if (r_val[i] == "" || r_typ[i] == "geosite" || r_typ[i] == "geoip") return 1
			if (r_typ[i] == "full") return d == r_val[i]
			if (r_typ[i] == "keyword") return index(d, r_val[i]) > 0
			# шаблон проверяем только когда знаем имя сайта: иначе, как и
			# раньше, правило отмечается «по выходу»
			if (r_typ[i] == "regexp") {
				if (nm == "") return 1
				return match(d, r_val[i]) > 0
			}
			if (r_typ[i] == "domain") {
				if (d == r_val[i]) return 1
				tail = substr(d, length(d) - length(r_val[i]))
				return tail == "." r_val[i]
			}
			if (r_typ[i] == "ip") {
				if (d == r_val[i]) return 1
				if (index(r_val[i], "/") > 0) {
					split(r_val[i], a, "/"); split(a[1], c, ".")
					split(d, b, ".")
					if (b[1] == c[1] && b[2] == c[2] && b[3] == c[3]) return 1
				}
				return 0
			}
			return 1
		}
		{
			# имя сайта для этого адреса (если панель знает его из журнала
			# запросов dnsmasq). Для правил по домену, слову и шаблону
			# сравниваем именно имя, а не адрес.
			nm = byname[$2]
			claimed = 0
			for (pass = 0; pass <= 1 && !claimed; pass++) {
				for (i = 1; i <= n; i++) {
					if (r_weak[i] != pass) continue
					# у правила «по пингу» в журнале стоит тег выбранного сервера
				if (r_out[i] == "auto") {
						if ($3 == "direct" || $3 == "blocked") continue
					} else if ($3 != r_out[i]) continue
					if (!src_ok(i, $1)) continue
					dp = (nm != "" && r_typ[i] != "ip" && r_typ[i] != "geoip") ? nm : $2
					if (!val_ok(i, dp)) continue
					if (!(i in best) || $4 + 0 < best[i] + 0) { best[i] = $4; dest[i] = dp; out_tag[i] = $3 }
					cnt_dest[i "\t" dp]++
					claimed = 1
					break
				}
			}
		}
		END {
			for (i = 1; i <= n; i++) {
				if (!(i in best)) continue
				# до трёх самых частых адресов этого правила — по ним видно, что
				# именно оно поймало
				m = 0
				for (k in cnt_dest) {
					split(k, a, "\t")
					if (a[1] != i) continue
					m++; kk[m] = a[2]; vv[m] = cnt_dest[k]
				}
				for (x = 1; x <= m; x++)
					for (y = x + 1; y <= m; y++)
						if (vv[y] > vv[x]) {
							t = vv[x]; vv[x] = vv[y]; vv[y] = t
							t = kk[x]; kk[x] = kk[y]; kk[y] = t
						}
				top = ""
				for (x = 1; x <= m && x <= 3; x++) top = top (x > 1 ? ", " : "") kk[x] " (" vv[x] ")"
				print r_sec[i] "\t" best[i] "\t" dest[i] "\t" out_tag[i] "\t" top
			}
		}
	' "$_rf" "$_af" 2>/dev/null
	rm -f "$_rf" "$_af" 2>/dev/null
}

# сколько байт ушло через каждый выход, включая «direct» и «blocked»:
# «выход<TAB>отдано<TAB>получено», по убыванию общего объёма
exit_traffic() {
	outbound_stats | LC_ALL=C awk -F'\t' '
		{
			if ($2 == "uplink")   up[$1] += $3
			else if ($2 == "downlink") dn[$1] += $3
		}
		END {
			for (t in up) total[t] = up[t] + dn[t]
			for (n = 0; n < 200; n++) {
				best = ""
				for (t in total) {
					if (t in done) continue
					if (best == "" || total[t] > total[best]) best = t
				}
				if (best == "") break
				done[best] = 1
				printf "%s\t%d\t%d\n", best, up[best], dn[best]
			}
		}
	'
}

# Суммарный трафик: сначала «через туннель» (все выходы-серверы), потом
# «напрямую». Печатает четыре числа: туннель вверх, туннель вниз, прямо вверх,
# прямо вниз (в байтах, с момента последнего перезапуска xray).
traffic_totals() {
	exit_traffic 2>/dev/null | LC_ALL=C awk -F'\t' '
		$1 == "direct" || $1 == "blocked" { dup += $2; ddn += $3; next }
		NF >= 3 { tup += $2; tdn += $3 }
		END { printf "%d %d %d %d\n", tup, tdn, dup, ddn }'
}

# через какой выход идёт трафик каждого клиента: «адрес<TAB>выход<TAB>секунд назад<TAB>куда»
client_exits() { # $1 = за сколько секунд смотреть (по умолчанию 120)
	_win=${1:-120}
	rule_activity | LC_ALL=C awk -F'\t' -v win="$_win" '
		$1 != "" && $3 != "" && $4 + 0 <= win + 0 {
			key = $1 "\t" $3
			cnt[key]++
			if (!(key in last) || $4 + 0 < last[key] + 0) last[key] = $4 + 0
			if (!(key in d) || $4 + 0 <= dlast[key] + 0) { d[key] = $2; dlast[key] = $4 + 0 }
			ips[$1] = 1
		}
		END {
			for (ip in ips) {
				best = ""
				for (k in cnt) {
					split(k, a, "\t")
					if (a[1] != ip) continue
					if (best == "" || cnt[k] > cnt[best]) best = k
				}
				if (best != "") {
					split(best, a, "\t")
					printf "%s\t%s\t%s\t%s\n", ip, a[2], last[best], d[best]
				}
			}
		}
	'
}

# --- поиск домена в готовых списках (как проверка в PassWall) ----------------
# Ищем, в каких списках (geosite) встречается домен: печатает
# «список<TAB>совпавшая строка<TAB>тип». Результат запоминаем, чтобы повторная
# проверка того же домена отвечала сразу (разбор файла идёт пару секунд).
geo_find_lists() { # $1 = домен (в нижнем регистре)
	_q="$1"
	_lk="${XRAYPANEL_GEO_LOOKUP:-/usr/lib/xraypanel/geo-lookup.awk}"
	_cache="$STATE_DIR/geo-lookup.cache"
	[ -f "$_lk" ] || return 0
	if [ -s "$_cache" ]; then
		_hit=$(LC_ALL=C awk -F'\t' -v q="$_q" '$1 == q { print $2 "\t" $3 "\t" $4 }' "$_cache" 2>/dev/null)
		if [ -n "$_hit" ]; then
			case "$_hit" in
				-*) return 0 ;;
				*)  printf '%s\n' "$_hit"; return 0 ;;
			esac
		fi
	fi
	_res=""
	for _pair in $(geo_files geosite | tr '\t' ':'); do
		_f=${_pair%%:*}
		[ -f "$_f" ] || continue
		_r=$(LC_ALL=C awk -v q="$_q" -f "$_lk" "$_f" 2>/dev/null | LC_ALL=C sort -u)
		[ -n "$_r" ] && _res="$_res$_r
"
	done
	_res=$(printf '%s' "$_res" | LC_ALL=C sort -u | awk 'NF')
	if [ -n "$_res" ]; then
		printf '%s\n' "$_res" | while IFS= read -r _l; do
			printf '%s\t%s\n' "$_q" "$_l"
		done >> "$_cache" 2>/dev/null
	else
		printf '%s\t-\t-\t-\n' "$_q" >> "$_cache" 2>/dev/null
	fi
	printf '%s\n' "$_res" | awk 'NF'
}

# ответ для домена уже посчитан? (первый поиск идёт по большим файлам и долго,
# поэтому его запускают в фоне, а результат потом берут из кэша)
geo_lookup_cached() { # $1 = домен
	_c="$STATE_DIR/geo-lookup.cache"
	[ -s "$_c" ] || return 1
	LC_ALL=C awk -F'\t' -v q="$1" '$1 == q { f = 1; exit } END { exit !f }' "$_c" 2>/dev/null
}

# что входит в готовый список: печатает «домен<TAB>тип» и строку «#всего<TAB>N»
geo_list_domains() { # $1 = название списка, $2 = сколько строк тянуть из файла
	_nl=$(printf '%s' "$1" | tr 'A-Z' 'a-z')
	_lim=${2:-5000}
	_lk="${XRAYPANEL_GEO_LIST:-/usr/lib/xraypanel/geo-list.awk}"
	[ -f "$_lk" ] || return 0
	_cache="$STATE_DIR/geo-list.cache"
	if [ -s "$_cache" ]; then
		_hit=$(LC_ALL=C awk -F'\t' -v n="$_nl" '$1 == n { print $2 "\t" $3 }' "$_cache" 2>/dev/null)
		if [ -n "$_hit" ]; then
			printf '%s\n' "$_hit"
			printf '#всего\t%s\n' "$(printf '%s\n' "$_hit" | grep -c . )"
			return 0
		fi
	fi
	_body=""
	for _pair in $(geo_files geosite | tr '\t' ':'); do
		_f=${_pair%%:*}
		[ -f "$_f" ] || continue
		_r=$(LC_ALL=C awk -v name="$_nl" -v lim="$_lim" -f "$_lk" "$_f" 2>/dev/null | sed -e '/^#всего/d')
		[ -n "$_r" ] && _body="$_body$_r
"
	done
	_body=$(printf '%s\n' "$_body" | awk 'NF' | LC_ALL=C sort -u)
	_tot=$(printf '%s\n' "$_body" | grep -c . )
	# небольшие списки запоминаем, чтобы повторный просмотр отвечал сразу
	if [ "${_tot:-0}" -gt 0 ] && [ "${_tot:-0}" -le 3000 ]; then
		printf '%s\n' "$_body" | while IFS= read -r _l; do
			[ -n "$_l" ] && printf '%s\t%s\n' "$_nl" "$_l"
		done >> "$_cache" 2>/dev/null
	fi
	[ -n "$_body" ] && printf '%s\n' "$_body"
	printf '#всего\t%s\n' "${_tot:-0}"
}

# --- история по выходам (снимки раз в 5 минут) -------------------------------
# Файл: «время<TAB>активный выход<TAB>тег=вверх.вниз;тег=…». По нему видно,
# сколько трафика прошло через каждый сервер за сутки и как оно переключалось.
exits_history() { printf '%s/exits-history.tsv' "$STATE_DIR"; }

# сколько прибавилось по каждому выходу за время хранения истории
exits_period() {
	_h=$(exits_history)
	[ -s "$_h" ] || return 0
	# К истории добавляем свежие байты: снимок делается раз в 5 минут, а на
	# странице числа должны расти, пока на неё смотришь. Точка отсчёта —
	# первый снимок в окне, текущие значения берём прямо из статистики xray.
	_cur=$(exit_traffic 2>/dev/null)
	LC_ALL=C awk -F'\t' -v cur="$(printf '%s' "$_cur" | tr '\n' '~')" '
		BEGIN {
			n = split(cur, cs, "~")
			for (i = 1; i <= n; i++) {
				if (cs[i] == "") continue
				split(cs[i], c, "\t")
				c_up[c[1]] = c[2] + 0; c_dn[c[1]] = c[3] + 0
			}
		}
		{
			n = split($3, parts, ";")
			for (i = 1; i <= n; i++) {
				if (parts[i] == "") continue
				split(parts[i], a, "=")
				tag = a[1]
				if (tag == "") continue
				split(a[2], b, ".")
				up = b[1] + 0; dn = b[2] + 0
				if (!(tag in first_up)) { first_up[tag] = up; first_dn[tag] = dn }
				last_up[tag] = up; last_dn[tag] = dn
			}
		}
		END {
			for (tag in first_up) {
				du = c_up[tag] - first_up[tag]
				dd = c_dn[tag] - first_dn[tag]
				# счётчики xray сбросились (служба перезапускалась) — считаем с начала
				if (du < 0 || dd < 0) { du = c_up[tag]; dd = c_dn[tag] }
				if (du + dd > 0) printf "%s\t%d\t%d\n", tag, du, dd
			}
			# выходы, которых в истории ещё не было
			for (tag in c_up)
				if (!(tag in first_up) && c_up[tag] + c_dn[tag] > 0)
					printf "%s\t%d\t%d\n", tag, c_up[tag], c_dn[tag]
		}
	' "$_h"
}

# как выход переключался: «🇩🇪frankfurt 15:00–15:25 · 🇩🇪berlin 15:25–15:40 · …»
exits_timeline() { # $1 = сколько последних снимков смотреть (по умолчанию 72 ≈ 6 часов)
	_h=$(exits_history)
	[ -s "$_h" ] || return 0
	_n=${1:-72}
	tail -n "$_n" "$_h" 2>/dev/null | LC_ALL=C awk -F'\t' '
		{
			t = $1 + 0
			act = ($2 == "") ? "нет данных" : $2
			if (NR == 1) { start = t; cur = act; next }
			if (act != cur) {
				printf "%s-%s %s · ", strftime("%H:%M", start), strftime("%H:%M", t), cur
				start = t; cur = act
			}
		}
		END { if (cur != "") printf "%s-сейчас %s", strftime("%H:%M", start), cur }
	'
}

# что ходило через каждый выход по журналу: «сколько<TAB>выход<TAB>куда»
exit_domains() { # $1 = за сколько секунд смотреть (по умолчанию 600)
	_win=${1:-600}
	rule_activity | LC_ALL=C awk -F'\t' -v win="$_win" '
		$3 != "" && $2 != "" && $4 + 0 <= win + 0 { c[$3 "\t" $2]++ }
		END { for (k in c) printf "%d\t%s\n", c[k], k }
	' | LC_ALL=C sort -rn | head -60
}

# что именно уходит в xray по каждому правилу — для разбора «почему не работает»
rules_matcher_dump() {
	for _r in $(rule_sections); do
		_parts=$(rule_parts "$_r")
		_s=$(printf '%s' "$_parts" | cut -f1)
		_t=$(printf '%s' "$_parts" | cut -f2)
		_v=$(printf '%s' "$_parts" | cut -f3)
		_o=$(uci -q get "$UCI_APP.$_r.outbound" 2>/dev/null)
		_off=""
		[ "$(uci -q get "$UCI_APP.$_r.disabled" 2>/dev/null)" = 1 ] && _off="  (выключено)"
		_line="$_r:"
		[ -n "$_s" ] && _line="$_line source=[$_s]"
		if [ -n "$_v" ]; then
			_mv=$(rule_matcher_value "$_t" "$_v")
			case "$_t" in
				ip|geoip) _key="ip" ;;
				*)        _key="domain" ;;
			esac
			_line="$_line  $_key=[\"$_mv\"]"
		fi
		printf '%s -> %s%s\n' "$_line" "${_o:-не задан}" "$_off"
	done
}

# через какой сервер трафик идёт прямо сейчас: «тег<TAB>сколько секунд назад»
# (по свежим записям журнала; «direct» и служебные входы не считаются)
active_server_now() {
	rule_activity | LC_ALL=C awk -F'\t' '
		$3 != "" && $3 != "direct" && $3 != "blocked" {
			if ($4 + 0 <= 120) {
				cnt[$3]++
				if (!($3 in last) || $4 + 0 < last[$3] + 0) last[$3] = $4 + 0
			}
		}
		END {
			for (t in cnt) {
				if (best == "" || cnt[t] > cnt[best] || (cnt[t] == cnt[best] && last[t] < last[best])) best = t
			}
			if (best != "") printf "%s\t%s", best, last[best]
		}
	'
}
