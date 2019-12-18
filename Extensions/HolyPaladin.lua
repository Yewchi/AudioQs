-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local extName = "HolyPaladin"
local extNameDetailed = "Holy Paladin"
local extShortNames = "hp"
local extSpecLimit = AQ.ANY_SPEC_ALLOWED -- TODO ExtensionsInterface needs update here

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
		[642] = 	{ "Divine Shield", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[853] = 	{ "Hammer of Justice", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
--		[20473] = 	{ "Holy Shock", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
--		[275773] = 	{ "Judgment", 					0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[114158] = 	{ "Light's Hammer", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[4987] = 	{ "Cleanse", 					0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[190784] = 	{ "Divine Steed", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[498] = 	{ "Divine Protection", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[1044] = 	{ "Blessing of Freedom", 		0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[85222] = 	{ "Light of Dawn", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[1022] = 	{ "Blessing of Protection", 	0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[633] = 	{ "Lay on Hands", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[223306] = 	{ "Bestow Faith", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[214202] = 	{ "Rule of Law", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[20066] = 	{ "Repentance", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[115750] = 	{ "Blinding Light", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[114165] = 	{ "Holy Prism", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[105809] = 	{ "Holy Avenger", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[216331] = 	{ "Avenging Crusader", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[200025] = 	{ "Beacon of Virtue", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[199454] = 	{ "Blessed Hands", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[31821] =	{ "Aura Mastery",				0,	0,	0,	"player",	AQ.SPELL_TYPE_ABILITY},
		[31884] =	{ "Avenging Wrath",				0,	0,	0,	"player",	AQ.SPELL_TYPE_ABILITY}
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
				"return AQ.spells[642][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[642][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/divine_shield.ogg",		nil,	true }
		}
	},
	[853] = {
		{
			{
				"return AQ.spells[853][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[853][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/hammer_of_justice.ogg",		nil,	true }
		}
	},
--[[[20473] = { -- Holy Shock
		{
			{
				"return AQ.spells[20473][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[20473][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/holy_shock.ogg",		nil,	true }
		}
	},]]--
--[[[275773] = { -- Judgment
		{
			{
				"return AQ.spells[275773][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[275773][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/judgment.ogg",		nil,	true }
		}
	},]]--
	[114158] = {
		{
			{
				"return AQ.spells[114158][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[114158][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/lights_hammer.ogg",		nil,	true }
		}
	},
	[4987] = {
		{
			{
				"return AQ.spells[4987][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[4987][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/cleanse.ogg",		nil,	true }
		}
	},
	[190784] = {
		{
			{
				"return AQ.spells[190784][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[190784][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/divine_steed.ogg",		nil,	true }
		}
	},
	[498] = {
		{
			{
				"return AQ.spells[498][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[498][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/divine_protection.ogg",		nil,	true }
		}
	},
	[1044] = {
		{
			{
				"if AQ.ChargeCooldownsAllowed ~= nil and AQ.ChargeCooldownsAllowed then local charges = GetSpellCharges(1044) return (AQ.spells[1044][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[1044][AQ.SPELL_EXPIRATION] > 0) or (charges ~= nil and charges > AQ.spellsSnapshot[1044][AQ.SPELL_CHARGES]) end return false",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/blessing_of_freedom.ogg",		nil,	true }
		}
	},
	[85222] = {
		{
			{
				"return AQ.spells[85222][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[85222][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/light_of_dawn.ogg",		nil,	true }
		}
	},
	[1022] = {
		{
			{
				"if AQ.ChargeCooldownsAllowed ~= nil and AQ.ChargeCooldownsAllowed then local charges = GetSpellCharges(1022) return (AQ.spells[1022][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[1022][AQ.SPELL_EXPIRATION] > 0) or (charges ~= nil and charges > AQ.spellsSnapshot[1022][AQ.SPELL_CHARGES]) end return false",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/blessing_of_protection.ogg",		nil,	true }
		}
	},
	[633] = {
		{
			{
				"return AQ.spells[633][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[633][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/lay_on_hands.ogg",		nil,	true }
		}
	},
	[223306] = {
		{
			{
				"return AQ.spells[223306][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[223306][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/bestow_faith.ogg",		nil,	true }
		}
	},
	[214202] = {
		{
			{
				"return AQ.spells[214202][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[214202][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/rule_of_law.ogg",		nil,	true }
		}
	},
	[20066] = {
		{
			{
				"return AQ.spells[20066][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[20066][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/repentance.ogg",		nil,	true }
		}
	},
	[115750] = {
		{
			{
				"return AQ.spells[115750][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[115750][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/blinding_light.ogg",		nil,	true }
		}
	},
	[114165] = {
		{
			{
				"return AQ.spells[114165][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[114165][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/holy_prism.ogg",		nil,	true }
		}
	},
	[105809] = {
		{
			{
				"return AQ.spells[105809][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[105809][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/holy_avenger.ogg",		nil,	true }
		}
	},
	[216331] = {
		{
			{
				"return AQ.spells[216331][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[216331][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/avenging_crusader.ogg",		nil,	true }
		}
	},
	[200025] = {
		{
			{
				"return AQ.spells[200025][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[200025][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/beacon_of_virtue.ogg",		nil,	true }
		}
	},
	[199454] = {
		{
			{
				"return AQ.spells[199454][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[199454][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/blessed_hands.ogg",		nil,	true }
		}
	},
	[31821] = {
		{
			{
				"return AQ.spells[31821][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[31821][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/aura_mastery.ogg",		nil,	true }
		}
	},
	[31884] = {
		{
			{
				"return AQ.spells[31884][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[31884][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/avenging_wrath.ogg",		nil,	true }
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
	["PLAYER_SPECIALIZATION_CHANGED"] = {
		{
			{
				"AQ.ChargeCooldownsAllowed = false return false",
				false
			},
			{0.25, 	nil, nil, true},
			{nil,	nil, nil, "AQ.ChargeCooldownsAllowed = true return true"}
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
	if extSpecLimit == AQ.ANY_SPEC_ALLOWED or extSpecLimit == specId then
		return true
	end
	return false
end
--
-- /Funcs --

-- Register Extension:
AQ.RegisterExtension(extName, extFuncs)