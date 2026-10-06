#!/bin/sh
# Установка клиента Mieru на роутер.
# Сначала ищем готовый архив рядом (его можно закинуть вручную), потом
# скачиваем официальную сборку с GitHub под архитектуру роутера.
#
# Переменная MIERU_INSTALL_DRY=1 — только скачать и распаковать, не ставить.
. /usr/lib/xraypanel/lib.sh 2>/dev/null

DRY="${MIERU_INSTALL_DRY:-0}"
VER="${MIERU_VER:-3.38.0}"
WORK="/tmp/mieru-install"

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }

# архитектура роутера -> имя сборки mieru
mieru_arch() {
	. /etc/openwrt_release 2>/dev/null
	case "${DISTRIB_ARCH:-}" in
		x86_64)                   printf 'amd64' ;;
		aarch64*)                 printf 'arm64' ;;
		arm_cortex-a*)            printf 'armv7' ;;
		arm_arm*)                 printf 'armv7' ;;
		riscv64*)                 printf 'riscv64' ;;
		*)                        printf '' ;;
	esac
}

finish_check() {
	if mieru_bin_ok; then
		log "готово: клиент Mieru установлен ($MIERU_BIN)"
		return 0
	fi
	log "клиент не установился — смотрите строки выше"
	return 1
}

install_local() { # ставим готовый архив/бинарник, если он рядом
	_any=0
	for _d in "$STATE_DIR/versions" /tmp; do
		for _f in "$_d"/mieru_*linux*.tar.gz "$_d"/mieru_*.tar.gz "$_d"/mieru; do
			[ -f "$_f" ] || continue
			_any=1
			if [ "$DRY" = 1 ]; then
				log "(проверка) нашёл: $(basename "$_f")"
				continue
			fi
			case "$_f" in
				*.tar.gz)
					rm -rf "$WORK/unpacked"
					mkdir -p "$WORK/unpacked"
					tar xzf "$_f" -C "$WORK/unpacked" 2>/dev/null
					_b=$(find "$WORK/unpacked" -type f -name mieru | head -1)
					# на OpenWrt нет команды install — копируем и ставим права
					[ -n "$_b" ] && cp -f "$_b" "$MIERU_BIN" && chmod 755 "$MIERU_BIN" && log "поставил из $(basename "$_f")"
					;;
				*)
					cp -f "$_f" "$MIERU_BIN" && chmod 755 "$MIERU_BIN" && log "поставил бинарник $(basename "$_f")"
					;;
			esac
		done
	done
	[ "$_any" = 1 ]
}

download_and_install() {
	_arch=$(mieru_arch)
	if [ -z "$_arch" ]; then
		log "для архитектуры ${DISTRIB_ARCH:-неизвестной} сборки mieru нет (есть amd64, arm64, armv7, riscv64)"
		return 1
	fi
	_url="https://github.com/enfein/mieru/releases/download/v${VER}/mieru_${VER}_linux_${_arch}.tar.gz"
	log "скачиваю: $(basename "$_url")"
	_arc="$WORK/mieru.tar.gz"
	mkdir -p "$WORK"
	if command -v wget >/dev/null 2>&1; then
		wget -q -T 30 -O "$_arc" "$_url" || { log "не скачался архив"; return 1; }
	else
		curl -fsS --max-time 120 -o "$_arc" "$_url" || { log "не скачался архив"; return 1; }
	fi
	[ -s "$_arc" ] || { log "архив пустой"; return 1; }
	rm -rf "$WORK/unpacked"
	mkdir -p "$WORK/unpacked"
	tar xzf "$_arc" -C "$WORK/unpacked" 2>/dev/null || { log "не смог распаковать архив"; return 1; }
	_b=$(find "$WORK/unpacked" -type f -name mieru | head -1)
	[ -n "$_b" ] || { log "в архиве нет клиента mieru"; return 1; }
	if [ "$DRY" = 1 ]; then
		log "(проверка) поставил бы: $_b ($(wc -c < "$_b") байт)"
		return 0
	fi
	cp -f "$_b" "$MIERU_BIN" && chmod 755 "$MIERU_BIN" && log "поставил клиент: $MIERU_BIN"
	return 0
}

log "=== установка клиента Mieru ($(date '+%d.%m.%Y %H:%M')) ==="
if mieru_bin_ok && [ "$DRY" != 1 ]; then
	log "клиент уже установлен — ничего не делаю"
	finish_check
	exit $?
fi
[ "$DRY" = 1 ] && log "режим проверки: ничего не устанавливаю"

if install_local; then
	finish_check
	exit $?
fi
log "готовых файлов рядом нет — беру сборку с GitHub"
download_and_install || { log "установка не удалась"; exit 1; }
finish_check
exit $?
