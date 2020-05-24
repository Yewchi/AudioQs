-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

--~ Calls out raid number of players which are low health in World or PvE, at higher frequencies for lower health. Idea theorized and developed alongside twitch.tv/BlindlyPlayingGames
--~ '1' is player's number for party and PvP. '2' to '4' are party1 to party4.
--~ '2' is focus in PvP and '3' is target in PvP.

-- Directives and advice given below is for documentation of writing further extensions.

--- Extension variables --
--
local mFloor = math.floor

AQ.DISPEL_FILE_MODIFIER = "_dispel"
AQ.NO_FILE_MODIFIER = ""

-- TODO Don't like that this is hard-coded, should list the spells which dispel for specs, and search the spell text on load to see what they can do.
local SPEC_DISPEL_TYPES = {
	[65] = {"Poison", "Disease", "Magic"}, 
	[105] = {"Magic", "Curse", "Poison"}, 
	[270] = {"Magic", "Poison", "Disease"}, 
	[256] = {"Magic", "Disease"}, 
	[257] = {"Magic", "Disease"}, 
	[264] = {"Curse", "Magic"}
}

AQ.GS.INSTANCE_PVMAG =				0x08 	-- b0000 1000
AQ.GS.INSTANCE_PVE =				0x10	-- b0001 0000
AQ.GS.INSTANCE_PARTY =				0x11	-- b0001 0001
AQ.GS.INSTANCE_RAID = 				0x12	-- b0001 0010
AQ.GS.INSTANCE_SCENARIO =			0x14	-- b0001 0100
AQ.GS.INSTANCE_PVP =				0x20	-- b0010 0000
AQ.GS.INSTANCE_ARENA =				0x21	-- b0010 0001
AQ.GS.INSTANCE_BG =					0x22	-- b0010 0010
local thisSpecDispels

local modesToCheck = {}
--
-- /Extension variables -- 

-- --- Set these >>
local extName = "HealthMonitor"
local extNameDetailed = "Health Monitor for Healers (Raid, Party, World and PvP)"
local extShortNames = "hm|healthtracker|healthtracking"
local extSpecLimit = AQ.ANY_SPEC_ALLOWED
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
		["Initialize"] = function() AQ.GS.HM_initialized = false AQ.HealthMonitor_CheckMode("INIT") end
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
if not AQ.WOW_CLASSIC then
	AQ.AmmendTable(
			extEvents, 
			{["PLAYER_SPECIALIZATION_CHANGED"] = {}}
	)
end

