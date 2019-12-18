-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com
--
-- Currently requires HealthMonitor to be loaded.
-- Does not currently support WoW Classic -- Patch planned before Jan 14 '20.

local extName = "GPS"
local extNameDetailed = "GPS"
local extShortNames = "gps"
local extSpecLimit = AQ.ANY_SPEC_ALLOWED 

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
			AQ.GS.GPS_PlayerAliveStatus = (UnitIsDeadOrGhost("player") and AQ.GS.GPS_PLAYER_DEAD or AQ.GS.GPS_PLAYER_LIVING) 

			if GetBindingAction("ALT-CTRL-SHIFT-C") ~= "" then
				print(AQ.audioQsSpecifier..GPS_gpsSpecifier.."Default keybind not loaded because ALT-CTRL-SHIFT-C already bound.")
			else -- Set keybind and button frame for compass (triggered via UPDATE_MACRO event)
				GPS_CompassButtonFrame = CreateFrame("BUTTON", "AQ_GPS_COMPASS_KEYBIND_HANDLER")
				SetBindingClick("ALT-CTRL-SHIFT-C", GPS_CompassButtonFrame:GetName())
				GPS_CompassButtonFrame:SetScript("OnClick", function() -- Raises event (allows a hook into the prompting system, for cleaner audio handling/stop sound functionality)
					AQ.GS.GPS_GetFacingUnhandled = true -- Turned off in segment conditional if this caused the UPDATE_MACRO

					CreateMacro("AQDirtyEventRaiser", 132089, "", 0)
					DeleteMacro("AQDirtyEventRaiser") -- If you're a WoW AddOn developer please mail me a trout to slap myself accross the face
				end)
				GPS_CompassButtonFrame:RegisterForClicks("AnyUp")
			end
		end
}

--- Static Vals ---
--
AQ.GS.GPS_PLAYER_LIVING = 			0x10 	-- 0001 0000
AQ.GS.GPS_PLAYER_LIVING_BY_RES =	0x11	-- 0001 0001
AQ.GS.GPS_PLAYER_LIVING_BY_SPIRIT = 0x12	-- 0001 0002
AQ.GS.GPS_PLAYER_DEAD = 			0x20 	-- 0010 0000 -- Keep Dead states above 0x1F
AQ.GS.GPS_PLAYER_GHOST = 			0x30 	-- 0010 0000
AQ.GS.GPS_PLAYER_LEFT_GY =			0x31	-- 0010 0001
AQ.GS.GPS_PLAYER_AT_GY =			0x32	-- 0010 0002

local GPS_DIRECTIONAL_RADIANS =	1
local GPS_DIRECTIONAL_STRING =	2

local GPS_PROHIBITIVELY_HIGH_TIME = 2^22 -- 48-year session anyone??

AQ.GPS_IGNORE_RANGE_TIME = 0.15
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

AQ.GS.GPS_lastRangeTimestamp = GetTime()
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
				"AQ.GPS_ProcessAlive() return false",
				false,
			},
			{nil, nil,	nil, false} 
		}
	},
	["PLAYER_DEAD"] = {
		{
			{
				"AQ.GPS_ProcessDeath() return false",
				false,
			},
			{nil, nil, nil, false}
		}
	},
	["PLAYER_UNGHOST"] = {
		{
			{
				"AQ.GPS_ProcessUnghost() return false",
				false
			},
			{nil, nil, nil, false}
		}
	},
	["AREA_SPIRIT_HEALER_IN_RANGE"] = {
		{
			{
				"return AQ.GPS_ProcessGraveyardInRange()",
				false
			},
			{
				nil,
				AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."GPS/entered_spirit_rez.ogg",		
				nil,
				true
			}
		}
	},
	["AREA_SPIRIT_HEALER_OUT_OF_RANGE"] = {
		{
			{
				"return AQ.GPS_ProcessGraveyardOutOfRange()", -- TODO Will this occur while alive
				false
			},
			{
				nil,	
				AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."GPS/left_spirit_rez.ogg",		
				nil,	
				true
			}
		}
	},
	["RESURRECT_REQUEST"] = {
		{
			{
				"AQ.GPS_ProcessResurrectRequest() return true",
				false,
			},
			{
				nil,
				AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."GPS/resurrect_requested.ogg",
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
				AQ.PROMPTSEG_CONDITIONAL_CONTINUATION
			},
			{
				nil,
				AQ.SOUND_FUNC_PREFIX.."local facing = AQ.GPS_GetFacing() if type(facing) == 'string' then return '"..AQ.SOUNDS_ROOT.."GPS/'..facing..'.ogg' end return nil",
				nil,
				"if AQ.GS.GPS_GetFacingUnhandled then AQ.GS.GPS_GetFacingUnhandled = false return true end return false"
			}
		}
	}
}

