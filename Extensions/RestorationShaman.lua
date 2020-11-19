-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local extName = "RestorationShaman"
local extNameDetailed = "Restoration Shaman"
local extShortNames = "rs"
local extSpecLimit = AUDIOQS.ANY_SPEC_ALLOWED

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
		[114052] = 	{ "Ascendance", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[108271] = 	{ "Astral Shift", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[192058] = 	{ "Capacitor Totem", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[204331] = 	{ "Counterstrike Totem", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[198103] = 	{ "Earth Elemental", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[2484] = 	{ "Earthbind Totem", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[198838] = 	{ "Earthen Wall Totem", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[51485] = 	{ "Earthgrab Totem", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[73920] = 	{ "Healing Rain", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[5394] = 	{ "Healing Stream Totem",		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY}, -- ALSO TRACKS CLOUDBURST TOTEM
		[108280] = 	{ "Healing Tide Totem", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[51514] = 	{ "Hex", 						0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[16191] =	{ "Mana Tide Totem",			0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
--		[77130] = 	{ "Purify Spirit", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
--		[61295] = 	{ "Riptide",					0,	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[320746] =	{ "Surge of Earth",				0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[98008] = 	{ "Spirit Link Totem", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[79206] = 	{ "Spiritwalker's Grace", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[8143] = 	{ "Tremor Totem", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[73685] = 	{ "Unleash Life", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[57994] = 	{ "Wind Shear", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[207399] = 	{ "Ancestral Protection Totem", 0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[192077] = 	{ "Wind Rush Totem", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[207778] = 	{ "Downpour", 					0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[197995] = 	{ "Wellspring", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[204336] = 	{ "Grounding Totem", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY}
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
				"return AUDIOQS.spells[114052][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[114052][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/ascendance.ogg",		nil,	true }
		}
	},
	[108271] = {
		{
			{
				"return AUDIOQS.spells[108271][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[108271][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/astral_shift.ogg",		nil,	true }
		}
	},
	[192058] = {
		{
			{
				"return AUDIOQS.spells[192058][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[192058][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/capacitor_totem.ogg",		nil,	true }
		}
	},
	[204331] = {
		{
			{
				"return AUDIOQS.spells[204331][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[204331][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/counterstrike_totem.ogg",		nil,	true }
		}
	},
	[198103] = {
		{
			{
				"return AUDIOQS.spells[198103][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[198103][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/earth_elemental.ogg",		nil,	true }
		}
	},
	[2484] = {
		{
			{
				"return AUDIOQS.spells[2484][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[2484][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/earthbind_totem.ogg",		nil,	true }
		}
	},
	[198838] = {
		{
			{
				"return AUDIOQS.spells[198838][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[198838][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/earthen_wall_totem.ogg",		nil,	true }
		}
	},
	[51485] = {
		{
			{
				"return AUDIOQS.spells[51485][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[51485][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/earthgrab_totem.ogg",		nil,	true }
		}
	},
	[73920] = {
		{
			{
				"return AUDIOQS.spells[73920][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[73920][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/healing_rain.ogg",		nil,	true }
		}
	},
	[5394] = {
		{
			{
				"if AUDIOQS.ChargeCooldownsAllowed ~= nil and AUDIOQS.ChargeCooldownsAllowed then local charges = GetSpellCharges(5394) return (AUDIOQS.spells[5394][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[5394][AUDIOQS.SPELL_EXPIRATION] > 0) or (charges ~= nil and charges > AUDIOQS.spellsSnapshot[5394][AUDIOQS.SPELL_CHARGES]) end return false",
				false
			},
			{nil,		AUDIOQS.SOUND_FUNC_PREFIX.."if select(4, GetTalentInfo(6, 3, 1)) then return '"..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/cloudburst_totem.ogg' end return '"..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/healing_stream_totem.ogg'",		nil,	true }
		}
	},
	[108280] = {
		{
			{
				"return AUDIOQS.spells[108280][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[108280][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/healing_tide_totem.ogg",		nil,	true }
		}
	},
	[51514] = {
		{
			{
				"return AUDIOQS.spells[51514][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[51514][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/hex.ogg",		nil,	true }
		}
	},
	[16191] = {
		{
			{
				"return AUDIOQS.spells[16191][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[16191][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/mana_tide_totem.ogg",		nil,	true }
		}
	},
--[[[77130] = { -- Purify Spirit
		{
			{
				"return AUDIOQS.spells[77130][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[77130][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/purify_spirit.ogg",		nil,	true }
		}
	}, ]]--
--[[[61295] = {
		{
			{
				"return AUDIOQS.spells[61295][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[61295][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/riptide.ogg",		nil,	true }
		}
	}, ]]--
	[320746] = {
		{
			{
				"return AUDIOQS.spells[320746][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[320746][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/surge_of_earth.ogg",		nil,	true }
		}
	},
	[98008] = {
		{
			{
				"return AUDIOQS.spells[98008][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[98008][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/spirit_link_totem.ogg",		nil,	true }
		}
	},
	[79206] = {
		{
			{
				"return AUDIOQS.spells[79206][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[79206][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/spiritwalkers_grace.ogg",		nil,	true }
		}
	},
	[8143] = {
		{
			{
				"return AUDIOQS.spells[8143][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[8143][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/tremor_totem.ogg",		nil,	true }
		}
	},
	[73685] = {
		{
			{
				"return AUDIOQS.spells[73685][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[73685][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/unleash_life.ogg",		nil,	true }
		}
	},
	[57994] = {
		{
			{
				"return AUDIOQS.spells[57994][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[57994][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/wind_shear.ogg",		nil,	true }
		}
	},
--[[[974] = { -- Earth Shield Drop (Unfinished) TODO Requires tracking of GUID of player with earthshield on them. UNIT_AURA checking if the ES has dropped from that player.
		{
			{
				"return AUDIOQS.spells[974][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[974][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/earth_shield_drop.ogg",		nil,	true }
		}
	},]]--
	[207399] = {
		{
			{
				"return AUDIOQS.spells[207399][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[207399][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/ancestral_protection_totem.ogg",		nil,	true }
		}
	},
	[192077] = {
		{
			{
				"return AUDIOQS.spells[192077][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[192077][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/wind_rush_totem.ogg",		nil,	true }
		}
	},
	[207778] = {
		{
			{
				"return AUDIOQS.spells[207778][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[207778][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/downpour.ogg",		nil,	true }
		}
	},
	[197995] = {
		{
			{
				"return AUDIOQS.spells[197995][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[197995][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/wellspring.ogg",		nil,	true }
		}
	},
	[204336] = {
		{
			{
				"return AUDIOQS.spells[204336][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[204336][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/grounding_totem.ogg",		nil,	true }
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