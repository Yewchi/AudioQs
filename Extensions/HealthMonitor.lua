-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

--~ Calls out raid number of players which are low health in World or PvE, at higher frequencies for lower health. Idea theorized and developed alongside twitch.tv/BlindlyPlayingGames
--~ '1' is player's number for party and PvP. '2' to '4' are party1 to party4.
--~ '2' is focus in PvP and '3' is target in PvP.

--- Extension variables --
--
local mFloor = math.floor

local AUDIOQS = AUDIOQS_4Q5
local GameState = AUDIOQS.GS

local extensionSpecifier = AUDIOQS.extensionColour.."<HealthMonitor>|r: "
local CHECK_ROLE_ASSIGNMENT = AUDIOQS.BUILD_VERSION >= 30300

AUDIOQS.DISPEL_FILE_MODIFIER = "_dispel"
AUDIOQS.NO_FILE_MODIFIER = ""

-- TODO Don't like that this is hard-coded, should list the spells which dispel for specs, and search the spell text on load to see what they can do.
local SPEC_DISPEL_TYPES = {
	[65] = {"Poison", "Disease", "Magic"}, 
	[105] = {"Magic", "Curse", "Poison"}, 
	[270] = {"Magic", "Poison", "Disease"}, 
	[256] = {"Magic", "Disease"}, 
	[257] = {"Magic", "Disease"}, 
	[264] = {"Curse", "Magic"}
}

GameState.INSTANCE_PVMAG =			0x08 	-- b0000 1000
GameState.INSTANCE_PVE =			0x10	-- b0001 0000
GameState.INSTANCE_PARTY =			0x11	-- b0001 0001
GameState.INSTANCE_RAID = 			0x12	-- b0001 0010
GameState.INSTANCE_SCENARIO =		0x14	-- b0001 0100
GameState.INSTANCE_PVP =			0x20	-- b0010 0000
GameState.INSTANCE_ARENA =			0x21	-- b0010 0001
GameState.INSTANCE_BG =				0x22	-- b0010 0010
local thisSpecDispels

local modesToCheck = {}
--
-- /Extension variables -- 

-- --- Set these >>
local extName = "HealthMonitor"
local extNameDetailed = "Health Monitor for Healers (Raid, Party, World and PvP)"
local extShortNames = "hm|healthtracker|healthtracking"
local extSpecLimit = AUDIOQS.ANY_SPEC_ALLOWED
-- -- << Set those

local MUTE_CMD_TO_ROLE = {
		["tank"] = "TANK",
		["tanks"] = "TANK",
		["healer"] = "HEALER",
		["healers"] = "HEALER",
		["heal"] = "HEALER",
		["heals"] = "HEALER",
		["dps"] = "DAMAGER",
		["damage"] = "DAMAGER",
		["damager"] = "DAMAGER"
	}
local MUTE_CMD_TO_UID = {
		["self"] = "player",
		["player"] = "player",
		["1"] = "player",
		["2"] = "party1",
		["3"] = "party2",
		["4"] = "party3",
		["5"] = "party4",
	}
	
local CONFIG__track_focus = false
	
local current_muted_table = {}
local current_muted_groups_table = {}
local CHECK_GROUP_MUTES = false

appp = current_muted_table

local MIN_GROUP_INDEX = 1
local MAX_GROUP_INDEX = 8

local extSpells, extEvents, extSegments

local reset_players_calling

local t_delims_info = {{}, {}}
local t_delims_funcs = t_delims_info[AUDIOQS.DELIM_I_FUNCS]
local t_delims_parameters = t_delims_info[AUDIOQS.DELIM_I_PARAMS]

local ext_ref_num