--
-- /Spell Tables and Rules

--- Funcs --
--
function AQ.GPS_ProcessDeath()
	if AQ.GS.GPS_PlayerAliveStatus ~= AQ.GS.GPS_PLAYER_DEAD then
		AQ.GS.GPS_lastRangeTimestamp = GPS_PROHIBITIVELY_HIGH_TIME -- Flags a delay is required on the first following AREA_SPIRIT_IN/OUT_OF_RANGE calls. (see ProcessGraveyardIn/OutRange())
		AQ.GS.GPS_PlayerAliveStatus = AQ.GS.GPS_PLAYER_DEAD
	end
end

function AQ.GPS_ProcessUnghost()
	if not UnitIsDeadOrGhost("player") and AQ.GS.GPS_PlayerAliveStatus >= AQ.GS.GPS_PLAYER_DEAD then
		if AQ.GS.GPS_PlayerResurrectionOffered == true then 
			AQ.GS.GPS_PlayerAliveStatus = AQ.GS.GPS_PLAYER_LIVING_BY_RES
			AQ.GS.GPS_PlayerResurrectionOffered = false
			return true
		else
			AQ.GS.GPS_PlayerAliveStatus = AQ.GS.GPS_PLAYER_LIVING_BY_SPIRIT
			return true
		end
	end
	return false
end

function AQ.GPS_ProcessAlive() -- The player is ghost or alive, e.g. not unreleased while dead.
	if UnitIsDeadOrGhost("player") and AQ.GS.GPS_PlayerAliveStatus ~= AQ.GS.GPS_PLAYER_GHOST then
		AQ.GS.GPS_PlayerAliveStatus = AQ.GS.GPS_PLAYER_GHOST
	elseif AQ.GS.GPS_PlayerResurrectionOffered and AQ.GS.GPS_PlayerAliveStatus ~= AQ.GS.GPS_PLAYER_LIVING then
		AQ.GS.GPS_PlayerAliveStatus = AQ.GS.GPS_PLAYER_LIVING_BY_RES
		AQ.GS.GPS_PlayerResurrectionOffered = false
	end
end

function AQ.GPS_ProcessResurrectRequest() 
	AQ.GS.GPS_PlayerResurrectionOffered = true
end

function AQ.GPS_ProcessGraveyardInRange()
	if true or UnitIsDeadOrGhost("player") and AQ.GS.GPS_PlayerAliveStatus >= AQ.GS.GPS_PLAYER_DEAD then
		AQ.GS.GPS_PlayerAliveStatus = AQ.GS.GPS_PLAYER_AT_GY

		local currTime = GetTime()
		if (currTime < AQ.GS.GPS_lastRangeTimestamp) then -- i.e. GPS_PROHIBITIVELY_HIGH_TIME was set as a flag to delay prompts from this moment
			AQ.GS.GPS_lastRangeTimestamp = GetTime() -- (this if-statement needed because IN/OUT_OF_RANGE is thrown in quick succession upon entering graveyard as ghost)
		elseif (currTime - AQ.GS.GPS_lastRangeTimestamp) >= AQ.GPS_IGNORE_RANGE_TIME then 
			AQ.GS.GPS_lastRangeTimestamp = GetTime() 
			return true 
		end	
	end
	return false
end

function AQ.GPS_ProcessGraveyardOutOfRange() -- TODO Test will this be raised when leaving while alive?
	if UnitIsDeadOrGhost("player") and AQ.GS.GPS_PlayerAliveStatus == AQ.GS.GPS_PLAYER_AT_GY then
		AQ.GS.GPS_PlayerAliveStatus = AQ.GS.GPS_PLAYER_LEFT_GY

		if (GetTime() - AQ.GS.GPS_lastRangeTimestamp) >= AQ.GPS_IGNORE_RANGE_TIME then 
			AQ.GS.GPS_lastRangeTimestamp = GetTime() 
			return true 
		end	
	end
	return false
end

function AQ.GPS_GetFacing()
	local radiansFacing = GetPlayerFacing()
	
	if radiansFacing == nil then return nil end

	for n=1, #directionals, 1 do
		if radiansFacing < directionals[n][GPS_DIRECTIONAL_RADIANS] then
			return directionals[n][GPS_DIRECTIONAL_STRING]
		end
	end
	return directionals[1][GPS_DIRECTIONAL_STRING] -- Loops around (north is 5.89 -> 0 -> 0.392)
end

function AQ.TEST_GPS_SaveFacing()
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
	if extSpecLimit == AQ.ANY_SPEC_ALLOWED or extSpecLimit == specId then
		return true
	end
	return false
end
--
-- /Funcs --

-- Register Extension:
AQ.RegisterExtension(extName, extFuncs)
