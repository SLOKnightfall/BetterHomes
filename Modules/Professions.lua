-- MyAddon.lua
-- Main addon logic

local addonName, addon = ...
addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local AceGUI = LibStub("AceGUI-3.0")

local id_to_profession = {}

function addon:BuildProfessionTable()
    local professionData = addon.ProfessionData
    for profession, p_data in pairs(professionData) do
        for expansion, ex_data in pairs(p_data) do
            for item, i_data in ipairs(p_data) do
                id_to_profession[i_data.id] = profession
            end
        end
    end
end

function IsFromProfession(itemID)
    retrun (id_to_profession[itemID] or false)
end