-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local extName = "RestorationShaman"
local extNameDetailed = "Restoration Shaman"
local extShortNames = "rs"
local extSpecLimit = AQ.ANY_SPEC_ALLOWED

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
		[114052] = 	{ "Ascendance", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[108271] = 	{ "Astral Shift", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[192058] = 	{ "Capacitor Totem", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[204331] = 	{ "Counterstrike Totem", 		0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[198103] = 	{ "Earth Elemental", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[2484] = 	{ "Earthbind Totem", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[198838] = 	{ "Earthen Wall Totem", 		0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[51485] = 	{ "Earthgrab Totem", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[73920] = 	{ "Healing Rain", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[5394] = 	{ "Healing Stream Totem",		0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY}, -- ALSO TRACKS CLOUDBURST TOTEM
		[108280] = 	{ "Healing Tide Totem", 		0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[51514] = 	{ "Hex", 						0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
--		[77130] = 	{ "Purify Spirit", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
--		[61295] = 	{ "Riptide",					0,	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[98008] = 	{ "Spirit Link Totem", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[79206] = 	{ "Spiritwalker's Grace", 		0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[8143] = 	{ "Tremor Totem", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[73685] = 	{ "Unleash Life", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[57994] = 	{ "Wind Shear", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[207399] = 	{ "Ancestral Protection Totem", 0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[192077] = 	{ "Wind Rush Totem", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[207778] = 	{ "Downpour", 					0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[197995] = 	{ "Wellspring", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[204336] = 	{ "Grounding Totem", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY}
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
local extEvents = {
	["LOADING_SCREEN_ENABLED"] = {
	},
	["LOADING_SCREEN_DISABLED"] = {
	}
}

local extSegments = {
	[114052] = {
		{
			{
				"return AQ.spells[114052][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[114052][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/ascendance.ogg",		nil,	true }
		}
	},
	[108271] = {
		{
			{
				"return AQ.spells[108271][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[108271][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/astral_shift.ogg",		nil,	true }
		}
	},
	[192058] = {
		{
			{
				"return AQ.spells[192058][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[192058][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/capacitor_totem.ogg",		nil,	true }
		}
	},
	[204331] = {
		{
			{
				"return AQ.spells[204331][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[204331][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/counterstrike_totem.ogg",		nil,	true }
		}
	},
	[198103] = {
		{
			{
				"return AQ.spells[198103][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[198103][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/earth_elemental.ogg",		nil,	true }
		}
	},
	[2484] = {
		{
			{
				"return AQ.spells[2484][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[2484][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/earthbind_totem.ogg",		nil,	true }
		}
	},
	[198838] = {
		{
			{
				"return AQ.spells[198838][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[198838][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/earthen_wall_totem.ogg",		nil,	true }
		}
	},
	[51485] = {
		{
			{
				"return AQ.spells[51485][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[51485][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/earthgrab_totem.ogg",		nil,	true }
		}
	},
	[73920] = {
		{
			{
				"return AQ.spells[73920][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[73920][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/healing_rain.ogg",		nil,	true }
		}
	},
	[5394] = {
		{
			{
				"if AQ.ChargeCooldownsAllowed ~= nil and AQ.ChargeCooldownsAllowed then local charges = GetSpellCharges(5394) return (AQ.spells[5394][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[5394][AQ.SPELL_EXPIRATION] > 0) or (charges ~= nil and charges > AQ.spellsSnapshot[5394][AQ.SPELL_CHARGES]) end return false",
				false
			},
			{nil,		AQ.SOUND_FUNC_PREFIX.."if select(4, GetTalentInfo(6, 3, 1)) then return '"..AQ.SOUNDS_ROOT.."Cooldowns/cloudburst_totem.ogg' end return '"..AQ.SOUNDS_ROOT.."Cooldowns/healing_stream_totem.ogg'",		nil,	true }
		}
	},
	[108280] = {
		{
			{
				"return AQ.spells[108280][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[108280][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/healing_tide_totem.ogg",		nil,	true }
		}
	},
	[51514] = {
		{
			{
				"return AQ.spells[51514][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[51514][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/hex.ogg",		nil,	true }
		}
	},
--[[[77130] = { -- Purify Spirit
		{
			{
				"return AQ.spells[77130][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[77130][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/purify_spirit.ogg",		nil,	true }
		}
	}, ]]--
--[[[61295] = {
		{
			{
				"return AQ.spells[61295][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[61295][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/riptide.ogg",		nil,	true }
		}
	},]]--
	[98008] = {
		{
			{
				"return AQ.spells[98008][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[98008][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/spirit_link_totem.ogg",		nil,	true }
		}
	},
	[79206] = {
		{
			{
				"return AQ.spells[79206][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[79206][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/spiritwalkers_grace.ogg",		nil,	true }
		}
	},
	[8143] = {
		{
			{
				"return AQ.spells[8143][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[8143][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/tremor_totem.ogg",		nil,	true }
		}
	},
	[73685] = {
		{
			{
				"return AQ.spells[73685][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[73685][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/unleash_life.ogg",		nil,	true }
		}
	},
	[57994] = {
		{
			{
				"return AQ.spells[57994][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[57994][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/wind_shear.ogg",		nil,	true }
		}
	},
--[[[974] = { -- Earth Shield Drop (Unfinished) TODO Requires tracking of GUID of player with earthshield on them. UNIT_AURA checking if the ES has dropped from that player.
		{
			{
				"return AQ.spells[974][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[974][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/earth_shield_drop.ogg",		nil,	true }
		}
	},]]--
	[207399] = {
		{
			{
				"return AQ.spells[207399][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[207399][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/ancestral_protection_totem.ogg",		nil,	true }
		}
	},
	[192077] = {
		{
			{
				"return AQ.spells[192077][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[192077][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/wind_rush_totem.ogg",		nil,	true }
		}
	},
	[207778] = {
		{
			{
				"return AQ.spells[207778][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[207778][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/downpour.ogg",		nil,	true }
		}
	},
	[197995] = {
		{
			{
				"return AQ.spells[197995][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[197995][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/wellspring.ogg",		nil,	true }
		}
	},
	[204336] = {
		{
			{
				"return AQ.spells[204336][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[204336][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/grounding_totem.ogg",		nil,	true }
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