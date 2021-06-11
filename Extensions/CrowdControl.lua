-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local AUDIOQS = AUDIOQS_4Q5
local GameState = AUDIOQS.GS

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
	["DISARM"] =					string.format("%sCrowdControl/%s.ogg", AUDIOQS.SOUNDS_ROOT, "disarmed"),
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
		["Initialize"] = function()
				GameState.CC_activeLoc = {}
				GameState.CC_locToBeAnnounced = {}
			end
}

--- Spell Tables and Prompts --
--
-- spells[spellId] = { "Spell Name", charges, cdDur, cdExpiration, unitId, spellType}
extSpells = { 
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
extEvents = {
		["LOSS_OF_CONTROL_ADDED"] = {},
		["LOSS_OF_CONTROL_UPDATE"] = {}
}

extSegments = {
	["LOSS_OF_CONTROL_ADDED"] = {
		{
			{
				function() AUDIOQS.CrowdControl_CheckLocUpdate() if table.getn(GameState.CC_locToBeAnnounced) > 0 then return true end end,
				false
			},
			{nil,		function() return AUDIOQS.CrowdControl_GetKeyLocFilename(table.remove(GameState.CC_locToBeAnnounced)) end,		nil,	true }
		}
	},
	["LOSS_OF_CONTROL_UPDATE"] = {
		{
			{
				function() AUDIOQS.CrowdControl_CheckLocUpdate() if table.getn(GameState.CC_locToBeAnnounced) > 0 then return true end end,
				false
			},
			{1.0,		function() return AUDIOQS.CrowdControl_GetKeyLocFilename(table.remove(GameState.CC_locToBeAnnounced)) end,		nil,	true }
		}
	}
}
--
-- /Spell Tables and Rules

--- Funcs --
--
-- Redundant in 90000 -- late note: Can't remember why, it's probably because modern wow has a variable LOC-data table size.
-------------- CC_DeleteLoc()
local function CC_DeleteLoc(key)
	GameState.CC_activeLoc[key].activeCheck = nil
	table.insert(tablesForRecycling, GameState.CC_activeLoc[key])
	GameState.CC_activeLoc[key] = nil
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
local CC_GetLossOfControlTable = AUDIOQS.WOW_VC and 
		function(index)
			local locType, spellID, _, _, startTime, _, dur, lockoutSchool = C_LossOfControl.GetEventInfo(index) -- "ID" in API
			return CC_CreateLoc(locType, spellID, startTime, dur, lockoutSchool)
		end
	or
		function(index)
			return C_LossOfControl.GetActiveLossOfControlData(index)
		end
;

local CC_GetLossOfControlCount = not AUDIOQS.WOW_VC and 
		function()
			return C_LossOfControl.GetActiveLossOfControlDataCount()
		end
	or
		function()
			return C_LossOfControl.GetNumEvents()
		end
;

-- Late note: Doesn't this only stop LOSS_OF_CONTROL_UPDATE from repeating calls if LOC_UPDATE is called twice (and no more) in quick succession (but on different frames)? Is this always the case? This needs to be detailed.
local CC_ClearHistory = not AUDIOQS.WOW_VC and
		function(activeLocs)
			for key,locTbl in pairs(activeLocs) do
				if locTbl.activeCheck == CC_LOC_PENDING then
					activeLocs[key] = nil -- Recycling LOC redundant in 90000 (The LoC data table is fully returned from the WoW API, we do not create the table ourself)
				else
					locTbl.activeCheck = CC_LOC_PENDING
				end
			end
		end
	or
		function(activeLocs)
			for key,locTbl in pairs(activeLocs) do
				if locTbl.activeCheck == CC_LOC_PENDING then
					CC_DeleteLoc(key)
				else
					locTbl.activeCheck = CC_LOC_PENDING
				end
			end
		end
;

-------- AUDIOQS.CrowdControl_CheckLocUpdate()
---- Called on LOSS_OF_CONTROL_UPDATE. Updates stored Loc everytime, indicates if they are fresh to trigger prompting.
function AUDIOQS.CrowdControl_CheckLocUpdate()
	local t = GetTime()
	if t == mostRecentLocCheck then return false else mostRecentLocCheck = t end

	local thisNumLoc = CC_GetLossOfControlCount()
	local thisLocTable
	local i = 1
	-- Soln elegance is hmmmm, but shouldn't have too much overhead. i.e.: usage of str concat of startTime and spellID as key.
	while (i <= thisNumLoc) do
		thisLocTable = CC_GetLossOfControlTable(i)
		if thisLocTable.startTime == nil then  -- This logic is true when standing in a "LoC pool": rather than on a timer, applied until the player is not within it's AoE, 
			thisLocTable.startTime = GetTime()
			thisLocTable.duration = 8
		end
		local key = string.format("%s-%s", thisLocTable.startTime, thisLocTable.spellID)
		if not GameState.CC_activeLoc[key] then
			GameState.CC_activeLoc[key] = thisLocTable
			table.insert(GameState.CC_locToBeAnnounced, key)
		end
		GameState.CC_activeLoc[key].activeCheck = CC_LOC_FOUND
		
if AUDIOQS.VERBOSE then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."LossOfControl!", thisLocTable.locType, thisLocTable.spellID, thisLocTable.startTime, thisLocTable.duration, thisLocTable.lockoutSchool) end
		i = i + 1
	end
	
	CC_ClearHistory(GameState.CC_activeLoc)
end

-------- AUDIOQS.CrowdControl_GetKeyLocFilename()
function AUDIOQS.CrowdControl_GetKeyLocFilename(key)
	local thisLocData = GameState.CC_activeLoc[key]
	
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
--
-- /Funcs --

-- Register Extension:
ext_ref_num = AUDIOQS.RegisterExtension(extName, extFuncs)