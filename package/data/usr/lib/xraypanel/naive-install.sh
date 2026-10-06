#!/bin/sh
# Установка клиента NaiveProxy (naive) на роутер.
#
# Порядок такой (каждый шаг проверяет, что клиент реально запускается):
#   1) пакет naiveproxy из фидов системы — правильная сборка под роутер
#      (работает и на 23 версии с opkg, и на 25 версии с apk);
#   2) готовый файл рядом: /etc/xraypanel/versions или /tmp;
#   3) официальный архив с GitHub — запасной путь. Важно: сборки naiveproxy с
#      GitHub собраны под glibc, а на роутерах OpenWrt стоит musl, поэтому
#      такой бинарник обычно не запускается («not found»), хотя файл на месте.
#
# Переменная NAIVE_INSTALL_DRY=1 — только показать, что нашлось, ничего не ставить.
. /usr/lib/xraypanel/lib.sh 2>/dev/null

DRY="${NAIVE_INSTALL_DRY:-0}"
VER="${NAIVE_VER:-154.0.8037.49-2}"
WORK="/tmp/naive-install"

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }

naive_arch() {
	. /etc/openwrt_release 2>/dev/null
	case "${DISTRIB_ARCH:-}" in
		x86_64)      printf 'x64' ;;
		i386*|i486*|i586*|i686*) printf 'x86' ;;
		aarch64*)    printf 'arm64' ;;
		arm_cortex-a*) printf 'arm' ;;
		arm_arm*)    printf 'arm' ;;
		mipsel*)     printf 'mipsel' ;;
		mips64el*)   printf 'mips64el' ;;
		riscv64*)    printf 'riscv64' ;;
		*)           printf '' ;;
	esac
}

finish_check() {
	NAIVE_RUN_CACHE=""
	if naive_bin_run_ok; then
		log "готово: клиент NaiveProxy установлен и запускается ($NAIVE_BIN)"
		return 0
	fi
	if naive_bin_ok; then
		log "файл клиента лежит на месте, но он не запускается: эта сборка не подходит системе"
		log "на роутере нужен пакет naiveproxy из фидов системы (сборка под musl)"
	fi
	log "клиент не установился — смотрите строки выше"
	return 1
}

# поставить файл как клиент, но только если он действительно запускается:
# иначе мы бы затирали рабочий клиент нерабочим (так и было с glibc-сборкой)
install_bin_from() { # $1 — путь к файлу-кандидату
	_c="$WORK/naive-candidate"
	mkdir -p "$WORK" 2>/dev/null
	rm -f "$_c"
	cp -f "$1" "$_c" 2>/dev/null || return 1
	chmod 755 "$_c" 2>/dev/null
	if ! naive_file_run_ok "$_c"; then
		rm -f "$_c"
		return 1
	fi
	cp -f "$_c" "$NAIVE_BIN" 2>/dev/null || { rm -f "$_c"; return 1; }
	chmod 755 "$NAIVE_BIN" 2>/dev/null
	rm -f "$_c"
	NAIVE_RUN_CACHE=""
	return 0
}

# --- 1) пакет из фидов системы ------------------------------------------------

install_from_feed() { # пакет naiveproxy из фидов (opkg на 23.x, apk на 25.x)
	_m=$(pkg_mgr)
	[ "$_m" = none ] && { log "в системе нет ни opkg, ни apk — пакет не поставить"; return 1; }
	log "пробую пакет naiveproxy из фидов системы ($_m)"
	pkg_update >/dev/null 2>&1
	_out=$(pkg_add naiveproxy 2>&1)
	log "пакет: $(printf '%s' "$_out" | tail -2 | tr '\n' ' ')"
	NAIVE_RUN_CACHE=""
	if [ "$_m" = opkg ] && ! naive_bin_run_ok; then
		# бывает, что opkg отказывается из-за подписи зеркала или мешает
		# посторонний файл /usr/bin/naive — пробуем ещё раз с перезаписью
		_out=$(opkg install --force-overwrite --force-reinstall naiveproxy 2>&1)
		log "пакет (повтор): $(printf '%s' "$_out" | tail -2 | tr '\n' ' ')"
	fi
	NAIVE_RUN_CACHE=""
	if ! naive_bin_run_ok; then
		case "$_out" in
			*"Unknown package"*|*"not found"*)
				log "в фидах этой системы пакета naiveproxy нет (он есть в фидах ImmortalWrt)" ;;
			*"Signature"*|*"signature"*)
				log "зеркало фида не отдаёт файл подписи — беру пакет напрямую" ;;
		esac
		install_from_feed_file
		return $?
	fi
	NAIVE_RUN_CACHE=""
	naive_bin_run_ok
}

