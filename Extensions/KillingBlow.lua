-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local AUDIOQS = AUDIOQS_4Q5

local extName = "KillingBlow"
local extNameDetailed = "Killing Blow"
local extShortNames = "kb"
local extSpecLimit = AUDIOQS.ANY_SPEC_ALLOWED -- TODO ExtensionsInterface needs update here
local ext_ref_num

local gameState = AUDIOQS.GS
gameState.KB_LockRefilter = 0

-- SOUND FILE -- Change this filename to add your own sound. Drop your file in World of Warcraft/{_retail|_clasic}/Interface/AddOns/AudioQs/Sounds/your_file.ogg
local KILLING_BLOW_SOUND_FILE = AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."tribal_kill.ogg"

-- PLAYER KILLS ONLY - Change 'true' to 'false' to allow all killing blows to trigger sound
local PVP_KILLS_ONLY = true

local MAX_COMBATLOG_BUFFER_SEARCH = 30

local CHAT_FRAME_COMBAT_LOG = ChatFrame2 -- Hard-coded as the combat log in wow ui

mostPreviousKillTimestamp = 0
lastTenKilledGuid = {}

local extSpells, extEvents, extSegments

local extFuncs = { -- For external use
		["GetName"] = function() return extName end,
		["GetNameDetailed"] = function() return extNameDetailed end,
		["GetShortNames"] = function() return extShortNames end,
		["GetExtRef"] = function() return ext_ref_num end,
		["GetVersion"] = function() return extVersion end,
		["GetSpells"] = function() return extSpells end,
		["GetEvents"] = function() return extEvents end,
		["GetPrompts"] = function() return extSegments end,
		["GetExtension"] = function() 
				return {spells=extSpells, events=extEvents, segments=extSegments, extNum=ext_ref_num}
			end,
		["SpecAllowed"] = function(specId) 
				if extSpecLimit == AUDIOQS.ANY_SPEC_ALLOWED or extSpecLimit == specId then
					return true
				end 
			end,

		["Initialize"] = 
			function()
				-- Post-load stuff
				AUDIOQS.KB_GENERIC_KILLED_SEARCH_KEY = Blizzard_CombatLog_Filters.filters[Blizzard_CombatLog_Filters.currentFilter].settings.fullText and UnitName("player")..".-slain" or "You.+killed" -- Bugged on ChatConfigCombatSettings "Verbose" changed
				Blizzard_CombatLog_Filters.filters[Blizzard_CombatLog_Filters.currentFilter].filters[1].eventList.PARTY_KILL = true -- forces the current chatcombatlog filter to track kills, an unfortunate consequence of this whole thing being otherwise impossible. Bugged on switched main chatcombatlog filter changed if the switched-to filter doesn't include kills
			end
}

