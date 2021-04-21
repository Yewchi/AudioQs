-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local extName = "RestorationDruid"
local extNameDetailed = "Restoration Druid"
local extShortNames = "rd|restodruid"
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
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/barkskin.ogg")
	},
	[102351] = 	{
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/cenarion_ward.ogg")
	},
	[33786] = 	{
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/cyclone.ogg")
	},
	[1850] = 	{
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/dash.ogg")
	},
	[319454] = 	{
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/heart_of_the_wild.ogg")
	},
	[29166] = 	{
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/innervate.ogg")
	},
	[102342] = 	{
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/ironbark.ogg")
	},
	[102359] = 	{
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/mass_entanglement.ogg")
	},
	[5211] = 	{
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/mighty_bash.ogg")
	},
	[203651] = 	{
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/overgrowth.ogg")
	},
	[20484] = 	{
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/rebirth.ogg")
	},
	[108238] = 	{
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/renewal.ogg")
	},
	[2908] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/soothe.ogg")
	},
	[77764] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/stampeding_roar.ogg")
	},
	[18562] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/swiftmend.ogg")
	},
	[305497] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/thorns.ogg")
	},
	[740] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/tranquility.ogg")
	},	
	[33891] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/tree_of_life.ogg")
	},
	[132469] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/typhoon.ogg")
	},
	[102793] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/ursols_vortex.ogg")
	},
	[102401] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/wild_charge.ogg")
	},
	[48438] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Druid/wild_growth.ogg")
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