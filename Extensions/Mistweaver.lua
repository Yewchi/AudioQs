-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local AUDIOQS = AUDIOQS_4Q5

local extName = "Mistweaver"
local extNameDetailed = "Mistweaver"
local extShortNames = "mw"
local extSpecLimit = AUDIOQS.ANY_SPEC_ALLOWED -- TODO ExtensionsInterface needs update here
local ext_ref_num

local extSpells, extEvents, extSegments

extFuncs = { -- For external use
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
		[115098] = 	{ "Chi Wave", 						0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[123986] = 	{ "Chi Burst", 						0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[122278] = 	{ "Dampen Harm", 					0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[115310] = 	{ "Revival", 						0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
--		[115450] = 	{ "Detox", 							0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[191837] = 	{ "Essence Font", 					0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[243435] = 	{ "Fortifying Brew", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[233759] = 	{ "Grapple Weapon", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[205234] = 	{ "Healing Sphere", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[122281] = 	{ "Healing Elixir", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[119381] = 	{ "Leg Sweep", 						0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[116849] = 	{ "Life Cocoon", 					0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[197908] = 	{ "Mana Tea",	 					0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[115078] = 	{ "Paralysis", 						0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
--		[115151] = 	{ "Renewing Mist", 					0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[116844] = 	{ "Ring of Peace", 					0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[198898] = 	{ "Song of Chi-Ji", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[116841] = 	{ "Tiger's Lust", 					0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[116680] = 	{ "Thunder Focus Tea", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[119996] = 	{ "Transcendence: Transfer", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
		[198664] = 	{ "Invoke Chi-Ji, the Red Crane",	0,	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY}, -- TODO Invoke Xuen, at least, shares a CD with Red-Crane, and it is detected in WindWlkr.
		[209584] = 	{ "Zen Focus Tea", 					0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
extEvents = {
	["LOADING_SCREEN_ENABLED"] = {},
	["LOADING_SCREEN_DISABLED"] = {},
	["PLAYER_SPECIALIZATION_CHANGED"] = {}
}

extSegments = {
	[115098] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/chi_wave.ogg")
	},
	[123986] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/chi_burst.ogg")
	},
	[122278] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/dampen_harm.ogg")
	},
	[115310] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/revival.ogg")
	},
--	[115450] = { 	AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/detox.ogg") }, -- Detox
	[191837] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/essence_font.ogg")
	},
	[243435] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/fortifying_brew.ogg")
	},
	[205234] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_CHARGES_COOLDOWN_SEGMENT("Cooldowns/Monk/healing_sphere.ogg")
	},
	[119381] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/leg_sweep.ogg")
	},
	[116849] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/life_cocoon.ogg")
	},
	[115078] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/paralysis.ogg")
	},
--	[115151] = {	AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/renewing_mist.ogg") },
	[115310] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/revival.ogg")
	},
	[116844] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/ring_of_peace.ogg")
	},
	[116680] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/focus_tea.ogg")
	},
	[198898] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/song_of_chi_ji.ogg")
	},
	[116841] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/tigers_lust.ogg")
	},
	[119996] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/transcendence.ogg")
	},
	[198664] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/red_crane.ogg")
	},
	[233759] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/grapple_weapon.ogg")
	},
	[197908] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/mana_tea.ogg")
	},
	[122281] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_CHARGES_COOLDOWN_SEGMENT("Cooldowns/Monk/healing_elixir.ogg")
	},
	[209584] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Monk/zen_focus_tea.ogg")
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
