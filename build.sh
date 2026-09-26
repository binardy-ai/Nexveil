#!/bin/bash
# Сборка пакета xraypanel_<версия>_all.ipk
set -e

BASE="$(cd "$(dirname "$0")" && pwd)"
BUILD="$BASE/build"
VER="$(sed -n 's/^Version: //p' "$BASE/control/control")"
OUT="$BASE/xraypanel_${VER}_all.ipk"

rm -rf "$BUILD"
mkdir -p "$BUILD/control" "$BUILD/data"

cp -a "$BASE/package/data/." "$BUILD/data/"
cp "$BASE/control/control" "$BUILD/control/control"
[ -f "$BASE/control/conffiles" ] && cp "$BASE/control/conffiles" "$BUILD/control/conffiles"
for s in postinst prerm; do
	[ -f "$BASE/control/$s" ] && { cp "$BASE/control/$s" "$BUILD/control/$s"; chmod 755 "$BUILD/control/$s"; }
done

# права внутри пакета
find "$BUILD/data" -type d -exec chmod 755 {} \;
find "$BUILD/data" -type f -exec chmod 644 {} \;
chmod 755 "$BUILD/data/www/cgi-bin/xraypanel"
chmod 644 "$BUILD/data/usr/lib/xraypanel/lib.sh"
chmod 755 "$BUILD/data/usr/lib/xraypanel/transparent.sh"
chmod 755 "$BUILD/data/usr/lib/xraypanel/install-xray.sh"
chmod 755 "$BUILD/data/usr/lib/xraypanel/urltest.sh"
chmod 755 "$BUILD/data/usr/lib/xraypanel/sub-update.sh"
chmod 755 "$BUILD/data/usr/lib/xraypanel/geo-tags.sh"
chmod 755 "$BUILD/data/usr/lib/xraypanel/geo-item.sh"
chmod 755 "$BUILD/data/usr/lib/xraypanel/exits-sample.sh"
chmod 755 "$BUILD/data/usr/lib/xraypanel/geo-update.sh"
chmod 755 "$BUILD/data/usr/lib/xraypanel/update-check.sh"
chmod 755 "$BUILD/data/usr/lib/xraypanel/update-install.sh"
chmod 755 "$BUILD/data/usr/lib/xraypanel/transparent-enable.sh"
chmod 755 "$BUILD/data/usr/lib/xraypanel/transparent-disable.sh"
chmod 755 "$BUILD/data/etc/init.d/xraypanel-transparent"
chmod 755 "$BUILD/data/etc/hotplug.d/iface/99-xraypanel"

printf '2.0\n' > "$BUILD/debian-binary"

# версия панели — чтобы её было видно на странице «Статус»
mkdir -p "$BUILD/data/etc/xraypanel"
printf '%s\n' "$VER" > "$BUILD/data/etc/xraypanel/version"

tar --owner=0 --group=0 -C "$BUILD/control" -czf "$BUILD/control.tar.gz" .
tar --owner=0 --group=0 -C "$BUILD/data"    -czf "$BUILD/data.tar.gz" .

# Формат ipk для OpenWrt 23.05+ : gzip-сжатый tar с тремя членами
# ./debian-binary ./control.tar.gz ./data.tar.gz (проверено на эталонных
# пакетах downloads.openwrt.org). Классический ar-формат opkg не принимает.
# ВАЖНО: порядок членов как у эталона — debian-binary, data.tar.gz,
# control.tar.gz. Если положить control раньше data, opkg записывает версию,
# но файлы не распаковывает (проверено на живом роутере).
rm -f "$BUILD/ipk.tar" "$OUT"
( cd "$BUILD" && tar --owner=0 --group=0 -cf "$BUILD/ipk.tar" ./debian-binary ./data.tar.gz ./control.tar.gz )
gzip -9n -c "$BUILD/ipk.tar" > "$OUT"
rm -f "$BUILD/ipk.tar"

# проверка, что пакет читается именно так, как ждёт opkg
if ! tar tzf "$OUT" | grep -qx './debian-binary'; then
	echo "ОШИБКА: пакет собран в неверном формате" >&2
	exit 1
fi

echo "Пакет собран: $OUT"
ls -lh "$OUT"
echo
echo "Установка на роутере:"
echo "  scp $OUT root@<IP роутера>:/tmp/"
echo "  ssh root@<IP роутера> 'opkg install /tmp/$(basename "$OUT")'"
