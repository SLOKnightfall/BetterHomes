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
			for item, i_data in ipairs(ex_data) do
				id_to_profession[i_data.id] = profession
			end
		end
	end
end

function addon:IsFromProfession(itemID)
	return (id_to_profession[tonumber(itemID)] or false)
end

--------------------------------------------------------------------------------
-- Tree Selection Handler
--------------------------------------------------------------------------------

--- Handle tree node selection and populate vendor list.
-- @param id string: Tree node identifier (xpac\001zone\001vendor).
local function onClick(id)
	
	local profession, xpac = id:match("^(.-)\001(.+)$")
	if not xpac then 
		return
	end
	local _, item = xpac:match("^(.-)\001(.+)$")

	if not item then 
		return
	end

	addon.GUI_ClearContainer(addon.vendorScroll)


	
	local function FindByName(searchName)
	  for profession, xpac in pairs(addon.ProfessionData) do
		for xpac, items in pairs(xpac) do
		  for _, item in ipairs(items) do
			if item.name == searchName then
				return item

			end
		  end
		end
	  end
	  return nil -- not found
	end

	local data = FindByName(item)

	if not data then return end

	local info  = C_HousingCatalog.GetCatalogEntryInfoByRecordID(1, data.id, true)
	local entry = info and C_HousingCatalog.GetCatalogEntryInfo(info.entryID) or {}
	local totalOwned, stored, placed = 0,0,0

	if info then
		HousingDashboardFrame.CatalogContent2.PreviewFrame:PreviewCatalogEntryInfo(info)
		HousingDashboardFrame.CatalogContent2.PreviewFrame:Show()
	end

end

--------------------------------------------------------------------------------
-- Main GUI Construction
--------------------------------------------------------------------------------

--- Generate the main vendor list view.
function addon:GenerateProfessionListView()
	if not self.LISTWINDOW3 then
		local window = AceGUI:Create("InlineGroup")
		window:SetLayout("FILL")
		window.frame:SetParent(HousingDashboardFrame.CatalogContent2)
		window:SetPoint("TOPLEFT", HousingDashboardFrame.CatalogContent2, "TOPLEFT", 0, -35)
		window:SetPoint("BOTTOMRIGHT", HousingDashboardFrame.CatalogContent2.OptionsContainer, "BOTTOMRIGHT", 10, -10)
		self.LISTWINDOW3 = window

		local tree = AceGUI:Create("TreeOnlyGroup")
		--tree:SetFullHeight(true)

		window:AddChild(tree)
		self.prof_tree = tree

	end

	self:RefreshProfessionListView()
end

local function OwnedCount(data)
	local count = 0
	local ownedCount = 0
   -- local items = data.items
	--for _, i_data in ipairs(items) do
		local info  = C_HousingCatalog.GetCatalogEntryInfoByRecordID(1, data.id, true)
		local entry = info and C_HousingCatalog.GetCatalogEntryInfo(info.entryID) or {}
		local totalOwned = 0

		if info then
			totalOwned = (entry.numStored or 0) + (entry.numPlaced or 0)
			ownedCount = ownedCount + (totalOwned > 0 and 1 or 0)
		end
		count = count + 1
   -- end

	return ownedCount, count
end

local function ExpandPath(widget, statusTbl, pathParts)
  local path = ""
  for i, part in ipairs(pathParts) do
	path = (i == 1) and part or (path .. "\001" .. part)  -- AceGUI path separator
	statusTbl.groups[path] = true
  end
  widget:RefreshTree()
  widget:SelectByValue(path) -- select last (deepest) node
end

--------------------------------------------------------------------------------
-- Refresh Tree
--------------------------------------------------------------------------------
local status = { groups = {}, selected = nil }

--- Refresh the tree view with vendor data.
function addon:RefreshProfessionListView()
	if not self.prof_tree then return end
	self.prof_tree:ReleaseChildren()

	local treeData = {}
	self.prof_tree:SetStatusTable(status)

	for expansion, zones in pairs(addon.ProfessionData or {}) do
		local entry1 = addon.GUI_CreateTreeEntry(expansion, expansion, true)
		local x_owned, x_total = 0,0
		for zone, z_data in pairs(zones) do
			local z_owned, z_total = 0,0
			local z_table = addon.GUI_CreateTreeEntry(zone, zone, true)
			for vendor, v_data in pairs(z_data) do
				local owned, total = 0,0 OwnedCount(v_data)
				z_owned = z_owned + owned
				z_total = z_total + total

				local info  = C_HousingCatalog.GetCatalogEntryInfoByRecordID(1, v_data.id, true)
				local iconTexture = nil
				if info then
					iconTexture = info.iconTexture
				end
				
				table.insert(z_table.children, addon.GUI_CreateTreeEntry(v_data.name,format("%s - %d",v_data.name, owned ), false, iconTexture))

			end
			x_owned = z_owned + x_owned
			x_total = z_total + x_total
			z_table.text = format("%s - %d/%d",zone, z_owned, z_total  )
			table.insert(entry1.children, z_table)
		end
		entry1.text = format("%s - %d/%d",expansion, x_owned, x_total  )

		table.insert(treeData, entry1)
	end

	self.prof_tree:SetTree(treeData)
	--self.tree:SetTreeWidth(250)
	self.prof_tree:SetCallback("OnGroupSelected", function(_, _, id) onClick(id) end)


	self.prof_tree:SetCallback("OnClick", function(widget, event, value)
	  -- Convert the clicked path string to parts using the same separator
	  local parts = {}
	  for part in string.gmatch(value, "[^\001]+") do table.insert(parts, part) end
	  ExpandPath(widget, status, parts)
	end)
end

--------------------------------------------------------------------------------
-- Event Handling
--------------------------------------------------------------------------------

-- Refresh tree when quest log updates
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:SetScript("OnEvent", function() addon:RefreshProfessionListView() end)
