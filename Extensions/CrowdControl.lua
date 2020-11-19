-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

---- Extension Flags --
--
local CC_SCHOOL_NATURE = 		0x08
local CC_SCHOOL_FIRE =			0x04
local CC_SCHOOL_FROST =			0x10
local CC_SCHOOL_ARCANE = 		0x40
local CC_SCHOOL_SHADOW = 		0x20
local CC_SCHOOL_HOLY =			0x02

local CC_LOC_FOUND =			0xFF -- i.e. in one run-through of CrowdControl_CheckLocUpdate() we did find this LOC event as stored.
local CC_LOC_PENDING = 			0xFE -- i.e. Delete this LOC if we finish processing all WoW-base LOC events and haven't set to FOUND.
--
--- /Extension Flags --

---- Extension Defs --
--
local CC_SPELLID_FREEZING_TRAP =		3355
local CC_SPELLID_CYCLONE =				209753
local CC_SPELLID_IMPRISON = 			217832
local CC_SPELLID_SHACKLE_UNDEAD = 		9484
local CC_SPELLID_POLYMORPH =			116
local CC_SPELLID_GOUGE =				1776
local CC_SPELLID_SAP =					6770
--
--- /Extension Defs --

---- Extension Variables --
--
local tablesForRecycling = {}
local mostRecentLocCheck 	-- prevents double checking

local schoolTypeToLockoutFilepath = {
	[CC_SCHOOL_HOLY] = 			string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "holy_locked"),
	[CC_SCHOOL_FIRE] = 			string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "fire_locked"),
	[CC_SCHOOL_NATURE] = 		string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "nature_locked"),
	[CC_SCHOOL_FROST] = 		string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "frost_locked"),
	[CC_SCHOOL_SHADOW] = 		string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "shadow_locked"),
	[CC_SCHOOL_ARCANE] = 		string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "arcane_locked"),
}
local locTypeToFilepath = {
	["STUN_MECHANIC"] = 			string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "stunned"),
	["STUN"] = 						string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "stunned"),
	["FEAR_MECHANIC"] = 			string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "feared"),
	["FEAR"] =						string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "feared"),
	["PACIFYSILENCE"] = 			string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "hexed"),
	["SILENCE"] = 					string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "silenced"), 
	["CONFUSE"] = 					string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "disorientated"),
	["POSSESS"] = 					string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "mind_controlled"),
	["CONFUSE"] = 					string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "disoriented"),
	-- Any below this comment are untested / guesswork. Worst that can happen is it doesn't announce.
	["BANISH"] = 					string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "banished"),
	["SLEEP"] = 					string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "slept")
}
local spellIDToFilepath = {
	[CC_SPELLID_FREEZING_TRAP] = 	string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "frost_trapped"),
	[CC_SPELLID_CYCLONE] =			string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "cycloned"),
	[CC_SPELLID_IMPRISON] =			string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "imprisoned"),
	[CC_SPELLID_SHACKLE_UNDEAD] =	string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "shackled"),
	[CC_SPELLID_POLYMORPH] =		string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "polymorphed"),
	[CC_SPELLID_GOUGE] = 			string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "incapacitated"),
	[CC_SPELLID_SAP] =				string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "incapacitated")
}
--
--- /Extension Variables --

local extName = "CrowdControl"
local extNameDetailed = "Crowd Control"
local extShortNames = "cc"
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

local CC_Initialize

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
		["Initialize"] = function() CC_Initialize() end
}

--- Spell Tables and Prompts --
--
-- spells[spellId] = { "Spell Name", charges, cdDur, cdExpiration, unitId, spellType}
local extSpells = { 
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
local extEvents = {
		["LOSS_OF_CONTROL_ADDED"] = {},
		["LOSS_OF_CONTROL_UPDATE"] = {}
}

local extSegments = {
	["LOSS_OF_CONTROL_ADDED"] = {
		{
			{
				"AUDIOQS.CrowdControl_CheckLocUpdate() if table.getn(AUDIOQS.GS.CC_locToBeAnnounced) > 0 then return true end",
				false
			},
			{nil,		AUDIOQS.SOUND_FUNC_PREFIX.."return AUDIOQS.CrowdControl_GetKeyLocFilename(table.remove(AUDIOQS.GS.CC_locToBeAnnounced))",		nil,	true }
		}
	},
	["LOSS_OF_CONTROL_UPDATE"] = {
		{
			{
				"AUDIOQS.CrowdControl_CheckLocUpdate() if table.getn(AUDIOQS.GS.CC_locToBeAnnounced) > 0 then return true end",
				false
			},
			{1.0,		AUDIOQS.SOUND_FUNC_PREFIX.."return AUDIOQS.CrowdControl_GetKeyLocFilename(table.remove(AUDIOQS.GS.CC_locToBeAnnounced))",		nil,	true }
		}
	}
}
--
-- /Spell Tables and Rules

--- Funcs --
--
----- Initialize()
CC_Initialize = function()
	AUDIOQS.GS.CC_activeLoc = {}
	AUDIOQS.GS.CC_locToBeAnnounced = {}
end

-- Redundant in 90000
-------------- CC_DeleteLoc()
local function CC_DeleteLoc(key)
	AUDIOQS.GS.CC_activeLoc[key].activeCheck = nil
	table.insert(tablesForRecycling, AUDIOQS.GS.CC_activeLoc[key])
	AUDIOQS.GS.CC_activeLoc[key] = nil
end

-- Redundant in 90000
-------------- CC_CreateLoc()
local function CC_CreateLoc(locType, spellID, startTime, duration, lockoutSchool)
	local newTable = table.remove(tablesForRecycling) or {}
	
if AUDIOQS.VERBOSE then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."CrowdControl_CreateLoc() using", newTable[1] and "recycled" or "new alloc", "table") end
	
	newTable.locType = locType
	newTable.spellID = spellID
	newTable.startTime = startTime
	newTable.duration = duration
	newTable.lockoutSchool = lockoutSchool
	
	return newTable
