-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local extName = "RestorationDruid"
local extNameDetailed = "Restoration Druid"
local extShortNames = "rd"
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
-- spells[spellId] = { "Spell Name", charges, cdDur, cdExpiration, unitId, spellType, badSpell}
local extSpells = { 
		[22812] = 	{ "Barkskin", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY}, -- TODO 'Bad spell' needs to be removed, too many spells need the tracking.
		[102351] = 	{ "Cenarion Ward", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[33786] = 	{ "Cyclone", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[1850] = 	{ "Dash", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[319454] = 	{ "Heart of the Wild",	0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[29166] = 	{ "Innervate", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[102342] = 	{ "Ironbark", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[102359] = 	{ "Mass Entanglement",	0,	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[5211] = 	{ "Mighty Bash", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[203651] = 	{ "Overgrowth", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[20484] = 	{ "Rebirth", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[108238] = 	{ "Renewal", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[2908] = 	{ "Soothe", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[77764] = 	{ "Stampeding Roar", 	0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[18562] = 	{ "Swiftmend", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[305497] = 	{ "Thorns", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[740] = 	{ "Traquility", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[33891] = 	{ "Tree of Life", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[132469] = 	{ "Typhoon", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[102793] = 	{ "Ursol's Vortex",		0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[102401] = 	{ "Wild Charge", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[48438] = 	{ "Wild Growth", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY}
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
local extEvents = {
	["LOADING_SCREEN_ENABLED"] = {},
	["LOADING_SCREEN_DISABLED"] = {}
}

local extSegments = {
	[22812] = {
		{
			{
				"return AUDIOQS.spells[22812][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[22812][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/barkskin.ogg",		nil,	true }
		}
	},
	[102351] = 	{
		{
			{
				"return AUDIOQS.spells[102351][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[102351][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/cenarion_ward.ogg",		nil,	true }
		}
	},
	[33786] = 	{
		{
			{
				"return AUDIOQS.spells[33786][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[33786][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/cyclone.ogg",		nil,	true }
		}
	},
	[1850] = 	{
		{
			{
				"return AUDIOQS.spells[1850][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[1850][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/dash.ogg",		nil,	true }
		}
	},
	[319454] = 	{
		{
			{
				"return AUDIOQS.spells[319454][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[319454][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/heart_of_the_wild.ogg",		nil,	true }
		}
	},
	[29166] = 	{
		{
			{
				"return AUDIOQS.spells[29166][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[29166][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/innervate.ogg",		nil,	true }
		}
	},
	[102342] = 	{
		{
			{
				"return AUDIOQS.spells[102342][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[102342][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/ironbark.ogg",		nil,	true }
		}
	},
	[102359] = 	{
		{
			{
				"return AUDIOQS.spells[102359][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[102359][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/mass_entanglement.ogg",		nil,	true }
		}
	},
	[5211] = 	{
		{
			{
				"return AUDIOQS.spells[5211][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[5211][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/mighty_bash.ogg",		nil,	true }
		}
	},
	[203651] = 	{
		{
			{
				"return AUDIOQS.spells[203651][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[203651][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/overgrowth.ogg",		nil,	true }
		}
	},
	[20484] = 	{
		{
			{
				"return AUDIOQS.spells[20484][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[20484][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/rebirth.ogg",		nil,	true }
		}
	},
	[108238] = 	{
		{
			{
				"return AUDIOQS.spells[108238][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[108238][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/renewal.ogg",		nil,	true }
		}
	},
	[2908] = {
		{
			{
				"return AUDIOQS.spells[2908][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[2908][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/soothe.ogg",		nil,	true }
		}
	},
	[77764] = {
		{
			{
				"return AUDIOQS.spells[77764][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[77764][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/stampeding_roar.ogg",		nil,	true }
		}
	},
	[18562] = 	{
		{
			{
				"return AUDIOQS.spells[18562][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[18562][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/swiftmend.ogg",		nil,	true }
		}
	},
	[305497] = {
		{
			{
				"return AUDIOQS.spells[305497][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[305497][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/thorns.ogg",		nil,	true }
		}
	},
	[740] = 	{
		{
			{
				"return AUDIOQS.spells[740][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[740][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/tranquility.ogg",		nil,	true }
		}
	},	
	[33891] = 	{
		{
			{
				"return AUDIOQS.spells[33891][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[33891][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/tree_of_life.ogg",		nil,	true }
		}
	},
	[132469] = 	{
		{
			{
				"return AUDIOQS.spells[132469][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[132469][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/typhoon.ogg",		nil,	true }
		}
	},
	[102793] = 	{
		{
			{
				"return AUDIOQS.spells[102793][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[102793][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/ursols_vortex.ogg",		nil,	true }
		}
	},
	[102401] = 	{
		{
			{
				"return AUDIOQS.spells[102401][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[102401][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/wild_charge.ogg",		nil,	true }
		}
	},
	[48438] = 	{
		{
			{
				"return AUDIOQS.spells[48438][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[48438][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Druid/wild_growth.ogg",		nil,	true }
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