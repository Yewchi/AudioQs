-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local extName = "RestorationDruid"
local extNameDetailed = "Restoration Druid"
local extShortNames = "rd"
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
-- spells[spellId] = { "Spell Name", charges, cdDur, cdExpiration, unitId, spellType, badSpell}
local extSpells = { 
		[22812] = 	{ "Barkskin", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY}, -- TODO 'Bad spell' needs to be removed, too many spells need the tracking.
		[102351] = 	{ "Cenarion Ward", 		0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[1850] = 	{ "Dash", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[29166] = 	{ "Innervate", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[102342] = 	{ "Ironbark", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[102359] = 	{ "Mass Entanglement",	0,	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[5211] = 	{ "Mighty Bash", 		0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[20484] = 	{ "Rebirth", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[108238] = 	{ "Renewal", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[18562] = 	{ "Swiftmend", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[740] = 	{ "Traquility", 		0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[33891] = 	{ "Tree of Life", 		0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[132469] = 	{ "Typhoon", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[102793] = 	{ "Ursol's Vortex",		0,	0,	0,	"player",	AQ.SPELL_TYPE_ABILITY},
		[102401] = 	{ "Wild Charge", 		0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[48438] = 	{ "Wild Growth", 		0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY}
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
				"return AQ.spells[22812][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[22812][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/barkskin.ogg",		nil,	true }
		}
	},
	[102351] = 	{
		{
			{
				"return AQ.spells[102351][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[102351][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/cenarion_ward.ogg",		nil,	true }
		}
	},
	[1850] = 	{
		{
			{
				"return AQ.spells[1850][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[1850][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/dash.ogg",		nil,	true }
		}
	},
	[29166] = 	{
		{
			{
				"return AQ.spells[29166][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[29166][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/innervate.ogg",		nil,	true }
		}
	},
	[102342] = 	{
		{
			{
				"return AQ.spells[102342][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[102342][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/ironbark.ogg",		nil,	true }
		}
	},
	[102359] = 	{
		{
			{
				"return AQ.spells[102359][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[102359][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/mass_entanglement.ogg",		nil,	true }
		}
	},
	[5211] = 	{
		{
			{
				"return AQ.spells[5211][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[5211][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/mighty_bash.ogg",		nil,	true }
		}
	},
	[20484] = 	{
		{
			{
				"return AQ.spells[20484][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[20484][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/rebirth.ogg",		nil,	true }
		}
	},
	[108238] = 	{
		{
			{
				"return AQ.spells[108238][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[108238][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/renewal.ogg",		nil,	true }
		}
	},
	[18562] = 	{
		{
			{
				"if AQ. ChargeCooldownsAllowed~= nil and AQ.ChargeCooldownsAllowed then local charges = GetSpellCharges(18562) return (AQ.spells[18562][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[18562][AQ.SPELL_EXPIRATION] > 0) or (charges ~= nil and charges > AQ.spellsSnapshot[18562][AQ.SPELL_CHARGES]) end return false",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/swiftmend.ogg",		nil,	true }
		}
	},
	[740] = 	{
		{
			{
				"return AQ.spells[740][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[740][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/tranquility.ogg",		nil,	true }
		}
	},	
	[33891] = 	{
		{
			{
				"return AQ.spells[33891][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[33891][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/tree_of_life.ogg",		nil,	true }
		}
	},
	[132469] = 	{
		{
			{
				"return AQ.spells[132469][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[132469][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/typhoon.ogg",		nil,	true }
		}
	},
	[102793] = 	{
		{
			{
				"return AQ.spells[102793][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[102793][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/ursols_vortex.ogg",		nil,	true }
		}
	},
	[102401] = 	{
		{
			{
				"return AQ.spells[102401][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[102401][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/wild_charge.ogg",		nil,	true }
		}
	},
	[48438] = 	{
		{
			{
				"return AQ.spells[48438][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[48438][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/wild_growth.ogg",		nil,	true }
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