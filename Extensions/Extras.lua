-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local extName = "Extras"
local extNameDetailed = "Extras"
local extShortNames = "ext"
local extSpecLimit = AUDIOQS.ANY_SPEC_ALLOWED -- TODO ExtensionsInterface needs update here

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
		["Initialize"] = function() end
}

--- Spell Tables and Prompts --
--
-- spells[spellId] = { "Spell Name", charges, cdDur, cdExpiration, unitId, spellType}
local extSpells = { 
		[208683] = 	{ "Gladiator's Medallion", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[152244] = 	{ "Adaptation",					0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY}
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
local extEvents = {
		["UNIT_POWER_UPDATE"] = {
		}
}

local extSegments = {
	[208683] = {
		{
			{
				"return AUDIOQS.spells[208683][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[208683][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/medallion.ogg",		nil,	true }
		}
	},
	[152244] = {
		{
			{
				"return AUDIOQS.spells[152244][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[152244][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/adaptation.ogg",		nil,	true }
		}
	},
}
--
-- /Spell Tables and Rules

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
	return false
end
--
-- /Funcs --

-- Register Extension:
AUDIOQS.RegisterExtension(extName, extFuncs)