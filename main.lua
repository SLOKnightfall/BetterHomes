--[[ 
Addon Initialization
This addon extends the Blizzard Housing UI with custom overlays and tabs.
It uses AceAddon-3.0 for modularity and event handling.
]]

local addonName, addon = ...
addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local eventframe = CreateFrame("Frame", nil, UIParent)

------------------------------------------------------------
-- Custom Overlay Frame
------------------------------------------------------------
-- Creates a custom overlay frame with text and a circular badge.
-- Used to display item information (owned/placed counts).
local function CreateCustomFrame(parentFrame)
    local newFrame = CreateFrame("Frame", nil, parentFrame)
    newFrame:SetSize(100, 100)
    newFrame:SetPoint("CENTER", parentFrame, "CENTER")

    -- Main text label
    local text = newFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("BOTTOM", newFrame, "BOTTOM", 0, 10)
    text:SetWidth(90)
    text:SetWordWrap(true)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("BOTTOM")
    text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    newFrame.text = text

    -- Circular badge frame
    local circleFrame = CreateFrame("Frame", nil, newFrame)
    circleFrame:SetSize(30, 30)
    circleFrame:SetPoint("TOPRIGHT", newFrame, "TOPRIGHT", -7, -2)

    -- Circle texture with mask
    local circleTex = circleFrame:CreateTexture(nil, "BACKGROUND")
    circleTex:SetAllPoints()
    local mask = circleFrame:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    mask:SetAllPoints(circleTex)
    circleTex:AddMaskTexture(mask)

    -- Text inside the circle badge
    local circleText = circleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    circleText:SetPoint("RIGHT", circleFrame, "RIGHT")
    circleText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    circleText:SetText("NEW")

    newFrame.circleText = circleText
    return newFrame
end

------------------------------------------------------------
-- Update Functions
------------------------------------------------------------
-- Updates overlay text based on item info (owned/placed counts).
local function updateText(element)
    local info = element.entryInfo
    if info then
        local totalStored, totalPlaced = info.numStored, info.numPlaced
        local totalOwned = totalStored + totalPlaced

        element.InfoText:SetText(totalOwned .. ":(" .. totalPlaced .. ")")
        element.InfoText:Hide()

        element.overlay1:Show()
        element.overlay1.text:SetText(info.name)

        -- Circle badge logic
        if totalOwned == 0 then
            element.overlay1.circleText:SetText("")
        elseif totalPlaced == 0 then
            element.overlay1.circleText:SetText(totalOwned)
        elseif totalOwned == totalPlaced then
            element.overlay1.circleText:SetText("(" .. totalPlaced .. ")")
        else
            element.overlay1.circleText:SetText(totalOwned .. " (" .. totalPlaced .. ")")
        end
    else
        element.InfoText:Hide()
        element.overlay1:Hide()
    end
end

-- Adds tooltip information for an element.
local function updateTooltip(element)
    local info = element.entryInfo
    if info then
        print(info.sourceText)
        GameTooltip_AddNormalLine(GameTooltip, info.sourceText)
    end
end

------------------------------------------------------------
-- Initialization
------------------------------------------------------------
-- Initializes overlays for each frame in the Housing Storage Panel.
local function init()
    HouseEditorFrame.StoragePanel.OptionsContainer.ScrollBox:ForEachFrame(function(element)
        if not element.overlay1 then
            local overlay1 = CreateCustomFrame(element)
            overlay1:Show()
            element.overlay1 = overlay1

            -- Hook into element update functions
            hooksecurefunc(element, "UpdateVisuals", function() updateText(element) end)
            hooksecurefunc(element, "AddTooltipLines", function() updateTooltip(element) end)

            -- Reposition the customize icon
            element.CustomizeIcon:ClearAllPoints()
            element.CustomizeIcon:SetPoint("TOPLEFT", 5, -6)
        end
    end)

    -- Example: create a standalone circle frame
    local circleFrame = CreateFrame("Frame", nil, UIParent, "HouseEditorPlacedDecorListTemplate")
    circleFrame:SetPoint("CENTER", UIParent, "CENTER")
    circleFrame:Show()
