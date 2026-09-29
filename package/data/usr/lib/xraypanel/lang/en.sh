#!/bin/sh
# Язык интерфейса: English
# Файл подключается из lib.sh (lang_load).
# Ключ = T_ + английский текст; рядом комментарий с исходной строкой.
# XP_JS_KEYS — строки, которые нужны браузерной части (см. xp_js_dict).

XP_JS_KEYS='T_the_whole_local_network T_router_only T_router_and_local_network T_only_selected_clients T_pcs T_none_selected_cannot_enable T_through_the_server_with_the_ T_straight_without_proxy T_through_outbound T_is_not_intercepted_for_clien T_is_intercepted_and_goes_stra T_is_intercepted_and_goes_to_t T_is_not_intercepted_it_goes_a T_goes_through_the_tunnel_the_ T_answers_with_its_own_servers T_plain_dns_over_port_53_2 T_encrypted_doh T_does_not_see_client_dns_is_n T_does_see_client_requests_go_ T_does_not_see_requests_go_pas T_sees_it_only_if_the_devices_ T_depends_on_how_the_devices_a T_does_not_see_names_they_go_o T_sees_names_the_resolver_asks T_does_not_see_names_the_resol T_depends_on_how_the_devices_a_2 T_b_wrapped_b T_br_b_traffic_goes_b T_br_b_client_dns_b T_br_b_router_resolver_b T_br_b_site_names_b_panel T_provider T_br_b_encrypted_dns_b_dot_853 T_closed T_allowed_dns_is_not_intercept T_allowed T_closed_by_list T_browser_and_apple_canaries T_enabled T_disabled_2 T_br_span_class_muted_this_is_ T_saving T_saved T_could_not_save T_did_not_find_the_row_templat T_not_selected T_span_class_muted_new_row_wil T_row_added_choose_sets_and_pr T_drag_the_row_to_the_right_pl T_td_data_label_check_span T_checking T_no_answer T_checking_all T_measuring T_td_data_label_ping T_refreshing T_just_now T_start_typing_category_ru_you T_start_typing_ru_cn_us_privat T_10_0_0_0_8_or_8_8_8_8 T_template_is_empty T_template_does_not_parse T_check_the_brackets T_the_template_has_that_is_an_ T_the_template_matches_everyth T_the_dot_before_the_domain_zo T_write_domains_for_example_vk T_ready_template T_press_add_to_set T_not_saving T_copied T_span_class_muted_style_font_ T_press_to_remove T_holding T_added_to_the_box T_already_in_the_box T_downloading_the_files_and_re T_could_not_start_the_update T_enter_the_list_name T_looking T_reading_the_lists_this_takes T_could_not_look T_enter_a_domain T_searching_the_list_files_are T_could_not_check T_making_two_requests_this_tak T_checking_2 T_collecting_names_this_takes_ T_collecting_failed_look_into_ T_sec_ago T_min_ago T_h_ago T_b T_kb T_mb T_gb T_tb T_set T_removed_traffic_goes_as_usua T_cancelled_the_rules_stay T_will_work_in T_sec_press_confirm T_waiting_for_confirmation T_not_active T_0_b T_b_straight_b T_b_blocked_b T_ago T_span_class_muted_also T_span_class_muted_no_fresh_en T_no_entries T_in_10_minutes T_outbound_2 T_in_10_minutes_2 T_no_fresh_entries T_clients T_router T_through_the_tunnel T_straight_2 T_span_class_muted_empty_so_fa T_not_applied T_differences T_h2_differences_with_the_file T_p_class_ok_config_applied_th T_config_applied_xray_restarte T_applying T_config_is_being_applied T_p_class_muted_collecting_p T_p_class_bad_could_not_collec T_enable_bridge T_disable_bridge_stays_in_the_'

T_dns_and_other_udp='DNS and other UDP'
T_dns_through_tunnel='DNS through tunnel'
T_mac='MAC'
T_quic_udp_443='QUIC (UDP 443)'
T_socks_api='SOCKS / API'
T_xray_is_not_installed='xray is not installed'
T_service_autostart='Service autostart'
T_auto_rollback='Auto-rollback'
T_address='Address'
T_panel_address='Panel address'
T_activity='Activity'
T_xray_binary='xray binary'
T_backup='Backup'
T_extra_json_files_in_the_conf='Extra .json files in the config directory'
T_panel_version='Panel version'
T_enable_xray_autostart='Enable xray autostart'
T_restore_from_text='Restore from text'
T_restoring_settings='Restoring settings'
T_set_log_time_to_router_time='Set log time to router time'
T_outbound='Outbound'
T_outbound_server='Outbound (server)'
T_default_outbound='Default outbound'
T_actions='Actions'
T_add_and_update='Add and update'
T_add_from_link='Add from link'
T_add_server_from_link='Add server from link'
T_share='Share'
T_domain='Domain'
T_upload='Upload'
T_upload_and_restore='Upload and restore'
T_entries='Entries'
T_value='Value'
T_modified='Modified'
T_or_paste_as_text='Or paste as text'
T_name='Name'
T_internet_traffic='Internet traffic'
T_which_reverse_modes_your_bui='Which reverse modes your build supports'
T_which_xray_builds_support_it='Which xray builds support it'
T_config='Config'
T_config_cannot_be_built='Config cannot be built'
T_who_goes='Who goes'
T_where_sets='Where (sets)'
T_where_traffic_goes='Where traffic goes'
T_where_the_traffic_goes='Where the traffic goes'
T_local_network_and_the_router='Local network and the router itself'
T_routes='Routes'
T_address_and_domain_sets='Address and domain sets'
T_names='Names'
T_names_parsed='Names parsed'
T_settings='Settings'
T_panel_settings='Panel settings'
T_panel_update='Panel update'
T_updated='Updated'
T_roll_back_config='Roll back config'
T_response='Response'
T_panel_without_a_password='Panel without a password'
T_restart_xray='Restart xray'
T_rename='Rename'
T_dns_interception='DNS interception'
T_ping_network='Ping (network)'
T_subscriptions='Subscriptions'
T_intercept_port='Intercept port'
T_last_start='Last start'
T_last_xray_restart='Last xray restart'
T_rules='Rules'
T_routing_rules='Routing rules'
T_firewall_rules='Firewall rules'
T_apply_config='Apply config'
T_check_proxy='Check (proxy)'
T_check_what_the_panel_sees='Check: what the panel sees'
T_transparent_mode='Transparent mode'
T_proxy='Proxy'
T_differences_with_the_file_on='Differences with the file on the router'
T_size='Size'
T_parsed='Parsed'
T_reverse='Reverse'
T_reverse_bridges='Reverse bridges'
T_mode_in_settings='Mode in settings'
T_xray_itself='xray itself'
T_currently_in_use_from_the_lo='Currently in use (from the log)'
T_traffic_is_currently_going_t='Traffic is currently going through'
T_servers='Servers'
T_download_settings='Download settings'
T_service='Service'
T_change_panel_version='Change panel version'
T_create_set='Create set'
T_status='Status'
T_saving_settings='Saving settings'
T_save='Save'
T_save_bridge='Save bridge'
T_save_settings='Save settings'
T_save_rule='Save rule'
T_list='List'
T_mode='Mode'
T_reverse_mode='Reverse mode'
T_status_2='Status'
T_tag='Tag'
T_bridge_tag='Bridge tag'
T_traffic='Traffic'
T_remove_extra_json_files='Remove extra .json files'
T_delete_bridge='Delete bridge'
T_delete_rule='Delete rule'
T_delete_server='Delete server'
T_nodes='Nodes'
T_file='File'
T_config_file='Config file'
T_log_time_zone='Log time zone'
T_through_what='Through what'
T_what='What'
T_contains='Contains'
T_what_next='What next'
T_what_went_through_the_interc='What went through the interceptor'
T_what_you_will_get='What you will get'
T_what_the_current_settings_wi='What the current settings will produce'
T_what_was_visited='What was visited'
T_what_it_is='What it is'
T_address_2='address'
T_enable_dns_query_logging='enable DNS query logging'
T_enable_proxy='enable proxy'
T_add_rule='add rule'
T_route='route'
T_measure_ping='measure ping'
T_goes_through='goes through'
T_name_2='name'
T_or_turn_it_off='or turn it off'
T_update='update'
T_update_lists_from_the_intern='update lists from the internet'
T_update_lists_now='update lists now'
T_confirm='confirm'
T_install_selected='install selected'
T_install_list_packages='install list packages'
T_fix_now='fix now'
T_check='check'
T_check_all='check all'
T_check_domain='check domain'
T_check_name='check name'
T_check_for_updates_now='check for updates now'
T_parse_lists='parse lists'
T_parse_set_lists='parse set lists'
T_reset='reset'
T_reset_traffic_for_all='reset traffic for all'
T_make_default='make default'
T_rebuild_names='rebuild names'
T_collect_list_names='collect list names'
T_build_template='build template'
T_save_2='save'
T_save_entry_changes='save entry changes'
T_save_folders='save folders'
T_traffic_2='traffic ↑/↓'
T_remove_duplicates='remove duplicates'
T_delete='delete'
T_delete_set='delete set'
T_what_is_in_the_list='what is in the list'
T_geo_lists_files_and_updates_='Geo lists: files and updates from the internet'
T_geo_lists_of_domains_and_add='Geo lists of domains and addresses (geosite / geoip)'
T_update_log_from_the_internet='Update log (from the internet)'
T_list_update_log='List update log'
T_transparent_mode_log='Transparent mode log'
T_set_list_parsing_log='Set list parsing log'
T_name_collection_log='Name collection log'
T_short_which_reverse_works_wi='Short: which reverse works with which build'
T_why_the_intercept_entry_did_='Why the intercept entry did not come up'
T_rules_currently_in_place='Rules currently in place'
T_choose_interfaces='choose interfaces'
T_last_check_log_detailed='last check log (detailed)'
T_update_check_log='update check log'
T_installation_log='installation log'
T_more_about_dns_and_intercept='more about DNS and interception'
T_show_sets_and_their_content='show sets and their content'
T_full_log_lines='full log lines'
T_apply_config_2='apply config'
T_config_applied='config applied'

