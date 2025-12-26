local addonName, addon = ...
local L = _G.LibStub("AceLocale-3.0"):NewLocale(addonName, "zhTW", true, true)

if not L then return end

-- Translator BlueNightSky
-- Group
L["AUTO_QUEST"] = "自動任務"
L["AUTO_QUEST_DESC"] = "自動任務處理的設置。"

-- Options
L["AUTO_ACCEPT"] = "自動接受"
L["AUTO_ACCEPT_DESC"] = "自動化接受任務。"

L["AUTO_TURN_IN"] = "自動交付"
L["AUTO_TURN_IN_DESC"] = "自動化交付完成任務。"

L["AUTO_WAYPOINT"] = "自動設置路徑點"
L["AUTO_WAYPOINT_DESC"] = "自動化設置到寶藏的路徑點。"

L["HIDE_WAYPOINT"] = "隱藏路徑點"
L["HIDE_WAYPOINT_DESC"] = "隱藏在寶藏清單中的路徑點座標。"

L["PRINT_TEXT"] = "發出提醒"
L["PRINT_TEXT_DESC"] = "在聊天中發出狀態訊息。"


-- Tabs
L["TREASURE_LIST"] = "寶藏清單"
L["VENDORS"] = "商人"
L["PROFESSIONS"] = "專業技能"

-- Announcements
L["QUEST_ACCEPTED"] = "任務已自動接受。"
L["QUEST_TURNIN"] = "任務已自動交付。"
L["WAYPOINT_SET"] = "建立到寶藏位置的路徑點。"

L["CLICK_TO_SET"] = "點擊來建立路徑點"
