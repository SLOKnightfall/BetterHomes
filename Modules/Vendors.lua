-- MyAddon.lua
-- Main addon logic

local addonName, addon = ...
addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local AceGUI = LibStub("AceGUI-3.0")

--------------------------------------------------------------------------------
-- Tree Selection Handler
--------------------------------------------------------------------------------

--- Handle tree node selection and populate vendor list.
-- @param id string: Tree node identifier (xpac\001zone).
local function onClick(id)
	
	local xpac, zone = id:match("^(.-)\001(.+)$")
	if not zone then 
		return
	end
	local _, vendor = zone:match("^(.-)\001(.+)$")

	if not vendor then 
		return
	end

	addon.GUI_ClearContainer(addon.vendorScroll)

	local function FindVendorByName(searchName)
	  for expansion, zones in pairs(addon.VendorData) do
		for zone, vendorList in pairs(zones) do
		  for _, vendor in ipairs(vendorList) do
			if vendor.name == searchName then
				return vendor

			end
		  end
		end
	  end
	  return nil -- not found
	end

	local data = 	FindVendorByName(vendor)

	if not data then return end

	addon.GUI_CreateVendorRow(data, addon.vendorScroll)
end

--------------------------------------------------------------------------------
-- Main GUI Construction
--------------------------------------------------------------------------------

--- Generate the main vendor list view.
function addon:GenerateVendorListView()
	if not self.LISTWINDOW2 then
		local window = AceGUI:Create("InlineGroup")
		window:SetLayout("FILL")
		window.frame:SetParent(HousingDashboardFrame.CatalogContent1)
		window:SetPoint("TOPLEFT", HousingDashboardFrame.CatalogContent1, "TOPLEFT", 0, -35)
		window:SetPoint("BOTTOMRIGHT", HousingDashboardFrame.CatalogContent1.OptionsContainer, "BOTTOMRIGHT", 10, -10)
		self.LISTWINDOW2 = window

		local tree = AceGUI:Create("TreeGroup")
		tree:SetFullHeight(true)
		window:AddChild(tree)
		self.tree = tree

		local innerWindow = AceGUI:Create("SimpleGroup")
		innerWindow:SetLayout("Fill")
		innerWindow.frame:SetParent(tree.content)
		innerWindow:SetPoint("TOPLEFT", tree.content, "TOPLEFT")
		innerWindow:SetPoint("BOTTOMRIGHT", tree.content, "BOTTOMRIGHT")
		innerWindow:SetFullWidth(true)
		innerWindow:SetFullHeight(true)

		local vendorScroll = AceGUI:Create("ScrollFrame")
		vendorScroll:SetLayout("Flow")
		vendorScroll:SetFullWidth(true)
		vendorScroll:SetFullHeight(true)
		innerWindow:AddChild(vendorScroll)
		self.vendorScroll = vendorScroll
	end

	self:RefreshVendorListView()
end

local function OwnedCount(data)
	local count = 0
	local ownedCount = 0
	local items = data.items
	for _, i_data in ipairs(items) do
		local info  = C_HousingCatalog.GetCatalogEntryInfoByRecordID(1, i_data.id, true)
		local entry = info and C_HousingCatalog.GetCatalogEntryInfo(info.entryID) or {}
		local totalOwned = 0

		if info then
			totalOwned = (entry.numStored or 0) + (entry.numPlaced or 0)
			ownedCount = ownedCount + (totalOwned > 0 and 1 or 0)
		end
		count = count + 1
	end

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
function addon:RefreshVendorListView()
	if not self.tree then return end
	self.tree:ReleaseChildren()
	local treeData = {}
	self.tree:SetStatusTable(status)

	for expansion, zones in pairs(addon.VendorData or {}) do
		local entry1 = addon.GUI_CreateTreeEntry(expansion, expansion, true)
		local x_owned, x_total = 0,0
		for zone, z_data in pairs(zones) do
			local z_owned, z_total = 0,0
			local z_table = addon.GUI_CreateTreeEntry(zone, zone, true)
			for vendor, v_data in pairs(z_data) do
				local owned, total = OwnedCount(v_data)
				z_owned = z_owned + owned
				z_total = z_total + total
				table.insert(z_table.children, addon.GUI_CreateTreeEntry(v_data.name,format("%s - %d/%d",v_data.name, owned, total  ), false))

			end
			x_owned = z_owned + x_owned
			x_total = z_total + x_total
			z_table.text = format("%s - %d/%d",zone, z_owned, z_total  )
			table.insert(entry1.children, z_table)
		end
		entry1.text = format("%s - %d/%d",expansion, x_owned, x_total  )

		table.insert(treeData, entry1)
	end

	self.tree:SetTree(treeData)
	self.tree:SetTreeWidth(250)
	self.tree:SetCallback("OnGroupSelected", function(_, _, id) onClick(id) end)
	self.tree:SetCallback("OnClick", function(widget, event, value)
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
eventFrame:SetScript("OnEvent", function() addon:RefreshVendorListView() end)
