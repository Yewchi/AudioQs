-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local extName = "HolyPaladin"
local extNameDetailed = "Holy Paladin"
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
		[642] = 	{ "Divine Shield", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[853] = 	{ "Hammer of Justice", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
--		[20473] = 	{ "Holy Shock", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
--		[275773] = 	{ "Judgment", 					0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[114158] = 	{ "Light's Hammer", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[4987] = 	{ "Cleanse", 					0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[190784] = 	{ "Divine Steed", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[498] = 	{ "Divine Protection", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[1044] = 	{ "Blessing of Freedom", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[85222] = 	{ "Light of Dawn", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[1022] = 	{ "Blessing of Protection", 	0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[633] = 	{ "Lay on Hands", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[223306] = 	{ "Bestow Faith", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[214202] = 	{ "Rule of Law", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[20066] = 	{ "Repentance", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[115750] = 	{ "Blinding Light", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[114165] = 	{ "Holy Prism", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[105809] = 	{ "Holy Avenger", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[216331] = 	{ "Avenging Crusader", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[200025] = 	{ "Beacon of Virtue", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[199454] = 	{ "Blessed Hands", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[31821] =	{ "Aura Mastery",				0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[31884] =	{ "Avenging Wrath",				0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY}
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
local extEvents = {
	["LOADING_SCREEN_ENABLED"] = {},
	["LOADING_SCREEN_DISABLED"] = {},
	["PLAYER_SPECIALIZATION_CHANGED"] = {}
}

local extSegments = {
	[642] = {
		{
			{
				"return AUDIOQS.spells[642][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[642][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/divine_shield.ogg",		nil,	true }
		}
	},
	[853] = {
		{
			{
				"return AUDIOQS.spells[853][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[853][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/hammer_of_justice.ogg",		nil,	true }
		}
	},
--[[[20473] = { -- Holy Shock
		{
			{
				"return AUDIOQS.spells[20473][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[20473][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/holy_shock.ogg",		nil,	true }
		}
	},]]--
--[[[275773] = { -- Judgment
		{
			{
				"return AUDIOQS.spells[275773][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[275773][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/judgment.ogg",		nil,	true }
		}
	},]]--
	[114158] = {
		{
			{
				"return AUDIOQS.spells[114158][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[114158][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/lights_hammer.ogg",		nil,	true }
		}
	},
	[4987] = {
		{
			{
				"return AUDIOQS.spells[4987][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[4987][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/cleanse.ogg",		nil,	true }
		}
	},
	[190784] = {
		{
			{
				"return AUDIOQS.spells[190784][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[190784][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/divine_steed.ogg",		nil,	true }
		}
	},
	[498] = {
		{
			{
				"return AUDIOQS.spells[498][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[498][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/divine_protection.ogg",		nil,	true }
		}
	},
	[1044] = {
		{
			{
				"if AUDIOQS.ChargeCooldownsAllowed ~= nil and AUDIOQS.ChargeCooldownsAllowed then local charges = GetSpellCharges(1044) return (AUDIOQS.spells[1044][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[1044][AUDIOQS.SPELL_EXPIRATION] > 0) or (charges ~= nil and charges > AUDIOQS.spellsSnapshot[1044][AUDIOQS.SPELL_CHARGES]) end return false",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/blessing_of_freedom.ogg",		nil,	true }
		}
	},
	[85222] = {
		{
			{
				"return AUDIOQS.spells[85222][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[85222][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/light_of_dawn.ogg",		nil,	true }
		}
	},
	[1022] = {
		{
			{
				"if AUDIOQS.ChargeCooldownsAllowed ~= nil and AUDIOQS.ChargeCooldownsAllowed then local charges = GetSpellCharges(1022) return (AUDIOQS.spells[1022][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[1022][AUDIOQS.SPELL_EXPIRATION] > 0) or (charges ~= nil and charges > AUDIOQS.spellsSnapshot[1022][AUDIOQS.SPELL_CHARGES]) end return false",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/blessing_of_protection.ogg",		nil,	true }
		}
	},
	[633] = {
		{
			{
				"return AUDIOQS.spells[633][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[633][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/lay_on_hands.ogg",		nil,	true }
		}
	},
	[223306] = {
		{
			{
				"return AUDIOQS.spells[223306][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[223306][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/bestow_faith.ogg",		nil,	true }
		}
	},
	[214202] = {
		{
			{
				"return AUDIOQS.spells[214202][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[214202][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/rule_of_law.ogg",		nil,	true }
		}
	},
	[20066] = {
		{
			{
				"return AUDIOQS.spells[20066][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[20066][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/repentance.ogg",		nil,	true }
		}
	},
	[115750] = {
		{
			{
				"return AUDIOQS.spells[115750][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[115750][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/blinding_light.ogg",		nil,	true }
		}
	},
	[114165] = {
		{
			{
				"return AUDIOQS.spells[114165][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[114165][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/holy_prism.ogg",		nil,	true }
		}
	},
	[105809] = {
		{
			{
				"return AUDIOQS.spells[105809][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[105809][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/holy_avenger.ogg",		nil,	true }
		}
	},
	[216331] = {
		{
			{
				"return AUDIOQS.spells[216331][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[216331][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/avenging_crusader.ogg",		nil,	true }
		}
	},
	[200025] = {
		{
			{
				"return AUDIOQS.spells[200025][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[200025][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/beacon_of_virtue.ogg",		nil,	true }
		}
	},
	[199454] = {
		{
			{
				"return AUDIOQS.spells[199454][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[199454][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/blessed_hands.ogg",		nil,	true }
		}
	},
	[31821] = {
		{
			{
				"return AUDIOQS.spells[31821][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[31821][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/aura_mastery.ogg",		nil,	true }
		}
	},
	[31884] = {
		{
			{
				"return AUDIOQS.spells[31884][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[31884][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/avenging_wrath.ogg",		nil,	true }
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