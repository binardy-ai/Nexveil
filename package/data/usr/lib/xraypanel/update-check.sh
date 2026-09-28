#!/bin/sh
# Проверка новой версии панели на GitHub.
#
# Куда смотреть — настройка update_repo («владелец/репозиторий»), по умолчанию
# binardy-ai/Nexveil. Если репозиторий приватный, можно указать update_token.
#
# Результат кладём в состояние панели, чтобы страница «Статус» показывала
# предупреждение без обращения к интернету:
#   update.info  — «ключ<TAB>значение»: date, version, tag, url, size, page
#   update.notes — что нового (текст релиза)
#   update.at    — когда проверяли (unix-время)
#   update.log   — журнал: что нашлось и что не получилось

STATE="${XRAYPANEL_STATE:-/etc/xraypanel}"
LIB="${XRAYPANEL_LIB:-/usr/lib/xraypanel/lib.sh}"
[ -f "$LIB" ] && . "$LIB"
mkdir -p "$STATE" 2>/dev/null

LOG="$STATE/update.log"
ERR="$STATE/update.error"
say() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }

# причину неудачи показываем прямо на странице «Статус», а не только в журнале
fail() {
	say "$*"
	printf '%s' "$*" > "$ERR" 2>/dev/null
	exit 1
}

# журнал не растёт бесконечно
if [ -f "$LOG" ] && [ "$(wc -c <"$LOG" 2>/dev/null)" -gt 200000 ] 2>/dev/null; then
	: > "$LOG"
fi

rm -f "$ERR" 2>/dev/null
_repo=$(cfg update_repo "binardy-ai/Nexveil" 2>/dev/null)
[ -n "$_repo" ] || { say "репозиторий обновлений не указан — выхожу"; exit 0; }
_tok=$(cfg update_token "" 2>/dev/null)

TMP="$STATE/update.json.new"
say "проверяю последний релиз: $_repo"

# Приватный репозиторий требует отправки токена, а busybox-wget и uclient-fetch
# на OpenWrt этого не умеют — там нужен пакет curl. Если репозиторий публичный,
# всё работает и обычным wget.
fetch() { # $1 = куда
	if [ -n "$_tok" ]; then
		if command -v curl >/dev/null 2>&1; then
			curl -sSL --max-time 30 -H "Authorization: Bearer $_tok" -o "$1" "$API" && return 0
			return 1
		fi
		say "для приватного репозитория нужен пакет curl: busybox-wget не умеет отправлять токен"
		say "поставьте его командой: $(pkg_cmd update) && $(pkg_cmd install curl)"
		return 1
	fi
	if command -v wget >/dev/null 2>&1; then
		wget -q -T 25 -O "$1" "$API" && return 0
	fi
	if command -v curl >/dev/null 2>&1; then
		curl -sSL --max-time 30 -o "$1" "$API" && return 0
	fi
	if command -v uclient-fetch >/dev/null 2>&1; then
		uclient-fetch -q -O "$1" "$API" && return 0
	fi
	return 1
}

API="https://api.github.com/repos/${_repo}/releases/latest"
rm -f "$TMP" 2>/dev/null
if ! fetch "$TMP"; then
	rm -f "$TMP" 2>/dev/null
	fail "не удалось получить ответ от GitHub: нет интернета, либо репозиторий приватный (тогда на странице «Настройки» нужен токен GitHub)"
fi

if grep -q '"message"' "$TMP" 2>/dev/null && ! grep -q '"tag_name"' "$TMP" 2>/dev/null; then
	_msg=$(sed -n 's/.*"message": *"\([^"]*\)".*/\1/p' "$TMP" | head -1)
	case "$_msg" in
		Not\ Found) _msg="репозиторий не найден (проверьте настройку «владелец/репозиторий»)" ;;
	esac
	rm -f "$TMP" 2>/dev/null
	fail "GitHub ответил ошибкой: ${_msg:-неизвестная ошибка}"
fi

_tag=$(sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' "$TMP" | head -1)
_ver=${_tag#v}
# ссылка на пакет панели: берём файл того формата, который подходит этой
# системе — .ipk на старых (opkg), .apk на новых (apk)
_ext=$(pkg_ext)
_url=$(grep -o '"browser_download_url": *"[^"]*\.'"$_ext"'"' "$TMP" 2>/dev/null | head -1 | sed -e 's/.*"\(http[^"]*\)".*/\1/')
# адрес того же файла через API: для приватного репозитория обычная ссылка не
# скачивается, а API-адрес с токеном — скачивается (Accept: octet-stream)
_apiurl=$(awk '
	/"url": *"[^"]*\/releases\/assets\/[0-9]+"/ { if (match($0, /assets\/[0-9]+/)) last = substr($0, RSTART, RLENGTH) }
	/"browser_download_url": *"[^"]*\.'"$_ext"'"/ { if (last != "") { print "https://api.github.com/repos/'"$_repo"'/releases/" last; exit } }
' "$TMP" 2>/dev/null)
_size=$(grep -o '"size": *[0-9]*' "$TMP" 2>/dev/null | head -1 | sed -e 's/.*: *//')
_date=$(date '+%d.%m.%Y %H:%M')

if [ -z "$_ver" ]; then
	rm -f "$TMP" 2>/dev/null
	fail "в ответе GitHub не нашлось версии — обновление не предлагаю"
fi

# что нового: текст релиза, с расшифровкой \n и \" из JSON
awk '
	BEGIN { inb = 0 }
	{
		if (!inb) {
			if (match($0, /"body": *"/)) { inb = 1; s = substr($0, RSTART + RLENGTH) }
			else next
		} else s = $0
		n = length(s); res = ""; i = 1; stop = 0
		while (i <= n) {
			c = substr(s, i, 1)
			if (c == "\\") {
				nx = substr(s, i + 1, 1)
				if (nx == "n") res = res "\n"
				else if (nx == "t") res = res "\t"
				else if (nx == "r") res = res ""
				else res = res nx
				i += 2; continue
			}
			if (c == "\"") { stop = 1; break }
			res = res c; i++
		}
		printf "%s", res
		if (stop) exit
		printf "\n"
	}
' "$TMP" > "$STATE/update.notes" 2>/dev/null

{
	printf 'date\t%s\n' "$_date"
	printf 'version\t%s\n' "$_ver"
	printf 'tag\t%s\n' "$_tag"
	printf 'url\t%s\n' "$_url"
	printf 'apiurl\t%s\n' "$_apiurl"
	printf 'size\t%s\n' "$_size"
	printf 'page\thttps://github.com/%s/releases/tag/%s\n' "$_repo" "$_tag"
} > "$STATE/update.info.new" 2>/dev/null
mv -f "$STATE/update.info.new" "$STATE/update.info" 2>/dev/null
date +%s > "$STATE/update.at" 2>/dev/null
rm -f "$TMP" 2>/dev/null

say "последняя версия на GitHub: $_ver${_url:+ (пакет найден)}"
[ -n "$_url" ] || say "в релизе нет файла .ipk — установить кнопкой не получится, только ссылкой"
exit 0
