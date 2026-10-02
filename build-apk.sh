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
# APK_STATIC мог быть задан на путь, где файла нет (например, сборка идёт на
# роутере и статический бинарник ещё не скачан) — тогда берём обычное место.
[ -x "$APK" ] || APK="$WORK/sbin/apk.static"
if [ ! -x "$APK" ]; then
	echo "нужен apk.static (apk-tools 3) — скачиваю apk-tools-static из Alpine…"
	mkdir -p "$WORK"
	_dir="https://dl-cdn.alpinelinux.org/alpine/edge/main/x86_64"
	_pkg=$(curl -sL --max-time 60 "$_dir/" | grep -oE 'apk-tools-static-[0-9][^"<]*\.apk' | head -1)
	[ -n "$_pkg" ] || { echo "не нашёл apk-tools-static в репозитории Alpine" >&2; exit 1; }
	curl -sL --max-time 120 -o "$WORK/apk-tools-static.apk" "$_dir/$_pkg"
	# пакет подписан и собран в старом формате (два склеенных потока gzip),
	# поэтому обычный tar на нём спотыкается, а нужен --ignore-zeros. На
	# роутерах с apk-tools 3 (25.12) в busybox такого ключа нет — зато сам apk
	# умеет извлекать содержимое пакета. Пробуем оба способа по очереди.
	if ! gzip -dc "$WORK/apk-tools-static.apk" | tar --ignore-zeros -x -C "$WORK" 2>/dev/null; then
		if command -v apk >/dev/null 2>&1; then
			apk extract --allow-untrusted --destination "$WORK" "$WORK/apk-tools-static.apk" >/dev/null 2>&1
		fi
	fi
	[ -x "$APK" ] || { echo "не удалось получить apk.static" >&2; exit 1; }
fi

echo "apk: $("$APK" --version 2>&1 | head -1)"

# Владельцы файлов в пакете берутся из файловой системы сборки. Если собирать
# не от root, в пакет попадёт имя сборщика, и на роутере apk про такого
# пользователя предупредит (файлы останутся за root, но лучше собирать с
# правильным владельцем). Правильно — запускать этот скрипт от root: например,
# на самом роутере, там apk.static тоже работает.
if [ "$(id -u)" != "0" ]; then
	echo "ошибка: .apk нужно собирать от root — иначе владельцем файлов внутри" >&2
	echo "пакета станет $(id -un), а на роутере эти файлы окажутся у nobody." >&2
	echo "Собирайте на роутере от root:" >&2
	echo "  APK_STATIC=/tmp/apk.static sh build-apk.sh" >&2
	exit 1
fi

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
	--script "post-upgrade:$BASE/control/postinst" \
	--script "pre-deinstall:$BASE/control/prerm" \
	--output "$OUT"

echo "готово: $OUT ($(wc -c <"$OUT") байт)"
