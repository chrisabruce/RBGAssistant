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
	table.insert(RBGAssistant_DB, json)
	
	print("RBG Assistant: battleground saved.")
end

function RBGAssistant:GetResultsJSON()
	local scores = RBGAssistant:GetBGScoresJSON()
	local leader = RBGAssistant:GetBGLeader()
	local winner = RBGAssistant:GetCurrentWinner()
	local timestamp = RBGAssistant:GetCurrentTimestamp()
	local mapName = RBGAssistant:GetBGMapName()
	local player = RBGAssistant:GetPlayer()
	local isRated = IsRatedBattleground()

	return string.format("{\"time\": %q, \"map\": %q, \"winner\": %q, \"leader\": %q, \"player\": %q, \"is_rated\": %s, \"scores\": %s}", timestamp, mapName, winner, leader, player, RBGAssistant:BoolToString(isRated), scores)

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

function RBGAssistant:GetFullName(name)
	local fullname = name
	if not string.find(name, "-") then
		fullname = name .. "-" .. GetRealmName()
	end
	return fullname
end

function RBGAssistant:BoolToString(b)
	str = "false"
	if (b == true) then
		str = "true"
	end
	return str
end


function RBGAssistant:GetBGScoresJSON()
	local numScores = GetNumBattlefieldScores()
	local scores = {}

	for i = 1, numScores do
		local name, killingBlows, honorableKills, deaths, honorGained, faction, race, class, classToken, damageDone, healingDone, bgRating, ratingChange, preMatchMMR, mmrChange, talentSpec = GetBattlefieldScore(i)
		name = RBGAssistant:GetFullName(name)
		local factionName = RBGAssistant:GetFactionName(faction)

		if factionName == nil then
			factionName = "n/a"
		end

		if race == nil then
			race = "n/a"
		end

		if class == nil then
			class = "n/a"
		end

		if talentSpec == nil then
			talentSpec = "n/a"
		end

		--score = score .. string.format("name: %q, ", name)
		--score = score .. string.format("kb: %d, ", killingBlows)
		--score = score .. string.format("hk: %d, ", honorableKills)
		--score = score .. string.format("deaths: %d, ", deaths)
		--score = score .. string.format("honor: %d, ", honorGained)
		--score = score .. string.format("faction: %q, ", factionName)
		--score = score .. string.format("race: %q, ", race)
		--score = score .. string.format("class: %q, ", class)
		--score = score .. string.format("damage: %d, ", damageDone)
		--score = score .. string.format("healing: %d, ", healingDone)
		--score = score .. string.format("bg_rating: %d, ", bgRating)
		--score = score .. string.format("bg_rating_change: %d, ", ratingChange)
		--score = score .. string.format("pre_mmr: %d,", preMatchMMR)
		--score = score .. string.format("mmr_change: %d,", mmrChange)
		--score = score .. string.format("talent_spec: %q}", talentSpec)

		scores[#scores + 1] = string.format("{\"name\": %q, \"kb\": %d, \"hk\": %d, \"deaths\": %d, \"honor\": %d, \"faction\": %q, \"race\": %q, \"class\": %q, \"damage\": %d, \"healing\": %d, \"bg_rating\": %d, \"bg_rating_change\": %d, \"pre_mmr\": %d, \"mmr_change\": %d, \"talent_spec\": %q}", name, killingBlows, honorableKills, deaths, honorGained, factionName, race, class, damageDone, healingDone, bgRating, ratingChange, preMatchMMR, mmrChange, talentSpec)
	end
	return "[" .. table.concat(scores, ", ") .. "]"
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
			bgLeader = RBGAssistant:GetFullName(name)
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