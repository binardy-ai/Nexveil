#!/bin/sh
# Язык интерфейса: English
# Файл подключается из lib.sh (lang_load). Строки «скелета»:
# меню, заголовки карточек, кнопки, столбцы таблиц.
# В комментарии рядом — исходный русский текст, чтобы было понятно,
# о чём строка.

# DNS и прочий UDP
T_dns_and_other_udp='DNS and other UDP'
# DNS через туннель
T_dns_through_tunnel='DNS through tunnel'
# MAC
T_mac='MAC'
# QUIC (UDP 443)
T_quic_udp_443='QUIC (UDP 443)'
# SOCKS / API
T_socks_api='SOCKS / API'
# xray не установлен
T_xray_is_not_installed='xray is not installed'
# Автозапуск службы
T_service_autostart='Service autostart'
# Автооткат
T_auto_rollback='Auto-rollback'
# Адрес
T_address='Address'
# Адрес панели
T_panel_address='Panel address'
# Активность
T_activity='Activity'
# Бинарник xray
T_xray_binary='xray binary'
# Бэкап
T_backup='Backup'
# В каталоге конфига есть лишние .json
T_extra_json_files_in_the_conf='Extra .json files in the config directory'
# Версия панели
T_panel_version='Panel version'
# Включить автозапуск xray
T_enable_xray_autostart='Enable xray autostart'
# Восстановить из текста
T_restore_from_text='Restore from text'
# Восстановление настроек
T_restoring_settings='Restoring settings'
# Выставить журналу время роутера
T_set_log_time_to_router_time='Set log time to router time'
# Выход
T_outbound='Outbound'
# Выход (сервер)
T_outbound_server='Outbound (server)'
# Выход по умолчанию
T_default_outbound='Default outbound'
# Действия
T_actions='Actions'
# Добавить и обновить
T_add_and_update='Add and update'
# Добавить из ссылки
T_add_from_link='Add from link'
# Добавить сервер из ссылки
T_add_server_from_link='Add server from link'
# Доля
T_share='Share'
# Домен
T_domain='Domain'
# Загрузить
T_upload='Upload'
# Загрузить и восстановить
T_upload_and_restore='Upload and restore'
# Записей
T_entries='Entries'
# Значение
T_value='Value'
# Изменён
T_modified='Modified'
# Или вставить текстом
T_or_paste_as_text='Or paste as text'
# Имя
T_name='Name'
# Интернет-трафик
T_internet_traffic='Internet traffic'
# Как заполнять
T_how_to_fill_in='How to fill in'
# Какие реверсы умеет ваша сборка
T_which_reverse_modes_your_bui='Which reverse modes your build supports'
# Какие сборки xray понимают
T_which_xray_builds_support_it='Which xray builds support it'
# Конфиг
T_config='Config'
# Конфиг не собирается
T_config_cannot_be_built='Config cannot be built'
# Кто идёт
T_who_goes='Who goes'
# Куда (наборы)
T_where_sets='Where (sets)'
# Куда идёт трафик
T_where_traffic_goes='Where traffic goes'
# Куда уходит трафик
T_where_the_traffic_goes='Where the traffic goes'
# Локальная сеть и сам роутер
T_local_network_and_the_router='Local network and the router itself'
# Маршруты
T_routes='Routes'
# Наборы адресов и доменов
T_address_and_domain_sets='Address and domain sets'
# Названий
T_names='Names'
# Названий разобрано
T_names_parsed='Names parsed'
# Настройки
T_settings='Settings'
# Настройки панели
T_panel_settings='Panel settings'
# Обновление панели
T_panel_update='Panel update'
# Обновлено
T_updated='Updated'
# Откат конфига
T_roll_back_config='Roll back config'
# Отклик
T_response='Response'
# Панель без пароля
T_panel_without_a_password='Panel without a password'
# Перезапустить xray
T_restart_xray='Restart xray'
# Переименовать
T_rename='Rename'
# Перехват DNS
T_dns_interception='DNS interception'
# Пинг (сеть)
T_ping_network='Ping (network)'
# Подписки
T_subscriptions='Subscriptions'
# Порт перехвата
T_intercept_port='Intercept port'
# Последний запуск
T_last_start='Last start'
# Последний перезапуск xray
T_last_xray_restart='Last xray restart'
# Правила
T_rules='Rules'
# Правила маршрутизации
T_routing_rules='Routing rules'
# Правила фаервола
T_firewall_rules='Firewall rules'
# Применить конфиг
T_apply_config='Apply config'
# Проверка (прокси)
T_check_proxy='Check (proxy)'
# Проверка: что видит панель
T_check_what_the_panel_sees='Check: what the panel sees'
# Прозрачный режим
T_transparent_mode='Transparent mode'
# Прокси
T_proxy='Proxy'
# Различия с файлом на роутере
T_differences_with_the_file_on='Differences with the file on the router'
# Размер
T_size='Size'
# Разобран
T_parsed='Parsed'
# Реверс
T_reverse='Reverse'
# Реверс-мосты
T_reverse_bridges='Reverse bridges'
# Режим в настройках
T_mode_in_settings='Mode in settings'
# Сам xray
T_xray_itself='xray itself'
# Сейчас в работе (по журналу)
T_currently_in_use_from_the_lo='Currently in use (from the log)'
# Сейчас трафик идёт через
T_traffic_is_currently_going_t='Traffic is currently going through'
# Серверы
T_servers='Servers'
# Скачать настройки
T_download_settings='Download settings'
# Служба
T_service='Service'
# Смена версии панели
T_change_panel_version='Change panel version'
# Создать набор
T_create_set='Create set'
# Состояние
T_status='Status'
# Сохранение настроек
T_saving_settings='Saving settings'
# Сохранить
T_save='Save'
# Сохранить мост
T_save_bridge='Save bridge'
# Сохранить настройки
T_save_settings='Save settings'
# Сохранить правило
T_save_rule='Save rule'
# Список
T_list='List'
# Способ
T_mode='Mode'
# Способ реверса
T_reverse_mode='Reverse mode'
# Статус
T_status_2='Status'
# Тег
T_tag='Tag'
# Тег моста
T_bridge_tag='Bridge tag'
# Трафик
T_traffic='Traffic'
# Убрать лишние .json из каталога конфига
T_remove_extra_json_files='Remove extra .json files'
# Удалить мост
T_delete_bridge='Delete bridge'
# Удалить правило
T_delete_rule='Delete rule'
# Удалить сервер
T_delete_server='Delete server'
# Узлов
T_nodes='Nodes'
# Файл
T_file='File'
# Файл конфига
T_config_file='Config file'
# Часовой пояс журнала
T_log_time_zone='Log time zone'
# Через что
T_through_what='Through what'
# Что
T_what='What'
# Что внутри
T_contains='Contains'
# Что дальше
T_what_next='What next'
# Что заходило в перехватчик
T_what_went_through_the_interc='What went through the interceptor'
# Что получится
T_what_you_will_get='What you will get'
# Что получится по текущим настройкам
T_what_the_current_settings_wi='What the current settings will produce'
# Что ходило
T_what_was_visited='What was visited'
# Что это
T_what_it_is='What it is'
# адрес
T_address_2='address'
# включить запись запросов DNS
T_enable_dns_query_logging='enable DNS query logging'
# включить прокси
T_enable_proxy='enable proxy'
# добавить правило
T_add_rule='add rule'
# завернуть
T_route='route'
# замерить пинг
T_measure_ping='measure ping'
# идёт через
T_goes_through='goes through'
# имя
T_name_2='name'
# можно и выключить
T_or_turn_it_off='or turn it off'
# обновить
T_update='update'
# обновить списки из интернета
T_update_lists_from_the_intern='update lists from the internet'
# обновить списки сейчас
T_update_lists_now='update lists now'
# подтвердить
T_confirm='confirm'
# поставить выбранный
T_install_selected='install selected'
# поставить пакеты со списками
T_install_list_packages='install list packages'
# починить сейчас
T_fix_now='fix now'
# проверить
T_check='check'
# проверить все
T_check_all='check all'
# проверить домен
T_check_domain='check domain'
# проверить название
T_check_name='check name'
# проверить обновление сейчас
T_check_for_updates_now='check for updates now'
# разобрать списки
T_parse_lists='parse lists'
# разобрать списки набора
T_parse_set_lists='parse set lists'
# сброс
T_reset='reset'
# сбросить трафик у всех
T_reset_traffic_for_all='reset traffic for all'
# сделать основным
T_make_default='make default'
# собрать названия заново
T_rebuild_names='rebuild names'
# собрать названия списков
T_collect_list_names='collect list names'
# собрать шаблон
T_build_template='build template'
# сохранить
T_save_2='save'
# сохранить изменения записей
T_save_entry_changes='save entry changes'
# сохранить папки
T_save_folders='save folders'
# сохранить способ
T_save_mode='save mode'
# трафик ↑/↓
T_traffic_2='traffic ↑/↓'
# убрать дубли
T_remove_duplicates='remove duplicates'
# удалить
T_delete='delete'
# удалить набор
T_delete_set='delete set'
# что в списке
T_what_is_in_the_list='what is in the list'
# Готовые списки (гео) — файлы со списками и обновление из интернета
T_geo_lists_files_and_updates_='Geo lists: files and updates from the internet'
# Готовые списки доменов и адресов (geosite / geoip)
T_geo_lists_of_domains_and_add='Geo lists of domains and addresses (geosite / geoip)'
# Журнал обновления из интернета
T_update_log_from_the_internet='Update log (from the internet)'
# Журнал обновления списков
T_list_update_log='List update log'
# Журнал прозрачного режима
T_transparent_mode_log='Transparent mode log'
# Журнал разбора списков наборов
T_set_list_parsing_log='Set list parsing log'
# Журнал сбора названий
T_name_collection_log='Name collection log'
# Кратко: какой реверс с какой сборкой работает
T_short_which_reverse_works_wi='Short: which reverse works with which build'
# Почему вход перехвата не поднялся
T_why_the_intercept_entry_did_='Why the intercept entry did not come up'
# Правила, которые стоят сейчас
T_rules_currently_in_place='Rules currently in place'
# выбрать интерфейсы
T_choose_interfaces='choose interfaces'
# журнал последней проверки (подробно)
T_last_check_log_detailed='last check log (detailed)'
# журнал проверок обновления
T_update_check_log='update check log'
# журнал установки
T_installation_log='installation log'
# подробнее про DNS и перехват
T_more_about_dns_and_intercept='more about DNS and interception'
# показать наборы и их содержимое
T_show_sets_and_their_content='show sets and their content'
# строки журнала целиком
T_full_log_lines='full log lines'
# применить конфиг
T_apply_config_2='apply config'
# конфиг применён
T_config_applied='config applied'
