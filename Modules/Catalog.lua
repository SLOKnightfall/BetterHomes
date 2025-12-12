--[[ 
Addon Initialization
This addon extends the Blizzard Housing UI with custom overlays and tabs.
It uses AceAddon-3.0 for modularity and event handling.
]]

local addonName, addon = ...
addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

------------------------------------------------------------
-- Custom Overlay Frame
------------------------------------------------------------
local function CreateCustomFrame(parentFrame)
    local newFrame = CreateFrame("Frame", nil, parentFrame)
    newFrame:SetAllPoints(parentFrame)
    newFrame:SetFrameLevel(parentFrame:GetFrameLevel() + 10)

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
    circleFrame:SetPoint("TOPRIGHT", newFrame, "TOPRIGHT", -2, -2)

    local circleTex = circleFrame:CreateTexture(nil, "BACKGROUND")
    circleTex:SetAllPoints()
    local mask = circleFrame:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    mask:SetAllPoints(circleTex)
    circleTex:AddMaskTexture(mask)

    local circleText = circleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    circleText:SetPoint("CENTER", circleFrame, "CENTER")
    circleText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    newFrame.circleText = circleText

    return newFrame
end

------------------------------------------------------------
-- Update Functions
------------------------------------------------------------
local function updateText(element)
    if not element or not element.entryInfo or not element.overlay1 then return end
    local info = element.entryInfo

    element.overlay1.text:SetText(info.name)
    element.InfoText:SetText("")
    element.InfoText:Hide()

    local totalStored, totalPlaced = info.numStored or 0, info.numPlaced or 0
    local totalOwned = totalStored + totalPlaced

    if totalOwned == 0 then
        element.overlay1.circleText:SetText("")
    elseif totalPlaced == 0 then
        element.overlay1.circleText:SetText(totalOwned)
    elseif totalOwned == totalPlaced then
        element.overlay1.circleText:SetText("(" .. totalPlaced .. ")")
    else
        element.overlay1.circleText:SetText(totalStored .. " (" .. totalPlaced .. ")")
    end
end

local function updateTooltip(element)
    if element and element.entryInfo and element.entryInfo.sourceText then
        GameTooltip_AddNormalLine(GameTooltip, element.entryInfo.sourceText)
    end
end

------------------------------------------------------------
-- Initialization
------------------------------------------------------------
function addon:InitCatalog()
    local scrollBox = HousingDashboardFrame
        and HousingDashboardFrame.CatalogContent
        and HousingDashboardFrame.CatalogContent.OptionsContainer
        and HousingDashboardFrame.CatalogContent.OptionsContainer.ScrollBox

    if not scrollBox then
        print("ScrollBox not found: HousingDashboardFrame.CatalogContent.OptionsContainer.ScrollBox")
        return
    end

    -- Overlay builder
	-- Overlay builder
	local function EnsureOverlay(element)
	  if not element or element.overlay1 then return end

	  local overlay = CreateCustomFrame(element)
	  overlay:Show()
	  element.overlay1 = overlay

	  -- Hook once to element updates so the overlay text stays fresh
	  if not element._overlayHooksInstalled then
	    element._overlayHooksInstalled = true
	    hooksecurefunc(element, "UpdateVisuals", function() updateText(element) end)
	    hooksecurefunc(element, "AddTooltipLines", function() updateTooltip(element) end)
	  end

	  -- Initial sync
	  updateText(element)

	  -- Optional: reposition customize icon
	  if element.CustomizeIcon then
	    element.CustomizeIcon:ClearAllPoints()
	    element.CustomizeIcon:SetPoint("TOPLEFT", 5, -6)
	  end
	end

	-- Cover currently visible frames
	if scrollBox.ForEachFrame then
	  scrollBox:ForEachFrame(EnsureOverlay)
	end

	-- Register string-based events on the ScrollBox
	if scrollBox.RegisterCallback then
	  -- When a frame is acquired/reused, ensure overlay is present
	  scrollBox:RegisterCallback("OnAcquiredFrame", function(_, frame)
	    EnsureOverlay(frame)
	  end)

	  -- When data changes (filters, refresh), re-scan visible frames
	  scrollBox:RegisterCallback("OnDataChanged", function()
	    if scrollBox.ForEachFrame then
	      scrollBox:ForEachFrame(EnsureOverlay)
	    end
	  end)

	  -- When a frame is released, you can hide the overlay (optional)
	  scrollBox:RegisterCallback("OnFrameReleased", function(_, frame)
	    if frame and frame.overlay1 then
	      frame.overlay1:Hide()
	    end
	  end)
	end

	-- Nudge a refresh so overlays apply promptly
	if scrollBox.Update then
	  scrollBox:Update()
	end
end

------------------------------------------------------------
-- Dashboard Tabs
------------------------------------------------------------
local function TabHandler(tab, button, upInside)
    if button == "LeftButton" and upInside then
        HousingDashboardFrame:OnTabButtonClicked(tab)
        if tab.tooltipText == L["VENDORS"] then
            addon:GenerateVendorListView()
        elseif tab.tooltipText == L["TREASURE_LIST"] then
            addon:GenerateTreasureListView()
        else
            addon:GenerateProfessionListView()
        end
    end
end

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

function addon:InitDashboard()
    local HDF = HousingDashboardFrame
    HDF.catalogTab1, HDF.CatalogContent1 = CreateCatalogTab(HDF, HDF.CatalogTabButton, "VENDORS")
    HDF.catalogTab2, HDF.CatalogContent2 = CreateCatalogTab(HDF, HDF.catalogTab1.tabButton, "Professions")
    HDF.catalogTab3, HDF.CatalogContent3 = CreateCatalogTab(HDF, HDF.catalogTab2.tabButton, "TREASURE_LIST")
end