end

------------------------------------------------------------
-- Dashboard Tabs
------------------------------------------------------------
-- Handles tab clicks in the Housing Dashboard.
local function TabHandler(tab, button, upInside)
    if button == "LeftButton" and upInside then
        HousingDashboardFrame:OnTabButtonClicked(tab)
        if tab.tooltipText == L["VENDORS"] then
            addon:GenerateVendorListView()

        else
            addon:GenerateTreasureListView() 
        end
    end
end

-- Creates a catalog tab with customizable atlas icons.
local function CreateCatalogTab(HDF, anchor, titleKey, activeAtlas, inactiveAtlas)
    local tabButton = CreateFrame("Frame", nil, HDF, "QuestLogTabButtonTemplate")
    tabButton.displayMode = "QuestLogDisplayMode.Quests"
    tabButton.activeAtlas = activeAtlas or "QuestLog-tab-icon-MapLegend"
    tabButton.inactiveAtlas = inactiveAtlas or "QuestLog-tab-icon-MapLegend-inactive"
    tabButton.tooltipText = L[titleKey]
    tabButton:SetPoint("TOP", anchor, "BOTTOM", 0, -12)
    tabButton:SetCustomOnMouseUpHandler(TabHandler)

    local contentFrame = CreateFrame("Frame", nil, HDF, "HousingCatalogFrameTemplate")
    contentFrame:SetAllPoints()
    contentFrame.OptionsContainer:Hide()
    contentFrame.Categories:Hide()

    local tab = {
        tabButton = tabButton,
        contentFrame = contentFrame,
        titleText = L[titleKey],
    }

    table.insert(HDF.tabs, tab)
    return tab, contentFrame
end

-- Initializes custom tabs in the Housing Dashboard.
local function init2()
    local HDF = HousingDashboardFrame
    HDF.catalogTab2, HDF.CatalogContent2 = CreateCatalogTab(HDF, HDF.CatalogTabButton, "TREASURE_LIST")
    HDF.catalogTab3, HDF.CatalogContent3 = CreateCatalogTab(HDF, HDF.catalogTab2.tabButton, "VENDORS")
end

------------------------------------------------------------
-- Event Handling
------------------------------------------------------------
-- Handles addon load events for Blizzard Housing UI addons.
local function This_OnEvent(self, event, ...)
    if event ~= "ADDON_LOADED" then return end
    local loadedAddon = ...

    if loadedAddon == "Blizzard_HouseEditor" then
        C_Timer.After(1, init)

        -- Override market tab visibility logic
        function HouseEditorFrame.StoragePanel:UpdateMarketTabVisibility()
            local marketEnabled = true -- Placeholder for C_Housing.IsHousingMarketEnabled()
            local showingDecor = true -- Placeholder for editor mode check
            local showMarketTab = marketEnabled and showingDecor

            self.TabSystem:SetTabShown(self.marketTabID, showMarketTab)
            if showMarketTab then
                self.TabSystem:SetTabEnabled(self.marketTabID, true, HOUSING_MARKET_TAB_UNAVAILABLE_TEXT)
                self:UpdateMarketTabNotification()
            elseif self:IsInMarketTab() then
                self:SetTab(self.storageTabID)
            end

            EventRegistry:TriggerEvent("HousingMarketTab.VisibilityUpdated")
        end

        -- Add a "Placed" tab
        HouseEditorFrame.StoragePanel.PlacedTabID = HouseEditorFrame.StoragePanel:AddNamedTab("Placed")

    elseif loadedAddon == "Blizzard_HousingDashboard" then
        C_Timer.After(1, init2)
    end
end

-- Register event handler
eventframe:RegisterEvent("ADDON_LOADED")
eventframe:SetScript("OnEvent", This_OnEvent)