# Скачать .ipk прямо с зеркала фида и поставить файлом: нужно, когда зеркало
# отдаёт пакеты без файла подписи и opkg из-за этого отказывается ставить.
install_from_feed_file() {
	[ "$(pkg_mgr)" = opkg ] || return 1
	_base=""
	for _f in /etc/opkg/distfeeds.conf /etc/opkg/customfeeds.conf; do
		[ -f "$_f" ] || continue
		while read -r _k _n _u; do
			case "$_k" in src/gz|src) ;; *) continue ;; esac
			case "$_u" in
				*/packages/x86_64/packages|*/packages/aarch64*/packages|*/packages/*/packages) _base="$_u" ;;
			esac
			[ -n "$_base" ] && break
		done < "$_f"
		[ -n "$_base" ] && break
	done
	[ -n "$_base" ] || { log "не нашёл в настройках фид с пакетами"; return 1; }
	mkdir -p "$WORK"
	_idx="$WORK/Packages.gz"
	rm -f "$_idx"
	log "читаю список пакетов: $_base"
	if command -v wget >/dev/null 2>&1; then
		wget -q -T 60 -O "$_idx" "$_base/Packages.gz" || { log "список пакетов не скачался"; return 1; }
	else
		curl -fsS --max-time 120 -o "$_idx" "$_base/Packages.gz" || { log "список пакетов не скачался"; return 1; }
	fi
	_pkg=$(gzip -dc "$_idx" 2>/dev/null | awk '
		/^Package: / { cur=$2 }
		cur == "naiveproxy" && /^Filename: / { print $2; exit }
	')
	[ -n "$_pkg" ] || { log "в этом фиде пакета naiveproxy нет"; return 1; }
	_dep=$(gzip -dc "$_idx" 2>/dev/null | awk '
		/^Package: / { cur=$2 }
		cur == "naiveproxy" && /^Depends: / { print $2; exit }
	')
	# тянем сам пакет и те зависимости, которых в системе ещё нет
	_list="$_pkg"
	for _d in $(printf '%s' "$_dep" | tr ',' ' '); do
		opkg list-installed 2>/dev/null | grep -q "^$_d - " && continue
		_f=$(gzip -dc "$_idx" 2>/dev/null | awk -v want="$_d" '
			/^Package: / { cur=$2 }
			cur == want && /^Filename: / { print $2; exit }
		')
		[ -n "$_f" ] && _list="$_list $_f"
	done
	for _f in $_list; do
		_out_f="$WORK/$(basename "$_f")"
		if command -v wget >/dev/null 2>&1; then
			wget -q -T 120 -O "$_out_f" "$_base/$_f" || { log "не скачался $(basename "$_f")"; return 1; }
		else
			curl -fsS --max-time 300 -o "$_out_f" "$_base/$_f" || { log "не скачался $(basename "$_f")"; return 1; }
		fi
		_files="$_files $_out_f"
	done
	log "ставлю файлами:$(printf '%s' "$_files" | sed 's#/tmp/naive-install/##g')"
	_out=$(opkg install --force-overwrite $_files 2>&1)
	log "установка: $(printf '%s' "$_out" | tail -2 | tr '\n' ' ')"
	NAIVE_RUN_CACHE=""
	naive_bin_run_ok
}

# распаковка .tar.xz: busybox-tar сам xz не умеет, поэтому сначала xz -dc
unpack_xz() { # $1 = архив, $2 = куда
	rm -rf "$2"; mkdir -p "$2"
	if command -v xz >/dev/null 2>&1; then
		xz -dc "$1" 2>/dev/null | tar xf - -C "$2" 2>/dev/null && return 0
	fi
	if command -v unxz >/dev/null 2>&1; then
		cp -f "$1" "$1.dec"; unxz -f "$1.dec" 2>/dev/null && \
			tar xf "$1.dec" -C "$2" 2>/dev/null && rm -f "$1.dec" && return 0
		rm -f "$1.dec"
	fi
	return 1
}

ensure_xz() {
	command -v xz >/dev/null 2>&1 && return 0
	command -v unxz >/dev/null 2>&1 && return 0
	log "для распаковки нужен xz — ставлю пакет"
	[ "$DRY" = 1 ] && return 1
	pkg_update >/dev/null 2>&1
	_out=$(pkg_add xz 2>&1)
	log "xz: $(printf '%s' "$_out" | tail -1)"
	command -v xz >/dev/null 2>&1 || command -v unxz >/dev/null 2>&1
}

install_local() {
	_any=0
	for _d in "$STATE_DIR/versions" /tmp; do
		for _f in "$_d"/naiveproxy-*linux*.tar.xz "$_d"/naiveproxy*.tar.gz "$_d"/naive "$_d"/naive-linux*; do
			[ -f "$_f" ] || continue
			_any=1
			if [ "$DRY" = 1 ]; then
				log "(проверка) нашёл: $(basename "$_f")"
				continue
			fi
			case "$_f" in
				*.tar.xz)
					ensure_xz || { log "нет xz — не могу распаковать $(basename "$_f")"; continue; }
					unpack_xz "$_f" "$WORK/unpacked" || { log "не распаковал $(basename "$_f")"; continue; }
					_b=$(find "$WORK/unpacked" -type f -name naive | head -1)
					if [ -n "$_b" ] && install_bin_from "$_b"; then
						log "поставил из $(basename "$_f")"
						return 0
					fi
					log "$(basename "$_f"): клиент из этого файла не запускается"
					;;
				*.tar.gz)
					rm -rf "$WORK/unpacked"; mkdir -p "$WORK/unpacked"
					tar xzf "$_f" -C "$WORK/unpacked" 2>/dev/null
					_b=$(find "$WORK/unpacked" -type f -name naive | head -1)
					if [ -n "$_b" ] && install_bin_from "$_b"; then
						log "поставил из $(basename "$_f")"
						return 0
					fi
					log "$(basename "$_f"): клиент из этого файла не запускается"
					;;
				*)
					if install_bin_from "$_f"; then
						log "поставил бинарник $(basename "$_f")"
						return 0
					fi
					log "$(basename "$_f"): этот файл как клиент не запускается (не та сборка)"
					;;
			esac
		done
	done
	[ "$_any" = 1 ] && log "подходящего готового файла рядом нет"
	return 1
}

download_and_install() {
	_arch=$(naive_arch)
	if [ -z "$_arch" ]; then
		log "для архитектуры ${DISTRIB_ARCH:-неизвестной} сборки naive нет"
		return 1
	fi
	_url="https://github.com/klzgrad/naiveproxy/releases/download/v${VER}/naiveproxy-v${VER}-linux-${_arch}.tar.xz"
	log "скачиваю: $(basename "$_url")"
	mkdir -p "$WORK"
	_arc="$WORK/naive.tar.xz"
	if command -v wget >/dev/null 2>&1; then
		wget -q -T 30 -O "$_arc" "$_url" || { log "не скачался архив"; return 1; }
	else
		curl -fsS --max-time 180 -o "$_arc" "$_url" || { log "не скачался архив"; return 1; }
	fi
	[ -s "$_arc" ] || { log "архив пустой"; return 1; }
	ensure_xz || { log "нет xz — распаковать официальный архив нечем. Поставьте пакет xz или положите готовый бинарник naive в /tmp"; return 1; }
	unpack_xz "$_arc" "$WORK/unpacked" || { log "не смог распаковать архив"; return 1; }
	_b=$(find "$WORK/unpacked" -type f -name naive | head -1)
	[ -n "$_b" ] || { log "в архиве нет клиента naive"; return 1; }
	if [ "$DRY" = 1 ]; then
		log "(проверка) поставил бы: $_b ($(wc -c < "$_b") байт)"
		return 0
	fi
	if install_bin_from "$_b"; then
		log "поставил клиент: $NAIVE_BIN"
		return 0
	fi
	log "эта сборка не запускается: она собрана под glibc, а на роутере стоит musl"
	return 1
}

log "=== установка клиента NaiveProxy ($(date '+%d.%m.%Y %H:%M')) ==="
if [ "$DRY" = 1 ]; then
	log "режим проверки: ничего не устанавливаю"
	install_local
	NAIVE_RUN_CACHE=""
	if naive_bin_run_ok; then
		log "сейчас на роутере рабочий клиент: $NAIVE_BIN ($("$NAIVE_BIN" --version 2>&1 | head -1))"
	elif naive_bin_ok; then
		log "сейчас на роутере файл клиента есть, но он не запускается"
	else
		log "сейчас клиента на роутере нет"
	fi
	exit 0
fi

if naive_bin_run_ok; then
	log "клиент уже установлен и запускается — ничего не делаю"
	finish_check
	exit $?
fi
naive_bin_ok && log "файл клиента есть, но он не запускается — переустанавливаю подходящей сборкой"

if install_from_feed; then
	finish_check
	exit $?
fi
if install_local; then
	finish_check
	exit $?
fi
log "беру официальную сборку с GitHub (запасной путь)"
download_and_install || { log "установка не удалась"; exit 1; }
finish_check
exit $?