local extSegments = {
	["UNIT_HEALTH"] = {
		{
			{
				"AQ.HealthMonitor_UpdateHealthSnapshot() return false",
				false
			},
			{nil, nil, nil, nil}
		},
		{ -- Party -- 
			{
				"if (AQ.GS.HM_playersCalling['player'] ~= true and AQ.HealthMonitor_AnyModesTrue(AQ.GS.INSTANCE_PARTY, AQ.GS.INSTANCE_PVP, AQ.GS.INSTANCE_SCENARIO) and AQ.GS.HM_healthSnapshot['player'] < 1) then AQ.GS.HM_playersCalling['player'] = true return true end", -- Evaluated and stored as an adjustedHp (Inside HealthMonitor_UpdateHealthSnapshot()), therefore, it is < 1.0 and > 1.0. If any changes are made to the requirements e.g. "I only want to monitor those below 80% hp", then the adjusted hp can be evaluated as ((curr))/0.8
				"if AQ.GS.HM_playersCalling['player'] ~= false and (not AQ.HealthMonitor_AnyModesTrue(AQ.GS.INSTANCE_PARTY, AQ.GS.INSTANCE_PVP, AQ.GS.INSTANCE_SCENARIO) or AQ.GS.HM_healthSnapshot['player'] >= 1) then AQ.GS.HM_playersCalling['player'] = false return true end"
			},
			{
				"return AQ.GS.HM_delaySnapshot['player']",
				AQ.SOUND_FUNC_PREFIX.."return (AQ.HealthMonitor_Dispellable('player') and '"..AQ.SOUNDS_ROOT.."Numerical/1"..AQ.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/1.ogg')",
				nil,
				AQ.PROMPTSEG_CONDITIONAL_REPEATER
			} 
		},
		{
			{
				"if AQ.GS.HM_playersCalling['party1'] ~= true and AQ.HealthMonitor_AnyModesTrue(AQ.GS.INSTANCE_PARTY, AQ.GS.INSTANCE_ARENA, AQ.GS.INSTANCE_SCENARIO) and AQ.GS.HM_healthSnapshot['party1'] < 1 then AQ.GS.HM_playersCalling['party1'] = true return true end",
				"if AQ.GS.HM_playersCalling['party1'] ~= false and (not AQ.HealthMonitor_AnyModesTrue(AQ.GS.INSTANCE_PARTY, AQ.GS.INSTANCE_ARENA, AQ.GS.INSTANCE_SCENARIO) or AQ.GS.HM_healthSnapshot['party1'] >= 1) then AQ.GS.HM_playersCalling['party1'] = false return true end"
			},
			{
				"return AQ.GS.HM_delaySnapshot['party1']",
				AQ.SOUND_FUNC_PREFIX.."return (AQ.HealthMonitor_Dispellable('party1') and '"..AQ.SOUNDS_ROOT.."Numerical/2"..AQ.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/2.ogg')",
				nil,
				AQ.PROMPTSEG_CONDITIONAL_REPEATER
			} 
		},
		{
			{
				"if AQ.GS.HM_playersCalling['party2'] ~= true and AQ.HealthMonitor_AnyModesTrue(AQ.GS.INSTANCE_PARTY, AQ.GS.INSTANCE_ARENA, AQ.GS.INSTANCE_SCENARIO) and AQ.GS.HM_healthSnapshot['party2'] < 1 then AQ.GS.HM_playersCalling['party2'] = true return true end",
				"if AQ.GS.HM_playersCalling['party2'] ~= false and (not AQ.HealthMonitor_AnyModesTrue(AQ.GS.INSTANCE_PARTY, AQ.GS.INSTANCE_ARENA, AQ.GS.INSTANCE_SCENARIO) or AQ.GS.HM_healthSnapshot['party2'] >= 1) then AQ.GS.HM_playersCalling['party2'] = false return true end"
			},
			{
				"return AQ.GS.HM_delaySnapshot['party2']",
				AQ.SOUND_FUNC_PREFIX.."return (AQ.HealthMonitor_Dispellable('party2') and '"..AQ.SOUNDS_ROOT.."Numerical/3"..AQ.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/3.ogg')",
				nil,
				AQ.PROMPTSEG_CONDITIONAL_REPEATER
			} 
		},
		{
			{
				"if AQ.GS.HM_playersCalling['party3'] ~= true and AQ.HealthMonitor_AnyModesTrue(AQ.GS.INSTANCE_PARTY, AQ.GS.INSTANCE_ARENA, AQ.GS.INSTANCE_SCENARIO) and AQ.GS.HM_healthSnapshot['party3'] < 1 then AQ.GS.HM_playersCalling['party3'] = true return true end",
				"if AQ.GS.HM_playersCalling['party3'] ~= false and (not AQ.HealthMonitor_AnyModesTrue(AQ.GS.INSTANCE_PARTY, AQ.GS.INSTANCE_ARENA, AQ.GS.INSTANCE_SCENARIO) or AQ.GS.HM_healthSnapshot['party3'] >= 1) then AQ.GS.HM_playersCalling['party3'] = false return true end"
			},
			{
				"return AQ.GS.HM_delaySnapshot['party3']",
				AQ.SOUND_FUNC_PREFIX.."return (AQ.HealthMonitor_Dispellable('party3') and '"..AQ.SOUNDS_ROOT.."Numerical/4"..AQ.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/4.ogg')",
				nil,
				AQ.PROMPTSEG_CONDITIONAL_REPEATER
			} 
		},
		{
			{
				"if AQ.GS.HM_playersCalling['party4'] ~= true and AQ.HealthMonitor_AnyModesTrue(AQ.GS.INSTANCE_PARTY, AQ.GS.INSTANCE_ARENA, AQ.GS.INSTANCE_SCENARIO) and AQ.GS.HM_healthSnapshot['party4'] < 1 then AQ.GS.HM_playersCalling['party4'] = true return true end",
				"if AQ.GS.HM_playersCalling['party4'] ~= false and (not AQ.HealthMonitor_AnyModesTrue(AQ.GS.INSTANCE_PARTY, AQ.GS.INSTANCE_ARENA, AQ.GS.INSTANCE_SCENARIO) or AQ.GS.HM_healthSnapshot['party4'] >= 1) then AQ.GS.HM_playersCalling['party4'] = false return true end"
			},
			{
				"return AQ.GS.HM_delaySnapshot['party4']",
				AQ.SOUND_FUNC_PREFIX.."return (AQ.HealthMonitor_Dispellable('party4') and '"..AQ.SOUNDS_ROOT.."Numerical/5"..AQ.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/5.ogg')",
				nil,
				AQ.PROMPTSEG_CONDITIONAL_REPEATER
			} 
		},
		{ -- Raid --
			{
				"if AQ.GS.HM_raidSegsStarted1 ~= true and AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_RAID) then AQ.GS.HM_raidSegsStarted1 = true return true end",
				"if AQ.GS.HM_raidSegsStarted1 == true and not AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_RAID) then AQ.GS.HM_raidSegsStarted1 = false return true end"
			},
			{
				"if AQ.GS.HM_alertPriority[1][1] ~= nil and AQ.GS.HM_settingAlertsPriorityFlag ~= nil then return AQ.GS.HM_alertPriority[1][3] else return 0xFFFF end", -- Return delay answer, or 18 hours.
				nil,
				nil,
				true
			},
			{
				0.0,
				AQ.SOUND_FUNC_PREFIX.."if AQ.GS.HM_informingPlayerRaidN then return nil end local currTime = GetTime() AQ.GS.HM_previousCallout[AQ.GS.HM_alertPriority[1][1]] = currTime AQ.SetPromptTimestamp(currTime) return '"..AQ.SOUNDS_ROOT.."Numerical/'..(AQ.GS.HM_alertPriority[1][1])..(AQ.GS.HM_alertPriority[1][4])..'.ogg'",
				nil,
				AQ.PROMPTSEG_CONDITIONAL_RESTART
			}
		},
		{
			{
				"if AQ.GS.HM_raidSegsStarted2 ~= true and AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_RAID) then AQ.GS.HM_raidSegsStarted2 = true return true end",
				"if AQ.GS.HM_raidSegsStarted2 == true and not AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_RAID) then AQ.GS.HM_raidSegsStarted2 = false return true end"
			},
			{
				"if AQ.GS.HM_alertPriority[2][1] ~= nil and AQ.GS.HM_settingAlertsPriorityFlag ~= nil then return AQ.GS.HM_alertPriority[2][3] else return 0xFFFF end", -- Return delay answer, or 18 hours.
				nil,
				nil,
				true
			},
			{
				0.0,
				AQ.SOUND_FUNC_PREFIX.."if AQ.GS.HM_informingPlayerRaidN then return nil end local currTime = GetTime() AQ.GS.HM_previousCallout[AQ.GS.HM_alertPriority[2][1]] = currTime AQ.SetPromptTimestamp(currTime) return '"..AQ.SOUNDS_ROOT.."Numerical/'..(AQ.GS.HM_alertPriority[2][1])..(AQ.GS.HM_alertPriority[2][4])..'.ogg'",
				nil,
				AQ.PROMPTSEG_CONDITIONAL_RESTART
			}
		},
		{
			{
				"if AQ.GS.HM_raidSegsStarted3 ~= true and AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_RAID) then AQ.GS.HM_raidSegsStarted3 = true return true end",
				"if AQ.GS.HM_raidSegsStarted3 == true and not AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_RAID) then AQ.GS.HM_raidSegsStarted3 = false return true end"
			},
			{
				"if AQ.GS.HM_alertPriority[3][1] ~= nil and AQ.GS.HM_settingAlertsPriorityFlag ~= nil then return AQ.GS.HM_alertPriority[3][3] else return 0xFFFF end", -- Return delay answer, or 18 hours.
				nil,
				nil,
				true
			},
			{
				0.0,
				AQ.SOUND_FUNC_PREFIX.."if AQ.GS.HM_informingPlayerRaidN then return nil end local currTime = GetTime() AQ.GS.HM_previousCallout[AQ.GS.HM_alertPriority[3][1]] = currTime AQ.SetPromptTimestamp(currTime) return '"..AQ.SOUNDS_ROOT.."Numerical/'..(AQ.GS.HM_alertPriority[3][1])..(AQ.GS.HM_alertPriority[3][4])..'.ogg'",
				nil,
				AQ.PROMPTSEG_CONDITIONAL_RESTART
			}
		},
		{ -- BattleGround --
			{
				"if AQ.GS.HM_playersCalling['focus'] ~= true and AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_BG) and AQ.GS.HM_healthSnapshot['focus'] < 1 then AQ.GS.HM_playersCalling['focus'] = true return true end", -- Evaluated and stored as an adjustedHp (Inside HealthMonitor_UpdateHealthSnapshot()), therefore, it is < 1.0 and > 1.0. If any changes are made to the requirements e.g. "I only want to monitor those below 80% hp", then the adjusted hp can be evaluated as ((curr))/0.8
				"if AQ.GS.HM_playersCalling['focus'] ~= false and (not AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_BG) or AQ.GS.HM_healthSnapshot['focus'] >= 1) then AQ.GS.HM_playersCalling['focus'] = false return true end"
			},
			{
				"return AQ.GS.HM_delaySnapshot['focus']",
				AQ.SOUND_FUNC_PREFIX.."return (AQ.HealthMonitor_Dispellable('focus') and '"..AQ.SOUNDS_ROOT.."Numerical/2"..AQ.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/2.ogg')",
				nil,
				AQ.PROMPTSEG_CONDITIONAL_REPEATER
			} 
		},
		{
			{
				"if AQ.GS.HM_playersCalling['target'] ~= true and AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_BG) and AQ.GS.HM_healthSnapshot['target'] < 1 then AQ.GS.HM_playersCalling['target'] = true return true end", -- Evaluated and stored as an adjustedHp (Inside HealthMonitor_UpdateHealthSnapshot()), therefore, it is < 1.0 and > 1.0. If any changes are made to the requirements e.g. "I only want to monitor those below 80% hp", then the adjusted hp can be evaluated as ((curr))/0.8
				"if AQ.GS.HM_playersCalling['target'] ~= false and (not AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_BG) or AQ.GS.HM_healthSnapshot['target'] >= 1) then AQ.GS.HM_playersCalling['target'] = false return true end"
			},
			{
				"return AQ.GS.HM_delaySnapshot['target']",
				AQ.SOUND_FUNC_PREFIX.."return (AQ.HealthMonitor_Dispellable('target') and '"..AQ.SOUNDS_ROOT.."Numerical/3"..AQ.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/3.ogg')",
				nil,
				AQ.PROMPTSEG_CONDITIONAL_REPEATER
			} 
		}
	},
	["GROUP_ROSTER_UPDATE"] = {
		{
			{
				"if AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_BG) then AQ.HealthMonitor_UpdateHealthSnapshot() else AQ.HealthMonitor_CheckMode('GROUP_ROSTER_UPDATE') end return false",
				false
			},
			{nil, nil, nil, nil}
		},
		{
			{
				"if AQ.GS.HM_informingPlayerRaidN == true and AQ.GS.HM_lastPlayerRaidNSpoken ~= AQ.GS.HM_playerRaidN and not AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_PVP) then AQ.GS.HM_lastPlayerRaidNSpoken = AQ.GS.HM_playerRaidN return true end return false",
				"return AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_PVP) or not UnitIsUnit('player', 'raid'..AQ.GS.HM_playerRaidN)"
			},
			{
				0.75,
				AQ.SOUND_FUNC_PREFIX.."return string.format('Interface/AddOns/AudioQs/Sounds/Numerical/%s.ogg', AQ.GS.HM_playerRaidN)", 
				nil,
				true
			},
			{
				0.85,
				AQ.SOUND_PATH_PREFIX.."Interface/AddOns/AudioQs/Sounds/Numerical/your_number_is.ogg", 
				nil, 
				AQ.PROMPTSEG_CONDITIONAL_CONTINUATION
			},
			{
				nil,
				AQ.SOUND_FUNC_PREFIX.."AQ.GS.HM_informingPlayerRaidN = false return string.format('Interface/AddOns/AudioQs/Sounds/Numerical/%s.ogg', AQ.GS.HM_playerRaidN)", 
				nil, 
				AQ.PROMPTSEG_CONDITIONAL_CONTINUATION
			}
		}
	},
	["ZONE_CHANGED_NEW_AREA"] = {
		{
			{
				"AQ.HealthMonitor_CheckMode('ZONE_CHANGED_NEW_AREA') return false",
				false
			},
			{nil, nil, nil, nil}
		}
	},
	["PLAYER_ENTERING_WORLD"] = {
		{
			{
				"AQ.HealthMonitor_CheckMode('PLAYER_ENTERING_WORLD') AQ.HealthMonitor_UpdateHealthSnapshot() return false",
				false
			},
			{nil, nil, nil, nil}
		},
		{
			{
				"return AQ.GS.HM_informingPlayerRaidN == true",
				"return not UnitIsUnit('player', 'raid'..AQ.GS.HM_playerRaidN)"
			},
			{
				0.75,
				AQ.SOUND_FUNC_PREFIX.."return 'Interface/AddOns/AudioQs/Sounds/Numerical/'..AQ.GS.HM_playerRaidN..'.ogg'", 
				nil, 
				true
			},
			{
				0.85,
				AQ.SOUND_PATH_PREFIX.."Interface/AddOns/AudioQs/Sounds/Numerical/your_number_is.ogg", 
				nil, 
				AQ.PROMPTSEG_CONDITIONAL_CONTINUATION
			},
			{
				nil,
				AQ.SOUND_FUNC_PREFIX.."AQ.GS.HM_informingPlayerRaidN = false return string.format('Interface/AddOns/AudioQs/Sounds/Numerical/%s.ogg', AQ.GS.HM_playerRaidN)", 
				nil, 
				AQ.PROMPTSEG_CONDITIONAL_CONTINUATION
			}
		}
	},
	["UPDATE_BATTLEFIELD_STATUS"] = {
		{
			{
				"AQ.HealthMonitor_CheckModePvP() return false",
				false
			},
			{nil, nil, nil, nil}
		}
	},
	["UNIT_MODEL_CHANGED"] = {
		{
			{
				"AQ.HealthMonitor_UpdateHealthSnapshot() return true",
				false
			},
			{0.2, nil, nil, true},
			{"AQ.HealthMonitor_UpdateHealthSnapshot() return nil", nil, nil, AQ.PROMPTSEG_CONDITIONAL_CONTINUATION}
		}
	},
	["UNIT_MAXHEALTH"] = {
		{
			{
				"AQ.HealthMonitor_UpdateHealthSnapshot() return false",
				false
			},
			{nil, nil, nil, nil}
		}
	},
	["PLAYER_DEAD"] = {
		{
			{
				"AQ.HealthMonitor_UpdateHealthSnapshot() return false",
				false
			},
			{nil, nil, nil, nil}
		}
	},
}
if not AQ.WOW_CLASSIC then
	AQ.AmmendTable(
			extSegments, 
			{
				["PLAYER_SPECIALIZATION_CHANGED"] = {
					{
						{
							"AQ.HealthMonitor_CheckMode('PLAYER_SPECIALIZATION_CHANGED') return false",
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
	if extSpecLimit == AQ.ANY_SPEC_ALLOWED or extSpecLimit == specId then
		return true
	end
end
--
-- /Funcs --

-- Register Extension:
AQ.RegisterExtension(extName, extFuncs)

-- --- Set these >> (At will -- For detailed custom code)
local function SetGenericHpVals(unitId, setToOff)
	if unitId == nil then return end
	if UnitExists(unitId) and --[[UnitIsPlayer(unitId) and]] not UnitIsDeadOrGhost(unitId) and not setToOff then
		local adjustedHp = ((UnitHealth(unitId)/UnitHealthMax(unitId))-0.1)/0.80
		AQ.GS.HM_healthSnapshot[unitId] = adjustedHp
		AQ.GS.HM_delaySnapshot[unitId] = (0.4 + 2.0*math.max(0, adjustedHp)^1.6)
	else
		AQ.GS.HM_healthSnapshot[unitId] = 1.0
		AQ.GS.HM_delaySnapshot[unitId] = 0xFFFF -- 18 hours
	end
end

function AQ.HealthMonitor_Dispellable(unitId)
	local aura
	if thisSpecDispels then
		for j=1, 40, 1 do
			aura = AQ.LoadAura(unitId, j, "HARMFUL")
			if aura[AQ.UNIT_AURA_SPELL_ID] == nil then break end 
			
			local debuffType = aura[AQ.UNIT_AURA_DEBUFF_TYPE]
			
			for n=1,#thisSpecDispels,1 do
				if debuffType == thisSpecDispels[n] then
					return true
				end
			end
		end
	end
	return false
end

function AQ.HealthMonitor_ModeIs(modeToCheck)
	if AQ.GS.HM_mode == nil or modeToCheck == nil then -- Avoid nil arithmetic
		if modeToCheck == nil and AQ.GS.HM_mode == nil then
			return true
		else
			return false
		end
	elseif modeToCheck % AQ.GS.INSTANCE_PVMAG == 0 then 	-- Check PvMode
		return mFloor(AQ.GS.HM_mode / AQ.GS.INSTANCE_PVMAG) == mFloor(modeToCheck / AQ.GS.INSTANCE_PVMAG)
	else										-- Check Instance Type
		return AQ.GS.HM_mode == modeToCheck
	end
end

-------- AQ.HealthMonitor_AnyModesTrue()
function AQ.HealthMonitor_AnyModesTrue(...)
	-- Sillyness below is to avoid table creation.
	modesToCheck[1], modesToCheck[2], modesToCheck[3], modesToCheck[4], modesToCheck[5], modesToCheck[6], modesToCheck[7], modesToCheck[8], modesToCheck[9] = ..., select(2, ...), select(3, ...), select(4, ...), select(5, ...), select(6, ...), select(7, ...), select(8, ...), select(9, ...)

	local i = 1
	local mode = modesToCheck[i]
	while mode ~= nil do
		if AQ.HealthMonitor_ModeIs(mode) then
			return true
		end
		i = i+1
		mode = modesToCheck[i]
	end
	return false
end

function AQ.HealthMonitor_UpdateHealthSnapshot()
	local numInGroup = GetNumGroupMembers()

	if AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_BG) then
		for n=1,3,1 do
			local thisUnit = (n == 3 and "target" or (n == 2 and "focus" or (n == 1 and "player")))
			if UnitIsDeadOrGhost("player") or 
			(thisUnit == "target" and (UnitIsUnit(thisUnit, "player") or UnitIsUnit(thisUnit, "focus"))) 
			or (thisUnit == "focus" and UnitIsUnit(thisUnit, "player")) 
			or UnitIsEnemy("player", thisUnit) then
				SetGenericHpVals(thisUnit, true) -- Set to off. If some rules are true about multiple targets: 1st rule: player is only ever '1', which overrides 2nd rule: Focus is only ever '2'
			else
				SetGenericHpVals(thisUnit)
			end
		end
	elseif AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_PARTY) or AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_ARENA) then
		for n=1,5,1 do -- TODO Iterate over partyUnitIds[n]
			local thisUnit = AQ.GS.HM_unitIds[n]
			SetGenericHpVals(thisUnit)
		end
	elseif AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_RAID) then
		AQ.HealthMonitor_CheckLowestForRaid()
	end
end

function AQ.HealthMonitor_SetPreviousCallout(unitNum, timestamp)
	AQ.GS.HM_previousCallout[unitNum] = timestamp
end

function AQ.HealthMonitor_CheckMode(event)
	local instanceName, instanceType = GetInstanceInfo()
	
	if AQ.GS.HM_initialized ~= true then
		AQ.GS.HM_ALERT_UNIT_NUM = 1
		AQ.GS.HM_ALERT_HP_PERCENTAGE = 2
		AQ.GS.HM_ALERT_MAX_ALERTS = 3
		AQ.GS.HM_ASSIGNED_NUMBER_SENTENCE_PART_1 = 1
		AQ.GS.HM_ASSIGNED_NUMBER_SENTENCE_PART_2 = 2
		AQ.GS.HM_ASSIGNED_NUMBER_SENTENCE_PART_3 = 3
		AQ.GS.HM_ASSIGNED_NUMBER_SENTENCE_LENGTH_1 = 0.75
		AQ.GS.HM_ASSIGNED_NUMBER_SENTENCE_LENGTH_2 = 0.85
		
		AQ.GS.HM_playersCalling = {}
		AQ.GS.HM_healthSnapshot = {}
		AQ.GS.HM_delaySnapshot = {}
		
		-- Raid only (Doesn't hurt having 4 empty tables for party, vs a "raidInitialized" variable checked every group_roster_update)
		AQ.GS.HM_unitIds = {} 
		AQ.GS.HM_raidUnitsIncluded = {}
		AQ.GS.HM_previousCallout = {}
		AQ.GS.HM_alertPriority = {}
		
		AQ.GS.HM_mode = nil
		AQ.GS.HM_instanceType = nil
		
		thisSpecDispels = SPEC_DISPEL_TYPES[AQ.GetSpec()]
		
		for n=1,AQ.GS.HM_ALERT_MAX_ALERTS,1 do
			table.insert(AQ.GS.HM_alertPriority, {nil, 100, 0xFFFF})
		end
		
		AQ.GS.HM_initialized = true
	end
	
	if event == "PLAYER_SPECIALIZATION_CHANGED" then 
		thisSpecDispels = SPEC_DISPEL_TYPES[AQ.GetSpec()]
	end
    
    if (instanceType == "pvp" or instanceType == "arena") then 
		if not AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_PVP) then
			if AQ.GS.HM_mode ~= nil then 
				print(AQ.audioQsSpecifier..AQ.extensionColour.."<HealthMonitor>".."|r: "..(AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_PARTY) and "Party" or "Raid").." health call-out stopped.")
			end
			AQ.HealthMonitor_CheckModePvP()
		end
    elseif AQ.GS.HM_instanceType ~= instanceType or event == "GROUP_ROSTER_UPDATE" or (IsInRaid() and AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_PARTY) or (not IsInRaid() and AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_RAID))) then
        AQ.GS.HM_instanceType = instanceType
        
        AQ.GS.HM_numInGroup = (GetNumGroupMembers() > 0 and GetNumGroupMembers() or 1)
        
        if IsInRaid() then 		-- Raid mode (PvE)
			local j = 1
            for n = 1, 40, 1 do
                local thisId = string.format("raid%s", n)
				AQ.GS.HM_unitIds[n] = thisId
                if UnitExists(thisId) then 
                    AQ.GS.HM_raidUnitsIncluded[j] = thisId
					j = j + 1
                end
				AQ.GS.HM_previousCallout[n] = 0
				if UnitIsUnit("player", thisId) and AQ.GS.HM_playerRaidN ~= n and event == "GROUP_ROSTER_UPDATE" then
					AQ.GS.HM_informingPlayerRaidN = true
					AQ.GS.HM_playerRaidN = n
				end
            end
			
			for n=1,GetNumGroupMembers(),1 do
				local thisId = "raid"..n
				AQ.GS.HM_healthSnapshot[thisId] = 1.0
				AQ.GS.HM_delaySnapshot[thisId] = nil
			end
            
            if not AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_RAID) then   
                if AQ.GS.HM_mode ~= nil then 
                    print(AQ.audioQsSpecifier..AQ.extensionColour.."<HealthMonitor>"..
						"|r: Switched to Raid health call-out.")
                else
                    print(AQ.audioQsSpecifier..AQ.extensionColour.."<HealthMonitor>"..
						"|r: Raid health call-out started.")
                end
                
                AQ.GS.HM_mode = AQ.GS.INSTANCE_RAID
            end
        elseif not IsInRaid() and not AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_PARTY) then   -- Party and World Mode (PvE)   
            AQ.GS.HM_unitIds = {"player", "party1", "party2", "party3", "party4"}
			
			AQ.GS.HM_playersCalling["player"] = false
			AQ.GS.HM_healthSnapshot["player"] = 1.0
			AQ.GS.HM_delaySnapshot["player"] = 0xFFFF
			for n = #AQ.GS.HM_unitIds - 1, 1, -1 do
				thisId = string.format("party%s", n)
				AQ.GS.HM_playersCalling[thisId] = false
				AQ.GS.HM_healthSnapshot[thisId] = 1.0
				AQ.GS.HM_delaySnapshot[thisId] = 0xFFFF
			end
			
            if AQ.GS.HM_mode ~= nil then
                print(AQ.audioQsSpecifier..AQ.extensionColour.."<HealthMonitor>".."|r: Switched to Party health call-out.")
            else
                print(AQ.audioQsSpecifier..AQ.extensionColour.."<HealthMonitor>".."|r: Party health call-out started.")
            end
            
            AQ.GS.HM_mode = AQ.GS.INSTANCE_PARTY
        end
        
		AQ.HealthMonitor_UpdateHealthSnapshot()
		
        return
    end
