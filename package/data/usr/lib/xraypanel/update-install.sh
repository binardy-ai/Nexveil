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
# Сначала обычная ссылка: для публичного репозитория она работает всегда и не
# зависит от токена. Через API с токеном идём только тогда, когда обычная файл не
# отдала (приватный репозиторий) — иначе старый или просроченный токен в
# настройках ломал обновление на ровном месте.
if command -v wget >/dev/null 2>&1; then
	wget -q -T 60 -O "$_f" "$_url" && _ok=1
fi
if [ "$_ok" = 0 ] && command -v curl >/dev/null 2>&1; then
	curl -sSL --max-time 120 -o "$_f" "$_url" && _ok=1
fi
if [ "$_ok" = 0 ] && command -v uclient-fetch >/dev/null 2>&1; then
	uclient-fetch -q -O "$_f" "$_url" && _ok=1
fi
# скачалось что-то, но это не пакет (например, страница «нет доступа» от
# приватного репозитория) — считаем попытку неудачной
if [ -s "$_f" ] && ! panel_ipk_ok "$_f" 2>/dev/null; then
	rm -f "$_f" 2>/dev/null
	_ok=0
fi
if [ "$_ok" = 0 ] && [ -n "$_tok" ]; then
	if [ -n "$_apiurl" ] && command -v curl >/dev/null 2>&1; then
		say "обычная ссылка файл не отдала — качаю через API с токеном"
		curl -sSL --max-time 300 -H "Authorization: Bearer $_tok" -H "Accept: application/octet-stream" -o "$_f" "$_apiurl" && _ok=1
		if [ -s "$_f" ] && ! panel_ipk_ok "$_f" 2>/dev/null; then _ok=0; fi
	else
		say "для приватного репозитория нужен пакет curl (busybox-wget не умеет отправлять токен): $(pkg_cmd update) && $(pkg_cmd install curl)"
	fi
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
	_head=$(head -c 160 "$_f" 2>/dev/null | tr -d '\r\n')
	[ -n "$_head" ] && say "вместо пакета пришло: $_head"
	[ -n "$_tok" ] && say "если репозиторий публичный — очистите поле «токен GitHub» на странице «Настройки» и повторите"
	rm -f "$_f" 2>/dev/null
	printf '1' > "$STATE/update-install.rc"
	rm -f "$RUN"
	exit 1
fi
_new=$(panel_ipk_version "$_f" 2>/dev/null)
# если версию из файла вытащить не вышло, показываем ту, что нашла проверка
[ -n "$_new" ] || _new="$_ver"
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
