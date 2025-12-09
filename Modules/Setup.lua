-- MyAddon.lua
-- Main addon logic

local addonName, addon = ...
addon = LibStub("AceAddon-3.0"):NewAddon(addon, addonName,
    "AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0", "AceSerializer-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Ace3 Options Table
local options = {
    type = "group",
    name = addonName,
    args = {
        autoQuest = {
            type = "group",
            name = L["AUTO_QUEST"],
            desc = L["AUTO_QUEST_DESC"],
            inline = true,
            args = {
                autoAccept = {
                    type = "toggle",
                    name = L["AUTO_ACCEPT"],
                    desc = L["AUTO_ACCEPT_DESC"],
                    get = function() return DecorTreasureHuntDB.autoAccept end,
                    set = function(_, val) DecorTreasureHuntDB.autoAccept = val end,
                },
                autoTurnIn = {
                    type = "toggle",
                    name = L["AUTO_TURN_IN"],
                    desc = L["AUTO_TURN_IN_DESC"],
                    get = function() return DecorTreasureHuntDB.autoTurnIn end,
                    set = function(_, val) DecorTreasureHuntDB.autoTurnIn = val end,
                },
                printText = {
                    type = "toggle",
                    name = L["PRINT_TEXT"],
                    desc = L["PRINT_TEXT_DESC"],
                    get = function() return DecorTreasureHuntDB.printText end,
                    set = function(_, val) DecorTreasureHuntDB.printText = val end,
                },
            },
        },
    },
}


function addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("BetterHomes_Options")
    AceConfig:RegisterOptionsTable(addonName, options)
    AceConfigDialog:AddToBlizOptions(addonName, addonName)
    --options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)

    addon:BuildProfessionTable()
end

function addon:OnEnable()
    -- Called when the addon is enabled
end

function addon:OnDisable()
    -- Called when the addon is disabled
end


