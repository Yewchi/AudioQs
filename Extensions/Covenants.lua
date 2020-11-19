-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

-------------------------------- TODO -- THIS MAY Y2K UPON RECEIVING COVENENANT?? DONT KNOW LOL ROAD 2 SERVER FIRST 60

local extName = "Covenants"
local extNameDetailed = "Covenants"
local extShortNames = "cov"
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
-- spells[spellId] = { "Spell Name", charges, cdDur, cdExpiration, unitId, spellType}
local extSpells = { 
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
local extEvents = {
	["LOADING_SCREEN_ENABLED"] = {},
	["LOADING_SCREEN_DISABLED"] = {},
	["PLAYER_SPECIALIZATION_CHANGED"] = {}
}

local extSegments = {
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
	["PLAYER_SPECIALIZATION_CHANGED"] = {
		{
			{
				"AUDIOQS.ChargeCooldownsAllowed = false return false",
				false
			},
			{0.25, 	nil, nil, true},
			{nil,	nil, nil, "AUDIOQS.ChargeCooldownsAllowed = true return true"}
		}
	}
}


do -- check chosen covenant. TODO Is this primitive? Rushed the design and just stepping into solution
	--- Data for garbage collection --
	local COVENANT_ABILITY_SPELL_ID = 1
	local COVENANT_ABILITY_SPELL_NAME = 2
	local COVENANT_ABILITY_FILE_NAME = 3 -- TODO Dork over to this behaviour for covenants. Only repeats the question of why spell cd prompt data still isn't mostly auto-generated, with just overrides for special functionality.

	local basicCovenantAbilityInfo = {
		[324739] = { "Summon Steward", 	"summon_steward"}, 
		[300728] = { "Door of Shadows",	"door_of_shadows"},
		[324631] = { "Fleshcraft",		"fleshcraft"},
		[310143] = { "Soulshape",		"soulshape"}
	}

	local basicCovenantAbilityToClassAbilityInfo = {
		[324739] = {
			[2] 	= {	304971, "Divine Toll",				"divine_toll"},
			[3] 	= {	308491, "Resonating Arrow",			"resonating_arrow"},
			[5] 	= {	325013,	"Boon of the Ascended",		"boon_of_the_ascended"},
			[7] 	= {	324386,	"Vesper Totem",				"vesper_totem"},
			[10] 	= {	310454,	"Weapons of Order",			"weapons_of_order"},
			[11] 	= {	326434,	"Kindred Spirits",			"kindred_spirits"},
		},
		[300728] = {
			[2] 	= {	316958,	"Ashen Hallow",				"ashen_hallow"},
			[3] 	= {	324149,	"Flayed Show",				"flayed_shot"},
			[5] 	= { 323673,	"Mindgames",				"mindgames"},
			[7] 	= {	320674,	"Chain Harvest",			"chain_harvest"},
			[10] 	= {	326860,	"Fallen Order",				"fallen_order"},
			[11] 	= {	323546,	"Ravenous Frenzy",			"ravenous_frenzy"},
		},
		[331180] = {
			[2] 	= {	328204,	"Vanquisher's Hammer",		"vanquishers_hammer"},
			[3] 	= {	325028,	"Death Chakram",			"death_chakram"},
			[5] 	= {	324724,	"Unholy Nova",				"unholy_nova"},
			[7] 	= {	326059,	"Primordial Wave",			"primordial_wave"},
			[10] 	= {	325216,	"Bonedust Brew",			"bonebust_brew"},
			[11] 	= {	325727,	"Adaptive Swarm",			"adaptive_swarm"},
		},
		[310143] = {
			[2] 	= {	328278,	"Blessing of the Seasons",	"blessing_of_the_seasons"},
			[3] 	= {	328231,	"Wild Spirits",				"wild_spirits"},
			[5] 	= {	327661,	"Fae Guardians",			"fae_guardians"},
			[7] 	= {	328923,	"Fae Transfusion",			"fae_transfusion"},
			[10] 	= {	327104,	"Faeline Stomp",			"faeline_stomp"},
			[11] 	= {	323764,	"Convoke the Spirits",		"convoke_the_spirits"},
		}
	}
	-- /Data for garbage collection --
	
	local basicCovenantSpellId = ( 
			select(AUDIOQS.SPELL_TYPE_SPELL_ID, IsSpellKnown(324739)) or 
			select(AUDIOQS.SPELL_TYPE_SPELL_ID, IsSpellKnown(300728)) or 
			select(AUDIOQS.SPELL_TYPE_SPELL_ID, IsSpellKnown(324631)) or 
			select(AUDIOQS.SPELL_TYPE_SPELL_ID, IsSpellKnown(310143)) )
	if ( basicCovenantSpellId ) then
		local covenantClassAbilityInfo = basicCovenantAbilityToClassAbility[basicCovenantSpellId][AUDIOQS.GetClassId()]
		local thisCovenantClassSpellId = covenantClassAbilityInfo[COVENANT_ABILITY_SPELL_ID]
		extSpells[ basicCovenantSpellId ] = 
				{basicCovenantAbilityInfo[COVENANT_ABILITY_SPELL_NAME], 0, 0, 0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY}  -- TODO ugly results of avoiding implementing prompt generation
		extSpells[ thisCovenantClassSpellId ] =
				{covenantClassAbilityInfo[COVENANT_ABILITY_SPELL_NAME], 0, 0, 0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY}
		extSegments[ basicCovenantSpellId ] = 
				{
					{
						{
							"return AUDIOQS.spells["..basicCovenantSpellId.."][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot["..basicCovenantSpellId.."][AUDIOQS.SPELL_EXPIRATION] > 0",
							false
						},
						{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Covenants/"..basicCovenantAbilityInfo[COVENANT_ABILITY_FILE_NAME]..".ogg",		nil,	true }
					}
				}
		extSegments[ thisCovenantClassSpellId ] =
				{
					{
						{
							"return AUDIOQS.spells["..thisCovenantClassSpellId.."][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot["..thisCovenantClassSpellId.."][AUDIOQS.SPELL_EXPIRATION] > 0",
							false
						},
						{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Covenants/"..covenantClassAbilityInfo[COVENANT_ABILITY_FILE_NAME]..".ogg",		nil,	true }
					}
				}
	end
end
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