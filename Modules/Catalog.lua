--[[ 
Addon Initialization
This addon extends the Blizzard Housing UI with custom overlays and tabs.
It uses AceAddon-3.0 for modularity and event handling.
]]

local addonName, addon = ...
addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- Unified icon lookup
local function GetIcon(category, key)
	local icons = {
		Profession = {
			["Alchemy"]       = "Interface\\Icons\\Trade_Alchemy",
			["Blacksmithing"] = "Interface\\Icons\\Trade_BlackSmithing",
			["Enchanting"]    = "Interface\\Icons\\Trade_Engraving",
			["Engineering"]   = "Interface\\Icons\\Trade_Engineering",
			["Herbalism"]     = "Interface\\Icons\\Trade_Herbalism",
			["Inscription"]   = "Interface\\Icons\\INV_Inscription_Tradeskill01",
			["Jewelcrafting"] = "Interface\\Icons\\INV_Misc_Gem_01",
			["Leatherworking"]= "Interface\\Icons\\Trade_LeatherWorking",
			["Mining"]        = "Interface\\Icons\\Trade_Mining",
			["Skinning"]      = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
			["Tailoring"]     = "Interface\\Icons\\Trade_Tailoring",
			["Cooking"]       = "Interface\\Icons\\INV_Misc_Food_15",
			["Fishing"]       = "Interface\\Icons\\Trade_Fishing",
			["First Aid"]     = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
		},
		Quest = {
			["Default"]  = "Interface\\MINIMAP\\MapQuestHub_Icon32", -- yellow "!"
		},
		Vendor = {
			["Default"] = "Interface\\Icons\\INV_Misc_Coin_01",
		},
		Achievement = {
			["Default"] = "Interface\\MINIMAP\\Minimap_shield_normal.blp",
		},
	}

	local categoryTable = icons[category]
	if categoryTable then
		return categoryTable[key] or categoryTable["Default"] or "Interface\\Icons\\INV_Misc_QuestionMark"
	end
	return "Interface\\Icons\\INV_Misc_QuestionMark"
end

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

	-- Profession icon in upper-left corner with mask
	local icon = newFrame:CreateTexture(nil, "OVERLAY")
	icon:SetSize(20, 20)
	icon:SetPoint("TOPLEFT", newFrame, "TOPLEFT", 2, -2)

	local iconMask = newFrame:CreateMaskTexture()
	iconMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
	iconMask:SetAllPoints(icon)
	icon:AddMaskTexture(iconMask)
	newFrame.icon = icon

	-- Circular border around the icon
	local border = newFrame:CreateTexture(nil, "OVERLAY")
	border:SetSize(48, 48) -- slightly larger than icon
	border:SetPoint("TOPLEFT", icon, "TOPLEFT",-4,4)

	-- Use a Blizzard ring texture or your own
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

	-- Optional: tint the border to make it pop
	border:SetVertexColor(1, 0.84, 0, 1) -- gold color (R,G,B,A)

	-- Optional: blend mode for glow effect
	border:SetBlendMode("ADD")

	newFrame.iconBorder = border

	function newFrame:ShowIcon()
		self.icon:Show()
		self.iconBorder:Show()
	end

	function newFrame:HideIcon()
		self.icon:Hide()
		self.iconBorder:Hide()
	end		

	-- Generic setter
	function newFrame:SetIcon(category, key)
		self.icon:SetTexture(GetIcon(category, key))
	end

	return newFrame
end


-- Use Blizzard global strings instead of hard-coded localized words
-- These are defined in GlobalStrings.lua and localized per client

local localizedKeywords = {
	Achievement = {
		"Achievement", "Erfolg", "Haut fait", "Logro", "Impresa",
		"Conquista", "Достижение", "成就", "업적",
	},
	Vendor = {
		"Vendor", "Verkäufer", "Vendedor", "Vendeur", "Mercante",
		"Comerciante", "商人出售", "상인","Торговец", "商人"
	},
	Quest = {
		"Quest", "Quête", "Misión", "Missão", "Missione",
		"Задание", "任务", "任務", "퀘스트",
	},
}


