-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

--~ Calls out raid number of players which are low health in World or PvE, at higher frequencies for lower health. Idea theorized and developed alongside twitch.tv/BlindlyPlayingGames
--~ '1' is player's number for party and PvP. '2' to '4' are party1 to party4.
--~ '2' is focus in PvP and '3' is target in PvP.

-- Directives and advice given below is for documentation of writing further extensions.

--- Extension variables --
--
local mFloor = math.floor

AUDIOQS.DISPEL_FILE_MODIFIER = "_dispel"
AUDIOQS.NO_FILE_MODIFIER = ""

-- TODO Don't like that this is hard-coded, should list the spells which dispel for specs, and search the spell text on load to see what they can do.
local SPEC_DISPEL_TYPES = {
	[65] = {"Poison", "Disease", "Magic"}, 
	[105] = {"Magic", "Curse", "Poison"}, 
	[270] = {"Magic", "Poison", "Disease"}, 
	[256] = {"Magic", "Disease"}, 
	[257] = {"Magic", "Disease"}, 
	[264] = {"Curse", "Magic"}
}

AUDIOQS.GS.INSTANCE_PVMAG =			0x08 	-- b0000 1000
AUDIOQS.GS.INSTANCE_PVE =			0x10	-- b0001 0000
AUDIOQS.GS.INSTANCE_PARTY =			0x11	-- b0001 0001
AUDIOQS.GS.INSTANCE_RAID = 			0x12	-- b0001 0010
AUDIOQS.GS.INSTANCE_SCENARIO =		0x14	-- b0001 0100
AUDIOQS.GS.INSTANCE_PVP =			0x20	-- b0010 0000
AUDIOQS.GS.INSTANCE_ARENA =			0x21	-- b0010 0001
AUDIOQS.GS.INSTANCE_BG =			0x22	-- b0010 0010
local thisSpecDispels

local modesToCheck = {}
--
-- /Extension variables -- 

-- --- Set these >>
local extName = "HealthMonitor"
local extNameDetailed = "Health Monitor for Healers (Raid, Party, World and PvP)"
local extShortNames = "hm|healthtracker|healthtracking"
local extSpecLimit = AUDIOQS.ANY_SPEC_ALLOWED
-- -- << Set those

local GetName
local GetNameDetailed
local GetShortNames
local GetVersion
local GetSpells
local GetEvents
local GetSegments
local GetExtension
local SpecAllowed

local extFuncs = {
		["GetName"] = function() return GetName() end,
		["GetNameDetailed"] = function() return GetNameDetailed() end,
		["GetShortNames"] = function() return GetShortNames() end,
		["GetVersion"] = function() return GetVersion() end,
		["GetSpells"] = function() return GetSpells() end,
		["GetEvents"] = function() return GetEvents() end,
		["GetSegments"] = function() return GetSegments() end,
		["GetExtension"] = function() return GetExtension() end,
		["SpecAllowed"] = function(specId) return SpecAllowed(specId) end,
		["Initialize"] = function() AUDIOQS.GS.HM_initialized = false AUDIOQS.HealthMonitor_CheckMode("INIT") end
}

-- --- Set these >>
local extSpells = {
}
	
local extEvents = {
	["UNIT_HEALTH"] = {
	},
	["ZONE_CHANGED_NEW_AREA"] = {
	},
	["GROUP_ROSTER_UPDATE"] = {
	},
	["UPDATE_BATTLEFIELD_STATUS"] = {
	},
	["PLAYER_ENTERING_WORLD"] = {
	},
	["UNIT_MODEL_CHANGED"] = {
	},
	["UNIT_MAXHEALTH"] = {
	},
	["PLAYER_DEAD"] = {
	}
}
if AUDIOQS.WOW_SPECS_IMPLEMENTED then
	AUDIOQS.AmmendTable(
			extEvents, 
			{["PLAYER_SPECIALIZATION_CHANGED"] = {}}
	)
end

