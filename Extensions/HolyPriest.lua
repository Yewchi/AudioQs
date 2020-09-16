-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local extName = "HolyPriest"
local extNameDetailed = "Holy Priest"
local extShortNames = "hp"
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
		[200183] = 	{ "Apotheosis", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[204883] = 	{ "Circle of Healing", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[64843] = 	{ "Divine Hymn", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[110744] = 	{ "Divine Star", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[586] = 	{ "Fade", 						0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[47788] = 	{ "Guardian Spirit", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[213602] = 	{ "Greater Fade", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[120517] = 	{ "Halo", 						0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[213610] = 	{ "Holy Ward", 					0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[88625] = 	{ "Holy Word: Chastise", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[289657] = 	{ "Holy Word: Concentration", 	0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[265202] = 	{ "Holy Word: Salvation",		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[34861] = 	{ "Holy Word: Sanctify",		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[2050] = 	{ "Holy Word: Serenity", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[32375] = 	{ "Mass Dispel", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[73325] = 	{ "Leap of Faith", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[32375] = 	{ "Mass Dispel", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[33076] = 	{ "Prayer Of Mending", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[8122] = 	{ "Psychic Scream", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[527] = 	{ "Purify", 					0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[197268] = 	{ "Ray of Hope", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
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
	[200183] = {
		{
			{
				"return AUDIOQS.spells[200183][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[200183][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/apotheosis.ogg",		nil,	true }
		}
	},
	[204883] = {
		{
			{
				"return AUDIOQS.spells[204883][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[204883][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/circle_of_healing.ogg",		nil,	true }
		}
	},
	[64843] = {
		{
			{
				"return AUDIOQS.spells[64843][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[64843][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/divine_hymn.ogg",		nil,	true }
		}
	},
	[110744] = {
		{
			{
				"return AUDIOQS.spells[110744][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[110744][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/divine_star.ogg",		nil,	true }
		}
	},
	[586] = {
		{
			{
				"return AUDIOQS.spells[586][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[586][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/fade.ogg",		nil,	true }
		}
	},
	[47788] = {
		{
			{
				"return AUDIOQS.spells[47788][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[47788][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/guardian_spirit.ogg",		nil,	true }
		}
	},
	[213602] = {
		{
			{
				"return AUDIOQS.spells[213602][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[213602][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/greater_fade.ogg",		nil,	true }
		}
	},
	[120517] = {
		{
			{
				"return AUDIOQS.spells[120517][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[120517][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/halo.ogg",		nil,	true }
		}
	},
	[213610] = {
		{
			{
				"return AUDIOQS.spells[213610][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[213610][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/holy_ward.ogg",		nil,	true }
		}
	},
	[88625] = {
		{
			{
				"return AUDIOQS.spells[88625][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[88625][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/chastise.ogg",		nil,	true }
		}
	},
	[289657] = {
		{
			{
				"return AUDIOQS.spells[289657][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[289657][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/concentration.ogg",		nil,	true }
		}
	},
	[265202] = {
		{
			{
				"return AUDIOQS.spells[265202][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[265202][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/salvation.ogg",		nil,	true }
		}
	},
	[34861] = {
		{
			{
				"return AUDIOQS.spells[34861][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[34861][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/sanctify.ogg",		nil,	true }
		}
	},
	[2050] = {
		{
			{
				"return AUDIOQS.spells[2050][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[2050][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/serenity.ogg",		nil,	true }
		}
	},
	[73325] = {
		{
			{
				"return AUDIOQS.spells[73325][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[73325][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/leap_of_faith.ogg",		nil,	true }
		}
	},
	[32375] = {
		{
			{
				"return AUDIOQS.spells[32375][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[32375][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/mass_dispel.ogg",		nil,	true }
		}
	},
	[33076] = {
		{
			{
				"return AUDIOQS.spells[33076][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[33076][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/prayer_of_mending.ogg",		nil,	true }
		}
	},
	[8122] = {
		{
			{
				"return AUDIOQS.spells[8122][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[8122][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/psychic_scream.ogg",		nil,	true }
		}
	},
	[527] = {
		{
			{
				"return AUDIOQS.spells[527][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[527][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/purify.ogg",		nil,	true }
		}
	},
	[197268] = {
		{
			{
				"return AUDIOQS.spells[197268][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[197268][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/ray_of_hope.ogg",		nil,	true }
		}
	},
	[204263] = {
		{
			{
				"return AUDIOQS.spells[204263][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[204263][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/shining_force.ogg",		nil,	true }
		}
	},
	[64901] = {
		{
			{
				"return AUDIOQS.spells[64901][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[64901][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/symbol_of_hope.ogg",		nil,	true }
		}
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