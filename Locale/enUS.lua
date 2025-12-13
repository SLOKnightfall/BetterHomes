local addonName, addon = ...
local L = _G.LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true, true)

if not L then return end

-- Group
L["AUTO_QUEST"] = "Auto Quest"
L["AUTO_QUEST_DESC"] = "Settings for automatic quest handling."

-- Options
L["AUTO_ACCEPT"] = "Auto Accept"
L["AUTO_ACCEPT_DESC"] = "Automatically accept quests."

L["AUTO_TURN_IN"] = "Auto Turn In"
L["AUTO_TURN_IN_DESC"] = "Automatically turn in completed quests."

L["PRINT_TEXT"] = "Print Announcements"
L["PRINT_TEXT_DESC"] = "Print status messages in chat."


-- Tabs
L["TREASURE_LIST"] = "Treasure List"
L["VENDORS"] = "Vendors"
L["PROFESSIONS"] = "Professions"

-- Announcements
L["QUEST_ACCEPTED"] = "Quest automatically accepted."
L["QUEST_TURNIN"] = "Quest automatically turned in."
L["WAYPOINT_SET"] = "Waypoint set to treasure location."

L["CLICK_TO_SET"] = "Click to set a Waypoint"