local Frame_NoUHCheck -- Used to make a regular check that there hasn't been a missing UNIT_HEALTH update (due to probably replenishment?)

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
		["GetDelimInfo"] = function() return t_delims_info end,
		["Initialize"] = function()
				CONFIG__track_focus = SV_Specializations["HealthMonitorTrackFocus"]
				
				AUDIOQS.GS.HM_initialized = false
				AUDIOQS.HealthMonitor_CheckMode("INIT")
				Frame_NoUHCheck = CreateFrame("FRAME", "AQ:HM_NO_UH_CHECK")
				Frame_NoUHCheck.limiter = 0.5
				Frame_NoUHCheck:SetScript("OnUpdate", function(_, elapsed)
						Frame_NoUHCheck.limiter = Frame_NoUHCheck.limiter - elapsed
						if Frame_NoUHCheck.limiter <= 0 then
							Frame_NoUHCheck.limiter = IsInRaid() and 0.3 or 0.125
							AUDIOQS.HealthMonitor_UpdateHealthSnapshot()
						end
					end
				)
				-- config
				if not AUDIOQS.Util_SlashCmdExists("hm") then
					AUDIOQS.Util_RegisterSlashCmd("hm", function(args)
							for i=1,#args do
								args[i] = string.lower(args[i])
							end
							-- if-else segment must return if nothing is changed.
							if not args[2] or args[2] == "-h" or string.match(args[2], ".*help.*") then
								-- Print -h
								print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."What would you like to change with Health Monitor?\n"..
										"Mute party#: \"/aq hm mute 5\" -- mute 'party4'. '1' is the player.\n"..
										"Mute type: \"/aq hm mute dps\" \"/aq hm unmute tank\"\n"..
										"Mute raid group: \"/aq hm mute group1\" \"/aq hm unmute g1\"\n"..
										"Exclusive: \"/aq hm self\" -- or unmute all: \"/aq hm all\"\n"..
										"Track Focus: \"/aq hm focus on\" \"/aq hm focus off\"")
								return
							elseif args[2] == "off" or args[2] == "mute" then
								local muteRoleString = MUTE_CMD_TO_ROLE[args[3]] or MUTE_CMD_TO_UID[args[3]]
								if args[3] == "all" then
									-- This is problematic, a "hm off / hm on" is probably needed instead, with "mute all party" "mute raid" "mute party" "mute raidgroups" "mute roles"
									-- (this is so that a user can quickly, say, mute all raidgroups then unmute group1; or turn alerts off with hm off then hm on regaining their config)
									-- The logical problem, as in logic -- not programmatically, is becoming vast.
									-- e.g. raid callouts will still occur as is, after muting all.
									-- N.B. if undertaking this: the only prompt that doesn't need a valid mode is 'focus' callout. xxxModexxx(mode) if ALL_OFF then return false end ... end
									-- Scope == Demand, so I won't be doing this unless specifically requested.
									for _,muteString in pairs(MUTE_CMD_TO_UID) do
										current_muted_table[muteString] = true
									end
									for iGroup=MIN_GROUP_INDEX,MAX_GROUP_INDEX do
										current_muted_groups_table[iGroup] = true
									end
									CHECK_GROUP_MUTES = true
									print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."All call-outs off.")
								elseif args[3]:find("^g") then
									local group = args[3]:match("^g(%d)$") or args[3]:match("group(%d)$")
									group = group and tonumber(group)
									if group and group >= MIN_GROUP_INDEX and group <= MAX_GROUP_INDEX then
										current_muted_groups_table[group] = true
										CHECK_GROUP_MUTES = true
										print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."Muting "..args[3].." for raids.")
									else
										print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."Group name must be as 'g1', 'g2', etc.")
										return
									end
								else
									if muteRoleString then
										current_muted_table[muteRoleString] = true
										print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."Muting '"..muteRoleString.."'.")
									else
										print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."The id '"..args[3].."' isn't recognized.")
										return
									end
								end
							elseif args[2] == "on" or args[2] == "unmute" or args[2] == "all" then
								if args[2] == "all" or args[3] == "all" then
									for _,unmuteString in pairs(MUTE_CMD_TO_UID) do
										current_muted_table[unmuteString] = nil
									end
									for _,unmuteString in pairs(MUTE_CMD_TO_ROLE) do
										current_muted_table[unmuteString] = nil
									end
									for iGroup=MIN_GROUP_INDEX,MAX_GROUP_INDEX do
										current_muted_groups_table[iGroup] = nil
									end
									CHECK_GROUP_MUTES = false
									print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."All call-outs on.")
								elseif args[3]:find("^g") then
									local group = args[3]:match("^g(%d)$") or args[3]:match("group(%d)$")
									group = group and tonumber(group)
									if group and group >= MIN_GROUP_INDEX and group <= MAX_GROUP_INDEX then
										current_muted_groups_table[group] = false
										print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."Unmuting "..args[3].." for raids.")
										local iGroup = MIN_GROUP_INDEX
										while(true) do
											if current_muted_groups_table[iGroup] then
												CHECK_GROUP_MUTES = true
											end
											if iGroup < MAX_GROUP_INDEX then
												iGroup = iGroup + 1
											else
												CHECK_GROUP_MUTES = false
												break
											end
										end
									else
										print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."Group name must be as 'group1', 'group2', etc.")
										return
									end
								else
									local unmuteRoleString = MUTE_CMD_TO_ROLE[args[3]] or MUTE_CMD_TO_UID[args[3]]
									if unmuteRoleString then
										current_muted_table[unmuteRoleString] = nil
										print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."Un-muting '"..unmuteRoleString.."'.")
									else
										print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."The id '"..args[3].."' isn't unrecognized.")
										return
									end
								end
							elseif args[2] == "self" then
								for _,muteString in pairs(MUTE_CMD_TO_UID) do
									current_muted_table[muteString] = true
								end
								print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."Self-mode on.")
								current_muted_table["player"] = nil
							elseif args[2] == "focus" then
								if args[3] == "on" or args[3] == "unmute" then
									CONFIG__track_focus = true
									SV_Specializations["HealthMonitorTrackFocus"] = true
									print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."Focus call-out on.")
								elseif args[3] == "off" or args[3] == "mute" then
									CONFIG__track_focus = false
									SV_Specializations["HealthMonitorTrackFocus"] = false
									print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."Focus call-out off.")
								end
							else
								return -- Don't reset the functional strings for exploding more/less code into the prompt segments, because we haven't changed anything
							end
							reset_players_calling()
							AUDIOQS.SEGLIB_ReloadExtDefaults(ext_ref_num)
						end)
					AUDIOQS.Util_RegisterSlashCmdSynonym("healthmonitor", "hm")
					AUDIOQS.Util_RegisterSlashCmdSynonym("healthtracker", "hm")
					AUDIOQS.Util_RegisterSlashCmdSynonym("healthtrack", "hm")
					AUDIOQS.Util_RegisterSlashCmdSynonym("healthtracking", "hm")
				end
			end
	}

-- --- Set these >>
extSpells = {
	}
	
extEvents = {
		["UNIT_HEALTH"] = {
		},
		["ZONE_CHANGED_NEW_AREA"] = {
		},
		["GROUP_ROSTER_UPDATE"] = {
		},
		["UPDATE_BATTLEFIELD_STATUS"] = {
		},
		["PLAYER_ENTERING_WORLD"] = {
		},
		["UNIT_MODEL_CHANGED"] = {
		},
		["UNIT_MAXHEALTH"] = {
		},
		["PLAYER_DEAD"] = {
		}
	}
if AUDIOQS.WOW_SPECS_IMPLEMENTED then
	AUDIOQS.AmmendTable(
			extEvents, 
			{["PLAYER_SPECIALIZATION_CHANGED"] = {}}
		)
end

function AUDIOQS.HealthMonitor_IsPlayerRoleMuted(unitId)
	return current_muted_table[UnitGroupRolesAssigned(unitId)]
end

local function any_roles_muted()
	return (current_muted_table["TANK"] or current_muted_table["HEALER"] or current_muted_table["DAMAGER"]) 
			and true or false
end

local function cancel_prompt_if_muted(delimParameters)
	local unitId, startPrompt = unpack(delimParameters)
	if current_muted_table[unitId] then
		GameState.HM_playersCalling[unitId] = true -- hacky way to force stop checks after mute
		return not startPrompt
	end
	if CHECK_ROLE_ASSIGNMENT and any_roles_muted() then
		local unitIdType = type(unitId)
		if unitIdType == "string" then
			return "if AUDIOQS.HealthMonitor_IsPlayerRoleMuted('"..unitId.."') then return false end"
		elseif unitIdType == "number" then
			return "local raidIndex = AUDIOQS_4Q5.GS.HM_alertPriority["..unitId.."][1] if raidIndex and AUDIOQS.HealthMonitor_IsPlayerRoleMuted('raid'..raidIndex) then return not "..tostring(startPrompt).." end"
		end
	end
	return AUDIOQS.DELIM_NO_CONCAT
end

local function battleground_or_generic_focus(delimParameters)
	local startPrompt = unpack(delimParameters)
	if startPrompt then
		return CONFIG__track_focus
			and "true"
			or "AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_BG)"
	else
		return CONFIG__track_focus
			and AUDIOQS.DELIM_NO_CONCAT
			or "not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_BG) or "
	end
end

local function battleground_or_generic_focus_file(delimParameters)
	return CONFIG__track_focus
			and "return not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_BG) and '"
			..AUDIOQS.SOUNDS_ROOT.."Joanna/focus.ogg' or (AUDIOQS.HealthMonitor_Dispellable('focus') and '"
			..AUDIOQS.SOUNDS_ROOT.."Numerical/2"..AUDIOQS.DISPEL_FILE_MODIFIER
			..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/2.ogg')"
			or "return AUDIOQS.HealthMonitor_Dispellable('focus') and '"
			..AUDIOQS.SOUNDS_ROOT.."Numerical/2"..AUDIOQS.DISPEL_FILE_MODIFIER
			..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/2.ogg'"
