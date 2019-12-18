-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

------- Error Codes --
--
AQ.ERR_UNKNOWN =										0xEFF0
AQ.ERR_INVALID_ARGS = 									0xEFF1
AQ.ERR_UNEXPECTED_RETURN_VALUE =						0xEFF2
AQ.ERR_UNKNOWN_SPELL_AS_ARGUMENT = 						0xEFF3
AQ.ERR_UNKNOWN_EVENT_AS_ARGUMENT =						0xEFF4
AQ.ERR_INVALID_AURA_DATA =								0xEFF5
AQ.ERR_INVALID_SOUND_DATA = 							0xEFF6
AQ.ERR_INVALID_CONDITIONAL_RESULT =						0xEFF7
AQ.ERR_CUSTOM_FUNCTION_RUNTIME =						0XEFF8
--
------ /Error Codes --

------- Default Msgs --
--
AQ.audioQsSpecifier = "|cff50C0F0[AudioQs]".."|r "
AQ.infoSpecifier = "|cff50A0FF<INFO>".."|r: "
AQ.debugSpecifier = "|cffF080F0<DEBUG>".."|r: "
AQ.errSpecifier = "|cffC01050<ERR>".."|r: "
AQ.ERR_MSGS = { 
	[AQ.ERR_UNKNOWN] =
		AQ.audioQsSpecifier..
		AQ.errSpecifier..
		"#"..AQ.ERR_UNKNOWN.." "..
		"Unknown error.",
	[AQ.ERR_INVALID_ARGS] =
		AQ.audioQsSpecifier..
		AQ.errSpecifier..
		"#"..AQ.ERR_INVALID_ARGS.." "..
		"Invalid args.",
	[AQ.ERR_UNEXPECTED_RETURN_VALUE] =
		AQ.audioQsSpecifier..
		AQ.errSpecifier..
		"#"..AQ.ERR_INVALID_ARGS.." "..
		"An unexpected or impossible result was returned from a function.",
	[AQ.ERR_UNKNOWN_SPELL_AS_ARGUMENT] = 
		AQ.audioQsSpecifier..
		AQ.errSpecifier..
		"#"..AQ.ERR_UNKNOWN_SPELL_AS_ARGUMENT.." "..
		" An unlisted spellId was passed to a function.",
	[AQ.ERR_UNKNOWN_EVENT_AS_ARGUMENT] = 
		AQ.audioQsSpecifier..
		AQ.errSpecifier..
		"#"..AQ.ERR_UNKNOWN_SPELL_AS_ARGUMENT.." "..
		" An unlisted event was passed to a function.",
	[AQ.ERR_INVALID_AURA_DATA] = 
		AQ.audioQsSpecifier..
		AQ.errSpecifier..
		"#"..AQ.ERR_INVALID_AURA_DATA.." "..
		" Data passed to a function did not contain a valid aura table.",
	[AQ.ERR_INVALID_SOUND_DATA] = 
		AQ.audioQsSpecifier..
		AQ.errSpecifier..
		"#"..AQ.ERR_INVALID_AURA_DATA.." "..
		" Sound data retreived from a segment was neither a number nor a filepath.",
	[AQ.ERR_INVALID_CONDITIONAL_RESULT] =
		AQ.audioQsSpecifier..
		AQ.errSpecifier..
		"#"..AQ.ERR_INVALID_CONDITIONAL_RESULT.." "..
		" An invalid result was derived from a segment conditional",
	[AQ.ERR_CUSTOM_FUNCTION_RUNTIME] = 
		AQ.audioQsSpecifier..
		AQ.errSpecifier..
		"#"..AQ.ERR_CUSTOM_FUNCTION_RUNTIME.." "..
		" Runtime error occured in CustomFunc."
}
AQ.extensionColour = "|cffFFA020"
AQ.STOP_ERROR_MAX_REPORTS = AQ.audioQsSpecifier.." Max errors exceeded. Stopping error reports."
--
------ /Default msgs --

