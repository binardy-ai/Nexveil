#!/bin/sh
# Прозрачный режим xraypanel: правила фаервола, заворачивающие трафик в xray.
#
# Запуск: transparent.sh on|off|keep|status|restore
#   on      — поставить правила и включить автооткат (по умолчанию 2 минуты)
#   keep    — подтвердить: правила остаются, автооткат отменяется
#   off     — снять правила (интернет возвращается как было)
#   restore — поставить правила, если режим включён в настройках (автозапуск)
#   status  — напечатать on или off

PATH="${XRAYPANEL_PATH:-/usr/sbin:/usr/bin:/sbin:/bin}"

UCI_APP=xraypanel
STATE_DIR="${XRAYPANEL_STATE:-/etc/xraypanel}"
TABLE="xraypanel"
SELF="${XRAYPANEL_TRANSPARENT:-/usr/lib/xraypanel/transparent.sh}"
KEEP="$STATE_DIR/transparent.keep"
DEADLINE="$STATE_DIR/transparent.deadline"
GENF="$STATE_DIR/transparent.gen"
REVERT="${XRAYPANEL_REVERT:-300}"
LIBFILE="${XRAYPANEL_LIB:-/usr/lib/xraypanel/lib.sh}"
# почему снимаем правила: shutdown — это штатное выключение роутера, тогда
# правила вернутся сами при загрузке, и писать «трафик идёт как обычно» нельзя
OFF_REASON="${XRAYPANEL_OFF_REASON:-}"

cfg() { uci -q get "$UCI_APP.settings.$1" 2>/dev/null; }

LOGF="$STATE_DIR/transparent.log"
STATUS="$STATE_DIR/transparent.last"

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOGF" 2>/dev/null; }
status_write() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >"$STATUS" 2>/dev/null; }

# nft с записью в журнал: видно каждую команду и текст ошибки
nftr() {
	log "nft $*"
	_out=$(nft "$@" 2>&1); _rc=$?
	[ -n "$_out" ] && log "$_out"
	if [ "$_rc" != 0 ]; then
		_last_err="nft $* -> $_out"
		log "ОШИБКА на шаге: nft $*"
		return 1
	fi
	return 0
}

iptr() {
	log "iptables $*"
	_out=$(iptables "$@" 2>&1); _rc=$?
	[ -n "$_out" ] && log "$_out"
	if [ "$_rc" != 0 ]; then
		_last_err="iptables $* -> $_out"
		log "ОШИБКА на шаге: iptables $*"
		return 1
	fi
	return 0
}

# необязательные правила (блокировка QUIC): если не получились — просто пишем
# в журнал и продолжаем, перехват из-за них падать не должен
nftr_soft() {
	log "nft $*"
	_out=$(nft "$@" 2>&1); _rc=$?
	[ -n "$_out" ] && log "$_out"
	[ "$_rc" != 0 ] && log "предупреждение: не удалось (не критично): nft $*"
	return 0
}

