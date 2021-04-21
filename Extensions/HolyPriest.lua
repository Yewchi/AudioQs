-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local extName = "HolyPriest"
local extNameDetailed = "Holy Priest"
local extShortNames = "hpriest"
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
		[121536] = 	{ "Angelic Feather", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[200183] = 	{ "Apotheosis", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[204883] = 	{ "Circle of Healing", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[19236] = 	{ "Desperate Prayer", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[64843] = 	{ "Divine Hymn", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[110744] = 	{ "Divine Star", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[586] = 	{ "Fade", 						0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[213602] = 	{ "Greater Fade", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[289666] = 	{ "Greater Heal", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[47788] = 	{ "Guardian Spirit", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[120517] = 	{ "Halo", 						0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[213610] = 	{ "Holy Ward", 					0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[88625] = 	{ "Holy Word: Chastise", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[289657] = 	{ "Holy Word: Concentration", 	0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[265202] = 	{ "Holy Word: Salvation",		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[34861] = 	{ "Holy Word: Sanctify",		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[2050] = 	{ "Holy Word: Serenity", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[73325] = 	{ "Leap of Faith", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[32375] = 	{ "Mass Dispel", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[32375] = 	{ "Mass Dispel", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[10060] = 	{ "Power Infusion", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[33076] = 	{ "Prayer Of Mending", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[8122] = 	{ "Psychic Scream", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[527] = 	{ "Purify", 					0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[197268] = 	{ "Ray of Hope", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[32379] = 	{ "Shadow Word: Death", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[204263] = 	{ "Shining Force", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[64901] = 	{ "Symbol of Hope", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
local extEvents = {
	["LOADING_SCREEN_ENABLED"] = {},
	["LOADING_SCREEN_DISABLED"] = {},
	["PLAYER_SPECIALIZATION_CHANGED"] = {}
}

local extSegments = {
	[121536] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/angelic_feather.ogg")
	},
	[200183] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/apotheosis.ogg")
	},
	[204883] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/circle_of_healing.ogg")
	},
	[19236] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/desperate_prayer.ogg")
	},
	[64843] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/divine_hymn.ogg")
	},
	[110744] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/divine_star.ogg")
	},
	[586] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/fade.ogg")
	},
	[213602] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/greater_fade.ogg")
	},
	[289666] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/greater_heal.ogg")
	},
	[47788] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/guardian_spirit.ogg")
	},
	[120517] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/halo.ogg")
	},
	[213610] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/holy_ward.ogg")
	},
	[88625] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/chastise.ogg")
	},
	[289657] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/concentration.ogg")
	},
	[265202] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/salvation.ogg")
	},
	[34861] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/sanctify.ogg")
	},
	[2050] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/serenity.ogg")
	},
	[73325] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/leap_of_faith.ogg")
	},
	[32375] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/mass_dispel.ogg")
	},
	[10060] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/power_infusion.ogg")
	},
	[33076] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/prayer_of_mending.ogg")
	},
	[8122] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/psychic_scream.ogg")
	},
	[527] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/purify.ogg")
	},
	[197268] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/ray_of_hope.ogg")
	},
	[32379] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/shadow_word_death.ogg")
	},
	[204263] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/shining_force.ogg")
	},
	[64901] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Priest/symbol_of_hope.ogg")
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