------- Static vals --
--
local MAX_ERRORS_PER_SESSION = 3
local DUPLICATE_ERROR_GARBAGE_TIMER = 3.0
--
------ /Static vals --

------- AddOn variables --
--
local errorsThisSession = 0
local mostRecentErrorString = nil
local mostRecentErrorTimestamp = 0

local currentlyEvaluatingAura = {"", 0, 0, "", 0, 0, "", false, false, 0, false, false, false, false, 0}
local currentlyEvaluatingCombatLog = {0, "", false, "", "", 0, 0, "", "", 0, 0}
--
------ /AddOn variables --

SLASH_AQ1 = "/aq"

local Frame_OnLoadMessages = CreateFrame("Frame", "On Load Messages")
Frame_OnLoadMessages:RegisterEvent("PLAYER_ENTERING_WORLD")
Frame_OnLoadMessages:SetScript("OnEvent", function() if SV_Specializations ~= nil and SV_Specializations["nextLoadMessage"] ~= nil then print(SV_Specializations["nextLoadMessage"]) SV_Specializations["nextLoadMessage"] = nil end end)

-- SLASH COMMANDS --
SlashCmdList["AQ"] = function(msg)
	local args = AQ.SplitString(msg, "%s")
	if args ~= nil then 
 		----- INSTALL -----
		if (args[1] == "load" or args[1] == "install") and args[2] ~= nil then
			local mySpecInfo = {AQ.GetSpec()}
			local mySpec = mySpecInfo[AQ.SPEC_INFO_NUM]
			local funcs = AQ.GetExtensionFuncs(args[2])
			
			if funcs == nil then
				print(AQ.audioQsSpecifier..AQ.infoSpecifier.."Extension \""..args[2].."\" is not available.\nRegistered extensions are:\n"..AQ.PrintableTable(AQ.GetRegisteredExtensionNames()))
				return
			elseif SV_Specializations ~= nil and SV_Specializations[mySpec] ~= nil and SV_Specializations[mySpec][funcs["GetName"]()] ~= nil then
				print(AQ.audioQsSpecifier..AQ.infoSpecifier.."Extension \""..funcs["GetName"]().."\" is already installed.") -- TODO Placeholder, informative, but messy output.
				return
			end
			
			if funcs["SpecAllowed"](mySpec) then
				AQ.GSI_LoadSpecTables(mySpec, funcs)
				AQ.SetAbilityAndAuraTables(AQ.InitializePrompts(mySpec))
				AQ.ReregisterEvents()
				ReloadUI()
				SV_Specializations["nextLoadMessage"] = AQ.audioQsSpecifier..AQ.infoSpecifier.."Loaded: "..funcs["GetNameDetailed"]()
				return --- Loaded
			else
				print(AQ.audioQsSpecifier..AQ.infoSpecifier.."Failed! Extension \""..funcs["GetName"]().."\" is not able to be loaded for "..mySpecInfo[AQ.SPEC_INFO_NAME].." (spec "..mySpec..").")
				return --- Spec not allowed
			end
		----- REMOVE -----
		elseif (args[1] == "remove" or args[1] == "uninstall" or args[1] == "unload") and args[2] ~= nil then
			local mySpecInfo = {AQ.GetSpec()}
			local mySpec = mySpecInfo[AQ.SPEC_INFO_NUM]
			local extName = args[2]
			local funcs = AQ.GetExtensionFuncs(extName)
			if funcs == nil or SV_Specializations == nil or SV_Specializations[mySpec] == nil or SV_Specializations[mySpec][funcs["GetName"]()] == nil then
				print(AQ.audioQsSpecifier..AQ.infoSpecifier.."Extension \""..extName.."\" is not loaded.\nLoaded extensions are:\n"..AQ.PrintableTable(SV_Specializations == nil and "nil" or SV_Specializations[mySpec])) -- TODO Placeholder, informative, but messy output.
				return
			else
				if AQ.GSI_RemoveExtension(mySpec, funcs["GetName"]()) then
					AQ.SetAbilityAndAuraTables(AQ.InitializePrompts(mySpec))
					AQ.ReregisterEvents()
					ReloadUI()
					SV_Specializations["nextLoadMessage"] = AQ.audioQsSpecifier..AQ.infoSpecifier.."Removed: "..funcs["GetNameDetailed"]()
					return
				else
					AQ.HandleError({code=AQ.ERR_UNEXPECTED_RETURN_VALUE}, "SlashCmdList()", "GSI_RemoveExtension("..AQ.Printable(mySpec)..", "..AQ.Printable(extName)..")")
					return
				end
			end
		----- HUSH ON -----
		elseif args[1] == "hush" or args[1] == "quiet" or args[1] == "stop" or args[1] == "shh" or args[1] == "off" then
			if AQ.hushMode == AQ.HUSHMODE_OFF then
				AQ.hushMode = AQ.HUSHMODE_USER
				print(AQ.audioQsSpecifier..AQ.infoSpecifier.."Hush mode on. Type \"/aq go\" in chat to enable AudioQs.")
				return
			else
				print(AQ.audioQsSpecifier..AQ.infoSpecifier.."Hush mode is already on. Type \"/aq go\" in chat to enable AudioQs.")
				return
			end
		----- HUSH OFF -----
		elseif args[1] == "start" or args[1] == "begin" or args[1] == "go" or args[1] == "on" then
			if AQ.hushMode ~= AQ.HUSHMODE_OFF then 
				AQ.hushMode = AQ.HUSHMODE_OFF
				print(AQ.audioQsSpecifier..AQ.infoSpecifier.."Hush mode off. AudioQs has been enabled.")
				return
			else
				print(AQ.audioQsSpecifier..AQ.infoSpecifier.."AudioQs is already enabled.")
				return
			end
		----- RESET -----
		elseif args[1] == "reset" then
			AQ.GSI_ResetAudioQs()
			ReloadUI()
			SV_Specializations["nextLoadMessage"] = AQ.audioQsSpecifier..AQ.infoSpecifier.."AudioQs set to default."
			return
		end
	end
	print(AQ.audioQsSpecifier..AQ.infoSpecifier.."Invalid command.")