end

-- Regrets about not using good functional abstractions are for later. Because Sanic /s (I'm reasonably dissappointed with the state of things)
-- This commit looks worse, and is barely extensible. But on the plus side, the worst part of it is gone (repeated _G[?]). It is replaced with something that requires additional logic around segment funcstrings if implemented. This makes things highly adaptable, with insertable code that otherwise can optimize by skipping any/all checks (however, where often they don't need to be checks-or-not, and just need to shut-off). An idea which elicits some excitement in me. It's just that it's ultimately well-oiled, but a machine that is greedy of the programmer to implement. Harder to write cleanly. Much more memory, but much faster. (below 1MB)
extSegments = {}
extSegments["UNIT_HEALTH"] = {}
-- UpdateHealthSnapshot()
table.insert(extSegments["UNIT_HEALTH"], {
		{
			function() AUDIOQS.HealthMonitor_UpdateHealthSnapshot() return false end,
			false
		},
		{nil, nil, nil, nil}
	})
-- Party --
t_delims_funcs["%%1"] = cancel_prompt_if_muted; t_delims_parameters["%%1"] = {"player", true};
t_delims_funcs["%%2"] = cancel_prompt_if_muted; t_delims_parameters["%%2"] = {"player", false};
table.insert(extSegments["UNIT_HEALTH"], {
		{
			"local AUDIOQS = AUDIOQS_4Q5 %%1 if (AUDIOQS.GS.HM_playersCalling['player'] ~= true and AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_PVP, AUDIOQS.GS.INSTANCE_SCENARIO) and AUDIOQS.GS.HM_healthSnapshot['player'] < 1) then AUDIOQS.GS.HM_playersCalling['player'] = true return true end", -- Evaluated and stored as an adjustedHp (Inside HealthMonitor_UpdateHealthSnapshot()), therefore, it is < 1.0 and > 1.0. If any changes are made to the requirements e.g. "I only want to monitor those below 80% hp", then the adjusted hp can be evaluated as ((curr))/0.8
			"local AUDIOQS = AUDIOQS_4Q5 %%2 if not AUDIOQS.GS.HM_playersCalling['player'] or not AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_PVP, AUDIOQS.GS.INSTANCE_SCENARIO) or AUDIOQS.GS.HM_healthSnapshot['player'] >= 1 then AUDIOQS.GS.HM_playersCalling['player'] = false return true end"
		},
		{
			function() return GameState.HM_delaySnapshot['player'] end,
			AUDIOQS.SOUND_FUNC_PREFIX.."return (AUDIOQS_4Q5.HealthMonitor_Dispellable('player') and '"..AUDIOQS.SOUNDS_ROOT.."Numerical/1"..AUDIOQS.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/1.ogg')",
			nil,
			AUDIOQS.PROMPTSEG_CONDITIONAL_REPEATER
		}
	})
t_delims_funcs["%%3"] = cancel_prompt_if_muted; t_delims_parameters["%%3"] = {"party1", true};
t_delims_funcs["%%4"] = cancel_prompt_if_muted; t_delims_parameters["%%4"] = {"party1", false};
table.insert(extSegments["UNIT_HEALTH"], {
		{
			"local AUDIOQS = AUDIOQS_4Q5 %%3 if AUDIOQS.GS.HM_playersCalling['party1'] ~= true and AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_ARENA, AUDIOQS.GS.INSTANCE_SCENARIO) and AUDIOQS.GS.HM_healthSnapshot['party1'] < 1 then AUDIOQS.GS.HM_playersCalling['party1'] = true return true end",
			"local AUDIOQS = AUDIOQS_4Q5 %%4 if not AUDIOQS.GS.HM_playersCalling['party1'] or (not AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_ARENA, AUDIOQS.GS.INSTANCE_SCENARIO) or AUDIOQS.GS.HM_healthSnapshot['party1'] >= 1) then AUDIOQS.GS.HM_playersCalling['party1'] = false return true end"
		},
		{
			function() return GameState.HM_delaySnapshot['party1'] end,
			AUDIOQS.SOUND_FUNC_PREFIX.."return (AUDIOQS_4Q5.HealthMonitor_Dispellable('party1') and '"..AUDIOQS.SOUNDS_ROOT.."Numerical/2"..AUDIOQS.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/2.ogg')",
			nil,
			AUDIOQS.PROMPTSEG_CONDITIONAL_REPEATER
		} 
	})
t_delims_funcs["%%5"] = cancel_prompt_if_muted; t_delims_parameters["%%5"] = {"party2", true};
t_delims_funcs["%%6"] = cancel_prompt_if_muted; t_delims_parameters["%%6"] = {"party2", false};
table.insert(extSegments["UNIT_HEALTH"], {
		{
			"local AUDIOQS = AUDIOQS_4Q5 %%5 if AUDIOQS.GS.HM_playersCalling['party2'] ~= true and AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_ARENA, AUDIOQS.GS.INSTANCE_SCENARIO) and AUDIOQS.GS.HM_healthSnapshot['party2'] < 1 then AUDIOQS.GS.HM_playersCalling['party2'] = true return true end",
			"local AUDIOQS = AUDIOQS_4Q5 %%6 if not AUDIOQS.GS.HM_playersCalling['party2'] or (not AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_ARENA, AUDIOQS.GS.INSTANCE_SCENARIO) or AUDIOQS.GS.HM_healthSnapshot['party2'] >= 1) then AUDIOQS.GS.HM_playersCalling['party2'] = false return true end"
		},
		{
			function() return AUDIOQS.GS.HM_delaySnapshot['party2'] end,
			AUDIOQS.SOUND_FUNC_PREFIX.."return (AUDIOQS_4Q5.HealthMonitor_Dispellable('party2') and '"..AUDIOQS.SOUNDS_ROOT.."Numerical/3"..AUDIOQS.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/3.ogg')",
			nil,
			AUDIOQS.PROMPTSEG_CONDITIONAL_REPEATER
		} 
	})
t_delims_funcs["%%7"] = cancel_prompt_if_muted; t_delims_parameters["%%7"] = {"party3", true};
t_delims_funcs["%%8"] = cancel_prompt_if_muted; t_delims_parameters["%%8"] = {"party3", false};
table.insert(extSegments["UNIT_HEALTH"], {
		{
			"local AUDIOQS = AUDIOQS_4Q5 %%7 if AUDIOQS.GS.HM_playersCalling['party3'] ~= true and AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_ARENA, AUDIOQS.GS.INSTANCE_SCENARIO) and AUDIOQS.GS.HM_healthSnapshot['party3'] < 1 then AUDIOQS.GS.HM_playersCalling['party3'] = true return true end",
			"local AUDIOQS = AUDIOQS_4Q5 %%8 if not AUDIOQS.GS.HM_playersCalling['party3'] or (not AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_ARENA, AUDIOQS.GS.INSTANCE_SCENARIO) or AUDIOQS.GS.HM_healthSnapshot['party3'] >= 1) then AUDIOQS.GS.HM_playersCalling['party3'] = false return true end"
		},
		{
			function() return AUDIOQS.GS.HM_delaySnapshot['party3'] end,
			AUDIOQS.SOUND_FUNC_PREFIX.."return (AUDIOQS_4Q5.HealthMonitor_Dispellable('party3') and '"..AUDIOQS.SOUNDS_ROOT.."Numerical/4"..AUDIOQS.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/4.ogg')",
			nil,
			AUDIOQS.PROMPTSEG_CONDITIONAL_REPEATER
		} 
	})
t_delims_funcs["%%9"] = cancel_prompt_if_muted; t_delims_parameters["%%9"] = {"party4", true};
t_delims_funcs["%%10"] = cancel_prompt_if_muted; t_delims_parameters["%%10"] = {"party4", false};
table.insert(extSegments["UNIT_HEALTH"], {
		{
			"local AUDIOQS = AUDIOQS_4Q5 %%9 if AUDIOQS.GS.HM_playersCalling['party4'] ~= true and AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_ARENA, AUDIOQS.GS.INSTANCE_SCENARIO) and AUDIOQS.GS.HM_healthSnapshot['party4'] < 1 then AUDIOQS.GS.HM_playersCalling['party4'] = true return true end",
			"local AUDIOQS = AUDIOQS_4Q5 %%10 if not AUDIOQS.GS.HM_playersCalling['party4'] or (not AUDIOQS.HealthMonitor_AnyModesTrue(AUDIOQS.GS.INSTANCE_PARTY, AUDIOQS.GS.INSTANCE_ARENA, AUDIOQS.GS.INSTANCE_SCENARIO) or AUDIOQS.GS.HM_healthSnapshot['party4'] >= 1) then AUDIOQS.GS.HM_playersCalling['party4'] = false return true end"
		},
		{
			function() return AUDIOQS.GS.HM_delaySnapshot['party4'] end,
			AUDIOQS.SOUND_FUNC_PREFIX.."return (AUDIOQS_4Q5.HealthMonitor_Dispellable('party4') and '"..AUDIOQS.SOUNDS_ROOT.."Numerical/5"..AUDIOQS.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/5.ogg')",
			nil,
			AUDIOQS.PROMPTSEG_CONDITIONAL_REPEATER
		} 
	})
-- Raid --
t_delims_funcs["%%11"] = cancel_prompt_if_muted; t_delims_parameters["%%11"] = {1, true}; -- Input roles if present
t_delims_funcs["%%12"] = cancel_prompt_if_muted; t_delims_parameters["%%12"] = {1, false};
table.insert(extSegments["UNIT_HEALTH"], {
		{
			"local AUDIOQS = AUDIOQS_4Q5 %%11 if AUDIOQS.GS.HM_raidSegsStarted1 ~= true and AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_RAID) then AUDIOQS.GS.HM_raidSegsStarted1 = true return true end",
			"local AUDIOQS = AUDIOQS_4Q5 %%12 if not AUDIOQS.GS.HM_raidSegsStarted1 or not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_RAID) then AUDIOQS.GS.HM_raidSegsStarted1 = false return true end"
		},
		{
			function() if AUDIOQS.GS.HM_alertPriority[1][1] ~= nil and AUDIOQS.GS.HM_settingAlertsPriorityFlag ~= nil then return AUDIOQS.GS.HM_alertPriority[1][3] else return 0xFFFF end end, -- Return delay answer, or 18 hours.
			nil,
			nil,
			true
		},
		{
			0.0,
			AUDIOQS.SOUND_FUNC_PREFIX.."local AUDIOQS = AUDIOQS_4Q5 if AUDIOQS.GS.HM_informingPlayerRaidN then return nil end local currTime = GetTime() AUDIOQS.GS.HM_previousCallout[AUDIOQS.GS.HM_alertPriority[1][1]] = currTime AUDIOQS.SetPromptTimestamp(currTime) return '"..AUDIOQS.SOUNDS_ROOT.."Numerical/'..(AUDIOQS.GS.HM_alertPriority[1][1])..(AUDIOQS.GS.HM_alertPriority[1][4])..'.ogg'",
			nil,
			AUDIOQS.PROMPTSEG_CONDITIONAL_RESTART
		}
	})
t_delims_funcs["%%13"] = cancel_prompt_if_muted; t_delims_parameters["%%13"] = {2, true}; -- Input roles if present
t_delims_funcs["%%14"] = cancel_prompt_if_muted; t_delims_parameters["%%14"] = {2, false};
table.insert(extSegments["UNIT_HEALTH"], {
		{
			"local AUDIOQS = AUDIOQS_4Q5 %%13 if AUDIOQS.GS.HM_raidSegsStarted2 ~= true and AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_RAID) then AUDIOQS.GS.HM_raidSegsStarted2 = true return true end",
			"local AUDIOQS = AUDIOQS_4Q5 %%14 if not AUDIOQS.GS.HM_raidSegsStarted2 or not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_RAID) then AUDIOQS.GS.HM_raidSegsStarted2 = false return true end"
		},
		{
			function() if GameState.HM_alertPriority[2][1] ~= nil and GameState.HM_settingAlertsPriorityFlag ~= nil then return GameState.HM_alertPriority[2][3] else return 0xFFFF end end, -- Return delay answer, or 18 hours.
			nil,
			nil,
			true
		},
		{
			0.0,
			AUDIOQS.SOUND_FUNC_PREFIX.."local AUDIOQS = AUDIOQS_4Q5 if AUDIOQS.GS.HM_informingPlayerRaidN then return nil end local currTime = GetTime() AUDIOQS.GS.HM_previousCallout[AUDIOQS.GS.HM_alertPriority[2][1]] = currTime AUDIOQS.SetPromptTimestamp(currTime) return '"..AUDIOQS.SOUNDS_ROOT.."Numerical/'..(AUDIOQS.GS.HM_alertPriority[2][1])..(AUDIOQS.GS.HM_alertPriority[2][4])..'.ogg'",
			nil,
			AUDIOQS.PROMPTSEG_CONDITIONAL_RESTART
		}
	})
t_delims_funcs["%%15"] = cancel_prompt_if_muted; t_delims_parameters["%%15"] = {3, true}; -- Input roles if present
t_delims_funcs["%%16"] = cancel_prompt_if_muted; t_delims_parameters["%%16"] = {3, false};
table.insert(extSegments["UNIT_HEALTH"], {
		{
			"local AUDIOQS = AUDIOQS_4Q5 %%15 if AUDIOQS.GS.HM_raidSegsStarted3 ~= true and AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_RAID) then AUDIOQS.GS.HM_raidSegsStarted3 = true return true end",
			"local AUDIOQS = AUDIOQS_4Q5 %%16 if not AUDIOQS.GS.HM_raidSegsStarted3 or not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_RAID) then AUDIOQS.GS.HM_raidSegsStarted3 = false return true end"
		},
		{
			function() if GameState.HM_alertPriority[3][1] ~= nil and GameState.HM_settingAlertsPriorityFlag ~= nil then return GameState.HM_alertPriority[3][3] else return 0xFFFF end end, -- Return delay answer, or 18 hours.
			nil,
			nil,
			true
		},
		{
			0.0,
			AUDIOQS.SOUND_FUNC_PREFIX.."local AUDIOQS = AUDIOQS_4Q5 if AUDIOQS.GS.HM_informingPlayerRaidN then return nil end local currTime = GetTime() AUDIOQS.GS.HM_previousCallout[AUDIOQS.GS.HM_alertPriority[3][1]] = currTime AUDIOQS.SetPromptTimestamp(currTime) return '"..AUDIOQS.SOUNDS_ROOT.."Numerical/'..(AUDIOQS.GS.HM_alertPriority[3][1])..(AUDIOQS.GS.HM_alertPriority[3][4])..'.ogg'",
			nil,
			AUDIOQS.PROMPTSEG_CONDITIONAL_RESTART
		}
	})
-- BattleGround --
t_delims_funcs["%%17"] = cancel_prompt_if_muted; t_delims_parameters["%%17"] = {'focus', true};
t_delims_funcs["%%18"] = battleground_or_generic_focus; t_delims_parameters["%%18"] = {true};
t_delims_funcs["%%19"] = cancel_prompt_if_muted; t_delims_parameters["%%19"] = {'focus', false};
t_delims_funcs["%%20"] = battleground_or_generic_focus; t_delims_parameters["%%20"] = {false};
t_delims_funcs["%%21"] = battleground_or_generic_focus_file; t_delims_parameters["%%20"] = {}
table.insert(extSegments["UNIT_HEALTH"], {
		{
			"local AUDIOQS = AUDIOQS_4Q5 %%17 if AUDIOQS.GS.HM_playersCalling['focus'] ~= true and %%18 and AUDIOQS.GS.HM_healthSnapshot['focus'] < 1 then AUDIOQS.GS.HM_playersCalling['focus'] = true return true end", -- Evaluated and stored as an adjustedHp (Inside HealthMonitor_UpdateHealthSnapshot()), therefore, it is < 1.0 and > 1.0. If any changes are made to the requirements e.g. "I only want to monitor those below 80% hp", then the adjusted hp can be evaluated as ((curr))/0.8
			"local AUDIOQS = AUDIOQS_4Q5 %%19 if not AUDIOQS.GS.HM_playersCalling['focus'] or %%20AUDIOQS.GS.HM_healthSnapshot['focus'] >= 1 then AUDIOQS.GS.HM_playersCalling['focus'] = false return true end"
		},
		{
			function() return GameState.HM_delaySnapshot['focus'] end,
			AUDIOQS.SOUND_FUNC_PREFIX.."local AUDIOQS = AUDIOQS_4Q5 %%21",
			nil,
			AUDIOQS.PROMPTSEG_CONDITIONAL_REPEATER
		}
	})
t_delims_funcs["%%22"] = cancel_prompt_if_muted; t_delims_parameters["%%22"] = {'target', true};
t_delims_funcs["%%23"] = cancel_prompt_if_muted; t_delims_parameters["%%23"] = {'target', false};
table.insert(extSegments["UNIT_HEALTH"], {
		{
			"local AUDIOQS = AUDIOQS_4Q5 %%22 if AUDIOQS.GS.HM_playersCalling['target'] ~= true and AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_BG) and AUDIOQS.GS.HM_healthSnapshot['target'] < 1 then AUDIOQS.GS.HM_playersCalling['target'] = true return true end", -- Evaluated and stored as an adjustedHp (Inside HealthMonitor_UpdateHealthSnapshot()), therefore, it is < 1.0 and > 1.0. If any changes are made to the requirements e.g. "I only want to monitor those below 80% hp", then the adjusted hp can be evaluated as ((curr))/0.8
			"local AUDIOQS = AUDIOQS_4Q5 %%23 if not AUDIOQS.GS.HM_playersCalling['target'] or not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_BG or AUDIOQS.GS.HM_healthSnapshot['target'] >= 1 then AUDIOQS.GS.HM_playersCalling['target'] = false return true end"
		},
		{
			function() return GameState.HM_delaySnapshot['target'] end,
			AUDIOQS.SOUND_FUNC_PREFIX.."return (AUDIOQS_4Q5.HealthMonitor_Dispellable('target') and '"..AUDIOQS.SOUNDS_ROOT.."Numerical/3"..AUDIOQS.DISPEL_FILE_MODIFIER..".ogg' or 'Interface/AddOns/AudioQs/Sounds/Numerical/DBM-Core/Corsica/3.ogg')",
			nil,
			AUDIOQS.PROMPTSEG_CONDITIONAL_REPEATER
		} 
	})
extSegments["GROUP_ROSTER_UPDATE"] = {
		{
			{
				"local AUDIOQS = AUDIOQS_4Q5 if AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_BG) then AUDIOQS.HealthMonitor_UpdateHealthSnapshot() else AUDIOQS.HealthMonitor_CheckMode('GROUP_ROSTER_UPDATE') end return false",
				false
			},
			{1.0, nil, nil, function() AUDIOQS.HealthMonitor_UpdateHealthSnapshot() end} -- This is just a manual 1 second later update to ensure that odd behaviour is caught, like a cutscene of a different area starting in the middle of combat, or an NPC scenario ends by removing all units, and no UNIT_HEALTH to follow.
		},
		{
			{
				"local AUDIOQS = AUDIOQS_4Q5 if AUDIOQS.GS.HM_informingPlayerRaidN == true and AUDIOQS.GS.HM_lastPlayerRaidNSpoken ~= AUDIOQS.GS.HM_playerRaidN and not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_PVP) then AUDIOQS.GS.HM_lastPlayerRaidNSpoken = AUDIOQS.GS.HM_playerRaidN return true end return false",
				"local AUDIOQS = AUDIOQS_4Q5 return AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_PVP) or not UnitIsUnit('player', 'raid'..AUDIOQS.GS.HM_playerRaidN)"
			},
			{
				0.75,
				function() return string.format('Interface/AddOns/AudioQs/Sounds/Numerical/%s.ogg', GameState.HM_playerRaidN) end,
				nil,
				true
			},
			{
				0.85,
				AUDIOQS.SOUND_PATH_PREFIX.."Interface/AddOns/AudioQs/Sounds/Numerical/your_number_is.ogg", 
				nil, 
				AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION
			},
			{
				nil,
				function() GameState.HM_informingPlayerRaidN = false return string.format('Interface/AddOns/AudioQs/Sounds/Numerical/%s.ogg', GameState.HM_playerRaidN) end, 
				nil, 
				AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION
			}
		}
	}
extSegments["ZONE_CHANGED_NEW_AREA"] = {
		{
			{
				function() AUDIOQS.HealthMonitor_CheckMode('ZONE_CHANGED_NEW_AREA') return false end,
				false
			},
			{nil, nil, nil, nil}
		}
	}
extSegments["PLAYER_ENTERING_WORLD"] = {
		{
			{
				function() AUDIOQS.HealthMonitor_CheckMode('PLAYER_ENTERING_WORLD') AUDIOQS.HealthMonitor_UpdateHealthSnapshot() return false end,
				false
			},
			{nil, nil, nil, nil}
		},
		{
			{
				function() return GameState.HM_informingPlayerRaidN == true end,
				function() return not UnitIsUnit('player', 'raid'..GameState.HM_playerRaidN) end
			},
			{
				0.75,
				function() return string.format('Interface/AddOns/AudioQs/Sounds/Numerical/%s.ogg', GameState.HM_playerRaidN) end, 
				nil, 
				true
			},
			{
				0.85,
				AUDIOQS.SOUND_PATH_PREFIX.."Interface/AddOns/AudioQs/Sounds/Numerical/your_number_is.ogg", 
				nil, 
				AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION
			},
			{
				nil,
				function() GameState.HM_informingPlayerRaidN = false return string.format('Interface/AddOns/AudioQs/Sounds/Numerical/%s.ogg', AUDIOQS.GS.HM_playerRaidN) end, 
				nil, 
				AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION
			}
		}
	}
extSegments["UPDATE_BATTLEFIELD_STATUS"] = {
		{
			{
				function() AUDIOQS.HealthMonitor_CheckModePvP() return false end,
				false
			},
			{nil, nil, nil, nil}
		}
	}
extSegments["UNIT_MODEL_CHANGED"] = {
		{
			{
				function() AUDIOQS.HealthMonitor_UpdateHealthSnapshot() return true end,
				false
			},
			{0.2, nil, nil, true},
			{function() AUDIOQS.HealthMonitor_UpdateHealthSnapshot() return nil end, nil, nil, AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION}
		}
	}
extSegments["UNIT_MAXHEALTH"] = {
		{
			{
				function() AUDIOQS.HealthMonitor_UpdateHealthSnapshot() return false end,
				false
			},
			{nil, nil, nil, nil}
		}
	}
extSegments["PLAYER_DEAD"] = {
		{
			{
				function() AUDIOQS.HealthMonitor_UpdateHealthSnapshot() return false end,
				false
			},
			{nil, nil, nil, nil}
		}
	}
if not AUDIOQS.WOW_CLASSIC then
	AUDIOQS.AmmendTable(
			extSegments,
			{
				["PLAYER_SPECIALIZATION_CHANGED"] = {
					{
						{
							function() AUDIOQS.HealthMonitor_CheckMode('PLAYER_SPECIALIZATION_CHANGED') return false end,
							false
						},
						{nil, nil, nil, nil}
					}
				}
			}
	)
end
-- -- << Set those

-- --- Set these >> (At will -- For detailed custom code)
local function SetGenericHpVals(unitId, setToOff)
	if unitId == nil then return end
	if UnitExists(unitId) and not setToOff and --[[UnitIsPlayer(unitId) and]] not UnitIsDeadOrGhost(unitId) then
		local adjustedHp = ((UnitHealth(unitId)/UnitHealthMax(unitId))-0.1)/0.80
		AUDIOQS.GS.HM_healthSnapshot[unitId] = adjustedHp
		AUDIOQS.GS.HM_delaySnapshot[unitId] = (0.4 + 2.0*math.max(0, adjustedHp)^1.6)
	else
		AUDIOQS.GS.HM_healthSnapshot[unitId] = 1.0
		AUDIOQS.GS.HM_delaySnapshot[unitId] = 0xFFFF -- 18 hours
	end
end

reset_players_calling = function()
	local playersCalling = GameState.HM_playersCalling
	if playersCalling then 
		for k,_ in pairs(playersCalling) do
			playersCalling[k] = false
		end
		GameState.HM_raidSegsStarted1 = false
		GameState.HM_raidSegsStarted2 = false
		GameState.HM_raidSegsStarted3 = false
	end
end

function AUDIOQS.HealthMonitor_Dispellable(unitId)
	local aura
	if thisSpecDispels then
		for j=1, 40, 1 do
			aura = AUDIOQS.LoadAura(unitId, j, "HARMFUL")
			if aura[AUDIOQS.UNIT_AURA_SPELL_ID] == nil then break end 
			
			local debuffType = aura[AUDIOQS.UNIT_AURA_DEBUFF_TYPE]
			
			for n=1,#thisSpecDispels,1 do
				if debuffType == thisSpecDispels[n] then
					return true
				end
			end
		end
	end
	return false
end

function AUDIOQS.HealthMonitor_ModeIs(modeToCheck)
	if AUDIOQS.GS.HM_mode == nil or modeToCheck == nil then -- Avoid nil arithmetic
		if modeToCheck == nil and AUDIOQS.GS.HM_mode == nil then
			return true
		else
			return false
		end
	elseif modeToCheck % AUDIOQS.GS.INSTANCE_PVMAG == 0 then 	-- Check PvMode
		return mFloor(AUDIOQS.GS.HM_mode / AUDIOQS.GS.INSTANCE_PVMAG) == mFloor(modeToCheck / AUDIOQS.GS.INSTANCE_PVMAG)
	else										-- Check Instance Type
		return AUDIOQS.GS.HM_mode == modeToCheck
	end
end

-------- AUDIOQS.HealthMonitor_AnyModesTrue()
function AUDIOQS.HealthMonitor_AnyModesTrue(...)
	local modesToCheck = modesToCheck
	modesToCheck[1], modesToCheck[2], modesToCheck[3], modesToCheck[4], modesToCheck[5], modesToCheck[6], modesToCheck[7], modesToCheck[8], modesToCheck[9] = ... -- A line of Lua code. (...see previous commit)

	local i = 1
	local mode = modesToCheck[i]
	while mode ~= nil do
		if AUDIOQS.HealthMonitor_ModeIs(mode) then
			return true
		end
		i = i+1
		mode = modesToCheck[i]
	end
	return false
end

function AUDIOQS.HealthMonitor_UpdateHealthSnapshot()
	local numInGroup = GetNumGroupMembers()

	if AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_BG) then
		for n=1,3,1 do
			local thisUnit = (n == 3 and "target" or (n == 2 and "focus" or (n == 1 and "player")))
			if UnitIsDeadOrGhost("player") -- Do not update this unitId if the player is dead, or a more strongly defined unitId exists for the unit, or it is an enemy.
					or ( thisUnit == "target" and ( UnitIsUnit(thisUnit, "player") or UnitIsUnit(thisUnit, "focus") ) ) 
					or ( thisUnit == "focus" and UnitIsUnit(thisUnit, "player") ) 
					or UnitIsEnemy("player", thisUnit) then
				SetGenericHpVals(thisUnit, true) -- Set to off. 
			else -- Update a unit that is in alive state
				SetGenericHpVals(thisUnit)
			end
		end
	else
		if AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_PARTY)
				or AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_ARENA) then
			for n=1,5,1 do -- TODO Iterate over partyUnitIds[n]
				local thisUnit = AUDIOQS.GS.HM_unitIds[n]
				SetGenericHpVals(thisUnit)
			end
		elseif AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_RAID) then
			AUDIOQS.HealthMonitor_CheckLowestForRaid()
		end
		if CONFIG__track_focus then
			if UnitIsUnit('focus', 'player') or UnitIsUnit('focus', 'party1') or UnitIsUnit('focus', 'party2') or UnitIsUnit('focus', 'party3') or UnitIsUnit('focus', 'party4') then
				SetGenericHpVals('focus', true)
			else
				SetGenericHpVals('focus')
			end
		end
	end