# --- второй этап: подписи полей, списки, подсказки ---
# Проверка
T_check_2='Check'
# Пинг
T_ping='Ping'
# собираю…
T_collecting='collecting…'
# Это куда идёт трафик, который не попал ни под одно правило: клиенты SOCKS-входа панели (10808), прозрачный режим в варианте «по правилам панели» и всё остальное без явного маршрута. Реверс-мосты и правила маршрутизации его не используют. Если включён автовыбор по пингу, эта настройка не участвует.
T_this_is_where_traffic_goes_t='This is where traffic goes that did not match any rule: clients of the panel SOCKS inbound (10808), transparent mode with the “panel rules” option, and everything else without an explicit route. Reverse bridges and routing rules do not use it. If auto-select by ping is on, this setting is not used.'
# «Применить конфиг» — собрать конфиг xray из настроек панели, проверить его и перезапустить службу. «Откат конфига» — вернуть прежний конфиг из единственной копии, которую панель сохраняет перед применением.
T_apply_config_build_the_xray_='“Apply config” — build the xray config from the panel settings, check it and restart the service. “Roll back config” — restore the previous config from the only copy the panel keeps before applying.'
# Можно поставить другую версию панели, не заходя по ssh: положите файл <b>.ipk</b> на роутер (например в <code>/tmp</code>) или загрузите его кнопкой ниже. Настройки, серверы и правила при этом не трогаются — меняется только сама панель, xray не перезапускается.
T_you_can_install_another_pane='You can install another panel version without ssh: put the package file (<b>.ipk</b> for older systems, <b>.apk</b> for new ones) on the router (for example into <code>/tmp</code>) or upload it with the button below. Settings, servers and rules are not touched — only the panel itself changes, xray is not restarted.'
# Выберите пакет
T_choose_a_package='Choose a package'
# %s — версия %s (стоит сейчас)
T_s_version_s_current='%s — version %s (current)'
# %s — версия %s, %s
T_s_version_s_s='%s — version %s, %s'
# Проверяются папки: <code>%s</code>. Их можно поменять командой <code>uci set xraypanel.settings.panel_ipk_dirs=\"/tmp /etc/xraypanel/versions\"</code>.
T_checked_folders_code_s_code_='Checked folders: <code>%s</code>. You can change them with <code>uci set xraypanel.settings.panel_ipk_dirs=\"/tmp /etc/xraypanel/versions\"</code>.'
# Пакетов не нашлось. Проверенные папки: <code>%s</code>. Загрузите файл — он попадёт в <code>/etc/xraypanel/versions</code> и появится здесь.
T_no_packages_found_checked_fo='No packages found. Checked folders: <code>%s</code>. Upload a file — it will be put into <code>/etc/xraypanel/versions</code> and appear here.'
# Загрузить пакет .ipk с компьютера
T_upload_ipk_package_from_the_='Upload a package (.ipk or .apk) from the computer'
# Папки, где искать пакеты (через пробел)
T_folders_to_look_for_packages='Folders to look for packages in (space separated)'
# Перед установкой панель запоминает пакет, который стоял до этого, — на него возвращает кнопка «вернуть прежнюю версию». Если новая версия не откроется совсем, спасают только ssh и <code>opkg install --force-reinstall /tmp/<файл>.ipk</code>.
T_before_installing_the_panel_='Before installing, the panel remembers the package that was installed before — the “restore previous version” button brings it back. If the new version does not open at all, only ssh and installing the package file by hand will help: <code>opkg install --force-reinstall /tmp/xraypanel_&lt;version&gt;_all.ipk</code> (on apk systems: <code>apk add --allow-untrusted /tmp/xraypanel_&lt;version&gt;_all.apk</code>).'
# Журнал установки:
T_installation_log_2='Installation log:'
# Если из репозитория не получится — поставьте вручную: <code>opkg update &amp;&amp; opkg install xray-core</code>, затем «Применить конфиг».
T_if_it_does_not_work_from_the='If it does not work from the repository — install manually: <code>opkg update &amp;&amp; opkg install xray-core</code>, then “Apply config”.'
# Если тут ошибка — xray не поднялся, проверьте конфиг кнопкой «Откат конфига».
T_if_there_is_an_error_here_xr='If there is an error here — xray did not start, check the config with the “Roll back config” button.'
# время реального запроса через сервер — именно по нему работает автовыбор «по лучшему пингу»
T_time_of_the_real_request_thr='time of the real request through the server — this is what the “best ping” auto-select uses'
# пинг сети до сервера, без учёта его канала
T_network_ping_to_the_server_i='network ping to the server, its channel is not taken into account'
# включить сервер
T_enable_server='enable server'
# выключить сервер (останется в списке, но уйдёт из конфига)
T_disable_server_stays_in_the_='disable server (stays in the list, but leaves the config)'
# этот сервер — выход по умолчанию: сюда идёт трафик без своего правила
T_this_server_is_the_default_o='this server is the default outbound: traffic without its own rule goes here'
# весь трафик без своего правила пойдёт через этот сервер (автовыбор по пингу будет выключен)
T_all_traffic_without_its_own_='all traffic without its own rule will go through this server (ping auto-select will be turned off)'
# Автовыбор «по лучшему пингу» смотрит на столбец <b>«Проверка (прокси)»</b> — это время реального запроса через сервер (его меряет сам xray каждые %s с). Столбец <b>«Пинг (сеть)»</b> показывает только сеть до сервера и для выбора не используется: сервер с малым пингом может оказаться медленным, если у него плохой канал или маршрут к сайтам.
T_best_ping_auto_select_looks_='“Best ping” auto-select looks at the <b>“Check (proxy)”</b> column — that is the real request time through the server (xray measures it every %s s). The <b>“Ping (network)”</b> column shows only the network to the server and is not used for the choice: a server with a small ping can be slow if its channel or route to the sites is bad.'
# Последняя проверка: <b>%s</b>.
T_last_check_b_s_b='Last check: <b>%s</b>.'
# «Проверка» — это не пинг, а скачивание тестового адреса через сервер: видно, работает ли узел на самом деле. Адрес и порт проверки задаются в «Настройках», там же можно включить периодическую проверку.
T_check_is_not_a_ping_but_down='“Check” is not a ping, but downloading a test address through the server: you can see whether the node really works. The check address and port are set in “Settings”, and periodic checks can be turned on there too.'
# Проверка одного узла занимает несколько секунд (панель поднимает отдельный xray и качает через него тестовую страницу). «Проверить все» идёт в фоне: результаты появляются в таблице сами, страница не перезагружается.
T_checking_one_node_takes_a_fe='Checking one node takes a few seconds (the panel starts a separate xray and downloads a test page through it). “Check all” runs in the background: results appear in the table by themselves, the page is not reloaded.'
# Кнопка ⏸ выключает сервер, не удаляя его: он остаётся в списке серым, но в конфиг xray не попадает — его нет ни в автовыборе, ни в правилах. Кнопка ▶ возвращает его обратно. Правила, которые указывают на выключенный сервер, тоже не применяются.
T_the_button_disables_a_server='The ⏸ button disables a server without deleting it: it stays in the list greyed out, but does not get into the xray config — it is neither in auto-select nor in the rules. The ▶ button brings it back. Rules that point to a disabled server are not applied either.'
# Серверы, занятые реверс-мостами (они работают как выход для моста), показаны <b style="color:#2563eb">жирным синим</b> — имя, тег и адрес.
T_servers_used_by_reverse_brid='Servers used by reverse bridges (they work as the outbound for the bridge) are shown in <b style="color:#2563eb">bold blue</b> — name, tag and address.'
# Столбец «Пинг» заполняется по кнопке <b>«замерить пинг»</b> (замер идёт при открытии страницы по этой кнопке, чтобы обычная загрузка не тормозила). Столбец «Проверка» — это не пинг, а скачивание тестового адреса через сервер.
T_the_ping_column_is_filled_by='The “Ping” column is filled by the <b>“measure ping”</b> button (the measurement runs when the page is opened with this button, so the usual page load is not slowed down). The “Check” column is not a ping, but downloading a test address through the server.'
# Подписка — это ссылка, по которой сервер отдаёт список узлов. Панель скачивает его и сама создаёт серверы; при обновлении узлы этой подписки заменяются свежими (ваши личные серверы не трогаются).
T_a_subscription_is_a_link_fro='A subscription is a link from which the server serves a list of nodes. The panel downloads it and creates servers itself; when updating, the nodes of this subscription are replaced with fresh ones (your own servers are not touched).'
# Имя подписки (латиницей)
T_subscription_name_latin_lett='Subscription name (latin letters)'
# Адрес подписки
T_subscription_address='Subscription address'
# User-Agent (некоторые серверы требуют свой)
T_user_agent_some_servers_requ='User-Agent (some servers require their own)'
# Некоторые подписки отдают узлы только определённым клиентам — тогда помогает поле User-Agent (например <code>v2rayNG/1.8.5</code> или <code>Clash</code>).
T_some_subscriptions_give_node='Some subscriptions give nodes only to certain clients — then the User-Agent field helps (for example <code>v2rayNG/1.8.5</code> or <code>Clash</code>).'
# Ссылка vless:// (Reality)
T_vless_link_reality='vless:// link (Reality)'
# vless://uuid@server:443?security=reality&amp;pbk=...&amp;sid=...&amp;sni=...&amp;flow=xtls-rprx-vision#имя
T_vless_uuid_server_443_securi='vless://uuid@server:443?security=reality&amp;pbk=...&amp;sid=...&amp;sni=...&amp;flow=xtls-rprx-vision#name'
# Из ссылки берутся адрес, порт, UUID, flow, SNI, публичный ключ, short ID и отпечаток. Название после # становится именем сервера. Реверс ссылкой не передаётся — он настраивается в разделе «Реверс».
T_the_link_gives_the_address_p='The link gives the address, port, UUID, flow, SNI, public key, short ID and fingerprint. The name after # becomes the server name. Reverse is not passed by a link — it is set in the “Reverse” section.'
# Имя раздела (латиницей, необязательно)
T_section_name_latin_letters_o='Section name (latin letters, optional)'
# Протокол
T_protocol='Protocol'
# Метод шифрования (можно выбрать из списка)
T_encryption_method_can_be_cho='Encryption method (can be chosen from the list)'
# aes-256-gcm или 2022-blake3-aes-256-gcm
T_aes_256_gcm_or_2022_blake3_a='aes-256-gcm or 2022-blake3-aes-256-gcm'
# Пароль
T_password='Password'
# Сеть (tcp или ws)
T_network_tcp_or_ws='Network (tcp or ws)'
# Путь (для ws)
T_path_for_ws='Path (for ws)'
# Host (для ws)
T_host_for_ws='Host (for ws)'
# нет
T_no='no'
# да
T_yes='yes'
# Проверять сертификат
T_verify_certificate='Verify certificate'
# проверять
T_verify='verify'
# не проверять (allowInsecure)
T_do_not_verify_allowinsecure='do not verify (allowInsecure)'
# Обфускация
T_obfuscation='Obfuscation'
# salamander (как в Hysteria 2)
T_salamander_as_in_hysteria_2='salamander (as in Hysteria 2)'
# Пароль обфускации
T_obfuscation_password='Obfuscation password'
# obfs-password из ссылки
T_obfs_password_from_the_link='obfs-password from the link'
# Приватный ключ клиента (secretKey)
T_client_private_key_secretkey='Client private key (secretKey)'
# Публичный ключ сервера (publicKey)
T_server_public_key_publickey='Server public key (publicKey)'
# Адрес клиента (например 10.0.0.2/32)
T_client_address_for_example_1='Client address (for example 10.0.0.2/32)'
# Куда направлять (allowedIPs)
T_where_to_route_allowedips='Where to route (allowedIPs)'
# Сменить общий способ
# старый — по домену (нужна сборка xray до 26.4.18)
# новый — VLESS Reverse Proxy по тегу (сборка 25.9.11+)
T_new_vless_reverse_proxy_by_t='new — VLESS Reverse Proxy by tag (build 25.9.11+)'
# Панель определяет возможности установленного бинарника сама: даёт ему тестовый конфиг и запоминает ответ, пока бинарник не заменят. В конфиг попадает только тот способ, который сборка понимает, — поэтому служба не падает и менять настройки вручную не нужно.
T_the_panel_detects_the_capabi='The panel detects the capabilities of the installed binary itself: it gives it a test config and remembers the answer until the binary is replaced. Only the method the build understands gets into the config — so the service does not fall over and nothing has to be changed by hand.'
# Для нового способа важно, чтобы версии xray на роутере и на портале были совместимы. Проверено 26.09.2026: портал 26.9.9 с мостом 26.4.17 не работает — соединение в панели есть, а ответы не возвращаются. Держите на портале и на роутере близкие версии.
T_for_the_new_method_it_is_imp='For the new method it is important that the xray versions on the router and on the portal are compatible. Checked on 26.09.2026: portal 26.9.9 with bridge 26.4.17 does not work — the panel shows a connection, but no answers come back. Keep close versions on the portal and on the router.'
# Хотите оба способа сразу — нужна сборка, которая понимает и старый, и новый (последняя из проверенных — 26.4.17), и портал, совместимый с её новым реверсом. Если на портале свежий xray, надёжнее держать свежий и на роутере и работать только новым способом.
T_if_you_want_both_methods_at_='If you want both methods at once — you need a build that understands both the old and the new one (the last one checked — 26.4.17), and a portal compatible with its new reverse. If the portal has a fresh xray, it is safer to keep the router fresh too and use only the new method.'
# Способ у отдельного моста задаётся в его форме, поле «Способ реверса»; «как у роутера» — значит берётся общий способ, выбранный выше.
# Мост — это обратный туннель: роутер сам подключается к серверу-порталу, и через него к тебе «заходят» сервисы роутера (LuCI, SSH и т.п.).
# время ответа выходного сервера (живой замер при открытии страницы)
T_response_time_of_the_outboun='response time of the outbound server (live measurement when the page is opened)'
# включить мост
T_enable_bridge='enable bridge'
# выключить мост (останется в списке)
T_disable_bridge_stays_in_the_='disable bridge (stays in the list)'
# новый способ — VLESS Reverse Proxy, связь по тегу моста
T_new_method_vless_reverse_pro='new method — VLESS Reverse Proxy, connection by bridge tag'
# старый способ — порталы и мосты по домену
T_old_method_portals_and_bridg='old method — portals and bridges by domain'
# Работающие мосты — зелёным, отвалившиеся — красным. Причина написана в столбце «Состояние»: панель сначала смотрит, есть ли у роутера живое соединение с сервером моста, а если не видно — насколько свежие записи моста в журнале xray.
# Кнопка ⏸ выключает мост, не удаляя его: он остаётся в списке серым, но в конфиг не попадает — туннель не поднимается, пока его не включат обратно.
T_the_button_disables_a_bridge='The ⏸ button disables a bridge without deleting it: it stays in the list greyed out but does not get into the config — the tunnel does not come up until it is turned on again.'
# Если тут написано «таблица соединений: НЕТ» или пусто в «есть команды» — пришлите этот текст, я скажу, что установить.
# как у роутера (сейчас: %s)
# старый — по домену (xray до 26.4.25)
T_old_by_domain_xray_before_26='old — by domain (xray before 26.4.25)'
# новый — VLESS Reverse Proxy по тегу (xray 25.9.11+)
T_new_vless_reverse_proxy_by_t_2='new — VLESS Reverse Proxy by tag (xray 25.9.11+)'
# Новый способ: на сервере-портале у клиента VLESS-входа должен стоять <code>"reverse": {"tag": "имя"}</code> — тогда трафик, предназначенный мосту, уйдёт в этот тег. А в поле «Выход» ниже выбирайте сервер, у которого в UUID прописан именно этот клиент портала.
T_new_method_on_the_portal_ser='New method: on the portal server the client of the VLESS inbound must have <code>"reverse": {"tag": "name"}</code> — then traffic meant for the bridge goes into this tag. And in the “Outbound” field below choose the server whose UUID contains exactly this portal client.'
# Выход (через какой сервер подключаться к порталу)
T_outbound_which_server_to_con='Outbound (which server to connect to the portal through)'
# %s — сервер не найден (проверьте, не удалён ли он)
T_s_server_not_found_check_whe='%s — server not found (check whether it was deleted)'
# direct — напрямую, без сервера
T_direct_straight_without_a_se='direct — straight, without a server'
# Куда выпускать трафик из туннеля
T_where_to_release_traffic_fro='Where to release traffic from the tunnel'
# домашняя сеть и интернет — роутер, локальные устройства и выход в интернет через домашний канал
T_home_network_and_internet_th='home network and internet — the router, local devices and internet access through the home channel'
# только интернет — домашняя сеть закрыта (ни роутер, ни локальные устройства недоступны)
T_internet_only_the_home_netwo='internet only — the home network is closed (neither the router nor local devices are reachable)'
# blocked — заблокировать
T_blocked_block='blocked — block'
# «Выход» — через какой сервер роутер подключается к порталу. «Куда выпускать трафик из туннеля» — куда уходит трафик клиента, который пришёл по реверсу: <b>домашняя сеть и интернет</b> — доступны и роутер с локальными устройствами, и выход в интернет через домашний канал; <b>только интернет</b> — домашняя сеть закрыта, клиент увидит внешний адрес роутера; <code>blocked</code> — не выпускать никуда; либо выбранный сервер.
T_outbound_which_server_the_ro='“Outbound” — which server the router connects to the portal through. “Where to release traffic from the tunnel” — where the traffic of a client that came through the reverse goes: <b>home network and internet</b> — both the router with local devices and internet access through the home channel are available; <b>internet only</b> — the home network is closed, the client will see the external address of the router; <code>blocked</code> — release nowhere; or a chosen server.'
# В списке выходов видны все серверы с их адресами — выбирайте из списка, вручную тег писать не нужно. «Выключен» рядом с сервером означает, что он не попадёт в конфиг, пока его не включат на странице «Серверы».
T_all_servers_with_their_addre='All servers with their addresses are visible in the outbound list — choose from the list, there is no need to write the tag by hand. “Disabled” next to a server means it will not get into the config until it is turned on on the “Servers” page.'
# по пингу — самый быстрый сервер
T_by_ping_the_fastest_server='by ping — the fastest server'
# %s (текущий, не из списка)
T_s_current_not_in_the_list='%s (current, not in the list)'
# просто напрямую
T_just_straight='just straight'
# через интерфейс %s
T_through_interface_s='through interface %s'
# — все устройства —
T_all_devices='— all devices —'
# вся локальная сеть (%s)
T_the_whole_local_network_s='the whole local network (%s)'
# %s (текущий адрес правила)
T_s_current_rule_address='%s (current rule address)'
# Их ставят пакеты v2ray-geosite и v2ray-geoip. Кнопка ниже поставит их в фоне.
T_they_are_installed_by_the_v2='They are installed by the v2ray-geosite and v2ray-geoip packages. The button below installs them in the background.'
# Названия для «списка доменов» и «списка адресов» панель берёт из файлов самого роутера — значит, список точно совпадает с тем, что умеет ваш xray.
T_the_panel_takes_the_names_fo='The panel takes the names for the “domain list” and the “address list” from the router'\''s own files — so the list exactly matches what your xray can do.'
# Набор файлов изменился после сбора — нажмите «собрать названия заново», чтобы список совпадал с файлами.
T_the_set_of_files_changed_aft='The set of files changed after collecting — press “collect names again” so the list matches the files.'
# Названия списков ещё не собраны. Это разово и занимает до пары минут — панель делает это в фоне, страницу держать открытой не нужно.
T_the_list_names_have_not_been='The list names have not been collected yet. This is a one-off and takes up to a couple of minutes — the panel does it in the background, the page does not have to stay open.'
# Файлы со списками можно скачать заново — старые сохранятся рядом как .bak, после обновления панель сама пересоберёт названия и перезапустит xray.
T_the_list_files_can_be_downlo='The list files can be downloaded again — the old ones are kept next to them as .bak, after the update the panel rebuilds the names itself and restarts xray.'
# Откуда брать
T_where_to_take_from='Where to take from'
# Loyalsoldier — как в PassWall (домены 10 МБ, адреса 16 МБ)
T_loyalsoldier_like_in_passwal='Loyalsoldier — like in PassWall (domains 10 MB, addresses 16 MB)'
# v2fly — официальные (домены 2 МБ, адреса 22 МБ)
T_v2fly_official_domains_2_mb_='v2fly — official (domains 2 MB, addresses 22 MB)'
# runetfreedom — российские списки (файлы большие: домены ~70 МБ)
T_runetfreedom_russian_lists_f='runetfreedom — Russian lists (files are large: domains ~70 MB)'
# сам роутер (%s)
T_the_router_itself_s='the router itself (%s)'
# по лучшему пингу
T_by_best_ping='by best ping'
# напрямую
T_straight='straight'
# сервер %s
T_server_s='server %s'
# %s (текущий)
T_s_current='%s (current)'
# все устройства
T_all_devices_2='all devices'
# %s (текущий адрес)
T_s_current_address='%s (current address)'
# весь трафик (без набора)
T_all_traffic_without_a_set='all traffic (without a set)'
# зажмите правило на секунду и потяните
T_hold_a_rule_for_a_second_and='hold a rule anywhere for a moment and pull (drag the ⠿ handle directly)'
# Куда
T_where='Where'
# включить правило
T_enable_rule='enable rule'
# выключить правило
T_disable_rule='disable rule'
# удалить правило
T_delete_rule_2='delete rule'
# Правила проверяются сверху вниз: первое подходящее решает, куда пойдёт трафик. Строку можно утащить на другое место — зажмите её на секунду. Наборы адресов — в блоке ниже.
T_rules_are_checked_from_top_t='Rules are checked from top to bottom: the first match decides where the traffic goes. A row can be dragged to another place — hold it for a second. Address sets are in the block below.'
# Новый набор
T_new_set='New set'
# например: Прямые
T_for_example_direct='for example: Direct'
# Переименовать «%s»
T_rename_s='Rename “%s”'
# разобрать готовые списки этого набора: по разобранному списку лампочка в наборе загорается точно так же, как в правиле
T_parse_the_ready_lists_of_thi='parse the ready lists of this set: with a parsed list the lamp in the set lights up exactly like in the rule'
# Наборов пока нет. Создайте первый — обычно это «Прямые», «Прокси» и «Блок».
T_there_are_no_sets_yet_create='There are no sets yet. Create the first one — usually these are “Direct”, “Proxy” and “Block”.'
# включить или выключить запись
T_enable_or_disable_the_entry='enable or disable the entry'
# удалить запись
T_delete_the_entry='delete the entry'
# Готовые списки набора ещё не разобраны: <b>%s</b>. Пока их нет, панель может показать срабатывание только «вероятно» (серым пунктиром) — лампочка в наборе станет точной, как в правиле, после разбора. Разбор идёт фоном, несколько секунд на список.
T_the_ready_lists_of_the_set_a='The ready lists of the set are not parsed yet: <b>%s</b>. While they are missing, the panel can show a match only as “probably” (grey dotted line) — the lamp in the set becomes exact, like in the rule, after parsing. Parsing runs in the background, a few seconds per list.'
# Что добавляем
T_what_to_add='What to add'
# Значение (можно несколько, каждое с новой строки)
T_value_several_allowed_each_o='Value (several allowed, each on a new line)'
# Собрать шаблон из сайтов (если нужен шаблон)
T_build_a_template_from_sites_='Build a template from sites (if a template is needed)'
# Проверка домена: где он есть и какое правило поймает
T_domain_check_where_it_is_and='Domain check: where it is and which rule will catch it'
# список: vk, rutube, youtube, category-ru
T_list_vk_rutube_youtube_categ='list: vk, rutube, youtube, category-ru'
# Нажмите на заголовок — покажу файлы со списками, состояние разбора по наборам, обновление из интернета и журналы. Расчёты панель делает только при открытии, чтобы «Маршруты» открывались быстрее.
T_click_the_title_i_will_show_='Click the title — I will show the files with lists, the parsing state per set, updating from the internet and the logs. The panel does the calculations only when opened, so that “Routes” open faster.'
# Панель берёт названия списков прямо из этих файлов — значит, подсказка в поле «Значение» совпадает с тем, что умеет ваш xray.
T_the_panel_takes_the_list_nam='The panel takes the list names straight from these files — so the hint in the “Value” field matches what your xray can do.'
# Названия списков ещё не собраны. Это разово и занимает до пары минут — панель делает это фоном, страницу держать открытой не нужно.
T_the_list_names_have_not_been_2='The list names have not been collected yet. This is a one-off and takes up to a couple of minutes — the panel does it in the background, the page does not have to stay open.'
# По разобранному списку панель точно понимает, какое правило поймало трафик: лампочка в правиле и в наборе загорается верно. Без разбора условие проверяется только «по выходу».
T_with_a_parsed_list_the_panel='With a parsed list the panel knows exactly which rule caught the traffic: the lamp in the rule and in the set lights up correctly. Without parsing the condition is only checked “by outbound”.'
# В правилах и наборах нет записей с готовыми списками — разбирать нечего.
T_there_are_no_entries_with_re='There are no entries with ready lists in the rules and sets — nothing to parse.'
# Разбирать нужно <b>один раз</b>. После обновления баз панель разбирает заново сама — вручную повторять ничего не надо. Списки адресов (geoip) нужны, чтобы правило вида <code>geoip:ru</code> проверялось по адресу.
T_it_only_has_to_be_parsed_b_o='It only has to be parsed <b>once</b>. After the databases are updated the panel parses again by itself — nothing has to be repeated by hand. Address lists (geoip) are needed so that a rule like <code>geoip:ru</code> is checked by address.'
# Файлы берутся из релизов на GitHub. Старые сохраняются рядом как <code>.bak</code>, затем панель сама пересобирает названия, разбирает списки наборов и перезапускает xray.
T_the_files_are_taken_from_git='The files are taken from GitHub releases. The old ones are kept next to them as <code>.bak</code>, then the panel rebuilds the names itself, parses the set lists and restarts xray.'
# Обновлять базы
T_update_databases='Update databases'
# выключено
T_disabled='disabled'
# раз в неделю — по понедельникам, в 4 утра
T_once_a_week_on_mondays_at_4_='once a week — on Mondays, at 4 am'
# раз в месяц — 1-го числа, в 4 утра
T_once_a_month_on_the_1st_at_4='once a month — on the 1st, at 4 am'
# Источник для автообновления
T_source_for_auto_update='Source for auto-update'
# Устройство (кто идёт)
T_device_who_goes='Device (who goes)'
# Тип
T_type='Type'
# Куда идём
T_where_we_go='Where we go'
# youtube.com, 10.0.0.0/8 или 8.8.8.8
T_youtube_com_10_0_0_0_8_or_8_='youtube.com, 10.0.0.0/8 or 8.8.8.8'
# Категория
T_category='Category'
# Если «через прокси» — какой выход
T_if_through_proxy_which_outbo='If “through proxy” — which outbound'
# Если «напрямую» — через интерфейс (необязательно)
T_if_straight_through_which_in='If “straight” — through which interface (optional)'
# Кто идёт (можно несколько)
T_who_goes_several_allowed='Who goes (several allowed)'
# Куда — наборы (можно несколько)
T_where_sets_several_allowed='Where — sets (several allowed)'
# Если «кто» не выбран — правило для всех устройств. Если наборы не выбраны — правило просто направляет выбранных клиентов целиком, без разбора адресов.
T_if_who_is_not_selected_the_r='If “who” is not selected — the rule is for all devices. If no sets are selected — the rule simply sends the selected clients as a whole, without looking at addresses.'
# Знакомой причины в журнале не нашлось — строки панели есть ниже.
T_no_familiar_reason_was_found='No familiar reason was found in the log — the panel lines are below.'
# Кнопка ниже переименует их в <code>.bak-дата</code> — xray их больше не увидит, а сами файлы останутся рядом.
T_the_button_below_renames_the='The button below renames them to <code>.bak-date</code> — xray will not see them any more, and the files themselves stay in place.'
# снять правила перехвата и вернуть обычный интернет
T_remove_the_interception_rule='remove the interception rules and bring back the usual internet'
# завернуть трафик в xray (с автооткатом через 5 минут)
T_wrap_traffic_into_xray_with_='wrap traffic into xray (with auto-rollback in 5 minutes)'
# оставить правила насовсем
T_keep_the_rules_forever='keep the rules forever'
# Автооткат — защита от потери доступа: если через 5 минут не нажать «Подтвердить», правила снимутся сами и интернет вернётся как было.
T_auto_rollback_is_protection_='Auto-rollback is protection against losing access: if “Confirm” is not pressed within 5 minutes, the rules are removed by themselves and the internet comes back as it was.'
# другой интерфейс
T_another_interface='another interface'
# по правилам панели (выход по умолчанию: %s)
T_by_the_panel_rules_default_o='by the panel rules (default outbound: %s)'
# по лучшему пингу (авто, балансировщик)
T_by_best_ping_auto_balancer='by best ping (auto, balancer)'
# direct — напрямую
T_direct_straight='direct — straight'
# не заворачивать
T_do_not_wrap='do not wrap'
# в туннель — напрямую в xray
T_into_the_tunnel_straight_int='into the tunnel — straight into xray'
# в роутерный резолвер (dnsmasq)
T_into_the_router_resolver_dns='into the router resolver (dnsmasq)'
# своими серверами (DoH или обычный DNS)
T_by_its_own_servers_doh_or_pl='by its own servers (DoH or plain DNS)'
# через туннель — панель ставит 127.0.0.1#%s
T_through_the_tunnel_the_panel='through the tunnel — the panel sets 127.0.0.1#%s'
# шифрованно (DoH) — провайдер не видит запрос
T_encrypted_doh_the_provider_d='encrypted (DoH) — the provider does not see the request'
# обычным DNS (по 53-му порту)
T_plain_dns_over_port_53='plain DNS (over port 53)'
# по лучшему пингу — через самый быстрый сервер
T_by_best_ping_through_the_fas='by best ping — through the fastest server'
# как у прозрачного режима — сейчас: %s
T_same_as_in_transparent_mode_='same as in transparent mode — now: %s'
# direct — напрямую, без прокси
T_direct_straight_without_prox='direct — straight, without proxy'
# пересылать через выбранный сервер (по умолчанию)
T_forward_through_the_chosen_s='forward through the chosen server (default)'
# внутренним резолвером xray (если сборка xray это умеет)
T_by_the_xray_internal_resolve='by the xray internal resolver (if the xray build can do it)'
# Запросы на 53-й порт перехватываются и уходят через выбранный сервер — тогда местный провайдер не видит, какие сайты вы открываете. Работает во всех режимах, а в режиме «только сам роутер» перехватываются и запросы самого роутера.
T_requests_to_port_53_are_inte='Requests to port 53 are intercepted and go through the chosen server — then the local provider does not see which sites you open. It works in all modes, and in the “router only” mode the router'\''s own requests are intercepted too.'
# Галочек две, и это разные вещи: первая заворачивает DNS клиентов (правила фаервола на 53-й порт), вторая переводит на тот же путь dnsmasq самого роутера. Можно, например, оставить DoH для роутера и перехватывать DNS только у выбранных клиентов.
T_there_are_two_checkboxes_and='There are two checkboxes and they are different things: the first wraps client DNS (firewall rules for port 53), the second moves the router'\''s own dnsmasq to the same path. You can, for example, keep DoH for the router and intercept DNS only for the selected clients.'
# Пересылка: перехваченный запрос уходит на выбранный сервер как есть. Ответы приходят, если сервер пропускает UDP на 53-й порт (наш пропускает).
T_forwarding_the_intercepted_r='Forwarding: the intercepted request goes to the chosen server as it is. Answers come back if the server allows UDP to port 53 (ours does).'
# <b>Куда уходит DNS сейчас:</b> перехват выключен — имена разбирает роутер (dnsmasq) со своими вышестоящими серверами, в туннель они не идут.
T_b_where_dns_goes_now_b_inter='<b>Where DNS goes now:</b> interception is off — names are resolved by the router (dnsmasq) with its own upstream servers, they do not go into the tunnel.'
# Кого заворачивать: список адресов
T_who_to_wrap_address_list='Who to wrap: address list'
# Отметьте нужных клиентов и нажмите «включить прокси». Если не отмечено ничего, панель считает, что нужны <b>все</b> — включая те устройства, что появятся позже.
T_mark_the_clients_you_need_an='Mark the clients you need and press “enable proxy”. If nothing is marked, the panel assumes <b>all</b> are needed — including devices that appear later.'
# Режим включён: <span class="ok">зелёные</span> — эти клиенты завёрнуты в туннель, <span class="muted">серые</span> — не в списке (идут как обычно). Чтобы поменять выбор, нажмите «можно и выключить».
T_mode_is_on_span_class_ok_gre='Mode is on: <span class="ok">green</span> — these clients are wrapped into the tunnel, <span class="muted">grey</span> — not in the list (go as usual). To change the selection, press “can be disabled too”.'
# обнулить счётчик у этого клиента
T_reset_the_counter_of_this_cl='reset the counter of this client'
# Список — постоянные аренды DHCP и текущие выданные адреса. «Трафик» — сколько устройство отдало и получило через туннель; «сброс» обнуляет счётчик у этого клиента. Есть и общая кнопка — обнуляет всем.
T_the_list_is_dhcp_static_leas='The list is DHCP static leases and currently issued addresses. “Traffic” is how much the device sent and received through the tunnel; “reset” zeroes the counter of this client. There is also a common button — it zeroes all.'
# Считается только <b>TCP</b> — тот трафик, который заворачивается в туннель. UDP (в том числе HTTP/3 на 443-м порту) панель намеренно блокирует, чтобы трафик не уходил мимо прокси; DNS-запросы клиента (порт 53) идут отдельным путём и показаны в столбце «трафик» как «DNS …».
T_only_b_tcp_b_is_counted_the_='Only <b>TCP</b> is counted — the traffic that is wrapped into the tunnel. UDP (including HTTP/3 on port 443) is deliberately blocked by the panel so that traffic does not bypass the proxy; client DNS requests (port 53) go a separate way and are shown in the “traffic” column as “DNS …”.'
# Список клиентов пуст: постоянных аренд нет и выданных сейчас тоже. Задайте их в LuCI → Сеть → DHCP и DNS → Статические аренды.
T_the_client_list_is_empty_the='The client list is empty: there are no static leases and nothing is issued right now. Set them in LuCI → Network → DHCP and DNS → Static leases.'
# В настройках остались адреса, которых сейчас нет среди подключённых (%s) — при сохранении они будут убраны.
# Кнопки управления — вверху страницы, в блоке «Управление». Правила ставятся «на пробу» на 5 минут: если не подтвердить, они снимутся сами.
T_the_control_buttons_are_at_t='The control buttons are at the top of the page, in the “Control” block. The rules are set “on trial” for 5 minutes: if you do not confirm, they are removed by themselves.'
# Статистика xray пока пустая — либо служба не запущена, либо трафика ещё не было.
T_xray_statistics_are_still_em='xray statistics are still empty — either the service is not running, or there has been no traffic yet.'
# Прошло
T_elapsed='Elapsed'
# История переключений появится через 10–15 минут: панель снимает статистику каждые 5 минут.
T_the_switch_history_will_appe='The switch history will appear in 10–15 minutes: the panel takes statistics every 5 minutes.'
# Байты — из статистики xray (считает по каждому выходу целиком, включая «напрямую»). Активный выход показан зелёным. Список сайтов — из журнала за последние 10 минут: имена видно только те, которые xray разглядел в соединении (обычные сайты по TLS/HTTP), иначе там будет адрес.
T_bytes_from_xray_statistics_c='Bytes — from xray statistics (counted per outbound as a whole, including “direct”). The active outbound is shown in green. The site list — from the log of the last 10 minutes: only the names xray could see in the connection are visible (usual sites over TLS/HTTP), otherwise there will be an address.'
# DNS через туннель: выключен
T_dns_through_the_tunnel_disab='DNS through the tunnel: disabled'
# Режим «только сам роутер»: заворачивается трафик и DNS самого роутера (через цепочки <code>output</code>), интерфейс сети и список клиентов в этом режиме не используются — выбирать <code>br-lan</code> тут не нужно.
T_router_only_mode_the_traffic='“Router only” mode: the traffic and DNS of the router itself are wrapped (through the <code>output</code> chains), the network interface and the client list are not used in this mode — there is no need to choose <code>br-lan</code> here.'
# Мосты на роутере: <code>%s</code>. В настройках указан <code>%s</code> — совпадает.
T_bridges_on_the_router_code_s='Bridges on the router: <code>%s</code>. The settings say <code>%s</code> — they match.'
# Судя по имени, выбран интерфейс верхней сети (WAN). Заворачивать его стоит только осознанно — через ваш туннель пойдёт трафик всех, кто находится за верхним роутером.
T_judging_by_the_name_the_uppe='Judging by the name, the upper network (WAN) interface is selected. Wrapping it makes sense only deliberately — the traffic of everyone behind the upper router will go through your tunnel.'
# пока пусто. Откройте на компьютере любой сайт — записи появятся сами, страницу обновлять не нужно. Если они так и не появятся, значит трафик до перехватчика не доходит: проверьте имя моста выше.
T_empty_so_far_open_any_site_o='empty so far. Open any site on the computer — entries will appear by themselves, the page does not need to be reloaded. If they still do not appear, the traffic does not reach the interceptor: check the bridge name above.'
# После перезагрузки роутера правила ставятся заново автоматически, если режим включён.
T_after_a_router_reboot_the_ru='After a router reboot the rules are set again automatically if the mode is on.'
# Это конфиг, собранный из настроек панели; на диск он попадёт только после кнопки «Применить конфиг». Здесь ничего не записывается.
T_this_is_the_config_built_fro='This is the config built from the panel settings; it gets to disk only after the “Apply config” button. Nothing is written here.'
# Различий нет: файл на роутере полностью совпадает с текущими настройками — применять нечего.
T_no_differences_the_file_on_t='No differences: the file on the router fully matches the current settings — nothing to apply.'
# Строки «в файле, но не в настройках» — то, что осталось от прежнего конфига; «в настройках, но не в файле» — то, что ещё не записано на роутер.
T_lines_in_the_file_but_not_in='Lines “in the file but not in the settings” are what is left from the previous config; “in the settings but not in the file” is what is not yet written to the router.'
# Это тот конфиг, с которым сейчас работает xray. Изменения настроек попадают сюда после кнопки «Применить конфиг».
T_this_is_the_config_xray_is_r='This is the config xray is running with right now. Settings changes get here after the “Apply config” button.'
# Порт SOCKS
T_socks_port='SOCKS port'
# Порт API
T_api_port='API port'
# Пароль панели (пусто = без пароля)
T_panel_password_empty_no_pass='Panel password (empty = no password)'
# Проверочный адрес для автовыбора
T_probe_address_for_auto_selec='Probe address for auto-select'
# Папка журналов xray
T_xray_log_folder='xray log folder'
# Адрес для проверки узлов
T_address_for_checking_nodes='Address for checking nodes'
# Порт для проверки
T_port_for_checking='Port for checking'
# Проверять узлы автоматически
T_check_nodes_automatically='Check nodes automatically'
# Обновлять подписки автоматически
T_update_subscriptions_automat='Update subscriptions automatically'
# Оформление панели
T_panel_theme='Panel theme'
# Язык панели
T_panel_language='Panel language'
# Лампочки в правилах
T_lamps_in_rules='Lamps in rules'
# Подсветка в наборах
T_highlight_in_sets='Highlight in sets'
# Звук кнопок
T_button_sound='Button sound'
# Громкость звука
T_sound_volume='Sound volume'
# Обновления панели: репозиторий GitHub
T_panel_updates_github_reposit='Panel updates: GitHub repository'
# владелец/репозиторий
T_owner_repository='owner/repository'
# необязательно
T_optional='optional'
# Проверять обновления
T_check_for_updates='Check for updates'
# раз в сутки (и при открытии «Статуса»)
T_once_a_day_and_when_status_i='once a day (and when “Status” is opened)'
# вручную, только по кнопке
T_manually_only_by_button='manually, only by button'
# Файл настроек: /etc/config/xraypanel. Изменения применяются кнопкой «Применить конфиг» на странице «Статус».
T_settings_file_etc_config_xra='Settings file: /etc/config/xraypanel. Changes are applied with the “Apply config” button on the “Status” page.'
# Проверка новых версий выключена: не указан репозиторий. Его можно вписать на странице «Настройки».
T_checking_for_new_versions_is='Checking for new versions is off: no repository is set. It can be entered on the “Settings” page.'
# Проверяли %s назад (репозиторий <code>%s</code>).
T_checked_s_ago_repository_cod='Checked %s ago (repository <code>%s</code>).'
# Если репозиторий приватный, впишите токен GitHub на странице «Настройки».
T_if_the_repository_is_private='If the repository is private, enter a GitHub token on the “Settings” page.'
# Страница релиза: <a href="%s" target="_blank">%s</a>
T_release_page_a_href_s_target='Release page: <a href="%s" target="_blank">%s</a>'
# Скачайте файл — в нём все настройки панели: серверы, реверс-мосты, правила маршрутизации, прозрачный режим и DNS. Файл можно хранить у себя и позже восстановить, в том числе на другом роутере.
T_download_the_file_it_contain='Download the file — it contains all the panel settings: servers, reverse bridges, routing rules, transparent mode and DNS. The file can be kept and later restored, including on another router.'
# Список клиентов (конкретные адреса устройств) по умолчанию в файл не попадает: на другом роутере такие адреса чужие. Если переносишь настройки на этот же роутер и хочешь сохранить список — отметь галочку ниже.
T_the_client_list_specific_dev='The client list (specific device addresses) does not get into the file by default: on another router such addresses are foreign. If you move the settings to this same router and want to keep the list — tick the box below.'
# Выберите файл настроек (тот, что скачали кнопкой выше) — панель применит его. Прежние настройки сохранятся рядом с конфигом как файл с датой и .bak, откатить можно в любой момент.
T_choose_the_settings_file_the='Choose the settings file (the one you downloaded with the button above) — the panel will apply it. The previous settings are kept next to the config as a file with the date and .bak, and can be rolled back at any moment.'
# Файл с настройками
T_settings_file='Settings file'
# Если файл почему-то не выбирается — можно открыть его в блокноте, скопировать содержимое целиком и вставить сюда.
T_if_the_file_is_somehow_not_s='If the file is somehow not selected — you can open it in a text editor, copy the whole contents and paste them here.'
# # Настройки панели xraypanel...
T_xraypanel_settings='# Nexveil settings...'
# После восстановления панель сама применит конфиг и перезапустит xray. Если что-то не так — верните прежний файл из копии .bak или нажмите «Откат конфига» на странице «Статус».
T_after_restoring_the_panel_ap='After restoring, the panel applies the config itself and restarts xray. If something is wrong — bring back the previous file from the .bak copy or press “Roll back config” on the “Status” page.'
# вся локальная сеть
T_the_whole_local_network='the whole local network'
# только сам роутер
T_router_only='router only'
# роутер и локальная сеть
T_router_and_local_network='router and local network'
# только выбранные клиенты
T_only_selected_clients='only selected clients'
#  шт.)
T_pcs=' pcs.)'
#  (ни один не отмечен — включить не даст)
T_none_selected_cannot_enable=' (none selected — cannot enable)'
# через сервер с лучшим пингом (авто)
T_through_the_server_with_the_='through the server with the best ping (auto)'
# напрямую, без прокси
T_straight_without_proxy='straight, without proxy'
# через выход «
T_through_outbound='through outbound “'
# у клиентов не перехватывается — в этом режиме заворачивается только DNS самого роутера
T_is_not_intercepted_for_clien='is not intercepted for clients — in this mode only the router'\''s own DNS is wrapped'
# перехватывается и сразу уходит в туннель (xray)
T_is_intercepted_and_goes_stra='is intercepted and goes straight into the tunnel (xray)'
# перехватывается и уходит на роутерный резолвер
T_is_intercepted_and_goes_to_t='is intercepted and goes to the router resolver'
# не перехватывается — уходит так, как настроено на самом устройстве
T_is_not_intercepted_it_goes_a='is not intercepted — it goes as set on the device itself'
# уходит через туннель — панель поставит в dnsmasq вход xray 127.0.0.1#
T_goes_through_the_tunnel_the_='goes through the tunnel — the panel will set the xray inbound 127.0.0.1# in dnsmasq'
# отвечает своими серверами (
T_answers_with_its_own_servers='answers with its own servers ('
# обычный DNS по 53-му порту
T_plain_dns_over_port_53_2='plain DNS over port 53'
# шифрованно, DoH
T_encrypted_doh='encrypted, DoH'
# не видит — клиентский DNS в этом режиме не перехватывается
T_does_not_see_client_dns_is_n='does not see — client DNS is not intercepted in this mode'
# видит — запросы клиентов проходят через резолвер роутера
T_does_see_client_requests_go_='does see — client requests go through the router resolver'
# не видит — запросы идут мимо резолвера роутера
T_does_not_see_requests_go_pas='does not see — requests go past the router resolver'
# видит, только если устройства спрашивают роутер
T_sees_it_only_if_the_devices_='sees it only if the devices ask the router'
# как настроено на устройствах — клиентский DNS не перехватывается
T_depends_on_how_the_devices_a='depends on how the devices are set up — client DNS is not intercepted'
# имена не видит — они уходят только через сервер туннеля
T_does_not_see_names_they_go_o='does not see names — they go only through the tunnel server'
# видит имена — резолвер спрашивает по 53-му порту
T_sees_names_the_resolver_asks='sees names — the resolver asks over port 53'
# имена не видит — резолвер отвечает шифрованно (DoH)
T_does_not_see_names_the_resol='does not see names — the resolver answers encrypted (DoH)'
# смотря как настроены устройства
T_depends_on_how_the_devices_a_2='depends on how the devices are set up'
# <b>Заворачивается:</b> 
T_b_wrapped_b='<b>Wrapped:</b> '
# <br><b>Трафик идёт:</b> 
T_br_b_traffic_goes_b='<br><b>Traffic goes:</b> '
# <br><b>DNS клиентов:</b> 
T_br_b_client_dns_b='<br><b>Client DNS:</b> '
# <br><b>Резолвер роутера:</b> 
T_br_b_router_resolver_b='<br><b>Router resolver:</b> '
# <br><b>Имена сайтов:</b> панель — 
T_br_b_site_names_b_panel='<br><b>Site names:</b> panel — '
# ; провайдер — 
T_provider='; provider — '
# <br><b>Шифрованный DNS:</b> DoT (853) — 
T_br_b_encrypted_dns_b_dot_853='<br><b>Encrypted DNS:</b> DoT (853) — '
# закрыт
T_closed='closed'
# разрешён (DNS не перехватывается)
T_allowed_dns_is_not_intercept='allowed (DNS is not intercepted)'
# разрешён
T_allowed='allowed'
# закрыт по списку
T_closed_by_list='closed by list'
#  Канарейки для браузеров и Apple: 
T_browser_and_apple_canaries=' Browser and Apple canaries: '
# включены
T_enabled='enabled'
# выключены
T_disabled_2='disabled'
# <br><span class="muted">Так будет после нажатия «включить прокси». До этого ничего не меняется.</span>
T_br_span_class_muted_this_is_='<br><span class="muted">This is how it will be after pressing “enable proxy”. Until then nothing changes.</span>'
# сохраняю…
T_saving='saving…'
# сохранено
T_saved='saved'
# не получилось сохранить
T_could_not_save='could not save'
# не нашёл шаблон строки — обновите страницу (Ctrl+F5)
T_did_not_find_the_row_templat='did not find the row template — refresh the page (Ctrl+F5)'
# не выбрано
T_not_selected='not selected'
# <span class="muted">новая строка — сохранится кнопкой «сохранить конфиг»</span>
T_span_class_muted_new_row_wil='<span class="muted">new row — will be saved with the “save config” button</span>'
# строка добавлена — выберите наборы и нажмите «применить конфиг»
T_row_added_choose_sets_and_pr='row added — choose sets and press “apply config”'
# тяните строку на нужное место
T_drag_the_row_to_the_right_pl='drag the row to the right place'
# td[data-label="Проверка"] span
T_td_data_label_check_span='td[data-label="Check"] span'
# проверяю…
T_checking='checking…'
# нет ответа
T_no_answer='no answer'
# проверяю все…
T_checking_all='checking all…'
# замеряю…
T_measuring='measuring…'
# td[data-label="Пинг"]
T_td_data_label_ping='td[data-label="Ping"]'
# обновляю…
T_refreshing='refreshing…'
# только что
T_just_now='just now'
# начните печатать: category-ru, youtube, category-ads-all…
T_start_typing_category_ru_you='start typing: category-ru, youtube, category-ads-all…'
# начните печатать: ru, cn, us, private…
T_start_typing_ru_cn_us_privat='start typing: ru, cn, us, private…'
# 10.0.0.0/8 или 8.8.8.8
T_10_0_0_0_8_or_8_8_8_8='10.0.0.0/8 or 8.8.8.8'
# шаблон пустой
T_template_is_empty='template is empty'
# шаблон не разбирается: 
T_template_does_not_parse='template does not parse: '
# проверьте скобки
T_check_the_brackets='check the brackets'
# в шаблоне есть \| — это лишний слэш: для «или» пишите просто |
T_the_template_has_that_is_an_='the template has \| — that is an extra backslash: for “or” write just |'
# шаблон совпадает со всем подряд (как «kino|.») — правило поймает все домены; для всего трафика есть отдельный пункт в «Куда»
T_the_template_matches_everyth='the template matches everything (like “kino|.”) — the rule will catch all domains; there is a separate item in “Where” for all traffic'
# точка перед доменной зоной не экранирована: пишите \.ru, а не .ru
T_the_dot_before_the_domain_zo='the dot before the domain zone is not escaped: write \.ru, not .ru'
# напишите домены, например: vkvideo.ru, rutube.ru
T_write_domains_for_example_vk='write domains, for example: vkvideo.ru, rutube.ru'
# готовый шаблон: 
T_ready_template='ready template: '
#  — нажмите «Добавить в набор»
T_press_add_to_set=' — press “Add to set”'
# не сохраняю: 
T_not_saving='not saving: '
# скопировано
T_copied='copied'
# <span class="muted" style="font-size:12px">пока пусто — впишите значение или зажмите домен из подбора на секунду</span>
T_span_class_muted_style_font_='<span class="muted" style="font-size:12px">empty so far — enter a value or hold a domain from the picker for a second</span>'
# нажмите, чтобы убрать
T_press_to_remove='press to remove'
# держите…
T_holding='holding…'
# добавлено в окно
T_added_to_the_box='added to the box'
# уже есть в окне
T_already_in_the_box='already in the box'
#  качаю файлы и пересобираю названия — это пара минут…
T_downloading_the_files_and_re=' downloading the files and rebuilding the names — this takes a couple of minutes…'
#  не получилось запустить обновление
T_could_not_start_the_update=' could not start the update'
#  впишите название списка
T_enter_the_list_name=' enter the list name'
# смотрю…
T_looking='looking…'
#  читаю списки, это несколько секунд…
T_reading_the_lists_this_takes=' reading the lists, this takes a few seconds…'
#  не получилось посмотреть
T_could_not_look=' could not look'
#  впишите домен
T_enter_a_domain=' enter a domain'
#  ищу — файлы списков большие, это несколько секунд…
T_searching_the_list_files_are=' searching — the list files are large, this takes a few seconds…'
#  не получилось проверить
T_could_not_check=' could not check'
#  делаю два запроса, это пара секунд…
T_making_two_requests_this_tak=' making two requests, this takes a couple of seconds…'
#  проверяю…
T_checking_2=' checking…'
#  собираю названия — это до пары минут…
T_collecting_names_this_takes_=' collecting names — this takes up to a couple of minutes…'
#  сбор не удался — загляните в журнал на странице «Конфиг»
T_collecting_failed_look_into_=' collecting failed — look into the log on the “Config” page'
#  сек назад
T_sec_ago=' sec ago'
#  мин назад
T_min_ago=' min ago'
#  ч назад
T_h_ago=' h ago'
# Б
T_b='B'
# КБ
T_kb='KB'
# МБ
T_mb='MB'
# ГБ
T_gb='GB'
# ТБ
T_tb='TB'
# стоят
T_set='set'
# сняты (трафик идёт как обычно)
T_removed_traffic_goes_as_usua='removed (traffic goes as usual)'
# отменён — правила остаются
T_cancelled_the_rules_stay='cancelled — the rules stay'
# сработает через 
T_will_work_in='will work in '
#  сек — нажмите «Подтвердить»
T_sec_press_confirm=' sec — press “Confirm”'
# ждёт подтверждения
T_waiting_for_confirmation='waiting for confirmation'
# не активен
T_not_active='not active'
# 0 Б
T_0_b='0 B'
# <b>напрямую</b>
T_b_straight_b='<b>straight</b>'
# <b>заблокировано</b>
T_b_blocked_b='<b>blocked</b>'
#  назад · 
T_ago=' ago · '
#  <span class="muted">(ещё: 
T_span_class_muted_also=' <span class="muted">(also: '
# <span class="muted">нет свежих записей</span>
T_span_class_muted_no_fresh_en='<span class="muted">no fresh entries</span>'
# нет записей
T_no_entries='no entries'
# за 10 минут: 
T_in_10_minutes='in 10 minutes: '
# выход 
T_outbound_2='outbound '
# ; за 10 минут: 
T_in_10_minutes_2='; in 10 minutes: '
# нет свежих записей
T_no_fresh_entries='no fresh entries'
# клиенты ↑ 
T_clients='clients ↑ '
#  (роутер)
T_router=' (router)'
# через туннель ↑ 
T_through_the_tunnel='through the tunnel ↑ '
#  · напрямую ↑ 
T_straight_2=' · straight ↑ '
# <span class="muted">пока пусто — завёрнутых клиентов нет, либо трафик ещё не проходил</span>
T_span_class_muted_empty_so_fa='<span class="muted">empty so far — no wrapped clients, or there has been no traffic yet</span>'
# не применено
T_not_applied='not applied'
# Различия
T_differences='Differences'
# <h2>Различия с файлом на роутере</h2>
T_h2_differences_with_the_file='<h2>Differences with the file on the router</h2>'
# <p class="ok">Конфиг применён — файл на роутере совпадает с настройками.</p>
T_p_class_ok_config_applied_th='<p class="ok">Config applied — the file on the router matches the settings.</p>'
# Конфиг применён, xray перезапущен.
T_config_applied_xray_restarte='Config applied, xray restarted.'
# Применяется…
T_applying='Applying…'
# Конфиг применяется…
T_config_is_being_applied='Config is being applied…'
# <p class="muted">собираю…</p>
T_p_class_muted_collecting_p='<p class="muted">collecting…</p>'
# <p class="bad">не получилось собрать — обновите страницу (Ctrl+F5)</p>
T_p_class_bad_could_not_collec='<p class="bad">could not collect — refresh the page (Ctrl+F5)</p>'
# открыта локально
T_open_locally='open locally'
# не выбран (такой трафик идёт напрямую)
T_not_selected_such_traffic_go='not selected (such traffic goes straight)'
# пока нечего показать
T_nothing_to_show_yet='nothing to show yet'
# Тег выхода
T_outbound_tag='Outbound tag'
# Адрес сервера (IP или домен)
T_server_address_ip_or_domain='Server address (IP or domain)'
# Порт
T_port='Port'
# Flow (только VLESS+Reality)
T_flow_vless_reality_only='Flow (VLESS+Reality only)'
# после этого нажмите «применить конфиг»
# (нужен только старому способу)
T_only_needed_by_the_old_metho='(only needed by the old method)'
# IP-адрес или сеть — 10.0.0.0/8, 8.8.8.8
T_ip_address_or_network_10_0_0='IP address or network — 10.0.0.0/8, 8.8.8.8'
# Домен и все поддомены — youtube.com
T_domain_and_all_subdomains_yo='Domain and all subdomains — youtube.com'
# Только ровно этот домен — youtube.com
T_exactly_this_domain_only_you='Exactly this domain only — youtube.com'
# Слово в имени — google
T_word_in_the_name_google='Word in the name — google'
# Шаблон — .*\\.ru\$
T_template_ru='Template — .*\.ru$'
# Готовый список доменов (из файла роутера)
T_ready_list_of_domains_from_t='Ready list of domains (from the router file)'
# Готовый список адресов (из файла роутера)
T_ready_list_of_addresses_from='Ready list of addresses (from the router file)'
# Напрямую — мимо прокси
T_straight_past_the_proxy='Straight — past the proxy'
# Через прокси — в тоннель
T_through_proxy_into_the_tunne='Through proxy — into the tunnel'
# Заблокировать
T_block='Block'
# новая строка — сохранится кнопкой «применить конфиг»
T_new_row_will_be_saved_with_t='new row — will be saved with the “apply config” button'
# сохраняет правила и применяет конфиг
T_saves_the_rules_and_applies_='saves the rules and applies the config'
# правьте тип и значение прямо в таблице
T_edit_the_type_and_value_righ='edit the type and value right in the table'
# ещё не разбирали
T_not_parsed_yet='not parsed yet'
# не разобран
T_not_parsed='not parsed'
# фоном: скачивание и разбор — минута-две
T_in_the_background_download_a='in the background: download and parsing — a minute or two'
# сейчас: включено — раз в неделю (понедельник, 4 утра)
T_now_on_once_a_week_monday_4_='now: on — once a week (Monday, 4 am)'
# сейчас: включено — раз в месяц (1-е число, 4 утра)
T_now_on_once_a_month_1st_4_am='now: on — once a month (1st, 4 am)'
# сейчас: выключено
T_now_off='now: off'
# не слушает (режим выключен)
T_not_listening_mode_is_off='not listening (mode is off)'
# порт, в который заворачивается трафик клиентов
T_port_that_clients_traffic_is='port that clients'\'' traffic is wrapped into'
# Порт DNS-входа
T_dns_inbound_port='DNS inbound port'
# порт, куда уходит перехваченный DNS
T_port_the_intercepted_dns_goe='port the intercepted DNS goes to'
# Резолверы (до 4)
T_resolvers_up_to_4='Resolvers (up to 4)'
# Кого заворачивать
T_who_to_wrap='Who to wrap'
# роутер и сеть
T_router_and_network='router and network'
# только клиенты из списка
T_only_clients_from_the_list='only clients from the list'
# весь трафик, только сам роутер, и то и другое или только выбранные клиенты из списка
T_all_traffic_router_only_both='all traffic, router only, both, or only the selected clients from the list'
# Интерфейсы сети
T_network_interfaces='Network interfaces'
# по умолчанию — LAN-мост роутера; в режиме «только сам роутер» не нужны
T_by_default_the_router_lan_br='by default — the router LAN bridge; not needed in “router only” mode'
# Куда направлять
T_where_to_route='Where to route'
# куда идёт трафик, который не попал под правила со страницы «Маршруты» (правила всегда важнее)
T_where_traffic_goes_that_did_='where traffic goes that did not match the rules from the “Routes” page (rules always win)'
# Автовыбор сервера
T_server_auto_select='Server auto-select'
#  спокойный режим — не менять сервер из-за мелкой разницы по пингу
T_calm_mode_do_not_change_the_=' calm mode — do not change the server because of a small ping difference'
# работает при выборе «по лучшему пингу»: сервер меняется только если другой заметно быстрее или текущий перестал отвечать
T_works_when_by_best_ping_is_s='works when “by best ping” is selected: the server changes only if another one is clearly faster or the current one stopped answering'
# Заворачивать DNS клиентов
T_wrap_client_dns='Wrap client DNS'
# в туннель — запрос сразу уходит через сервер; в роутерный резолвер — запрос разбирает dnsmasq (панель видит имена для правил, работают локальные имена и кэш)
T_into_the_tunnel_the_request_='into the tunnel — the request goes through the server at once; into the router resolver — the request is resolved by dnsmasq (the panel sees names for the rules, local names and the cache work)'
# Чем отвечает роутерный резолвер
T_what_the_router_resolver_ans='What the router resolver answers with'
# свои серверы — как настроено в dnsmasq (например DoH); через туннель — панель сама прописывает входы xray и включает noresolv
T_its_own_servers_as_configure='its own servers — as configured in dnsmasq (for example DoH); through the tunnel — the panel writes the xray inbounds itself and turns on noresolv'
# DNS самого роутера
T_router_s_own_dns='Router'\''s own DNS'
#  и у самого роутера — тем же путём
T_and_the_router_itself_the_sa=' and the router itself — the same way'
# роутерный резолвер один на всех: если он уходит в туннель, DNS самого роутера идёт тем же путём — галочка ставится сама
T_the_router_resolver_is_share='the router resolver is shared by everyone: if it goes into the tunnel, the router'\''s own DNS goes the same way — the checkbox sets itself'
# Шифрованный DNS у клиентов
T_encrypted_dns_for_clients='Encrypted DNS for clients'
#  закрывать DoT (порт 853) — «приватный DNS» на телефонах и в браузерах
T_close_dot_port_853_private_d=' close DoT (port 853) — “private DNS” on phones and in browsers'
#  закрывать DoH (443) по списку адресов ниже
T_close_doh_443_by_the_address=' close DoH (443) by the address list below'
# адреса DoH для блокировки (через запятую или пробел) — работает только с галочкой выше
T_doh_addresses_to_block_comma='DoH addresses to block (comma or space separated) — works only with the checkbox above'
# первое закрывает «приватный DNS» (DoT), второе — жёсткий режим: перекрывает известные DoH-серверы. QUIC (UDP 443) панель закрывает всегда, пока клиент завёрнут
T_the_first_closes_private_dns='the first closes “private DNS” (DoT), the second is hard mode: it blocks the known DoH servers. QUIC (UDP 443) is always closed by the panel while the client is wrapped'
#  просить браузеры и Apple не использовать свой шифрованный DNS («канарейки»)
T_ask_browsers_and_apple_not_t=' ask browsers and Apple not to use their own encrypted DNS (“canaries”)'
# три записи в профиле роутера: use-application-dns.net (Firefox выключает свой DoH) и два mask-домена (Apple выключает приватный релей)
T_three_records_in_the_router_='three records in the router profile: use-application-dns.net (Firefox turns off its DoH) and two mask domains (Apple turns off the private relay)'
#  раскрутка имён серверов через вышестоящий DNS
T_bootstrap_of_server_names_th=' bootstrap of server names through the upstream DNS'
# нужна только если после перезапуска dnsmasq туннель не поднимается: имена своих серверов разрешаются напрямую, минуя туннель. По умолчанию выключено — иначе имена ваших серверов видит провайдер
T_needed_only_if_the_tunnel_do='needed only if the tunnel does not come up after dnsmasq is restarted: the names of your servers are resolved directly, past the tunnel. Off by default — otherwise the provider sees the names of your servers'
# Как разрешать имена серверов
T_how_to_resolve_server_names='How to resolve server names'
# как панель разрешает имена своих серверов (шифрованно или обычным DNS)
T_how_the_panel_resolves_the_n='how the panel resolves the names of its servers (encrypted or plain DNS)'
# Выход для DNS
T_outbound_for_dns='Outbound for DNS'
# через какой выход уходят DNS-запросы; пусто — как у прозрачного режима
T_which_outbound_dns_requests_='which outbound DNS requests go through; empty — same as in transparent mode'
# Как выпускать DNS
T_how_to_release_dns='How to release DNS'
# пересылка работает везде; внутренний резолвер — только если сборка xray это умеет
T_forwarding_works_everywhere_='forwarding works everywhere; the internal resolver — only if the xray build can do it'
# Проверить DNS
T_check_dns='Check DNS'
# делает два запроса: через роутер (как видят клиенты) и напрямую к резолверу; разные ответы — похоже на подмену DNS провайдером
T_makes_two_requests_through_t='makes two requests: through the router (as clients see it) and straight to the resolver; different answers mean the DNS is probably being spoofed by the provider'
# серые
T_grey='grey'
# выключен
T_disabled_3='disabled'
#  не учитывать служебный трафик (проверки панели, обращения к серверам, вход в панель)
T_do_not_count_service_traffic=' do not count service traffic (panel checks, requests to servers, logging into the panel)'
#  подсвечивать сработавшие записи в открытом наборе (вспыхивает ярко и гаснет за 30 секунд — как лампочка правила выше)
T_highlight_the_entries_that_w=' highlight the entries that worked in the open set (lights up bright and fades in 30 seconds — like the rule lamp above)'
# (нужен только для приватного репозитория)
T_only_needed_for_a_private_re='(only needed for a private repository)'
# скачает пакет и поставит его; настройки, серверы и правила не тронутся
T_downloads_the_package_and_in='downloads the package and installs it; settings, servers and rules are not touched'
# Изменено, но ещё не применено: %s
T_changed_but_not_applied_yet_='Changed, but not applied yet: %s'
# Прошло (%s)
T_elapsed_s='Elapsed (%s)'
# ещё не запускалось
T_not_started_yet='not started yet'
# каждые %s минут
T_every_s_minutes='every %s minutes'
# каждые %s ч
T_every_s_h='every %s h'
# Компактная — плотные списки и кнопки в строку
T_compact_dense_lists_and_butt='Compact — dense lists and buttons in one row'
# Тёмная с боковым меню
T_dark_with_a_side_menu='Dark with a side menu'
# В стиле Windows XP
T_windows_xp_style='Windows XP style'
# В стиле LuCI
T_luci_style='LuCI style'
# С боковым меню (как PassWall)
T_with_a_side_menu_like_passwa='With a side menu (like PassWall)'
# Плитками, крупные кнопки (как HomeProxy)
T_tiles_large_buttons_like_hom='Tiles, large buttons (like HomeProxy)'
# Классическая
T_classic='Classic'
# Тёмная
T_dark='Dark'
# щелчок (короткий, по умолчанию)
T_click_short_default='click (short, default)'
# тик (самый тихий)
T_tick_quietest='tick (quietest)'
# блип (мягкий гудок)
T_blip_soft_beep='blip (soft beep)'
# два тона (вверх — обычные, вниз — удаление)
T_two_tones_up_normal_down_del='two tones (up — normal, down — delete)'
# тихо
T_quiet='quiet'
# средне
T_medium='medium'
# громко
T_loud='loud'
# поставить другую версию панели — найдено пакетов: %s
T_install_another_version_of_t='install another version of the panel — found packages: %s'
# Показать файл на диске: %s
T_show_the_file_on_disk_s='Show the file on disk: %s'
# что нового в версии %s
T_what_is_new_in_version_s='what is new in version %s'
# продолжить
T_continue='continue'
# изменить
T_edit_2='edit'
# изменить
T_edit_2='edit'
# добавить сервер вручную
T_add_a_server_manually='add a server manually'
# добавить мост
T_add_a_bridge='add a bridge'
# Обновление из интернета
T_update_from_the_internet='Update from the internet'
# 3. Обновление из интернета
T_3_update_from_the_internet='Update from the internet'
# 1. Файлы со списками на роутере
T_1_list_files_on_the_router='1. List files on the router'
# 2. Списки из правил и наборов
T_2_lists_from_rules_and_sets='2. Lists from rules and sets'
# 3. Обновление из интернета
T_3_update_from_the_internet='3. Update from the internet'
# Управление
T_control='Control'
# Автоматическое обновление
T_automatic_update='Automatic update'
# Правила перенесены в новую модель: адреса и домены разложены по наборам, из пар «кто + выход» собраны правила. Копия прежних настроек: <code>%s</code>
T_the_rules_were_moved_to_the_='The rules were moved to the new model: addresses and domains are spread over sets, and rules are built from “who + outbound” pairs.'
# Правила включены «на пробу»: через <span id="t-left">%s</span> сек они снимутся сами. Если всё работает — нажмите «Подтвердить (оставить правила)».
T_the_rules_are_turned_on_on_t='The rules are turned on “on trial”: in <span id="t-left">%s</span> sec they are removed by themselves. If everything works — press “Confirm” to keep them.'
# <b>Проверка</b> — что видит панель: DNS, мост, правила, журнал
T_b_check_b_what_the_panel_see='<b>Check</b> — what the panel sees: DNS, bridge, rules, log'
# <b>Что именно заворачивается</b>
T_b_what_exactly_is_wrapped_b='<b>What exactly is wrapped</b>'
# Выбрано:
T_selected='Selected:'
# старый
T_old='old'
# по домену, <code>reverse.bridges</code>
T_by_domain_code_reverse_bridg='by domain, <code>reverse.bridges</code>'
# до 26.4.18: 24.12.31, 26.4.17 и подобные. В 26.4.25 его уже нет
T_before_26_4_18_24_12_31_26_4='before 26.4.18: 24.12.31, 26.4.17 and similar. In 26.4.25 it is already gone'
# новый
T_new='new'
# VLESS Reverse Proxy по тегу, <code>"reverse": {"tag": …}</code> у выхода моста
T_vless_reverse_proxy_by_tag_c='VLESS Reverse Proxy by tag, <code>"reverse": {"tag": …}</code> on the bridge outbound'
# 25.9.11 и новее: 26.4.25, 26.9.9 и подобные
T_25_9_11_and_newer_26_4_25_26='25.9.11 and newer: 26.4.25, 26.9.9 and similar'
# имя моста, оно должно совпадать с тем, что прописано на сервере-портале (в старом конфиге было <code>router-lucy</code>)
# <b>старый</b> — порталы и мосты по домену (<code>reverse.bridges</code>, xray до 26.4.25); <b>новый</b> — VLESS Reverse Proxy: на портале у клиента стоит <code>"reverse": {"tag": "…"}</code>, а панель ставит такую же пометку у выхода моста. Новому способу домен не нужен, а трафик из туннеля приходит как вход с тегом моста — поэтому правила маршрутизации для мостов работают в обоих способах одинаково.
T_b_old_b_portals_and_bridges_='<b>old</b> — portals and bridges by domain (<code>reverse.bridges</code>, xray before 26.4.25); <b>new</b> — VLESS Reverse Proxy: on the portal the client has <code>"reverse": {"tag": "…"}</code>, and the panel puts the same mark on the bridge outbound. The new method does not need a domain, and traffic from the tunnel arrives as an inbound with the bridge tag — that is why routing rules for bridges work the same in both methods.'
# домен, по которому портал принимает мост (было <code>router-lucy.reverse.xui</code>) — нужен только старому способу
# тег сервера, через который роутер подключается к порталу; чтобы ходить напрямую, укажите <code>direct</code>
# идёт в xray, а дальше по правилам панели: в нужный сервер или напрямую
T_goes_into_xray_and_then_by_t='goes into xray and then by the panel rules: to the needed server or straight'
# проверяются первыми — поэтому «частное» правило работает даже при выбранном сервере выше
T_are_checked_first_so_a_priva='are checked first — so a “private” rule works even with a server selected above'
# не трогается — доступ к панели, LuCI и SSH не ломается
T_is_not_touched_access_to_the='is not touched — access to the panel, LuCI and SSH does not break'
# не заворачивается в себя (у его соединений ставится метка)
T_is_not_wrapped_into_itself_i='is not wrapped into itself (its connections are marked)'
# для завёрнутых клиентов блокируется, чтобы браузеры не обходили прокси по UDP — они сами переходят на обычный TCP
T_is_blocked_for_wrapped_clien='is blocked for wrapped clients so that browsers do not bypass the proxy over UDP — they switch to usual TCP by themselves'
# в этой версии не заворачиваются: имена разбирает роутер как обычно
T_are_not_wrapped_in_this_vers='are not wrapped in this version: the router resolves names as usual'

# --- panel name and the tagline in the header ---
T_app_name='Nexveil'
T_app_tagline='· Xray proxy for the router'
T_app_title='Nexveil — Xray proxy for the router'
