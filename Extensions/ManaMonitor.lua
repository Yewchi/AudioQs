-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local AUDIOQS = AUDIOQS_4Q5
local GameState = AUDIOQS.GS

local extName = "ManaMonitor"
local extNameDetailed = "Mana Monitor"
local extShortNames = "mana"
local extSpecLimit = AUDIOQS.ANY_SPEC_ALLOWED
local ext_ref_num

-- Extension Variables --
--
AUDIOQS.GS.POWER_TYPE_MANA = 0
 -- Six second prevention of repeated prompts 
 -- TODO nb. drinking mage food restores 10% mana every 2 seconds .'. drinking from below 10% and up will prompt "10", but not "20". Fix is checking for eating buff every UNIT_POWER_UPDATE... >8(
AUDIOQS.GS.MANA_MONITOR_MIN_DELAY = 6.0
AUDIOQS.GS.MANA_MONITOR_ANNOUNCING_SEG = nil
AUDIOQS.GS.MANA_MONITOR_PREV_PROMPT_TIMESTAMP = 0

 -- Default 50-100%. Expressed as a integer %age for easy comparisons when determining if e.g. mana is decreasing to 20-49 (call 50), or increasing to 20-49 (call 20) .'. avoid using flags for this.
local currentManaSegment = 50
local previousSegmentCallout = 0
--
-- /Extension Variables

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
		["Initialize"] = function() AUDIOQS.ManaMonitor_UpdateManaSegment() end
}

--- Spell Tables and Prompts --
--
extSpells = { 
}

extEvents = {
	["UNIT_POWER_UPDATE"] = {
	},
}

local allowPrompts -- for simplicity within func strings
extSegments = {
	["UNIT_POWER_UPDATE"] = { 
		{
			{
				function() allowPrompts, GameState.MANA_MONITOR_ANNOUNCING_SEG = AUDIOQS.ManaMonitor_UpdateManaSegment() if allowPrompts and GameState.MANA_MONITOR_ANNOUNCING_SEG then GameState.MANA_MONITOR_PREV_PROMPT_TIMESTAMP = GetTime() return true end end,
				false
			},
			{
				0.0,
				function() local seg = GameState.MANA_MONITOR_ANNOUNCING_SEG if seg ~= nil then return string.format('%smana_%s.ogg', AUDIOQS.SOUNDS_ROOT, GameState.MANA_MONITOR_ANNOUNCING_SEG) end end,
				nil,
				true
			}
		}
	}
}
--
-- /Spell Tables and Rules

--- Funcs --
--
local function ManaSegmentCalloutInfo(desiredSegmentCallout)
	local sameAsPrevious = (desiredSegmentCallout == previousSegmentCallout)
	local promptAllowed = GetTime() > (AUDIOQS.GS.MANA_MONITOR_PREV_PROMPT_TIMESTAMP + (sameAsPrevious and AUDIOQS.GS.MANA_MONITOR_MIN_DELAY or 0))
	
	previousSegmentCallout = desiredSegmentCallout
	
	return promptAllowed, desiredSegmentCallout
end

------ Returns a flag if a prompt is intended.
-------- AUDIOQS.ManaMonitor_UpdateManaSegment()
function AUDIOQS.ManaMonitor_UpdateManaSegment()
	local playerMana = UnitPower("player", AUDIOQS.GS.POWER_TYPE_MANA) / UnitPowerMax("player", AUDIOQS.GS.POWER_TYPE_MANA) * 100
	local manaDecreasing = playerMana < currentManaSegment
	
	if playerMana > 50 then -- 50 - 100
		if currentManaSegment ~= 100 then 
			currentManaSegment = 100 -- Only here when increasing 49% -> 50%
			if playerMana < 60 then -- "(playerMana < 60.." i.e. Do not call "50" if the player suddenly restores a large portion of mana.
				return ManaSegmentCalloutInfo(50)
			end
		end
	elseif playerMana > 20 then -- 20 - 49
		if currentManaSegment ~= 50 then
			currentManaSegment = 50
			return ManaSegmentCalloutInfo(manaDecreasing and 50 or 20) -- i.e. call 50 if we decreased 50% -> 49%; call 20 if we increased from 19% -> 20%
		end
	elseif playerMana > 10 then -- 10 - 19
		if currentManaSegment ~= 20 then
			currentManaSegment = 20
			return ManaSegmentCalloutInfo(manaDecreasing and 20 or 10)
		end
	else --[[if playerMana > 0 then]] -- 0 - 9
		if currentManaSegment ~= 10 then
			currentManaSegment = 10 -- Only here when decreasing 10 -> 9%
			return ManaSegmentCalloutInfo(10)
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