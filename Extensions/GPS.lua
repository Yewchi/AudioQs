-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com
--
-- Currently requires HealthMonitor to be loaded.
-- Does not currently support WoW Classic -- Patch planned before Jan 14 '20.

local extName = "GPS"
local extNameDetailed = "GPS"
local extShortNames = "gps"
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

local GPS_gpsSpecifier = "|cff55B589<GPS>|r "
GPS_CompassButtonFrame = nil

local GPS_CompassKeybindHandlerFrame = "AQ_GPS_COMPASS_KEYBIND_HANDLER"
local GPS_CompassKeybindHandlerFrameBindingAction = "CLICK "..GPS_CompassKeybindHandlerFrame..":LeftButton"


-- TODO - This implies an "unload" function is desirable when unloading extensions (to remove AQcompass macro).
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
		["Initialize"] = function() 
			AUDIOQS.GS.GPS_PlayerAliveStatus = (UnitIsDeadOrGhost("player") and AUDIOQS.GS.GPS_PLAYER_DEAD or AUDIOQS.GS.GPS_PLAYER_LIVING) 

			if GetBindingAction("ALT-CTRL-SHIFT-C") ~= "" and GetBindingAction("ALT-CTRL-SHIFT-C") ~= GPS_CompassKeybindHandlerFrameBindingAction then
				print(AUDIOQS.audioQsSpecifier..GPS_gpsSpecifier.."Default keybind not loaded because ALT-CTRL-SHIFT-C already bound.")
			else -- Set keybind and button frame for compass (triggered via UPDATE_MACRO event)
				GPS_CompassButtonFrame = CreateFrame("BUTTON", GPS_CompassKeybindHandlerFrame)
				SetBindingClick("ALT-CTRL-SHIFT-C", GPS_CompassButtonFrame:GetName())
				GPS_CompassButtonFrame:SetScript("OnClick", function() -- Raises event (allows a hook into the prompting system, for cleaner audio handling/stop sound functionality)
					AUDIOQS.GS.GPS_GetFacingUnhandled = true -- Turned off in segment conditional if this caused the UPDATE_MACRO

					CreateMacro("AQDirtyEventRaiser", 132089, "", 0)
					DeleteMacro("AQDirtyEventRaiser") -- If you're a WoW AddOn developer please mail me a trout to slap myself accross the face
				end)
				GPS_CompassButtonFrame:RegisterForClicks("AnyUp")
			end
		end
}

--- Static Vals ---
--
AUDIOQS.GS.GPS_PLAYER_LIVING = 			0x10 	-- 0001 0000
AUDIOQS.GS.GPS_PLAYER_LIVING_BY_RES =	0x11	-- 0001 0001
AUDIOQS.GS.GPS_PLAYER_LIVING_BY_SPIRIT = 0x12	-- 0001 0002
AUDIOQS.GS.GPS_PLAYER_DEAD = 			0x20 	-- 0010 0000 -- Keep Dead states above 0x1F
AUDIOQS.GS.GPS_PLAYER_GHOST = 			0x30 	-- 0010 0000
AUDIOQS.GS.GPS_PLAYER_LEFT_GY =			0x31	-- 0010 0001
AUDIOQS.GS.GPS_PLAYER_AT_GY =			0x32	-- 0010 0002

local GPS_DIRECTIONAL_RADIANS =	1
local GPS_DIRECTIONAL_STRING =	2

local GPS_PROHIBITIVELY_HIGH_TIME = 2^22 -- 48-year session anyone??

AUDIOQS.GPS_IGNORE_RANGE_TIME = 0.15
--
-- /Static Vals ---

--- Extension Vars --
--
local directionals = {	{0.3927, "north"},
						{1.1781, "northwest"},
						{1.9635, "west"},
						{2.7489, "southwest"},
						{3.5343, "south"},
						{4.3197, "southeast"},
						{5.1051, "east"},
						{5.8904, "northeast"}
}

AUDIOQS.GS.GPS_lastRangeTimestamp = GetTime()
--
-- /Extension Vars