local extSegments = {
	["UNIT_HEALTH"] = {
		{
			{
				"AUDIOQS.HealthMonitor_UpdateHealthSnapshot() return false",
				false
			},
			{nil, nil, nil, nil}
		},
		{ -- Party -- 
			{
				"if (AUDIOQS.GS.HM_playersCalling['player'] ~= true and AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_PVP, AUDIOQS.GS.INSTANCE_SCENARIO) and AUDIOQS.GS.HM_healthSnapshot['player'] < 1) then AUDIOQS.GS.HM_playersCalling['player'] = true return true end", -- Evaluated and stored as an adjustedHp (Inside HealthMonitor_UpdateHealthSnapshot()), therefore, it is < 1.0 and > 1.0. If any changes are made to the requirements e.g. "I only want to monitor those below 80% hp", then the adjusted hp can be evaluated as ((curr))/0.8
				"if AUDIOQS.GS.HM_playersCalling['player'] ~= false and (not AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_PVP, AUDIOQS.GS.INSTANCE_SCENARIO) or AUDIOQS.GS.HM_healthSnapshot['player'] >= 1) then AUDIOQS.GS.HM_playersCalling['player'] = false return true end"
			},
			{
				"return AUDIOQS.GS.HM_delaySnapshot['player']",
				AUDIOQS.SOUND_FUNC_PREFIX.."return (AUDIOQS.HealthMonitor_Dispellable('player') and '"..AUDIOQS.SOUNDS_ROOT.."Numerical/1"..AUDIOQS.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/1.ogg')",
				nil,
				AUDIOQS.PROMPTSEG_CONDITIONAL_REPEATER
			} 
		},
		{
			{
				"if AUDIOQS.GS.HM_playersCalling['party1'] ~= true and AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_ARENA, AUDIOQS.GS.INSTANCE_SCENARIO) and AUDIOQS.GS.HM_healthSnapshot['party1'] < 1 then AUDIOQS.GS.HM_playersCalling['party1'] = true return true end",
				"if AUDIOQS.GS.HM_playersCalling['party1'] ~= false and (not AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_ARENA, AUDIOQS.GS.INSTANCE_SCENARIO) or AUDIOQS.GS.HM_healthSnapshot['party1'] >= 1) then AUDIOQS.GS.HM_playersCalling['party1'] = false return true end"
			},
			{
				"return AUDIOQS.GS.HM_delaySnapshot['party1']",
				AUDIOQS.SOUND_FUNC_PREFIX.."return (AUDIOQS.HealthMonitor_Dispellable('party1') and '"..AUDIOQS.SOUNDS_ROOT.."Numerical/2"..AUDIOQS.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/2.ogg')",
				nil,
				AUDIOQS.PROMPTSEG_CONDITIONAL_REPEATER
			} 
		},
		{
			{
				"if AUDIOQS.GS.HM_playersCalling['party2'] ~= true and AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_ARENA, AUDIOQS.GS.INSTANCE_SCENARIO) and AUDIOQS.GS.HM_healthSnapshot['party2'] < 1 then AUDIOQS.GS.HM_playersCalling['party2'] = true return true end",
				"if AUDIOQS.GS.HM_playersCalling['party2'] ~= false and (not AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_ARENA, AUDIOQS.GS.INSTANCE_SCENARIO) or AUDIOQS.GS.HM_healthSnapshot['party2'] >= 1) then AUDIOQS.GS.HM_playersCalling['party2'] = false return true end"
			},
			{
				"return AUDIOQS.GS.HM_delaySnapshot['party2']",
				AUDIOQS.SOUND_FUNC_PREFIX.."return (AUDIOQS.HealthMonitor_Dispellable('party2') and '"..AUDIOQS.SOUNDS_ROOT.."Numerical/3"..AUDIOQS.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/3.ogg')",
				nil,
				AUDIOQS.PROMPTSEG_CONDITIONAL_REPEATER
			} 
		},
		{
			{
				"if AUDIOQS.GS.HM_playersCalling['party3'] ~= true and AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_ARENA, AUDIOQS.GS.INSTANCE_SCENARIO) and AUDIOQS.GS.HM_healthSnapshot['party3'] < 1 then AUDIOQS.GS.HM_playersCalling['party3'] = true return true end",
				"if AUDIOQS.GS.HM_playersCalling['party3'] ~= false and (not AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_ARENA, AUDIOQS.GS.INSTANCE_SCENARIO) or AUDIOQS.GS.HM_healthSnapshot['party3'] >= 1) then AUDIOQS.GS.HM_playersCalling['party3'] = false return true end"
			},
			{
				"return AUDIOQS.GS.HM_delaySnapshot['party3']",
				AUDIOQS.SOUND_FUNC_PREFIX.."return (AUDIOQS.HealthMonitor_Dispellable('party3') and '"..AUDIOQS.SOUNDS_ROOT.."Numerical/4"..AUDIOQS.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/4.ogg')",
				nil,
				AUDIOQS.PROMPTSEG_CONDITIONAL_REPEATER
			} 
		},
		{
			{
				"if AUDIOQS.GS.HM_playersCalling['party4'] ~= true and AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_ARENA, AUDIOQS.GS.INSTANCE_SCENARIO) and AUDIOQS.GS.HM_healthSnapshot['party4'] < 1 then AUDIOQS.GS.HM_playersCalling['party4'] = true return true end",
				"if AUDIOQS.GS.HM_playersCalling['party4'] ~= false and (not AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_ARENA, AUDIOQS.GS.INSTANCE_SCENARIO) or AUDIOQS.GS.HM_healthSnapshot['party4'] >= 1) then AUDIOQS.GS.HM_playersCalling['party4'] = false return true end"
			},
			{
				"return AUDIOQS.GS.HM_delaySnapshot['party4']",
				AUDIOQS.SOUND_FUNC_PREFIX.."return (AUDIOQS.HealthMonitor_Dispellable('party4') and '"..AUDIOQS.SOUNDS_ROOT.."Numerical/5"..AUDIOQS.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/5.ogg')",
				nil,
				AUDIOQS.PROMPTSEG_CONDITIONAL_REPEATER
			} 
		},
		{ -- Raid --
			{
				"if AUDIOQS.GS.HM_raidSegsStarted1 ~= true and AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_RAID) then AUDIOQS.GS.HM_raidSegsStarted1 = true return true end",
				"if AUDIOQS.GS.HM_raidSegsStarted1 == true and not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_RAID) then AUDIOQS.GS.HM_raidSegsStarted1 = false return true end"
			},
			{
				"if AUDIOQS.GS.HM_alertPriority[1][1] ~= nil and AUDIOQS.GS.HM_settingAlertsPriorityFlag ~= nil then return AUDIOQS.GS.HM_alertPriority[1][3] else return 0xFFFF end", -- Return delay answer, or 18 hours.
				nil,
				nil,
				true
			},
			{
				0.0,
				AUDIOQS.SOUND_FUNC_PREFIX.."if AUDIOQS.GS.HM_informingPlayerRaidN then return nil end local currTime = GetTime() AUDIOQS.GS.HM_previousCallout[AUDIOQS.GS.HM_alertPriority[1][1]] = currTime AUDIOQS.SetPromptTimestamp(currTime) return '"..AUDIOQS.SOUNDS_ROOT.."Numerical/'..(AUDIOQS.GS.HM_alertPriority[1][1])..(AUDIOQS.GS.HM_alertPriority[1][4])..'.ogg'",
				nil,
				AUDIOQS.PROMPTSEG_CONDITIONAL_RESTART
			}
		},
		{
			{
				"if AUDIOQS.GS.HM_raidSegsStarted2 ~= true and AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_RAID) then AUDIOQS.GS.HM_raidSegsStarted2 = true return true end",
				"if AUDIOQS.GS.HM_raidSegsStarted2 == true and not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_RAID) then AUDIOQS.GS.HM_raidSegsStarted2 = false return true end"
			},
			{
				"if AUDIOQS.GS.HM_alertPriority[2][1] ~= nil and AUDIOQS.GS.HM_settingAlertsPriorityFlag ~= nil then return AUDIOQS.GS.HM_alertPriority[2][3] else return 0xFFFF end", -- Return delay answer, or 18 hours.
				nil,
				nil,
				true
			},
			{
				0.0,
				AUDIOQS.SOUND_FUNC_PREFIX.."if AUDIOQS.GS.HM_informingPlayerRaidN then return nil end local currTime = GetTime() AUDIOQS.GS.HM_previousCallout[AUDIOQS.GS.HM_alertPriority[2][1]] = currTime AUDIOQS.SetPromptTimestamp(currTime) return '"..AUDIOQS.SOUNDS_ROOT.."Numerical/'..(AUDIOQS.GS.HM_alertPriority[2][1])..(AUDIOQS.GS.HM_alertPriority[2][4])..'.ogg'",
				nil,
				AUDIOQS.PROMPTSEG_CONDITIONAL_RESTART
			}
		},
		{
			{
				"if AUDIOQS.GS.HM_raidSegsStarted3 ~= true and AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_RAID) then AUDIOQS.GS.HM_raidSegsStarted3 = true return true end",
				"if AUDIOQS.GS.HM_raidSegsStarted3 == true and not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_RAID) then AUDIOQS.GS.HM_raidSegsStarted3 = false return true end"
			},
			{
				"if AUDIOQS.GS.HM_alertPriority[3][1] ~= nil and AUDIOQS.GS.HM_settingAlertsPriorityFlag ~= nil then return AUDIOQS.GS.HM_alertPriority[3][3] else return 0xFFFF end", -- Return delay answer, or 18 hours.
				nil,
				nil,
				true
			},
			{
				0.0,
				AUDIOQS.SOUND_FUNC_PREFIX.."if AUDIOQS.GS.HM_informingPlayerRaidN then return nil end local currTime = GetTime() AUDIOQS.GS.HM_previousCallout[AUDIOQS.GS.HM_alertPriority[3][1]] = currTime AUDIOQS.SetPromptTimestamp(currTime) return '"..AUDIOQS.SOUNDS_ROOT.."Numerical/'..(AUDIOQS.GS.HM_alertPriority[3][1])..(AUDIOQS.GS.HM_alertPriority[3][4])..'.ogg'",
				nil,
				AUDIOQS.PROMPTSEG_CONDITIONAL_RESTART
			}
		},
		{ -- BattleGround --
			{
				"if AUDIOQS.GS.HM_playersCalling['focus'] ~= true and AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_BG) and AUDIOQS.GS.HM_healthSnapshot['focus'] < 1 then AUDIOQS.GS.HM_playersCalling['focus'] = true return true end", -- Evaluated and stored as an adjustedHp (Inside HealthMonitor_UpdateHealthSnapshot()), therefore, it is < 1.0 and > 1.0. If any changes are made to the requirements e.g. "I only want to monitor those below 80% hp", then the adjusted hp can be evaluated as ((curr))/0.8
				"if AUDIOQS.GS.HM_playersCalling['focus'] ~= false and (not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_BG) or AUDIOQS.GS.HM_healthSnapshot['focus'] >= 1) then AUDIOQS.GS.HM_playersCalling['focus'] = false return true end"
			},
			{
				"return AUDIOQS.GS.HM_delaySnapshot['focus']",
				AUDIOQS.SOUND_FUNC_PREFIX.."return (AUDIOQS.HealthMonitor_Dispellable('focus') and '"..AUDIOQS.SOUNDS_ROOT.."Numerical/2"..AUDIOQS.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/2.ogg')",
				nil,
				AUDIOQS.PROMPTSEG_CONDITIONAL_REPEATER
			} 
		},
		{
			{
				"if AUDIOQS.GS.HM_playersCalling['target'] ~= true and AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_BG) and AUDIOQS.GS.HM_healthSnapshot['target'] < 1 then AUDIOQS.GS.HM_playersCalling['target'] = true return true end", -- Evaluated and stored as an adjustedHp (Inside HealthMonitor_UpdateHealthSnapshot()), therefore, it is < 1.0 and > 1.0. If any changes are made to the requirements e.g. "I only want to monitor those below 80% hp", then the adjusted hp can be evaluated as ((curr))/0.8
				"if AUDIOQS.GS.HM_playersCalling['target'] ~= false and (not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_BG) or AUDIOQS.GS.HM_healthSnapshot['target'] >= 1) then AUDIOQS.GS.HM_playersCalling['target'] = false return true end"
			},
			{
				"return AUDIOQS.GS.HM_delaySnapshot['target']",
				AUDIOQS.SOUND_FUNC_PREFIX.."return (AUDIOQS.HealthMonitor_Dispellable('target') and '"..AUDIOQS.SOUNDS_ROOT.."Numerical/3"..AUDIOQS.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/3.ogg')",
				nil,
				AUDIOQS.PROMPTSEG_CONDITIONAL_REPEATER
			} 
		}
	},
	["GROUP_ROSTER_UPDATE"] = {
		{
			{
				"if AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_BG) then AUDIOQS.HealthMonitor_UpdateHealthSnapshot() else AUDIOQS.HealthMonitor_CheckMode('GROUP_ROSTER_UPDATE') end return false",
				false
			},
			{1.0, nil, nil, "AUDIOQS.HealthMonitor_UpdateHealthSnapshot()"} -- This is just a manual 1 second later update to ensure that odd behaviour is caught, like a cutscene of a different area starting in the middle of combat, or an NPC scenario ends by removing all units, and no UNIT_HEALTH to follow.
		},
		{
			{
				"if AUDIOQS.GS.HM_informingPlayerRaidN == true and AUDIOQS.GS.HM_lastPlayerRaidNSpoken ~= AUDIOQS.GS.HM_playerRaidN and not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_PVP) then AUDIOQS.GS.HM_lastPlayerRaidNSpoken = AUDIOQS.GS.HM_playerRaidN return true end return false",
				"return AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_PVP) or not UnitIsUnit('player', 'raid'..AUDIOQS.GS.HM_playerRaidN)"
			},
			{
				0.75,
				AUDIOQS.SOUND_FUNC_PREFIX.."return string.format('Interface/AddOns/AudioQs/Sounds/Numerical/%s.ogg', AUDIOQS.GS.HM_playerRaidN)", 
				nil,
				true
			},
			{
				0.85,
				AUDIOQS.SOUND_PATH_PREFIX.."Interface/AddOns/AudioQs/Sounds/Numerical/your_number_is.ogg", 
				nil, 
				AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION
			},
			{
				nil,
				AUDIOQS.SOUND_FUNC_PREFIX.."AUDIOQS.GS.HM_informingPlayerRaidN = false return string.format('Interface/AddOns/AudioQs/Sounds/Numerical/%s.ogg', AUDIOQS.GS.HM_playerRaidN)", 
				nil, 
				AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION
			}
		}
	},
	["ZONE_CHANGED_NEW_AREA"] = {
		{
			{
				"AUDIOQS.HealthMonitor_CheckMode('ZONE_CHANGED_NEW_AREA') return false",
				false
			},
			{nil, nil, nil, nil}
		}
	},
	["PLAYER_ENTERING_WORLD"] = {
		{
			{
				"AUDIOQS.HealthMonitor_CheckMode('PLAYER_ENTERING_WORLD') AUDIOQS.HealthMonitor_UpdateHealthSnapshot() return false",
				false
			},
			{nil, nil, nil, nil}
		},
		{
			{
				"return AUDIOQS.GS.HM_informingPlayerRaidN == true",
				"return not UnitIsUnit('player', 'raid'..AUDIOQS.GS.HM_playerRaidN)"
			},
			{
				0.75,
				AUDIOQS.SOUND_FUNC_PREFIX.."return 'Interface/AddOns/AudioQs/Sounds/Numerical/'..AUDIOQS.GS.HM_playerRaidN..'.ogg'", 
				nil, 
				true
			},
			{
				0.85,
				AUDIOQS.SOUND_PATH_PREFIX.."Interface/AddOns/AudioQs/Sounds/Numerical/your_number_is.ogg", 
				nil, 
				AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION
			},
			{
				nil,
				AUDIOQS.SOUND_FUNC_PREFIX.."AUDIOQS.GS.HM_informingPlayerRaidN = false return string.format('Interface/AddOns/AudioQs/Sounds/Numerical/%s.ogg', AUDIOQS.GS.HM_playerRaidN)", 
				nil, 
				AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION
			}
		}
	},
	["UPDATE_BATTLEFIELD_STATUS"] = {
		{
			{
				"AUDIOQS.HealthMonitor_CheckModePvP() return false",
				false
			},
			{nil, nil, nil, nil}
		}
	},
	["UNIT_MODEL_CHANGED"] = {
		{
			{
				"AUDIOQS.HealthMonitor_UpdateHealthSnapshot() return true",
				false
			},
			{0.2, nil, nil, true},
			{"AUDIOQS.HealthMonitor_UpdateHealthSnapshot() return nil", nil, nil, AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION}
		}
	},
	["UNIT_MAXHEALTH"] = {
		{
			{
				"AUDIOQS.HealthMonitor_UpdateHealthSnapshot() return false",
				false
			},
			{nil, nil, nil, nil}
		}
	},
	["PLAYER_DEAD"] = {
		{
			{
				"AUDIOQS.HealthMonitor_UpdateHealthSnapshot() return false",
				false
			},
			{nil, nil, nil, nil}
		}
	},
}
if not AUDIOQS.WOW_CLASSIC then
	AUDIOQS.AmmendTable(
			extSegments, 
			{
				["PLAYER_SPECIALIZATION_CHANGED"] = {
					{
						{
							"AUDIOQS.HealthMonitor_CheckMode('PLAYER_SPECIALIZATION_CHANGED') return false",
							false
						},
						{nil, nil, nil, nil}
					}
				}
			}
	)