end

function AQ.HealthMonitor_CheckLowestForRaid() -- Raid mode
	AQ.GS.HM_settingAlertsPriorityFlag = true
	for n=1,AQ.GS.HM_ALERT_MAX_ALERTS,1 do -- TODO Read Lua scope / Garbage collection tute. May not need this.
		local thisAlertPriority = AQ.GS.HM_alertPriority[n]
		thisAlertPriority[1] = nil
		thisAlertPriority[2] = 100
		thisAlertPriority[3] = 0xFFFF
		thisAlertPriority[4] = AQ.NO_FILE_MODIFIER
	end
	
	for i = 1, 40, 1 do
		local unitId = AQ.GS.HM_unitIds[i]
		
		if not UnitIsDeadOrGhost(unitId) and 
				AQ.GS.HM_raidUnitsIncluded[i] and
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
				
				while n <= AQ.GS.HM_ALERT_MAX_ALERTS do
					if inserted == true then
						local nextNum = AQ.GS.HM_alertPriority[n][1]
						local nextHp = AQ.GS.HM_alertPriority[n][2]
						local nextDelay = AQ.GS.HM_alertPriority[n][3]
						
						AQ.GS.HM_alertPriority[n][1] = prevNum
						AQ.GS.HM_alertPriority[n][2] = prevHp
						AQ.GS.HM_alertPriority[n][3] = prevDelay
						
						prevNum = nextNum
						prevHp = nextHp
						prevDelay = nextDelay
					elseif adjustedHp < 
					AQ.GS.HM_alertPriority[n][2] then
						prevNum = AQ.GS.HM_alertPriority[n][1]
						prevHp = AQ.GS.HM_alertPriority[n][2]
						prevDelay = AQ.GS.HM_alertPriority[n][3]

						AQ.GS.HM_alertPriority[n][1] = i
						AQ.GS.HM_alertPriority[n][2] = adjustedHp
						AQ.GS.HM_alertPriority[n][3] = 3.0 / (1 + math.exp(-4*(math.pow(adjustedHp, 2)-0.4)))
						
						inserted = true
					end
					n = n + 1
				end
			end
		end
	end
	for n=1, AQ.GS.HM_ALERT_MAX_ALERTS, 1 do
		local unitId = AQ.GS.HM_unitIds[AQ.GS.HM_alertPriority[n][1]]
		if unitId ~= nil and AQ.HealthMonitor_Dispellable(unitId) then
			AQ.GS.HM_alertPriority[n][4] = AQ.DISPEL_FILE_MODIFIER
		end
	end
	AQ.GS.HM_settingAlertsPriorityFlag = false