end

function AQ.LoadAura(unitId, num, filter)
	currentlyEvaluatingAura[1], currentlyEvaluatingAura[2], currentlyEvaluatingAura[3], 
		currentlyEvaluatingAura[4], currentlyEvaluatingAura[5], currentlyEvaluatingAura[6], 
		currentlyEvaluatingAura[7], currentlyEvaluatingAura[8], currentlyEvaluatingAura[9],
		currentlyEvaluatingAura[10], currentlyEvaluatingAura[11], currentlyEvaluatingAura[12],
		currentlyEvaluatingAura[13], currentlyEvaluatingAura[14], currentlyEvaluatingAura[15],
		currentlyEvaluatingAura[16] 
		= UnitAura(unitId, num, filter)
		
	return currentlyEvaluatingAura
end

function AQ.LoadCombatLog()
	currentlyEvaluatingCombatLog[1], currentlyEvaluatingCombatLog[2], currentlyEvaluatingCombatLog[3],
		currentlyEvaluatingCombatLog[4], currentlyEvaluatingCombatLog[5], currentlyEvaluatingCombatLog[6],
		currentlyEvaluatingCombatLog[7], currentlyEvaluatingCombatLog[8], currentlyEvaluatingCombatLog[9],
		currentlyEvaluatingCombatLog[10], currentlyEvaluatingCombatLog[11], currentlyEvaluatingCombatLog[12],
		currentlyEvaluatingCombatLog[13], currentlyEvaluatingCombatLog[14], currentlyEvaluatingCombatLog[15],
		currentlyEvaluatingCombatLog[16], currentlyEvaluatingCombatLog[17], currentlyEvaluatingCombatLog[18],
		currentlyEvaluatingCombatLog[19], currentlyEvaluatingCombatLog[20], currentlyEvaluatingCombatLog[21],
		currentlyEvaluatingCombatLog[22], currentlyEvaluatingCombatLog[23], currentlyEvaluatingCombatLog[24]
		= CombatLogGetCurrentEventInfo()
	
	return currentlyEvaluatingCombatLog