end
-- -- << Set those

--- Funcs --
--
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
end
--
-- /Funcs --

-- Register Extension:
AUDIOQS.RegisterExtension(extName, extFuncs)

-- --- Set these >> (At will -- For detailed custom code)
local function SetGenericHpVals(unitId, setToOff)
	if unitId == nil then return end
	if UnitExists(unitId) and --[[UnitIsPlayer(unitId) and]] not UnitIsDeadOrGhost(unitId) and not setToOff then
		local adjustedHp = ((UnitHealth(unitId)/UnitHealthMax(unitId))-0.1)/0.80
		AUDIOQS.GS.HM_healthSnapshot[unitId] = adjustedHp
		AUDIOQS.GS.HM_delaySnapshot[unitId] = (0.4 + 2.0*math.max(0, adjustedHp)^1.6)
	else
		AUDIOQS.GS.HM_healthSnapshot[unitId] = 1.0
		AUDIOQS.GS.HM_delaySnapshot[unitId] = 0xFFFF -- 18 hours
	end
end

function AUDIOQS.HealthMonitor_Dispellable(unitId)
	local aura
	if thisSpecDispels then
		for j=1, 40, 1 do
			aura = AUDIOQS.LoadAura(unitId, j, "HARMFUL")
			if aura[AUDIOQS.UNIT_AURA_SPELL_ID] == nil then break end 
			
			local debuffType = aura[AUDIOQS.UNIT_AURA_DEBUFF_TYPE]
			
			for n=1,#thisSpecDispels,1 do
				if debuffType == thisSpecDispels[n] then
					return true
				end
			end
		end
	end
	return false
