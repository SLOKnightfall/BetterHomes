-- GUIUtils.lua
-- Centralized GUI helper functions

local addonName, addon = ...
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)


--------------------------------------------------------------------------------
-- Item Row
--------------------------------------------------------------------------------

--- Create a row for an item in the vendor list.
-- @param id number: Item ID.
-- @param data table: Item data (expects .id and .name).
-- @param scroll AceGUI ScrollFrame: Parent scroll container.
function addon.GUI_CreateItemRow(id, data, scroll)
	local label = AceGUI:Create("InteractiveLabel")
	local info  = C_HousingCatalog.GetCatalogEntryInfoByRecordID(1, data.id, true)
	local entry = info and C_HousingCatalog.GetCatalogEntryInfo(info.entryID) or {}
	local totalOwned, stored, placed = 0,0,0

	if info then
		totalOwned = (entry.numStored or 0) + (entry.numPlaced or 0)

		local name = string.format("%s (%d)", data.name, totalOwned)
		label:SetText(name)
		label:SetFullWidth(true)
		label:SetImage(info.iconTexture, 0.15, 0.85, 0.15, 0.85)
		label:SetImageSize(120, 120)
	else
		label:SetImage(nil)
	end

	label:SetCallback("OnClick", function()
		if info then
			HousingDashboardFrame.CatalogContent1.PreviewFrame:PreviewCatalogEntryInfo(info)
			HousingDashboardFrame.CatalogContent1.PreviewFrame:Show()
		end
	end)

	label:SetCallback("OnLeave", function() GameTooltip:Hide() end)

	scroll:AddChild(label)
end

local function IsLoaded(addon)
	if C_AddOns and C_AddOns.IsAddOnLoaded then
		return C_AddOns.IsAddOnLoaded(addon)
	elseif IsAddOnLoaded then
		return IsAddOnLoaded(addon)
	end
	return false
end

local function SetWaypoint(data)
	local x = data.x/100
	local y = data.y/100

	if IsLoaded("TomTom") then
		TomTom:AddWaypoint(data.mapID, x,y, {
			title = data.name .. " - " .. (data.zone or ""),
			persistent = false,
			minimap = true,
			world = true,
		})
	end

	if data.mapID and data.x and data.y then
		local mapPoint = UiMapPoint.CreateFromCoordinates(data.mapID, x, y)
		C_Map.SetUserWaypoint(mapPoint)
	end
 end

--------------------------------------------------------------------------------
-- Vendor Row
--------------------------------------------------------------------------------

--- Create a row for a vendor, including coordinates and items.
-- @param data table: Vendor data (expects .name, .x, .y, .items).
-- @param scroll AceGUI ScrollFrame: Parent scroll container.
function addon.GUI_CreateVendorRow(data, scroll)
	if not data then return end
	local heading = AceGUI:Create("Heading")
	heading:SetText(data.name)
	heading:SetFullWidth(true)
	scroll:AddChild(heading)

	local coords = AceGUI:Create("InteractiveLabel")
	coords:SetText(string.format("X:%s Y:%s", data.x or "-", data.y or "-"))
	coords:SetFontObject("GameFontNormalSmall")
	coords:SetFullWidth(false)
	coords:SetImage("Interface\\Icons\\INV_Drink_05",0.15, 0.85, 0.15, 0.85)
	coords:SetWidth(300)
	coords.image:SetAtlas("Waypoint-MapPin-ChatIcon", true)
	coords:SetUserData("vendorInfo",data)
	coords:SetCallback("OnClick", function(widget, event, ...)
		local data = widget:GetUserData("vendorInfo")
		SetWaypoint(data)
	end)
	coords:SetCallback("OnEnter", function()
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
        GameTooltip:SetText(L["CLICK_TO_SET"])
        GameTooltip:Show()
	end)

	coords:SetCallback("OnLeave", function() GameTooltip:Hide() end)


	scroll:AddChild(coords)

	local divider = AceGUI:Create("Heading")
	divider:SetFullWidth(true)
	scroll:AddChild(divider)

	for _, itemData in pairs(data.items or {}) do
		addon.GUI_CreateItemRow(itemData.id, itemData, scroll)
	end

	coords:SetCallback("OnLeave", function() GameTooltip:Hide() end)
