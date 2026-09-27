#!/bin/sh
# Установка новой версии панели из релиза на GitHub (кнопка «обновить»).
#
# Скачиваем пакет в /etc/xraypanel/versions, проверяем, что это пакет панели и
# что он читается, ставим через штатный менеджер системы (opkg на старых,
# apk на новых) и записываем код возврата — страница
# «Статус» сама показывает итог.

STATE="${XRAYPANEL_STATE:-/etc/xraypanel}"
LIB="${XRAYPANEL_LIB:-/usr/lib/xraypanel/lib.sh}"
[ -f "$LIB" ] && . "$LIB"
mkdir -p "$STATE" 2>/dev/null

LOG="$STATE/update-install.log"
RUN="$STATE/update-install.running"
say() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

rm -f "$STATE/update-install.rc" 2>/dev/null

_url="$1"
[ -n "$_url" ] || _url=$(awk -F'\t' '$1 == "url" { print $2; exit }' "$STATE/update.info" 2>/dev/null)
_ver=$(awk -F'\t' '$1 == "version" { print $2; exit }' "$STATE/update.info" 2>/dev/null)
[ -n "$_url" ] || { say "нет ссылки на пакет — сначала проверьте обновления"; printf '1' > "$STATE/update-install.rc"; rm -f "$RUN"; exit 1; }

mkdir -p "$STATE/versions" 2>/dev/null
_f="$STATE/versions/xraypanel_${_ver}_all.$(pkg_ext)"
say "скачиваю $_url"
rm -f "$_f" 2>/dev/null
_ok=0
_tok=$(cfg update_token "" 2>/dev/null)
_apiurl=$(awk -F'\t' '$1 == "apiurl" { print $2; exit }' "$STATE/update.info" 2>/dev/null)
# приватный репозиторий: обычная ссылка отдаёт 404, файл берём через API с токеном
if [ -n "$_tok" ] && [ -n "$_apiurl" ] && command -v curl >/dev/null 2>&1; then
	say "репозиторий приватный — качаю через API с токеном"
	curl -sSL --max-time 300 -H "Authorization: Bearer $_tok" -H "Accept: application/octet-stream" -o "$_f" "$_apiurl" && _ok=1
elif [ -n "$_tok" ]; then
	say "для приватного репозитория нужен пакет curl (busybox-wget не умеет отправлять токен): $(pkg_cmd update) && $(pkg_cmd install curl)"
	printf '1' > "$STATE/update-install.rc"
	rm -f "$RUN"
	exit 1
fi
if [ "$_ok" = 0 ] && command -v wget >/dev/null 2>&1; then
	wget -q -T 60 -O "$_f" "$_url" && _ok=1
fi
if [ "$_ok" = 0 ] && command -v curl >/dev/null 2>&1; then
	curl -sSL --max-time 120 -o "$_f" "$_url" && _ok=1
fi
if [ "$_ok" = 0 ] && command -v uclient-fetch >/dev/null 2>&1; then
	uclient-fetch -q -O "$_f" "$_url" && _ok=1
fi
if [ "$_ok" = 0 ] || [ ! -s "$_f" ]; then
	say "скачать не удалось — оставляю текущую версию"
	rm -f "$_f" 2>/dev/null
	printf '1' > "$STATE/update-install.rc"
	rm -f "$RUN"
	exit 1
fi

if ! panel_ipk_ok "$_f" 2>/dev/null; then
	say "скачанный файл не похож на пакет панели — не ставлю"
	rm -f "$_f" 2>/dev/null
	printf '1' > "$STATE/update-install.rc"
	rm -f "$RUN"
	exit 1
fi
_new=$(panel_ipk_version "$_f" 2>/dev/null)
say "пакет на месте: версия $_new ($(file_size "$_f") байт), ставлю"

pkg_add_file "$_f" >>"$LOG" 2>&1
_rc=$?
printf '%s' "$_rc" > "$STATE/update-install.rc"
if [ "$_rc" = 0 ]; then
	say "установлено: $("$LIB" 2>/dev/null; panel_version 2>/dev/null) — настройки, серверы и правила не тронуты"
else
	say "$(pkg_mgr) вернул код $_rc — посмотрите журнал выше"
fi
rm -f "$RUN"
exit 0