end

function AUDIOQS.HealthMonitor_ModeIs(modeToCheck)
	if AUDIOQS.GS.HM_mode == nil or modeToCheck == nil then -- Avoid nil arithmetic
		if modeToCheck == nil and AUDIOQS.GS.HM_mode == nil then
			return true
		else
			return false
		end
	elseif modeToCheck % AUDIOQS.GS.INSTANCE_PVMAG == 0 then 	-- Check PvMode
		return mFloor(AUDIOQS.GS.HM_mode / AUDIOQS.GS.INSTANCE_PVMAG) == mFloor(modeToCheck / AUDIOQS.GS.INSTANCE_PVMAG)
	else										-- Check Instance Type
		return AUDIOQS.GS.HM_mode == modeToCheck
	end
end

-------- AUDIOQS.HealthMonitor_AnyModesTrue()
function AUDIOQS.HealthMonitor_AnyModesTrue(...)
	-- Sillyness below is to avoid table creation.
	modesToCheck[1], modesToCheck[2], modesToCheck[3], modesToCheck[4], modesToCheck[5], modesToCheck[6], modesToCheck[7], modesToCheck[8], modesToCheck[9] = ..., select(2, ...), select(3, ...), select(4, ...), select(5, ...), select(6, ...), select(7, ...), select(8, ...), select(9, ...)

	local i = 1
	local mode = modesToCheck[i]
	while mode ~= nil do
		if AUDIOQS.HealthMonitor_ModeIs(mode) then
			return true
		end
		i = i+1
		mode = modesToCheck[i]
	end
	return false
