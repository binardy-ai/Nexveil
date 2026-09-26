# Показывает диапазоны адресов указанного готового списка (geoip):
#   awk -v name=ru -v lim=200000 -f geo-ip-list.awk /usr/share/xray/geoip.dat
# Печатает «адрес/маска<TAB>» и в конце строку «#всего<TAB>сколько».
#
# Устройство файла (protobuf):
#   запись списка = 0x0A <длина> <имя списка>, дальше повторяется CIDR:
#   0x12 0x08 0x0A 0x04 <адрес, 4 байта> 0x10 <маска>
# Байт 0x0A встречается и как разделитель строк, поэтому файл, прочитанный «по
# строкам», разрезан внутри самих CIDR. Здесь поток собирается обратно: куски
# склеиваются (с возвратом разделителя 0x0A), а шаблон CIDR ищется по
# непрерывным байтам, с переносом хвоста между кусками.
#
# Нужно это для лампочек: по списку адресов панель проверяет правило вида
# «geoip:ru» точно, а не «по выходу».

BEGIN {
	RS = "\n"
	for (_i = 0; _i < 256; _i++) M[sprintf("%c", _i)] = _i
	tag = ""; prev = ""; prev2 = ""
	want = tolower(name)
	if (lim == "") lim = 200000
	total = 0
	first = 1
	tail = ""
}

function is_short_varint(s,   k, i) {
	k = length(s)
	if (k < 1 || k > 3) return 0
	for (i = 1; i < k; i++) if (M[substr(s, i, 1)] < 128) return 0
	return 1
}

{
	rec = $0

	# имя списка — по тем же признакам, что и в geo-parse.awk: запись
	# начинается с длины имени, сразу за именем идёт байт 0x12
	found = 0
	nr = length(rec)
	if (nr >= 3) {
		b = M[substr(rec, 1, 1)]
		if (b >= 1 && b <= 48 && nr >= b + 2) {
			t = substr(rec, 2, b)
			if (M[substr(rec, b + 2, 1)] == 18 && t ~ /^[ -~]+$/) { tag = t; found = 1 }
		}
	}
	if (!found && nr >= 11 && (is_short_varint(prev) || (length(prev) == 0 && is_short_varint(prev2)))) {
		t = substr(rec, 1, 10)
		if (M[substr(rec, 11, 1)] == 18 && t ~ /^[ -~]+$/) tag = t
	}
	prev2 = prev; prev = rec

	if (tolower(tag) != want) { first = 0; tail = ""; next }

	# склеиваем поток обратно: между кусками стоял байт-разделитель 0x0A
	piece = (first ? rec : sprintf("%c", 10) rec)
	first = 0
	buf = tail piece
	bl = length(buf)
	off = length(tail)

	for (p = 1; p <= bl - 9; p++) {
		if (M[substr(buf, p, 1)] != 18) continue          # 0x12 — поле CIDR
		if (M[substr(buf, p + 1, 1)] != 8) continue       # длина вложенной записи
		if (M[substr(buf, p + 2, 1)] != 10) continue      # 0x0A — адрес
		if (M[substr(buf, p + 3, 1)] != 4) continue       # адрес ровно 4 байта (IPv4)
		if (M[substr(buf, p + 8, 1)] != 16) continue      # 0x10 — маска
		pre = M[substr(buf, p + 9, 1)]                    # маска: одно число, для IPv4 до 32
		if (pre < 8 || pre > 32) continue
		# то, что уже было в хвосте от прошлого куска, повторно не считаем
		if (p + 9 > off) {
			total++
			if (total <= lim)
				print M[substr(buf, p + 4, 1)] "." M[substr(buf, p + 5, 1)] "." \
					M[substr(buf, p + 6, 1)] "." M[substr(buf, p + 7, 1)] "/" pre "\t"
		}
		p += 8
	}
	tail = (bl > 12) ? substr(buf, bl - 11) : buf
}

END { printf "#всего\t%d\n", total }
