# Поиск домена в файле готовых списков (geosite.dat).
# Запуск: awk -v q=youtube.com -f geo-lookup.awk /usr/share/xray/geosite.dat
# Печатает: «список<TAB>совпавшая строка<TAB>тип».
#
# Файл читается напрямую (как и в geo-parse.awk). Внутри записи домены лежат
# парами «тип + значение»: байты 0x08 <тип> 0x12 <длина> <значение>.
# Тип: 0 — домен и поддомены, 1 — шаблон, 2 — домен и поддомены, 3 — ровно этот.

BEGIN {
	RS = "\n"
	for (_i = 0; _i < 256; _i++) M[sprintf("%c", _i)] = _i
	tag = ""; prev = ""; prev2 = ""
	q = tolower(q)
}

function is_short_varint(s,   k, i) {
	k = length(s)
	if (k < 1 || k > 3) return 0
	for (i = 1; i < k; i++) if (M[substr(s, i, 1)] < 128) return 0
	return 1
}

function matches(t, v,   tail) {
	v = tolower(v)
	if (t == 3) return (v == q)                # ровно этот домен
	if (t == 0 || t == 2) {                    # домен и все поддомены
		if (v == q) return 1
		tail = substr(q, length(q) - length(v))
		return (tail == "." v)
	}
	return 0                                    # шаблоны (regexp) не разбираем
}

{
	rec = $0
	n = length(rec)

	# текущий список: то же правило, что и в разборе названий
	found = 0
	if (n >= 3) {
		b = M[substr(rec, 1, 1)]
		if (b >= 1 && b <= 48 && n >= b + 2) {
			t = substr(rec, 2, b)
			if (M[substr(rec, b + 2, 1)] == 18 && t ~ /^[ -~]+$/) { tag = t; found = 1 }
		}
	}
	if (!found && n >= 11 && (is_short_varint(prev) || (length(prev) == 0 && is_short_varint(prev2)))) {
		t = substr(rec, 1, 10)
		if (M[substr(rec, 11, 1)] == 18 && t ~ /^[ -~]+$/) tag = t
	}
	prev2 = prev; prev = rec

	if (tag == "" || index(rec, "\010") == 0) next
	# домены внутри записи
	for (p = 1; p <= n - 4; p++) {
		if (M[substr(rec, p, 1)] != 8) continue
		ty = M[substr(rec, p + 1, 1)]
		if (ty < 0 || ty > 3) continue
		if (M[substr(rec, p + 2, 1)] != 18) continue
		L = M[substr(rec, p + 3, 1)]
		if (L < 1 || L > 120 || p + 3 + L > n) continue
		v = substr(rec, p + 4, L)
		if (v ~ /[^ -~]/) continue
		if (matches(ty, v)) print tag "\t" v "\t" ty
		p += 3 + L
	}
}