end

function AUDIOQS.HealthMonitor_SetPreviousCallout(unitNum, timestamp)
	AUDIOQS.GS.HM_previousCallout[unitNum] = timestamp
end

function AUDIOQS.HealthMonitor_CheckMode(event)
	local instanceName, instanceType = GetInstanceInfo()
	
	if GameState.HM_initialized ~= true then
		GameState.HM_ALERT_UNIT_NUM = 1
		GameState.HM_ALERT_HP_PERCENTAGE = 2
		GameState.HM_ALERT_MAX_ALERTS = 3
		GameState.HM_ASSIGNED_NUMBER_SENTENCE_PART_1 = 1
		GameState.HM_ASSIGNED_NUMBER_SENTENCE_PART_2 = 2
		GameState.HM_ASSIGNED_NUMBER_SENTENCE_PART_3 = 3
		GameState.HM_ASSIGNED_NUMBER_SENTENCE_LENGTH_1 = 0.75
		GameState.HM_ASSIGNED_NUMBER_SENTENCE_LENGTH_2 = 0.85
		
		GameState.HM_playersCalling = {}
		GameState.HM_healthSnapshot = {}
		GameState.HM_delaySnapshot = {}
		
		-- Raid only (Doesn't hurt having 4 empty tables for party, vs a "raidInitialized" variable checked every group_roster_update)
		GameState.HM_unitIds = {} 
		GameState.HM_raidUnitsIncluded = {}
		GameState.HM_previousCallout = {}
		GameState.HM_raidSegStarted = {}
		GameState.HM_alertPriority = {}
		
		GameState.HM_mode = nil
		GameState.HM_instanceType = nil
		
		thisSpecDispels = SPEC_DISPEL_TYPES[AUDIOQS.GetSpecId()]
		
		for n=1,AUDIOQS.GS.HM_ALERT_MAX_ALERTS,1 do
			table.insert(AUDIOQS.GS.HM_alertPriority, {nil, 100, 0xFFFF})
		end
		
		AUDIOQS.GS.HM_initialized = true
	end
	
	if event == "PLAYER_SPECIALIZATION_CHANGED" then 
		thisSpecDispels = SPEC_DISPEL_TYPES[AUDIOQS.GetSpecId()]
	end
    
    if (instanceType == "pvp" or instanceType == "arena") then 
		if not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_PVP) then
			if AUDIOQS.GS.HM_mode ~= nil then 
				print(AUDIOQS.audioQsSpecifier..extensionSpecifier..(AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_PARTY) and "Party" or "Raid").." health call-out stopped.")
			end
			AUDIOQS.HealthMonitor_CheckModePvP()
		end
    elseif AUDIOQS.GS.HM_instanceType ~= instanceType or event == "GROUP_ROSTER_UPDATE" or (IsInRaid() and AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_PARTY) or (not IsInRaid() and AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_RAID))) then
		AUDIOQS.GS.HM_instanceType = instanceType
        
        AUDIOQS.GS.HM_numInGroup = (GetNumGroupMembers() > 0 and GetNumGroupMembers() or 1)
        
        if IsInRaid() then -- Raid mode (PvE)
			local j = 1
            for n = 1, 40, 1 do
                local thisId = string.format("raid%s", n)
				AUDIOQS.GS.HM_unitIds[n] = thisId
                if UnitExists(thisId) then 
                    AUDIOQS.GS.HM_raidUnitsIncluded[j] = thisId
					j = j + 1
                end
				AUDIOQS.GS.HM_previousCallout[n] = 0
				if UnitIsUnit("player", thisId) and AUDIOQS.GS.HM_playerRaidN ~= n and event == "GROUP_ROSTER_UPDATE" then
					AUDIOQS.GS.HM_informingPlayerRaidN = true
					AUDIOQS.GS.HM_playerRaidN = n
				end
            end
			
			for n=1,GetNumGroupMembers(),1 do
				local thisId = "raid"..n
				AUDIOQS.GS.HM_healthSnapshot[thisId] = 1.0
				AUDIOQS.GS.HM_delaySnapshot[thisId] = nil
			end
            
            if not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_RAID) then   
                if AUDIOQS.GS.HM_mode ~= nil then 
                    print(AUDIOQS.audioQsSpecifier..AUDIOQS.extensionColour.."<HealthMonitor>"..
						"|r: Switched to Raid health call-out.")
                else
                    print(AUDIOQS.audioQsSpecifier..AUDIOQS.extensionColour.."<HealthMonitor>"..
						"|r: Raid health call-out started.")
                end
                
                AUDIOQS.GS.HM_mode = AUDIOQS.GS.INSTANCE_RAID
            end
        elseif not IsInRaid() and not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_PARTY) then -- Party and World Mode (PvE)   
            AUDIOQS.GS.HM_unitIds = {"player", "party1", "party2", "party3", "party4"}
			
			AUDIOQS.GS.HM_playersCalling["player"] = false
			AUDIOQS.GS.HM_healthSnapshot["player"] = 1.0
			AUDIOQS.GS.HM_delaySnapshot["player"] = 0xFFFF
			for n = #AUDIOQS.GS.HM_unitIds - 1, 1, -1 do
				thisId = string.format("party%s", n)
				AUDIOQS.GS.HM_playersCalling[thisId] = false
				AUDIOQS.GS.HM_healthSnapshot[thisId] = 1.0
				AUDIOQS.GS.HM_delaySnapshot[thisId] = 0xFFFF
			end
			
            if AUDIOQS.GS.HM_mode ~= nil then
                print(AUDIOQS.audioQsSpecifier..AUDIOQS.extensionColour.."<HealthMonitor>".."|r: Switched to Party health call-out.")
            else
                print(AUDIOQS.audioQsSpecifier..AUDIOQS.extensionColour.."<HealthMonitor>".."|r: Party health call-out started.")
            end
            
            AUDIOQS.GS.HM_mode = AUDIOQS.GS.INSTANCE_PARTY
        end
        
		AUDIOQS.HealthMonitor_UpdateHealthSnapshot()
		
        return
    end
