-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local extName = "Mistweaver"
local extNameDetailed = "Mistweaver"
local extShortNames = "mw"
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
		[122278] = 	{ "Dampen Harm", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[115310] = 	{ "Revival", 					0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
--		[115450] = 	{ "Detox", 						0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[191837] = 	{ "Essence Font", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[243435] = 	{ "Fortifying Brew", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[119381] = 	{ "Leg Sweep", 					0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[116849] = 	{ "Life Cocoon", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[115078] = 	{ "Paralysis", 					0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
--		[115151] = 	{ "Renewing Mist", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[115310] = 	{ "Revival",		 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[116844] = 	{ "Ring of Peace", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[116680] = 	{ "Thunder Focus Tea", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[119996] = 	{ "Transcendence: Transfer", 		0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[198664] = 	{ "Invoke Chi-Ji, the Red Crane",	0,	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[233759] = 	{ "Grapple Weapon", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[197908] = 	{ "Mana Tea",	 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
		[122281] = 	{ "Healing Elixir", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY}
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
local extEvents = {
	["LOADING_SCREEN_ENABLED"] = {},
	["LOADING_SCREEN_DISABLED"] = {}
}

local extSegments = {
	[122278] = {
		{
			{
				"return AQ.spells[122278][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[122278][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/dampen_harm.ogg",		nil,	true }
		}
	},
	[115310] = {
		{
			{
				"return AQ.spells[115310][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[115310][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/revival.ogg",		nil,	true }
		}
	},
--[[[115450] = { -- Detox
		{
			{
				"return AQ.spells[115450][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[115450][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/detox.ogg",		nil,	true }
		}
	},]]--
	[191837] = {
		{
			{
				"return AQ.spells[191837][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[191837][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/essence_font.ogg",		nil,	true }
		}
	},
	[243435] = {
		{
			{
				"return AQ.spells[243435][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[243435][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/fortifying_brew.ogg",		nil,	true }
		}
	},
	[119381] = {
		{
			{
				"return AQ.spells[119381][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[119381][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/leg_sweep.ogg",		nil,	true }
		}
	},
	[116849] = {
		{
			{
				"return AQ.spells[116849][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[116849][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/life_cocoon.ogg",		nil,	true }
		}
	},
	[115078] = {
		{
			{
				"return AQ.spells[115078][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[115078][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/paralysis.ogg",		nil,	true }
		}
	},
--[[[115151] = { -- Renewing Mist
		{
			{
				"return AQ.spells[115151][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[115151][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/renewing_mist.ogg",		nil,	true }
		}
	},]]--
	[115310] = {
		{
			{
				"return AQ.spells[115310][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[115310][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/revival.ogg",		nil,	true }
		}
	},
	[116844] = {
		{
			{
				"return AQ.spells[116844][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[116844][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/ring_of_peace.ogg",		nil,	true }
		}
	},
	[116680] = {
		{
			{
				"return AQ.spells[116680][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[116680][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/focus_tea.ogg",		nil,	true }
		}
	},
	[119996] = { -- Transcendence: Transfer
		{
			{
				"return AQ.spells[119996][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[119996][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/transcendence.ogg",		nil,	true }
		}
	},
	[198664] = {
		{
			{
				"return AQ.spells[198664][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[198664][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/red_crane.ogg",		nil,	true }
		}
	},
	[233759] = {
		{
			{
				"return AQ.spells[233759][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[233759][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/grapple_weapon.ogg",		nil,	true }
		}
	},
	[197908] = {
		{
			{
				"return AQ.spells[197908][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[197908][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/mana_tea.ogg",		nil,	true }
		}
	},
	[122281] = {
		{
			{
				"if AQ.ChargeCooldownsAllowed ~= nil and AQ.ChargeCooldownsAllowed then local charges = GetSpellCharges(122281) return (AQ.spells[122281][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[122281][AQ.SPELL_EXPIRATION] > 0) or (charges ~= nil and charges > AQ.spellsSnapshot[122281][AQ.SPELL_CHARGES]) end return false",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/healing_elixir.ogg",		nil,	true }
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
