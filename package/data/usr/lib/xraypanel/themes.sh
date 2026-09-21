#!/bin/sh
# Оформление панели: общий каркас на CSS-переменных + варианты тем.
# Тема выбирается в «Настройках» (uci xraypanel.settings.theme).

THEME_LIST="classic compact dark sidebar tiles luci sidebar-dark winxp"

theme_name() {
	_t=$(cfg theme classic)
	case " $THEME_LIST " in
		*" $_t "*) printf '%s' "$_t" ;;
		*)         printf 'classic' ;;
	esac
}

theme_title() {
	case "$1" in
		classic) printf 'Классическая' ;;
		compact) printf 'Компактная — плотные списки и кнопки в строку' ;;
		dark)    printf 'Тёмная' ;;
		sidebar) printf 'С боковым меню (как PassWall)' ;;
		tiles)   printf 'Плитками, крупные кнопки (как HomeProxy)' ;;
		luci)    printf 'В стиле LuCI' ;;
		sidebar-dark) printf 'Тёмная с боковым меню' ;;
		winxp)   printf 'В стиле Windows XP' ;;
		*)       printf '%s' "$1" ;;
	esac
}

theme_style() {
	_t=$(theme_name)
	cat <<'CSS'
:root{
 --bg:#f4f5f7; --fg:#1b1f27;
 --hd-bg:#1f2937; --hd-fg:#ffffff; --nav:#cbd5e1; --nav-on:#ffffff; --nav-line:#60a5fa;
 --card:#ffffff; --card-bd:#e2e5ea; --card-radius:10px; --card-pad:14px; --card-shadow:none;
 --muted:#6b7280; --ok:#15803d; --bad:#b91c1c;
 --th-bg:#f8fafc; --td-bd:#eceff3; --table-fs:14px;
 --btn:#2563eb; --btn-fg:#ffffff; --btn-bd:#2563eb;
 --btn2:#ffffff; --btn2-fg:#2563eb; --btn2-bd:#2563eb;
 --danger-fg:#b91c1c; --danger-bd:#f0c4c4;
 --input-bg:#ffffff; --input-bd:#cfd5de; --input-pad:5px 7px;
 --code-bg:#0f172a; --code-fg:#e2e8f0;
 --msg-bg:#ecfdf5; --msg-bd:#a7f3d0; --msg-fg:#065f46;
 --row-ok:#ecfdf5; --row-bad:#fef2f2;
 --gap:12px; --main-max:1400px;
}
*{box-sizing:border-box}
body{font:14px/1.45 system-ui,-apple-system,Segoe UI,Roboto,sans-serif;margin:0;background:var(--bg);color:var(--fg)}
header{background:var(--hd-bg);color:var(--hd-fg);padding:10px 16px;display:flex;gap:14px;align-items:center;flex-wrap:wrap}
header b{font-size:16px}
nav a{color:var(--nav);text-decoration:none;margin-right:12px;display:inline-block}
nav a.on{color:var(--nav-on);font-weight:600;border-bottom:2px solid var(--nav-line);padding-bottom:2px}
main{padding:16px;max-width:var(--main-max);margin:0 auto;min-width:0;overflow-x:auto}
.card{background:var(--card);border:1px solid var(--card-bd);border-radius:var(--card-radius);padding:var(--card-pad);margin-bottom:var(--card-pad);box-shadow:var(--card-shadow)}
h2{font-size:15px;margin:0 0 10px}
h3{font-size:13px;margin:14px 0 6px;color:var(--muted);text-transform:uppercase;letter-spacing:.03em}
table{border-collapse:collapse;width:100%;font-size:var(--table-fs)}
th,td{border-bottom:1px solid var(--td-bd);padding:6px 8px;text-align:left;vertical-align:top;overflow-wrap:anywhere;word-break:break-word}
th{background:var(--th-bg);font-size:12px;text-transform:uppercase;color:var(--muted)}
input,select,textarea{font:inherit;padding:var(--input-pad);border:1px solid var(--input-bd);border-radius:7px;width:100%;background:var(--input-bg);color:var(--fg)}
label{display:block;font-size:12px;color:var(--muted);margin:8px 0 2px}
/* поля не растягиваются на всю ширину экрана: иначе на большом мониторе
   получается много пустого места */
.row{display:grid;grid-template-columns:repeat(auto-fit,minmax(190px,320px));gap:10px;justify-content:start}
button,.btn{font:inherit;padding:6px 12px;border-radius:8px;border:1px solid var(--btn-bd);background:var(--btn);color:var(--btn-fg);cursor:pointer;text-decoration:none;display:inline-block;margin:0 4px 4px 0}
.btn.sec{background:var(--btn2);color:var(--btn2-fg);border-color:var(--btn2-bd)}
.btn.danger{background:var(--btn2);color:var(--danger-fg);border-color:var(--danger-bd)}
/* кнопка применения конфига: красная, пока есть неприменённые изменения,
   зелёная — после применения */
.apply-btn.pending{color:var(--bad);border-color:var(--bad);background:var(--btn2);font-weight:600}
.apply-btn.done{color:var(--ok);border-color:var(--ok);background:var(--btn2);font-weight:600}
/* ручка перетаскивания правил: зажать на секунду и тянуть */
.drag-cell{width:26px;text-align:center}
.drag-handle{cursor:grab;color:var(--muted);font-size:17px;line-height:1;user-select:none;touch-action:none;padding:2px 4px}
.drag-handle:hover{color:var(--fg)}
/* выпадающие списки с галочками в таблице правил */
details.dd{position:relative}
details.dd>summary{cursor:pointer;border:1px solid var(--input-bd);border-radius:7px;padding:5px 7px;font-size:13px;background:var(--input-bg);color:var(--fg);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:260px}
details.dd[open]>summary{border-color:var(--nav-line)}
details.dd .dd-body{position:absolute;top:100%;left:0;z-index:30;background:var(--card);border:1px solid var(--card-bd);border-radius:8px;box-shadow:0 10px 26px rgba(0,0,0,.35);padding:6px 8px;min-width:230px;max-height:320px;overflow:auto}
details.dd>label.chk{display:flex;gap:6px;align-items:center;margin:2px 0;font-size:13px}
details.dd>label.chk input{width:auto}
details.dd .dd-body label.chk{display:flex;gap:6px;align-items:center;margin:3px 0;font-size:13px}
details.dd .dd-body label.chk input{width:auto}
/* активное правило: яркая мигающая подсветка */
tr.row-live{background:var(--row-ok);animation:rowpulse 1.6s ease-in-out infinite}
tr.row-live td{background:transparent}
@keyframes rowpulse{0%,100%{background:var(--row-ok)}50%{background:rgba(74,222,128,.35)}}
@media (prefers-reduced-motion:reduce){tr.row-live{animation:none}}
tr.dragging{opacity:.55;background:var(--row-ok)}
tr.drop-target{box-shadow:inset 0 2px 0 0 var(--nav-line)}
/* компактные кнопки действий в таблицах (правила, серверы) */
.acts{display:inline-flex;flex-wrap:wrap;gap:4px;align-items:center}
.acts form{display:inline;margin:0}
.acts .btn,.acts button{padding:2px 7px;margin:0;line-height:1.2;font-size:14px}
.acts{gap:3px}
/* столбец «Работает» у правил: один адрес, остальное — в подсказке */
.rule-seen{display:inline-block;max-width:170px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;vertical-align:bottom}
td[data-label="Работает"],td[data-label="Что ходило"]{max-width:230px}
.report{white-space:pre-line}
/* цветные кнопки порядка правил: чем выше — тем зеленее, чем ниже — тем темнее */
.acts .btn.top,.acts .btn.up,.acts .btn.down,.acts .btn.bottom,.acts .btn.stop,.acts .btn.start{border-color:transparent;color:#fff;font-weight:700}
.acts .btn.top{background:#15803d}
.acts .btn.up{background:#4ade80;color:#04310f}
.acts .btn.down{background:#b45309}
.acts .btn.bottom{background:#7c2d12}
.acts .btn.stop{background:#dc2626}
.acts .btn.start{background:#16a34a}
.ok{color:var(--ok)}.bad{color:var(--bad)}.muted{color:var(--muted)}
code,pre{background:var(--code-bg);color:var(--code-fg);border-radius:8px;padding:10px;display:block;overflow:auto;font-size:12px}
code{display:inline;padding:1px 5px}
.msg{background:var(--msg-bg);border:1px solid var(--msg-bd);color:var(--msg-fg);padding:8px 10px;border-radius:8px;margin-bottom:var(--gap)}
.active{color:var(--ok);font-weight:700}
/* лампочка у правила на странице «Маршруты»: зелёная мигает, пока идёт трафик */
.dot{display:inline-block;width:10px;height:10px;border-radius:50%;background:#cbd5e1;margin-right:6px;vertical-align:middle}
.dot.warm{background:#f59e0b}
.dot.live{background:var(--ok);animation:dotpulse 1.4s ease-out infinite}
@keyframes dotpulse{
 0%{box-shadow:0 0 0 0 rgba(21,128,61,.55)}
 70%{box-shadow:0 0 0 7px rgba(21,128,61,0)}
 100%{box-shadow:0 0 0 0 rgba(21,128,61,0)}
}
@media (prefers-reduced-motion:reduce){.dot.live{animation:none}}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:var(--gap)}
tr.row-ok{background:var(--row-ok)}
tr.row-bad{background:var(--row-bad)}
/* активный выход в таблицах (серверы, реверс, правила): подсвечиваем как
   в «Реверсе» — зелёным и жирным */
.tagmark.active{color:var(--ok);font-weight:700}
.tagmark.bad{color:var(--bad);font-weight:600}
/* галочки в раскрывающемся списке интерфейсов */
details.pick{margin:4px 0}
details.pick>summary{cursor:pointer;font-size:13px;color:var(--muted);padding:4px 0}
label.chk{display:flex;align-items:center;gap:8px;margin:3px 0;font-size:13px;color:var(--fg)}
label.chk input{width:auto;margin:0}
/* на узком экране длинные строки таблиц превращаются в карточки */
@media (max-width:760px){
 table.responsive tr{display:block;border:1px solid var(--card-bd);border-radius:8px;margin:0 0 8px;padding:6px 8px}
 table.responsive th{display:none}
 table.responsive td{display:flex;justify-content:space-between;gap:10px;border:none;padding:2px 0;text-align:right}
 table.responsive td:before{content:attr(data-label);color:var(--muted);font-size:12px;text-align:left;flex:0 0 auto}
 table.responsive td:empty{display:none}
 /* длинные адреса и ключи переносим, а кнопки — в одну строку с переносом */
 table.responsive td span,table.responsive td b{overflow-wrap:anywhere;word-break:break-word}
 table.responsive td[data-label="Действия"]{flex-wrap:wrap;justify-content:flex-end}
 table.responsive td[data-label="Действия"] form{display:inline-block;margin:0}
 table.responsive button,table.responsive .btn{padding:4px 8px;font-size:13px}
 /* на телефоне поля идут в одну колонку, а отступы уменьшаем */
 main{padding:10px}
 .card{padding:calc(var(--card-pad) - 2px)}
 .row{grid-template-columns:1fr;justify-content:stretch}
 header{padding:8px 10px;gap:8px}
 nav a{margin-right:8px;font-size:13px}
}
/* длинный адрес подписки или ссылка не должны растягивать карточку */
.url{overflow-wrap:anywhere;word-break:break-all}
CSS
	case "$_t" in
	compact)
		cat <<'CSS'
:root{--card-radius:6px;--card-pad:9px;--gap:8px;--input-pad:3px 6px;--table-fs:13px;--main-max:1400px}
header{padding:6px 12px;gap:10px}
header b{font-size:15px}
nav a{margin-right:9px;font-size:13px}
th,td{padding:3px 6px}
th{font-size:11px}
.card{margin-bottom:8px}
h2{font-size:14px;margin:0 0 6px}
button,.btn{padding:4px 9px;border-radius:6px;font-size:13px}
label{margin:5px 0 1px}
code,pre{padding:6px 8px;font-size:11px}
CSS
		;;
	dark)
		cat <<'CSS'
:root{
 --bg:#0b1220;--fg:#e5e9f0;
 --hd-bg:#111a2b;--hd-fg:#ffffff;--nav:#93a2b8;--nav-on:#ffffff;--nav-line:#3b82f6;
 --card:#141d30;--card-bd:#243049;--muted:#93a2b8;--ok:#4ade80;--bad:#f87171;
 --th-bg:#182238;--td-bd:#22304a;
 --btn:#2563eb;--btn-fg:#ffffff;--btn-bd:#2563eb;
 --btn2:#1b2740;--btn2-fg:#93c5fd;--btn2-bd:#2b3a58;
 --danger-fg:#fca5a5;--danger-bd:#4c1d1d;
 --input-bg:#0f1729;--input-bd:#2b3a58;
 --code-bg:#050b16;--code-fg:#cbd5e1;
 --msg-bg:#0f2a1e;--msg-bd:#1d5c3d;--msg-fg:#86efac;
 --row-ok:#0f2a1e;--row-bad:#2a1416;
}
CSS
		;;
	sidebar)
		cat <<'CSS'
:root{--hd-bg:#ffffff;--hd-fg:#111827;--nav:#374151;--nav-on:#2563eb;--nav-line:#2563eb;--card-radius:8px;--main-max:1400px}
/* minmax(0,1fr) вместо 1fr: иначе длинные строки (ключи, ссылки) растягивают
   колонку шире экрана и появляется горизонтальная прокрутка всей страницы */
body{display:grid;grid-template-columns:230px minmax(0,1fr);grid-template-rows:auto 1fr;grid-template-areas:"brand main" "menu main";min-height:100vh}
header{display:contents}
header b{grid-area:brand;display:block;padding:14px 16px;background:var(--hd-bg);color:var(--hd-fg);border-bottom:1px solid var(--card-bd);font-size:16px}
nav{grid-area:menu;background:var(--hd-bg);border-right:1px solid var(--card-bd);padding:10px 0}
nav a{display:block;margin:0;padding:9px 16px;color:var(--nav);font-size:14px}
nav a:hover{background:var(--th-bg)}
nav a.on{color:var(--nav-on);border-left:3px solid var(--nav-line);border-bottom:none;background:var(--th-bg);font-weight:600}
main{grid-area:main;max-width:var(--main-max);width:100%;margin:0 auto;padding:16px;min-width:0}
@media (max-width:760px){
 body{grid-template-columns:1fr;grid-template-areas:"brand" "menu" "main"}
 nav{display:flex;flex-wrap:wrap;border-right:none;border-bottom:1px solid var(--card-bd);padding:0}
 nav a{padding:8px 12px}
 nav a.on{border-left:none;border-bottom:2px solid var(--nav-line)}
}
CSS
		;;
	tiles)
		cat <<'CSS'
:root{--card-radius:14px;--card-pad:16px;--gap:14px;--main-max:1200px;--card-shadow:0 1px 3px rgba(15,23,42,.08)}
body{background:#eef2f7}
header{background:linear-gradient(90deg,#1d4ed8,#0ea5e9);padding:12px 18px}
nav a{color:#dbeafe;margin-right:14px}
nav a.on{color:#ffffff;border-bottom-color:#ffffff}
main>.card{max-width:none}
table{background:var(--card);border-radius:10px;overflow:hidden}
button,.btn{border-radius:999px;padding:8px 16px;font-weight:600}
input,select,textarea{border-radius:10px;padding:8px 10px}
th{background:transparent;border-bottom:2px solid var(--td-bd)}
h2{font-size:16px}
CSS
		;;
	luci)
		cat <<'CSS'
:root{--bg:#f5f5f5;--hd-bg:#5b6e7e;--hd-fg:#ffffff;--nav:#e3e8ec;--nav-on:#ffffff;--nav-line:#ffffff;
 --card:#ffffff;--card-bd:#c9cdd2;--card-radius:3px;--card-pad:12px;--muted:#5b6472;
 --th-bg:#eef1f4;--td-bd:#dcdfe3;--table-fs:13px;--input-pad:4px 7px;--main-max:1200px;
 --ok:#1a7f37;--bad:#b42318;--row-ok:#eaf7ee;--row-bad:#fdecea}
nav a{margin-right:0;padding:6px 12px;border-bottom:none}
nav a.on{background:var(--card);color:#1f2937;border:1px solid var(--card-bd);border-bottom-color:var(--card);font-weight:600}
input,select,textarea{border-radius:2px}
button,.btn{border-radius:3px;background:#e9ecef;color:#1f2937;border-color:#c9cdd2;font-weight:600}
.btn.danger{background:#fdecea;color:#b42318;border-color:#f3b8b3}
th{text-transform:none;font-weight:700;color:#1f2937}
table{background:var(--card)}
CSS
		;;
	sidebar-dark)
		cat <<'CSS'
/* Тёмная тема с меню слева (как в PassWall, но тёмная) */
:root{
 --bg:#0b1220;--fg:#e5e9f0;--hd-bg:#0f1729;--hd-fg:#ffffff;--nav:#93a2b8;--nav-on:#60a5fa;--nav-line:#3b82f6;
 --card:#141d30;--card-bd:#243049;--card-radius:8px;--muted:#93a2b8;--ok:#4ade80;--bad:#f87171;
 --th-bg:#182238;--td-bd:#22304a;--input-bg:#0f1729;--input-bd:#2b3a58;
 --btn:#2563eb;--btn-fg:#ffffff;--btn-bd:#2563eb;--btn2:#1b2740;--btn2-fg:#93c5fd;--btn2-bd:#2b3a58;
 --danger-fg:#fca5a5;--danger-bd:#4c1d1d;--code-bg:#050b16;--code-fg:#cbd5e1;
 --msg-bg:#0f2a1e;--msg-bd:#1d5c3d;--msg-fg:#86efac;--row-ok:#0f2a1e;--row-bad:#2a1416;--main-max:1400px;
}
*{box-sizing:border-box}
body{display:grid;grid-template-columns:230px minmax(0,1fr);grid-template-rows:auto 1fr;grid-template-areas:"brand main" "menu main";min-height:100vh;background:var(--bg)}
header{display:contents}
header b{grid-area:brand;display:block;padding:14px 16px;background:var(--hd-bg);color:var(--hd-fg);border-bottom:1px solid var(--card-bd)}
nav{grid-area:menu;background:var(--hd-bg);border-right:1px solid var(--card-bd);padding:10px 0}
nav a{display:block;margin:0;padding:9px 16px;color:var(--nav)}
nav a:hover{background:var(--th-bg)}
nav a.on{color:var(--nav-on);background:var(--th-bg);border-left:3px solid var(--nav-line);border-bottom:none;font-weight:600}
main{grid-area:main;max-width:var(--main-max);width:100%;margin:0 auto;padding:16px;min-width:0}
@media (max-width:760px){
 body{grid-template-columns:1fr;grid-template-areas:"brand" "menu" "main"}
 nav{display:flex;flex-wrap:wrap;border-right:none;border-bottom:1px solid var(--card-bd);padding:0}
 nav a{padding:8px 12px}
 nav a.on{border-left:none;border-bottom:2px solid var(--nav-line)}
}
CSS
		;;
	winxp)
		cat <<'CSS'
/* В стиле Windows XP: синие заголовки, серые панели, кнопки с рамкой */
:root{
 --bg:#d4d0c8;--fg:#000000;--hd-bg:#0a246a;--hd-fg:#ffffff;--nav:#d4d0c8;--nav-on:#ffffff;--nav-line:#ffcc00;
 --card:#ece9d8;--card-bd:#808080;--card-radius:3px;--card-pad:10px;--muted:#404040;
 --ok:#006600;--bad:#cc0000;--th-bg:#d4d0c8;--td-bd:#b0aca4;--table-fs:13px;
 --btn:#ece9d8;--btn-fg:#000000;--btn-bd:#808080;--btn2:#ece9d8;--btn2-fg:#000000;--btn2-bd:#808080;
 --input-bg:#ffffff;--input-bd:#7f9db9;--input-pad:3px 5px;--code-bg:#000000;--code-fg:#c0c0c0;
 --msg-bg:#ffffe1;--msg-bd:#c8c8a0;--msg-fg:#000000;--row-ok:#e8f5e8;--row-bad:#fdeaea;--main-max:1400px;
}
body{font-family:Tahoma,Verdana,sans-serif;background:var(--bg)}
header{background:linear-gradient(180deg,#0a246a,#3a6ea5);padding:6px 10px;border-bottom:2px solid #0831d9}
header b{font-weight:700}
nav a{margin-right:8px;padding:3px 10px;border:1px solid transparent;color:#eaf0ff}
nav a.on{background:var(--card);color:#000;border-color:#808080;font-weight:700}
main{padding:12px;max-width:var(--main-max);margin:0 auto;min-width:0}
.card{background:var(--card);border:1px solid #fff;border-right-color:#404040;border-bottom-color:#404040;border-radius:2px;padding:calc(var(--card-pad) - 2px);margin-bottom:10px}
h2{font-size:14px;margin:0 0 8px;color:#000}
table{background:#ffffff;border:1px solid #808080}
th{background:linear-gradient(180deg,#f2f2f2,#dcdcdc);color:#000;text-transform:none;font-weight:700;border-bottom:1px solid #b0aca4}
button,.btn{border-radius:2px;border:1px solid #003c74;background:linear-gradient(180deg,#fdfdfd,#e3e3e3 45%,#cfcfcf);color:#000;padding:4px 12px;font-weight:600}
button:active,.btn:active{border-style:inset}
.btn.danger{color:#a00000}
input,select,textarea{border-radius:1px}
code,pre{border-radius:2px}
/* на телефоне тема не должна сжиматься в узкую колонку посреди экрана */
@media (max-width:760px){
 body{font-size:13px}
 main{padding:8px;max-width:none;width:100%}
 header{padding:6px 8px}
 .card{padding:8px;margin-bottom:8px}
 h2{font-size:13px}
 h3{font-size:12px}
 nav a{padding:2px 7px;margin-right:5px}
 table{font-size:12px}
}
CSS
		;;
	esac
}