end

local GetRaidRosterInfo = GetRaidRosterInfo
local function raid_index_group_muted(raidIndex)
	local _, _, group = GetRaidRosterInfo(raidIndex)
	return current_muted_groups_table[group]
end

function AUDIOQS.HealthMonitor_CheckLowestForRaid() -- Raid mode
	AUDIOQS.GS.HM_settingAlertsPriorityFlag = true
	local alertPriorityTable = AUDIOQS.GS.HM_alertPriority
	
	for n=1,AUDIOQS.GS.HM_ALERT_MAX_ALERTS,1 do -- TODO Read Lua scope / Garbage collection tute. May not need this.
		local thisAlertPriority = alertPriorityTable[n]
		thisAlertPriority[1] = nil
		thisAlertPriority[2] = 100
		thisAlertPriority[3] = 0xFFFF
		thisAlertPriority[4] = AUDIOQS.NO_FILE_MODIFIER
	end
	
	local doNotCheckGroups = not CHECK_GROUP_MUTES
	
	for i = 1, 40, 1 do
		local unitId = AUDIOQS.GS.HM_unitIds[i]
		
		if not UnitIsDeadOrGhost(unitId) and 
				AUDIOQS.GS.HM_raidUnitsIncluded[i] and
				UnitExists(unitId)
				and (doNotCheckGroups or not raid_index_group_muted(i)) then
			local unitIncHeals = math.max(0, UnitGetIncomingHeals(unitId))
			local unitHpPercentage = 
			(UnitHealth(unitId) + unitIncHeals) / UnitHealthMax(unitId)
			
			if unitHpPercentage < 0.95 then
				local n = 1
				local inserted = false
				local prevNum = nil
				local prevHp = nil
				local prevDelay = nil
				local adjustedHp = unitHpPercentage
				
				-- dev note: CHECK_ROLE_ASSIGNMENT was an incorrect 'less-than' build vers 30300, the patch of the addition of *shudders* LFG
				if unitId == "player" or CHECK_ROLE_ASSIGNMENT and UnitGroupRolesAssigned(unitId) == "TANK" then
					adjustedHp = math.max(0, 0.5*math.log(0.3*adjustedHp) + 1.4)
				end
				
				while n <= AUDIOQS.GS.HM_ALERT_MAX_ALERTS do -- i.e. typically (n=1;n<=3;n++)
					local thisUnitAlertPriorityTable = alertPriorityTable[n]
					if inserted == true then
						local nextNum = thisUnitAlertPriorityTable[1]
						local nextHp = thisUnitAlertPriorityTable[2]
						local nextDelay = thisUnitAlertPriorityTable[3]
						
						thisUnitAlertPriorityTable[1] = prevNum
						thisUnitAlertPriorityTable[2] = prevHp
						thisUnitAlertPriorityTable[3] = prevDelay
						
						prevNum = nextNum
						prevHp = nextHp
						prevDelay = nextDelay
					elseif adjustedHp < thisUnitAlertPriorityTable[2] then
						prevNum = thisUnitAlertPriorityTable[1]
						prevHp = thisUnitAlertPriorityTable[2]
						prevDelay = thisUnitAlertPriorityTable[3]

						thisUnitAlertPriorityTable[1] = i
						thisUnitAlertPriorityTable[2] = adjustedHp
						thisUnitAlertPriorityTable[3] = 3.0 / (1 + math.exp(-4*(math.pow(adjustedHp, 2)-0.4)))
						
						inserted = true
					end
					n = n + 1
				end
			end
		end
	end
	for n=1, AUDIOQS.GS.HM_ALERT_MAX_ALERTS, 1 do
		local unitId = AUDIOQS.GS.HM_unitIds[AUDIOQS.GS.HM_alertPriority[n][1]]
		if unitId ~= nil and AUDIOQS.HealthMonitor_Dispellable(unitId) then
			AUDIOQS.GS.HM_alertPriority[n][4] = AUDIOQS.DISPEL_FILE_MODIFIER
		end
	end
	AUDIOQS.GS.HM_settingAlertsPriorityFlag = false
