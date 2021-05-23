-- Mage extensions contributed by <J.A.>

-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local extName = "FireMage"
local extNameDetailed = "Fire Mage"
local extShortNames = "fire"
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
		[235313] =	{ "Blazing Barrier",		0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[1953] = 	{ "Blink",					0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[190319] =	{ "Combustion",				0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[2139] = 	{ "Counterspell",			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[31661] = 	{ "Dragon's Breath",		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[108853] =	{ "Fire Blast",				0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[45438] =	{ "Ice Block",				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[122] =		{ "Frost Nova",				0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[66] = 		{ "Invisibility",			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[153561] = 	{ "Meteor",					0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[55342] = 	{ "Mirror Image",			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[257541] = 	{ "Phoenix Flames",			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[475] = 	{ "Remove Curse",			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[113724] = 	{ "Ring of Frost",			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[116011] = 	{ "Rune of Power",			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[212653] = 	{ "Shimmer",				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[80353] = 	{ "Time Warp",				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY}
}

local extEvents = {
	["LOADING_SCREEN_ENABLED"] = {},
	["LOADING_SCREEN_DISABLED"] = {},
	["PLAYER_SPECIALIZATION_CHANGED"] = {}
}

local extSegments = {
	[235313] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/blazing_barrier.ogg")
	},
	[1953] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/blink.ogg")
	},
	[2139] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/counterspell.ogg")
	},
	[190319] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/combustion.ogg")
	},
	[31661] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/dragons_breath.ogg")
	},
	[108853] = {
		{
			{
				AUDIOQS.SEGLIB_GENERIC_SPELL_CHARGES_COOLDOWN,
				false
			},
			{0.1,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."blast_primer.ogg",		nil,	true},
			{0.06,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."blast_charge2.ogg",	nil,	"return GetSpellCharges(108853) >= 2"},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."blast_charge3.ogg",	nil,	"return GetSpellCharges(108853) == 3"}
		},
	},
	[45438] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/ice_block.ogg")
	},
	[122] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_CHARGES_COOLDOWN_SEGMENT("Cooldowns/Mage/frost_nova.ogg")
	},
	[66] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/invisibility.ogg")
	},
	[153561] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/meteor.ogg")
	},
	[55342] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/mirror_image.ogg")
	},
	[257541] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/phoenix_flames.ogg")
	},
	[475] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/remove_curse.ogg")
	},
	[113724] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/ring_of_frost.ogg")
	},
	[116011] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/rune_of_power.ogg")
	},
	[212653] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_CHARGES_COOLDOWN_SEGMENT("Cooldowns/Mage/shimmer.ogg")
	},
	--[31687] = {	AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/summon_water_elemental.ogg")},
	[80353] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/time_warp.ogg")
	},
	["LOADING_SCREEN_DISABLED"] = { -- TODO Should be in an "essentials", hidden extension or in the AudioQs.lua main event handlers. Workaround for now.
		{
			{
				"AUDIOQS.ChargeCooldownsAllowed = false return true",
				false
			},
			{0.25, 	nil, nil, true},
			{nil,	nil, nil, "AUDIOQS.ChargeCooldownsAllowed = true return true"}
		}
	},
	["LOADING_SCREEN_ENABLED"] = { -- TODO Likewise ^^
		{
			{
				"AUDIOQS.ChargeCooldownsAllowed = false return false",
				false
			},
			{}
		}
	},
	["PLAYER_SPECIALIZATION_CHANGED"] = {
		{
			{
				"AUDIOQS.ChargeCooldownsAllowed = false return false",
				false
			},
			{0.25, 	nil, nil, true},
			{nil,	nil, nil, "AUDIOQS.ChargeCooldownsAllowed = true return true"}
		}
	}
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