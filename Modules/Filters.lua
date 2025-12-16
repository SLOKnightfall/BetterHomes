local addonName, addon = ...
addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local AceGUI = LibStub("AceGUI-3.0")


	function CreateFilterDropdown(parent)
	-- Create dropdown on the PreviewFrame
	local filterDropdown = CreateFrame("Frame", "MyAddonFilterDropdown", parent, "UIDropDownMenuTemplate")
	filterDropdown:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -30, -10)

	local currentFilter = "ALL"

	-- Initialize dropdown entries
	UIDropDownMenu_Initialize(filterDropdown, function(self, level, menuList)
	    local info = UIDropDownMenu_CreateInfo()

	    info.text = "All"
	    info.func = function() MyAddon_SetFilter("ALL") end
	    UIDropDownMenu_AddButton(info)

	    info.text = "Alliance"
	    info.func = function() MyAddon_SetFilter("ALLIANCE") end
	    UIDropDownMenu_AddButton(info)

	    info.text = "Horde"
	    info.func = function() MyAddon_SetFilter("HORDE") end
	    UIDropDownMenu_AddButton(info)

	    info.text = "Elven Decor"
	    info.func = function() MyAddon_SetFilter("ELVEN") end
	    UIDropDownMenu_AddButton(info)
	end)

	UIDropDownMenu_SetWidth(filterDropdown, 140)
	UIDropDownMenu_SetText(filterDropdown, "Filter")
end
-- Called when user picks a filter
function MyAddon_SetFilter(filterType)
    currentFilter = filterType
    UIDropDownMenu_SetText(filterDropdown, filterType)
    MyAddon_RefreshCatalog()
end

-- Decide if an entry should be shown
function MyAddon_ShouldShow(entryInfo)
    if currentFilter == "ALL" then return true end
    if currentFilter == "ALLIANCE" and entryInfo.faction == "Alliance" then return true end
    if currentFilter == "HORDE" and entryInfo.faction == "Horde" then return true end
    if currentFilter == "ELVEN" and entryInfo.theme == "Elven" then return true end
    return false
end

-- Refresh the ScrollBox contents
function MyAddon_RefreshCatalog()
    local dataProvider = CatalogContent.PreviewFrame.ScrollBox:GetDataProvider()
    if not dataProvider then return end

    -- Filter entries
    local filtered = {}
    for _, entryInfo in dataProvider:Enumerate() do
        if MyAddon_ShouldShow(entryInfo) then
            table.insert(filtered, entryInfo)
        end
    end

    -- Replace ScrollBox data with filtered list
    CatalogContent.PreviewFrame.ScrollBox:SetDataProvider(CreateDataProvider(filtered))
end



local filteredData = {} -- HousingDashboardFrame.CatalogContent1.Filters.catalogSearcher:GetCatalogSearchResults()

function addon:TryCallSearcherFunc(funcName, ...)
	if not self.catalogSearcher then
		return nil;
	end
	C_Timer.After(0.5, function() addon:RefreshVendorListView() end) 
	return self.catalogSearcher[funcName](self.catalogSearcher, ...);
end