--- Spell Tables and Prompts --
--
-- spells[spellId] = { "Spell Name", charges, cdDur, cdExpiration, unitId, spellType}
extSpells = { 
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
extEvents = {
		--["PLAYER_TARGET_CHANGED"] = {},
		[AUDIOQS.COMPAT_UNIT_HEALTH_FREQ] = {}, -- WOW_SHADOWLANDS
		["LOADING_SCREEN_DISABLED"] = {}
}

extSegments = {
	--[[["PLAYER_TARGET_CHANGED"] = { -- for deletion
		{
			{
				"AUDIOQS.GS.KM_newTargetPTC = UnitGUID('target') if AUDIOQS.GS.KB_currentTargetGuid ~= AUDIOQS.GS.KM_newTargetPTC then if not AUDIOQS.GS.KB_LockRefilter then Blizzard_CombatLog_Refilter() end return true end",
				false
			},
			{
				0.17, 
				nil, 
				nil, 
				AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION 
			},
			{
				nil, 
				KILLING_BLOW_SOUND_FILE, 
				nil, 
				"return AUDIOQS.KB_CheckLostTargetForPlayerKills(AUDIOQS.GS.KM_newTargetPTC)"
			}
		}
	},]]
	--[[[AUDIOQS.COMPAT_UNIT_HEALTH_FREQ] = { -- for deletion
		{
			{
				"AUDIOQS.GS.KM_newTargetCLE = UnitGUID('target') local cL = AUDIOQS.LoadCombatLog() local e = cL[2] if e == 'UNIT_DIED' or e == 'PARTY_KILL' then if not AUDIOQS.GS.KB_LockRefilter then Blizzard_CombatLog_Refilter() end return true end local dmgType = e:match('(.+)_DAMAGE') if dmgType ~= nil and dmgType ~= 'ENVIRONMENTAL' and (dmgType == 'SWING' and cL[13] or cL[16]) > 0 then if not AUDIOQS.GS.KB_LockRefilter then Blizzard_CombatLog_Refilter() end return true end print('Rejecting '..cL[2])",
				false
			},
			{
				0.17, 
				nil, 
				nil, 
				AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION 
			},
			{
				nil, 
				KILLING_BLOW_SOUND_FILE, 
				nil, 
				"return AUDIOQS.KB_CheckLostTargetForPlayerKills(AUDIOQS.GS.KM_newTargetCLE)"
			}
		}
	},]]
	[AUDIOQS.COMPAT_UNIT_HEALTH_FREQ] = { -- WOW_SHADOWLANDS
		{
			{ -- Start on UHF, stop if we didn't get a UHF in the time we were waiting for completion of the prompt (.'. does not miss kill after killing-blows without a following UHF)
				function() if AUDIOQS.GS.KB_LockRefilter > 0 then if AUDIOQS.GS.KB_LockRefilter < 5 then AUDIOQS.GS.KB_LockRefilter = 30 AUDIOQS.KB_Refilter() end return false end AUDIOQS.GS.KB_LockRefilter = 30 AUDIOQS.KB_Refilter() return true end,
				function() return AUDIOQS.GS.KB_LockRefilter <= 0 end
			},
			{
				0.15,
				nil,
				nil,
				AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION
			},
			{
				0.0,
				KILLING_BLOW_SOUND_FILE,
				AUDIOQS.STOP_SOUND_DISALLOWED,
				function() AUDIOQS.GS.KB_LockRefilter = AUDIOQS.GS.KB_LockRefilter - 1 local foundKill = AUDIOQS.KB_CheckLostTargetForPlayerKills(UnitGUID('target')) AUDIOQS.KB_Refilter() return foundKill end
			},
			{
				0.0,
				nil,
				nil,
				AUDIOQS.PROMPTSEG_CONDITIONAL_RESTART
			}
		}
	},
	["LOADING_SCREEN_DISABLED"] = { -- TODO Should be in an "essentials", hidden extension or in the AudioQs.lua main event handlers. Workaround for now.
		{
			{
				function() AUDIOQS.KB_LockRefilter = 0xFFFF AUDIOQS.KB_Refilter() return true end,
				false
			},
			{5.0, 	nil, nil, AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION},
			{nil,	nil, nil, function() local e = COMBATLOG.historyBuffer.elements for i=1,#e,1 do local m = e[i].message if m:find(AUDIOQS.KB_GENERIC_KILLED_SEARCH_KEY) then local thisKilledGuid = m:match('.-Hunit.-Hunit:(.-):') AUDIOQS.KB_RotationalInsert(thisKilledGuid) end end AUDIOQS.KB_LockRefilter = 0 return true end}
		}
	}
}
--
-- /Spell Tables and Rules

--- Funcs --
--
function AUDIOQS.KB_RotationalInsert(Guid)
	table.insert(lastTenKilledGuid, 1, Guid)
	lastTenKilledGuid[11] = nil
end

function AUDIOQS.KB_Refilter()
	if CHAT_FRAME_COMBAT_LOG:IsVisible() then return end -- Refreshing was only needed when the combat log was not open, because it would shut-off when not visible to the user.
	Blizzard_CombatLog_Refilter()
	--if AUDIOQS.WOW_VC then
	--	AUDIOQS.KB_clcRefilterTimestamp = time()
	--end
end

function AUDIOQS.KB_CheckLostTargetForPlayerKills(thisGuid)
	gameState.KB_currentTargetGuid = thisGuid
	local buffer = COMBATLOG.historyBuffer.elements
	local bufferSize = #buffer
	local h, m, s
	local currentTimestamp
	
	if bufferSize < 1 then
		return false
	end
	
	currentTimestamp = buffer[1].timestamp
	
	for i=bufferSize,max(1, bufferSize-MAX_COMBATLOG_BUFFER_SEARCH),-1 do
		local thisMessage = buffer[i].message
		local thisTimestamp
		
		thisTimestamp = buffer[i].timestamp

		if currentTimestamp > thisTimestamp + 2 then
			return false
		end
		
		--print("found ", thisMessage:find(AUDIOQS.KB_GENERIC_KILLED_SEARCH_KEY))
		if thisMessage:find(AUDIOQS.KB_GENERIC_KILLED_SEARCH_KEY) then
			local thisKilledGuid = thisMessage:match(".-Hunit.-Hunit:(.-):")
			--print(thisKilledGuid)
		
			if not PVP_KILLS_ONLY or thisKilledGuid:find("Player") then
				local previouslyRecorded = false
				for j=1,#lastTenKilledGuid,1 do
					if lastTenKilledGuid[j] == thisKilledGuid then
						previouslyRecorded = true
						break -- Already on the list, but we may have called them out-of-order. Search the rest and see if we should prompt again.
					end
				end
				if not previouslyRecorded then
					if thisTimestamp >= mostPreviousKillTimestamp or (mostPreviousKillTimestamp - thisTimestamp) > 2 then -- Newer kill, or most previous kill was yesterday on the clock
						mostPreviousKillTimestamp = thisTimestamp
						AUDIOQS.KB_RotationalInsert(thisKilledGuid)
						return true
					end
				end
			end
		end
	end
end

GetName = function()
	return extName
end

GetNameDetailed = function()
	return extNameDetailed
end

GetShortNames = function()
	return extShortNames
end

GetVersion = function()
	return extVersion
end

GetSpells = function()
	return extSpells
end

GetEvents = function()
	return extEvents
end

GetSegments = function()
	return extSegments
end

GetExtension = function()
	return {spells=extSpells, events=extEvents, segments=extSegments}
end

SpecAllowed = function(specId)
	if extSpecLimit == AUDIOQS.ANY_SPEC_ALLOWED or extSpecLimit == specId then
		return true
	end
	return false
end
--
-- /Funcs --

-- Register Extension:
ext_ref_num = AUDIOQS.RegisterExtension(extName, extFuncs)