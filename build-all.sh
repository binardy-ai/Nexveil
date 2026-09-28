#!/bin/bash
# Сборка обоих пакетов одной командой: .ipk (для opkg) и .apk (для apk).
#
# Зачем это нужно: код панели один, а форматов пакета два — .ipk ставят системы
# до 24.10, .apk ставят 25.12 и новее. Если собирать только .ipk, то правка
# оказывается «только для 23.05», и на новых системах панель отстаёт (именно так
# и потерялась кнопка обновления на 25.12). Этот скрипт собирает и проверяет оба
# формата сразу.
#
# .apk обязательно собирается от root: внутри пакета записываются владельцы
# файлов, и при обычной сборке на роутере файлы достаются nobody. Поэтому:
#   1) запущено от root            — соберём сразу;
#   2) задан APK_BUILD_HOST=…      — соберём на этом хосте по ssh (например,
#      APK_BUILD_HOST=root@192.168.99.95, при необходимости добавьте
#      APK_BUILD_SSH_OPTS="-i /путь/к/ключу");
#   3) доступен docker             — соберём в контейнере;
#   4) ничего из этого             — скажем, что сделать руками.
set -e

BASE="$(cd "$(dirname "$0")" && pwd)"
VER="$(sed -n 's/^Version: //p' "$BASE/control/control")"
DIST="$BASE/dist"
IPK="$BASE/xraypanel_${VER}_all.ipk"
APK="$BASE/xraypanel_${VER}_all.apk"

echo "=== Сборка xraypanel $VER ==="
echo
echo "--- 1/3: пакет для opkg (.ipk) ---"
bash "$BASE/build.sh"

echo
echo "--- 2/3: пакет для apk (25.12+) ---"

# локальный apk.static (если уже скачан) — пригодится и на удалённой сборке
_static=""
for _p in "${APK_STATIC:-}" "$BASE/apk.static" /tmp/apkstudy/static/sbin/apk.static /tmp/apk-tools-static/sbin/apk.static; do
	[ -n "$_p" ] && [ -x "$_p" ] && { _static="$_p"; break; }
done

_build_apk_here() { # сборка на этой машине (нужен root)
	APK_STATIC="$_static" bash "$BASE/build-apk.sh"
}

_build_apk_ssh() { # сборка на роутере: там apk.static работает, а сборка идёт от root
	_host="$1"
	_dir="/tmp/xraypanel-apkbuild.$$"
	rm -rf "$BASE/.apkbuild"; mkdir -p "$BASE/.apkbuild"
	cp "$BASE/build-apk.sh" "$BASE/.apkbuild/"
	cp -a "$BASE/control" "$BASE/.apkbuild/"
	cp -a "$BASE/build" "$BASE/.apkbuild/"
	[ -n "$_static" ] && cp "$_static" "$BASE/.apkbuild/apk.static"
	echo "собираю на $_host (от root)…"
	# shellcheck disable=SC2086
	ssh $APK_BUILD_SSH_OPTS "$_host" "rm -rf $_dir"
	# shellcheck disable=SC2086
	scp -q -r $APK_BUILD_SSH_OPTS "$BASE/.apkbuild" "$_host:$_dir"
	# shellcheck disable=SC2086
	ssh $APK_BUILD_SSH_OPTS "$_host" "cd $_dir && APK_STATIC=$_dir/apk.static sh build-apk.sh"
	# shellcheck disable=SC2086
	scp -q $APK_BUILD_SSH_OPTS "$_host:$_dir/xraypanel_${VER}_all.apk" "$APK"
	# shellcheck disable=SC2086
	ssh $APK_BUILD_SSH_OPTS "$_host" "rm -rf $_dir"
	rm -rf "$BASE/.apkbuild"
}

if [ "$(id -u)" = 0 ]; then
	_build_apk_here
elif [ -n "${APK_BUILD_HOST:-}" ]; then
	_build_apk_ssh "$APK_BUILD_HOST"
elif command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
	echo "собираю в контейнере alpine (от root внутри)…"
	docker run --rm -v "$BASE":/src -w /work alpine:3.20 sh -c '
		set -e
		apk add --no-cache apk-tools-static >/dev/null 2>&1
		cp -a /src/build /work/build
		cp -a /src/control /work/control
		cp /src/build-apk.sh /work/
		APK_STATIC=/sbin/apk.static sh build-apk.sh
		cp /work/xraypanel_*_all.apk /src/
	'
else
	echo
	echo "Не удалось собрать .apk: для него нужен root (внутри пакета записываются"
	echo "владельцы файлов). Выберите один из вариантов:"
	echo "  * собрать на роутере:  APK_BUILD_HOST=root@192.168.99.95 sh build-all.sh"
	echo "  * или от root:         sudo bash build-apk.sh"
	echo
	echo "Готовый .ipk при этом уже собран: $IPK"
	exit 1
fi

echo
echo "--- 3/3: проверка пакетов ---"

# .ipk: внутри обязаны быть debian-binary и control с той же версией
_t="$(mktemp -d)"
gzip -dc "$IPK" | tar tf - 2>/dev/null | grep -qx './debian-binary' || {
	echo "ошибка: .ipk не читается как пакет opkg"; rm -rf "$_t"; exit 1; }
gzip -dc "$IPK" | tar xf - -C "$_t" ./control.tar.gz 2>/dev/null
tar xzf "$_t/control.tar.gz" -C "$_t" ./control 2>/dev/null
_iv="$(sed -n 's/^Version: //p' "$_t/control" 2>/dev/null | head -1)"
rm -rf "$_t"
[ "$_iv" = "$VER" ] || { echo "ошибка: внутри .ipk версия «$_iv», а ждали $VER"; exit 1; }

# .apk: это контейнер ADB, он начинается с «ADB» и весит заметно больше мелочи
[ "$(head -c 3 "$APK" 2>/dev/null)" = "ADB" ] || { echo "ошибка: .apk не похож на пакет apk"; exit 1; }
_sz=$(wc -c < "$APK")
[ "$_sz" -gt 100000 ] || { echo "ошибка: .apk подозрительно маленький ($_sz байт)"; exit 1; }

# имена с постоянной версией — их удобно прикладывать к релизу руками
mkdir -p "$DIST"
cp -f "$IPK" "$DIST/xraypanel_all.ipk"
cp -f "$APK" "$DIST/xraypanel_all.apk"

echo "готово:"
printf '  %s (%s байт)\n' "$IPK" "$(wc -c < "$IPK")"
printf '  %s (%s байт)\n' "$APK" "$_sz"
echo "  для релиза (постоянные имена):"
printf '  %s/xraypanel_all.ipk, %s/xraypanel_all.apk\n' "$DIST" "$DIST"
echo
echo "Оба формата собраны и проверены. Перед выпуском прогоните проверку на"
echo "роутерах 23.05 и 25.12: docs/ПРОВЕРКА-ПЕРЕД-ВЫПУСКОМ.md"
