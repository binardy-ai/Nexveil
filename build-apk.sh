#!/bin/bash
# Сборка пакета в формате apk — для OpenWrt 25.12+ и всего, где пакетный
# менеджер уже apk (до 24.10 это был opkg и .ipk, их собирает build.sh).
#
# Формат пакетов у apk v3 — контейнер ADB, а не tar.gz, поэтому собираем
# настоящим apk-tools 3: нужен статический бинарник apk.static.
# Если он не задан через APK_STATIC, скрипт разово скачает apk-tools-static
# из Alpine (это статическая сборка, работает в любом Linux).
set -e

BASE="$(cd "$(dirname "$0")" && pwd)"
VER="$(sed -n 's/^Version: //p' "$BASE/control/control")"
DESC="$(sed -n 's/^Description: //p' "$BASE/control/control")"
DATA="$BASE/build/data"
OUT="$BASE/xraypanel_${VER}_all.apk"
WORK="${APK_WORK:-/tmp/apk-tools-static}"

if [ ! -d "$DATA" ]; then
	echo "нет $DATA — сначала соберите пакет: bash build.sh" >&2
	exit 1
fi

APK="${APK_STATIC:-$WORK/sbin/apk.static}"
if [ ! -x "$APK" ]; then
	echo "нужен apk.static (apk-tools 3) — скачиваю apk-tools-static из Alpine…"
	mkdir -p "$WORK"
	_dir="https://dl-cdn.alpinelinux.org/alpine/edge/main/x86_64"
	_pkg=$(curl -sL --max-time 60 "$_dir/" | grep -oE 'apk-tools-static-[0-9][^"<]*\.apk' | head -1)
	[ -n "$_pkg" ] || { echo "не нашёл apk-tools-static в репозитории Alpine" >&2; exit 1; }
	curl -sL --max-time 120 -o "$WORK/apk-tools-static.apk" "$_dir/$_pkg"
	# пакет подписан и собран в старом формате (gzip), поэтому распаковываем
	# обычным tar с --ignore-zeros — статический бинарник ляжет в sbin/
	gzip -dc "$WORK/apk-tools-static.apk" | tar --ignore-zeros -x -C "$WORK" 2>/dev/null
	[ -x "$APK" ] || { echo "не удалось получить apk.static" >&2; exit 1; }
fi

echo "apk: $("$APK" --version 2>&1 | head -1)"
rm -f "$OUT"
"$APK" mkpkg \
	--info "name:xraypanel" \
	--info "version:$VER" \
	--info "arch:noarch" \
	--info "license:MIT" \
	--info "description:$DESC" \
	--info "depends:uhttpd" \
	--files "$DATA" \
	--script "post-install:$BASE/control/postinst" \
	--script "pre-deinstall:$BASE/control/prerm" \
	--output "$OUT"

echo "готово: $OUT ($(wc -c <"$OUT") байт)"
