--#ifdef WOW_CLASSIC
if AQ.WOW_CLASSIC then
-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local extName = "ClassicDruid"
local extNameDetailed = "ClassicDruid"
local extShortNames = "clcdruid"
local extSpecLimit = 11 -- TODO ExtensionsInterface needs update here

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
	[740] = { 	"Tranquility", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
	[20484] = { "Rebirth", 					0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY}
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
local extEvents = {
	["LOADING_SCREEN_ENABLED"] = {},
	["LOADING_SCREEN_DISABLED"] = {},
}

local extSegments = {
	[740] = {
		{
			{
				"return AQ.spells[740][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[740][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/tranquility.ogg",		nil,	true }
		}
	},
	[20484] = {
		{
			{
				"return AQ.spells[20484][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[20484][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/rebirth.ogg",		nil,	true }
		}
	},
	["LOADING_SCREEN_DISABLED"] = { -- TODO Should be in an "essentials", hidden extension or in the AudioQs.lua main event handlers. Workaround for now.
		{
			{
				"AQ.ChargeCooldownsAllowed = false return true",
				false
			},
			{0.25, 	nil, nil, true},
			{nil,	nil, nil, "AQ.ChargeCooldownsAllowed = true return true"}
		}
	},
	["LOADING_SCREEN_ENABLED"] = { -- TODO Likewise ^^
		{
			{
				"AQ.ChargeCooldownsAllowed = false return false",
				false
			},
			{}
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
	if extSpecLimit == AQ.ANY_SPEC_ALLOWED or extSpecLimit == specId then
		return true
	end
	return false
end
--
-- /Funcs --

-- Register Extension:
AQ.RegisterExtension(extName, extFuncs)
end
--#endif