end

function AQ.HealthMonitor_CheckModePvP()
	local instanceName, instanceType, _, _, _, _, _, instanceId = GetInstanceInfo()
	
if AQ.VERBOSE then print(AQ.audioQsSpecifier..AQ.debugSpecifier.."Checking PvP Mode. name =", instanceName, "; instanceType =", instanceType, "; winner =", GetBattlefieldWinner(), ";") end
    
    if AQ.GS.HM_instanceCompletedOrNotBg == true then
        if AQ.GS.HM_instanceId == instanceId then
            return
        else
			AQ.GS.HM_instanceId = instanceId
			AQ.GS.HM_instanceCompletedOrNotBg = false
        end
    end
    
    if AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_PVP) and
    (GetBattlefieldWinner() ~= nil or not (instanceType == "pvp" or instanceType == "arena")) then
		AQ.GS.HM_instanceCompletedOrNotBg = true
		AQ.GS.HM_instanceId = instanceId
		AQ.GS.HM_mode = nil
        return
    elseif (instanceType == "pvp" or instanceType == "arena") and not AQ.HealthMonitor_ModeIs(AQ.GS.INSTANCE_PVP) then
		AQ.GS.HM_instanceType = instanceType
		AQ.GS.HM_instanceId = instanceId
        
        AQ.GS.HM_mode = (instanceType == "pvp" and AQ.GS.INSTANCE_BG or AQ.GS.INSTANCE_ARENA)
		
		AQ.HealthMonitor_UpdateHealthSnapshot()
		
        print(AQ.audioQsSpecifier..AQ.extensionColour.."<HealthMonitor>".."|r: "..(instanceType == "pvp" and "Battleground" or "Arena").." health call-out started.")
    end
end
-- -- << Set those 