end

--------------------------------------------------------------------------------
-- Quest Row
--------------------------------------------------------------------------------

--- Create a quest row in a scroll frame.
-- @param questID number: Quest ID.
-- @param data table: Quest data {x, y, name}.
-- @param scroll AceGUI ScrollFrame: Parent scroll container.
function addon.GUI_CreateQuestRow(questID, data, scroll)
	local label = AceGUI:Create("InteractiveLabel")

	local x, y, name = data[1] * 100, data[2] * 100, data[3]
	local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(questID)

	-- Default display name (white, no totals)
	local displayName = string.format("%s - X:%d Y:%d", name, x, y)

	label:SetFullWidth(true)
	label:SetHeight(30)
	label:SetFontObject("GameFontNormal")

	-- Reward icon and ownership logic
	local numRewards = GetNumQuestLogRewards(questID)
	if numRewards and numRewards > 0 then
		local _, itemTexture, _, _, _, id = GetQuestLogRewardInfo(1, questID)
		local info  = C_HousingCatalog.GetCatalogEntryInfoByItem(id, true)

		if info then
			-- Crop the icon slightly for nicer framing
			label:SetImage(info.iconTexture, 0.15, 0.85, 0.15, 0.85)
			label:SetImageSize(35, 35)

			local totalOwned = (info.numStored or 0) + (info.numPlaced or 0)
			if totalOwned > 0 then
				if isCompleted then
					-- Green text if completed and has items
					displayName = string.format("|cff00ff00%s|r (%d) - X:%d Y:%d", name, totalOwned, x, y)
				else
					-- Yellow text if not completed but has items
					displayName = string.format("|cffffff00%s|r (%d) - X:%d Y:%d", name, totalOwned, x, y)
				end
			else
				-- No items, keep white text
				displayName = string.format("%s - X:%d Y:%d", name, x, y)
			end
			
		end
	end

	label:SetText(displayName)

	-- Click preview
	label:SetCallback("OnClick", function()
		local _, _, _, _, _, itemID = GetQuestLogRewardInfo(1, questID)
		if itemID then
			local info = C_HousingCatalog.GetCatalogEntryInfoByItem(itemID, true)
			HousingDashboardFrame.CatalogContent3.PreviewFrame:PreviewCatalogEntryInfo(info)
			HousingDashboardFrame.CatalogContent3.PreviewFrame:Show()
		end
	end)

	-- Tooltip
	label:SetCallback("OnEnter", function()
		GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
		local _, _, _, _, _, itemID = GetQuestLogRewardInfo(1, questID)
		if itemID then
			local itemLink = select(2, GetItemInfo(itemID))
			if itemLink then
				GameTooltip:SetHyperlink(itemLink)
				GameTooltip:Show()
			end
		end
	end)

	label:SetCallback("OnLeave", function() GameTooltip:Hide() end)

	scroll:AddChild(label)
end

--------------------------------------------------------------------------------
-- Tree Entry
--------------------------------------------------------------------------------

--- Create a tree entry for the TreeGroup widget.
-- @param value string: Internal value.
-- @param text string: Display text.
-- @param hasChildren boolean: Whether this entry should have children.
-- @return table: Tree entry structure.
function addon.GUI_CreateTreeEntry(value, text, hasChildren,iconTexture)
	local entry = {
		value = value,
		text  = text,
		icon  = (iconTexture and iconTexture) or nil,
		children = hasChildren and {} or nil,
	}

	return entry
end

--------------------------------------------------------------------------------
-- Container Helpers
--------------------------------------------------------------------------------

--- Create an InlineGroup container.
function addon.GUI_CreateInlineGroup(parent, layout)
	local group = AceGUI:Create("InlineGroup")
	group:SetLayout(layout)
	group.frame:SetParent(parent)
	return group
end

--- Create a SimpleGroup container.
function addon.GUI_CreateSimpleGroup(parent, layout)
	local group = AceGUI:Create("SimpleGroup")
	group:SetFullWidth(true)
	group:SetFullHeight(true)
	group:SetLayout(layout)
	parent:AddChild(group)
	return group