function addon:FilterDropdownInitialize(catalogSearcher, parent)
	local self = parent
	self.filters = {
	}
	self.catalogSearcher = catalogSearcher;

	self.filterTagGroups = C_HousingCatalog.GetAllFilterTagGroups();
	self:ResetFiltersToDefault();

	self.FilterDropdown:SetIsDefaultCallback(function() return self:AreFiltersAtDefault(); end);
	self.FilterDropdown:SetDefaultCallback(function() self:ResetFiltersToDefault(); end);

	local function getCustomizableOnly()
		self.filters.IsCustomizable = self:TryCallSearcherFunc("IsCustomizableOnlyActive");
		addon:RefreshVendorListView()
		return self:TryCallSearcherFunc("IsCustomizableOnlyActive");
	end
	local function toggleCustomizableOnly() 
		self:TryCallSearcherFunc("ToggleCustomizableOnly");
	end

	local function getAllowedIndoors()
		self.filters.FirstAcquisitionBonus = self:TryCallSearcherFunc("IsAllowedIndoorsActive");
		return self:TryCallSearcherFunc("IsAllowedIndoorsActive");

	end
	local function toggleAllowedIndoors() 
		self:TryCallSearcherFunc("ToggleAllowedIndoors");
	end

	local function getAllowedOutdoors()
		self.filters.FirstAcquisitionBonus = self:TryCallSearcherFunc("IsAllowedOutdoorsActive");
		return self:TryCallSearcherFunc("IsAllowedOutdoorsActive");
	end
	local function toggleAllowedOutdoors()
		self:TryCallSearcherFunc("ToggleAllowedOutdoors");
	end

	local function getCollected()
		self.filters.FirstAcquisitionBonus = self:TryCallSearcherFunc("IsCollectedActive");
		return self:TryCallSearcherFunc("IsCollectedActive");
	end
	local function toggleCollected()
		self:TryCallSearcherFunc("ToggleCollected");
	end

	local function getUncollected()
		return self:TryCallSearcherFunc("IsUncollectedActive");
	end
	local function toggleUncollected()
		self:TryCallSearcherFunc("ToggleUncollected");
	end

	local function getFirstAcquisitionBonusOnly()
		--self.filters.FirstAcquisitionBonus = self:TryCallSearcherFunc("IsFirstAcquisitionBonusOnlyActive");
		--addon:RefreshVendorListView()
		return self:TryCallSearcherFunc("IsFirstAcquisitionBonusOnlyActive");
	end
	local function toggleFirstAcquisitionBonusOnly()
		self:TryCallSearcherFunc("ToggleFirstAcquisitionBonusOnly");
	end

	local function checkAllTagGroup(groupID)
		self:TryCallSearcherFunc("SetAllInFilterTagGroup", groupID, true);
		return MenuResponse.Refresh; -- Keeps menu open on click
	end
	local function unCheckAllTagGroup(groupID)
		self:TryCallSearcherFunc("SetAllInFilterTagGroup", groupID, false);
		return MenuResponse.Refresh; -- Keeps menu open on click
	end
	local function isFilterTagChecked(data)
		return self:TryCallSearcherFunc("GetFilterTagStatus", data.groupID, data.tagID);
	end
	local function toggleFilterTag(data)
		self:TryCallSearcherFunc("ToggleFilterTag", data.groupID, data.tagID);
	end

	local function IsSortTypeChecked(parameter)
		return self:TryCallSearcherFunc("GetSortType") == parameter;
	end

	local function SetSortTypeChecked(parameter)
		self:TryCallSearcherFunc("SetSortType", parameter);
	end

	self.FilterDropdown:SetupMenu(function(dropdown, rootDescription)
		rootDescription:CreateCheckbox(HOUSING_CATALOG_FILTERS_DYEABLE, getCustomizableOnly, toggleCustomizableOnly);
		rootDescription:CreateCheckbox(HOUSING_CATALOG_FILTERS_INDOORS, getAllowedIndoors, toggleAllowedIndoors);
		rootDescription:CreateCheckbox(HOUSING_CATALOG_FILTERS_OUTDOORS, getAllowedOutdoors, toggleAllowedOutdoors);

		if self.collectionFiltersAvailable then
			rootDescription:CreateCheckbox(HOUSING_CATALOG_FILTERS_COLLECTED, getCollected, toggleCollected);
			rootDescription:CreateCheckbox(HOUSING_CATALOG_FILTERS_UNCOLLECTED, getUncollected, toggleUncollected);
			rootDescription:CreateCheckbox(HOUSING_CATALOG_FILTERS_FIRST_ACQUISITION, getFirstAcquisitionBonusOnly, toggleFirstAcquisitionBonusOnly);
		end

		--local sortBySubmenu = rootDescription:CreateButton(RAID_FRAME_SORT_LABEL);
		--sortBySubmenu:CreateRadio(HOUSING_CHEST_SORT_TYPE_DATE_ADDED, IsSortTypeChecked, SetSortTypeChecked, Enum.HousingCatalogSortType.DateAdded);
		--sortBySubmenu:CreateRadio(HOUSING_CHEST_SORT_TYPE_ALPHABETICAL, IsSortTypeChecked, SetSortTypeChecked, Enum.HousingCatalogSortType.Alphabetical);

		for groupIndex, tagGroup in ipairs(self.filterTagGroups) do
			if tagGroup.tags and TableHasAnyEntries(tagGroup.tags) then
				local groupSubmenu = rootDescription:CreateButton(tagGroup.groupName);
				groupSubmenu:SetGridMode(MenuConstants.VerticalGridDirection);

				groupSubmenu:CreateButton(CHECK_ALL, checkAllTagGroup, tagGroup.groupID);
				groupSubmenu:CreateButton(UNCHECK_ALL, unCheckAllTagGroup, tagGroup.groupID);

				for tagID, tagInfo in pairs(tagGroup.tags) do
					if tagInfo.anyAssociatedEntries then
						groupSubmenu:CreateCheckbox(tagInfo.tagName, isFilterTagChecked, toggleFilterTag, { groupID = tagGroup.groupID, tagID = tagInfo.tagID });
					end
				end
			end
		end
	end);
end


local id_to_Vendors = {}

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

local localizedKeywords = {
	Vendor = {
		"Vendor", "Verkäufer", "Vendedor", "Vendeur", "Mercante",
		"Comerciante", "商人出售", "상인","Торговец", "商人"
	},
}

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

function addon:FilterData(id, filterList)
	local filteredData = filterList -- HousingDashboardFrame.CatalogContent1.Filters.catalogSearcher:GetCatalogSearchResults()

	local idSet = {}
	for _, data in ipairs(filteredData) do
		if data.recordID == id then
			return true
		end
	end
	return false
end