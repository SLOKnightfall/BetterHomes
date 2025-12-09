-- MyAddon.lua
-- Main addon logic for DecorTreasureHunt

local addonName, addon = ...
addon = LibStub("AceAddon-3.0"):GetAddon(addonName)
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
local MAP_RAZORWIND, RAZORWIND_NPC = 2351, 253596
local MAP_FOUNDERS, FOUNDERS_NPC   = 2352, 248854

local MAP_NAMES = {
	[MAP_FOUNDERS] = "Founder's Point",   -- Alliance
	[MAP_RAZORWIND] = "Razorwind Shores", -- Horde
}

--------------------------------------------------------------------------------
-- Waypoint Helpers
--------------------------------------------------------------------------------
local tomtomWaypointUid

--- Print formatted addon output.
local function printOutput(text)
	print("|cffe6c619" .. addonName .. ":|r " .. text)
end

--- Set a user waypoint and optionally a TomTom waypoint.
local function setUserWaypoint(x, y)
	local mapId = C_Map.GetBestMapForUnit("player")
	if not mapId or (mapId ~= MAP_RAZORWIND and mapId ~= MAP_FOUNDERS) then return end

	C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapId, x, y))
	C_SuperTrack.SetSuperTrackedUserWaypoint(true)

	if TomTom and TomTom.AddWaypoint then
		tomtomWaypointUid = TomTom:AddWaypoint(mapId, x, y, { title = addonName })
	end
	printOutput(L.WAYPOINT_SET)
end

--- Clear TomTom waypoint if present.
local function clearTomTomWaypoint()
	if TomTom and TomTom.RemoveWaypoint then
		TomTom:RemoveWaypoint(tomtomWaypointUid)
	end
end

--- Clear user waypoint and TomTom waypoint.
local function clearUserWaypoint()
	C_Map.ClearUserWaypoint()
	clearTomTomWaypoint()
end

--------------------------------------------------------------------------------
-- Event Handling
--------------------------------------------------------------------------------

--- Handle addon events.
function addon:OnEvent(event, name, questID)
	if event == "ADDON_LOADED" and name == addonName then
		self:UnregisterEvent(event)
		if not DecorTreasureHuntDB then
			DecorTreasureHuntDB = { autoAccept = true, autoTurnIn = true }
		end
		return
	end

	if event == "PLAYER_ENTERING_WORLD" then
		for i = 1, C_QuestLog.GetNumQuestLogEntries() do
			local info = C_QuestLog.GetInfo(i)
			if info and not info.isHeader then
				local mapId = C_Map.GetBestMapForUnit("player")
				local data = addon.QuestData[mapId] and addon.QuestData[mapId][info.questID]
				if data then
					questId = info.questID
					event = "QUEST_ACCEPTED"
					break
				end
			end
		end
	end

	if event == "GOSSIP_SHOW" then
		local guid = UnitGUID("npc")
		if not guid or IsShiftKeyDown() or not DecorTreasureHuntDB.autoAccept then return end

		local npcId = tonumber((select(6, strsplit("-", guid))))
		if npcId == RAZORWIND_NPC or npcId == FOUNDERS_NPC then
			local mapId = C_Map.GetBestMapForUnit("player")
			for _, data in ipairs(C_GossipInfo.GetAvailableQuests() or {}) do
				if addon.QuestData[mapId][data.questID] then
					self:RegisterEvent("QUEST_DETAIL", "OnEvent")
					C_GossipInfo.SelectAvailableQuest(data.questID)
					break
				end
			end
		end
		return
	elseif event == "QUEST_DETAIL" then
		AcceptQuest()
		printOutput(L.QUEST_ACCEPTED)
		return
	elseif event == "QUEST_ACCEPTED" then
		local mapId = C_Map.GetBestMapForUnit("player")
		local data = addon.QuestData[mapId][questId]
		setUserWaypoint(data[1], data[2])
		self:RegisterEvent("QUEST_COMPLETE", "OnEvent")
	elseif event == "QUEST_COMPLETE" then
		if IsShiftKeyDown() or not DecorTreasureHuntDB.autoTurnIn then return end
		GetQuestReward(1)
		self:UnregisterEvent("QUEST_COMPLETE")
		self:UnregisterEvent("QUEST_DETAIL")
		printOutput(L.QUEST_TURNIN)
		return
	elseif event == "QUEST_FINISHED" then
		clearUserWaypoint()
		self:UnregisterEvent("QUEST_DETAIL")
		self:UnregisterEvent("QUEST_COMPLETE")
		return
	elseif event == "QUEST_REMOVED" then
		clearUserWaypoint()
		self:UnregisterEvent("QUEST_COMPLETE")
	elseif event == "QUEST_LOG_UPDATE" then
		addon:RefreshListView()
	end