end

function AQ.SplitString(str, splitter)
	if str == nil or splitter == nil then
		error({code=AQ.ERR_INVALID_ARGS, func="splitString(str = "..(str == nil and "nil" or str)..", splitter = "..(splitter == nil and "nil" or splitter)..")"})
	end
	local str_arr = {}
	local i = 1
	for sub in str:gmatch(string.format("[^%s]+", splitter)) do
		str_arr[i] = sub
		i = i + 1
	end
	return str_arr
end

function AQ.Print(formatString, ...)
end

function AQ.GetSpec()
	if AQ.WOW_CLASSIC then
		local class = {C_PlayerInfo.GetClass(PlayerLocation:CreateFromUnit("player"))}
		return class[AQ.CLC_PLAYERLOCATION_CLASS_ID], class[AQ.CLC_PLAYERLOCATION_NAME]
	else
		return GetSpecializationInfo(GetSpecialization())
	end
end

function AQ.GetGcdDur()
	return select(2, GetSpellCooldown(AQ.SPELLID_GCD))
end

function AQ.Printable(val)
	local t = type(val)
	if val == nil then return "nil"
	elseif t == "number" or t == "string" then return val
	elseif t == "boolean" then return (val and "true" or "false")
	elseif t == "table" then return "[tbl]"
	elseif t == "function" then return "[func]"
	elseif t == "userdata" then return "[ud]"
	elseif t == "thread" then return "[thread]"
	end
	return "[WTF]"
end

-- TODO "Nicer"
function AQ.PrintableTable(tbl, depth)
	if depth == nil then depth = 0 elseif depth > 7 then return AQ.Printable(tbl) end
	if type(tbl) ~= "table" then
		return AQ.Printable(tbl)..", "
	end
	local str = "{\n "
	for k,v in pairs(tbl) do
		str = str.."["..AQ.Printable(k).."]="..AQ.PrintableTable(v, depth + 1)
	end
	return str.."}\n"
end

function AQ.TablePrint(tbl)
	local newLineSplit = AQ.PrintableTable(tbl)
	newLineSplit = newLineSplit:gmatch("[^\n]+")
	
	for sub in newLineSplit do
		print(sub)
	end
end

-- Will overwrite any matching keys from ammended into tbl. .'. use sparingly, and often only for conditional table creation on the moment of it's creation.
function AQ.AmmendTable(tbl, ammended)
	for k,v in pairs(ammended) do
		tbl[k] = v
	end
end

function AQ.TableEmpty(tbl)
	if tbl == nil then return true end
	for _,_ in pairs(tbl) do
		return false
	end
	return true
end

