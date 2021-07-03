-- Mage extensions contributed by <J.A.>

-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local AUDIOQS = AUDIOQS_4Q5

local extName = "FrostMage"
local extNameDetailed = "Frost Mage"
local extShortNames = "im"
local extSpecLimit = AUDIOQS.ANY_SPEC_ALLOWED -- TODO ExtensionsInterface needs update here
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
local extSpells = { 
		[235313] =	{ "Blazing Barrier",		0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[1953] = 	{ "Blink",					0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[190319] =	{ "Combustion",				0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[235219] =	{ "Cold Snap",				0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[153595] =	{ "Comet Storm",			0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[120] =		{ "Cone of Cold",			0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[2139] = 	{ "Counterspell",			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[214634] =	{ "Ebonbolt",				0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[108853] =	{ "Fire Blast",				0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[33395] =	{ "Freeze",					0,	0,	0,	"pet",		AUDIOQS.SPELL_TYPE_ABILITY},
		[122] = 	{ "Frost Nova",				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[84714] =	{ "Frost Orb",				0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[198094] =	{ "Ice Barrier",			0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[45438] =	{ "Ice Block",				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[108839] =	{ "Ice Floes",				0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[198144] =	{ "Ice Form",				0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[157997] =	{ "Ice Nova",				0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[12472] =	{ "Icy Veins",				0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[66] = 		{ "Invisibility",			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[55342] = 	{ "Mirror Image",			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[475] = 	{ "Remove Curse",			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[205021] =	{ "Ray of Frost",			0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[113724] = 	{ "Ring of Frost",			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[116011] = 	{ "Rune of Power",			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[212653] = 	{ "Shimmer",				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		--[31687] =	{ "Summon Water Elemental",	0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
		[80353] = 	{ "Time Warp",				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
}

local extEvents = {
	["LOADING_SCREEN_ENABLED"] = {},
	["LOADING_SCREEN_DISABLED"] = {},
	["PLAYER_SPECIALIZATION_CHANGED"] = {}
}

local GetSpellCharges=GetSpellCharges
local extSegments = {
	[65792] = {
		{
			{
				AUDIOQS.SEGLIB_GENERIC_SPELL_CHARGES_COOLDOWN,
				false
			},
			{0.25, 		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."frost_primer.ogg",				nil,		true },
			{nil, 		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."fost_charge_1.ogg", 			nil,		function() return GetSpellCharges(65792) == 1 end},
			{nil, 		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."frost_charge_2.ogg",			nil,		function() return GetSpellCharges(65792) == 2 end},
			{nil, 		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."frost_charge_3.ogg",			nil,		function() return GetSpellCharges(65792) == 3 end}
		}
	},
	[212653] = {
		{
			{
				AUDIOQS.SEGLIB_GENERIC_SPELL_CHARGES_COOLDOWN,
				false
			},
			{0.25, 		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."shimmer_primer.ogg",			nil,		true },
			{nil, 		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."shimmer_charge_1.ogg", 		nil,		function() return GetSpellCharges(212653) == 1 end},
			{nil, 		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."shimmer_charge_2.ogg",			nil,		function() return GetSpellCharges(212653) == 2 end}
		}
	},
	[108978] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/alter_time.ogg")
	},
	[1953] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/blink.ogg")
	},
	[190356] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/blizzard.ogg")
	},
	[235219] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/cold_snap.ogg")
	},
	[153595] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/comet_storm.ogg")
	},
	[120] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/cone_of_cold.ogg")
	},
	[37470] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/counterspell.ogg")
	},
	[214634] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/ebonbolt.ogg")
	},
	[33395] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/freeze.ogg")
	},
	[84714] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/frozen_orb.ogg")
	},
	[198094] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/ice_barrier.ogg")
	},
	[45438] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/ice_block.ogg")
	},	
	[108839] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/ice_floes.ogg")
	},
	[198144] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/ice_form.ogg")
	},
	[157997] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/ice_nova.ogg")
	},
	[12472] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/icy_veins.ogg")
	},
	[66] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/invisibility.ogg")
	},
	[55342] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/mirror_image.ogg")
	},
	[205021] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/ray_of_frost.ogg")
	},
	[113724] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/ring_of_frost.ogg")
	},
	[116011] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/rune_of_power.ogg")
	},
	--[31687] = {	AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/summon_water_elemental.ogg")},
	[80353] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Mage/time_warp.ogg")
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