--- Spell Tables and Prompts --
--
-- spells[spellId] = { "Spell Name", charges, cdDur, cdExpiration, unitId, spellType}
local extSpells = { 
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
local extEvents = {
	["PLAYER_ALIVE"] = {},
	["PLAYER_DEAD"] = {},
	["PLAYER_UNGHOST"] = {},
	["AREA_SPIRIT_HEALER_IN_RANGE"] = {},
	["AREA_SPIRIT_HEALER_OUT_OF_RANGE"] = {},
	["RESURRECT_REQUEST"] = {},
	["UPDATE_MACROS"] = {} -- Used with a macro to trigger a prompt stating the direction facing (out of PvP instances)
}

local extSegments = {
	["PLAYER_ALIVE"] = {
		{
			{
				"AUDIOQS.GPS_ProcessAlive() return false",
				false,
			},
			{nil, nil,	nil, false} 
		}
	},
	["PLAYER_DEAD"] = {
		{
			{
				"AUDIOQS.GPS_ProcessDeath() return false",
				false,
			},
			{nil, nil, nil, false}
		}
	},
	["PLAYER_UNGHOST"] = {
		{
			{
				"AUDIOQS.GPS_ProcessUnghost() return false",
				false
			},
			{nil, nil, nil, false}
		}
	},
	["AREA_SPIRIT_HEALER_IN_RANGE"] = {
		{
			{
				"return AUDIOQS.GPS_ProcessGraveyardInRange()",
				false
			},
			{
				nil,
				AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."GPS/entered_spirit_rez.ogg",		
				nil,
				true
			}
		}
	},
	["AREA_SPIRIT_HEALER_OUT_OF_RANGE"] = {
		{
			{
				"return AUDIOQS.GPS_ProcessGraveyardOutOfRange()", -- TODO Will this occur while alive
				false
			},
			{
				nil,	
				AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."GPS/left_spirit_rez.ogg",		
				nil,	
				true
			}
		}
	},
	["RESURRECT_REQUEST"] = {
		{
			{
				"AUDIOQS.GPS_ProcessResurrectRequest() return true",
				false,
			},
			{
				nil,
				AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."GPS/resurrect_requested.ogg",
				nil,
				true
			},
		}
	},
	["UPDATE_MACROS"] = {
		{
			{
				true,
				false,
			},
			{
				0.1, -- delay incase chat macro does not finish before this event raised.
				nil,
				nil,
				AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION
			},
			{
				nil,
				AUDIOQS.SOUND_FUNC_PREFIX.."local facing = AUDIOQS.GPS_GetFacing() if type(facing) == 'string' then return '"..AUDIOQS.SOUNDS_ROOT.."GPS/'..facing..'.ogg' end return nil",
				nil,
				"if AUDIOQS.GS.GPS_GetFacingUnhandled then AUDIOQS.GS.GPS_GetFacingUnhandled = false return true end return false"
			}
		}
	}
}

--
-- /Spell Tables and Rules

--- Funcs --
--
function AUDIOQS.GPS_ProcessDeath()
	if AUDIOQS.GS.GPS_PlayerAliveStatus ~= AUDIOQS.GS.GPS_PLAYER_DEAD then
		AUDIOQS.GS.GPS_lastRangeTimestamp = GPS_PROHIBITIVELY_HIGH_TIME -- Flags a delay is required on the first following AREA_SPIRIT_IN/OUT_OF_RANGE calls. (see ProcessGraveyardIn/OutRange())
		AUDIOQS.GS.GPS_PlayerAliveStatus = AUDIOQS.GS.GPS_PLAYER_DEAD
	end
end

function AUDIOQS.GPS_ProcessUnghost()
	if not UnitIsDeadOrGhost("player") and AUDIOQS.GS.GPS_PlayerAliveStatus >= AUDIOQS.GS.GPS_PLAYER_DEAD then
		if AUDIOQS.GS.GPS_PlayerResurrectionOffered == true then 
			AUDIOQS.GS.GPS_PlayerAliveStatus = AUDIOQS.GS.GPS_PLAYER_LIVING_BY_RES
			AUDIOQS.GS.GPS_PlayerResurrectionOffered = false
			return true
		else
			AUDIOQS.GS.GPS_PlayerAliveStatus = AUDIOQS.GS.GPS_PLAYER_LIVING_BY_SPIRIT
			return true
		end
	end
	return false
end

function AUDIOQS.GPS_ProcessAlive() -- The player is ghost or alive, e.g. not unreleased while dead.
	if UnitIsDeadOrGhost("player") and AUDIOQS.GS.GPS_PlayerAliveStatus ~= AUDIOQS.GS.GPS_PLAYER_GHOST then
		AUDIOQS.GS.GPS_PlayerAliveStatus = AUDIOQS.GS.GPS_PLAYER_GHOST
	elseif AUDIOQS.GS.GPS_PlayerResurrectionOffered and AUDIOQS.GS.GPS_PlayerAliveStatus ~= AUDIOQS.GS.GPS_PLAYER_LIVING then
		AUDIOQS.GS.GPS_PlayerAliveStatus = AUDIOQS.GS.GPS_PLAYER_LIVING_BY_RES
		AUDIOQS.GS.GPS_PlayerResurrectionOffered = false
	end
end

function AUDIOQS.GPS_ProcessResurrectRequest() 
	AUDIOQS.GS.GPS_PlayerResurrectionOffered = true
end

function AUDIOQS.GPS_ProcessGraveyardInRange()
	if true or UnitIsDeadOrGhost("player") and AUDIOQS.GS.GPS_PlayerAliveStatus >= AUDIOQS.GS.GPS_PLAYER_DEAD then -- TODO Clearly test code. Need to double check this if statement can be removed.
		AUDIOQS.GS.GPS_PlayerAliveStatus = AUDIOQS.GS.GPS_PLAYER_AT_GY

		local currTime = GetTime()
		if (currTime < AUDIOQS.GS.GPS_lastRangeTimestamp) then
			AUDIOQS.GS.GPS_lastRangeTimestamp = GetTime()
		elseif (currTime - AUDIOQS.GS.GPS_lastRangeTimestamp) >= AUDIOQS.GPS_IGNORE_RANGE_TIME then 
			AUDIOQS.GS.GPS_lastRangeTimestamp = GetTime() 
			return true 
		end	
	end
	return false
end

function AUDIOQS.GPS_ProcessGraveyardOutOfRange() -- TODO Test will this be raised when leaving while alive?
	if UnitIsDeadOrGhost("player") and AUDIOQS.GS.GPS_PlayerAliveStatus == AUDIOQS.GS.GPS_PLAYER_AT_GY then
		AUDIOQS.GS.GPS_PlayerAliveStatus = AUDIOQS.GS.GPS_PLAYER_LEFT_GY

		if (GetTime() - AUDIOQS.GS.GPS_lastRangeTimestamp) >= AUDIOQS.GPS_IGNORE_RANGE_TIME then 
			AUDIOQS.GS.GPS_lastRangeTimestamp = GetTime() 
			return true 
		end	
	end
	return false
end

function AUDIOQS.GPS_GetFacing()
	local radiansFacing = GetPlayerFacing()
	
	if radiansFacing == nil then return nil end

	for n=1, #directionals, 1 do
		if radiansFacing < directionals[n][GPS_DIRECTIONAL_RADIANS] then
			return directionals[n][GPS_DIRECTIONAL_STRING]
		end
	end
	return directionals[1][GPS_DIRECTIONAL_STRING] -- Loops around (north is 5.89 -> 0 -> 0.392)
end

function AUDIOQS.TEST_GPS_SaveFacing()
	if SV_Specializations["Respawns"] == nil then 
		SV_Specializations["Respawns"] = {}
	end

	table.insert(SV_Specializations["Respawns"], {GetPlayerFacing(), date()})
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
