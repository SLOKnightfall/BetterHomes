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
		if addon.db.global.showItemName then
			element.overlay1.text:SetText(info.name)
			element.overlay1.text:Show()
		else
			element.overlay1.text:Hide()
		end

		-- Circle badge logic
		if totalOwned == 0 then
			element.overlay1.circleText:SetText("")
		elseif totalPlaced == 0 then
			element.overlay1.circleText:SetText(totalOwned)
		elseif totalOwned == totalPlaced then
			element.overlay1.circleText:SetText("(" .. totalPlaced .. ")")
		else
			element.overlay1.circleText:SetText(totalStored .. " (" .. totalPlaced .. ")")
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
		GameTooltip_AddNormalLine(GameTooltip, info.sourceText)
	end
end

------------------------------------------------------------
-- Initialization
------------------------------------------------------------
-- Initializes overlays for each frame in the Housing Storage Panel.
function addon:InitStorage()
	HouseEditorFrame.StoragePanel.OptionsContainer.ScrollBox:ForEachFrame(function(element)
		if not element.overlay1 then
			local overlay1 = CreateCustomFrame(element)
			overlay1:Show()
			element.overlay1 = overlay1

			-- Hook into element update functions
			hooksecurefunc(element, "UpdateVisuals", function() updateText(element) end)
			hooksecurefunc(element, "AddTooltipLines", function() updateTooltip(element) end)

			updateText(element)
			-- Reposition the customize icon
			element.CustomizeIcon:ClearAllPoints()
			element.CustomizeIcon:SetPoint("TOPLEFT", 5, -6)
		end
	end)

	-- Example: create a standalone circle frame
	--local circleFrame = CreateFrame("Frame", nil, UIParent, "HouseEditorPlacedDecorListTemplate")
	--circleFrame:SetPoint("CENTER", UIParent, "CENTER")
	--circleFrame:Show()
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
		elseif tab.tooltipText == L["TREASURE_LIST"] then
			addon:GenerateTreasureListView() 
		else
			addon:GenerateProfessionListView()
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
