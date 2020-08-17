--#ifdef WOW_CLASSIC
if AUDIOQS.WOW_CLASSIC then
-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local extName = "ClassicPriest"
local extNameDetailed = "ClassicPriest"
local extShortNames = "clcpriest"
local extSpecLimit = 5 -- TODO ExtensionsInterface needs update here

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
	[2944] = { 	"Devouring Plague", 0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[586] = { 	"Fade", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[8122] = { 	"Psychic Scream", 	0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[724] = { 	"Lightwell", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[13908] = { "Desperate Prayer", 0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[13896] = { "Feedback", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[2651] = { 	"Elune's Grace", 	0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY}
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
local extEvents = {
	["LOADING_SCREEN_ENABLED"] = {},
	["LOADING_SCREEN_DISABLED"] = {},
}

local extSegments = {
	[2944] = {
		{
			{
				"return AUDIOQS.spells[2944][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[2944][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/devouring_plague.ogg",		nil,	true }
		}
	},
	[586] = {
		{
			{
				"return AUDIOQS.spells[586][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[586][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/fade.ogg",		nil,	true }
		}
	},
	[8122] = {
		{
			{
				"return AUDIOQS.spells[8122][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[8122][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/psychic_scream.ogg",		nil,	true }
		}
	},
	[724] = {
		{
			{
				"return AUDIOQS.spells[724][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[724][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/lightwell.ogg",		nil,	true }
		}
	},
	[13908] = {
		{
			{
				"return AUDIOQS.spells[13908][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[13908][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/desperate_prayer.ogg",		nil,	true }
		}
	},
	[13896] = {
		{
			{
				"return AUDIOQS.spells[13896][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[13896][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/feedback.ogg",		nil,	true }
		}
	},
	[2651] = {
		{
			{
				"return AUDIOQS.spells[2651][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[2651][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/elunes_grace.ogg",		nil,	true }
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
	},
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
end
--#endif