-------- AQ.LogError()
function AQ.LogError(err, parent, child, detailed)
	AQ.HandleError(err, parent, child)
	errMsg = ((err ~= nil and err.code ~= nil) and "<#"..err.code..">" or "<No ErrCode>")..".."..((parent ~= nil and parent ~= "") and parent or "???()").."->"..((child ~= nil and child ~= "") and child or "???()")..(detailed ~= nil and "..'"..detailed.."'" or "")
	
	if SV_Specializations["errorLog"] == nil then 
		SV_Specializations["errorLog"] = {} 
	end
	
	if SV_Specializations["errorLog"][1] ~= errMsg or SV_Specializations["errorLog"][2] ~= errMsg then -- TODO, was meant for simple repetition dampening, needs better agthm.
		table.insert(SV_Specializations["errorLog"], 1, errMsg)
		while (#SV_Specializations["errorLog"] > 50) do
			table.remove(SV_Specializations["errorLog"], 51) 
		end
	end
end

-- Needs automatic arguments string concats, errors need args={val1,val2}
-------- AQ.HandleError()
function AQ.HandleError(err, parent, child)
	if not AQ.DEBUG and errorsThisSession >= MAX_ERRORS_PER_SESSION then 
		return
	end
	
	if type(err) == "table" then 
		if err.code == nil then err.code = ERR_UNKNOWN end
	elseif err == nil then 
		err = {code=ERR_UNKNOWN}
	end
	
	-- Formulate full string --
	local msgGiven = (type(err) == "string" and err or "")
	local errorString = ""
	local funcString = (err.func~=nil and " func:"..err.func or ((parent~=nil and parent ~= "") and parent or "???").."->"..((child ~= nil and child ~= "") and child or "???"))
	
	if type(err.code) == "number" then 
		local errMsg = AQ.ERR_MSGS[err.code]
		errorString = (errMsg~=nil and errMsg or "[InvalidErrCode]").." "..funcString
	else
		errorString = AQ.ERR_MSGS[AQ.ERR_UNKNOWN].." "..msgGiven.." "..funcString
	end
	
	-- Check error frequency of duplicates is not too high, and print. --
	local currTime = GetTime()
	if not (errorString == mostRecentErrorString and
			currTime < mostRecentErrorTimestamp + DUPLICATE_ERROR_GARBAGE_TIMER) then
		mostRecentErrorString = errorString
		mostRecentErrorTimestamp = currTime
		
		print(errorString)
		
		errorsThisSession = errorsThisSession + 1
		if not AQ.DEBUG and errorsThisSession >= MAX_ERRORS_PER_SESSION then
			print(AQ.STOP_ERROR_MAX_REPORTS)
		end
	end
end

-- TEST (Incomplete -- Bad Refactor)
AQ.Perf = {}
AQ.CurrFrame = 0
function AQ.PerformanceStart(area_str)
	if not AQ.DEBUG then return end
	if AQ.Perf[area_str] == nil then
		AQ.Perf[area_str] = {{0, 0}, {0, 0}, false}
	end
	local newFrame = GetTime() > AQ.CurrFrame
	
	UpdateAddOnMemoryUsage()
	
	AQ.Perf[area_str][1][1] = debugprofilestop()
	AQ.Perf[area_str][2][1] = GetAddOnMemoryUsage("AudioQs")
	
	if newFrame or AQ.Perf[area_str][3] == false then
		AQ.CurrFrame = GetTime()
		
		AQ.PerformancePrint(area_str)
		if newFrame then
			for _, area in pairs(AQ.Perf) do
				area[3] = false
			end
		end
		AQ.Perf[area_str][2][2] = 0
		AQ.Perf[area_str][3] = true
		
		return
	end
end

function AQ.PerformanceEnd(area_str)
	if not AQ.DEBUG then return end
	local perf = AQ.Perf[area_str]
	
	UpdateAddOnMemoryUsage()
	
	perf[1][2], perf[2][2] = perf[1][2] + debugprofilestop()-perf[1][1], GetAddOnMemoryUsage("AudioQs")-perf[2][1]
end

function AQ.PerformancePrint(area_str)
	local perf = AQ.Perf[area_str]
	print(string.format("%s -- ms:%d. KB:%d. KB+:%d", area_str, perf[1][2], perf[2][1], perf[2][2]))
end

-------- AQ.IsEqualToGcd() -- Returns if the cooldown is equal to the GCD cd, or 1.5 (some abilities trigger a GCD which is not affected by haste)
function AQ.IsEqualToGcd(cd)
	return cd == AQ.GetGcdDur() or cd == 1.5
end
