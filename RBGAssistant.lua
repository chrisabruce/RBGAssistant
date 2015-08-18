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

function RBGAssistant:UpdateDB(winner)
	shouldRecordSession = false
	
	local timestamp = RBGAssistant:GetCurrentTimestamp()
	local status = RBGAssistant:GetBGStatus()
	local leader = RBGAssistant:GetBGLeader()
	local scores = RBGAssistant:GetBGScores()
	local player = RBGAssistant:GetPlayer()
	local isRated = IsRatedBattleground()

	local bgInfo = {bgStatus = status, 
					winner = winner,
					leader = leader,
					scores = scores,
					player = player,
					isRated = isRated}

	RBGAssistant_DB[timestamp] = bgInfo
	
	print("RBG Assistant: battleground saved.")
end

function RBGAssistant:GetCurrentTimestamp()
	local weekday, month, day, year = CalendarGetDate()
	local hour, minute = GetGameTime()

	local timestamp = string.format("%04d-%02d-%02d %02d:%02d", year, month, day, hour, minute)
	return timestamp
end

function RBGAssistant:GetCurrentWinner()
	local winner = GetBattlefieldWinner()
	local winnerName = nil

	if winner == 0 then
		winnerName = "Horde"
	elseif winner == 1 then
		winnerName = "Alliance"
	end

	return winnerName
end

function RBGAssistant:GetBGScores()
	local numScores = GetNumBattlefieldScores()
	local scores = {}

	for i = 1, numScores do
		local name, killingBlows, honorableKills, deaths, honorGained, faction, race, class, classToken, damageDone, healingDone, bgRating, ratingChange, preMatchMMR, mmrChange, talentSpec = GetBattlefieldScore(i)
		scores[#scores + 1] = {name, killingBlows, honorableKills, deaths, honorGained, faction, race, class, classToken, damageDone, healingDone, bgRating, ratingChange, preMatchMMR, mmrChange, talentSpec}
	end
	return scores
end

function RBGAssistant:GetBGStatus()
	local bgStatus = {}
	for i = 1, GetMaxBattlefieldID() do
		status, mapName, instanceID, bracketMin, bracketMax, teamSize, registeredMatch = GetBattlefieldStatus(i)
		if status == "active" then
			bgStatus = {status = status, mapName = mapName, instanceID = instanceID, bracketMin = bracketMin, bracketMax = bracketMax, teamSize = teamSize, registeredMatch = registeredMatch}
			break
		end
	end
	return bgStatus
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

	local winner = RBGAssistant:GetCurrentWinner()

	if winner == nil then
		shouldRecordSession = true
	elseif shouldRecordSession == true then
		--print("Winner Found")
		RBGAssistant:UpdateDB(winner)
	end
end


RBGAssistant:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")

RBGAssistant:SetScript("OnEvent", RBGAssistant.OnEvent)
print("RBG Assistant Loaded version 1.3")