end

function AUDIOQS.HealthMonitor_CheckModePvP()
	local instanceName, instanceType, _, _, _, _, _, instanceId = GetInstanceInfo()
	
--if AUDIOQS.VERBOSE then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."Checking PvP Mode. name =", instanceName, "; instanceType =", instanceType, "; winner =", GetBattlefieldWinner(), ";") end
    
    if AUDIOQS.GS.HM_instanceCompletedOrNotBg == true then
        if AUDIOQS.GS.HM_instanceId == instanceId then
            return
        else
			AUDIOQS.GS.HM_instanceId = instanceId
			AUDIOQS.GS.HM_instanceCompletedOrNotBg = false
        end
    end
    
    if AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_PVP) and
    (GetBattlefieldWinner() ~= nil or not (instanceType == "pvp" or instanceType == "arena")) then
		AUDIOQS.GS.HM_instanceCompletedOrNotBg = true
		AUDIOQS.GS.HM_instanceId = instanceId
		AUDIOQS.GS.HM_mode = nil
        return
    elseif (instanceType == "pvp" or instanceType == "arena") and not AUDIOQS.HealthMonitor_ModeIs(AUDIOQS.GS.INSTANCE_PVP) then
		AUDIOQS.GS.HM_instanceType = instanceType
		AUDIOQS.GS.HM_instanceId = instanceId
        
        AUDIOQS.GS.HM_mode = (instanceType == "pvp" and AUDIOQS.GS.INSTANCE_BG or AUDIOQS.GS.INSTANCE_ARENA)
		
		AUDIOQS.HealthMonitor_UpdateHealthSnapshot()
		
        print(AUDIOQS.audioQsSpecifier..AUDIOQS.extensionColour.."<HealthMonitor>".."|r: "..(instanceType == "pvp" and "Battleground" or "Arena").." health call-out started.")
    end
end
-- -- << Set those

-- Register Extension:
ext_ref_num = AUDIOQS.RegisterExtension(extName, extFuncs)