end

function AUDIOQS.HealthMonitor_UpdateHealthSnapshot()
	local numInGroup = GetNumGroupMembers()

	if AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_BG) then
		for n=1,3,1 do
			local thisUnit = (n == 3 and "target" or (n == 2 and "focus" or (n == 1 and "player")))
			if UnitIsDeadOrGhost("player") -- Do not update this unitId if the player is dead, or a more strongly defined unitId exists for the unit, or it is an enemy.
					or ( thisUnit == "target" and ( UnitIsUnit(thisUnit, "player") or UnitIsUnit(thisUnit, "focus") ) ) 
					or ( thisUnit == "focus" and UnitIsUnit(thisUnit, "player") ) 
					or UnitIsEnemy("player", thisUnit) then
				SetGenericHpVals(thisUnit, true) -- Set to off. 
			else -- Update a unit that is in alive state
				SetGenericHpVals(thisUnit)
			end
		end
	elseif AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_PARTY) or AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_ARENA) then
		for n=1,5,1 do -- TODO Iterate over partyUnitIds[n]
			local thisUnit = AUDIOQS.GS.HM_unitIds[n]
			SetGenericHpVals(thisUnit)
		end
	elseif AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_RAID) then
		AUDIOQS.HealthMonitor_CheckLowestForRaid()
	end