end

-------------- CC_GetLossOfControlTable() 
local function CC_GetLossOfControlTable(index)
	if AUDIOQS.WOW_SHADOWLANDS then
		return C_LossOfControl.GetActiveLossOfControlData(index)
	else
		local locType, spellID, _, _, startTime, _, dur, lockoutSchool = C_LossOfControl.GetEventInfo(index) -- "ID" in API
		
		return CC_CreateLoc(locType, spellID, startTime, dur, lockoutSchool)
	end
end

local function CC_GetLossOfControlCount()
	if AUDIOQS.WOW_SHADOWLANDS then
		return C_LossOfControl.GetActiveLossOfControlDataCount()
	else
		return C_LossOfControl.GetNumEvents()
	end
end

-------- AUDIOQS.CrowdControl_CheckLocUpdate()
---- Called on LOSS_OF_CONTROL_UPDATE. Updates stored Loc everytime, indicates if they are fresh to trigger prompting.
function AUDIOQS.CrowdControl_CheckLocUpdate()
	local t = GetTime()
	if t == mostRecentLocCheck then return false else mostRecentLocCheck = t end

	local thisNumLoc = CC_GetLossOfControlCount()
	local thisLocTable
	local i = 1
	-- Soln elegance is hmmmm, but shouldn't have too much overhead. i.e.: usage of str concat of startTime and spellID as key.
	while (i <= thisNumLoc)
	do
		thisLocTable = CC_GetLossOfControlTable(i)
		if thisLocTable.startTime == nil then AUDIOQS.TablePrint(thisLocTable); PlaySoundFile("Interface/Addons/AudioQs/Sound/pulse_1_dropoped.ogg") end
		local key = string.format("%s-%s", thisLocTable.startTime, thisLocTable.spellID)
		if not AUDIOQS.GS.CC_activeLoc[key] then
			AUDIOQS.GS.CC_activeLoc[key] = thisLocTable
			table.insert(AUDIOQS.GS.CC_locToBeAnnounced, key)
			AUDIOQS.GS.CC_activeLoc[key].activeCheck = CC_LOC_FOUND
		else
			AUDIOQS.GS.CC_activeLoc[key].activeCheck = CC_LOC_FOUND
		end
if AUDIOQS.VERBOSE then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."LossOfControl!", thisLocTable.locType, thisLocTable.spellID, thisLocTable.startTime, thisLocTable.duration, thisLocTable.lockoutSchool) end
		i = i + 1
	end
	
	for k,tbl in pairs(AUDIOQS.GS.CC_activeLoc) do
		if tbl.activeCheck == CC_LOC_PENDING then
			if AUDIOQS.WOW_SHADOWLANDS then
				AUDIOQS.GS.CC_activeLoc[k] = nil -- Recycling LOC redundant in 90000
			else
				CC_DeleteLoc(k)
			end
		else
			tbl.activeCheck = CC_LOC_PENDING
		end
	end
end

-------- AUDIOQS.CrowdControl_GetKeyLocFilename()
function AUDIOQS.CrowdControl_GetKeyLocFilename(key)
	local thisLocData = AUDIOQS.GS.CC_activeLoc[key]
	
	if key == nil or key == '' or thisLocData == nil then 
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."GetKeyLocFilename called with missing arg or data. (key:", key, "activeLoc[key]:", thisLocData) end 
		return nil 
	end
	
	local thisLocType = thisLocData.locType
	local thisLocSpellID = thisLocData.spellID
	if thisLocType == nil then 
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.." locType was nil for key=", key) end
		return nil
	elseif thisLocType == "SCHOOL_INTERRUPT" then
		local thisLockoutSchool = thisLocData.lockoutSchool
		local thisFilepath = schoolTypeToLockoutFilepath[thisLockoutSchool]
		return thisLockoutSchool and thisFilepath or nil
	else
		return spellIDToFilepath[thisLocSpellID] or locTypeToFilepath[thisLocType] or nil
	end
end

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