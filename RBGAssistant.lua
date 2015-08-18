-- -------------------------------------------------------------------------- --
-- RBG Assistant by Chris Bruce                                                --
-- -------------------------------------------------------------------------- --
--                                                                            --
-- Features:                                                                  --
-- # Stores each Rated Battleground ScoreBoard								  --
-- -------------------------------------------------------------------------- --
--                                                                            --
-- These events are always registered:                                        --
-- - ZONE_CHANGED_NEW_AREA (to determine if current zone is a battleground)   --
--                                                                            --
-- Registered events in battleground:                                         --
-- # If enabled: ------------------------------------------------------------ --
--   - UPDATE_BATTLEFIELD_SCORE                                               --
--   - GROUP_ROSTER_UPDATE                                                    --
--                                                                            --
-- -------------------------------------------------------------------------- --
--                                                                            --
-- slash commands: n/a                                                        --
-- -------------------------------------------------------------------------- --

RBGAssistant_DB = {} -- Saved Variables DB

local shouldRecordSession = true

local RBGAssistant = CreateFrame("Frame")

function RBGAssistant:UpdateDB()
	shouldRecordSession = false
	
	local json = RBGAssistant:GetResultsJSON()

	local bgInfo = {mapName = R, 
					winner = winner,
					leader = leader,
					scores = scores,
					player = player,
					isRated = isRated}

	RBGAssistant_DB[timestamp] = bgInfo
	
	print("RBG Assistant: battleground saved.")
end

function RBGAssistant:GetResultsJSON()
	
	local winner = RBGAssistant:GetCurrentWinner()
	local timestamp = RBGAssistant:GetCurrentTimestamp()
	local mapName = RBGAssistant:GetBGMapName()
	local leader = RBGAssistant:GetBGLeader()
	local scores = RBGAssistant:GetBGScoresJSON()
	local player = RBGAssistant:GetPlayer()
	local isRated = IsRatedBattleground()

	local json = string.format('{"time": "%s", "map": "%s", "leader": "%s", "player": "%s", "is_rated": %s, "scores": %s}', timestamp, mapName, leader, player, isRated, scores)
end

function RBGAssistant:GetCurrentTimestamp()
	local weekday, month, day, year = CalendarGetDate()
	local hour, minute = GetGameTime()

	local timestamp = string.format("%04d-%02d-%02d %02d:%02d", year, month, day, hour, minute)
	return timestamp
end

function RBGAssistant:GetCurrentWinner()
	local winner = GetBattlefieldWinner()
	return RBGAssistant:GetFactionName(winner)
end

function RBGAssistant:GetFactionName(f)
	local faction
	if f == 0 then
		faction = "Horde"
	elseif f == 1 then
		faction = "Alliance"
	end
	return faction
end

function RBGAssistant:GetBGScoresJSON()
	local numScores = GetNumBattlefieldScores()
	local scores = {}

	for i = 1, numScores do
		local name, killingBlows, honorableKills, deaths, honorGained, faction, race, class, classToken, damageDone, healingDone, bgRating, ratingChange, preMatchMMR, mmrChange, talentSpec = GetBattlefieldScore(i)
		
		scores[#scores + 1] = string.format('{"name": "%s", "kb": %d, "hk": %d, "deaths": %d, "honor": %d, "faction": "%s", "race": "%s", "class": "%s", "damage": %d, "healing": %d, "bg_rating": %d, "bg_rating_change": %d, "pre_mmr": %d, "mmr_change": %d, "talent_spec": "%s"}', name, killingBlows, honorableKills, deaths, honorGained, RBGAssistant:GetFactionName(faction), race, class, damageDone, healingDone, bgRating, ratingChange, preMatchMMR, mmrChange, talentSpec}
	end
	return "[" .. table.concat(scrores, ", ") .. "]"
end

function RBGAssistant:GetBGMapName()
	local bgMapName
	for i = 1, GetMaxBattlefieldID() do
		local status, mapName, instanceID, bracketMin, bracketMax, teamSize, registeredMatch = GetBattlefieldStatus(i)
		if status == "active" then
			bgMapName = mapName
			break
		end
	end
	return bgMapName
end

function RBGAssistant:GetBGLeader()
	local bgLeader
	for i = 1, GetNumGroupMembers() do
		local name, rank = GetRaidRosterInfo(i)
		if rank == 2 then
			bgLeader = name
			if not string.find(bgLeader, "-") then
				bgLeader = bgLeader .. "-" .. GetRealmName()
			end
			break
		end
	end
	return bgLeader
end

function RBGAssistant:GetPlayer()
	local name, realm = UnitName("player")
	if realm == nil then
		realm = GetRealmName()
	end
	return name .. "-" .. realm
end



function RBGAssistant:OnEvent(self, event, ...)
	--print("UPDATE_BATTLEFIELD_SCORE")
	local winner = GetBattlefieldWinner()

	if winner == nil then
		shouldRecordSession = true
	elseif shouldRecordSession == true then
		--print("Winner Found")
		RBGAssistant:UpdateDB()
	end
end


RBGAssistant:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")

RBGAssistant:SetScript("OnEvent", RBGAssistant.OnEvent)
print("RBG Assistant Loaded version 1.3")