end

function AUDIOQS.HealthMonitor_SetPreviousCallout(unitNum, timestamp)
	AUDIOQS.GS.HM_previousCallout[unitNum] = timestamp
end

function AUDIOQS.HealthMonitor_CheckMode(event)
	local instanceName, instanceType = GetInstanceInfo()
	
	if AUDIOQS.GS.HM_initialized ~= true then
		AUDIOQS.GS.HM_ALERT_UNIT_NUM = 1
		AUDIOQS.GS.HM_ALERT_HP_PERCENTAGE = 2
		AUDIOQS.GS.HM_ALERT_MAX_ALERTS = 3
		AUDIOQS.GS.HM_ASSIGNED_NUMBER_SENTENCE_PART_1 = 1
		AUDIOQS.GS.HM_ASSIGNED_NUMBER_SENTENCE_PART_2 = 2
		AUDIOQS.GS.HM_ASSIGNED_NUMBER_SENTENCE_PART_3 = 3
		AUDIOQS.GS.HM_ASSIGNED_NUMBER_SENTENCE_LENGTH_1 = 0.75
		AUDIOQS.GS.HM_ASSIGNED_NUMBER_SENTENCE_LENGTH_2 = 0.85
		
		AUDIOQS.GS.HM_playersCalling = {}
		AUDIOQS.GS.HM_healthSnapshot = {}
		AUDIOQS.GS.HM_delaySnapshot = {}
		
		-- Raid only (Doesn't hurt having 4 empty tables for party, vs a "raidInitialized" variable checked every group_roster_update)
		AUDIOQS.GS.HM_unitIds = {} 
		AUDIOQS.GS.HM_raidUnitsIncluded = {}
		AUDIOQS.GS.HM_previousCallout = {}
		AUDIOQS.GS.HM_alertPriority = {}
		
		AUDIOQS.GS.HM_mode = nil
		AUDIOQS.GS.HM_instanceType = nil
		
		thisSpecDispels = SPEC_DISPEL_TYPES[AUDIOQS.GetSpecId()]
		
		for n=1,AUDIOQS.GS.HM_ALERT_MAX_ALERTS,1 do
			table.insert(AUDIOQS.GS.HM_alertPriority, {nil, 100, 0xFFFF})
		end
		
		AUDIOQS.GS.HM_initialized = true
	end
	
	if event == "PLAYER_SPECIALIZATION_CHANGED" then 
		thisSpecDispels = SPEC_DISPEL_TYPES[AUDIOQS.GetSpecId()]
	end
    
    if (instanceType == "pvp" or instanceType == "arena") then 
		if not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_PVP) then
			if AUDIOQS.GS.HM_mode ~= nil then 
				print(AUDIOQS.audioQsSpecifier..AUDIOQS.extensionColour.."<HealthMonitor>".."|r: "..(AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_PARTY) and "Party" or "Raid").." health call-out stopped.")
			end
			AUDIOQS.HealthMonitor_CheckModePvP()
		end
    elseif AUDIOQS.GS.HM_instanceType ~= instanceType or event == "GROUP_ROSTER_UPDATE" or (IsInRaid() and AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_PARTY) or (not IsInRaid() and AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_RAID))) then
		AUDIOQS.GS.HM_instanceType = instanceType
        
        AUDIOQS.GS.HM_numInGroup = (GetNumGroupMembers() > 0 and GetNumGroupMembers() or 1)
        
        if IsInRaid() then -- Raid mode (PvE)
			local j = 1
            for n = 1, 40, 1 do
                local thisId = string.format("raid%s", n)
				AUDIOQS.GS.HM_unitIds[n] = thisId
                if UnitExists(thisId) then 
                    AUDIOQS.GS.HM_raidUnitsIncluded[j] = thisId
					j = j + 1
                end
				AUDIOQS.GS.HM_previousCallout[n] = 0
				if UnitIsUnit("player", thisId) and AUDIOQS.GS.HM_playerRaidN ~= n and event == "GROUP_ROSTER_UPDATE" then
					AUDIOQS.GS.HM_informingPlayerRaidN = true
					AUDIOQS.GS.HM_playerRaidN = n
				end
            end
			
			for n=1,GetNumGroupMembers(),1 do
				local thisId = "raid"..n
				AUDIOQS.GS.HM_healthSnapshot[thisId] = 1.0
				AUDIOQS.GS.HM_delaySnapshot[thisId] = nil
			end
            
            if not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_RAID) then   
                if AUDIOQS.GS.HM_mode ~= nil then 
                    print(AUDIOQS.audioQsSpecifier..AUDIOQS.extensionColour.."<HealthMonitor>"..
						"|r: Switched to Raid health call-out.")
                else
                    print(AUDIOQS.audioQsSpecifier..AUDIOQS.extensionColour.."<HealthMonitor>"..
						"|r: Raid health call-out started.")
                end
                
                AUDIOQS.GS.HM_mode = AUDIOQS.GS.INSTANCE_RAID
            end
        elseif not IsInRaid() and not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_PARTY) then -- Party and World Mode (PvE)   
            AUDIOQS.GS.HM_unitIds = {"player", "party1", "party2", "party3", "party4"}
			
			AUDIOQS.GS.HM_playersCalling["player"] = false
			AUDIOQS.GS.HM_healthSnapshot["player"] = 1.0
			AUDIOQS.GS.HM_delaySnapshot["player"] = 0xFFFF
			for n = #AUDIOQS.GS.HM_unitIds - 1, 1, -1 do
				thisId = string.format("party%s", n)
				AUDIOQS.GS.HM_playersCalling[thisId] = false
				AUDIOQS.GS.HM_healthSnapshot[thisId] = 1.0
				AUDIOQS.GS.HM_delaySnapshot[thisId] = 0xFFFF
			end
			
            if AUDIOQS.GS.HM_mode ~= nil then
                print(AUDIOQS.audioQsSpecifier..AUDIOQS.extensionColour.."<HealthMonitor>".."|r: Switched to Party health call-out.")
            else
                print(AUDIOQS.audioQsSpecifier..AUDIOQS.extensionColour.."<HealthMonitor>".."|r: Party health call-out started.")
            end
            
            AUDIOQS.GS.HM_mode = AUDIOQS.GS.INSTANCE_PARTY
        end
        
		AUDIOQS.HealthMonitor_UpdateHealthSnapshot()
		
        return
    end