end
-- Register events
addon:RegisterEvent("ADDON_LOADED", "OnEvent")
addon:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
addon:RegisterEvent("GOSSIP_SHOW", "OnEvent")
addon:RegisterEvent("QUEST_ACCEPTED", "OnEvent")
addon:RegisterEvent("QUEST_REMOVED", "OnEvent")
addon:RegisterEvent("QUEST_FINISHED", "OnEvent")
addon:RegisterEvent("QUEST_LOG_UPDATE", "OnEvent")

--------------------------------------------------------------------------------
-- Quest Completion Helper
--------------------------------------------------------------------------------

--- Get completion stats for a quest list.
local function getCompletion(list)
	local completed, count = 0, 0
	for questID in pairs(list) do
		if C_QuestLog.IsQuestFlaggedCompleted(questID) then
			completed = completed + 1
		end
		count = count + 1
	end
	return completed, count
end

--------------------------------------------------------------------------------
-- GUI Integration (using GUIUtils)
--------------------------------------------------------------------------------

--- Create a quest row in the scroll frame.
function addon:CreateQuestRow(questID, data, scroll)
	addon.GUI_CreateQuestRow(questID, data, scroll)
end

--- Generate treasure list view.
function addon:GenerateTreasureListView()
	if not self.LISTWINDOW then
		local window = addon.GUI_CreateInlineGroup(HousingDashboardFrame.CatalogContent2, "Flow")
				window:SetPoint("TOPLEFT", HousingDashboardFrame.CatalogContent2, "TOPLEFT", 0, -35)
		window:SetPoint("BOTTOMRIGHT", HousingDashboardFrame.CatalogContent2.PreviewFrame, "BOTTOMLEFT", 10)
		self.LISTWINDOW = window

		local scrollContainer = addon.GUI_CreateSimpleGroup(window, "Fill")
		local scroll = addon.GUI_CreateScrollFrame(scrollContainer, "Flow")
		self.scroll = scroll
	end

	self:RefreshListView()
end

--- Refresh treasure list view.
function addon:RefreshListView()
	if not self.scroll then return end
	addon.GUI_ClearContainer(self.scroll)

	local hordeHeading, allianceHeading
	for mapID, mapData in pairs(addon.QuestData) do
		if mapID == MAP_RAZORWIND or mapID == MAP_FOUNDERS then
			local heading = addon.GUI_CreateHeading(self.scroll)
			if mapID == MAP_RAZORWIND then
				hordeHeading = heading
			else
				allianceHeading = heading
			end
		end

		local completed, total = getCompletion(mapData)
		if mapID == MAP_RAZORWIND and hordeHeading then
			hordeHeading:SetText(addon.GUI_FormatProgress("Horde", completed, total, "00ff00"))   -- green
		elseif allianceHeading then
			allianceHeading:SetText(addon.GUI_FormatProgress("Alliance", completed, total, "0000ff")) -- blue
		end

		for questID, data in pairs(mapData) do
			if data then
				self:CreateQuestRow(questID, data, self.scroll)
			end
		end
	end
end