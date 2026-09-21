# Показывает домены указанного готового списка:
#   awk -v name=VK -v lim=200 -f geo-list.awk /usr/share/xray/geosite.dat
# Печатает «домен<TAB>тип» и в конце строку «#всего<TAB>сколько».
# Тип: 0/2 — домен и поддомены, 3 — ровно этот домен, 1 — шаблон.

BEGIN {
	RS = "\n"
	for (_i = 0; _i < 256; _i++) M[sprintf("%c", _i)] = _i
	tag = ""; prev = ""; prev2 = ""
	want = tolower(name)
	if (lim == "") lim = 200
	total = 0
}

function is_short_varint(s,   k, i) {
	k = length(s)
	if (k < 1 || k > 3) return 0
	for (i = 1; i < k; i++) if (M[substr(s, i, 1)] < 128) return 0
	return 1
}

{
	rec = $0
	n = length(rec)

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
	if (tolower(tag) != want) next
	for (p = 1; p <= n - 4; p++) {
		if (M[substr(rec, p, 1)] != 8) continue
		ty = M[substr(rec, p + 1, 1)]
		if (ty < 0 || ty > 3) continue
		if (M[substr(rec, p + 2, 1)] != 18) continue
		L = M[substr(rec, p + 3, 1)]
		if (L < 1 || L > 120 || p + 3 + L > n) continue
		v = substr(rec, p + 4, L)
		if (v ~ /[^ -~]/) { p += 3 + L; continue }
		total++
		if (total <= lim) print v "\t" ty
		p += 3 + L
	}
}

END { printf "#всего\t%d\n", total }