end

function AUDIOQS.HealthMonitor_CheckLowestForRaid() -- Raid mode
	AUDIOQS.GS.HM_settingAlertsPriorityFlag = true
	for n=1,AUDIOQS.GS.HM_ALERT_MAX_ALERTS,1 do -- TODO Read Lua scope / Garbage collection tute. May not need this.
		local thisAlertPriority = AUDIOQS.GS.HM_alertPriority[n]
		thisAlertPriority[1] = nil
		thisAlertPriority[2] = 100
		thisAlertPriority[3] = 0xFFFF
		thisAlertPriority[4] = AUDIOQS.NO_FILE_MODIFIER
	end
	
	for i = 1, 40, 1 do
		local unitId = AUDIOQS.GS.HM_unitIds[i]
		
		if not UnitIsDeadOrGhost(unitId) and 
				AUDIOQS.GS.HM_raidUnitsIncluded[i] and
				UnitExists(unitId) then
			local unitIncHeals = math.max(0, UnitGetIncomingHeals(unitId))
			local unitHpPercentage = 
			(UnitHealth(unitId) + unitIncHeals) / UnitHealthMax(unitId)
			
			if unitHpPercentage < 0.95 then
				local n = 1
				local inserted = false
				local prevNum = nil
				local prevHp = nil
				local prevDelay = nil
				local adjustedHp = unitHpPercentage
				
				if unitId == "player" or UnitGroupRolesAssigned(unitId) == "TANK" then
					adjustedHp = math.max(0, 0.5*math.log(0.3*adjustedHp) + 1.4)
				end
				
				while n <= AUDIOQS.GS.HM_ALERT_MAX_ALERTS do
					if inserted == true then
						local nextNum = AUDIOQS.GS.HM_alertPriority[n][1]
						local nextHp = AUDIOQS.GS.HM_alertPriority[n][2]
						local nextDelay = AUDIOQS.GS.HM_alertPriority[n][3]
						
						AUDIOQS.GS.HM_alertPriority[n][1] = prevNum
						AUDIOQS.GS.HM_alertPriority[n][2] = prevHp
						AUDIOQS.GS.HM_alertPriority[n][3] = prevDelay
						
						prevNum = nextNum
						prevHp = nextHp
						prevDelay = nextDelay
					elseif adjustedHp < 
					AUDIOQS.GS.HM_alertPriority[n][2] then
						prevNum = AUDIOQS.GS.HM_alertPriority[n][1]
						prevHp = AUDIOQS.GS.HM_alertPriority[n][2]
						prevDelay = AUDIOQS.GS.HM_alertPriority[n][3]

						AUDIOQS.GS.HM_alertPriority[n][1] = i
						AUDIOQS.GS.HM_alertPriority[n][2] = adjustedHp
						AUDIOQS.GS.HM_alertPriority[n][3] = 3.0 / (1 + math.exp(-4*(math.pow(adjustedHp, 2)-0.4)))
						
						inserted = true
					end
					n = n + 1
				end
			end
		end
	end
	for n=1, AUDIOQS.GS.HM_ALERT_MAX_ALERTS, 1 do
		local unitId = AUDIOQS.GS.HM_unitIds[AUDIOQS.GS.HM_alertPriority[n][1]]
		if unitId ~= nil and AUDIOQS.HealthMonitor_Dispellable(unitId) then
			AUDIOQS.GS.HM_alertPriority[n][4] = AUDIOQS.DISPEL_FILE_MODIFIER
		end
	end
	AUDIOQS.GS.HM_settingAlertsPriorityFlag = false
