-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local AUDIOQS = AUDIOQS_4Q5

local extName = "RestorationShaman"
local extNameDetailed = "Restoration Shaman"
local extShortNames = "rs|restorationsham|restosham|restoshaman"
local extSpecLimit = AUDIOQS.ANY_SPEC_ALLOWED
local ext_ref_num

local extSpells, extEvents, extSegments

local extFuncs = { -- For external use
		["GetName"] = function() return extName end,
		["GetNameDetailed"] = function() return extNameDetailed end,
		["GetShortNames"] = function() return extShortNames end,
		["GetExtRef"] = function() return ext_ref_num end,
		["GetVersion"] = function() return extVersion end,
		["GetSpells"] = function() return extSpells end,
		["GetEvents"] = function() return extEvents end,
		["GetPrompts"] = function() return extSegments end,
		["GetExtension"] = function() 
				return {spells=extSpells, events=extEvents, segments=extSegments, extNum=ext_ref_num}
			end,
		["SpecAllowed"] = function(specId) 
				if extSpecLimit == AUDIOQS.ANY_SPEC_ALLOWED or extSpecLimit == specId then
					return true
				end 
			end,

		["Initialize"] = function() end
}

--- Spell Tables and Prompts --
--
-- spells[spellId] = { "Spell Name", charges, cdDur, cdExpiration, unitId, spellType}
extSpells = { 
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
extEvents = {
	["LOADING_SCREEN_ENABLED"] = {},
	["LOADING_SCREEN_DISABLED"] = {},
	["PLAYER_SPECIALIZATION_CHANGED"] = {}
}

extSegments = {
	[114052] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/ascendance.ogg")
	},
	[108271] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/astral_shift.ogg")
	},
	[192058] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/capacitor_totem.ogg")
	},
	[204331] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/counterstrike_totem.ogg")
	},
	[198103] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/earth_elemental.ogg")
	},
	[2484] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/earthbind_totem.ogg")
	},
	[198838] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/earthen_wall_totem.ogg")
	},
	[51485] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/earthgrab_totem.ogg")
	},
	[73920] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/healing_rain.ogg")
	},
	[5394] = {
		{
			{
				AUDIOQS.SEGLIB_GENERIC_SPELL_CHARGES_COOLDOWN,
				false
			},
			{nil,		AUDIOQS.SOUND_FUNC_PREFIX.."if select(4, GetTalentInfo(6, 3, 1)) then return '"..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/cloudburst_totem.ogg' end return '"..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Shaman/healing_stream_totem.ogg'",		nil,	true }
		}
	},
	[108280] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/healing_tide_totem.ogg")
	},
	[51514] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/hex.ogg")
	},
	[16191] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/mana_tide_totem.ogg")
	},
--	[77130] = { AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/purify_spirit.ogg") }, -- Purify Spirit
--	[61295] = { AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/riptide.ogg") }, -- Riptide
	[320746] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/surge_of_earth.ogg")
	},
	[98008] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/spirit_link_totem.ogg")
	},
	[79206] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/spiritwalkers_grace.ogg")
	},
	[8143] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/tremor_totem.ogg")
	},
	[73685] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/unleash_life.ogg")
	},
	[57994] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/wind_shear.ogg")
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
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/ancestral_protection_totem.ogg")
	},
	[192077] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/wind_rush_totem.ogg")
	},
	[207778] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/downpour.ogg")
	},
	[197995] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/wellspring.ogg")
	},
	[204336] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/grounding_totem.ogg")
	},
	["LOADING_SCREEN_DISABLED"] = { -- TODO Should be in an "essentials", hidden extension or in the AudioQs.lua main event handlers. Workaround for now.
		{
			{
				function() AUDIOQS.ChargeCooldownsAllowed = false return true end,
				false
			},
			{0.25, 	nil, nil, true},
			{nil,	nil, nil, function() AUDIOQS.ChargeCooldownsAllowed = true return true end}
		}
	},
	["LOADING_SCREEN_ENABLED"] = { -- TODO Likewise ^^
		{
			{
				function() AUDIOQS.ChargeCooldownsAllowed = false return false end,
				false
			},
			{}
		}
	},
	["PLAYER_SPECIALIZATION_CHANGED"] = {
		{
			{
				function() AUDIOQS.ChargeCooldownsAllowed = false return false end,
				false
			},
			{0.25, 	nil, nil, true},
			{nil,	nil, nil, function() AUDIOQS.ChargeCooldownsAllowed = true return true end}
		}
	}
}
--
-- /Spell Tables and Rules

--- Funcs --
--
--
-- /Funcs --

-- Register Extension:
ext_ref_num = AUDIOQS.RegisterExtension(extName, extFuncs)