# Правила «через интерфейс …» панель выполняет не в xray, а в ядре
# (ip rule + своя таблица маршрутов). Но пакет, попавший в перехватчик
# (redirect в nat prerouting), до маршрутизации уже не дойдёт — его адрес
# подменён на адрес роутера. Поэтому такие потоки надо «отпустить» в nft
# раньше, чем сработает redirect: тогда ядро само отправит их в нужный
# интерфейс. Иначе правило «через интерфейс» не работает, пока включён прокси.
iface_returns() { # $1 = pre|out
	. "$LIBFILE" 2>/dev/null
	for _r in $(rule_sections); do
		rule_disabled "$_r" && continue
		case "$(uci -q get "$UCI_APP.$_r.outbound" 2>/dev/null)" in
			iface:*) ;;
			*) continue ;;
		esac
		_parts=$(rule_parts "$_r")
		_rs=$(printf '%s' "$_parts" | cut -f1)
		_rv=$(printf '%s' "$_parts" | cut -f3)
		# в ip rule адрес должен быть одним: сети и домены тут не годятся
		case "$_rs$_rv" in
			''|*/*|*[!0-9.]*) continue ;;
		esac
		if [ "$1" = out ]; then
			# у трафика самого роутера источник ещё не выбран, смотрим только «куда»
			[ -n "$_rs" ] && continue
			nftr_soft add rule ip "$TABLE" out ip daddr "$_rv" return
		elif [ -n "$_rs" ] && [ -n "$_rv" ]; then
			nftr_soft add rule ip "$TABLE" pre ip saddr "$_rs" ip daddr "$_rv" return
		elif [ -n "$_rs" ]; then
			nftr_soft add rule ip "$TABLE" pre ip saddr "$_rs" return
		else
			nftr_soft add rule ip "$TABLE" pre ip daddr "$_rv" return
		fi
	done
}

# Счётчики трафика по клиентам. Живут в отдельных цепочках — и вот почему:
# если правило-счётчик поставить в ту же цепочку, что и перехватчик, оно
# окажется ЗА правилом redirect, а после redirect цепочка дальше не идёт.
# В итоге счётчики не видели ни одного пакета (жалоба «трафик клиента не
# считается»). Отдельная цепочка только считает и ничего не решает: политика
# accept, никаких вердиктов. Плюс так считается и тот трафик, который уходит
# мимо прокси — по правилам «через интерфейс».
client_counters() { # $1 — адреса клиентов (через запятую или с новой строки)
	# Пусто или не передано — «все клиенты» (режимы «вся сеть» и «роутер и
	# сеть»): адреса заранее неизвестны, поэтому считаем наборами со
	# счётчиками, куда адрес попадает сам, как только с него пошёл трафик.
	# Список передан — режим «только адреса из списка»: считаем ровно эти
	# адреса, иначе в трафик попали бы устройства, которых мы не заворачиваем.
	_cl=$(printf '%s' "$1" | tr ',' ' ')
	# «вверх»: пакеты от клиентов. Приоритет -150 — раньше перехватчика,
	# чтобы попало всё, включая то, что потом уйдёт в свой интерфейс.
	nftr_soft add chain ip "$TABLE" ctr '{ type filter hook prerouting priority -150 ; policy accept ; }'
	nftr_soft add rule ip "$TABLE" ctr ip daddr "{ $_nets }" return
	[ -n "$_srv_ip" ] && nftr_soft add rule ip "$TABLE" ctr ip daddr "{ $_srv_ip }" return
	# «вниз»: ответы клиентам, которые идут транзитом (мимо прокси)
	nftr_soft add chain ip "$TABLE" ctrd '{ type filter hook forward priority 1 ; policy accept ; }'
	# «вниз» для прокси: ответы отдаёт сам xray, они уходят через output
	nftr_soft add chain ip "$TABLE" outf '{ type filter hook output priority 0 ; policy accept ; }'
	if [ -n "$(printf '%s' "$_cl" | tr -d ' ')" ]; then
		for _c in $_cl; do
			[ -n "$_c" ] || continue
			nftr_soft add rule ip "$TABLE" ctr  ip saddr "$_c" meta l4proto tcp counter
			nftr_soft add rule ip "$TABLE" ctrd ip daddr "$_c" meta l4proto tcp counter
			nftr_soft add rule ip "$TABLE" outf ip daddr "$_c" meta l4proto tcp counter
		done
	else
		# Наборы со счётчиками. Важная проверенная на роутере деталь: набор с
		# одним флагом dynamic (даже с timeout) сам НЕ наполняется — nftables
		# 1.0.8 элементы не добавляет. Поэтому в правиле стоит `update @набор
		# { адрес }`: он и заводит адрес, и считает его байты. Timeout нужен,
		# чтобы адрес не висел вечно; при простое больше недели счётчик по нему
		# начнётся заново.
		nftr_soft add set ip "$TABLE" cli4 '{ type ipv4_addr ; flags dynamic ; timeout 7d ; size 4096 ; counter ; }'
		nftr_soft add set ip "$TABLE" cli4dn '{ type ipv4_addr ; flags dynamic ; timeout 7d ; size 4096 ; counter ; }'
		nftr_soft add rule ip "$TABLE" ctr iifname { $IF_LIST } meta l4proto tcp update @cli4 { ip saddr }
		nftr_soft add rule ip "$TABLE" ctrd oifname { $IF_LIST } meta l4proto tcp update @cli4dn { ip daddr }
		nftr_soft add rule ip "$TABLE" outf oifname { $IF_LIST } meta l4proto tcp update @cli4dn { ip daddr }
	fi
	return 0
}

PORT=$(cfg transparent_port); [ -n "$PORT" ] || PORT=12345
SCOPE=$(cfg transparent_scope); [ -n "$SCOPE" ] || SCOPE="lan"
CLIENTS=$(cfg transparent_clients)
LAN_IF=$(cfg transparent_iface); [ -n "$LAN_IF" ] || LAN_IF="br-lan"
# интерфейсов может быть несколько: "br-lan wan", "br-lan,guest"
IF_LIST=$(printf '%s' "$LAN_IF" | tr ', ' '\n' | awk 'NF {gsub(/"/, ""); if (n++) s = s ", "; s = s "\"" $0 "\""} END {print s}')
[ -n "$IF_LIST" ] || IF_LIST='"br-lan"'
DNS_TUNNEL=$(cfg dns_tunnel); [ -n "$DNS_TUNNEL" ] || DNS_TUNNEL=0
# DNS самого роутера (dnsmasq) — отдельная задача: её можно включить или
# выключить независимо от перехвата DNS у клиентов
DNS_ROUTER=$(cfg dns_router); [ -n "$DNS_ROUTER" ] || DNS_ROUTER=$DNS_TUNNEL
DNS_PORT=$(cfg dns_port); [ -n "$DNS_PORT" ] || DNS_PORT=5353
# куда заворачивать DNS клиентов: в xray (туннель) или в роутерный резолвер
# (тогда запросы попадают на dnsmasq и он сам выбирает, куда их отправить —
# при мёртвом туннеле уходит на другие серверы из своего списка)
DNS_CLIENT_VIA=$(cfg dns_client_via); [ -n "$DNS_CLIENT_VIA" ] || DNS_CLIENT_VIA=xray
# Заставляем клиентов пользоваться нашим DNS: закрываем шифрованный DNS,
# иначе «приватный DNS» на телефоне (DoT, порт 853) или DoH в браузере
# уводят запросы мимо перехвата.
BLOCK_DOT=$(cfg block_dot 1); [ -n "$BLOCK_DOT" ] || BLOCK_DOT=1
BLOCK_DOH=$(cfg block_doh 0); [ -n "$BLOCK_DOH" ] || BLOCK_DOH=0
DOH_LIST=$(cfg doh_block_list "1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4 9.9.9.9 9.9.9.10 94.140.14.14 94.140.15.15 208.67.222.222 208.67.220.220 76.76.2.0 76.76.10.0 185.228.168.9 185.228.169.9 156.154.70.1 156.154.71.1")
DOH_SET=$(printf '%s' "$DOH_LIST" | tr ', ' '\n' | awk 'NF {gsub(/"/, ""); if (n++) s = s ", "; s = s $0} END {print s}')
DNS_MARK=83
DNS_TABLE=83

has_nft() { command -v nft >/dev/null 2>&1; }

# --- nftables (OpenWrt 23.05 и новее, фаервол fw4) --------------------------
nft_off() { # удаляем только если таблица есть: иначе nft ругается «No such file»
	nft list table ip "$TABLE" >/dev/null 2>&1 || return 0
	nftr delete table ip "$TABLE" >/dev/null 2>&1
}

# TPROXY требует, чтобы пакеты с меткой обрабатывались локально
dns_routes_on() {
	# добавляем только если такого правила ещё нет — иначе они копятся
	if ! ip rule show 2>/dev/null | grep -q "lookup $DNS_TABLE"; then
		ip rule add fwmark "$DNS_MARK" lookup "$DNS_TABLE" 2>/dev/null
		ip rule show 2>/dev/null | grep -q "lookup $DNS_TABLE" || \
			ip rule add fwmark "$DNS_MARK" table "$DNS_TABLE" 2>/dev/null
	fi
	if ! ip route show table "$DNS_TABLE" 2>/dev/null | grep -q "^local"; then
		ip route add local 0.0.0.0/0 dev lo table "$DNS_TABLE" 2>/dev/null
		ip route show table "$DNS_TABLE" 2>/dev/null | grep -q "^local" || \
			ip route add local default dev lo table "$DNS_TABLE" 2>/dev/null
	fi
	# проверяем, что маршрутизация для TPROXY действительно встала
	_r=no; _t=no
	ip rule show 2>/dev/null | grep -q "lookup $DNS_TABLE" && _r=yes
	ip route show table "$DNS_TABLE" 2>/dev/null | grep -q "^local" && _t=yes
	if [ "$_r" = yes ] && [ "$_t" = yes ]; then
		log "маршрутизация TPROXY готова (fwmark $DNS_MARK -> таблица $DNS_TABLE)"
	else
		log "ВНИМАНИЕ: маршрутизация TPROXY не встала (правило: $_r, маршрут: $_t) — DNS не будет доставлен в xray"
	fi
}

dns_routes_off() {
	# убираем все правила, включая дубли от прежних включений
	_n=0
	while ip rule show 2>/dev/null | grep -q "lookup $DNS_TABLE"; do
		ip rule del fwmark "$DNS_MARK" lookup "$DNS_TABLE" 2>/dev/null || break
		_n=$((_n + 1))
		[ "$_n" -ge 20 ] && break
	done
	ip route del local 0.0.0.0/0 dev lo table "$DNS_TABLE" 2>/dev/null
	ip route del local default dev lo table "$DNS_TABLE" 2>/dev/null
}

nft_on() {
	nft_off
	# таблица в семействе ip: так проще и совместимее, чем inet
	nftr add table ip "$TABLE" || return 1
	_nets='0.0.0.0/8, 10.0.0.0/8, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/4'
	# для DNS исключения другие: клиенты спрашивают имена у самого роутера
	# (192.168.x.1), и это как раз нужно перехватывать. Не трогаем только
	# localhost, мультикаст и широковещание.
	_dns_nets='0.0.0.0/8, 127.0.0.0/8, 224.0.0.0/4, 255.255.255.255/32'
	# адреса наших серверов (включая портал реверса) не заворачиваем: иначе
	# туннель сам себя загоняет в прокси и рвётся, если сервер не отвечает
	_srv_ip=""
	for _sec in $(uci -q show "$UCI_APP" 2>/dev/null | sed -n 's/^xraypanel\.\([^.]*\)=server$/\1/p'); do
		_a=$(uci -q get "$UCI_APP.$_sec.address")
		case "$_a" in
			''|*[!0-9.]*) continue ;;
		esac
		# один и тот же адрес может встречаться у нескольких серверов
		case ",$_srv_ip," in
			*",$_a,"*) continue ;;
		esac
		if [ -z "$_srv_ip" ]; then _srv_ip="$_a"; else _srv_ip="$_srv_ip, $_a"; fi
	done
	[ -n "$_srv_ip" ] && log "адреса серверов не заворачиваем: $_srv_ip"

	# цепочки для трафика клиентов сети — только если он нужен
	case "$SCOPE" in
		lan|both|list)
			nftr add chain ip "$TABLE" pre '{ type nat hook prerouting priority dstnat ; }' || return 1
			# QUIC (UDP 443) заворачивать не умеем: блокируем его завёрнутым
			# клиентам, чтобы браузер сам перешёл на обычный TCP через прокси
			nftr_soft add chain ip "$TABLE" fw '{ type filter hook forward priority 0 ; }'
			# локальная сеть и сам роутер (его адреса приватные) — мимо
			nftr add rule ip "$TABLE" pre ip daddr "{ $_nets }" return || return 1
			[ -n "$_srv_ip" ] && { nftr add rule ip "$TABLE" pre ip daddr "{ $_srv_ip }" return || return 1; }
			# соединения самого xray помечены меткой 255 — их не заворачиваем
			nftr add rule ip "$TABLE" pre meta mark 255 return || return 1
			# потоки, которые должны уйти в свой интерфейс (правила «через
			# интерфейс …») — отпускаем до redirect, см. iface_returns
			iface_returns pre
			;;
	esac
	# цепочки для трафика самого роутера
	case "$SCOPE" in
		router|both)
			# для hook output имя приоритета «dstnat» nft не принимает
			# (invalid priority expression) — пишем числом: -100 = dstnat
			nftr add chain ip "$TABLE" out '{ type nat hook output priority -100 ; }' || return 1
			nftr_soft add chain ip "$TABLE" outf '{ type filter hook output priority 0 ; }'
			nftr add rule ip "$TABLE" out ip daddr "{ $_nets }" return || return 1
			[ -n "$_srv_ip" ] && { nftr add rule ip "$TABLE" out ip daddr "{ $_srv_ip }" return || return 1; }
			nftr add rule ip "$TABLE" out meta mark 255 return || return 1
			iface_returns out
			;;
	esac

	# если DNS-перехват включён, 53-й порт обрабатывает отдельная цепочка dns,
	# и общий заворот его не трогает
	_dns_guard=0
	[ "$DNS_TUNNEL" = 1 ] && [ "$DNS_PORT" != "$PORT" ] && _dns_guard=1

	case "$SCOPE" in
		lan)
			[ "$_dns_guard" = 1 ] && nftr_soft add rule ip "$TABLE" pre ct status dnat return
			# учёт трафика по клиентам — отдельными цепочками, чтобы счётчики
			# не оказались за перехватчиком (там они ничего не видят)
			. "$LIBFILE" 2>/dev/null
			# без списка = «все клиенты»: считаются и DHCP, и статика, и новые
			client_counters ""
			nftr add rule ip "$TABLE" pre iifname { $IF_LIST } meta l4proto tcp counter redirect to :"$PORT" || return 1
			nftr_soft add rule ip "$TABLE" fw iifname { $IF_LIST } udp dport 443 drop
			[ "$DNS_TUNNEL" = 1 ] && [ "$BLOCK_DOT" = 1 ] && {
				nftr_soft add rule ip "$TABLE" fw iifname { $IF_LIST } tcp dport 853 drop
				nftr_soft add rule ip "$TABLE" fw iifname { $IF_LIST } udp dport 853 drop
			}
			[ "$BLOCK_DOH" = 1 ] && [ -n "$DOH_SET" ] && \
				nftr_soft add rule ip "$TABLE" fw iifname { $IF_LIST } ip daddr "{ $DOH_SET }" tcp dport 443 drop
			;;
		list)
			# пустой список = заворачивать некого: говорим об этом прямо,
			# иначе непонятно, почему режим не поднялся
			[ -n "$CLIENTS" ] || { log "режим «только клиенты из списка», а список пуст — отметьте клиентов в панели"; return 1; }
			[ "$_dns_guard" = 1 ] && nftr_soft add rule ip "$TABLE" pre ct status dnat return
			# счётчики — в отдельных цепочках (иначе за перехватчиком их не видно)
			client_counters "$CLIENTS"
			# по одному правилу перехвата на клиента
			for _c in $(printf '%s' "$CLIENTS" | tr ',' ' '); do
				[ -n "$_c" ] || continue
				nftr add rule ip "$TABLE" pre ip saddr "$_c" meta l4proto tcp redirect to :"$PORT" || return 1
				nftr_soft add rule ip "$TABLE" fw ip saddr "$_c" udp dport 443 drop
				if [ "$DNS_TUNNEL" = 1 ] && [ "$BLOCK_DOT" = 1 ]; then
					nftr_soft add rule ip "$TABLE" fw ip saddr "$_c" tcp dport 853 drop
					nftr_soft add rule ip "$TABLE" fw ip saddr "$_c" udp dport 853 drop
				fi
				[ "$BLOCK_DOH" = 1 ] && [ -n "$DOH_SET" ] && \
					nftr_soft add rule ip "$TABLE" fw ip saddr "$_c" ip daddr "{ $DOH_SET }" tcp dport 443 drop
			done ;;
		both)
			[ "$_dns_guard" = 1 ] && nftr_soft add rule ip "$TABLE" pre ct status dnat return
			. "$LIBFILE" 2>/dev/null
			# без списка = «все клиенты»: считаются и DHCP, и статика, и новые
			client_counters ""
			nftr add rule ip "$TABLE" pre iifname { $IF_LIST } meta l4proto tcp counter redirect to :"$PORT" || return 1
			nftr_soft add rule ip "$TABLE" fw iifname { $IF_LIST } udp dport 443 drop
			[ "$DNS_TUNNEL" = 1 ] && [ "$BLOCK_DOT" = 1 ] && {
				nftr_soft add rule ip "$TABLE" fw iifname { $IF_LIST } tcp dport 853 drop
				nftr_soft add rule ip "$TABLE" fw iifname { $IF_LIST } udp dport 853 drop
			}
			[ "$BLOCK_DOH" = 1 ] && [ -n "$DOH_SET" ] && \
				nftr_soft add rule ip "$TABLE" fw iifname { $IF_LIST } ip daddr "{ $DOH_SET }" tcp dport 443 drop
			[ "$_dns_guard" = 1 ] && nftr_soft add rule ip "$TABLE" out ct status dnat return
			nftr add rule ip "$TABLE" out meta l4proto tcp counter redirect to :"$PORT" || return 1
			nftr_soft add rule ip "$TABLE" outf udp dport 443 drop
			[ "$DNS_TUNNEL" = 1 ] && [ "$BLOCK_DOT" = 1 ] && {
				nftr_soft add rule ip "$TABLE" outf tcp dport 853 drop
				nftr_soft add rule ip "$TABLE" outf udp dport 853 drop
			}
			[ "$BLOCK_DOH" = 1 ] && [ -n "$DOH_SET" ] && \
				nftr_soft add rule ip "$TABLE" outf ip daddr "{ $DOH_SET }" tcp dport 443 drop
			;;
		router)
			[ "$_dns_guard" = 1 ] && nftr_soft add rule ip "$TABLE" out ct status dnat return
			nftr add rule ip "$TABLE" out meta l4proto tcp counter redirect to :"$PORT" || return 1
			nftr_soft add rule ip "$TABLE" outf udp dport 443 drop
			[ "$DNS_TUNNEL" = 1 ] && [ "$BLOCK_DOT" = 1 ] && {
				nftr_soft add rule ip "$TABLE" outf tcp dport 853 drop
				nftr_soft add rule ip "$TABLE" outf udp dport 853 drop
			}
			[ "$BLOCK_DOH" = 1 ] && [ -n "$DOH_SET" ] && \
				nftr_soft add rule ip "$TABLE" outf ip daddr "{ $DOH_SET }" tcp dport 443 drop
			;;
	esac

	# Перехват DNS-запросов клиентов (53-й порт) и передача их в xray.
	# Раньше здесь был TPROXY, и он давал неприятный эффект: xray отвечал
	# клиенту со своего порта (5353), а клиент ждёт ответ с того адреса и порта,
	# куда сам спрашивал (192.168.x.x:53) — и молча выбрасывает ответ.
	# Поэтому делаем redirect (DNAT): conntrack сам вернёт адрес отправителя
	# ответа к исходному, как это уже работает для обычного трафика.
	# Куда заворачивать: в xray (порт туннеля) или в роутерный резолвер (53).
	_dns_target="$DNS_PORT"
	[ "$DNS_CLIENT_VIA" = router ] && _dns_target=53
	if [ "$DNS_TUNNEL" = 1 ]; then
		case "$SCOPE" in
			lan|both|list)
				# правила TPROXY от прежних версий панели убираем — они больше не нужны
				dns_routes_off
				nftr add chain ip "$TABLE" dns '{ type nat hook prerouting priority -110 ; }' || return 1
				nftr add rule ip "$TABLE" dns meta mark 255 return || return 1
				nftr add rule ip "$TABLE" dns ip daddr "{ $_dns_nets }" return || return 1
				[ -n "$_srv_ip" ] && { nftr add rule ip "$TABLE" dns ip daddr "{ $_srv_ip }" return || return 1; }
				if [ "$SCOPE" = "list" ]; then
					[ -n "$CLIENTS" ] || return 1
					for _proto in udp tcp; do
						nftr add rule ip "$TABLE" dns ip saddr "{ $CLIENTS }" "$_proto" dport 53 counter redirect to :"$_dns_target" || return 1
					done
				else
					for _proto in udp tcp; do
						nftr add rule ip "$TABLE" dns iifname { $IF_LIST } "$_proto" dport 53 counter redirect to :"$_dns_target" || return 1
					done
				fi
				if [ "$DNS_CLIENT_VIA" = router ]; then
					log "перехват DNS включён: порт 53 -> роутерный резолвер (с откатом на другие серверы)"
				else
					log "перехват DNS включён: порт 53 -> $DNS_PORT -> туннель (redirect)"
				fi
				;;
		esac
		# DNS самого роутера правилами не заворачиваем: у локально созданных
		# запросов ответ приходит с другого адреса (127.0.0.1:порт xray) и для
		# резолвера выглядит чужим — он его выбрасывает. Вместо этого dnsmasq
		# переводится на локальный порт xray (см. dnsmasq_tunnel_on ниже).
	fi
	# маршруты через интерфейс ставим и здесь: правила панели могли поменяться
	# без «Применить конфиг», а без них nft вернёт трафик в обычную таблицу,
	# где маршрута через нужный интерфейс ещё нет
	. "$LIBFILE" 2>/dev/null && iface_routes_apply >/dev/null 2>&1
	return 0
}

# --- iptables (старые сборки OpenWrt) --------------------------------------
ipt_chain() { # $1 цепочка, $2 "pre"|"out"
	iptr -t nat -N "$1" 2>/dev/null
	iptr -t nat -F "$1"
	iptr -t nat -A "$1" -m addrtype --dst-type LOCAL -j RETURN
	for _n in 0.0.0.0/8 10.0.0.0/8 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16 224.0.0.0/4; do
		iptr -t nat -A "$1" -d "$_n" -j RETURN
	done
	iptr -t nat -A "$1" -m mark --mark 255 -j RETURN
	case "$2" in
		pre)
			case "$SCOPE" in
				lan|both) for _if in $(printf '%s' "$LAN_IF" | tr ', ' '\n' | awk 'NF'); do
						iptr -t nat -A "$1" -i "$_if" -p tcp -j REDIRECT --to-ports "$PORT"
					done ;;
				list)     for _ip in $CLIENTS; do iptr -t nat -A "$1" -s "$_ip" -p tcp -j REDIRECT --to-ports "$PORT"; done ;;
			esac ;;
		out)
			case "$SCOPE" in
				router|both) iptr -t nat -A "$1" -p tcp -j REDIRECT --to-ports "$PORT" ;;
			esac ;;
	esac
}

ipt_on() {
	iptr -t nat -N XRAYTP_PRE 2>/dev/null
	iptr -t nat -N XRAYTP_OUT 2>/dev/null
	ipt_chain XRAYTP_PRE pre
	ipt_chain XRAYTP_OUT out
	iptr -t nat -C PREROUTING -j XRAYTP_PRE 2>/dev/null || iptr -t nat -A PREROUTING -j XRAYTP_PRE
	iptr -t nat -C OUTPUT -j XRAYTP_OUT 2>/dev/null || iptr -t nat -A OUTPUT -j XRAYTP_OUT
	# блокировка QUIC (UDP 443), иначе браузеры обходят прокси по UDP
	iptr -t filter -N XRAYTP_QUIC 2>/dev/null
	iptr -t filter -F XRAYTP_QUIC
	iptr -t filter -N XRAYTP_QUICOUT 2>/dev/null
	iptr -t filter -F XRAYTP_QUICOUT
	case "$SCOPE" in
		lan|both) for _if in $(printf '%s' "$LAN_IF" | tr ', ' '\n' | awk 'NF'); do
					iptr -t filter -A XRAYTP_QUIC -i "$_if" -p udp --dport 443 -j DROP
				done ;;
		list)     for _ip in $CLIENTS; do iptr -t filter -A XRAYTP_QUIC -s "$_ip" -p udp --dport 443 -j DROP; done ;;
	esac
	case "$SCOPE" in
		router|both) iptr -t filter -A XRAYTP_QUICOUT -p udp --dport 443 -j DROP ;;
	esac
	# заставляем клиентов пользоваться нашим DNS: закрываем шифрованный DNS
	if [ "$DNS_TUNNEL" = 1 ] && [ "$BLOCK_DOT" = 1 ]; then
		case "$SCOPE" in
			lan|both) for _if in $(printf '%s' "$LAN_IF" | tr ', ' '\n' | awk 'NF'); do
						iptr -t filter -A XRAYTP_QUIC -i "$_if" -p tcp --dport 853 -j DROP
						iptr -t filter -A XRAYTP_QUIC -i "$_if" -p udp --dport 853 -j DROP
					done ;;
			list)     for _ip in $CLIENTS; do
						iptr -t filter -A XRAYTP_QUIC -s "$_ip" -p tcp --dport 853 -j DROP
						iptr -t filter -A XRAYTP_QUIC -s "$_ip" -p udp --dport 853 -j DROP
					done ;;
		esac
		case "$SCOPE" in
			router|both) iptr -t filter -A XRAYTP_QUICOUT -p tcp --dport 853 -j DROP
				     iptr -t filter -A XRAYTP_QUICOUT -p udp --dport 853 -j DROP ;;
		esac
	fi
	if [ "$BLOCK_DOH" = 1 ]; then
		for _ip in $(printf '%s' "$DOH_LIST" | tr ', ' '\n' | awk 'NF'); do
			iptr -t filter -A XRAYTP_QUIC -d "$_ip" -p tcp --dport 443 -j DROP
			iptr -t filter -A XRAYTP_QUICOUT -d "$_ip" -p tcp --dport 443 -j DROP
		done
	fi
	iptr -t filter -C FORWARD -j XRAYTP_QUIC 2>/dev/null || iptr -t filter -A FORWARD -j XRAYTP_QUIC
	iptr -t filter -C OUTPUT -j XRAYTP_QUICOUT 2>/dev/null || iptr -t filter -A OUTPUT -j XRAYTP_QUICOUT
	return 0
}

ipt_off() {
	iptr -t nat -D PREROUTING -j XRAYTP_PRE 2>/dev/null
	iptr -t nat -D OUTPUT -j XRAYTP_OUT 2>/dev/null
	iptr -t nat -F XRAYTP_PRE 2>/dev/null
	iptr -t nat -F XRAYTP_OUT 2>/dev/null
	iptr -t nat -X XRAYTP_PRE 2>/dev/null
	iptr -t nat -X XRAYTP_OUT 2>/dev/null
	iptr -t filter -D FORWARD -j XRAYTP_QUIC 2>/dev/null
	iptr -t filter -D OUTPUT -j XRAYTP_QUICOUT 2>/dev/null
	iptr -t filter -F XRAYTP_QUIC 2>/dev/null
	iptr -t filter -F XRAYTP_QUICOUT 2>/dev/null
	iptr -t filter -X XRAYTP_QUIC 2>/dev/null
	iptr -t filter -X XRAYTP_QUICOUT 2>/dev/null
}

rules_on() { if has_nft; then nft_on; else ipt_on; fi; }
rules_off() { if has_nft; then nft_off; else ipt_off; fi; }

# команда автоотката: ждёт, проверяет, что это тот же запуск, и снимает правила
revert_cmd() {
	printf "sleep %s; [ -f '%s' ] && exit 0; [ \"\$(cat '%s' 2>/dev/null)\" = '%s' ] || exit 0; echo \"\$(date '+%%Y-%%m-%%d %%H:%%M:%%S')\" 'автооткат: правила сняты, подтверждение не нажали' >>'%s'; '%s' off" \
		"$REVERT" "$KEEP" "$GENF" "$GEN" "$LOGF" "$SELF"
}

mkdir -p "$STATE_DIR" 2>/dev/null

case "$1" in
	on)
		rm -f "$KEEP"
		_last_err=""
		# метка запуска: таймеры от прошлых включений станут недействительными
		GEN=$(date +%s)
		printf '%s\n' "$GEN" > "$GENF"
		log "=== включение: режим=$SCOPE, интерфейс=$LAN_IF, порт=$PORT"
		if ! rules_on; then
			rules_off
			log "правила сняты, ничего не изменилось"
			status_write "ОШИБКА: ${_last_err:-правила не установились}, всё откатил"
			echo "не удалось поставить правила фаервола — всё откатил, интернет не тронут"
			exit 1
		fi
		log "правила установлены"
		# DNS самого роутера правилами не заворачиваем: у локально созданных
		# запросов ответ приходит с другого адреса и теряется. Поэтому просто
		# просим dnsmasq спрашивать локальный порт xray.
		. "$LIBFILE" 2>/dev/null
		if [ "$DNS_ROUTER" = 1 ]; then
			dnsmasq_tunnel_on
		else
			# если dnsmasq перенастраивали раньше — вернуть как было
			dnsmasq_tunnel_off >/dev/null 2>&1
		fi
		status_write "правила установлены, автооткат через $REVERT секунд"
		expr "$(date +%s)" + "$REVERT" > "$DEADLINE" 2>/dev/null || echo "$REVERT" > "$DEADLINE"
		if command -v setsid >/dev/null 2>&1; then
			setsid sh -c "$(revert_cmd)" >>/dev/null 2>&1 &
		else
			sh -c "$(revert_cmd)" >>/dev/null 2>&1 &
		fi
		echo "правила включены, автооткат через $REVERT секунд"
		;;
	keep)
		touch "$KEEP"
		rm -f "$DEADLINE"
		date +%s > "$GENF" 2>/dev/null
		log "правила подтверждены"
		status_write "правила подтверждены, автооткат выключен"
		echo "правила оставлены, автооткат отменён"
		;;
	off)
		rules_off
		dns_routes_off
		. "$LIBFILE" 2>/dev/null
		dnsmasq_tunnel_off
		rm -f "$KEEP" "$DEADLINE"
		date +%s > "$GENF" 2>/dev/null
		log "правила сняты"
		if [ "$OFF_REASON" = shutdown ]; then
			# при выключении роутера правила снимаются штатно и вернутся сами:
			# иначе в панели остаётся пугающая строка «трафик идёт как обычно»
			status_write "роутер выключается — правила вернутся сами после загрузки"
		else
			status_write "правила сняты, трафик идёт как обычно"
		fi
		echo "правила сняты"
		;;
	restore)
		[ "$(cfg transparent)" = 1 ] || exit 0
		touch "$KEEP"
		if rules_on; then
			# строка состояния пишется заново: без этого в панели так и висело
			# «правила сняты» от выключения, хотя правила уже стоят
			log "правила восстановлены автоматически после загрузки роутера"
			status_write "правила восстановлены автоматически, автооткат не нужен"
		else
			rules_off
			log "ОШИБКА: правила не восстановились после загрузки роутера: ${_last_err:-неизвестная причина}"
			status_write "ОШИБКА: правила после загрузки не встали, трафик идёт как обычно"
			exit 1
		fi
		;;
	status)
		if has_nft; then
			nft list table ip "$TABLE" >/dev/null 2>&1 && echo on || echo off
		else
			iptables -t nat -C PREROUTING -j XRAYTP_PRE >/dev/null 2>&1 && echo on || echo off
		fi
		;;
	*)
		echo "использование: $0 on|off|keep|status|restore" >&2
		exit 2
		;;
esac
