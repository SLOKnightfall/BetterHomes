local addonName, addon = ...
local L = _G.LibStub("AceLocale-3.0"):NewLocale(addonName, "ruRU", true, true)

if not L then return end
-- Translator ZamestoTV
-- Group
L["AUTO_QUEST"] = "Автозадания"
L["AUTO_QUEST_DESC"] = "Настройки автоматической обработки заданий."

-- Options
L["AUTO_ACCEPT"] = "Автопринятие"
L["AUTO_ACCEPT_DESC"] = "Автоматически принимать задания."

L["AUTO_TURN_IN"] = "Автосдача"
L["AUTO_TURN_IN_DESC"] = "Автоматически сдавать выполненные задания."

L["AUTO_WAYPOINT"] = "Автоустановка путевой точки"
L["AUTO_WAYPOINT_DESC"] = "Автоматически ставить путевую точку к сокровищу."

L["HIDE_WAYPOINT"] = "Скрывать координаты точки"
L["HIDE_WAYPOINT_DESC"] = "Скрывает координаты путевой точки в списке сокровищ."

L["PRINT_TEXT"] = "Сообщения в чат"
L["PRINT_TEXT_DESC"] = "Выводить сообщения о статусе в чат."


-- Tabs
L["TREASURE_LIST"] = "Список сокровищ"
L["VENDORS"] = "Торговцы"
L["PROFESSIONS"] = "Профессии"

-- Announcements
L["QUEST_ACCEPTED"] = "Задание автоматически принято."
L["QUEST_TURNIN"] = "Задание автоматически сдано."
L["WAYPOINT_SET"] = "Путевая точка установлена к месту сокровища."

L["CLICK_TO_SET"] = "Кликните, чтобы установить путевую точку"
