'use strict';
'require view';
'require ui';

/* Страница «Xray-панель» в LuCI: показывает адрес панели и ведёт в неё.
   Добавлена пакетом xraypanel, чтобы адрес всегда можно было найти из роутера. */

return view.extend({
	render: function() {
		var url = '/cgi-bin/xraypanel';

		return E('div', { 'class': 'cbi-map' }, [
			E('h2', { 'name': 'content' }, [ 'Xray-панель' ]),
			E('div', { 'class': 'cbi-map-descr' }, [
				E('p', {}, [ 'Адрес панели: ', E('code', {}, [ url ]) ]),
				E('p', {}, [
					E('a', {
						'class': 'cbi-button cbi-button-apply',
						'href': url,
						'target': '_blank',
						'rel': 'noopener'
					}, [ 'Открыть панель' ])
				]),
				E('p', {}, [
					'Та же страница доступна напрямую: ',
					E('code', {}, [ '/xraypanel.html' ])
				]),
				E('p', { 'style': 'color:#6b7280' }, [
					'Страница добавлена пакетом xraypanel.'
				])
			])
		]);
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
