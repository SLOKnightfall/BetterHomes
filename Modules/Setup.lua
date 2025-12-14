-- MyAddon.lua
-- Main addon logic

local addonName, addon = ...
addon = LibStub("AceAddon-3.0"):NewAddon(addon, addonName,
	"AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0", "AceSerializer-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Ace3 Options Table
local options = {
	type = "group",
	name = addonName,
	args = {
		autoQuest = {
			type = "group",
			name = L["AUTO_QUEST"],
			desc = L["AUTO_QUEST_DESC"],
			inline = FALSE,
			args = {
				autoAccept = {
					type = "toggle",
					name = L["AUTO_ACCEPT"],
					desc = L["AUTO_ACCEPT_DESC"],
					get = function() return addon.db.global.autoAccept end,
					set = function(_, val) addon.db.global.autoAccept = val end,
				},
				autoTurnIn = {
					type = "toggle",
					name = L["AUTO_TURN_IN"],
					desc = L["AUTO_TURN_IN_DESC"],
					get = function() return addon.db.global.autoTurnIn end,
					set = function(_, val) addon.db.global.autoTurnIn = val end,
				},
				autoWayPoint = {
					type = "toggle",
					name = L["AUTO_WAYPOINT"],
					desc = L["AUTO_WAYPOINT_DESC"],
					get = function() return addon.db.global.autoWayPoint end,
					set = function(_, val) addon.db.global.autoWayPoint = val end,
				},
				Text = {
					type = "toggle",
					name = L["PRINT_TEXT"],
					desc = L["PRINT_TEXT_DESC"],
					get = function() return addon.db.global.printText end,
					set = function(_, val) addon.db.global.printText = val end,
				},
			},
		},
		catelog = {
			type = "group",
			name = "Catelog",
			order = 10,
			args = {
				itemName = {
					type = "toggle",
					name = "Show Item Name",
					desc = "Toggle display of item names in the catalog.",
					order = 1,
					get = function() return addon.db.global.showItemName end,
					set = function(_, val) addon.db.global.showItemName = val end,
				},
				icon = {
					type = "toggle",
					name = "Show Icon",
					desc = "Toggle display of item icons in the catalog.",
					order = 2,
					get = function() return addon.db.global.showIcon end,
					set = function(_, val) addon.db.global.showIcon = val end,
				},

			},
		},
		quests = {
			type = "group",
			name = "Treasure Quest List",
			order = 20,
			args = {
				hideWayPoint = {
					type = "toggle",
					name = L["HIDE_WAYPOINT"],
					desc = L["HIDE_WAYPOINT_DESC"],
					get = function() return addon.db.global.hideWayPoint end,
					set = function(_, val) addon.db.global.hideWayPoint = val end,
				},
			},
		},
	},
}

local defaults = {
	global  = {
	   ['*'] = true,
	   hideWayPoint = false,
	}
}

------------------------------------------------------------
-- Event Handling
------------------------------------------------------------
-- Handles addon load events for Blizzard Housing UI addons.
function addon:OnLoadEvent(event, ...)
	if event ~= "ADDON_LOADED" then return end
	local loadedAddon = ...

	if loadedAddon == "Blizzard_HouseEditor" then
		C_Timer.After(.5, function() addon:InitStorage() end)

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
		--HouseEditorFrame.StoragePanel.PlacedTabID = HouseEditorFrame.StoragePanel:AddNamedTab("Placed")

	elseif loadedAddon == "Blizzard_HousingDashboard" then
		C_Timer.After(0.5, function() addon:InitDashboard(); addon:InitCatalog() end)
	end
end

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("BetterHomes_Options", defaults, true)
	AceConfig:RegisterOptionsTable(addonName, options)
	AceConfigDialog:AddToBlizOptions(addonName, addonName)
	--options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(db)
	-- Register event handler


	addon:BuildProfessionTable()
end


function addon:OnEnable()
	-- Called when the addon is enabled
		-- Register events
	addon:RegisterEvent("ADDON_LOADED", "OnLoadEvent")
	addon:RegisterEvent("PLAYER_ENTERING_WORLD", "OnQuestEvent")
	addon:RegisterEvent("GOSSIP_SHOW", "OnQuestEvent")
	
	addon:RegisterEvent("QUEST_REMOVED", "OnQuestEvent")
	addon:RegisterEvent("QUEST_FINISHED", "OnQuestEvent")
	addon:RegisterEvent("QUEST_LOG_UPDATE", "OnQuestEvent")
end

function addon:OnDisable()
	-- Called when the addon is disabled
end