-- Helper function to check text against global strings
local function ContainsCategory(text)
	local lowerText = string.lower(text)
	for category, words in pairs(localizedKeywords) do
		for _, word in ipairs(words) do
			if word and string.find(lowerText, string.lower(word), 1, true) then
				return category
			end
		end
	end
	return nil -- no match
end

------------------------------------------------------------
-- Update Functions
------------------------------------------------------------
local function updateText(element)
	if not element or not element.entryInfo or not element.overlay1 then return end
	local info = element.entryInfo
	if addon.db.global.showItemName then
		element.overlay1.text:SetText(info.name)
		element.overlay1.text:Show()

	else
		element.overlay1.text:Hide()

	end
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

	local id = info.entryID.recordID
	local profession = addon:IsFromProfession(id)
	local source = ContainsCategory(info.sourceText)
	if addon.db.global.showIcon then
		if profession then
			element.overlay1:SetIcon("Profession", profession)
			element.overlay1:ShowIcon()
		elseif source then
			element.overlay1:SetIcon(source, "Default")
			element.overlay1:ShowIcon()	
		
		else
			element.overlay1:HideIcon()	
		end
	else
		element.overlay1:HideIcon()	
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

	if not scrollBox and addon.debug then
		print("ScrollBox not found: HousingDashboardFrame.CatalogContent.OptionsContainer.ScrollBox")
		return
	end

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
	--contentFrame.Filters:Hide()
	contentFrame.SearchBox:Hide()
	--contentFrame.Filters.TryCallSearcherFunc = addon.TryCallSearcherFunc
	contentFrame.Filters.Initialize = addon.FilterDropdownInitialize
	contentFrame.Filters:Initialize(contentFrame.Filters.catalogSearcher, contentFrame.Filters)
	if anchor == HDF.CatalogTabButton then 
		contentFrame.Filters.catalogSearcher:SetResultsUpdatedCallback(function() addon:RefreshVendorListView(); end);

	elseif anchor == HDF.catalogTab1.tabButton then 
		contentFrame.Filters.catalogSearcher:SetResultsUpdatedCallback(function() addon:RefreshProfessionListView(); end);

	elseif anchor == HDF.catalogTab2.tabButton then 
		--contentFrame.Filters.catalogSearcher:SetResultsUpdatedCallback(function() addon:RefreshVendorListView(); end);
		contentFrame.Filters:Hide()
	end

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
	HDF.catalogTab2, HDF.CatalogContent2 = CreateCatalogTab(HDF, HDF.catalogTab1.tabButton, "PROFESSIONS", "Profession", "Profession;")
	HDF.catalogTab3, HDF.CatalogContent3 = CreateCatalogTab(HDF, HDF.catalogTab2.tabButton, "TREASURE_LIST","QuestLog-tab-icon-quest","QuestLog-tab-icon-quest-inactive")

	-- Post-hook the PreviewCatalogEntryInfo method
	hooksecurefunc(HDF.CatalogContent.PreviewFrame, "PreviewCatalogEntryInfo", function(self, entryInfo)
			-- Your custom logic runs AFTER Blizzard's function executes
			zzz=entryInfo
			local source = addon:IsFromProfession(entryInfo.entryID.recordID)
			if source then
				HDF.CatalogContent.PreviewFrame.TextContainer.SourceInfo:SetText("|cFFFFD200Profession: |r"..source)
				HDF.CatalogContent.PreviewFrame.TextContainer.SourceInfo:Show()
				HDF.CatalogContent.PreviewFrame.TextContainer:Layout();
			end
		end)

end

--[[
HousingDashboardFrame.CatalogContent1.Filters.catalogSearcher:GetCatalogSearchResults()
HousingDashboardFrame.CatalogContent.OptionsContainer:SetCatalogData({
 {
    recordID=14461,
    subtypeIdentifier=0,
    entrySubtype=4,
    entryType=1
  },
})
]]--