end

function AUDIOQS.HealthMonitor_CheckModePvP()
	local instanceName, instanceType, _, _, _, _, _, instanceId = GetInstanceInfo()
	
--if AUDIOQS.VERBOSE then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."Checking PvP Mode. name =", instanceName, "; instanceType =", instanceType, "; winner =", GetBattlefieldWinner(), ";") end
    
    if AUDIOQS.GS.HM_instanceCompletedOrNotBg == true then
        if AUDIOQS.GS.HM_instanceId == instanceId then
            return
        else
			AUDIOQS.GS.HM_instanceId = instanceId
			AUDIOQS.GS.HM_instanceCompletedOrNotBg = false
        end
    end
    
    if AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_PVP) and
    (GetBattlefieldWinner() ~= nil or not (instanceType == "pvp" or instanceType == "arena")) then
		AUDIOQS.GS.HM_instanceCompletedOrNotBg = true
		AUDIOQS.GS.HM_instanceId = instanceId
		AUDIOQS.GS.HM_mode = nil
        return
    elseif (instanceType == "pvp" or instanceType == "arena") and not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_PVP) then
		AUDIOQS.GS.HM_instanceType = instanceType
		AUDIOQS.GS.HM_instanceId = instanceId
        
        AUDIOQS.GS.HM_mode = (instanceType == "pvp" and AUDIOQS.GS.INSTANCE_BG or AUDIOQS.GS.INSTANCE_ARENA)
		
		AUDIOQS.HealthMonitor_UpdateHealthSnapshot()
		
        print(AUDIOQS.audioQsSpecifier..AUDIOQS.extensionColour.."<HealthMonitor>".."|r: "..(instanceType == "pvp" and "Battleground" or "Arena").." health call-out started.")
    end
end
-- -- << Set those 
