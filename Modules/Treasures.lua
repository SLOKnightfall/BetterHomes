
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
local currentWayPoint
local TomTomLoaded = false
local currentQuest
local waypointSet = false

--- Print formatted addon output.
local function PrintOutput(text)
	if addon.db.global.printText then
		print(text)
	end
end

--- Set a user waypoint and optionally a TomTom waypoint.
local function SetUserWaypoint(x, y)
	if not addon.db.global.autoWayPoint then return end

	local mapId = C_Map.GetBestMapForUnit("player")
	if not mapId or (mapId ~= MAP_RAZORWIND and mapId ~= MAP_FOUNDERS) then return end

	C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapId, x, y))
	C_SuperTrack.SetSuperTrackedUserWaypoint(true)

	if TomTomLoaded and TomTom.AddWaypoint then
		currentWayPoint = TomTom:AddWaypoint(mapId, x, y, { title = "Housing Treasure" })
	end
	waypointSet = true
	PrintOutput(L.WAYPOINT_SET)
end

--- Clear TomTom waypoint if present.
local function ClearTomTomWaypoint()
	if TomTom.RemoveWaypoint then
		TomTom:RemoveWaypoint(currentWayPoint)
	end
end

--- Clear user waypoint and TomTom waypoint.
local function ClearUserWaypoint(questId)
	if waypointSet == questId then
		waypointSet = false
		C_Map.ClearUserWaypoint()
		if TomTomLoaded then
			ClearTomTomWaypoint()
		end
	end
end

--------------------------------------------------------------------------------
-- Event Handling
--------------------------------------------------------------------------------

--- Handle addon events.
function addon:OnQuestEvent(event, name, questID)
	local function AcceptQuestEvent(questId)
		currentQuest = questID 
		local mapId = C_Map.GetBestMapForUnit("player")
		local data = addon.QuestData[tostring(mapId)][tostring(questId)]
		SetUserWaypoint(data[1], data[2])
		self:RegisterEvent("QUEST_COMPLETE", "OnQuestEvent")
		self:UnregisterEvent("QUEST_ACCEPTED")
		return
	end

	if event == "PLAYER_ENTERING_WORLD" then
		TomTomLoaded = C_AddOns.IsAddOnLoaded("TomTom")
		for i = 1, C_QuestLog.GetNumQuestLogEntries() do
			local info = C_QuestLog.GetInfo(i)
			if info and not info.isHeader then
				local mapId = C_Map.GetBestMapForUnit("player")
				local data = addon.QuestData[tostring(mapId)] and addon.QuestData[tostring(mapId)][tostring(info.questID)]
				if data then
					AcceptQuestEvent(info.questID)
					return
				end
			end
		end
	end

	if event == "GOSSIP_SHOW" then
		local unitGUID = UnitGUID("npc")
		if not unitGUID  then return end
		local npcId = tonumber((select(6, strsplit("-", unitGUID))))
		if RAZORWIND_NPC ~= npcId and FOUNDERS_NPC ~= npcId  then return end
		local mapId = tostring(C_Map.GetBestMapForUnit("player"))
		for _, data in ipairs(C_GossipInfo.GetAvailableQuests() or {}) do
			if addon.QuestData[mapId][tostring(data.questID)] then
				self:RegisterEvent("QUEST_DETAIL", "OnQuestEvent")
				if addon.db.global.autoAccept then
					C_GossipInfo.SelectAvailableQuest(tonumber(data.questID))
					break
				end
			end
		end
		return
	elseif event == "QUEST_DETAIL" then
		addon:RegisterEvent("QUEST_ACCEPTED", "OnQuestEvent")
		AcceptQuest()
		return
	elseif event == "QUEST_ACCEPTED" then
		AcceptQuestEvent(name)
	elseif event == "QUEST_COMPLETE" then
		if name == currentQuest then
			currentQuest = nil
			if addon.db.global.autoTurnIn then
				GetQuestReward(1)
			end
			self:UnregisterEvent("QUEST_COMPLETE")
			self:UnregisterEvent("QUEST_DETAIL")
			return
		end
	elseif event == "QUEST_FINISHED" then
		if name == currentQuest then 
			ClearUserWaypoint()
			currentQuest = nil
			self:UnregisterEvent("QUEST_DETAIL")
			self:UnregisterEvent("QUEST_COMPLETE")
			return
		end
	elseif event == "QUEST_REMOVED" then
		if name == currentQuest then 
			ClearUserWaypoint()
			self:UnregisterEvent("QUEST_COMPLETE")
			currentQuest = nil
		end
	elseif event == "QUEST_LOG_UPDATE" then
		addon:RefreshListView()
	end
end


--------------------------------------------------------------------------------
-- Quest Completion Helper
--------------------------------------------------------------------------------

--- Get completion stats for a quest list.
local function GetQuestCompletion(list)
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
local function CreateQuestRow(questID, data, scroll)
	addon.GUI_CreateQuestRow(questID, data, scroll)
end

--- Generate treasure list view.
function addon:GenerateTreasureListView()
	if not self.LISTWINDOW then
		local window = addon.GUI_CreateInlineGroup(HousingDashboardFrame.CatalogContent3, "Flow")
		window:SetPoint("TOPLEFT", HousingDashboardFrame.CatalogContent3, "TOPLEFT", 0, -35)
		window:SetPoint("BOTTOMRIGHT", HousingDashboardFrame.CatalogContent3.PreviewFrame, "BOTTOMLEFT", 10)
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

		local completed, total = GetQuestCompletion(mapData)
		if mapID == MAP_RAZORWIND and hordeHeading then
			hordeHeading:SetText(addon.GUI_FormatProgress("Horde", completed, total, "00ff00"))   -- green
		elseif allianceHeading then
			allianceHeading:SetText(addon.GUI_FormatProgress("Alliance", completed, total, "0000ff")) -- blue
		end

		for questID, data in pairs(mapData) do
			if data then
				CreateQuestRow(questID, data, self.scroll)
			end
		end
	end
end