end

--- Create a ScrollFrame.
function addon.GUI_CreateScrollFrame(parent, layout)
	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout(layout)
	scroll:SetFullWidth(true)
	scroll:SetFullHeight(true)
	parent:AddChild(scroll)
	return scroll
end

--- Create a Heading widget.
function addon.GUI_CreateHeading(parent)
	local heading = AceGUI:Create("Heading")
	heading:SetFullWidth(true)
	heading.label:SetFontObject("GameFontNormalLarge")

	parent:AddChild(heading)
	return heading
end

--- Clear all children from an AceGUI container.
function addon.GUI_ClearContainer(container)
	if not container or not container.children then return end
	for i = #container.children, 1, -1 do
		AceGUI:Release(container.children[i])
		container.children[i] = nil
	end
end

--------------------------------------------------------------------------------
-- Progress Formatting
--------------------------------------------------------------------------------

--- Format a progress string with faction name, completed count, total count, and optional color.
-- @param faction string: Faction name ("Horde", "Alliance", etc.).
-- @param completed number: Number of completed quests/items.
-- @param total number: Total number of quests/items.
-- @param color string|nil: Hex color code (e.g. "00ff00" for green). Defaults to white.
-- @return string: Formatted progress string.
function addon.GUI_FormatProgress(faction, completed, total, color)
	color = "ff0000" -- default Red

	if faction == "Alliance" then
		color = "0000ff" -- default Blue
	end
	
	return string.format("|cff%s%s|r: %d/%d", color, faction, completed, total)
end


local AceGUI = LibStub("AceGUI-3.0")

-- Constructor for TreeOnlyGroup
local function Constructor()
    -- Wrap an existing TreeGroup
    local widget = AceGUI:Create("TreeGroup")

    -- Rebrand the widget type so AceGUI sees it as distinct
    widget.type = "TreeOnlyGroup"

    -- Hide the right-hand content and the splitter/sizer (if present)
    if widget.content then
        widget.content:Hide()
        widget.content:SetWidth(0)
    end
    if widget.sizer then
        widget.sizer:Hide()
        widget.sizer:EnableMouse(false)
    end

    -- Prevent any population of the content area on selection
    widget:SetCallback("OnGroupSelected", function(self, event, value)
        if self.content then
            self.content:Hide()
            self.content:SetWidth(0)
        end
        -- You can handle selection externally here if desired
        -- e.g., Fire a callback or update your own frames
        if self._ExternalOnSelect then
            self:_ExternalOnSelect(value)
        end
    end)

    -- Ensure the tree occupies the full widget area
    local originalLayout = widget.Layout
    widget.Layout = function(self)
        local frame = self.frame
        local treeframe = self.treeframe
        local border = self.border
        local content = self.content

        -- Make the treeframe fill the whole widget
        treeframe:ClearAllPoints()
        treeframe:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -0)
        treeframe:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

        treeframe:SetBackdrop(nil)
		treeframe:SetBackdropColor(0,0,0,0)   -- transparent background
		treeframe:SetBackdropBorderColor(0,0,0,0) -- transparent border

        border:ClearAllPoints()
        border:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -0)
        border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

		border:SetBackdrop(nil)
		border:SetBackdropColor(0,0,0,0)   -- transparent background
		border:SetBackdropBorderColor(0,0,0,0) -- transparent border

        -- Keep content collapsed and hidden
        if content then
            content:Hide()
            content:SetWidth(0)
        end
    end

    -- Re-apply hiding on acquisition (AceGUI calls this when reusing widgets)
    local originalOnAcquire = widget.OnAcquire
    widget.OnAcquire = function(self, ...)
        if originalOnAcquire then originalOnAcquire(self, ...) end
        if self.content then
            self.content:Hide()
            self.content:SetWidth(0)
        end
        if self.sizer then
            self.sizer:Hide()
            self.sizer:EnableMouse(false)
        end
        self:Layout()
    end

    return widget
end

-- Register the new widget type (version can be bumped if you refine it later)
AceGUI:RegisterWidgetType("TreeOnlyGroup", Constructor, 1)
