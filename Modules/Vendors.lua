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
    if not zone then return end

    addon.GUI_ClearContainer(addon.vendorScroll)

    local vendors = addon.VendorData[xpac][zone]
    local heading = AceGUI:Create("Heading")
    heading:SetText(zone)
    heading:SetFullWidth(true)
    addon.vendorScroll:AddChild(heading)

    for _, data in pairs(vendors or {}) do
        addon.GUI_CreateVendorRow(data, addon.vendorScroll)
    end
end

--------------------------------------------------------------------------------
-- Main GUI Construction
--------------------------------------------------------------------------------

--- Generate the main vendor list view.
function addon:GenerateVendorListView()
    if not self.LISTWINDOW2 then
        local window = AceGUI:Create("InlineGroup")
        window:SetLayout("FILL")
        window.frame:SetParent(HousingDashboardFrame.CatalogContent3)
        window:SetPoint("TOPLEFT", HousingDashboardFrame.CatalogContent3, "TOPLEFT", 0, -35)
        window:SetPoint("BOTTOMRIGHT", HousingDashboardFrame.CatalogContent3.OptionsContainer, "BOTTOMRIGHT", 10, -10)
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

--------------------------------------------------------------------------------
-- Refresh Tree
--------------------------------------------------------------------------------

--- Refresh the tree view with vendor data.
function addon:RefreshVendorListView()
    if not self.tree then return end
    self.tree:ReleaseChildren()
    local treeData = {}

    for expansion, zones in pairs(addon.VendorData or {}) do
        local entry1 = addon.GUI_CreateTreeEntry(expansion, expansion, true)
        for zone in pairs(zones) do
            table.insert(entry1.children, addon.GUI_CreateTreeEntry(zone, zone, false))
        end
        table.insert(treeData, entry1)
    end

    self.tree:SetTree(treeData)
    self.tree:SetTreeWidth(200)
    self.tree:SetCallback("OnGroupSelected", function(_, _, id) onClick(id) end)
end

--------------------------------------------------------------------------------
-- Event Handling
--------------------------------------------------------------------------------

-- Refresh tree when quest log updates
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:SetScript("OnEvent", function() addon:RefreshVendorListView() end)
