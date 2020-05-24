-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local extName = "ManaMonitor"
local extNameDetailed = "Mana Monitor"
local extShortNames = "mana"
local extSpecLimit = AQ.ANY_SPEC_ALLOWED

-- Extension Variables --
--
AQ.GS.POWER_TYPE_MANA = 0
 -- Six second prevention of repeated prompts 
 -- TODO nb. drinking mage food restores 10% mana every 2 seconds .'. drinking from below 10% and up will prompt "10", but not "20". Fix is checking for eating buff every UNIT_POWER_UPDATE... >8(
AQ.GS.MANA_MONITOR_MIN_DELAY = 6.0
AQ.GS.MANA_MONITOR_ANNOUNCING_SEG = nil
AQ.GS.MANA_MONITOR_PREV_PROMPT_TIMESTAMP = 0

 -- Default 50-100%. Expressed as a integer %age for easy comparisons when determining if e.g. mana is decreasing to 20-49 (call 50), or increasing to 20-49 (call 20) .'. avoid using flags for this.
local currentManaSegment = 50
local previousSegmentCallout = 0
--
-- /Extension Variables

-- Functions predeclared
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
		["Initialize"] = function() AQ.ManaMonitor_UpdateManaSegment() end
}

--- Spell Tables and Prompts --
--
local extSpells = { 
}

local extEvents = {
	["UNIT_POWER_UPDATE"] = {
	},
}

local allowPrompts -- for simplicity within func strings
local extSegments = {
	["UNIT_POWER_UPDATE"] = { 
		{
			{
				"allowPrompts, AQ.GS.MANA_MONITOR_ANNOUNCING_SEG = AQ.ManaMonitor_UpdateManaSegment() if allowPrompts and AQ.GS.MANA_MONITOR_ANNOUNCING_SEG then AQ.GS.MANA_MONITOR_PREV_PROMPT_TIMESTAMP = GetTime() return true end",
				false
			},
			{
				0.0,
				AQ.SOUND_FUNC_PREFIX.."local seg = AQ.GS.MANA_MONITOR_ANNOUNCING_SEG if seg ~= nil then return string.format('%smana_%s.ogg', AQ.SOUNDS_ROOT, AQ.GS.MANA_MONITOR_ANNOUNCING_SEG) end",
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
	local promptAllowed = GetTime() > (AQ.GS.MANA_MONITOR_PREV_PROMPT_TIMESTAMP + (sameAsPrevious and AQ.GS.MANA_MONITOR_MIN_DELAY or 0))
	
	previousSegmentCallout = desiredSegmentCallout
	
	return promptAllowed, desiredSegmentCallout
end

------ Returns a flag if a prompt is intended.
-------- AQ.ManaMonitor_UpdateManaSegment()
function AQ.ManaMonitor_UpdateManaSegment()
	local playerMana = UnitPower("player", AQ.GS.POWER_TYPE_MANA) / UnitPowerMax("player", AQ.GS.POWER_TYPE_MANA) * 100
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
	if extSpecLimit == AQ.ANY_SPEC_ALLOWED or extSpecLimit == specId then
		return true
	end
	return false
end
--
-- /Funcs --

-- Register Extension:
AQ.RegisterExtension(extName, extFuncs)
