local addonName, addon = ...
local L = _G.LibStub("AceLocale-3.0"):NewLocale(addonName, "deDE", true, true)

if not L then return end

-- Translator NostradoFM

-- Group
L["AUTO_QUEST"] = "Auto Quest-Handling"
L["AUTO_QUEST_DESC"] = "Einstellungen für autmoatisches Questhandling."

-- Options
L["AUTO_ACCEPT"] = "Auto Annahme"
L["AUTO_ACCEPT_DESC"] = "Automatische Quest-Annahme."

L["AUTO_TURN_IN"] = "Auto Turn In"
L["AUTO_TURN_IN_DESC"] = "Automatische Quest-Abgabe."

L["AUTO_WAYPOINT"] = "Wegpunkt Automatik "
L["AUTO_WAYPOINT_DESC"] = "Automtischen Wegpunkt zum Schatz setzen."

L["HIDE_WAYPOINT"] = "Wegpunkt verbergen"
L["HIDE_WAYPOINT_DESC"] = "Verbirgt die Koordinaten des Wegpunkts in der Schatzliste."

L["PRINT_TEXT"] = "Chat Nachrichten"
L["PRINT_TEXT_DESC"] = "Überträgt Status Meldungen in den Chat."


-- Tabs
L["TREASURE_LIST"] = "Schatzliste"
L["VENDORS"] = "Verkäufer"
L["PROFESSIONS"] = "Berufe"

-- Announcements
L["QUEST_ACCEPTED"] = "Quest automatisch angenommen."
L["QUEST_TURNIN"] = "Quest automatisch abgegeben."
L["WAYPOINT_SET"] = "Wegpunkt erstellt mit der Position des Schatzes."

L["CLICK_TO_SET"] = "Klick um einen Wegpunkt zu setzen"
